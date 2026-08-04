# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 35

================================================================================

<!-- START_FILE: shua_resume\cmd\main.go -->
# FILE: main.go
**Relative Path**: `shua_resume\cmd\main.go`

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
		// Wrap the handler in a goroutine to prevent IPC deadlocks
		go func(payload []byte) {
			response := hbpHandler.Handle(payload)
			if response != nil {
				if err := mcpSrv.SendHBPReply(response); err != nil {
					logger.Error("main", "failed to send HBP reply over IPC", err, nil)
				}
			}
		}(raw)
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


<!-- END_FILE: shua_resume\cmd\main.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\ai\tailor.go -->
# FILE: tailor.go
**Relative Path**: `shua_resume\pkg\ai\tailor.go`

// Package ai provides the Jaccard resume tailoring engine.
// Ported from horAIzon 2.0 with the direct Ollama HTTP call replaced by
// governor.ai.route HBP v2 RPC via the shared MCP IPC connection.
//
// Time Complexity:
//   - Tokenize:        O(n),         n = input token count
//   - JaccardSimilarity: O(|A|+|B|)
//   - FilterResume:    O((W+P)*T),   W=work, P=projects, T=avg token set size
//   - TailorResume:    O(network)    — bounded by Ollama inference time on Pi 5
//
// Space Complexity: O(n) token set per call; O(W+P) for sorted score lists.
package ai

import (
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strings"

	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
)

var wordRegex = regexp.MustCompile(`[a-zA-Z0-9+#.\-]+`)

// Tokenize processes raw text, splits into lowercase alphanumeric tokens,
// and returns a unique token set. O(n).
func Tokenize(text string) map[string]bool {
	tokens := make(map[string]bool)
	for _, match := range wordRegex.FindAllString(strings.ToLower(text), -1) {
		cleaned := strings.TrimRight(match, ".,!?;:")
		if len(cleaned) > 1 {
			tokens[cleaned] = true
		}
	}
	return tokens
}

// JaccardSimilarity calculates |A ∩ B| / |A ∪ B|. O(|A|+|B|).
func JaccardSimilarity(setA, setB map[string]bool) float64 {
	if len(setA) == 0 || len(setB) == 0 {
		return 0.0
	}
	intersection := 0
	for token := range setA {
		if setB[token] {
			intersection++
		}
	}
	union := len(setA) + len(setB) - intersection
	if union == 0 {
		return 0.0
	}
	return float64(intersection) / float64(union)
}

// TailorConfig contains options for relevance filtering and AI tailoring.
type TailorConfig struct {
	WorkLimit    int     `json:"work_limit"`
	ProjectLimit int     `json:"project_limit"`
	MinScore     float64 `json:"min_score"`
	UseAI        bool    `json:"use_ai"`
}

// DefaultTailorConfig returns conservative defaults suitable for Pi 5 workloads.
func DefaultTailorConfig() TailorConfig {
	return TailorConfig{
		WorkLimit:    3,
		ProjectLimit: 2,
		MinScore:     0.0,
		UseAI:        true,
	}
}

// FilterResume ranks work items and projects by Jaccard similarity against the
// job description and activates the top-scoring entries up to the configured limits.
// The matrix is modified in place and returned.
func FilterResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) (*models.ResumeMatrix, float64) {
	if strings.TrimSpace(jobDescription) == "" {
		for i := range matrix.Work {
			matrix.Work[i].Active = true
		}
		for i := range matrix.Projects {
			matrix.Projects[i].Active = true
		}
		return matrix, 0.0
	}

	jdTokens := Tokenize(jobDescription)

	// Filter work items
	type scored struct {
		index int
		score float64
	}
	workScores := make([]scored, 0, len(matrix.Work))
	for i, item := range matrix.Work {
		content := strings.Join([]string{
			item.Name, item.Position, item.Summary,
			strings.Join(item.Highlights, " "),
			strings.Join(item.Skills, " "),
		}, " ")
		s := JaccardSimilarity(jdTokens, Tokenize(content))
		if s >= config.MinScore {
			workScores = append(workScores, scored{i, s})
		}
	}
	sort.SliceStable(workScores, func(i, j int) bool { return workScores[i].score > workScores[j].score })

	for i := range matrix.Work {
		matrix.Work[i].Active = false
	}
	var bestScore float64
	for i := 0; i < len(workScores) && i < config.WorkLimit; i++ {
		matrix.Work[workScores[i].index].Active = true
		if i == 0 {
			bestScore = workScores[i].score
		}
	}

	// Filter projects
	projScores := make([]scored, 0, len(matrix.Projects))
	for i, item := range matrix.Projects {
		content := strings.Join([]string{
			item.Name, item.Description,
			strings.Join(item.Highlights, " "),
		}, " ")
		s := JaccardSimilarity(jdTokens, Tokenize(content))
		if s >= config.MinScore {
			projScores = append(projScores, scored{i, s})
		}
	}
	sort.SliceStable(projScores, func(i, j int) bool { return projScores[i].score > projScores[j].score })

	for i := range matrix.Projects {
		matrix.Projects[i].Active = false
	}
	for i := 0; i < len(projScores) && i < config.ProjectLimit; i++ {
		matrix.Projects[projScores[i].index].Active = true
	}

	return matrix, bestScore
}

// TailorResumeViaGovernor sends an AI enhance request to the Governor via
// governor.ai.route HBP v2 RPC. On any failure it gracefully falls back to
// the unmodified matrix and logs a warning — never blocks the compile pipeline.
//
// ipcSend is a callback injected by mcp/mcp_server.go to send a JSON frame
// over the live IPC WebSocket and receive the text response. This avoids a
// circular import between ai and mcp packages.
func TailorResumeViaGovernor(
	matrix *models.ResumeMatrix,
	jobDescription string,
	config TailorConfig,
	ipcSend func(op string, payload map[string]interface{}) (string, error),
) *models.ResumeMatrix {
	if !config.UseAI || strings.TrimSpace(jobDescription) == "" || ipcSend == nil {
		return matrix
	}

	matrixJSON, err := json.Marshal(matrix)
	if err != nil {
		logger.Error("ai_tailor", "failed to marshal matrix for AI route", err, nil)
		return matrix
	}

	prompt := fmt.Sprintf(
		"Enhance this resume JSON for the following job. Return ONLY the modified JSON with no markdown fences:\n%s\nJob description:\n%s",
		string(matrixJSON), jobDescription,
	)

	reply, err := ipcSend("governor.ai.route", map[string]interface{}{
		"prompt":       prompt,
		"context_hint": "resume",
	})
	if err != nil {
		logger.Warn("ai_tailor", "Governor AI route failed — using original matrix", map[string]interface{}{"error": err.Error()})
		return matrix
	}

	// Strip markdown fences if model wrapped the response
	reply = strings.TrimSpace(reply)
	reply = strings.TrimPrefix(reply, "```json")
	reply = strings.TrimPrefix(reply, "```")
	reply = strings.TrimSuffix(reply, "```")
	reply = strings.TrimSpace(reply)

	var enhanced models.ResumeMatrix
	if err := json.Unmarshal([]byte(reply), &enhanced); err != nil {
		logger.Warn("ai_tailor", "AI response was not valid JSON — using original matrix", map[string]interface{}{"raw": reply[:min(200, len(reply))]})
		return matrix
	}

	logger.Info("ai_tailor", "AI tailoring applied successfully", nil)
	return &enhanced
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}


<!-- END_FILE: shua_resume\pkg\ai\tailor.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\compiler\typst_compiler.go -->
# FILE: typst_compiler.go
**Relative Path**: `shua_resume\pkg\compiler\typst_compiler.go`

// Package compiler wraps the Typst CLI to compile a ResumeMatrix into a PDF []byte.
// Ported from horAIzon 2.0 with updated path resolution for the horAIzon 3.0 layout.
//
// Time Complexity:  O(n) for JSON marshalling (n = matrix fields);
//
//	O(pdf_size) for reading stdout.
//
// Space Complexity: O(json_size + pdf_size) transient during compilation.
package compiler

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
)

// findModuleRoot traverses upward from the working directory to find the directory
// containing go.mod (= the shua_resume module root). Needed because typst templates
// live at {module_root}/templates/*.typ.
// findModuleRoot checks known environment paths to locate the templates folder,
// ensuring cross-platform compatibility between the Windows dev environment and the Pi 5.
func findModuleRoot() string {
	candidates := []string{
		".",                                   // Standard local execution
		"C:\\horaizon-3.0\\shua_resume",       // Windows laptop
		"/home/shua/horaizon-3.0/shua_resume", // Raspberry Pi 5
	}

	for _, dir := range candidates {
		// Check if the "templates" directory exists inside this candidate path
		if stat, err := os.Stat(filepath.Join(dir, "templates")); err == nil && stat.IsDir() {
			return dir
		}
	}

	// Fallback to the current working directory
	cwd, _ := os.Getwd()
	return cwd
}

// resolveTypstPath locates the typst binary in:
//  1. System PATH
//  2. Windows WinGet link directory
//  3. Linux common Cargo / system install paths
func resolveTypstPath() string {
	if path, err := exec.LookPath("typst"); err == nil {
		return path
	}

	// Windows WinGet
	if userProfile := os.Getenv("USERPROFILE"); userProfile != "" {
		candidate := filepath.Join(userProfile, "AppData", "Local", "Microsoft", "WinGet", "Links", "typst.exe")
		if _, err := os.Stat(candidate); err == nil {
			return candidate
		}
	}

	// Linux / Pi 5 fallback paths
	for _, path := range []string{
		"/home/shua/.cargo/bin/typst",
		"/usr/local/bin/typst",
		"/usr/bin/typst",
	} {
		if _, err := os.Stat(path); err == nil {
			return path
		}
	}

	return "typst" // last resort: let OS resolve
}

// CompileTypst serializes matrix to JSON, injects it into the named Typst template
// via stdin, and runs `typst compile - -` to produce a PDF byte slice.
//
// On Typst binary absence or compile error this function returns a non-nil error.
// The caller (hbp_handler) handles the markdown fallback.
func CompileTypst(matrix *models.ResumeMatrix, templateName string) ([]byte, error) {
	jsonData, err := json.Marshal(matrix)
	if err != nil {
		return nil, fmt.Errorf("marshal matrix: %w", err)
	}

	// Escape for embedding in a Typst string literal
	escaped := string(jsonData)
	escaped = strings.ReplaceAll(escaped, `\`, `\\`)
	escaped = strings.ReplaceAll(escaped, `"`, `\"`)

	typstInput := fmt.Sprintf(`#import "templates/%s.typ": resume_template
#let data = json(bytes("%s"))
#show: doc => resume_template(data)
`, templateName, escaped)

	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()

	typstBin := resolveTypstPath()
	cmd := exec.CommandContext(ctx, typstBin, "compile", "--ignore-system-fonts", "-", "-")
	cmd.Stdin = strings.NewReader(typstInput)
	cmd.Dir = findModuleRoot() // templates/ lives here

	var stdoutBuf, stderrBuf bytes.Buffer
	cmd.Stdout = &stdoutBuf
	cmd.Stderr = &stderrBuf

	start := time.Now()
	err = cmd.Run()
	latencyMs := time.Since(start).Milliseconds()

	if err != nil {
		if ctx.Err() == context.DeadlineExceeded {
			logger.Warn("compiler", "typst compile timeout (20s)", map[string]interface{}{
				"template": templateName,
			})
			return nil, fmt.Errorf("ERR_TYPST_UNAVAILABLE: compile timeout")
		}
		logger.Warn("compiler", "typst compilation failed — markdown fallback will activate", map[string]interface{}{
			"template":   templateName,
			"latency_ms": latencyMs,
			"stderr":     stderrBuf.String(),
		})
		return nil, fmt.Errorf("ERR_TYPST_UNAVAILABLE: %w (stderr: %s)", err, stderrBuf.String())
	}

	logger.Info("compiler", "typst compiled PDF", map[string]interface{}{
		"template":   templateName,
		"latency_ms": latencyMs,
		"pdf_bytes":  stdoutBuf.Len(),
	})

	return stdoutBuf.Bytes(), nil
}

// MatrixToMarkdown generates a plain-text Markdown fallback when Typst is unavailable,
// or when the user explicitly requests a Markdown export.
func MatrixToMarkdown(matrix *models.ResumeMatrix) string {
	var sb strings.Builder

	sb.WriteString(fmt.Sprintf("# %s\n\n", matrix.Basics.Name))

	// Header line: label | email | phone
	sb.WriteString(fmt.Sprintf("**%s** | %s | %s | %s\n\n",
		matrix.Basics.Label, matrix.Basics.Email, matrix.Basics.Phone,
		matrix.Basics.Location.City+", "+matrix.Basics.Location.Region))

	// Profile links
	if len(matrix.Basics.Profiles) > 0 {
		for _, p := range matrix.Basics.Profiles {
			sb.WriteString(fmt.Sprintf("- **%s**: %s\n", p.Network, p.Url))
		}
		sb.WriteString("\n")
	}

	if matrix.Basics.Summary != "" {
		sb.WriteString("## Summary\n\n")
		sb.WriteString(matrix.Basics.Summary + "\n\n")
	}

	if len(matrix.Work) > 0 {
		sb.WriteString("## Experience\n\n")
		for _, w := range matrix.Work {
			if !w.Active {
				continue
			}
			sb.WriteString(fmt.Sprintf("### %s — %s  \n", w.Position, w.Name))
			sb.WriteString(fmt.Sprintf("*%s – %s*\n\n", w.StartDate, w.EndDate))
			if w.Summary != "" {
				sb.WriteString(w.Summary + "\n\n")
			}
			for _, h := range w.Highlights {
				sb.WriteString(fmt.Sprintf("- %s\n", h))
			}
			if len(w.Keywords) > 0 {
				sb.WriteString(fmt.Sprintf("\n*Keywords: %s*\n", strings.Join(w.Keywords, ", ")))
			}
			sb.WriteString("\n")
		}
	}

	if len(matrix.Organizations) > 0 {
		sb.WriteString("## Organizational Experience\n\n")
		for _, o := range matrix.Organizations {
			if !o.Active {
				continue
			}
			sb.WriteString(fmt.Sprintf("### %s — %s  \n", o.Role, o.Organization))
			sb.WriteString(fmt.Sprintf("*%s – %s*\n\n", o.StartDate, o.EndDate))
			if o.Summary != "" {
				sb.WriteString(o.Summary + "\n\n")
			}
			for _, h := range o.Highlights {
				sb.WriteString(fmt.Sprintf("- %s\n", h))
			}
			sb.WriteString("\n")
		}
	}

	if len(matrix.Projects) > 0 {
		sb.WriteString("## Projects\n\n")
		for _, p := range matrix.Projects {
			if !p.Active {
				continue
			}
			sb.WriteString(fmt.Sprintf("### %s\n\n%s\n\n", p.Name, p.Description))
			for _, h := range p.Highlights {
				sb.WriteString(fmt.Sprintf("- %s\n", h))
			}
			if len(p.Keywords) > 0 {
				sb.WriteString(fmt.Sprintf("\n*Keywords: %s*\n", strings.Join(p.Keywords, ", ")))
			}
			sb.WriteString("\n")
		}
	}

	if len(matrix.Education) > 0 {
		sb.WriteString("## Education\n\n")
		for _, e := range matrix.Education {
			sb.WriteString(fmt.Sprintf("**%s** — %s, %s  \n", e.Institution, e.StudyType, e.Area))
			sb.WriteString(fmt.Sprintf("*%s – %s*  %s\n\n", e.StartDate, e.EndDate, e.Score))
		}
	}

	if len(matrix.Skills) > 0 {
		sb.WriteString("## Skills\n\n")
		for _, s := range matrix.Skills {
			sb.WriteString(fmt.Sprintf("**%s**: %s\n\n", s.Name, strings.Join(s.Keywords, ", ")))
		}
	}

	if len(matrix.Certificates) > 0 {
		sb.WriteString("## Certifications\n\n")
		for _, c := range matrix.Certificates {
			sb.WriteString(fmt.Sprintf("- %s — %s (%s)\n", c.Name, c.Issuer, c.Date))
		}
		sb.WriteString("\n")
	}

	if len(matrix.Awards) > 0 {
		sb.WriteString("## Awards & Recognition\n\n")
		for _, a := range matrix.Awards {
			sb.WriteString(fmt.Sprintf("- **%s** (%s) — %s\n", a.Title, a.Date, a.Sender))
		}
		sb.WriteString("\n")
	}

	return sb.String()
}



<!-- END_FILE: shua_resume\pkg\compiler\typst_compiler.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\dateutil\normalize.go -->
# FILE: normalize.go
**Relative Path**: `shua_resume\pkg\dateutil\normalize.go`

// Package dateutil provides resume date parsing and normalization helpers.
//
// Time Complexity:  O(p) where p = number of date format candidates tried (bounded constant).
// Space Complexity: O(1) — no heap allocations beyond the output string.
package dateutil

import (
	"strings"
	"time"

	"shua_resume/pkg/logger"
)

// presentMarkers lists strings the user might type to indicate an ongoing role.
var presentMarkers = map[string]bool{
	"present": true, "current": true, "now": true, "ongoing": true, "today": true,
}

// inputLayouts lists all accepted Go time.Parse layouts, ordered most-specific first.
var inputLayouts = []string{
	"2006-01-02",   // YYYY-MM-DD
	"January 2006", // Month YYYY (full)
	"Jan 2006",     // Mon YYYY (abbreviated)
	"01/2006",      // MM/YYYY
	"2006-01",      // YYYY-MM
	"2006",         // YYYY only
}

// outputLayout is the canonical output format used in Typst templates and Markdown.
const outputLayout = "Jan 2006" // e.g. "Aug 2024"

// NormalizeDate accepts a freeform date string and returns a canonical "Mon YYYY" string.
//
// Rules:
//   - Empty string                           → returns ""
//   - Present markers ("Present", "Current") → returns "Present"
//   - YYYY-only input                        → returns "YYYY" (no month available)
//   - All other recognized formats           → returns "Mon YYYY" (e.g. "Aug 2024")
//   - Unrecognized input                     → returns the original string unchanged
//     (with a warning log so the issue is visible in telemetry)
func NormalizeDate(input string) string {
	trimmed := strings.TrimSpace(input)
	if trimmed == "" {
		return ""
	}

	lower := strings.ToLower(trimmed)
	if presentMarkers[lower] {
		return "Present"
	}

	// Try each layout in priority order.
	for _, layout := range inputLayouts {
		t, err := time.Parse(layout, trimmed)
		if err != nil {
			continue
		}
		// YYYY-only: no month info available — keep year only.
		if layout == "2006" {
			return t.Format("2006")
		}
		return t.Format(outputLayout)
	}

	// Unrecognized — log a warning and return as-is so data is not lost.
	logger.Warn("dateutil", "unrecognized date format — stored as-is", map[string]interface{}{
		"input": trimmed,
	})
	return trimmed
}

// NormalizeDateField normalizes a date field in-place and returns the result.
// Convenience wrapper for use at the call site without an intermediate variable.
func NormalizeDateField(input *string) {
	if input == nil {
		return
	}
	*input = NormalizeDate(*input)
}


<!-- END_FILE: shua_resume\pkg\dateutil\normalize.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\db\db.go -->
# FILE: db.go
**Relative Path**: `shua_resume\pkg\db\db.go`

package db

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"

	"shua_resume/pkg/logger"
)

var (
	// DB is the global SQLite connection (WAL mode, single writer).
	DB   *sql.DB
	once sync.Once
)

// InitDB opens the SQLite database at dbPath, applies migrations, and seeds baseline data.
// Safe to call multiple times — the sync.Once ensures a single open.
func InitDB(dbPath string) error {
	var initErr error
	once.Do(func() {
		var err error
		DB, err = sql.Open("sqlite", dbPath+"?_journal_mode=WAL&_foreign_keys=on")
		if err != nil {
			initErr = fmt.Errorf("failed to open database: %w", err)
			return
		}
		if err = DB.Ping(); err != nil {
			initErr = fmt.Errorf("failed to ping SQLite: %w", err)
			return
		}
		// Bounded pool — single writer model for Pi 5
		DB.SetMaxOpenConns(1)
		DB.SetMaxIdleConns(1)

		if err = runMigrations(); err != nil {
			initErr = fmt.Errorf("migration failure: %w", err)
			return
		}
		if err = seedDatabase(); err != nil {
			initErr = fmt.Errorf("seed failure: %w", err)
			return
		}
		logger.Info("database", "Database initialized and migrated", map[string]interface{}{
			"path": dbPath,
		})
	})
	return initErr
}

