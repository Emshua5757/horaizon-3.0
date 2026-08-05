// Package logger provides structured HBP v2 binary frame logging for shua_resume.
//
// Startup behaviour:
//  1. Attempt to connect to the Governor's Unix Domain Socket (Linux/Pi5 only)
//     at /tmp/horaizon_logs.sock — this pipes HBP binary log frames into the
//     central telemetry DB via shua_governor's log IPC listener.
//  2. If UDS is unavailable, attempt TCP loopback 127.0.0.1:5001.
//  3. If neither is reachable, fall back to stdout only (human-readable text).
//
// Wire format emitted per log entry (12-byte HBP header + MsgPack payload):
//
//	[0x48][0x42][0x02][0x12] [0x00 0x00 0x00 0x00] [payload_len u32 BE] [MsgPack LogEntryDto]
//	  H     B   ver   LOG        reserved
//
// Time Complexity:  O(n) — n = number of fields in telemetry map (usually 0–5).
// Space Complexity: O(n) — single stack-allocated header + heap MsgPack bytes.
package logger

import (
	"encoding/binary"
	"fmt"
	"log"
	"net"
	"os"
	"runtime"
	"sync"
	"time"

	"github.com/vmihailenco/msgpack/v5"

	hbp "shua_resume/pkg/hbp/generated"
)

const (
	hbpMagic0   byte = 0x48 // 'H'
	hbpMagic1   byte = 0x42 // 'B'
	hbpVersion  byte = 0x02
	hbpTypeLog  byte = 0x12
	moduleResume uint8 = 20 // shua.resume module ID
	moduleName   = "shua.resume"
)

var stdLogger = log.New(os.Stdout, "", 0)

// socketSink is the live connection to the Governor telemetry listener (UDS or TCP).
// nil if no socket could be established.
var (
	socketSink net.Conn
	socketOnce sync.Once
	socketMu   sync.Mutex
)

// initSocket tries to establish a connection to the Governor telemetry listener.
// Called lazily on first log emission so the binary doesn't block startup if
// the Governor is not yet ready.
func initSocket() {
	socketOnce.Do(func() {
		// UDS — Linux / Pi5 only.
		if runtime.GOOS == "linux" {
			if conn, err := net.DialTimeout("unix", "/tmp/horaizon_logs.sock", 500*time.Millisecond); err == nil {
				socketSink = conn
				stdLogger.Printf("[%s] [INFO] [logger] HBP v2 telemetry sink established (uds)", time.Now().UTC().Format(time.RFC3339))
				return
			}
		}
		// TCP loopback — fallback for non-Linux or when UDS is absent.
		if conn, err := net.DialTimeout("tcp", "127.0.0.1:5001", 500*time.Millisecond); err == nil {
			socketSink = conn
			stdLogger.Printf("[%s] [INFO] [logger] HBP v2 telemetry sink established (tcp_loopback)", time.Now().UTC().Format(time.RFC3339))
			return
		}
		// No socket available — stdout only.
		stdLogger.Printf("[%s] [WARN] [logger] no telemetry socket available — stdout only", time.Now().UTC().Format(time.RFC3339))
	})
}

func emit(level uint8, subsystem, msg string, extra map[string]interface{}) {
	initSocket()

	modName := moduleName
	entry := hbp.LogEntryDto{
		Ts:         uint64(time.Now().UnixMilli()),
		Level:      level,
		Module:     moduleResume,
		Subsystem:  subsystem,
		Msg:        msg,
		Tags:       0,
		ModuleName: &modName,
	}
	if len(extra) > 0 {
		// Pack extra fields into Telemetry map
		telemetry := make(map[string]interface{}, len(extra))
		for k, v := range extra {
			telemetry[k] = v
		}
		entry.Telemetry = &telemetry
	}

	// Always emit human-readable line to stdout (visible via SSH / gov logs).
	levelStr := levelToStr(level)
	stdLogger.Printf("[%s] [%s] [%s] %s", time.Now().UTC().Format(time.RFC3339), levelStr, subsystem, msg)

	// Serialize and send HBP binary frame to Governor telemetry socket.
	socketMu.Lock()
	defer socketMu.Unlock()
	if socketSink == nil {
		return
	}

	payload, err := msgpack.Marshal(entry)
	if err != nil {
		stdLogger.Printf("[ERROR] [logger] msgpack marshal failed: %v", err)
		return
	}

	// Build 12-byte HBP header.
	var header [12]byte
	header[0] = hbpMagic0
	header[1] = hbpMagic1
	header[2] = hbpVersion
	header[3] = hbpTypeLog
	// bytes 4..7 = reserved (zeros)
	binary.BigEndian.PutUint32(header[8:12], uint32(len(payload)))

	_ = socketSink.SetWriteDeadline(time.Now().Add(200 * time.Millisecond))
	if _, writeErr := socketSink.Write(header[:]); writeErr != nil {
		socketSink.Close()
		socketSink = nil
		socketOnce = sync.Once{} // allow re-init on next emit
		return
	}
	if _, writeErr := fmt.Fprint(socketSink, string(payload)); writeErr != nil {
		socketSink.Close()
		socketSink = nil
		socketOnce = sync.Once{}
	}
}

func levelToStr(level uint8) string {
	switch level {
	case 1:
		return "TRACE"
	case 2:
		return "DEBUG"
	case 3:
		return "INFO"
	case 4:
		return "WARN"
	case 5:
		return "ERROR"
	default:
		return "INFO"
	}
}

// Info emits an INFO-level structured HBP log entry.
func Info(subsystem, msg string, fields map[string]interface{}) {
	emit(3, subsystem, msg, fields)
}

// Warn emits a WARN-level structured HBP log entry.
func Warn(subsystem, msg string, fields map[string]interface{}) {
	emit(4, subsystem, msg, fields)
}

// Error emits an ERROR-level structured HBP log entry.
func Error(subsystem, msg string, err error, fields map[string]interface{}) {
	if fields == nil {
		fields = make(map[string]interface{})
	}
	if err != nil {
		fields["error"] = fmt.Sprintf("%v", err)
	}
	emit(5, subsystem, msg, fields)
}
