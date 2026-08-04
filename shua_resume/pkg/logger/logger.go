package logger

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"time"
)

var stdLogger = log.New(os.Stdout, "", 0)

func emit(level, subsystem, msg string, extra map[string]interface{}) {
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
	stdLogger.Println(string(b))
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