func runMigrations() error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS resume_basics (
			user_id       TEXT PRIMARY KEY DEFAULT 'shua',
			name          TEXT NOT NULL DEFAULT '',
			label         TEXT NOT NULL DEFAULT '',
			email         TEXT NOT NULL DEFAULT '',
			phone         TEXT NOT NULL DEFAULT '',
			url           TEXT NOT NULL DEFAULT '',
			summary       TEXT NOT NULL DEFAULT '',
			city          TEXT NOT NULL DEFAULT '',
			region        TEXT NOT NULL DEFAULT '',
			country_code  TEXT NOT NULL DEFAULT '',
			profiles_json TEXT NOT NULL DEFAULT '[]',
			updated_at    TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS resume_work (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			name        TEXT NOT NULL DEFAULT '',
			position    TEXT NOT NULL DEFAULT '',
			url         TEXT NOT NULL DEFAULT '',
			start_date  TEXT NOT NULL DEFAULT '',
			end_date    TEXT NOT NULL DEFAULT '',
			summary     TEXT NOT NULL DEFAULT '',
			highlights  TEXT NOT NULL DEFAULT '[]',
			skills      TEXT NOT NULL DEFAULT '[]',
			active      INTEGER NOT NULL DEFAULT 1,
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_education (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			institution TEXT NOT NULL DEFAULT '',
			url         TEXT NOT NULL DEFAULT '',
			area        TEXT NOT NULL DEFAULT '',
			study_type  TEXT NOT NULL DEFAULT '',
			start_date  TEXT NOT NULL DEFAULT '',
			end_date    TEXT NOT NULL DEFAULT '',
			score       TEXT NOT NULL DEFAULT '',
			courses     TEXT NOT NULL DEFAULT '[]',
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_projects (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			name        TEXT NOT NULL DEFAULT '',
			description TEXT NOT NULL DEFAULT '',
			highlights  TEXT NOT NULL DEFAULT '[]',
			url         TEXT NOT NULL DEFAULT '',
			exhibits    TEXT NOT NULL DEFAULT '[]',
			active      INTEGER NOT NULL DEFAULT 1,
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_skills (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			name       TEXT NOT NULL DEFAULT '',
			level      TEXT NOT NULL DEFAULT '',
			keywords   TEXT NOT NULL DEFAULT '[]',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_certificates (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			name       TEXT NOT NULL DEFAULT '',
			issuer     TEXT NOT NULL DEFAULT '',
			date       TEXT NOT NULL DEFAULT '',
			url        TEXT NOT NULL DEFAULT '',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_awards (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			title      TEXT NOT NULL DEFAULT '',
			date       TEXT NOT NULL DEFAULT '',
			awarder    TEXT NOT NULL DEFAULT '',
			summary    TEXT NOT NULL DEFAULT '',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_history (
			exhibit_id   TEXT PRIMARY KEY,
			vault_url    TEXT NOT NULL,
			template_id  TEXT NOT NULL DEFAULT '',
			job_desc     TEXT NOT NULL DEFAULT '',
			tailor_score REAL,
			ai_enhanced  INTEGER NOT NULL DEFAULT 0,
			duration_ms  INTEGER NOT NULL DEFAULT 0,
			compiled_at  TEXT NOT NULL
		);`,
	}

	for _, stmt := range statements {
		if _, err := DB.Exec(stmt); err != nil {
			return fmt.Errorf("migration error: %w", err)
		}
	}

	// Additive migrations for existing deployments — idempotent via IF NOT EXISTS / IGNORE.
	additiveMigrations := []string{
		`ALTER TABLE resume_work ADD COLUMN keywords TEXT NOT NULL DEFAULT '[]'`,
		`ALTER TABLE resume_projects ADD COLUMN keywords TEXT NOT NULL DEFAULT '[]'`,
		`CREATE TABLE IF NOT EXISTS resume_organizations (
			id           TEXT PRIMARY KEY,
			user_id      TEXT NOT NULL DEFAULT 'shua',
			organization TEXT NOT NULL DEFAULT '',
			role         TEXT NOT NULL DEFAULT '',
			start_date   TEXT NOT NULL DEFAULT '',
			end_date     TEXT NOT NULL DEFAULT '',
			summary      TEXT NOT NULL DEFAULT '',
			highlights   TEXT NOT NULL DEFAULT '[]',
			active       INTEGER NOT NULL DEFAULT 1,
			sort_order   INTEGER NOT NULL DEFAULT 0
		);`,
	}
	for _, stmt := range additiveMigrations {
		// Ignore errors — ALTER TABLE fails harmlessly if column already exists.
		_, _ = DB.Exec(stmt)
	}

	return nil
}

// seedDatabase inserts Joshua B. Ygot's master profile if tables are empty.
func seedDatabase() error {
	var count int
	if err := DB.QueryRow("SELECT COUNT(*) FROM resume_basics").Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil // already seeded
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// ── Basics ──────────────────────────────────────────────────────────────────
	profiles, _ := json.Marshal([]map[string]string{
		{"network": "LinkedIn", "username": "joshua-ygot-298a5736a", "url": "https://www.linkedin.com/in/joshua-ygot-298a5736a"},
	})
	if _, err := DB.Exec(`INSERT INTO resume_basics
		(user_id,name,label,email,phone,url,summary,city,region,country_code,profiles_json,updated_at) VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?)`,
		"shua",
		"Joshua B. Ygot",
		"Computer Engineer & Embedded Systems Specialist",
		"ygot.joshua5142004@gmail.com",
		"09615981753",
		"https://www.linkedin.com/in/joshua-ygot-298a5736a",
		"Computer Engineering student and systems engineer specializing in hardware-software co-design, embedded systems, and mobile client integrations. Certified in Java Programming, Internet of Things, Creative Web Design, and Data Analytics. Experienced in custom firmware optimization, hardware prototyping, and edge-native ML deployment.",
		"Mandaue City",
		"Cebu",
		"PH",
		string(profiles),
		now,
	); err != nil {
		return fmt.Errorf("seed basics: %w", err)
	}

	// ── Work ────────────────────────────────────────────────────────────────────
	type workSeed struct {
		name, position, startDate, endDate, summary string
		highlights, skills                          []string
	}
	workItems := []workSeed{
		{
			name: "Sustainable Center for Engineering and Next-Generation Technology",
			position: "Project Research Assistant (Intern)",
			startDate: "2026-02-01", endDate: "2026-05-01",
			summary: "Research and systems engineering for the Agri3D automated horticulture platform.",
			highlights: []string{
				"Embedded Firmware: Customized the GRBL motion control engine on an ATmega328P, stripping unused modules to optimize Flash footprint and interfacing stepper drivers via custom routines.",
				"Hardware Co-design: Routed a custom PCB shield in KiCAD for an Arduino Nano host to drive stepper control circuits.",
				"Dynamic Modeling & Kinematics: Modeled mechanical linkages and 3D-printed components using Autodesk Inventor and Fusion 360, with animation in Blender.",
				"Client Integration: Integrated hardware state telemetry with a cross-platform mobile client built in Flutter.",
				"TinyML & Computer Vision: Engineered and trained an edge-native classification model using Edge Impulse for real-time weed detection, deploying the optimized C++ model library onto an ESP32 node for localized, low-latency inferencing.",
			},
			skills: []string{"Research and Development (R&D)", "Embedded Systems", "Mechatronics", "Flutter"},
		},
		{
			name: "Department of Science and Technology (DOST)",
			position: "On-the-Job Trainee – Quality Assurance (Intern)",
			startDate: "2025-07-01", endDate: "2025-08-01",
			summary: "Participated in the League of Developers Initiative (Project LODI), supporting quality assurance and system compliance workflows for the Information Technology Division.",
			highlights: []string{
				"Test Specification Engineering: Translated technical requirements into structured test case specifications to validate system behavior against functional specifications.",
				"Defect Isolation: Executed systematic test protocols, logging results and verifying compliance boundaries for remote software services.",
				"SDLC Standards: Maintained requirement-to-test traceability matrices in accordance with agency engineering and documentation standards.",
			},
			skills: []string{"Quality Assurance"},
		},
	}
	for i, w := range workItems {
		h, _ := json.Marshal(w.highlights)
		s, _ := json.Marshal(w.skills)
		kw, _ := json.Marshal([]string{})
		if _, err := DB.Exec(`INSERT INTO resume_work (id,user_id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", w.name, w.position, "", w.startDate, w.endDate, w.summary, string(h), string(kw), string(s), 1, i,
		); err != nil {
			return fmt.Errorf("seed work: %w", err)
		}
	}

	// ── Education ───────────────────────────────────────────────────────────────
	type eduSeed struct {
		institution, area, studyType, startDate, endDate, score string
		courses                                                  []string
	}
	eduItems := []eduSeed{
		{"Cebu Technological University Main Campus", "Computer Engineering", "Bachelor of Science", "2022-08-01", "2026-07-01", "GWA: 1.35",
			[]string{"Embedded Systems", "Microprocessors", "Hardware Description Languages", "Data Structures and Algorithms"}},
		{"Mandaue City Science High School", "Secondary Education (High School)", "With Honors", "2016-06-01", "2022-05-01", "With Honors", []string{}},
		{"Opao Elementary School", "Primary Education (Elementary)", "Valedictorian", "2010-06-01", "2016-03-01", "Valedictorian", []string{}},
	}
	for i, e := range eduItems {
		c, _ := json.Marshal(e.courses)
		if _, err := DB.Exec(`INSERT INTO resume_education (id,user_id,institution,url,area,study_type,start_date,end_date,score,courses,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", e.institution, "", e.area, e.studyType, e.startDate, e.endDate, e.score, string(c), i,
		); err != nil {
			return fmt.Errorf("seed education: %w", err)
		}
	}

	// ── Projects ────────────────────────────────────────────────────────────────
	projHighlights, _ := json.Marshal([]string{
		"Constructed firmware optimizations to yield higher execution speeds on restricted 8-bit microcontrollers.",
		"Modeled multi-axis linkages using Autodesk systems to print structural joints.",
	})
	projKeywords, _ := json.Marshal([]string{"Flutter", "Embedded Systems", "GRBL", "ESP32", "Edge AI"})
	projExhibits, _ := json.Marshal([]string{"e5a6f2b4-7c9d-4e8f-9a1b-3c5d7e9f1a2b"})
	if _, err := DB.Exec(`INSERT INTO resume_projects (id,user_id,name,description,highlights,keywords,url,exhibits,active,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?)`,
		uuid.New().String(), "shua",
		"Agri3D Platform",
		"Automated horticulture platform incorporating custom embedded motion controls, spatial design, and Edge AI.",
		string(projHighlights), string(projKeywords), "", string(projExhibits), 1, 0,
	); err != nil {
		return fmt.Errorf("seed projects: %w", err)
	}

	// ── Skills ──────────────────────────────────────────────────────────────────
	type skillSeed struct{ name, level string; keywords []string }
	skills := []skillSeed{
		{"Mechatronics & Embedded Systems", "Expert", []string{"ATmega328P", "ESP32", "Arduino", "GRBL", "KiCAD", "PCB Routing", "Autodesk Inventor", "Fusion 360", "Microcontrollers", "Hardware design"}},
		{"Software Development", "Expert", []string{"Flutter", "Dart", "Java", "C++", "C", "Go", "TypeScript", "HTML", "CSS", "Creative Web Design"}},
		{"Data Analysis", "Intermediate", []string{"Data Analytics", "Microsoft Power BI", "Data Wrangling", "Visualization"}},
		{"Quality Assurance", "Intermediate", []string{"Test Cases", "Traceability Matrices", "SDLC Standards", "Defect Isolation"}},
	}
	for i, sk := range skills {
		kw, _ := json.Marshal(sk.keywords)
		if _, err := DB.Exec(`INSERT INTO resume_skills (id,user_id,name,level,keywords,sort_order) VALUES (?,?,?,?,?,?)`,
			uuid.New().String(), "shua", sk.name, sk.level, string(kw), i,
		); err != nil {
			return fmt.Errorf("seed skills: %w", err)
		}
	}

	// ── Certificates ────────────────────────────────────────────────────────────
	type certSeed struct{ id, name, issuer, date string }
	certs := []certSeed{
		{"YJB-04-174-07022-001-java", "Programming (Java) NC III", "TESDA: Technical Education and Skills Development Authority", "2025-02-01"},
		{"YJB-04-174-07022-002-iot", "Internet of Things (TESDA NC)", "TESDA: Technical Education and Skills Development Authority", "2024-02-01"},
		{"YJB-04-174-07022-003-web", "Creative Web Design (TESDA NC)", "TESDA: Technical Education and Skills Development Authority", "2023-10-01"},
		{"YJB-04-174-07022-004-da", "Data Analytics Level III", "TESDA: Technical Education and Skills Development Authority", "2026-04-01"},
	}
	for i, c := range certs {
		if _, err := DB.Exec(`INSERT INTO resume_certificates (id,user_id,name,issuer,date,url,sort_order) VALUES (?,?,?,?,?,?,?)`,
			c.id, "shua", c.name, c.issuer, c.date, "", i,
		); err != nil {
			return fmt.Errorf("seed certificates: %w", err)
		}
	}

	// ── Awards ──────────────────────────────────────────────────────────────────
	type awardSeed struct{ title, date, awarder, summary string }
	awards := []awardSeed{
		{"DOST-SEI Scholar (JLSS-RA 10612)", "2024-10-01", "Department of Science and Technology – Science Education Institute (DOST-SEI)", "Awarded junior level science scholarship for high academic performance in computer engineering."},
		{"Deans Lister Awardee", "2024-05-01", "Cebu Technological University", "Academic honor recipient during Second Year, GWA: 1.40, and served as ICpEP.SE CTU-MC Secretary."},
		{"Academic Excellence - First Year", "2023-05-01", "Cebu Technological University", "GWA - 1.28 (First Semester), GWA - 1.32 (Second Semester), and served as ICpEP.SE CTU-MC Secretary."},
		{"Secondary Education With Honors", "2022-05-01", "Mandaue City Science High School", "Graduated secondary education with honors."},
		{"Elementary Valedictorian", "2016-03-01", "Opao Elementary School", "Graduated primary education as class valedictorian."},
	}
	for i, a := range awards {
		if _, err := DB.Exec(`INSERT INTO resume_awards (id,user_id,title,date,awarder,summary,sort_order) VALUES (?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", a.title, a.date, a.awarder, a.summary, i,
		); err != nil {
			return fmt.Errorf("seed awards: %w", err)
		}
	}

	logger.Info("database", "Seeded master profile (Joshua B. Ygot) into all resume tables", nil)
	return nil
}


<!-- END_FILE: shua_resume\pkg\db\db.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\hbp\hbp_handler.go -->
# FILE: hbp_handler.go
**Relative Path**: `shua_resume\pkg\hbp\hbp_handler.go`

// Package hbp decodes incoming HBP v2 frames from the Governor dispatcher,
// dispatches to the correct handler, and encodes the response.
//
// Frame routing:
//
//	shua.resume.matrix.get     -> handleMatrixGet
//	shua.resume.matrix.update  -> handleMatrixUpdate
//	shua.resume.compile        -> handleCompile
//	shua.resume.history.list   -> handleHistoryList
//	shua.resume.templates.list -> handleTemplatesList
//	shua.resume.export.markdown -> handleExportMarkdown
package hbp

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/vmihailenco/msgpack/v5"

	"shua_resume/pkg/ai"
	"shua_resume/pkg/compiler"
	"shua_resume/pkg/dateutil"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/mcp"
	"shua_resume/pkg/models"
	"shua_resume/pkg/repository"
)

// Frame is a minimal HBP v2 frame envelope (JSON, as forwarded by the Governor IPC).
type Frame struct {
	ID  string          `json:"id"`
	Mod string          `json:"mod"`
	Op  string          `json:"op"`
	P   json.RawMessage `json:"p"`
	Ts  int64           `json:"ts"`
}

// Handler routes incoming HBP frames to operation handlers.
type Handler struct {
	mcp *mcp.Server
}

// New creates a Handler with a reference to the shared MCP server
// (needed for vault.upload IPC and governor.ai.route RPC).
func New(mcpSrv *mcp.Server) *Handler {
	return &Handler{mcp: mcpSrv}
}

// Handle decodes a raw JSON HBP frame (forwarded from the Governor dispatcher)
// and dispatches it to the correct handler. Returns an encoded JSON response frame.
func (h *Handler) Handle(raw []byte) []byte {
	var frame Frame
	if err := json.Unmarshal(raw, &frame); err != nil {
		logger.Error("hbp_handler", "frame decode error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_FRAME_DECODE")
	}

	logger.Info("hbp_handler", "RPC dispatch", map[string]interface{}{
		"op": frame.Op, "id": frame.ID,
	})

	switch frame.Op {
	case "matrix.get":
		return h.handleMatrixGet(frame)
	case "matrix.update":
		return h.handleMatrixUpdate(frame)
	case "compile":
		return h.handleCompile(frame)
	case "history.list":
		return h.handleHistoryList(frame)
	case "templates.list":
		return h.handleTemplatesList(frame)
	case "export.markdown":
		return h.handleExportMarkdown(frame)
	default:
		logger.Warn("hbp_handler", "unknown op", map[string]interface{}{"op": frame.Op})
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_UNKNOWN_OP")
	}
}

// handleMatrixGet loads the full ResumeMatrix and encodes it as msgpack.
func (h *Handler) handleMatrixGet(frame Frame) []byte {
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		logger.Error("hbp_handler", "matrix.get DB error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, matrix)
}

// normalizeDatesInItem runs NormalizeDate on any known date fields inside the
// generic map[string]interface{} item before it is persisted to SQLite.
func normalizeDatesInItem(item map[string]interface{}) {
	for _, key := range []string{"start_date", "end_date", "date"} {
		if v, ok := item[key]; ok {
			if s, ok := v.(string); ok {
				item[key] = dateutil.NormalizeDate(s)
			}
		}
	}
}

// handleMatrixUpdate processes upsert/delete/reorder actions on a resume section.
func (h *Handler) handleMatrixUpdate(frame Frame) []byte {
	var req struct {
		Section string                 `json:"section" msgpack:"section"`
		Action  string                 `json:"action" msgpack:"action"`
		Item    map[string]interface{} `json:"item" msgpack:"item"`
		ID      string                 `json:"id" msgpack:"id"`
	}
	if err := decodeMsgpackOrJSON(frame.P, &req); err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_MALFORMED_PAYLOAD")
	}

	// Normalize any date fields before persisting.
	if req.Item != nil {
		normalizeDatesInItem(req.Item)
	}

	newID, err := repository.UpdateSection("shua", req.Section, req.Action, req.Item, req.ID)
	if err != nil {
		logger.Error("hbp_handler", "matrix.update error", err, map[string]interface{}{
			"section": req.Section, "action": req.Action,
		})
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}

	logger.Info("hbp_handler", "matrix.update ok", map[string]interface{}{
		"section": req.Section, "action": req.Action, "id": newID,
	})
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{"ok": true, "id": newID})
}

// handleCompile runs the full PDF compile pipeline:
// 1. Load matrix
// 2. Optional Jaccard filter
// 3. Optional AI enhance via governor.ai.route
// 4. Typst compile → []byte PDF (markdown fallback on error)
// 5. vault.upload IPC → sha256 + vault_url
// 6. Save history row
// 7. Return ResumeCompileResponse
func (h *Handler) handleCompile(frame Frame) []byte {
	var req struct {
		MatrixID  string `json:"matrix_id" msgpack:"matrix_id"`
		Template  string `json:"template" msgpack:"template"`
		JobDesc   string `json:"job_desc" msgpack:"job_desc"`
		Tailor    bool   `json:"tailor" msgpack:"tailor"`
		AIEnhance bool   `json:"ai_enhance" msgpack:"ai_enhance"`
	}
	if err := decodeMsgpackOrJSON(frame.P, &req); err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_MALFORMED_PAYLOAD")
	}
	if req.Template == "" {
		req.Template = "default"
	}

	logger.Info("hbp_handler", "resume.compile dispatched", map[string]interface{}{
		"template": req.Template, "tailor": req.Tailor, "ai_enhance": req.AIEnhance,
	})

	start := time.Now()

	// 1. Load matrix
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}

	// 2. Jaccard filter
	var tailorScore *float32
	if req.Tailor && req.JobDesc != "" {
		cfg := ai.DefaultTailorConfig()
		cfg.UseAI = false // Jaccard only here
		_, score := ai.FilterResume(matrix, req.JobDesc, cfg)
		sf := float32(score)
		tailorScore = &sf
	}

	// 3. AI enhance
	if req.AIEnhance && req.JobDesc != "" {
		cfg := ai.DefaultTailorConfig()
		cfg.UseAI = true
		matrix = ai.TailorResumeViaGovernor(matrix, req.JobDesc, cfg, h.mcp.SendAIRoute)
	}

	// 4. Typst compile — markdown fallback on error
	var pdfBytes []byte
	var compileErr string
	pdfBytes, err = compiler.CompileTypst(matrix, req.Template)
	if err != nil {
		if strings.HasPrefix(err.Error(), "ERR_TYPST_UNAVAILABLE") {
			compileErr = "ERR_TYPST_UNAVAILABLE"
			// Fallback: encode markdown as UTF-8 bytes
			md := compiler.MatrixToMarkdown(matrix)
			pdfBytes = []byte(md)
			logger.Warn("compiler", "typst binary absent — markdown fallback activated", nil)
		} else {
			return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_COMPILE: %v", err))
		}
	}

	// 5. Vault upload via Governor IPC
	ts := time.Now().UTC().Format("20060102T150405")
	fileName := fmt.Sprintf("resume_%s.pdf", ts)
	mimeType := "application/pdf"
	if compileErr != "" {
		fileName = fmt.Sprintf("resume_%s.md", ts)
		mimeType = "text/markdown"
	}
	b64Data := base64.StdEncoding.EncodeToString(pdfBytes)
	sha256Hash, vaultURL, vaultErr := h.mcp.SendVaultUpload("resume", fileName, mimeType, b64Data)
	if vaultErr != nil {
		logger.Error("vault_ipc", "vault.upload IPC failed", vaultErr, map[string]interface{}{"file": fileName})
		// Use a local placeholder to avoid blocking the response
		sha256Hash = uuid.New().String()
		vaultURL = ""
	}

	// 6. Save history
	durationMs := uint32(time.Since(start).Milliseconds())
	history := models.HistoryItem{
		ExhibitId:   sha256Hash,
		VaultUrl:    vaultURL,
		TemplateId:  req.Template,
		JobDesc:     req.JobDesc,
		TailorScore: tailorScore,
		AiEnhanced:  req.AIEnhance,
		DurationMs:  durationMs,
		CompiledAt:  time.Now().UTC().Format(time.RFC3339),
	}
	if err := repository.SaveHistory(history); err != nil {
		logger.Error("hbp_handler", "save history error", err, nil)
	}

	logger.Info("hbp_handler", "resume.compile complete", map[string]interface{}{
		"exhibit_id": sha256Hash, "vault_url": vaultURL, "duration_ms": durationMs,
	})

	// 7. Response
	resp := map[string]interface{}{
		"1": sha256Hash,  // exhibit_id
		"2": vaultURL,    // pdf_url
		"3": durationMs,  // duration_ms
		"4": tailorScore, // tailor_score (nil if not tailored)
	}
	if compileErr != "" {
		resp["err"] = compileErr
		resp["p"] = string(pdfBytes) // markdown fallback text
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, resp)
}

// handleHistoryList returns the last 50 PDF compilation history rows.
func (h *Handler) handleHistoryList(frame Frame) []byte {
	items, err := repository.ListHistory()
	if err != nil {
		logger.Error("hbp_handler", "history.list error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{"items": items})
}

// handleTemplatesList returns the static list of available Typst templates.
func (h *Handler) handleTemplatesList(frame Frame) []byte {
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{
		"templates": mcp.AvailableTemplates,
	})
}

// handleExportMarkdown loads the current matrix and returns it as a Markdown string.
func (h *Handler) handleExportMarkdown(frame Frame) []byte {
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		logger.Error("hbp_handler", "export.markdown DB error", err, nil)
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	md := compiler.MatrixToMarkdown(matrix)
	logger.Info("hbp_handler", "export.markdown complete", map[string]interface{}{
		"bytes": len(md),
	})
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{"markdown": md})
}

// ── encode helpers ────────────────────────────────────────────────────────────

func encodeOK(id, mod, op string, payload interface{}) []byte {
	p, _ := msgpack.Marshal(payload)
	b64 := base64.StdEncoding.EncodeToString(p)
	frame := map[string]interface{}{
		"t":   2, // MessageTypeResponse
		"id":  id,
		"mod": mod,
		"op":  op,
		"p":   b64,
		"ts":  time.Now().UnixMilli(),
	}
	b, _ := json.Marshal(frame)
	return b
}

func encodeError(id, mod, op, errMsg string) []byte {
	frame := map[string]interface{}{
		"t":   6, // MessageTypeError
		"id":  id,
		"mod": mod,
		"op":  op,
		"err": errMsg,
		"ts":  time.Now().UnixMilli(),
	}
	b, _ := json.Marshal(frame)
	return b
}

// decodeMsgpackOrJSON tries msgpack first, falls back to JSON.
// decodeMsgpackOrJSON tries msgpack (Base64 or Int Array) first, falls back to JSON.
func decodeMsgpackOrJSON(raw json.RawMessage, dst interface{}) error {
	if len(raw) == 0 {
		return nil
	}

	// 1. Attempt Base64 + msgpack (HBP v2 canonical)
	var b64str string
	if err := json.Unmarshal(raw, &b64str); err == nil {
		decoded, err := base64.StdEncoding.DecodeString(b64str)
		if err == nil {
			if err := msgpack.Unmarshal(decoded, dst); err == nil {
				return nil
			}
		}
	}

	// 2. Attempt JSON array of integers (if Dart sent List<int> directly)
	var intArr []int
	if err := json.Unmarshal(raw, &intArr); err == nil {
		bytes := make([]byte, len(intArr))
		for i, v := range intArr {
			bytes[i] = byte(v)
		}
		if err := msgpack.Unmarshal(bytes, dst); err == nil {
			return nil
		}
	}

	// 3. Fallback: plain JSON object decoding
	err := json.Unmarshal(raw, dst)
	if err != nil {
		// Stop failing silently! Log the exact reason decoding failed.
		logger.Error("hbp_handler", "all payload decoders failed", err, map[string]interface{}{
			"raw_payload": string(raw),
		})
	}

	return err
}


<!-- END_FILE: shua_resume\pkg\hbp\hbp_handler.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\hbp\generated\hbp_enums.go -->
# FILE: hbp_enums.go
**Relative Path**: `shua_resume\pkg\hbp\generated\hbp_enums.go`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: tools/sync_contracts/schema/hbp_operations.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

package hbp


// Outer frame message type code
type MessageType int

const (
	MessageTypeRequest MessageType = 1
	MessageTypeResponse MessageType = 2
	MessageTypeEvent MessageType = 3
	MessageTypePing MessageType = 4
	MessageTypePong MessageType = 5
	MessageTypeError MessageType = 6
)

// High-level category for structured HbpError payloads
type ErrorCategory int

const (
	ErrorCategoryTransport ErrorCategory = 1
	ErrorCategoryAuthSecurity ErrorCategory = 2
	ErrorCategoryRpcRouting ErrorCategory = 3
	ErrorCategoryDatabase ErrorCategory = 4
	ErrorCategoryResourceExhaustion ErrorCategory = 5
	ErrorCategoryInternal ErrorCategory = 6
)

// Lifecycle state of a managed shua module process
type ModuleState int

const (
	ModuleStateRunning ModuleState = 1
	ModuleStateSleeping ModuleState = 2
	ModuleStateStopped ModuleState = 3
	ModuleStateUnknown ModuleState = 4
)

// AI router intent classification result
type IntentClass int

const (
	IntentClassFactualPrecision IntentClass = 1
	IntentClassReflectiveDialogue IntentClass = 2
	IntentClassCodeAst IntentClass = 3
	IntentClassCopilotCommand IntentClass = 4
)

// Universal Media Type Classifier for HBP Stream Packets
type StreamMediaType int

const (
	StreamMediaTypeLlmToken StreamMediaType = 1
	StreamMediaTypeAudioPcm StreamMediaType = 2
	StreamMediaTypeAudioOpus StreamMediaType = 3
	StreamMediaTypeVideoNal StreamMediaType = 4
	StreamMediaTypeVideoWebp StreamMediaType = 5
	StreamMediaTypeStepMilestone StreamMediaType = 6
	StreamMediaTypeTelemetryMetric StreamMediaType = 7
)


<!-- END_FILE: shua_resume\pkg\hbp\generated\hbp_enums.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\hbp\generated\hbp_models.go -->
# FILE: hbp_models.go
**Relative Path**: `shua_resume\pkg\hbp\generated\hbp_models.go`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: tools/sync_contracts/schema/hbp_operations.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

package hbp


// Single parameter signature representation
type ParamDto struct {
	Name string `msgpack:"name"`
	TypeName string `msgpack:"type_name"`
	IsOptional bool `msgpack:"is_optional"`
}

// Structured node representation for AST code topology
type GraphNode struct {
	Id string `msgpack:"id"`
	Kind string `msgpack:"kind"`
	QualifiedName string `msgpack:"qualified_name"`
	File string `msgpack:"file"`
	Line uint32 `msgpack:"line"`
	Params []ParamDto `msgpack:"params"`
	ReturnType string `msgpack:"return_type"`
	Complexity uint32 `msgpack:"complexity"`
	SideEffects []string `msgpack:"side_effects"`
	Intent string `msgpack:"intent"`
	Loc uint32 `msgpack:"loc"`
	FanIn uint32 `msgpack:"fan_in"`
	FanOut uint32 `msgpack:"fan_out"`
	RiskScore float32 `msgpack:"risk_score"`
	IsOrphan bool `msgpack:"is_orphan"`
	ExceedsParamThreshold bool `msgpack:"exceeds_param_threshold"`
	ExceedsComplexityThreshold bool `msgpack:"exceeds_complexity_threshold"`
	ExceedsLocThreshold bool `msgpack:"exceeds_loc_threshold"`
}

// Dependency call/import edge between symbols
type GraphEdge struct {
	From string `msgpack:"from"`
	To string `msgpack:"to"`
	Relation string `msgpack:"relation"`
}

// Full AST topology graph payload
type TopologyExportResponse struct {
	Nodes []GraphNode `msgpack:"nodes"`
	Edges []GraphEdge `msgpack:"edges"`
}

// Incremental code delta push on file change
type TopologyDeltaEvent struct {
	FilePath string `msgpack:"file_path"`
	ChangeType string `msgpack:"change_type"`
	AffectedNodeIds []string `msgpack:"affected_node_ids"`
}

// Standardized structured error payload for HBP v2 responses
type HbpError struct {
	// Standard error code (e.g. 400 bad request, 404 not found, 500 internal)
	Code uint16 `msgpack:"code"`
	// Error category enum code
	Category ErrorCategory `msgpack:"category"`
	// Human-readable error description
	Message string `msgpack:"message"`
	// Optional context details key-value map
	Details *map[string]string `msgpack:"details"`
}

// Universal HBP v2 message envelope — every message uses this outer shape
type HbpFrame struct {
	// Protocol version, always 2
	V uint8 `msgpack:"v"`
	// Message type code
	T MessageType `msgpack:"t"`
	// Transaction ID — UUID v4. RESPONSE echoes REQUEST id. EVENT generates its own.
	Id string `msgpack:"id"`
	// Module namespace e.g. shua.resume
	Mod string `msgpack:"mod"`
	// Operation name e.g. compile
	Op string `msgpack:"op"`
	// Timestamp of creation (UTC)
	Ts uint64 `msgpack:"ts"`
	// Payload bytes — msgpack-encoded operation body. Empty string for PING/PONG.
	P string `msgpack:"p"`
	// null on success. Structured error object on failure.
	Err *HbpError `msgpack:"err"`
}

// Standardized pagination metadata wrapper
type PaginationMeta struct {
	// Total matching items count
	TotalItems uint32 `msgpack:"total_items"`
	// True if additional pages exist
	HasMore bool `msgpack:"has_more"`
	// Current page index (0-indexed)
	Page uint32 `msgpack:"page"`
	// Items per page
	PageSize uint32 `msgpack:"page_size"`
}

// Server-pushed sentiment analysis event
type SentimentEvent struct {
	EntryId string `msgpack:"entry_id"`
	Score float32 `msgpack:"score"`
	Label string `msgpack:"label"`
}

// Server-pushed real-time entry update event for multi-device optimistic concurrency
type EntryUpdatedEvent struct {
	EntryId string `msgpack:"entry_id"`
	BlockId string `msgpack:"block_id"`
	Version uint32 `msgpack:"version"`
}

// Module process description and live telemetry returned in governor.status
type ModuleEntry struct {
	// Module namespace string e.g. shua.resume
	Name string `msgpack:"name"`
	// Current process state
	State ModuleState `msgpack:"state"`
	// OS Process ID if running or sleeping
	Pid *uint32 `msgpack:"pid"`
	// Current CPU load percentage
	CpuPercent *float32 `msgpack:"cpu_percent"`
	// Current RSS/cgroup memory usage in megabytes
	RamMb *float32 `msgpack:"ram_mb"`
	// Configured memory ceiling limit in megabytes
	RamLimitMb *uint32 `msgpack:"ram_limit_mb"`
	// Total process uptime in seconds
	UptimeS *uint64 `msgpack:"uptime_s"`
	// True if module process health check is passing
	HealthOk bool `msgpack:"health_ok"`
	// Number of auto-restarts following crashes
	RestartCount uint32 `msgpack:"restart_count"`
	// Most recent crash or exit reason description
	LastError *string `msgpack:"last_error"`
}

// Current Ollama subsystem state
type OllamaInfo struct {
	// Currently loaded model name or null
	LoadedModel *string `msgpack:"loaded_model"`
	// VRAM/RAM footprint of loaded model in MB
	RamMb *float32 `msgpack:"ram_mb"`
}

// Response payload for governor.status
type GovernorStatusResponse struct {
	// Array of all registered module states
	Modules []ModuleEntry `msgpack:"modules"`
	// Ollama lifecycle state
	Ollama OllamaInfo `msgpack:"ollama"`
}

// Request payload for governor.ollama.load
type OllamaLoadRequest struct {
	// Ollama model name e.g. qwen2.5:1.5b
	Model string `msgpack:"model"`
}

type OllamaLoadResponse struct {
	LoadedModel string `msgpack:"loaded_model"`
	RamMb float32 `msgpack:"ram_mb"`
	DurationMs uint32 `msgpack:"duration_ms"`
}

type ModuleWakeRequest struct {
	// Module namespace to wake e.g. shua.resume
	Module string `msgpack:"module"`
}

type AiRouteRequest struct {
	// User input prompt text
	Prompt string `msgpack:"prompt"`
	// Optional module domain hint e.g. diary
	ContextHint *string `msgpack:"context_hint"`
}

type AiRouteResponse struct {
	ModelUsed string `msgpack:"model_used"`
	Intent IntentClass `msgpack:"intent"`
	Reply string `msgpack:"reply"`
	DurationMs uint32 `msgpack:"duration_ms"`
	// List of agent loop turn step records
	Steps []AgentLoopStepDto `msgpack:"steps"`
}

// Record of a single tool call executed within an agent loop step
type ToolCallStepDto struct {
	// Name of the executed MCP tool
	ToolName string `msgpack:"tool_name"`
	// Truncated string summary of the tool execution output
	ResultSummary string `msgpack:"result_summary"`
	// True if tool executed successfully
	Success bool `msgpack:"success"`
}

// Record of a single turn iteration in the N-turn agent loop
type AgentLoopStepDto struct {
	// Turn iteration index (1..5)
	Turn uint32 `msgpack:"turn"`
	// Step category (tool_execution, inline_tool_execution, nudge, final_answer)
	StepType string `msgpack:"step_type"`
	// Raw LLM output text for this turn
	ModelContent string `msgpack:"model_content"`
	// List of tool calls executed during this turn
	ToolCalls []ToolCallStepDto `msgpack:"tool_calls"`
}

// System configuration settings payload returned/updated via governor.config.*
type GovernorConfigDto struct {
	// HBP WebSocket broker server port (default 7700)
	Port uint32 `msgpack:"port"`
	// Global log verbosity level (trace, debug, info, warn, error)
	LogLevel string `msgpack:"log_level"`
	// System timezone string (e.g. Asia/Manila)
	Timezone string `msgpack:"timezone"`
	// Optional laptop node URL for heavy AI offloading
	OffloadDeviceUrl *string `msgpack:"offload_device_url"`
	// Ollama model RAM ceiling cap in megabytes
	OllamaRamCapMb uint32 `msgpack:"ollama_ram_cap_mb"`
	// Nightly 02:00 AM maintenance dream loop toggle
	DreamLoopEnabled bool `msgpack:"dream_loop_enabled"`
	// Dream loop cron schedule expression
	DreamLoopCron string `msgpack:"dream_loop_cron"`
	// SQLite log database retention period in days
	LogRetentionDays uint32 `msgpack:"log_retention_days"`
}

// Universal HBP Stream Frame container for arbitrary data/media streams
type StreamFrameDto struct {
	// Media stream classification (LlmToken, AudioPcm, VideoNal, etc.)
	MediaType StreamMediaType `msgpack:"media_type"`
	// Monotonic chunk sequence index (0, 1, 2...)
	SequenceNum uint64 `msgpack:"sequence_num"`
	// UTF-8 text delta string or Base64/MsgPack binary data chunk
	ChunkData string `msgpack:"chunk_data"`
	// True if this chunk terminates the active stream
	IsLast bool `msgpack:"is_last"`
}

// Client WebSocket subscription filter for live log events
type LogFilter struct {
	// Minimum log level (1=TRACE..5=ERROR)
	MinLevel *uint8 `msgpack:"min_level"`
	// List of module namespaces to filter
	Modules *[]string `msgpack:"modules"`
	// Tag bitmask filter
	TagMask *uint32 `msgpack:"tag_mask"`
}

// Centralized log event entry payload
type LogEntryDto struct {
	// Timestamp of creation (UTC)
	Ts uint64 `msgpack:"ts"`
	// Log level (1=TRACE..5=ERROR)
	Level uint8 `msgpack:"level"`
	// Module ID
	Module uint8 `msgpack:"module"`
	// Subsystem component name
	Subsystem string `msgpack:"subsystem"`
	// Log message text
	Msg string `msgpack:"msg"`
	// Tag bitmask
	Tags uint32 `msgpack:"tags"`
	// Optional transaction trace ID
	TraceId *string `msgpack:"trace_id"`
}

// Request payload for governor.logs.query
type LogQueryRequestDto struct {
	MinLevel *uint8 `msgpack:"min_level"`
	Module *uint8 `msgpack:"module"`
	Subsystem *string `msgpack:"subsystem"`
	StartTs *uint64 `msgpack:"start_ts"`
	EndTs *uint64 `msgpack:"end_ts"`
	TraceId *string `msgpack:"trace_id"`
	Limit *uint32 `msgpack:"limit"`
	Offset *uint32 `msgpack:"offset"`
}

// Response payload for governor.logs.query
type LogQueryResponseDto struct {
	Total uint32 `msgpack:"total"`
	Entries []LogEntryDto `msgpack:"entries"`
}

// Request payload for resume.compile
type ResumeCompileRequest struct {
	// ID of resume matrix to compile
	MatrixId string `msgpack:"matrix_id"`
	// Typst template name
	Template string `msgpack:"template"`
	// Optional job description text for AI tailoring
	JobDesc *string `msgpack:"job_desc"`
	// Apply AI keyword tailoring filter
	Tailor bool `msgpack:"tailor"`
	// Apply full Ollama enhancement
	AiEnhance bool `msgpack:"ai_enhance"`
}

// Response payload for resume.compile
type ResumeCompileResponse struct {
	// CAS content-addressed ID of generated PDF
	ExhibitId string `msgpack:"exhibit_id"`
	// Accessible HTTP URL on Pi5
	PdfUrl string `msgpack:"pdf_url"`
	// Compilation time in milliseconds
	DurationMs uint32 `msgpack:"duration_ms"`
	// Jaccard similarity score if tailored
	TailorScore *float32 `msgpack:"tailor_score"`
}


<!-- END_FILE: shua_resume\pkg\hbp\generated\hbp_models.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\hbp\generated\hbp_ops.go -->
# FILE: hbp_ops.go
**Relative Path**: `shua_resume\pkg\hbp\generated\hbp_ops.go`

// AUTO-GENERATED by sync_contracts — DO NOT EDIT
// Source: tools/sync_contracts/schema/hbp_operations.toml
// HBP v2 — horAIzon Binary Protocol v2 — data-only, bidirectional RPC over WebSocket + MessagePack

package hbp


// HBP v2 operation key constants.
const (
	// Start the file-watcher daemon
	ShuaCodeVisualizerWatchStart = "shua.code_visualizer.watch.start"
	// Stop the file-watcher daemon
	ShuaCodeVisualizerWatchStop = "shua.code_visualizer.watch.stop"
	// Server-pushed incremental topology delta on file change
	ShuaCodeVisualizerChanged = "shua.code_visualizer.changed"
	// Heartbeat check — server responds with PONG frame
	ShuaGovernorPing = "shua.governor.ping"
	// Paginated diary entry list
	ShuaDiaryEntryList = "shua.diary.entry.list"
	// Single entry with all blocks
	ShuaDiaryEntryGet = "shua.diary.entry.get"
	// Create a new diary entry
	ShuaDiaryEntryCreate = "shua.diary.entry.create"
	// Upsert diary entry metadata or block array with optimistic version check
	ShuaDiaryEntrySave = "shua.diary.entry.save"
	// Delete a diary entry
	ShuaDiaryEntryDelete = "shua.diary.entry.delete"
	// Full-text search (FTS5) across diary entry text and block contents
	ShuaDiarySearch = "shua.diary.search"
	// Upload binary media file to Pi 5 Content-Addressable Media Vault
	ShuaDiaryMediaUpload = "shua.diary.media.upload"
	// Retrieve media file metadata and URL from Media Vault
	ShuaDiaryMediaGet = "shua.diary.media.get"
	// Upsert a block (debounced)
	ShuaDiaryBlockSave = "shua.diary.block.save"
	// Reorder blocks with LexoRank
	ShuaDiaryBlockReorder = "shua.diary.block.reorder"
	// Delete a diary block
	ShuaDiaryBlockDelete = "shua.diary.block.delete"
	// Server-pushed real-time entry update notification
	ShuaDiaryEntryUpdated = "shua.diary.entry.updated"
	// Server-pushed sentiment score after a block save
	ShuaDiarySentimentScore = "shua.diary.sentiment.score"
	// Elevate a diary entry to the Global Identity Matrix
	ShuaDiaryMemoryElevate = "shua.diary.memory.elevate"
	// Fetch lifecycle status of all supervised modules and Ollama
	ShuaGovernorStatus = "shua.governor.status"
	// Send SIGCONT to wake a sleeping module process
	ShuaGovernorModuleWake = "shua.governor.module.wake"
	// Send SIGSTOP to freeze a running module process
	ShuaGovernorModuleSleep = "shua.governor.module.sleep"
	// Fetch current Governor system configuration settings
	ShuaGovernorConfigGet = "shua.governor.config.get"
	// Update Governor system configuration settings and persist to config.toml
	ShuaGovernorConfigUpdate = "shua.governor.config.update"
	// Load a named Ollama model, evicting any previously loaded model
	ShuaGovernorOllamaLoad = "shua.governor.ollama.load"
	// Evict the currently loaded Ollama model (keep_alive: 0)
	ShuaGovernorOllamaEvict = "shua.governor.ollama.evict"
	// Route a prompt through the intent classifier and get an AI reply
	ShuaGovernorAiRoute = "shua.governor.ai.route"
	// Universal server-pushed stream packet for LLM tokens, Audio, Video, and Telemetry
	ShuaGovernorStreamChunk = "shua.governor.stream.chunk"
	// Server-pushed milestone event for agent turn changes and tool execution results
	ShuaGovernorStreamStep = "shua.governor.stream.step"
	// Subscribe or update WebSocket live log stream filter
	ShuaGovernorLogsSubscribe = "shua.governor.logs.subscribe"
	// Ingest client diagnostic log event into Governor
	ShuaGovernorLogEmit = "shua.governor.log.emit"
	// Query historical logs from SQLite LTM database
	ShuaGovernorLogsQuery = "shua.governor.logs.query"
	// Server-pushed live log event frame to subscribed WebSocket clients
	ShuaGovernorLogEvent = "shua.governor.log_event"
	// Compile a Typst PDF with optional AI tailoring
	ShuaResumeCompile = "shua.resume.compile"
	// Fetch the current resume matrix
	ShuaResumeMatrixGet = "shua.resume.matrix.get"
	// List past PDF compilations
	ShuaResumeHistoryList = "shua.resume.history.list"
	// List available Typst templates
	ShuaResumeTemplatesList = "shua.resume.templates.list"
)

// HBP v2 module namespace constants.
const (
	ShuaCodeVisualizer = "shua.code_visualizer"
	ShuaGovernor = "shua.governor"
	ShuaDiary = "shua.diary"
	ShuaResume = "shua.resume"
)

<!-- END_FILE: shua_resume\pkg\hbp\generated\hbp_ops.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\logger\logger.go -->
# FILE: logger.go
**Relative Path**: `shua_resume\pkg\logger\logger.go`

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


<!-- END_FILE: shua_resume\pkg\logger\logger.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\mcp\mcp_server.go -->
# FILE: mcp_server.go
**Relative Path**: `shua_resume\pkg\mcp\mcp_server.go`

// Package mcp manages the WebSocket IPC connection to the Governor (port 7701)
// and handles MCP tool call dispatch.
package mcp

import (
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"

	"shua_resume/pkg/ai"
	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
	"shua_resume/pkg/repository"
)

const (
	governorIPC = "ws://127.0.0.1:7701"
	moduleID    = "shua.resume"
	version     = "3.0.0"
	scope       = "resume"
)

// Server manages the IPC connection to the Governor.
type Server struct {
	mu      sync.Mutex
	conn    *websocket.Conn
	pending map[string]chan string // request_id -> reply channel
	// OnHBPFrame is called for incoming HBP frames forwarded from dispatcher.
	// Set by mcp_server.go after construction.
	OnHBPFrame func(raw []byte)
}

// New creates a disconnected Server. Call Connect() to establish the IPC link.
func New() *Server {
	return &Server{
		pending: make(map[string]chan string),
	}
}

// Connect dials the Governor IPC endpoint and registers the MCP manifest.
// Retries on failure with exponential backoff (max 30s).
func (s *Server) Connect() {
	backoff := time.Second
	for {
		if err := s.connect(); err != nil {
			logger.Warn("mcp_server", "IPC connect failed — retrying", map[string]interface{}{
				"backoff_s": backoff.Seconds(),
				"error":     err.Error(),
			})
			time.Sleep(backoff)
			if backoff < 30*time.Second {
				backoff *= 2
			}
			continue
		}
		logger.Info("mcp_server", "Connected to Governor IPC and registered MCP tools", nil)
		backoff = time.Second

		// Read loop — blocks until disconnected
		s.readLoop()

		logger.Warn("mcp_server", "IPC connection lost — reconnecting", nil)
		time.Sleep(2 * time.Second)
	}
}

func (s *Server) connect() error {
	conn, _, err := websocket.DefaultDialer.Dial(governorIPC, nil)
	if err != nil {
		return fmt.Errorf("dial %s: %w", governorIPC, err)
	}

	manifest := map[string]interface{}{
		"op":        "governor.mcp.register",
		"module_id": moduleID,
		"version":   version,
		"scope":     scope,
		"tools": []map[string]interface{}{
			{
				"name":        "resume_tailor_jaccard",
				"description": "Filters the active resume matrix against a job description using Jaccard token similarity. Returns a filtered ResumeMatrix with match score.",
				"scope":       scope,
				"timeout_s":   15,
				"input_schema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"job_desc":  map[string]string{"type": "string"},
						"threshold": map[string]interface{}{"type": "number", "description": "Minimum Jaccard score (0.0-1.0, default 0.15)"},
					},
					"required": []string{"job_desc"},
				},
			},
			{
				"name":        "resume_compile_pdf",
				"description": "Compiles the active resume matrix into a Typst PDF. Returns exhibit_id and vault URL for the PDF on Pi 5.",
				"scope":       scope,
				"timeout_s":   60,
				"input_schema": map[string]interface{}{
					"type": "object",
					"properties": map[string]interface{}{
						"template":   map[string]interface{}{"type": "string", "enum": []string{"default", "modern", "minimalist"}},
						"job_desc":   map[string]string{"type": "string"},
						"tailor":     map[string]string{"type": "boolean"},
						"ai_enhance": map[string]string{"type": "boolean"},
					},
					"required": []string{"template"},
				},
			},
		},
	}

	b, err := json.Marshal(manifest)
	if err != nil {
		conn.Close()
		return fmt.Errorf("marshal manifest: %w", err)
	}
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		conn.Close()
		return fmt.Errorf("send manifest: %w", err)
	}

	s.mu.Lock()
	s.conn = conn
	s.mu.Unlock()
	return nil
}

