package logger

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/vmihailenco/msgpack/v5"
)

// LogEntry matches the fields of the universal log_entry_contract schema
type LogEntry struct {
	Ts        uint64                 `json:"ts"`
	Level     uint8                  `json:"level"`
	Module    uint8                  `json:"module"`
	Subsystem string                 `json:"subsystem"`
	Msg       string                 `json:"msg"`
	Telemetry map[string]interface{} `json:"telemetry,omitempty"`
	TraceID   string                 `json:"trace_id,omitempty"`
}

var (
	logChannel       = make(chan LogEntry, 256)
	droppedLogsCount uint64
	workerOnce       sync.Once
	httpClient       = &http.Client{
		Timeout: 1 * time.Second,
	}
)

func init() {
	// Start the background log emitter goroutine exactly once
	workerOnce.Do(func() {
		go logWorker()
	})
}

// logWorker continuously drains logChannel and POSTs HBP binary packets to the Governor
func logWorker() {
	for entry := range logChannel {
		// Map the LogEntry fields to integer-keyed map matching HBP contract
		payloadMap := map[int]interface{}{
			0: entry.Ts,
			1: entry.Level,
			2: entry.Module,
			3: entry.Subsystem,
			4: entry.Msg,
			5: uint32(0), // tags
		}
		if entry.Telemetry != nil {
			payloadMap[7] = entry.Telemetry
		}
		if entry.TraceID != "" {
			payloadMap[8] = entry.TraceID
		}

		msgpackBytes, err := msgpack.Marshal(payloadMap)
		if err != nil {
			continue // Discard if encoding fails
		}

		// Build 12-byte HBP header:
		//   [0]    = 0x48 ('H') magic
		//   [1]    = 0x42 ('B') magic
		//   [2]    = 0x00       version (reserved)
		//   [3]    = 0x12       type: LOG
		//   [4-7]  = 0x00000000 flags / stream ID (reserved)
		//   [8-11] = payload length as u32 big-endian
		header := make([]byte, 12)
		header[0] = 0x48
		header[1] = 0x42
		header[2] = 0x00
		header[3] = 0x12
		binary.BigEndian.PutUint32(header[8:12], uint32(len(msgpackBytes)))

		// Combine header and payload
		frame := append(header, msgpackBytes...)

		resp, err := httpClient.Post(
			"http://127.0.0.1:3000/api/logs/ingest",
			"application/octet-stream",
			bytes.NewReader(frame),
		)
		if err != nil {
			// Fail silently
			continue
		}
		resp.Body.Close()
	}
}

// Map level string to integer ID
func resolveLogLevel(level string) uint8 {
	switch level {
	case "TRACE":
		return 1
	case "DEBUG":
		return 2
	case "INFO":
		return 3
	case "WARN":
		return 4
	case "ERROR":
		return 5
	default:
		return 3
	}
}

// submitLog writes to the buffered channel in a non-blocking select block
func submitLog(levelStr, subsystem, msg string, telemetry map[string]interface{}) {
	entry := LogEntry{
		Ts:        uint64(time.Now().UnixNano() / int64(time.Millisecond)),
		Level:     resolveLogLevel(levelStr),
		Module:    5, // SHUA_RESUME
		Subsystem: subsystem,
		Msg:       msg,
		Telemetry: telemetry,
	}

	select {
	case logChannel <- entry:
	default:
		// Log channel buffer is full, drop log and increment atomic counter
		atomic.AddUint64(&droppedLogsCount, 1)
	}
}

// Debug logs debug-level events
func Debug(subsystem, msg string, telemetry map[string]interface{}) {
	submitLog("DEBUG", subsystem, msg, telemetry)
}

// Info logs info-level events
func Info(subsystem, msg string, telemetry map[string]interface{}) {
	submitLog("INFO", subsystem, msg, telemetry)
}

// Error logs error-level events, automatically formatting the error if present
func Error(subsystem, msg string, err error, telemetry map[string]interface{}) {
	fullMsg := msg
	if err != nil {
		fullMsg = fmt.Sprintf("%s: %v", msg, err)
	}
	submitLog("ERROR", subsystem, fullMsg, telemetry)
}

// GetDroppedCount returns the number of logs dropped due to channel congestion
func GetDroppedCount() uint64 {
	return atomic.LoadUint64(&droppedLogsCount)
}
