package db

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"

	_ "modernc.org/sqlite"
	"shua_resume/pkg/logger"
)

var (
	DB   *sql.DB
	once sync.Once
)

// InitDB initializes the CGO-free SQLite database, runs migrations, and seeds table defaults
func InitDB(dbPath string) error {
	var err error
	once.Do(func() {
		DB, err = sql.Open("sqlite", dbPath)
		if err != nil {
			err = fmt.Errorf("failed to open database: %w", err)
			return
		}

		if err = DB.Ping(); err != nil {
			err = fmt.Errorf("failed to ping SQLite database: %w", err)
			return
		}

		// Run DDL Migrations
		if err = runMigrations(); err != nil {
			err = fmt.Errorf("sqlite migration failure: %w", err)
			return
		}

		// Seed initial Resume Matrix if empty
		if err = seedDatabase(); err != nil {
			err = fmt.Errorf("sqlite seed failure: %w", err)
			return
		}

		logger.Info("database", "Database successfully initialized and migrated", map[string]interface{}{
			"path": dbPath,
		})
	})
	return err
}

func runMigrations() error {
	queries := []string{
		`CREATE TABLE IF NOT EXISTS shua_resume_matrix (
			user_id TEXT PRIMARY KEY,
			matrix_json TEXT NOT NULL,
			updated_at INTEGER NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS shua_resume_templates (
			id TEXT PRIMARY KEY,
			name TEXT NOT NULL UNIQUE,
			template_type TEXT CHECK(template_type IN ('typst', 'html_css', 'latex')) NOT NULL,
			raw_source TEXT NOT NULL,
			created_at INTEGER NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS shua_compiled_resumes (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			template_id TEXT NOT NULL,
			exhibit_id TEXT,
			version_tag TEXT DEFAULT 'v1.0.0',
			meta_notes TEXT,
			created_at INTEGER NOT NULL,
			FOREIGN KEY(template_id) REFERENCES shua_resume_templates(id)
		);`,
	}

	for _, query := range queries {
		if _, err := DB.Exec(query); err != nil {
			return fmt.Errorf("migration query error (%s): %w", query, err)
		}
	}
	return nil
}

func seedDatabase() error {
	var count int
	err := DB.QueryRow("SELECT COUNT(*) FROM shua_resume_matrix").Scan(&count)
	if err != nil {
		return err
	}

	if count == 0 {
		profilePath := "master_profile.json"
		if _, err := os.Stat(profilePath); os.IsNotExist(err) {
			// Fallback when running from monorepo root
			profilePath = filepath.Join("shua_modules", "shua_resume", "master_profile.json")
		}

		data, err := os.ReadFile(profilePath)
		if err != nil {
			return fmt.Errorf("failed to read master profile seed: %w", err)
		}

		// Parse JSON to validate structural compliance before inserting
		var validation interface{}
		if err = json.Unmarshal(data, &validation); err != nil {
			return fmt.Errorf("seed master profile is not valid JSON: %w", err)
		}

		now := time.Now().UnixNano() / int64(time.Millisecond)
		_, err = DB.Exec(
			"INSERT INTO shua_resume_matrix (user_id, matrix_json, updated_at) VALUES (?, ?, ?)",
			"default", string(data), now,
		)
		if err != nil {
			return fmt.Errorf("failed to insert seed row: %w", err)
		}
		logger.Info("database", "Seeded shua_resume_matrix table successfully with master_profile.json", nil)
	}

	// Seed initial template if empty
	var tempCount int
	err = DB.QueryRow("SELECT COUNT(*) FROM shua_resume_templates").Scan(&tempCount)
	if err != nil {
		return err
	}

	if tempCount == 0 {
		templatePath := filepath.Join("pkg", "templates", "ats_technical.typ")
		if _, err := os.Stat(templatePath); os.IsNotExist(err) {
			templatePath = filepath.Join("shua_modules", "shua_resume", "pkg", "templates", "ats_technical.typ")
		}

		data, err := os.ReadFile(templatePath)
		if err != nil {
			return fmt.Errorf("failed to read default template: %w", err)
		}

		now := time.Now().UnixNano() / int64(time.Millisecond)
		_, err = DB.Exec(
			"INSERT INTO shua_resume_templates (id, name, template_type, raw_source, created_at) VALUES (?, ?, ?, ?, ?)",
			"ats_technical", "ats_technical", "typst", string(data), now,
		)
		if err != nil {
			return fmt.Errorf("failed to insert seed template: %w", err)
		}
		logger.Info("database", "Seeded shua_resume_templates table successfully with ats_technical.typ", nil)
	}

	return nil
}