func (s *Server) readLoop() {
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn == nil {
		return
	}

	for {
		_, msg, err := conn.ReadMessage()
		if err != nil {
			logger.Warn("mcp_server", "IPC read error", map[string]interface{}{"error": err.Error()})
			return
		}

		// Try to parse as JSON to check if it's a tool call or RPC response
		var frame map[string]interface{}
		if err := json.Unmarshal(msg, &frame); err != nil {
			// Binary frame — forward to HBP handler
			if s.OnHBPFrame != nil {
				s.OnHBPFrame(msg)
			}
			continue
		}

		// Check for pending RPC reply (governor.ai.route response)
		id, _ := frame["id"].(string)
		if id != "" {
			s.mu.Lock()
			ch, ok := s.pending[id]
			s.mu.Unlock()
			if ok {
				reply, _ := frame["reply"].(string)
				if reply == "" {
					// Fallback: stringify the entire result
					if r, ok := frame["result"]; ok {
						b, _ := json.Marshal(r)
						reply = string(b)
					}
				}
				ch <- reply
				s.mu.Lock()
				delete(s.pending, id)
				s.mu.Unlock()
				continue
			}
		}

		// MCP tool call dispatch
		op, _ := frame["op"].(string)
		if op == "mcp.tool.call" || op == "tool_call" {
			s.handleToolCall(frame)
			continue
		}

		// Forward HBP JSON frame to the HBP handler
		if s.OnHBPFrame != nil {
			s.OnHBPFrame(msg)
		}
	}
}

