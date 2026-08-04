package main

import (
	"shua_resume/pkg/db"
	"shua_resume/pkg/handlers"
	"shua_resume/pkg/logger"

	"github.com/gofiber/contrib/websocket"
	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	logger.Info("lifecycle", "Initializing S.H.U.A. Resume & Portfolio Builder on Port 3006", nil)

	// 1. Initialize SQLite Database (runs DDL migrations & seeds matrix)
	if err := db.InitDB("resume.db"); err != nil {
		logger.Error("lifecycle", "Database initialization failed", err, nil)
		panic(err)
	}

	// 2. Setup Fiber Router
	app := fiber.New(fiber.Config{
		DisableStartupMessage: true, // Obey Zero-Stdout / Zero-Print Rule
	})

	// Add panic recovery middleware
	app.Use(recover.New())

	// WebSocket / Socket.io upgrade endpoint
	app.Use("/socket.io", func(c *fiber.Ctx) error {
		if websocket.IsWebSocketUpgrade(c) {
			return c.Next()
		}
		return fiber.ErrUpgradeRequired
	})
	app.Get("/socket.io", websocket.New(handlers.HandleWebSocket))
	app.Get("/socket.io/*", websocket.New(handlers.HandleWebSocket))

	// 3. Register HTTP Routes
	app.Get("/health", handlers.HealthCheckHandler)
	app.Get("/api/resume/matrix", handlers.GetMatrixHandler)
	app.Post("/api/resume/matrix", handlers.UpdateMatrixHandler)
	app.Post("/api/resume/compile", handlers.CompilePdfHandler)
	app.Get("/api/resume/templates", handlers.GetTemplatesHandler)
	app.Get("/api/resume/compiled", handlers.ListCompiledHandler)

	// 4. Start HTTP Server
	logger.Info("lifecycle", "Fiber router successfully configured; listening on port 3006", nil)
	if err := app.Listen(":3006"); err != nil {
		logger.Error("lifecycle", "Server failed to start", err, nil)
		panic(err)
	}
}
