// Package main is the entrypoint for shua_resume.
// On startup it:
//  1. Initialises the SQLite database (WAL, migrations, seed)
//  2. Connects to the Governor IPC (port 7701) and registers 2 MCP tools
//  3. Wires the HBP handler into the IPC frame loop
//  4. Blocks until a termination signal is received
package main

import (
	"os"
	"os/signal"
	"syscall"

	"shua_resume/pkg/db"
	"shua_resume/pkg/hbp"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/mcp"
)

const dbPath = "resume.db"

func main() {
	// Allow override from environment (useful for systemd unit on Pi 5)
	resolvedDB := dbPath
	if p := os.Getenv("SHUA_RESUME_DB"); p != "" {
		resolvedDB = p
	}

	// 1. Init SQLite
	if err := db.InitDB(resolvedDB); err != nil {
		logger.Error("main", "Database init failed — exiting", err, nil)
		os.Exit(1)
	}
	logger.Info("main", "shua_resume starting", map[string]interface{}{
		"db": resolvedDB,
	})

	// 2. Create MCP / IPC server
	mcpSrv := mcp.New()

	// 3. Create HBP handler (needs mcp for vault IPC + AI route)
	hbpHandler := hbp.New(mcpSrv)

	// 4. Wire: IPC frames forwarded from Governor dispatcher -> HBP handler
	mcpSrv.OnHBPFrame = func(raw []byte) {
		response := hbpHandler.Handle(raw)
		if response != nil {
			// TODO: send response back over IPC once governor dispatcher
			// supports reply channel (TASK-020 follow-up)
			_ = response
		}
	}

	// 5. Start IPC connection in background (reconnects automatically)
	go mcpSrv.Connect()

	// 6. Block until SIGTERM / SIGINT
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGTERM, syscall.SIGINT)
	sig := <-quit

	logger.Info("main", "shutdown signal received — exiting cleanly", map[string]interface{}{
		"signal": sig.String(),
	})
}