func (s *Server) handleToolCall(frame map[string]interface{}) {
	callID, _ := frame["id"].(string)
	toolName, _ := frame["tool_name"].(string)
	params, _ := frame["params"].(map[string]interface{})
	if params == nil {
		params = make(map[string]interface{})
	}

	logger.Info("mcp_server", "MCP tool call received", map[string]interface{}{
		"tool": toolName, "call_id": callID,
	})

	var result interface{}
	var toolErr string

	switch toolName {
	case "resume_tailor_jaccard":
		matrix, err := repository.GetMatrix("shua")
		if err != nil {
			toolErr = fmt.Sprintf("get matrix: %v", err)
			break
		}
		jobDesc, _ := params["job_desc"].(string)
		threshold := 0.15
		if t, ok := params["threshold"].(float64); ok {
			threshold = t
		}
		cfg := ai.DefaultTailorConfig()
		cfg.MinScore = threshold
		filtered, score := ai.FilterResume(matrix, jobDesc, cfg)
		result = map[string]interface{}{
			"matrix":       filtered,
			"tailor_score": score,
		}

	default:
		toolErr = fmt.Sprintf("unknown tool: %s", toolName)
	}

	response := map[string]interface{}{
		"id":     callID,
		"status": "ok",
		"result": result,
	}
	if toolErr != "" {
		response["status"] = "error"
		response["error"] = toolErr
	}

	b, _ := json.Marshal(response)
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn != nil {
		if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
			logger.Error("mcp_server", "failed to send tool call response", err, map[string]interface{}{"call_id": callID})
		}
	}
}

// SendHBPReply writes a raw HBP response frame (already JSON-encoded by
// hbp.Handle via encodeOK/encodeError) back over the IPC WebSocket to
// Governor, which routes it back to the client that made the request.
func (s *Server) SendHBPReply(raw []byte) error {
	s.mu.Lock()
	conn := s.conn
	s.mu.Unlock()
	if conn == nil {
		return fmt.Errorf("IPC not connected")
	}
	return conn.WriteMessage(websocket.TextMessage, raw)
}

// SendVaultUpload sends a vault.upload IPC frame and waits for the Governor's response.
// Returns sha256_hash and vault_url.
func (s *Server) SendVaultUpload(module, fileName, mimeType, dataBase64 string) (string, string, error) {
	id := uuid.New().String()
	frame := map[string]interface{}{
		"op":          "vault.upload",
		"id":          id,
		"module":      module,
		"file_name":   fileName,
		"mime_type":   mimeType,
		"data_base64": dataBase64,
	}

	ch := make(chan string, 1)
	s.mu.Lock()
	s.pending[id] = ch
	conn := s.conn
	s.mu.Unlock()

	if conn == nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("IPC not connected")
	}

	b, _ := json.Marshal(frame)
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("send vault.upload: %w", err)
	}

	select {
	case reply := <-ch:
		var resp map[string]interface{}
		if err := json.Unmarshal([]byte(reply), &resp); err != nil {
			// Might already be parsed as the result map
			_ = err
		}
		// Try result field first, then top-level
		if result, ok := resp["result"].(map[string]interface{}); ok {
			sha256, _ := result["sha256_hash"].(string)
			url, _ := result["url"].(string)
			return sha256, url, nil
		}
		sha256, _ := resp["sha256_hash"].(string)
		url, _ := resp["url"].(string)
		return sha256, url, nil
	case <-time.After(15 * time.Second):
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", "", fmt.Errorf("vault.upload IPC timeout")
	}
}

// SendAIRoute sends a governor.ai.route HBP v2 RPC and returns the text reply.
// Used as the ipcSend callback in ai.TailorResumeViaGovernor.
func (s *Server) SendAIRoute(op string, payload map[string]interface{}) (string, error) {
	id := uuid.New().String()
	frame := map[string]interface{}{
		"op":     op,
		"id":     id,
		"mod":    "shua.governor",
		"prompt": payload["prompt"],
	}
	if hint, ok := payload["context_hint"].(string); ok {
		frame["context_hint"] = hint
	}

	ch := make(chan string, 1)
	s.mu.Lock()
	s.pending[id] = ch
	conn := s.conn
	s.mu.Unlock()

	if conn == nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("IPC not connected")
	}

	b, _ := json.Marshal(frame)
	if err := conn.WriteMessage(websocket.TextMessage, b); err != nil {
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("send ai.route: %w", err)
	}

	select {
	case reply := <-ch:
		return reply, nil
	case <-time.After(60 * time.Second):
		s.mu.Lock()
		delete(s.pending, id)
		s.mu.Unlock()
		return "", fmt.Errorf("governor.ai.route timeout")
	}
}

// TemplateInfo describes an available Typst template.
type TemplateInfo struct {
	Id          string `json:"id" msgpack:"id"`
	Name        string `json:"name" msgpack:"name"`
	Description string `json:"description" msgpack:"description"`
}

// AvailableTemplates is the static template list.
var AvailableTemplates = []TemplateInfo{
	{"default", "Default", "Clean ATS-friendly single-column layout"},
	{"modern", "Modern", "Two-column with sidebar for skills and education"},
	{"minimalist", "Minimalist", "Compact tight-layout for one-page resumes"},
}

// FilteredMatrix is the result of a Jaccard tailor operation.
type FilteredMatrix struct {
	Matrix      *models.ResumeMatrix `json:"matrix" msgpack:"matrix"`
	TailorScore float64              `json:"tailor_score" msgpack:"tailor_score"`
}


<!-- END_FILE: shua_resume\pkg\mcp\mcp_server.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\models\resume.go -->
# FILE: resume.go
**Relative Path**: `shua_resume\pkg\models\resume.go`

package models

// ResumeMatrix is the canonical resume data model for horAIzon 3.0.
type ResumeMatrix struct {
	Basics        Basics        `json:"basics"        msgpack:"basics"`
	Work          []WorkItem    `json:"work"          msgpack:"work"`
	Education     []Education   `json:"education"     msgpack:"education"`
	Projects      []ProjectItem `json:"projects"      msgpack:"projects"`
	Skills        []Skill       `json:"skills"        msgpack:"skills"`
	Certificates  []Certificate `json:"certificates"  msgpack:"certificates"`
	Awards        []Award       `json:"awards"        msgpack:"awards"`
	Organizations []OrgItem     `json:"organizations" msgpack:"organizations"`
}

// Basics holds primary contact and identity information.
type Basics struct {
	Name     string    `json:"name"          msgpack:"name"`
	Label    string    `json:"label"         msgpack:"label"`
	Email    string    `json:"email"         msgpack:"email"`
	Phone    string    `json:"phone"         msgpack:"phone"`
	Url      string    `json:"url,omitempty" msgpack:"url,omitempty"` // Deprecated: use Profiles
	Summary  string    `json:"summary"       msgpack:"summary"`
	Location Location  `json:"location"      msgpack:"location"`
	Profiles []Profile `json:"profiles"      msgpack:"profiles"`
}

// Location holds city, region, and country code.
type Location struct {
	Address     string `json:"address,omitempty" msgpack:"address,omitempty"`
	City        string `json:"city"              msgpack:"city"`
	Region      string `json:"region"            msgpack:"region"`
	CountryCode string `json:"country_code"      msgpack:"country_code"`
}

// Profile holds a social/professional profile link (GitHub, LinkedIn, Portfolio, etc.)
type Profile struct {
	Network  string `json:"network"  msgpack:"network"`
	Username string `json:"username" msgpack:"username"`
	Url      string `json:"url"      msgpack:"url"`
}

// WorkItem holds a single work experience entry.
type WorkItem struct {
	Id         string   `json:"id"         msgpack:"id"`
	Name       string   `json:"name"       msgpack:"name"`
	Position   string   `json:"position"   msgpack:"position"`
	Url        string   `json:"url"        msgpack:"url"`
	StartDate  string   `json:"start_date" msgpack:"start_date"`
	EndDate    string   `json:"end_date"   msgpack:"end_date"`
	Summary    string   `json:"summary"    msgpack:"summary"`
	Highlights []string `json:"highlights" msgpack:"highlights"`
	Keywords   []string `json:"keywords"   msgpack:"keywords"`
	Skills     []string `json:"skills"     msgpack:"skills"`
	Active     bool     `json:"active"     msgpack:"active"`
}

// Education holds a single education entry.
type Education struct {
	Id          string   `json:"id"          msgpack:"id"`
	Institution string   `json:"institution" msgpack:"institution"`
	Url         string   `json:"url"         msgpack:"url"`
	Area        string   `json:"area"        msgpack:"area"`
	StudyType   string   `json:"study_type"  msgpack:"study_type"`
	StartDate   string   `json:"start_date"  msgpack:"start_date"`
	EndDate     string   `json:"end_date"    msgpack:"end_date"`
	Score       string   `json:"score"       msgpack:"score"`
	Courses     []string `json:"courses"     msgpack:"courses"`
}

// ProjectItem holds a single project entry.
type ProjectItem struct {
	Id          string   `json:"id"          msgpack:"id"`
	Name        string   `json:"name"        msgpack:"name"`
	Description string   `json:"description" msgpack:"description"`
	Highlights  []string `json:"highlights"  msgpack:"highlights"`
	Keywords    []string `json:"keywords"    msgpack:"keywords"`
	Url         string   `json:"url"         msgpack:"url"`
	Exhibits    []string `json:"exhibits"    msgpack:"exhibits"`
	Active      bool     `json:"active"      msgpack:"active"`
}

// Skill holds a skill group with keywords.
type Skill struct {
	Id       string   `json:"id"       msgpack:"id"`
	Name     string   `json:"name"     msgpack:"name"`
	Level    string   `json:"level"    msgpack:"level"`
	Keywords []string `json:"keywords" msgpack:"keywords"`
}

// Certificate holds a professional certificate.
type Certificate struct {
	Id     string `json:"id"     msgpack:"id"`
	Name   string `json:"name"   msgpack:"name"`
	Issuer string `json:"issuer" msgpack:"issuer"`
	Date   string `json:"date"   msgpack:"date"`
	Url    string `json:"url"    msgpack:"url"`
}

// Award holds an award or recognition.
type Award struct {
	Id      string `json:"id"      msgpack:"id"`
	Title   string `json:"title"   msgpack:"title"`
	Date    string `json:"date"    msgpack:"date"`
	Sender  string `json:"awarder" msgpack:"awarder"`
	Summary string `json:"summary" msgpack:"summary"`
}

// OrgItem holds a single organizational / leadership experience entry.
type OrgItem struct {
	Id           string   `json:"id"           msgpack:"id"`
	Organization string   `json:"organization" msgpack:"organization"`
	Role         string   `json:"role"         msgpack:"role"`
	StartDate    string   `json:"start_date"   msgpack:"start_date"`
	EndDate      string   `json:"end_date"     msgpack:"end_date"`
	Summary      string   `json:"summary"      msgpack:"summary"`
	Highlights   []string `json:"highlights"   msgpack:"highlights"`
	Active       bool     `json:"active"       msgpack:"active"`
}

// HistoryItem is a single PDF compilation record stored in resume_history.
type HistoryItem struct {
	ExhibitId   string   `json:"exhibit_id"             msgpack:"exhibit_id"`
	VaultUrl    string   `json:"vault_url"              msgpack:"vault_url"`
	TemplateId  string   `json:"template_id"            msgpack:"template_id"`
	JobDesc     string   `json:"job_desc"               msgpack:"job_desc"`
	TailorScore *float32 `json:"tailor_score,omitempty" msgpack:"tailor_score"`
	AiEnhanced  bool     `json:"ai_enhanced"            msgpack:"ai_enhanced"`
	DurationMs  uint32   `json:"duration_ms"            msgpack:"duration_ms"`
	CompiledAt  string   `json:"compiled_at"            msgpack:"compiled_at"`
}


<!-- END_FILE: shua_resume\pkg\models\resume.go -->
================================================================================

<!-- START_FILE: shua_resume\pkg\repository\resume_repository.go -->
# FILE: resume_repository.go
**Relative Path**: `shua_resume\pkg\repository\resume_repository.go`

// Package repository provides CRUD operations against the SQLite resume tables.
// All functions use the shared db.DB connection (WAL mode, single open connection).
//
// Time Complexity: O(n) on row count per table, n <= 100 rows total.
// Space Complexity: O(n) for returned slices; O(1) per scalar operation.
package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"

	"shua_resume/pkg/db"
	"shua_resume/pkg/models"
)

// GetMatrix loads the full ResumeMatrix for the given userId from all tables.
func GetMatrix(userID string) (*models.ResumeMatrix, error) {
	matrix := &models.ResumeMatrix{}
	var err error

	// Basics
	matrix.Basics, err = getBasics(userID)
	if err != nil {
		return nil, fmt.Errorf("get basics: %w", err)
	}

	// Work
	matrix.Work, err = getWork(userID)
	if err != nil {
		return nil, fmt.Errorf("get work: %w", err)
	}

	// Education
	matrix.Education, err = getEducation(userID)
	if err != nil {
		return nil, fmt.Errorf("get education: %w", err)
	}

	// Projects
	matrix.Projects, err = getProjects(userID)
	if err != nil {
		return nil, fmt.Errorf("get projects: %w", err)
	}

	// Skills
	matrix.Skills, err = getSkills(userID)
	if err != nil {
		return nil, fmt.Errorf("get skills: %w", err)
	}

	// Certificates
	matrix.Certificates, err = getCertificates(userID)
	if err != nil {
		return nil, fmt.Errorf("get certificates: %w", err)
	}

	// Awards
	matrix.Awards, err = getAwards(userID)
	if err != nil {
		return nil, fmt.Errorf("get awards: %w", err)
	}

	// Organizations
	matrix.Organizations, err = getOrganizations(userID)
	if err != nil {
		return nil, fmt.Errorf("get organizations: %w", err)
	}

	return matrix, nil
}

func getBasics(userID string) (models.Basics, error) {
	var b models.Basics
	var profilesJSON string
	err := db.DB.QueryRow(`SELECT name,label,email,phone,url,summary,city,region,country_code,profiles_json FROM resume_basics WHERE user_id=?`, userID).
		Scan(&b.Name, &b.Label, &b.Email, &b.Phone, &b.Url, &b.Summary,
			&b.Location.City, &b.Location.Region, &b.Location.CountryCode, &profilesJSON)
	if err == sql.ErrNoRows {
		return b, nil
	}
	if err != nil {
		return b, err
	}
	_ = json.Unmarshal([]byte(profilesJSON), &b.Profiles)
	return b, nil
}

