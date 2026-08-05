// Package logger provides structured JSON logging for shua_resume.
//
// Startup behaviour:
//  1. Attempt to connect to the Governor's Unix Domain Socket (Linux/Pi5 only)
//     at /tmp/horaizon_logs.sock — this pipes logs into the central telemetry DB.
//  2. If UDS is unavailable, attempt TCP loopback 127.0.0.1:5001.
//  3. If neither is reachable, fall back to stdout only.
//
// All sinks receive the same JSON line; stdout is always included so logs are
// visible via `gov logs` SSH tailing on the Pi5.
//
// Time Complexity:  O(1) per log entry.
// Space Complexity: O(1) — single buffered connection, no queuing.
package logger

import (
	"encoding/json"
	"fmt"
	"log"
	"net"
	"os"
	"runtime"
	"sync"
	"time"
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
				stdLogger.Println(`{"ts":"` + time.Now().UTC().Format(time.RFC3339) + `","level":"INFO","subsystem":"logger","module":"shua.resume","msg":"telemetry sink established","sink":"uds"}`)
				return
			}
		}
		// TCP loopback — fallback for non-Linux or when UDS is absent.
		if conn, err := net.DialTimeout("tcp", "127.0.0.1:5001", 500*time.Millisecond); err == nil {
			socketSink = conn
			stdLogger.Println(`{"ts":"` + time.Now().UTC().Format(time.RFC3339) + `","level":"INFO","subsystem":"logger","module":"shua.resume","msg":"telemetry sink established","sink":"tcp_loopback"}`)
			return
		}
		// No socket available — stdout only.
		stdLogger.Println(`{"ts":"` + time.Now().UTC().Format(time.RFC3339) + `","level":"WARN","subsystem":"logger","module":"shua.resume","msg":"no telemetry socket available — stdout only"}`)
	})
}

func emit(level, subsystem, msg string, extra map[string]interface{}) {
	initSocket()

	entry := map[string]interface{}{
		"ts":        time.Now().UTC().Format(time.RFC3339),
		"level":     level,
		"subsystem": subsystem,
		"module":    "shua.resume",
		"msg":       msg,
	}
	for k, v := range extra {
		entry[k] = v
	}
	b, err := json.Marshal(entry)
	if err != nil {
		stdLogger.Printf("[ERROR] failed to marshal log entry: %v", err)
		return
	}
	line := string(b) + "\n"

	// Always emit to stdout (visible via SSH / gov logs).
	stdLogger.Print(line)

	// Forward to Governor telemetry socket if available.
	socketMu.Lock()
	defer socketMu.Unlock()
	if socketSink != nil {
		_ = socketSink.SetWriteDeadline(time.Now().Add(200 * time.Millisecond))
		if _, writeErr := fmt.Fprint(socketSink, line); writeErr != nil {
			// Socket lost — reset so initSocket can reconnect next call.
			_ = socketSink.Close()
			socketSink = nil
			socketOnce = sync.Once{} // allow re-init on next emit
		}
	}
}

// Info emits an INFO-level structured log entry.
func Info(subsystem, msg string, fields map[string]interface{}) {
	emit("INFO", subsystem, msg, fields)
}

// Warn emits a WARN-level structured log entry.
func Warn(subsystem, msg string, fields map[string]interface{}) {
	emit("WARN", subsystem, msg, fields)
}

// Error emits an ERROR-level structured log entry.
func Error(subsystem, msg string, err error, fields map[string]interface{}) {
	if fields == nil {
		fields = make(map[string]interface{})
	}
	if err != nil {
		fields["error"] = fmt.Sprintf("%v", err)
	}
	emit("ERROR", subsystem, msg, fields)
}