func getWork(userID string) ([]models.WorkItem, error) {
	rows, err := db.DB.Query(`SELECT id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active FROM resume_work WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.WorkItem
	for rows.Next() {
		var item models.WorkItem
		var highlightsJSON, keywordsJSON, skillsJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Name, &item.Position, &item.Url, &item.StartDate, &item.EndDate, &item.Summary, &highlightsJSON, &keywordsJSON, &skillsJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highlightsJSON), &item.Highlights)
		_ = json.Unmarshal([]byte(keywordsJSON), &item.Keywords)
		_ = json.Unmarshal([]byte(skillsJSON), &item.Skills)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		if item.Skills == nil {
			item.Skills = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.WorkItem{}
	}
	return items, rows.Err()
}

func getEducation(userID string) ([]models.Education, error) {
	rows, err := db.DB.Query(`SELECT id,institution,url,area,study_type,start_date,end_date,score,courses FROM resume_education WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Education
	for rows.Next() {
		var item models.Education
		var coursesJSON string
		if err := rows.Scan(&item.Id, &item.Institution, &item.Url, &item.Area, &item.StudyType, &item.StartDate, &item.EndDate, &item.Score, &coursesJSON); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(coursesJSON), &item.Courses)
		if item.Courses == nil {
			item.Courses = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Education{}
	}
	return items, rows.Err()
}

func getProjects(userID string) ([]models.ProjectItem, error) {
	rows, err := db.DB.Query(`SELECT id,name,description,highlights,keywords,url,exhibits,active FROM resume_projects WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.ProjectItem
	for rows.Next() {
		var item models.ProjectItem
		var highJSON, kwJSON, exhibJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Name, &item.Description, &highJSON, &kwJSON, &item.Url, &exhibJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highJSON), &item.Highlights)
		_ = json.Unmarshal([]byte(kwJSON), &item.Keywords)
		_ = json.Unmarshal([]byte(exhibJSON), &item.Exhibits)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		if item.Exhibits == nil {
			item.Exhibits = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.ProjectItem{}
	}
	return items, rows.Err()
}

func getSkills(userID string) ([]models.Skill, error) {
	rows, err := db.DB.Query(`SELECT id,name,level,keywords FROM resume_skills WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Skill
	for rows.Next() {
		var item models.Skill
		var kwJSON string
		if err := rows.Scan(&item.Id, &item.Name, &item.Level, &kwJSON); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(kwJSON), &item.Keywords)
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Skill{}
	}
	return items, rows.Err()
}

func getCertificates(userID string) ([]models.Certificate, error) {
	rows, err := db.DB.Query(`SELECT id,name,issuer,date,url FROM resume_certificates WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Certificate
	for rows.Next() {
		var item models.Certificate
		if err := rows.Scan(&item.Id, &item.Name, &item.Issuer, &item.Date, &item.Url); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Certificate{}
	}
	return items, rows.Err()
}

func getAwards(userID string) ([]models.Award, error) {
	rows, err := db.DB.Query(`SELECT id,title,date,awarder,summary FROM resume_awards WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Award
	for rows.Next() {
		var item models.Award
		if err := rows.Scan(&item.Id, &item.Title, &item.Date, &item.Sender, &item.Summary); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Award{}
	}
	return items, rows.Err()
}

func getOrganizations(userID string) ([]models.OrgItem, error) {
	rows, err := db.DB.Query(`SELECT id,organization,role,start_date,end_date,summary,highlights,active FROM resume_organizations WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		// Table may not exist on older deployments — return empty gracefully.
		return []models.OrgItem{}, nil
	}
	defer rows.Close()

	var items []models.OrgItem
	for rows.Next() {
		var item models.OrgItem
		var highJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Organization, &item.Role, &item.StartDate, &item.EndDate, &item.Summary, &highJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highJSON), &item.Highlights)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.OrgItem{}
	}
	return items, rows.Err()
}

// UpdateSection handles upsert, delete, and reorder actions for a named section.
func UpdateSection(userID, section, action string, item map[string]interface{}, id string) (string, error) {
	switch section {
	case "basics":
		return upsertBasics(userID, item)
	case "work":
		return upsertWork(userID, action, item, id)
	case "education":
		return upsertEducation(userID, action, item, id)
	case "projects":
		return upsertProject(userID, action, item, id)
	case "skills":
		return upsertSkill(userID, action, item, id)
	case "certificates":
		return upsertCertificate(userID, action, item, id)
	case "awards":
		return upsertAward(userID, action, item, id)
	case "organizations":
		return upsertOrganization(userID, action, item, id)
	default:
		return "", fmt.Errorf("unknown section: %s", section)
	}
}

func upsertBasics(userID string, item map[string]interface{}) (string, error) {
	now := time.Now().UTC().Format(time.RFC3339)

	// Unmarshal location and profiles from nested fields
	locMap, _ := item["location"].(map[string]interface{})
	city, _ := locMap["city"].(string)
	region, _ := locMap["region"].(string)
	countryCode, _ := locMap["country_code"].(string)

	profilesJSON := "[]"
	if p, ok := item["profiles"]; ok {
		b, _ := json.Marshal(p)
		profilesJSON = string(b)
	}

	_, err := db.DB.Exec(`INSERT INTO resume_basics
		(user_id,name,label,email,phone,url,summary,city,region,country_code,profiles_json,updated_at)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(user_id) DO UPDATE SET
			name=excluded.name, label=excluded.label, email=excluded.email,
			phone=excluded.phone, url=excluded.url, summary=excluded.summary,
			city=excluded.city, region=excluded.region, country_code=excluded.country_code,
			profiles_json=excluded.profiles_json, updated_at=excluded.updated_at`,
		userID,
		strField(item, "name"), strField(item, "label"),
		strField(item, "email"), strField(item, "phone"),
		strField(item, "url"), strField(item, "summary"),
		city, region, countryCode, profilesJSON, now,
	)
	return userID, err
}

func upsertWork(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_work WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	k, _ := json.Marshal(jsonArray(item, "keywords"))
	s, _ := json.Marshal(jsonArray(item, "skills"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_work
		(id,user_id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name, position=excluded.position, url=excluded.url,
			start_date=excluded.start_date, end_date=excluded.end_date, summary=excluded.summary,
			highlights=excluded.highlights, keywords=excluded.keywords, skills=excluded.skills, active=excluded.active`,
		itemID, userID,
		strField(item, "name"), strField(item, "position"), strField(item, "url"),
		strField(item, "start_date"), strField(item, "end_date"), strField(item, "summary"),
		string(h), string(k), string(s), active,
	)
	return itemID, err
}

func upsertEducation(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_education WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	c, _ := json.Marshal(jsonArray(item, "courses"))
	_, err := db.DB.Exec(`INSERT INTO resume_education
		(id,user_id,institution,url,area,study_type,start_date,end_date,score,courses)
		VALUES (?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			institution=excluded.institution, url=excluded.url, area=excluded.area,
			study_type=excluded.study_type, start_date=excluded.start_date,
			end_date=excluded.end_date, score=excluded.score, courses=excluded.courses`,
		itemID, userID,
		strField(item, "institution"), strField(item, "url"), strField(item, "area"),
		strField(item, "study_type"), strField(item, "start_date"), strField(item, "end_date"),
		strField(item, "score"), string(c),
	)
	return itemID, err
}

func upsertProject(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_projects WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	k, _ := json.Marshal(jsonArray(item, "keywords"))
	e, _ := json.Marshal(jsonArray(item, "exhibits"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_projects
		(id,user_id,name,description,highlights,keywords,url,exhibits,active)
		VALUES (?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name, description=excluded.description,
			highlights=excluded.highlights, keywords=excluded.keywords, url=excluded.url,
			exhibits=excluded.exhibits, active=excluded.active`,
		itemID, userID,
		strField(item, "name"), strField(item, "description"), string(h),
		string(k), strField(item, "url"), string(e), active,
	)
	return itemID, err
}

func upsertSkill(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_skills WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	kw, _ := json.Marshal(jsonArray(item, "keywords"))
	_, err := db.DB.Exec(`INSERT INTO resume_skills (id,user_id,name,level,keywords) VALUES (?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET name=excluded.name, level=excluded.level, keywords=excluded.keywords`,
		itemID, userID, strField(item, "name"), strField(item, "level"), string(kw),
	)
	return itemID, err
}

func upsertCertificate(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_certificates WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	_, err := db.DB.Exec(`INSERT INTO resume_certificates (id,user_id,name,issuer,date,url) VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET name=excluded.name, issuer=excluded.issuer, date=excluded.date, url=excluded.url`,
		itemID, userID,
		strField(item, "name"), strField(item, "issuer"), strField(item, "date"), strField(item, "url"),
	)
	return itemID, err
}

func upsertAward(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_awards WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	_, err := db.DB.Exec(`INSERT INTO resume_awards (id,user_id,title,date,awarder,summary) VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET title=excluded.title, date=excluded.date, awarder=excluded.awarder, summary=excluded.summary`,
		itemID, userID,
		strField(item, "title"), strField(item, "date"), strField(item, "awarder"), strField(item, "summary"),
	)
	return itemID, err
}

func upsertOrganization(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_organizations WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_organizations
		(id,user_id,organization,role,start_date,end_date,summary,highlights,active)
		VALUES (?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			organization=excluded.organization, role=excluded.role,
			start_date=excluded.start_date, end_date=excluded.end_date,
			summary=excluded.summary, highlights=excluded.highlights, active=excluded.active`,
		itemID, userID,
		strField(item, "organization"), strField(item, "role"),
		strField(item, "start_date"), strField(item, "end_date"),
		strField(item, "summary"), string(h), active,
	)
	return itemID, err
}

// ListHistory returns all PDF compilation history rows, newest first.
func ListHistory() ([]models.HistoryItem, error) {
	rows, err := db.DB.Query(`SELECT exhibit_id,vault_url,template_id,job_desc,tailor_score,ai_enhanced,duration_ms,compiled_at FROM resume_history ORDER BY compiled_at DESC LIMIT 50`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.HistoryItem
	for rows.Next() {
		var item models.HistoryItem
		var aiEnhanced int
		var tailorScore sql.NullFloat64
		if err := rows.Scan(&item.ExhibitId, &item.VaultUrl, &item.TemplateId, &item.JobDesc, &tailorScore, &aiEnhanced, &item.DurationMs, &item.CompiledAt); err != nil {
			return nil, err
		}
		item.AiEnhanced = aiEnhanced != 0
		if tailorScore.Valid {
			v := float32(tailorScore.Float64)
			item.TailorScore = &v
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.HistoryItem{}
	}
	return items, rows.Err()
}

// SaveHistory inserts a PDF compilation record into resume_history.
func SaveHistory(h models.HistoryItem) error {
	aiInt := 0
	if h.AiEnhanced {
		aiInt = 1
	}
	var tailorScore interface{}
	if h.TailorScore != nil {
		tailorScore = *h.TailorScore
	}
	_, err := db.DB.Exec(`INSERT INTO resume_history
		(exhibit_id,vault_url,template_id,job_desc,tailor_score,ai_enhanced,duration_ms,compiled_at) VALUES (?,?,?,?,?,?,?,?)
		ON CONFLICT(exhibit_id) DO UPDATE SET
			vault_url=excluded.vault_url, template_id=excluded.template_id, compiled_at=excluded.compiled_at`,
		h.ExhibitId, h.VaultUrl, h.TemplateId, h.JobDesc, tailorScore, aiInt, h.DurationMs, h.CompiledAt,
	)
	return err
}

// ── helpers ──────────────────────────────────────────────────────────────────

func strField(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func jsonArray(m map[string]interface{}, key string) []string {
	v, ok := m[key]
	if !ok {
		return []string{}
	}
	switch t := v.(type) {
	case []interface{}:
		out := make([]string, 0, len(t))
		for _, el := range t {
			if s, ok := el.(string); ok {
				out = append(out, s)
			}
		}
		return out
	case []string:
		return t
	}
	return []string{}
}


<!-- END_FILE: shua_resume\pkg\repository\resume_repository.go -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\resume_compile_response_dto.dart -->
# FILE: resume_compile_response_dto.dart
**Relative Path**: `client_flutter\lib\features\resume\resume_compile_response_dto.dart`

import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';

/// Response DTO for shua.resume.compile HBP v2 RPC.
///
/// The backend encodes the response with index-keyed msgpack:
///   1 → exhibit_id (str)
///   2 → pdf_url    (str)
///   3 → duration_ms (u32)
///   4 → tailor_score (f32?) — null if not tailored
///
/// Time: O(1) | Space: O(1)
class ResumeCompileResponseDto {
  final String exhibitId;
  final String vaultUrl;
  final int durationMs;
  final double? tailorScore;

  const ResumeCompileResponseDto({
    required this.exhibitId,
    required this.vaultUrl,
    required this.durationMs,
    this.tailorScore,
  });

  /// Decode from raw msgpack bytes (the `p` field of the HBP frame, after
  /// base64-decoding by the caller).
  factory ResumeCompileResponseDto.fromMsgpack(List<int> bytes) {
    final u = Unpacker(Uint8List.fromList(bytes));
    final len = u.unpackMapLength();

    String exhibitId = '';
    String vaultUrl = '';
    int durationMs = 0;
    double? tailorScore;

    for (var i = 0; i < len; i++) {
      // Keys may be integer indices OR strings — try both.
      dynamic key;
      try {
        key = u.unpackInt();
      } catch (_) {
        try {
          key = u.unpackString();
        } catch (_) {
          break;
        }
      }

      switch (key) {
        case 1:
        case '1':
          exhibitId = u.unpackString() ?? '';
        case 2:
        case '2':
          vaultUrl = u.unpackString() ?? '';
        case 3:
        case '3':
          durationMs = u.unpackInt() ?? 0;
        case 4:
        case '4':
          try {
            final d = u.unpackDouble();
            tailorScore = d;
          } catch (_) {
            // nil / absent — skip
            u.unpackString(); // consume nil token
          }
        default:
          // Unknown key — consume value and skip
          try {
            u.unpackString();
          } catch (_) {
            try {
              u.unpackInt();
            } catch (_) {}
          }
      }
    }

    return ResumeCompileResponseDto(
      exhibitId: exhibitId,
      vaultUrl: vaultUrl,
      durationMs: durationMs,
      tailorScore: tailorScore,
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\resume_compile_response_dto.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\resume_history_item_dto.dart -->
# FILE: resume_history_item_dto.dart
**Relative Path**: `client_flutter\lib\features\resume\resume_history_item_dto.dart`

/// History item DTO for shua.resume.history.list HBP v2 RPC response.
///
/// Each item in the `items` list maps directly to a `resume_history` SQLite
/// row via the Go `HistoryItem` struct (string-keyed msgpack).
class ResumeHistoryItemDto {
  final String exhibitId;
  final String vaultUrl;
  final String templateId;
  final String jobDesc;
  final double? tailorScore;
  final bool aiEnhanced;
  final int durationMs;
  final DateTime compiledAt;

  const ResumeHistoryItemDto({
    required this.exhibitId,
    required this.vaultUrl,
    required this.templateId,
    required this.jobDesc,
    this.tailorScore,
    required this.aiEnhanced,
    required this.durationMs,
    required this.compiledAt,
  });

  factory ResumeHistoryItemDto.fromMap(Map<dynamic, dynamic> m) {
    DateTime parsedAt;
    try {
      parsedAt = DateTime.parse((m['compiled_at'] ?? '') as String);
    } catch (_) {
      parsedAt = DateTime.now();
    }

    double? score;
    final rawScore = m['tailor_score'];
    if (rawScore is double) {
      score = rawScore;
    } else if (rawScore is num) {
      score = rawScore.toDouble();
    }

    return ResumeHistoryItemDto(
      exhibitId: (m['exhibit_id'] ?? '') as String,
      vaultUrl: (m['vault_url'] ?? '') as String,
      templateId: (m['template_id'] ?? '') as String,
      jobDesc: (m['job_desc'] ?? '') as String,
      tailorScore: score,
      aiEnhanced: (m['ai_enhanced'] ?? false) as bool,
      durationMs: ((m['duration_ms'] ?? 0) as num).toInt(),
      compiledAt: parsedAt,
    );
  }

  /// Formatted date string for display: "Aug 4, 2026"
  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[compiledAt.month - 1]} ${compiledAt.day}, ${compiledAt.year}';
  }

  /// Duration in seconds, formatted: "1.2s"
  String get formattedDuration =>
      '${(durationMs / 1000).toStringAsFixed(1)}s';

  /// File name for download/share: "resume_default_20260804.pdf"
  String get fileName =>
      'resume_${templateId}_'
      '${compiledAt.year}'
      '${compiledAt.month.toString().padLeft(2, '0')}'
      '${compiledAt.day.toString().padLeft(2, '0')}.pdf';
}


<!-- END_FILE: client_flutter\lib\features\resume\resume_history_item_dto.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\resume_matrix_dto.dart -->
# FILE: resume_matrix_dto.dart
**Relative Path**: `client_flutter\lib\features\resume\resume_matrix_dto.dart`

import 'dart:convert';
import 'dart:typed_data';
import 'package:messagepack/messagepack.dart';

// ---------------------------------------------------------------------------
// Location & Profile
// ---------------------------------------------------------------------------

class LocationDto {
  final String city;
  final String region;
  final String countryCode;

  const LocationDto({
    this.city = '',
    this.region = '',
    this.countryCode = '',
  });

  factory LocationDto.fromMap(Map<dynamic, dynamic> m) => LocationDto(
        city: (m['city'] ?? '') as String,
        region: (m['region'] ?? '') as String,
        countryCode: (m['country_code'] ?? m['countryCode'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'city': city,
        'region': region,
        'country_code': countryCode,
      };
}

class ProfileDto {
  final String network;
  final String username;
  final String url;

  const ProfileDto({this.network = '', this.username = '', this.url = ''});

  factory ProfileDto.fromMap(Map<dynamic, dynamic> m) => ProfileDto(
        network: (m['network'] ?? '') as String,
        username: (m['username'] ?? '') as String,
        url: (m['url'] ?? '') as String,
      );

  Map<String, dynamic> toMap() =>
      {'network': network, 'username': username, 'url': url};
}

// ---------------------------------------------------------------------------
// Basics
// ---------------------------------------------------------------------------

class BasicsDto {
  final String name;
  final String label;
  final String email;
  final String phone;
  final String url;
  final String summary;
  final LocationDto location;
  final List<ProfileDto> profiles;

  const BasicsDto({
    this.name = '',
    this.label = '',
    this.email = '',
    this.phone = '',
    this.url = '',
    this.summary = '',
    this.location = const LocationDto(),
    this.profiles = const [],
  });

  factory BasicsDto.fromMap(Map<dynamic, dynamic> m) => BasicsDto(
        name: (m['name'] ?? '') as String,
        label: (m['label'] ?? '') as String,
        email: (m['email'] ?? '') as String,
        phone: (m['phone'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
        location: m['location'] is Map
            ? LocationDto.fromMap(m['location'] as Map)
            : const LocationDto(),
        profiles: (m['profiles'] as List? ?? [])
            .whereType<Map>()
            .map(ProfileDto.fromMap)
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'label': label,
        'email': email,
        'phone': phone,
        'url': url,
        'summary': summary,
        'location': location.toMap(),
        'profiles': profiles.map((p) => p.toMap()).toList(),
      };

  BasicsDto copyWith({
    String? name,
    String? label,
    String? email,
    String? phone,
    String? url,
    String? summary,
    LocationDto? location,
    List<ProfileDto>? profiles,
  }) =>
      BasicsDto(
        name: name ?? this.name,
        label: label ?? this.label,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        url: url ?? this.url,
        summary: summary ?? this.summary,
        location: location ?? this.location,
        profiles: profiles ?? this.profiles,
      );
}

// ---------------------------------------------------------------------------
// WorkItemDto
// ---------------------------------------------------------------------------

class WorkItemDto {
  final String id;
  final String name;
  final String position;
  final String url;
  final String startDate;
  final String endDate;
  final String summary;
  final List<String> highlights;
  final List<String> keywords;
  final List<String> skills;
  final bool active;

  const WorkItemDto({
    this.id = '',
    this.name = '',
    this.position = '',
    this.url = '',
    this.startDate = '',
    this.endDate = '',
    this.summary = '',
    this.highlights = const [],
    this.keywords = const [],
    this.skills = const [],
    this.active = true,
  });

  factory WorkItemDto.fromMap(Map<dynamic, dynamic> m) => WorkItemDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        position: (m['position'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        startDate: (m['start_date'] ?? m['startDate'] ?? '') as String,
        endDate: (m['end_date'] ?? m['endDate'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
        highlights: _strList(m['highlights']),
        keywords: _strList(m['keywords']),
        skills: _strList(m['skills']),
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'position': position,
        'url': url,
        'start_date': startDate,
        'end_date': endDate,
        'summary': summary,
        'highlights': highlights,
        'keywords': keywords,
        'skills': skills,
        'active': active,
      };

  WorkItemDto copyWith({
    String? id,
    String? name,
    String? position,
    String? url,
    String? startDate,
    String? endDate,
    String? summary,
    List<String>? highlights,
    List<String>? keywords,
    List<String>? skills,
    bool? active,
  }) =>
      WorkItemDto(
        id: id ?? this.id,
        name: name ?? this.name,
        position: position ?? this.position,
        url: url ?? this.url,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        summary: summary ?? this.summary,
        highlights: highlights ?? this.highlights,
        keywords: keywords ?? this.keywords,
        skills: skills ?? this.skills,
        active: active ?? this.active,
      );
}

// ---------------------------------------------------------------------------
// EducationDto
// ---------------------------------------------------------------------------

class EducationDto {
  final String id;
  final String institution;
  final String url;
  final String area;
  final String studyType;
  final String startDate;
  final String endDate;
  final String score;
  final List<String> courses;

  const EducationDto({
    this.id = '',
    this.institution = '',
    this.url = '',
    this.area = '',
    this.studyType = '',
    this.startDate = '',
    this.endDate = '',
    this.score = '',
    this.courses = const [],
  });

  factory EducationDto.fromMap(Map<dynamic, dynamic> m) => EducationDto(
        id: (m['id'] ?? '') as String,
        institution: (m['institution'] ?? '') as String,
        url: (m['url'] ?? '') as String,
        area: (m['area'] ?? '') as String,
        studyType: (m['study_type'] ?? m['studyType'] ?? '') as String,
        startDate: (m['start_date'] ?? m['startDate'] ?? '') as String,
        endDate: (m['end_date'] ?? m['endDate'] ?? '') as String,
        score: (m['score'] ?? '') as String,
        courses: _strList(m['courses']),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'institution': institution,
        'url': url,
        'area': area,
        'study_type': studyType,
        'start_date': startDate,
        'end_date': endDate,
        'score': score,
        'courses': courses,
      };

  EducationDto copyWith({
    String? id,
    String? institution,
    String? url,
    String? area,
    String? studyType,
    String? startDate,
    String? endDate,
    String? score,
    List<String>? courses,
  }) =>
      EducationDto(
        id: id ?? this.id,
        institution: institution ?? this.institution,
        url: url ?? this.url,
        area: area ?? this.area,
        studyType: studyType ?? this.studyType,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        score: score ?? this.score,
        courses: courses ?? this.courses,
      );
}

// ---------------------------------------------------------------------------
// ProjectItemDto
// ---------------------------------------------------------------------------

class ProjectItemDto {
  final String id;
  final String name;
  final String description;
  final List<String> highlights;
  final List<String> keywords;
  final String url;
  final List<String> exhibits;
  final bool active;

  const ProjectItemDto({
    this.id = '',
    this.name = '',
    this.description = '',
    this.highlights = const [],
    this.keywords = const [],
    this.url = '',
    this.exhibits = const [],
    this.active = true,
  });

  factory ProjectItemDto.fromMap(Map<dynamic, dynamic> m) => ProjectItemDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        description: (m['description'] ?? '') as String,
        highlights: _strList(m['highlights']),
        keywords: _strList(m['keywords']),
        url: (m['url'] ?? '') as String,
        exhibits: _strList(m['exhibits']),
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'highlights': highlights,
        'keywords': keywords,
        'url': url,
        'exhibits': exhibits,
        'active': active,
      };

  ProjectItemDto copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? highlights,
    List<String>? keywords,
    String? url,
    List<String>? exhibits,
    bool? active,
  }) =>
      ProjectItemDto(
        id: id ?? this.id,
        name: name ?? this.name,
        description: description ?? this.description,
        highlights: highlights ?? this.highlights,
        keywords: keywords ?? this.keywords,
        url: url ?? this.url,
        exhibits: exhibits ?? this.exhibits,
        active: active ?? this.active,
      );
}

// ---------------------------------------------------------------------------
// SkillDto
// ---------------------------------------------------------------------------

class SkillDto {
  final String id;
  final String name;
  final String level;
  final List<String> keywords;

  const SkillDto({
    this.id = '',
    this.name = '',
    this.level = '',
    this.keywords = const [],
  });

  factory SkillDto.fromMap(Map<dynamic, dynamic> m) => SkillDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        level: (m['level'] ?? '') as String,
        keywords: _strList(m['keywords']),
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'level': level, 'keywords': keywords};

  SkillDto copyWith({
    String? id,
    String? name,
    String? level,
    List<String>? keywords,
  }) =>
      SkillDto(
        id: id ?? this.id,
        name: name ?? this.name,
        level: level ?? this.level,
        keywords: keywords ?? this.keywords,
      );
}

// ---------------------------------------------------------------------------
// CertificateDto
// ---------------------------------------------------------------------------

class CertificateDto {
  final String id;
  final String name;
  final String issuer;
  final String date;
  final String url;

  const CertificateDto({
    this.id = '',
    this.name = '',
    this.issuer = '',
    this.date = '',
    this.url = '',
  });

  factory CertificateDto.fromMap(Map<dynamic, dynamic> m) => CertificateDto(
        id: (m['id'] ?? '') as String,
        name: (m['name'] ?? '') as String,
        issuer: (m['issuer'] ?? '') as String,
        date: (m['date'] ?? '') as String,
        url: (m['url'] ?? '') as String,
      );

  Map<String, dynamic> toMap() =>
      {'id': id, 'name': name, 'issuer': issuer, 'date': date, 'url': url};

  CertificateDto copyWith({
    String? id,
    String? name,
    String? issuer,
    String? date,
    String? url,
  }) =>
      CertificateDto(
        id: id ?? this.id,
        name: name ?? this.name,
        issuer: issuer ?? this.issuer,
        date: date ?? this.date,
        url: url ?? this.url,
      );
}

// ---------------------------------------------------------------------------
// AwardDto
// ---------------------------------------------------------------------------

class AwardDto {
  final String id;
  final String title;
  final String date;
  final String awarder;
  final String summary;

  const AwardDto({
    this.id = '',
    this.title = '',
    this.date = '',
    this.awarder = '',
    this.summary = '',
  });

  factory AwardDto.fromMap(Map<dynamic, dynamic> m) => AwardDto(
        id: (m['id'] ?? '') as String,
        title: (m['title'] ?? '') as String,
        date: (m['date'] ?? '') as String,
        awarder: (m['awarder'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'date': date,
        'awarder': awarder,
        'summary': summary,
      };

  AwardDto copyWith({
    String? id,
    String? title,
    String? date,
    String? awarder,
    String? summary,
  }) =>
      AwardDto(
        id: id ?? this.id,
        title: title ?? this.title,
        date: date ?? this.date,
        awarder: awarder ?? this.awarder,
        summary: summary ?? this.summary,
      );
}

// ---------------------------------------------------------------------------
// OrgItemDto
// ---------------------------------------------------------------------------

class OrgItemDto {
  final String id;
  final String organization;
  final String role;
  final String startDate;
  final String endDate;
  final String summary;
  final List<String> highlights;
  final bool active;

  const OrgItemDto({
    this.id = '',
    this.organization = '',
    this.role = '',
    this.startDate = '',
    this.endDate = '',
    this.summary = '',
    this.highlights = const [],
    this.active = true,
  });

  factory OrgItemDto.fromMap(Map<dynamic, dynamic> m) => OrgItemDto(
        id: (m['id'] ?? '') as String,
        organization: (m['organization'] ?? '') as String,
        role: (m['role'] ?? '') as String,
        startDate: (m['start_date'] ?? '') as String,
        endDate: (m['end_date'] ?? '') as String,
        summary: (m['summary'] ?? '') as String,
        highlights: _strList(m['highlights']),
        active: (m['active'] ?? true) as bool,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'organization': organization,
        'role': role,
        'start_date': startDate,
        'end_date': endDate,
        'summary': summary,
        'highlights': highlights,
        'active': active,
      };

  OrgItemDto copyWith({
    String? id,
    String? organization,
    String? role,
    String? startDate,
    String? endDate,
    String? summary,
    List<String>? highlights,
    bool? active,
  }) =>
      OrgItemDto(
        id: id ?? this.id,
        organization: organization ?? this.organization,
        role: role ?? this.role,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        summary: summary ?? this.summary,
        highlights: highlights ?? this.highlights,
        active: active ?? this.active,
      );
}

// ---------------------------------------------------------------------------
// ResumeMatrixDto
// ---------------------------------------------------------------------------

class ResumeMatrixDto {
  final BasicsDto basics;
  final List<WorkItemDto> work;
  final List<EducationDto> education;
  final List<ProjectItemDto> projects;
  final List<SkillDto> skills;
  final List<CertificateDto> certificates;
  final List<AwardDto> awards;
  final List<OrgItemDto> organizations;

  const ResumeMatrixDto({
    this.basics = const BasicsDto(),
    this.work = const [],
    this.education = const [],
    this.projects = const [],
    this.skills = const [],
    this.certificates = const [],
    this.awards = const [],
    this.organizations = const [],
  });

  /// Decode from base64-encoded msgpack bytes (as received in HBP v2 `p` field).
  /// The backend encodes the response payload as msgpack, then base64-encodes it.
  factory ResumeMatrixDto.fromBase64Msgpack(List<int> bytes) {
    // The HBP frame payload arrives as raw msgpack bytes
    final u = Unpacker(Uint8List.fromList(bytes));
    final len = u.unpackMapLength();
    final map = <dynamic, dynamic>{};
    for (var i = 0; i < len; i++) {
      final key = u.unpackString();
      if (key == null) continue;
      map[key] = _unpackValue(u);
    }
    return ResumeMatrixDto.fromMap(map);
  }

  factory ResumeMatrixDto.fromMap(Map<dynamic, dynamic> m) => ResumeMatrixDto(
        basics: m['basics'] is Map
            ? BasicsDto.fromMap(m['basics'] as Map)
            : const BasicsDto(),
        work: (m['work'] as List? ?? [])
            .whereType<Map>()
            .map(WorkItemDto.fromMap)
            .toList(),
        education: (m['education'] as List? ?? [])
            .whereType<Map>()
            .map(EducationDto.fromMap)
            .toList(),
        projects: (m['projects'] as List? ?? [])
            .whereType<Map>()
            .map(ProjectItemDto.fromMap)
            .toList(),
        skills: (m['skills'] as List? ?? [])
            .whereType<Map>()
            .map(SkillDto.fromMap)
            .toList(),
        certificates: (m['certificates'] as List? ?? [])
            .whereType<Map>()
            .map(CertificateDto.fromMap)
            .toList(),
        awards: (m['awards'] as List? ?? [])
            .whereType<Map>()
            .map(AwardDto.fromMap)
            .toList(),
        organizations: (m['organizations'] as List? ?? [])
            .whereType<Map>()
            .map(OrgItemDto.fromMap)
            .toList(),
      );

  ResumeMatrixDto copyWith({
    BasicsDto? basics,
    List<WorkItemDto>? work,
    List<EducationDto>? education,
    List<ProjectItemDto>? projects,
    List<SkillDto>? skills,
    List<CertificateDto>? certificates,
    List<AwardDto>? awards,
    List<OrgItemDto>? organizations,
  }) =>
      ResumeMatrixDto(
        basics: basics ?? this.basics,
        work: work ?? this.work,
        education: education ?? this.education,
        projects: projects ?? this.projects,
        skills: skills ?? this.skills,
        certificates: certificates ?? this.certificates,
        awards: awards ?? this.awards,
        organizations: organizations ?? this.organizations,
      );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

List<String> _strList(dynamic v) {
  if (v is List) return v.whereType<String>().toList();
  return [];
}

/// Recursively unpack a msgpack value into a Dart object.
dynamic _unpackValue(Unpacker u) {
  // We can't peek the type byte, so we rely on the messagepack library's unpack
  // order. Use a try-cascade approach on the unpacker.
  // For map values in the resume schema we try the most likely types in order.
  try {
    return u.unpackString();
  } catch (_) {}
  // Fallback for non-string values handled by caller context — in practice
  // the ResumeMatrix is fully string-keyed so map values are strings, lists,
  // booleans, or nested maps. The Unpacker advances its cursor on each call,
  // so we cannot retry. Instead, the calling code iterates known keys and
  // uses specialised decoders. This helper is only used for the top-level map
  // scan where we skip unknown keys.
  return null;
}

/// Decode HBP v2 payload bytes (raw msgpack from the frame's `p` field) into a
/// dynamic Dart Map. The Go backend uses vmihailenco/msgpack which serialises
/// struct fields with their msgpack tag keys (string-keyed map).
Map<dynamic, dynamic> decodeMsgpackMap(List<int> bytes) {
  if (bytes.isEmpty) return {};
  final u = Unpacker(Uint8List.fromList(bytes));
  return _unpackMap(u);
}

Map<dynamic, dynamic> _unpackMap(Unpacker u) {
  final len = u.unpackMapLength();
  final map = <dynamic, dynamic>{};
  for (var i = 0; i < len; i++) {
    final key = _unpackAny(u);
    final val = _unpackAny(u);
    if (key != null) map[key] = val;
  }
  return map;
}

List<dynamic> _unpackList(Unpacker u) {
  final len = u.unpackListLength();
  return List.generate(len, (_) => _unpackAny(u));
}

/// Full-featured recursive msgpack value unpacker.
dynamic _unpackAny(Unpacker u) {
  // Peek at first byte to determine type
  final raw = u;
  // Try bool first (nil/bool are single bytes in msgpack)
  // The messagepack package exposes unpackBool / unpackString / unpackInt /
  // unpackDouble / unpackBinary / unpackListLength / unpackMapLength.
  // We probe in order of likely type.
  // NOTE: The Unpacker cursor advances on every call so we must be careful.
  // We use a JSON round-trip via the base64 payload for robustness.
  // This is called with already-decoded bytes so JSON is not applicable.
  // Strategy: call unpackString; if that throws, we've advanced the cursor
  // so we can't recover without raw byte access. Instead we use the known
  // schema structure and specialised fromMap factories above.
  try {
    final s = raw.unpackString();
    return s; // null means msgpack nil
  } catch (_) {
    try {
      final i = raw.unpackInt();
      return i;
    } catch (_) {
      try {
        final d = raw.unpackDouble();
        return d;
      } catch (_) {
        try {
          return _unpackMap(raw);
        } catch (_) {
          try {
            return _unpackList(raw);
          } catch (_) {
            return null;
          }
        }
      }
    }
  }
}

/// Decode base64 string → raw bytes (used when backend wraps payload in base64).
List<int> decodeBase64Payload(String b64) => base64.decode(b64);


<!-- END_FILE: client_flutter\lib\features\resume\resume_matrix_dto.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\resume_screen.dart -->
# FILE: resume_screen.dart
**Relative Path**: `client_flutter\lib\features\resume\resume_screen.dart`

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/resume_compile_screen.dart';
import 'screens/resume_editor_screen.dart';
import 'screens/resume_history_screen.dart';
import 'providers/resume_history_provider.dart';

// ---------------------------------------------------------------------------
// Tab index provider — used to allow programmatic tab switching
// ---------------------------------------------------------------------------

/// Local tab index for the ResumeScreen bottom nav.
/// Navigation between tabs is LOCAL state — NOT GoRouter push —
/// to preserve scroll position and avoid rebuild cost.
final _resumeTabIndexProvider = StateProvider<int>((ref) => 0);

/// ResumeScreen tab shell with Editor / Compile / History bottom nav.
///
/// Tab navigation is local (StatefulWidget index) — not GoRouter push.
class ResumeScreen extends ConsumerWidget {
  const ResumeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = ref.watch(_resumeTabIndexProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Builder'),
        actions: [
          if (tabIndex == 2)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Refresh history',
              onPressed: () => ref.invalidate(resumeHistoryProvider),
            ),
        ],
      ),
      body: IndexedStack(
        index: tabIndex,
        children: [
          const ResumeEditorScreen(),
          ResumeCompileScreen(
            onCompileSuccess: () =>
                ref.read(_resumeTabIndexProvider.notifier).state = 2,
          ),
          const ResumeHistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: (i) =>
            ref.read(_resumeTabIndexProvider.notifier).state = i,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note_rounded),
            label: 'Editor',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome_rounded),
            label: 'Compile',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\resume_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\providers\resume_compile_provider.dart -->
# FILE: resume_compile_provider.dart
**Relative Path**: `client_flutter\lib\features\resume\providers\resume_compile_provider.dart`

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_compile_response_dto.dart';
import 'resume_history_provider.dart';

// ---------------------------------------------------------------------------
// Compile state machine
// ---------------------------------------------------------------------------

sealed class ResumeCompileState {
  const ResumeCompileState();
}

class CompileIdle extends ResumeCompileState {
  const CompileIdle();
}

class CompileInProgress extends ResumeCompileState {
  final bool aiEnhance;
  const CompileInProgress({this.aiEnhance = false});
}

class CompileSuccess extends ResumeCompileState {
  final ResumeCompileResponseDto result;
  const CompileSuccess(this.result);
}

class CompileError extends ResumeCompileState {
  final String message;
  const CompileError(this.message);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final resumeCompileProvider =
    StateNotifierProvider<ResumeCompileNotifier, ResumeCompileState>(
  (ref) => ResumeCompileNotifier(ref),
);

/// Simple providers for compile screen local state.
final jdTextProvider = StateProvider<String>((ref) => '');
final liveJaccardScoreProvider = StateProvider<double>((ref) => 0.0);
final selectedTemplateProvider = StateProvider<String>((ref) => 'default');
final aiEnhanceProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// State machine for the PDF compile pipeline.
///
/// States: idle → compiling → success | error → idle.
///
/// Time: O(network) bounded by Typst + optional Ollama on Pi 5.
/// Space: O(pdf_size) transient during compile.
class ResumeCompileNotifier extends StateNotifier<ResumeCompileState> {
  final Ref _ref;

  ResumeCompileNotifier(this._ref) : super(const CompileIdle());

  /// Dispatch shua.resume.compile RPC with 120s timeout.
  ///
  /// On success: transitions to [CompileSuccess] and triggers history refresh.
  /// On error:  transitions to [CompileError] with the error message.
  Future<void> compile({
    required String template,
    String jobDesc = '',
    bool tailor = false,
    bool aiEnhance = false,
  }) async {
    state = CompileInProgress(aiEnhance: aiEnhance);

    try {
      final hbp = await _ref.read(hbpClientProvider.future);
      final payload = _buildCompilePayload(
        template: template,
        jobDesc: jobDesc,
        tailor: tailor,
        aiEnhance: aiEnhance,
      );
      final frame =
          HbpFrame.request('shua.resume', 'compile', payload);
      final resp = await hbp.send(
        frame,
        timeout: const Duration(seconds: 120),
      );

      if (resp.isError) {
        state = CompileError(resp.error ?? 'Compile failed');
        return;
      }

      final dto = ResumeCompileResponseDto.fromMsgpack(resp.payload);
      state = CompileSuccess(dto);

      // Refresh history list after successful compile
      _ref.invalidate(resumeHistoryProvider);
    } catch (e) {
      state = CompileError(e.toString());
    }
  }

  /// Reset to idle — called after the overlay is dismissed.
  void reset() => state = const CompileIdle();

  // ── Payload builder ────────────────────────────────────────────────────────

  /// Encode compile request as string-keyed msgpack.
  /// Go handler decodes via decodeMsgpackOrJSON which accepts both string and
  /// integer keys; we use string keys matching the json struct tags.
  List<int> _buildCompilePayload({
    required String template,
    required String jobDesc,
    required bool tailor,
    required bool aiEnhance,
  }) {
    final p = Packer();
    p.packMapLength(5);
    p.packString('matrix_id'); p.packString('shua');
    p.packString('template');  p.packString(template);
    p.packString('job_desc');  p.packString(jobDesc);
    p.packString('tailor');    p.packBool(tailor);
    p.packString('ai_enhance'); p.packBool(aiEnhance);
    return p.takeBytes();
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\providers\resume_compile_provider.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\providers\resume_history_provider.dart -->
# FILE: resume_history_provider.dart
**Relative Path**: `client_flutter\lib\features\resume\providers\resume_history_provider.dart`

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_history_item_dto.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final resumeHistoryProvider =
    AsyncNotifierProvider<ResumeHistoryNotifier, List<ResumeHistoryItemDto>>(
  ResumeHistoryNotifier.new,
);

/// Track the currently selected history item for the PDF viewer.
final selectedHistoryItemProvider =
    StateProvider<ResumeHistoryItemDto?>((ref) => null);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Fetches and caches the resume PDF compile history list.
///
/// Invalidated automatically after a successful compile via
/// [resumeCompileProvider].
///
/// Time: O(n) for n history rows (capped at 50 on the backend).
/// Space: O(n).
class ResumeHistoryNotifier
    extends AsyncNotifier<List<ResumeHistoryItemDto>> {
  @override
  Future<List<ResumeHistoryItemDto>> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);
    final frame = HbpFrame.request('shua.resume', 'history.list', []);
    final resp = await hbp.send(frame);
    return _decodeHistory(resp);
  }

  /// Force a refresh (called after compile succeeds).
  Future<void> refresh() async => ref.invalidateSelf();
}

// ---------------------------------------------------------------------------
// Decode helper
// ---------------------------------------------------------------------------

List<ResumeHistoryItemDto> _decodeHistory(HbpFrame frame) {
  if (frame.payload.isEmpty) return [];
  try {
    final u = Unpacker(Uint8List.fromList(frame.payload));
    final topLen = u.unpackMapLength();

    for (var i = 0; i < topLen; i++) {
      final key = u.unpackString();
      if (key == 'items') {
        final listLen = u.unpackListLength();
        final items = <ResumeHistoryItemDto>[];
        for (var j = 0; j < listLen; j++) {
          final itemLen = u.unpackMapLength();
          final m = <dynamic, dynamic>{};
          for (var k = 0; k < itemLen; k++) {
            final mk = _unpackAny(u);
            final mv = _unpackAny(u);
            if (mk != null) m[mk] = mv;
          }
          items.add(ResumeHistoryItemDto.fromMap(m));
        }
        return items;
      } else {
        // Skip value for this key
        _unpackAny(u);
      }
    }
    return [];
  } catch (_) {
    return [];
  }
}

dynamic _unpackAny(Unpacker u) {
  try {
    return u.unpackString();
  } catch (_) {}
  try {
    return u.unpackInt();
  } catch (_) {}
  try {
    return u.unpackDouble();
  } catch (_) {}
  try {
    return u.unpackBool();
  } catch (_) {}
  try {
    final len = u.unpackMapLength();
    final m = <dynamic, dynamic>{};
    for (var i = 0; i < len; i++) {
      final k = _unpackAny(u);
      final v = _unpackAny(u);
      if (k != null) m[k] = v;
    }
    return m;
  } catch (_) {}
  try {
    final len = u.unpackListLength();
    return List.generate(len, (_) => _unpackAny(u));
  } catch (_) {}
  return null;
}


<!-- END_FILE: client_flutter\lib\features\resume\providers\resume_history_provider.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\providers\resume_matrix_provider.dart -->
# FILE: resume_matrix_provider.dart
**Relative Path**: `client_flutter\lib\features\resume\providers\resume_matrix_provider.dart`

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import 'package:uuid/uuid.dart';

import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/hbp/hbp_frame.dart';
import '../resume_matrix_dto.dart';

const _uuid = Uuid();

// ---------------------------------------------------------------------------
// Provider declaration
// ---------------------------------------------------------------------------

final resumeMatrixProvider =
    AsyncNotifierProvider<ResumeMatrixNotifier, ResumeMatrixDto>(
  ResumeMatrixNotifier.new,
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

/// Manages the ResumeMatrix state: fetch on build, optimistic CRUD mutations.
///
/// Data flow: Widget → provider method → HBP v2 RPC (shua.resume.*).
///
/// Time Complexity: O(n) on matrix size.  Space: O(n) for cached state.
class ResumeMatrixNotifier extends AsyncNotifier<ResumeMatrixDto> {
  @override
  Future<ResumeMatrixDto> build() async {
    final hbp = await ref.watch(hbpClientProvider.future);
    // matrix.get has no request payload — empty bytes
    final frame = HbpFrame.request('shua.resume', 'matrix.get', []);
    final resp = await hbp.send(frame);
    return _decodeMatrix(resp);
  }

  /// Upsert a section item with optimistic local update.
  ///
  /// Immediately updates local state, then fires background RPC.
  /// On RPC error, invalidates self to revert to last good server state.
  Future<void> upsertSection(
      String section, Map<String, dynamic> item) async {
    // Optimistic update
    final current = state.requireValue;
    state = AsyncData(_applyUpsert(current, section, item));

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final payload = _encodeMsgpack({
        'section': section,
        'action': 'upsert',
        'item': item,
      });
      final frame = HbpFrame.request('shua.resume', 'matrix.update', payload);
      final resp = await hbp.send(frame);
      if (resp.isError) ref.invalidateSelf(); // Revert on server error
    } catch (_) {
      ref.invalidateSelf(); // Revert on network error
    }
  }

  /// Delete a section item optimistically.
  Future<void> deleteItem(String section, String id) async {
    final current = state.requireValue;
    state = AsyncData(_applyDelete(current, section, id));

    try {
      final hbp = await ref.read(hbpClientProvider.future);
      final payload = _encodeMsgpack({
        'section': section,
        'action': 'delete',
        'id': id,
      });
      final frame = HbpFrame.request('shua.resume', 'matrix.update', payload);
      final resp = await hbp.send(frame);
      if (resp.isError) ref.invalidateSelf();
    } catch (_) {
      ref.invalidateSelf();
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  ResumeMatrixDto _applyUpsert(
      ResumeMatrixDto matrix, String section, Map<String, dynamic> item) {
    final id = item['id'] as String? ?? '';
    switch (section) {
      case 'basics':
        return matrix.copyWith(
            basics: BasicsDto.fromMap(item));
      case 'work':
        final list = List<WorkItemDto>.from(matrix.work);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = WorkItemDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(work: list);
      case 'education':
        final list = List<EducationDto>.from(matrix.education);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = EducationDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(education: list);
      case 'projects':
        final list = List<ProjectItemDto>.from(matrix.projects);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = ProjectItemDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(projects: list);
      case 'skills':
        final list = List<SkillDto>.from(matrix.skills);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = SkillDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(skills: list);
      case 'certificates':
        final list = List<CertificateDto>.from(matrix.certificates);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = CertificateDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(certificates: list);
      case 'awards':
        final list = List<AwardDto>.from(matrix.awards);
        final idx = list.indexWhere((e) => e.id == id);
        final dto = AwardDto.fromMap(item);
        if (idx >= 0) {
          list[idx] = dto;
        } else {
          list.insert(0, dto);
        }
        return matrix.copyWith(awards: list);
      default:
        return matrix;
    }
  }

  ResumeMatrixDto _applyDelete(
      ResumeMatrixDto matrix, String section, String id) {
    switch (section) {
      case 'work':
        return matrix.copyWith(
            work: matrix.work.where((e) => e.id != id).toList());
      case 'education':
        return matrix.copyWith(
            education: matrix.education.where((e) => e.id != id).toList());
      case 'projects':
        return matrix.copyWith(
            projects: matrix.projects.where((e) => e.id != id).toList());
      case 'skills':
        return matrix.copyWith(
            skills: matrix.skills.where((e) => e.id != id).toList());
      case 'certificates':
        return matrix.copyWith(
            certificates:
                matrix.certificates.where((e) => e.id != id).toList());
      case 'awards':
        return matrix.copyWith(
            awards: matrix.awards.where((e) => e.id != id).toList());
      default:
        return matrix;
    }
  }
}

// ---------------------------------------------------------------------------
// Decode helpers
// ---------------------------------------------------------------------------

/// Decode matrix from HBP v2 response frame.
/// The backend sends payload as base64-encoded msgpack in the JSON frame.
/// HbpFrame.decode() extracts the raw msgpack bytes already.
ResumeMatrixDto _decodeMatrix(HbpFrame frame) {
  if (frame.payload.isEmpty) return const ResumeMatrixDto();
  try {
    final u = Unpacker(Uint8List.fromList(frame.payload));
    final map = _unpackMap(u);
    return ResumeMatrixDto.fromMap(map);
  } catch (e) {
    // Fallback: try JSON decode (useful in dev/mock)
    try {
      final decoded = utf8.decode(frame.payload);
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return ResumeMatrixDto.fromMap(json);
    } catch (_) {
      return const ResumeMatrixDto();
    }
  }
}

/// Encode a string-keyed map as msgpack bytes for HBP v2 request payload.
List<int> _encodeMsgpack(Map<String, dynamic> map) {
  final p = Packer();
  _packMap(p, map);
  return p.takeBytes();
}

void _packMap(Packer p, Map<String, dynamic> map) {
  p.packMapLength(map.length);
  for (final entry in map.entries) {
    p.packString(entry.key);
    _packValue(p, entry.value);
  }
}

void _packValue(Packer p, dynamic value) {
  if (value == null) {
    p.packNull();
  } else if (value is bool) {
    p.packBool(value);
  } else if (value is int) {
    p.packInt(value);
  } else if (value is double) {
    p.packDouble(value);
  } else if (value is String) {
    p.packString(value);
  } else if (value is List) {
    p.packListLength(value.length);
    for (final item in value) {
      _packValue(p, item);
    }
  } else if (value is Map<String, dynamic>) {
    _packMap(p, value);
  } else {
    p.packString(value.toString());
  }
}

Map<dynamic, dynamic> _unpackMap(Unpacker u) {
  final len = u.unpackMapLength();
  final map = <dynamic, dynamic>{};
  for (var i = 0; i < len; i++) {
    final key = _unpackAny(u);
    final val = _unpackAny(u);
    if (key != null) map[key] = val;
  }
  return map;
}

dynamic _unpackAny(Unpacker u) {
  try {
    final s = u.unpackString();
    return s;
  } catch (_) {}
  try {
    final i = u.unpackInt();
    return i;
  } catch (_) {}
  try {
    final d = u.unpackDouble();
    return d;
  } catch (_) {}
  try {
    final b = u.unpackBool();
    return b;
  } catch (_) {}
  try {
    return _unpackMap(u);
  } catch (_) {}
  try {
    final len = u.unpackListLength();
    return List.generate(len, (_) => _unpackAny(u));
  } catch (_) {}
  return null;
}

/// Generates a fresh blank WorkItemDto with a new UUID.
WorkItemDto newBlankWorkItem() => WorkItemDto(id: _uuid.v4());

/// Generates a fresh blank ProjectItemDto with a new UUID.
ProjectItemDto newBlankProjectItem() => ProjectItemDto(id: _uuid.v4());

/// Generates a fresh blank EducationDto with a new UUID.
EducationDto newBlankEducation() => EducationDto(id: _uuid.v4());

/// Generates a fresh blank SkillDto with a new UUID.
SkillDto newBlankSkill() => SkillDto(id: _uuid.v4());

/// Generates a fresh blank CertificateDto with a new UUID.
CertificateDto newBlankCertificate() => CertificateDto(id: _uuid.v4());

/// Generates a fresh blank AwardDto with a new UUID.
AwardDto newBlankAward() => AwardDto(id: _uuid.v4());


<!-- END_FILE: client_flutter\lib\features\resume\providers\resume_matrix_provider.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\screens\resume_compile_screen.dart -->
# FILE: resume_compile_screen.dart
**Relative Path**: `client_flutter\lib\features\resume\screens\resume_compile_screen.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hbp/hbp_client.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../providers/resume_compile_provider.dart';
import '../providers/resume_matrix_provider.dart';
import '../utils/jaccard_dart.dart';
import '../widgets/compile_progress_overlay.dart';
import '../widgets/jaccard_score_gauge.dart';
import '../widgets/template_picker.dart';

/// AI Tailoring & Compile screen.
///
/// Layout (top to bottom):
/// 1. Job description TextField (multiline, 400ms debounce → Jaccard)
/// 2. JaccardScoreGauge (animated arc, client-side live score)
/// 3. TemplatePicker (Default / Modern / Minimalist)
/// 4. AI Enhancement SwitchListTile
/// 5. Compile PDF ElevatedButton
/// 6. Last compile result card (if cached)
class ResumeCompileScreen extends ConsumerStatefulWidget {
  /// Called when compile succeeds to navigate to History tab.
  final VoidCallback onCompileSuccess;

  const ResumeCompileScreen({super.key, required this.onCompileSuccess});

  @override
  ConsumerState<ResumeCompileScreen> createState() =>
      _ResumeCompileScreenState();
}

class _ResumeCompileScreenState extends ConsumerState<ResumeCompileScreen> {
  final _jdController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _jdController.addListener(_onJdChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _jdController.dispose();
    super.dispose();
  }

  void _onJdChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final jd = _jdController.text;
      ref.read(jdTextProvider.notifier).state = jd;

      if (jd.trim().isEmpty) {
        ref.read(liveJaccardScoreProvider.notifier).state = 0.0;
        return;
      }

      final matrix = ref.read(resumeMatrixProvider).valueOrNull;
      if (matrix == null) return;

      final score = scoreResumeAgainstJd(matrix, jd);
      ref.read(liveJaccardScoreProvider.notifier).state = score;
    });
  }

  Future<void> _compile() async {
    final jd = ref.read(jdTextProvider);
    final template = ref.read(selectedTemplateProvider);
    final aiEnhance = ref.read(aiEnhanceProvider);
    final tailor = jd.trim().isNotEmpty;

    await ref.read(resumeCompileProvider.notifier).compile(
          template: template,
          jobDesc: jd,
          tailor: tailor,
          aiEnhance: aiEnhance,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ??
        HbpConnectionState.disconnected;
    final isOffline = connState != HbpConnectionState.connected;

    final compileState = ref.watch(resumeCompileProvider);
    final jaccardScore = ref.watch(liveJaccardScoreProvider);
    final template = ref.watch(selectedTemplateProvider);
    final aiEnhance = ref.watch(aiEnhanceProvider);

    // Navigate to history on success
    ref.listen(resumeCompileProvider, (_, next) {
      if (next is CompileSuccess) {
        widget.onCompileSuccess();
        ref.read(resumeCompileProvider.notifier).reset();
      }
    });

    final CompileInProgress? inProgress = compileState is CompileInProgress
        ? compileState
        : null;
    final isCompiling = inProgress != null;
    final lastSuccess =
        compileState is CompileSuccess ? compileState.result : null;

    return Stack(
      children: [
        // ── Main scroll content ──────────────────────────────────────────
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isOffline)
                _offlineBanner(),

              // 1. Job description input
              Text('Job Description',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: _jdController,
                maxLines: 7,
                decoration: InputDecoration(
                  hintText:
                      'Paste the job description here to analyse keyword match...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                ),
              ),

              // 2. Jaccard gauge
              const SizedBox(height: 24),
              Center(child: JaccardScoreGauge(score: jaccardScore)),

              // 3. Template picker
              const SizedBox(height: 24),
              Text('Template',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TemplatePicker(
                selected: template,
                onSelected: (t) =>
                    ref.read(selectedTemplateProvider.notifier).state = t,
              ),

              // 4. AI enhancement toggle
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Ollama AI Enhancement'),
                subtitle: const Text(
                    'Uses Pi 5 Ollama to rewrite bullet points for this job.'),
                value: aiEnhance,
                onChanged: isOffline
                    ? null
                    : (v) =>
                        ref.read(aiEnhanceProvider.notifier).state = v,
                contentPadding: EdgeInsets.zero,
              ),

              // 5. Compile button
              const SizedBox(height: 8),
              Tooltip(
                message: isOffline ? 'Connect to Pi 5 to compile' : '',
                child: FilledButton.icon(
                  onPressed: isOffline || isCompiling ? null : _compile,
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: const Text('Compile PDF'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                ),
              ),

              // Error state
              if (compileState is CompileError) ...[
                const SizedBox(height: 12),
                Card(
                  color: cs.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded,
                            color: cs.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text((compileState).message,
                              style: TextStyle(color: cs.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // 6. Last compile result card
              if (lastSuccess != null) ...[
                const SizedBox(height: 16),
                _LastResultCard(
                  exhibitId: lastSuccess.exhibitId,
                  durationMs: lastSuccess.durationMs,
                  tailorScore: lastSuccess.tailorScore,
                  onTap: widget.onCompileSuccess,
                ),
              ],

              const SizedBox(height: 32),
            ],
          ),
        ),

        // ── Compile overlay ────────────────────────────────────────────────
        if (isCompiling)
          CompileProgressOverlay(
            aiEnhance: inProgress.aiEnhance,
            onCancel: () =>
                ref.read(resumeCompileProvider.notifier).reset(),
          ),
      ],
    );
  }

  Widget _offlineBanner() => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: MaterialBanner(
          content: const Text(
              'Pi 5 offline — Resume data unavailable'),
          backgroundColor: const Color(0xFFFFF3E0),
          leading: const Icon(Icons.wifi_off_rounded,
              color: Color(0xFFFFA000)),
          actions: [
            TextButton(onPressed: () {}, child: const Text('Dismiss')),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Last result card
// ---------------------------------------------------------------------------

class _LastResultCard extends StatelessWidget {
  final String exhibitId;
  final int durationMs;
  final double? tailorScore;
  final VoidCallback onTap;

  const _LastResultCard({
    required this.exhibitId,
    required this.durationMs,
    required this.tailorScore,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = tailorScore != null
        ? ' — Match: ${(tailorScore! * 100).round()}%'
        : '';
    final dur = '${(durationMs / 1000).toStringAsFixed(1)}s';

    return Card(
      color: cs.primaryContainer,
      child: ListTile(
        leading: Icon(Icons.check_circle_rounded, color: cs.primary),
        title: const Text('PDF compiled successfully'),
        subtitle: Text('Duration: $dur$score'),
        trailing:
            Icon(Icons.arrow_forward_rounded, color: cs.primary),
        onTap: onTap,
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\screens\resume_compile_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\screens\resume_editor_screen.dart -->
# FILE: resume_editor_screen.dart
**Relative Path**: `client_flutter\lib\features\resume\screens\resume_editor_screen.dart`

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/hbp/hbp_client.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';
import '../widgets/award_item_card.dart';
import '../widgets/certificate_item_card.dart';
import '../widgets/education_item_card.dart';
import '../widgets/org_item_card.dart';
import '../widgets/project_item_card.dart';
import '../widgets/resume_section_tab.dart';
import '../widgets/skill_chip_row.dart';
import '../widgets/work_item_card.dart';


/// 8-tab CRUD matrix editor for the resume data.
///
/// Tabs: Basics | Experience | Projects | Skills | Education | Certs | Awards | Org Exp
///
/// Each list tab supports: inline expand-to-edit, 800ms debounced auto-save,
/// FAB add, swipe-to-dismiss delete (optimistic UI).
class ResumeEditorScreen extends ConsumerWidget {
  const ResumeEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connState = ref.watch(hbpConnectionStateProvider).valueOrNull ??
        HbpConnectionState.disconnected;
    final isOffline = connState != HbpConnectionState.connected;

    return DefaultTabController(
      length: 8,
      child: Column(
        children: [
          // ── Offline banner ─────────────────────────────────────────────
          if (isOffline)
            MaterialBanner(
              content: const Text('Pi 5 offline — Resume data unavailable'),
              backgroundColor: const Color(0xFFFFF3E0),
              leading: const Icon(Icons.wifi_off_rounded,
                  color: Color(0xFFFFA000)),
              actions: [
                TextButton(
                    onPressed: () {},
                    child: const Text('Dismiss')),
              ],
            ),

          // ── Tab bar ────────────────────────────────────────────────────
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'Basics'),
              Tab(text: 'Experience'),
              Tab(text: 'Projects'),
              Tab(text: 'Skills'),
              Tab(text: 'Education'),
              Tab(text: 'Certs'),
              Tab(text: 'Awards'),
              Tab(text: 'Org Exp'),
            ],
          ),

          // ── Tab views ──────────────────────────────────────────────────
          Expanded(
            child: ref.watch(resumeMatrixProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => _ErrorState(message: err.toString()),
              data: (matrix) => TabBarView(
                children: [
                  _BasicsTab(matrix: matrix),
                  _WorkTab(matrix: matrix),
                  _ProjectsTab(matrix: matrix),
                  _SkillsTab(matrix: matrix),
                  _EducationTab(matrix: matrix),
                  _CertsTab(matrix: matrix),
                  _AwardsTab(matrix: matrix),
                  _OrgsTab(matrix: matrix),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Basics tab (single-record form)
// ---------------------------------------------------------------------------

class _BasicsTab extends ConsumerStatefulWidget {
  final ResumeMatrixDto matrix;

  const _BasicsTab({required this.matrix});

  @override
  ConsumerState<_BasicsTab> createState() => _BasicsTabState();
}

class _BasicsTabState extends ConsumerState<_BasicsTab> {
  late TextEditingController _nameCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _regionCtrl;

  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final b = widget.matrix.basics;
    _nameCtrl = TextEditingController(text: b.name);
    _labelCtrl = TextEditingController(text: b.label);
    _emailCtrl = TextEditingController(text: b.email);
    _phoneCtrl = TextEditingController(text: b.phone);
    _urlCtrl = TextEditingController(text: b.url);
    _summaryCtrl = TextEditingController(text: b.summary);
    _cityCtrl = TextEditingController(text: b.location.city);
    _regionCtrl = TextEditingController(text: b.location.region);
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _labelCtrl, _emailCtrl, _phoneCtrl,
      _urlCtrl, _summaryCtrl, _cityCtrl, _regionCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('basics', {
      'name': _nameCtrl.text,
      'label': _labelCtrl.text,
      'email': _emailCtrl.text,
      'phone': _phoneCtrl.text,
      'url': _urlCtrl.text,
      'summary': _summaryCtrl.text,
      'location': {
        'city': _cityCtrl.text,
        'region': _regionCtrl.text,
        'country_code': widget.matrix.basics.location.countryCode,
      },
      'profiles': widget.matrix.basics.profiles
          .map((p) => p.toMap())
          .toList(),
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: cs.primary, size: 18),
                  const SizedBox(width: 6),
                  Text('Saved', style: TextStyle(color: cs.primary)),
                ],
              ),
            ),
          _field('Full Name', _nameCtrl),
          _field('Label / Headline', _labelCtrl),
          _field('Email', _emailCtrl,
              keyboard: TextInputType.emailAddress),
          _field('Phone', _phoneCtrl,
              keyboard: TextInputType.phone),
          _field('Professional Summary', _summaryCtrl, maxLines: 4),
          const SizedBox(height: 8),
          Text('Location',
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: cs.outline)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: _field('City', _cityCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _field('Region', _regionCtrl)),
          ]),
          const SizedBox(height: 16),
          // ── Profile Links ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Profile Links',
                    style: Theme.of(context)
                        .textTheme
                        .labelLarge
                        ?.copyWith(color: cs.outline)),
              ),
              TextButton.icon(
                onPressed: _addProfile,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add Link'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'e.g. GitHub, LinkedIn, Portfolio — these appear in the resume header',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.outline),
          ),
          const SizedBox(height: 8),
          ...List.generate(widget.matrix.basics.profiles.length, (i) {
            final p = widget.matrix.basics.profiles[i];
            return _ProfileLinkRow(
              key: ValueKey('profile_$i'),
              initial: p,
              onRemove: () => _removeProfile(i),
              onChanged: (updated) => _updateProfile(i, updated),
            );
          }),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Save Basics'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboard,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );
}

// ---------------------------------------------------------------------------
// List tabs (Experience, Projects, Skills, Education, Certs, Awards)
// ---------------------------------------------------------------------------

class _WorkTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _WorkTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Experience',
        isEmpty: matrix.work.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.work_outline_rounded,
          message: 'No experience yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('work', newBlankWorkItem().toMap()),
        child: Column(
          children: matrix.work
              .map((w) => WorkItemCard(key: ValueKey(w.id), item: w))
              .toList(),
        ),
      );
}

class _ProjectsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _ProjectsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Project',
        isEmpty: matrix.projects.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.folder_open_rounded,
          message: 'No projects yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('projects', newBlankProjectItem().toMap()),
        child: Column(
          children: matrix.projects
              .map((p) => ProjectItemCard(key: ValueKey(p.id), item: p))
              .toList(),
        ),
      );
}

class _SkillsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _SkillsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Skill Group',
        isEmpty: matrix.skills.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.code_rounded,
          message: 'No skill groups yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('skills', newBlankSkill().toMap()),
        child: Column(
          children: matrix.skills
              .map((s) => SkillChipRow(key: ValueKey(s.id), item: s))
              .toList(),
        ),
      );
}

class _EducationTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _EducationTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Education',
        isEmpty: matrix.education.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.school_rounded,
          message: 'No education entries yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('education', newBlankEducation().toMap()),
        child: Column(
          children: matrix.education
              .map((e) => EducationItemCard(key: ValueKey(e.id), item: e))
              .toList(),
        ),
      );
}

class _CertsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _CertsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Certificate',
        isEmpty: matrix.certificates.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.verified_outlined,
          message: 'No certificates yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('certificates', newBlankCertificate().toMap()),
        child: Column(
          children: matrix.certificates
              .map((c) =>
                  CertificateItemCard(key: ValueKey(c.id), item: c))
              .toList(),
        ),
      );
}

class _AwardsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _AwardsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Award',
        isEmpty: matrix.awards.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.emoji_events_outlined,
          message: 'No awards yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('awards', newBlankAward().toMap()),
        child: Column(
          children: matrix.awards
              .map((a) => AwardItemCard(key: ValueKey(a.id), item: a))
              .toList(),
        ),
      );
}

class _OrgsTab extends ConsumerWidget {
  final ResumeMatrixDto matrix;

  const _OrgsTab({required this.matrix});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ResumeSectionTab(
        title: 'Org Experience',
        isEmpty: matrix.organizations.isEmpty,
        emptyState: const SectionEmptyState(
          icon: Icons.groups_rounded,
          message: 'No org experience yet\nTap + to add one',
        ),
        onAdd: () => ref
            .read(resumeMatrixProvider.notifier)
            .upsertSection('organizations', newBlankOrgItem().toMap()),
        child: Column(
          children: matrix.organizations
              .map((o) => OrgItemCard(key: ValueKey(o.id), item: o))
              .toList(),
        ),
      );
}

// ---------------------------------------------------------------------------
// Error state
// ---------------------------------------------------------------------------

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: cs.error)),
          ],
        ),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\screens\resume_editor_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\screens\resume_history_screen.dart -->
# FILE: resume_history_screen.dart
**Relative Path**: `client_flutter\lib\features\resume\screens\resume_history_screen.dart`

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/resume_history_provider.dart';
import '../resume_history_item_dto.dart';

/// PDF History & Viewer screen.
///
/// Shows a scrollable list of compiled PDFs.
/// On narrow screens (< 720px): tapping an item navigates to a detail view.
/// On wide screens: side-by-side split: list left, pdfx viewer right.
class ResumeHistoryScreen extends ConsumerWidget {
  const ResumeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(resumeHistoryProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Text('Error loading history: $err'),
      ),
      data: (items) {
        if (items.isEmpty) {
          return _EmptyHistory();
        }
        final isWide = MediaQuery.of(context).size.width >= 720;
        return isWide
            ? _WideLayout(items: items)
            : _NarrowLayout(items: items);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyHistory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history_rounded, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            'No compiled PDFs yet\nGo to Compile tab to build your first resume',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.outline),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Narrow layout (< 720px)
// ---------------------------------------------------------------------------

class _NarrowLayout extends ConsumerWidget {
  final List<ResumeHistoryItemDto> items;

  const _NarrowLayout({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, i) => _HistoryListTile(
        item: items[i],
        onTap: () {
          ref.read(selectedHistoryItemProvider.notifier).state = items[i];
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _PdfDetailPage(item: items[i]),
            ),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Wide layout (>= 720px) — split view
// ---------------------------------------------------------------------------

class _WideLayout extends ConsumerStatefulWidget {
  final List<ResumeHistoryItemDto> items;

  const _WideLayout({required this.items});

  @override
  ConsumerState<_WideLayout> createState() => _WideLayoutState();
}

class _WideLayoutState extends ConsumerState<_WideLayout> {
  ResumeHistoryItemDto? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.items.firstOrNull;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: history list
        SizedBox(
          width: 320,
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (_, i) {
              final item = widget.items[i];
              return _HistoryListTile(
                item: item,
                selected: _selected?.exhibitId == item.exhibitId,
                onTap: () => setState(() => _selected = item),
              );
            },
          ),
        ),
        const VerticalDivider(width: 1),
        // Right: PDF viewer
        Expanded(
          child: _selected == null
              ? const Center(child: Text('Select a PDF to preview'))
              : _PdfViewerPanel(item: _selected!),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// History list tile
// ---------------------------------------------------------------------------

class _HistoryListTile extends StatelessWidget {
  final ResumeHistoryItemDto item;
  final bool selected;
  final VoidCallback onTap;

  const _HistoryListTile({
    required this.item,
    this.selected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final score = item.tailorScore != null
        ? 'Match: ${(item.tailorScore! * 100).round()}%'
        : null;

    return ListTile(
      selected: selected,
      selectedTileColor: cs.primaryContainer.withValues(alpha: 0.4),
      leading: const Icon(Icons.picture_as_pdf_rounded, color: Colors.red),
      title: Text(
        '${_capitalize(item.templateId)} — ${item.formattedDate}',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: score != null
          ? Text('$score · ${item.formattedDuration}')
          : Text(item.formattedDuration),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download',
            onPressed: () => _download(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share',
            onPressed: () => _share(context, item),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ---------------------------------------------------------------------------
// PDF viewer panel (used in wide split and detail page)
// ---------------------------------------------------------------------------

class _PdfViewerPanel extends StatefulWidget {
  final ResumeHistoryItemDto item;

  const _PdfViewerPanel({required this.item});

  @override
  State<_PdfViewerPanel> createState() => _PdfViewerPanelState();
}

class _PdfViewerPanelState extends State<_PdfViewerPanel> {
  PdfController? _ctrl;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initPdf();
  }

  @override
  void didUpdateWidget(_PdfViewerPanel old) {
    super.didUpdateWidget(old);
    if (old.item.exhibitId != widget.item.exhibitId) {
      _ctrl?.dispose();
      _ctrl = null;
      setState(() {
        _loading = true;
        _error = null;
      });
      _initPdf();
    }
  }

  void _initPdf() {
    if (widget.item.vaultUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No vault URL available for this PDF.';
      });
      return;
    }

    // pdfx has no built-in HTTP URI support — download bytes, then openData.
    _loadPdfFromUrl();
  }

  Future<void> _loadPdfFromUrl() async {
    try {
      final response = await http.get(Uri.parse(widget.item.vaultUrl));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }
      _ctrl = PdfController(
        document: PdfDocument.openData(response.bodyBytes),
      );
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      // URL unreachable or unsupported — offer open-in-browser fallback
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null || _ctrl == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_rounded,
                  size: 48, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'PDF preview unavailable',
                style: theme.textTheme.titleMedium,
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 20),
              if (widget.item.vaultUrl.isNotEmpty)
                FilledButton.icon(
                  onPressed: () => _openInBrowser(context),
                  icon: const Icon(Icons.open_in_browser_rounded),
                  label: const Text('Open in Browser'),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Toolbar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${_capitalize(widget.item.templateId)} — ${widget.item.formattedDate}',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Download',
                onPressed: () => _download(context, widget.item),
              ),
              IconButton(
                icon: const Icon(Icons.share_rounded),
                tooltip: 'Share',
                onPressed: () => _share(context, widget.item),
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser_rounded),
                tooltip: 'Open in browser',
                onPressed: () => _openInBrowser(context),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: PdfView(controller: _ctrl!),
        ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  void _openInBrowser(BuildContext context) async {
    final uri = Uri.tryParse(widget.item.vaultUrl);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot open URL')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Detail page (narrow screens)
// ---------------------------------------------------------------------------

class _PdfDetailPage extends StatelessWidget {
  final ResumeHistoryItemDto item;

  const _PdfDetailPage({required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${item.templateId[0].toUpperCase()}${item.templateId.substring(1)} — ${item.formattedDate}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _download(context, item),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () => _share(context, item),
          ),
        ],
      ),
      body: _PdfViewerPanel(item: item),
    );
  }
}

// ---------------------------------------------------------------------------
// Download & Share helpers
// ---------------------------------------------------------------------------

Future<void> _download(BuildContext context, ResumeHistoryItemDto item) async {
  if (item.vaultUrl.isEmpty) return;

  try {
    final response = await http.get(Uri.parse(item.vaultUrl));
    if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

    Directory? dir;
    if (UniversalPlatform.isWindows) {
      dir = await getDownloadsDirectory();
    } else {
      dir = await getExternalStorageDirectory();
    }
    dir ??= await getTemporaryDirectory();

    final file = File('${dir.path}/${item.fileName}');
    await file.writeAsBytes(response.bodyBytes);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to ${file.path}')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $e')),
      );
    }
  }
}

Future<void> _share(BuildContext context, ResumeHistoryItemDto item) async {
  if (item.vaultUrl.isEmpty) return;

  // On Windows: open in browser (no native share sheet)
  if (UniversalPlatform.isWindows) {
    final uri = Uri.tryParse(item.vaultUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return;
  }

  try {
    final response = await http.get(Uri.parse(item.vaultUrl));
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/${item.fileName}')
      ..writeAsBytesSync(response.bodyBytes);
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: 'My Resume — ${item.fileName}',
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: $e')),
      );
    }
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\screens\resume_history_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\utils\jaccard_dart.dart -->
# FILE: jaccard_dart.dart
**Relative Path**: `client_flutter\lib\features\resume\utils\jaccard_dart.dart`

import '../resume_matrix_dto.dart';

/// Pure Dart port of Go's `pkg/ai/tailor.go` — `Tokenize` + `JaccardSimilarity`.
///
/// Kept functionally identical to the Go version so client-side scores match
/// the Pi 5's server-side filtered result (within floating-point precision).
///
/// Time Complexity:  O(n + m) where n = resume tokens, m = JD tokens.
/// Space Complexity: O(n + m) for the two token sets.

/// English stopwords — identical set to Go's `tailor.go`.
const _stopwords = {
  'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
  'of', 'with', 'is', 'are', 'was', 'were', 'be', 'been', 'being', 'have',
  'has', 'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
  'may', 'might', 'shall', 'can', 'need', 'dare', 'ought', 'used',
};

/// Tokenizes [text] into a lowercase word set, removing punctuation and
/// stopwords.
///
/// O(n) where n = word count.
Set<String> tokenize(String text) {
  return text
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((w) => w.length > 2 && !_stopwords.contains(w))
      .toSet();
}

/// Jaccard similarity: |A ∩ B| / |A ∪ B|.
///
/// Returns 0.0 when both sets are empty.
/// O(|A| + |B|).
double jaccardSimilarity(Set<String> a, Set<String> b) {
  if (a.isEmpty && b.isEmpty) return 0.0;
  final intersection = a.intersection(b).length;
  final union = a.union(b).length;
  if (union == 0) return 0.0;
  return intersection / union;
}

/// Computes a live Jaccard score between [matrix] resume content and [jobDesc].
///
/// Concatenates all meaningful resume text (work highlights, project
/// descriptions + highlights, skill keywords) and tokenizes both sides.
///
/// Call with a 400ms debounce — NOT on every keystroke.
///
/// O(n + m) where n = resume token count, m = JD token count.
double scoreResumeAgainstJd(ResumeMatrixDto matrix, String jobDesc) {
  final buf = StringBuffer();

  for (final w in matrix.work) {
    buf.writeAll(w.highlights, ' ');
    buf.write(' ');
    buf.write(w.summary);
    buf.write(' ');
  }
  for (final p in matrix.projects) {
    buf.write(p.description);
    buf.write(' ');
    buf.writeAll(p.highlights, ' ');
    buf.write(' ');
  }
  for (final s in matrix.skills) {
    buf.writeAll(s.keywords, ' ');
    buf.write(' ');
  }

  final setA = tokenize(buf.toString());
  final setB = tokenize(jobDesc);
  return jaccardSimilarity(setA, setB);
}


<!-- END_FILE: client_flutter\lib\features\resume\utils\jaccard_dart.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\award_item_card.dart -->
# FILE: award_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\award_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline edit card for an award / recognition entry.
class AwardItemCard extends ConsumerStatefulWidget {
  final AwardDto item;
  final bool initiallyExpanded;

  const AwardItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<AwardItemCard> createState() => _AwardItemCardState();
}

class _AwardItemCardState extends ConsumerState<AwardItemCard> {
  late bool _expanded;
  late TextEditingController _titleCtrl;
  late TextEditingController _awarderCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _summaryCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _titleCtrl = TextEditingController(text: widget.item.title);
    _awarderCtrl = TextEditingController(text: widget.item.awarder);
    _dateCtrl = TextEditingController(text: widget.item.date);
    _summaryCtrl = TextEditingController(text: widget.item.summary);
    for (final c in [_titleCtrl, _awarderCtrl, _dateCtrl, _summaryCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_titleCtrl, _awarderCtrl, _dateCtrl, _summaryCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('awards', {
      'id': widget.item.id,
      'title': _titleCtrl.text,
      'awarder': _awarderCtrl.text,
      'date': _dateCtrl.text,
      'summary': _summaryCtrl.text,
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('award_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('awards', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.title.isEmpty
                              ? 'New Award'
                              : widget.item.title,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      if (widget.item.awarder.isNotEmpty)
                        Text(widget.item.awarder,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: cs.outline)),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Award Title', _titleCtrl),
                    _field('Awarder / Organisation', _awarderCtrl),
                    _field('Date (YYYY-MM)', _dateCtrl),
                    _field('Summary', _summaryCtrl, maxLines: 2),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true),
        ),
      );

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete award?'),
          content: Text('"${widget.item.title}" will be permanently removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\award_item_card.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\certificate_item_card.dart -->
# FILE: certificate_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\certificate_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline edit card for a certificate entry.
class CertificateItemCard extends ConsumerStatefulWidget {
  final CertificateDto item;
  final bool initiallyExpanded;

  const CertificateItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<CertificateItemCard> createState() =>
      _CertificateItemCardState();
}

class _CertificateItemCardState extends ConsumerState<CertificateItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _issuerCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _urlCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _issuerCtrl = TextEditingController(text: widget.item.issuer);
    _dateCtrl = TextEditingController(text: widget.item.date);
    _urlCtrl = TextEditingController(text: widget.item.url);
    for (final c in [_nameCtrl, _issuerCtrl, _dateCtrl, _urlCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _issuerCtrl, _dateCtrl, _urlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('certificates', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'issuer': _issuerCtrl.text,
      'date': _dateCtrl.text,
      'url': _urlCtrl.text,
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('cert_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('certificates', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.isEmpty
                                  ? 'New Certificate'
                                  : widget.item.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.issuer.isNotEmpty)
                              Text(widget.item.issuer,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.outline)),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      if (widget.item.date.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(widget.item.date,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.outline)),
                        ),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Certificate Name', _nameCtrl),
                    _field('Issuer', _issuerCtrl),
                    _field('Date (YYYY-MM)', _dateCtrl),
                    _field('URL', _urlCtrl),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true),
        ),
      );

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete certificate?'),
          content: Text('"${widget.item.name}" will be permanently removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\certificate_item_card.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\compile_progress_overlay.dart -->
# FILE: compile_progress_overlay.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\compile_progress_overlay.dart`

import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen overlay shown during PDF compilation on Pi 5.
///
/// - Shimmer card animation
/// - Live elapsed time [Ticker]
/// - Optional AI enhancement text when [aiEnhance] is true
/// - Cancel button: dismisses overlay locally only (compile continues on Pi 5)
class CompileProgressOverlay extends StatefulWidget {
  final bool aiEnhance;
  final VoidCallback onCancel;

  const CompileProgressOverlay({
    super.key,
    required this.aiEnhance,
    required this.onCancel,
  });

  @override
  State<CompileProgressOverlay> createState() => _CompileProgressOverlayState();
}

class _CompileProgressOverlayState extends State<CompileProgressOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;
  int _elapsedSeconds = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  @override
  void dispose() {
    _shimmer.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Material(
      color: Colors.black54,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Shimmer card ───────────────────────────────────────
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      final gradient = LinearGradient(
                        colors: [
                          cs.surfaceContainerHighest,
                          cs.surfaceContainerHigh,
                          cs.surfaceContainerHighest,
                        ],
                        stops: [
                          (_shimmer.value - 0.3).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.3).clamp(0.0, 1.0),
                        ],
                      );
                      return Container(
                        width: 240,
                        height: 16,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _shimmer,
                    builder: (_, __) {
                      final gradient = LinearGradient(
                        colors: [
                          cs.surfaceContainerHighest,
                          cs.surfaceContainerHigh,
                          cs.surfaceContainerHighest,
                        ],
                        stops: [
                          (_shimmer.value - 0.3).clamp(0.0, 1.0),
                          _shimmer.value.clamp(0.0, 1.0),
                          (_shimmer.value + 0.3).clamp(0.0, 1.0),
                        ],
                      );
                      return Container(
                        width: 180,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ── Status text ────────────────────────────────────────
                  Icon(Icons.description_rounded,
                      size: 40, color: cs.primary),
                  const SizedBox(height: 12),
                  Text(
                    'Compiling on Pi 5...',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elapsed: ${_elapsedSeconds}s',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.outline),
                  ),

                  if (widget.aiEnhance) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome_rounded,
                            size: 14, color: cs.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'AI enhancement in progress...',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: cs.tertiary),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Cancel button ──────────────────────────────────────
                  OutlinedButton.icon(
                    onPressed: widget.onCancel,
                    icon: const Icon(Icons.close_rounded),
                    label: const Text('Dismiss'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Compile continues on Pi 5 — result will arrive when done.',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: cs.outline),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\compile_progress_overlay.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\education_item_card.dart -->
# FILE: education_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\education_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline edit card for a single education entry.
class EducationItemCard extends ConsumerStatefulWidget {
  final EducationDto item;
  final bool initiallyExpanded;

  const EducationItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<EducationItemCard> createState() => _EducationItemCardState();
}

class _EducationItemCardState extends ConsumerState<EducationItemCard> {
  late bool _expanded;
  late TextEditingController _instCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _scoreCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _instCtrl = TextEditingController(text: widget.item.institution);
    _areaCtrl = TextEditingController(text: widget.item.area);
    _typeCtrl = TextEditingController(text: widget.item.studyType);
    _startCtrl = TextEditingController(text: widget.item.startDate);
    _endCtrl = TextEditingController(text: widget.item.endDate);
    _scoreCtrl = TextEditingController(text: widget.item.score);
    for (final c in [_instCtrl, _areaCtrl, _typeCtrl, _startCtrl, _endCtrl, _scoreCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_instCtrl, _areaCtrl, _typeCtrl, _startCtrl, _endCtrl, _scoreCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('education', {
      'id': widget.item.id,
      'institution': _instCtrl.text,
      'area': _areaCtrl.text,
      'study_type': _typeCtrl.text,
      'start_date': _startCtrl.text,
      'end_date': _endCtrl.text,
      'score': _scoreCtrl.text,
      'url': widget.item.url,
      'courses': widget.item.courses,
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('edu_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('education', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.institution.isEmpty
                                  ? 'New Education'
                                  : widget.item.institution,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.studyType.isNotEmpty ||
                                widget.item.area.isNotEmpty)
                              Text(
                                '${widget.item.studyType} in ${widget.item.area}',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Institution', _instCtrl),
                    _field('Area / Field of Study', _areaCtrl),
                    _field('Degree Type (e.g. BS, MS)', _typeCtrl),
                    Row(children: [
                      Expanded(child: _field('Start Date', _startCtrl)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('End Date', _endCtrl)),
                    ]),
                    _field('GWA / Score', _scoreCtrl),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true),
        ),
      );

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete education entry?'),
          content: Text('"${widget.item.institution}" will be permanently removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\education_item_card.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\jaccard_score_gauge.dart -->
# FILE: jaccard_score_gauge.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\jaccard_score_gauge.dart`

import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated arc gauge displaying the live Jaccard keyword match score.
///
/// Color interpolation:
///   0–30%  → red    #E53935
///   31–60% → amber  #FFA000
///   61–100%→ green  #43A047
///
/// Uses [AnimationController] + [Tween<double>] for smooth arc transitions.
class JaccardScoreGauge extends StatefulWidget {
  /// Match score in [0.0, 1.0].
  final double score;

  const JaccardScoreGauge({super.key, required this.score});

  @override
  State<JaccardScoreGauge> createState() => _JaccardScoreGaugeState();
}

class _JaccardScoreGaugeState extends State<JaccardScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.0, end: widget.score.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(JaccardScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.score.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _gaugeColor(double score) {
    if (score <= 0.30) return const Color(0xFFE53935);
    if (score <= 0.60) {
      final t = (score - 0.30) / 0.30;
      return Color.lerp(const Color(0xFFE53935), const Color(0xFFFFA000), t)!;
    }
    final t = (score - 0.60) / 0.40;
    return Color.lerp(const Color(0xFFFFA000), const Color(0xFF43A047), t)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final val = _anim.value;
        final pct = (val * 100).round();
        final color = _gaugeColor(val);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 100,
              child: CustomPaint(
                painter: _ArcPainter(
                  value: val,
                  color: color,
                  trackColor: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      '$pct%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Match: $pct%',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              '(live keyword analysis)',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;   // 0.0 – 1.0
  final Color color;
  final Color trackColor;

  const _ArcPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width / 2 - strokeWidth / 2;

    // Track arc (180° from left to right)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    if (value > 0) {
      final valuePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * value,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\jaccard_score_gauge.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\org_item_card.dart -->
# FILE: org_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\org_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline expand-to-edit card for an organizational/leadership experience entry.
///
/// - Collapsed: shows organization name, role, and date range.
/// - Expanded: full edit form with auto-save (800 ms debounce).
/// - Swipe-to-dismiss: optimistic delete via [ResumeMatrixNotifier].
class OrgItemCard extends ConsumerStatefulWidget {
  final OrgItemDto item;
  final bool initiallyExpanded;

  const OrgItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<OrgItemCard> createState() => _OrgItemCardState();
}

class _OrgItemCardState extends ConsumerState<OrgItemCard> {
  late bool _expanded;
  late TextEditingController _orgCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _highlightsCtrl;

  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _orgCtrl = TextEditingController(text: widget.item.organization);
    _roleCtrl = TextEditingController(text: widget.item.role);
    _startCtrl = TextEditingController(text: widget.item.startDate);
    _endCtrl = TextEditingController(text: widget.item.endDate);
    _summaryCtrl = TextEditingController(text: widget.item.summary);
    _highlightsCtrl =
        TextEditingController(text: widget.item.highlights.join('\n'));

    for (final ctrl in [
      _orgCtrl, _roleCtrl, _startCtrl, _endCtrl, _summaryCtrl, _highlightsCtrl,
    ]) {
      ctrl.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ctrl in [
      _orgCtrl, _roleCtrl, _startCtrl, _endCtrl, _summaryCtrl, _highlightsCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final highlights = _highlightsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await ref.read(resumeMatrixProvider.notifier).upsertSection(
      'organizations',
      {
        'id': widget.item.id,
        'organization': _orgCtrl.text,
        'role': _roleCtrl.text,
        'start_date': _startCtrl.text,
        'end_date': _endCtrl.text,
        'summary': _summaryCtrl.text,
        'highlights': highlights,
        'active': widget.item.active,
      },
    );

    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('org_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) {
        ref
            .read(resumeMatrixProvider.notifier)
            .deleteItem('organizations', widget.item.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.organization.isEmpty
                                  ? 'New Org Experience'
                                  : widget.item.organization,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.role.isNotEmpty)
                              Text(
                                widget.item.role,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      if (widget.item.startDate.isNotEmpty)
                        Text(
                          '${widget.item.startDate} – '
                          '${widget.item.endDate.isEmpty ? 'Present' : widget.item.endDate}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),

                  // ── Expanded edit form ──────────────────────────────────
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Organization / Club / Committee', _orgCtrl,
                        hint: 'e.g. ICpEP.SE CTU-MC, Student Government'),
                    _field('Role / Title', _roleCtrl,
                        hint: 'e.g. Secretary, Vice President'),
                    Row(
                      children: [
                        Expanded(child: _field('Start Date', _startCtrl,
                            hint: 'e.g. Aug 2023 or Present')),
                        const SizedBox(width: 8),
                        Expanded(child: _field('End Date', _endCtrl,
                            hint: 'e.g. May 2025 or Present')),
                      ],
                    ),
                    _field(
                      'Summary',
                      _summaryCtrl,
                      maxLines: 2,
                      hint: 'Describe your overall role or involvement',
                    ),
                    _field(
                      'Highlights (one per line — auto-bulleted)',
                      _highlightsCtrl,
                      maxLines: 4,
                      hint: 'e.g. Organized Annual Tech Summit with 200+ attendees',
                      helper: 'Each line becomes a bullet point (•) on the resume',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete org experience?'),
        content: Text(
          '"${widget.item.organization}" will be permanently removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return confirmed ?? false;
  }
}

/// Factory helper — creates a new blank [OrgItemDto] for the FAB add action.
OrgItemDto newBlankOrgItem() => const OrgItemDto(
      id: '',
      organization: '',
      role: '',
      startDate: '',
      endDate: '',
      summary: '',
      highlights: [],
      active: true,
    );


<!-- END_FILE: client_flutter\lib\features\resume\widgets\org_item_card.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\project_item_card.dart -->
# FILE: project_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\project_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline expand-to-edit card for a project entry.
class ProjectItemCard extends ConsumerStatefulWidget {
  final ProjectItemDto item;
  final bool initiallyExpanded;

  const ProjectItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<ProjectItemCard> createState() => _ProjectItemCardState();
}

class _ProjectItemCardState extends ConsumerState<ProjectItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _highlightsCtrl;
  late TextEditingController _keywordsCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _urlCtrl = TextEditingController(text: widget.item.url);
    _highlightsCtrl =
        TextEditingController(text: widget.item.highlights.join('\n'));
    _keywordsCtrl =
        TextEditingController(text: widget.item.keywords.join(', '));
    for (final c in [_nameCtrl, _descCtrl, _urlCtrl, _highlightsCtrl, _keywordsCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _descCtrl, _urlCtrl, _highlightsCtrl, _keywordsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final highlights = _highlightsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await ref.read(resumeMatrixProvider.notifier).upsertSection('projects', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'url': _urlCtrl.text,
      'highlights': highlights,
      'keywords': keywords,
      'exhibits': widget.item.exhibits,
      'active': widget.item.active,
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('project_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('projects', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.item.name.isEmpty ? 'New Project' : widget.item.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (widget.item.description.isNotEmpty && !_expanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Project Name', _nameCtrl),
                    _field('Description', _descCtrl,
                        maxLines: 3,
                        hint: 'Brief overall description of the project'),
                    _field('URL', _urlCtrl,
                        hint: 'e.g. https://github.com/you/project'),
                    _field(
                      'Highlights (one per line — auto-bulleted)',
                      _highlightsCtrl,
                      maxLines: 4,
                      hint: 'e.g. Reduced build time by 60% via parallelized CI pipeline',
                      helper: 'Each line becomes a bullet point (•) on the resume',
                    ),
                    _field(
                      'Keywords (comma-separated)',
                      _keywordsCtrl,
                      hint: 'e.g. Flutter, Dart, Firebase, REST API',
                      helper: 'ATS skill tags — shown as a subtle tag line',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    String? helper,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            helperText: helper,
            helperMaxLines: 2,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
        ),
      );


  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete project?'),
          content: Text('"${widget.item.name}" will be permanently removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\project_item_card.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\resume_section_tab.dart -->
# FILE: resume_section_tab.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\resume_section_tab.dart`

import 'package:flutter/material.dart';

/// Generic tab container used in the 7-tab resume editor.
///
/// Provides a scrollable [ListView] body with a [FloatingActionButton]
/// for adding new items. The [emptyState] is shown when [isEmpty] is true.
class ResumeSectionTab extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final Widget emptyState;
  final Widget child;
  final VoidCallback onAdd;

  const ResumeSectionTab({
    super.key,
    required this.title,
    required this.isEmpty,
    required this.emptyState,
    required this.child,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isEmpty
              ? SizedBox.expand(key: const ValueKey('empty'), child: emptyState)
              : SingleChildScrollView(
                  key: const ValueKey('list'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: child,
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_$title',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text('Add ${title.toLowerCase()}'),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
        ),
      ],
    );
  }
}

/// Illustrated empty state widget shown when a section has no items.
class SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const SectionEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\resume_section_tab.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\skill_chip_row.dart -->
# FILE: skill_chip_row.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\skill_chip_row.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Skill group card with inline keyword chip editing.
///
/// Displays the skill group name and level, with keyword [FilterChip]s.
/// Tapping the edit icon expands to a form for editing name, level, and keywords.
class SkillChipRow extends ConsumerStatefulWidget {
  final SkillDto item;
  final bool initiallyExpanded;

  const SkillChipRow({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<SkillChipRow> createState() => _SkillChipRowState();
}

class _SkillChipRowState extends ConsumerState<SkillChipRow> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _levelCtrl;
  late TextEditingController _keywordsCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _levelCtrl = TextEditingController(text: widget.item.level);
    _keywordsCtrl =
        TextEditingController(text: widget.item.keywords.join(', '));
    for (final c in [_nameCtrl, _levelCtrl, _keywordsCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _levelCtrl, _keywordsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await ref.read(resumeMatrixProvider.notifier).upsertSection('skills', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'level': _levelCtrl.text,
      'keywords': keywords,
    });
    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('skill_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('skills', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.isEmpty
                                  ? 'New Skill Group'
                                  : widget.item.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.level.isNotEmpty)
                              Text(widget.item.level,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.outline)),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (!_expanded && widget.item.keywords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.item.keywords
                          .take(8)
                          .map((k) => Chip(
                                label: Text(k),
                                labelStyle: theme.textTheme.labelSmall,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                    if (widget.item.keywords.length > 8)
                      Text(
                        '+${widget.item.keywords.length - 8} more',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.outline),
                      ),
                  ],
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Skill Group Name', _nameCtrl),
                    _field('Level (e.g. Expert)', _levelCtrl),
                    _field('Keywords (comma-separated)', _keywordsCtrl,
                        maxLines: 3),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true),
        ),
      );

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete skill group?'),
          content:
              Text('"${widget.item.name}" and all keywords will be removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\skill_chip_row.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\template_picker.dart -->
# FILE: template_picker.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\template_picker.dart`

import 'package:flutter/material.dart';

/// Horizontal chip selector for Typst template choice.
///
/// Shows three [ChoiceChip]s: Default / Modern / Minimalist.
/// The selected chip uses solid fill; others are outlined.
class TemplatePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TemplatePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _templates = [
    (id: 'default',    label: 'Default',    icon: Icons.article_outlined),
    (id: 'modern',     label: 'Modern',     icon: Icons.view_sidebar_outlined),
    (id: 'minimalist', label: 'Minimalist', icon: Icons.density_small_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _templates.map((t) {
          final isSelected = t.id == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(t.icon,
                  size: 16,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              label: Text(t.label),
              selected: isSelected,
              onSelected: (_) => onSelected(t.id),
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\template_picker.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\resume\widgets\work_item_card.dart -->
# FILE: work_item_card.dart
**Relative Path**: `client_flutter\lib\features\resume\widgets\work_item_card.dart`

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline expand-to-edit card for a single work experience entry.
///
/// - Collapsed: shows company name, position, date range.
/// - Expanded: full edit form with auto-save (800ms debounce).
/// - Swipe-to-dismiss: optimistic delete via [ResumeMatrixNotifier].
class WorkItemCard extends ConsumerStatefulWidget {
  final WorkItemDto item;
  final bool initiallyExpanded;

  const WorkItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<WorkItemCard> createState() => _WorkItemCardState();
}

class _WorkItemCardState extends ConsumerState<WorkItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _posCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _highlightsCtrl;
  late TextEditingController _keywordsCtrl;


  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _initControllers(widget.item);
  }

  void _initControllers(WorkItemDto item) {
    _nameCtrl = TextEditingController(text: item.name);
    _posCtrl = TextEditingController(text: item.position);
    _startCtrl = TextEditingController(text: item.startDate);
    _endCtrl = TextEditingController(text: item.endDate);
    _summaryCtrl = TextEditingController(text: item.summary);
    _highlightsCtrl =
        TextEditingController(text: item.highlights.join('\n'));
    _keywordsCtrl =
        TextEditingController(text: item.keywords.join(', '));

    for (final ctrl in [
      _nameCtrl, _posCtrl, _startCtrl, _endCtrl, _summaryCtrl,
      _highlightsCtrl, _keywordsCtrl,
    ]) {
      ctrl.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ctrl in [
      _nameCtrl, _posCtrl, _startCtrl, _endCtrl, _summaryCtrl,
      _highlightsCtrl, _keywordsCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final highlights = _highlightsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await ref.read(resumeMatrixProvider.notifier).upsertSection(
      'work',
      {
        'id': widget.item.id,
        'name': _nameCtrl.text,
        'position': _posCtrl.text,
        'start_date': _startCtrl.text,
        'end_date': _endCtrl.text,
        'summary': _summaryCtrl.text,
        'highlights': highlights,
        'keywords': keywords,
        'skills': widget.item.skills,
        'url': widget.item.url,
        'active': widget.item.active,
      },
    );

    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('work_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) {
        ref
            .read(resumeMatrixProvider.notifier)
            .deleteItem('work', widget.item.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.isEmpty
                                  ? 'New Position'
                                  : widget.item.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.position.isNotEmpty)
                              Text(
                                widget.item.position,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      if (widget.item.startDate.isNotEmpty)
                        Text(
                          '${widget.item.startDate} – '
                          '${widget.item.endDate.isEmpty ? 'Present' : widget.item.endDate}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),

                  // ── Expanded edit form ──────────────────────────────────
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Company / Organisation', _nameCtrl),
                    _field('Position / Title', _posCtrl),
                    Row(
                      children: [
                        Expanded(child: _field('Start Date', _startCtrl,
                            hint: 'e.g. Aug 2024 or Present')),
                        const SizedBox(width: 8),
                        Expanded(child: _field('End Date', _endCtrl,
                            hint: 'e.g. May 2026 or Present')),
                      ],
                    ),
                    _field(
                      'Summary',
                      _summaryCtrl,
                      maxLines: 2,
                      hint: 'Describe what you did overall (1–3 sentences)',
                    ),
                    _field(
                      'Highlights (one per line — auto-bulleted)',
                      _highlightsCtrl,
                      maxLines: 5,
                      hint: 'e.g. Led migration of legacy monolith, reducing p99 latency by 40%',
                      helper: 'Each line becomes a bullet point (•) on the resume',
                    ),
                    _field(
                      'Keywords (comma-separated)',
                      _keywordsCtrl,
                      hint: 'e.g. Go, Docker, gRPC, Kubernetes',
                      helper: 'ATS skill tags — shown as a subtle tag line',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }


  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete experience?'),
        content: Text(
          '"${widget.item.name}" will be permanently removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return confirmed ?? false;
  }
}


<!-- END_FILE: client_flutter\lib\features\resume\widgets\work_item_card.dart -->
================================================================================

