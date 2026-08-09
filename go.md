# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 13

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
	WorkLimit     int     `json:"work_limit"`
	ProjectLimit  int     `json:"project_limit"`
	MinScore      float64 `json:"min_score"`
	UseAI         bool    `json:"use_ai"`
	Model         string  `json:"model,omitempty"`
	OffloadTarget string  `json:"offload_target,omitempty"`
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

// extractJSON locates the first '{' and matching last '}' in the string,
// stripping any conversational preamble or markdown code fence blocks.
func extractJSON(s string) string {
	start := strings.Index(s, "{")
	end := strings.LastIndex(s, "}")
	if start != -1 && end != -1 && end > start {
		return s[start : end+1]
	}
	return strings.TrimSpace(s)
}

// mergeMatrix ensures that any section accidentally omitted by the LLM
// is preserved from the original matrix.
func mergeMatrix(orig, enhanced *models.ResumeMatrix) *models.ResumeMatrix {
	if enhanced.Basics.Name == "" {
		enhanced.Basics = orig.Basics
	}
	if len(enhanced.Work) == 0 {
		enhanced.Work = orig.Work
	}
	if len(enhanced.Education) == 0 {
		enhanced.Education = orig.Education
	}
	if len(enhanced.Projects) == 0 {
		enhanced.Projects = orig.Projects
	}
	if len(enhanced.Skills) == 0 {
		enhanced.Skills = orig.Skills
	}
	if len(enhanced.Certificates) == 0 {
		enhanced.Certificates = orig.Certificates
	}
	if len(enhanced.Awards) == 0 {
		enhanced.Awards = orig.Awards
	}
	if len(enhanced.Organizations) == 0 {
		enhanced.Organizations = orig.Organizations
	}
	return enhanced
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
	if !config.UseAI || ipcSend == nil {
		return matrix
	}

	matrixJSON, err := json.Marshal(matrix)
	if err != nil {
		logger.Error("ai_tailor", "failed to marshal matrix for AI route", err, nil)
		return matrix
	}

	var prompt string
	if strings.TrimSpace(jobDescription) != "" {
		prompt = fmt.Sprintf(
			"SYSTEM: You are a JSON transformation engine. Return ONLY valid JSON matching the exact ResumeMatrix schema. Do NOT include markdown blocks, preamble, explanation, or notes.\n\nResume JSON:\n%s\n\nJob Description:\n%s",
			string(matrixJSON), jobDescription,
		)
	} else {
		prompt = fmt.Sprintf(
			"SYSTEM: You are a JSON transformation engine. Return ONLY valid JSON matching the exact ResumeMatrix schema with polished action verbs and impact. Do NOT include markdown blocks, preamble, explanation, or notes.\n\nResume JSON:\n%s",
			string(matrixJSON),
		)
	}

	payload := map[string]interface{}{
		"prompt":       prompt,
		"context_hint": "resume",
	}
	if config.Model != "" {
		payload["model"] = config.Model
	}
	if config.OffloadTarget != "" {
		payload["offload_device_url"] = config.OffloadTarget
	}

	logger.Info("ai_tailor", "⚡ FEEDING RESUME TAILORING PROMPT TO GOVERNOR AI ROUTE", map[string]interface{}{
		"prompt":       prompt,
		"jd_bytes":     len(jobDescription),
		"matrix_bytes": len(matrixJSON),
		"model":        config.Model,
		"offload_url":  config.OffloadTarget,
	})

	reply, err := ipcSend("governor.ai.route", payload)
	if err != nil {
		logger.Warn("ai_tailor", "Governor AI route failed — using original matrix", map[string]interface{}{"error": err.Error()})
		return matrix
	}

	jsonString := extractJSON(reply)

	var enhanced models.ResumeMatrix
	if err := json.Unmarshal([]byte(jsonString), &enhanced); err != nil {
		logger.Warn("ai_tailor", "AI response was not valid JSON — using original matrix", map[string]interface{}{
			"error": err.Error(),
			"raw":   jsonString[:min(200, len(jsonString))],
		})
		return matrix
	}

	merged := mergeMatrix(matrix, &enhanced)
	logger.Info("ai_tailor", "AI tailoring applied successfully", map[string]interface{}{
		"work_items": len(merged.Work),
		"projects":   len(merged.Projects),
	})
	return merged
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

// normalizeDatesInMatrix normalizes all date fields inside a ResumeMatrix
// in-place. Called before Typst compilation to ensure Typst templates always
// receive canonical "Mon YYYY" / "YYYY" / "Present" date strings regardless
// of what was originally stored in SQLite.
//
// Time Complexity:  O(w + e + p + o + c + a) — linear in total section items.
// Space Complexity: O(1) — mutates in place, no allocations.
func normalizeDatesInMatrix(m *models.ResumeMatrix) {
	for i := range m.Work {
		dateutil.NormalizeDateField(&m.Work[i].StartDate)
		dateutil.NormalizeDateField(&m.Work[i].EndDate)
	}
	for i := range m.Education {
		dateutil.NormalizeDateField(&m.Education[i].StartDate)
		dateutil.NormalizeDateField(&m.Education[i].EndDate)
	}
	for i := range m.Organizations {
		dateutil.NormalizeDateField(&m.Organizations[i].StartDate)
		dateutil.NormalizeDateField(&m.Organizations[i].EndDate)
	}
	for i := range m.Certificates {
		dateutil.NormalizeDateField(&m.Certificates[i].Date)
	}
	for i := range m.Awards {
		dateutil.NormalizeDateField(&m.Awards[i].Date)
	}
	logger.Info("hbp_handler", "compile-time date normalization complete", map[string]interface{}{
		"work":          len(m.Work),
		"education":     len(m.Education),
		"organizations": len(m.Organizations),
	})
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
		MatrixID        string `json:"matrix_id" msgpack:"matrix_id"`
		Template        string `json:"template" msgpack:"template"`
		JobDesc         string `json:"job_desc" msgpack:"job_desc"`
		Tailor          bool   `json:"tailor" msgpack:"tailor"`
		AIEnhance       bool   `json:"ai_enhance" msgpack:"ai_enhance"`
		AIModel         string `json:"ai_model" msgpack:"ai_model"`
		AIOffloadTarget string `json:"ai_offload_target" msgpack:"ai_offload_target"`
	}
	if err := decodeMsgpackOrJSON(frame.P, &req); err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, "ERR_MALFORMED_PAYLOAD")
	}
	if req.Template == "" {
		req.Template = "default"
	}

	logger.Info("hbp_handler", "resume.compile dispatched", map[string]interface{}{
		"template": req.Template, "tailor": req.Tailor, "ai_enhance": req.AIEnhance,
		"ai_model": req.AIModel, "ai_offload_target": req.AIOffloadTarget,
	})

	start := time.Now()

	// 1. Load matrix + normalize dates (compile-time guard — ensures old DB data
	//    with non-canonical dates cannot crash the Typst template).
	matrix, err := repository.GetMatrix("shua")
	if err != nil {
		return encodeError(frame.ID, frame.Mod, frame.Op, fmt.Sprintf("ERR_DB: %v", err))
	}
	normalizeDatesInMatrix(matrix)

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
	if req.AIEnhance {
		cfg := ai.DefaultTailorConfig()
		cfg.UseAI = true
		cfg.Model = req.AIModel
		cfg.OffloadTarget = req.AIOffloadTarget
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
	return encodeOK(frame.ID, frame.Mod, frame.Op, map[string]interface{}{
		"1": md, // markdown
	})
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
	// List of subsystem names to exclude (e.g. governor_heartbeat)
	ExcludeSubsystems *[]string `msgpack:"exclude_subsystems"`
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
	// Optional structured telemetry key-value pairs
	Telemetry *map[string]interface{} `msgpack:"telemetry"`
	// Human-readable module identifier (e.g. shua.resume). Canonical string for Flutter attribution.
	ModuleName *string `msgpack:"module_name"`
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

// Request payload for resume.export.markdown
type ResumeExportMarkdownRequest struct {
	// ID of resume matrix to export
	MatrixId string `msgpack:"matrix_id"`
}

// Response payload for resume.export.markdown
type ResumeExportMarkdownResponse struct {
	// Rendered Markdown content of the resume
	Markdown string `msgpack:"markdown"`
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
	// Export the resume matrix as Markdown
	ShuaResumeExportMarkdown = "shua.resume.export.markdown"
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
	"encoding/json"
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
	hbpMagic0    byte  = 0x48 // 'H'
	hbpMagic1    byte  = 0x42 // 'B'
	hbpVersion   byte  = 0x02
	hbpTypeLog   byte  = 0x12
	moduleResume uint8 = 20 // shua.resume module ID
	moduleName         = "shua.resume"
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
	if len(extra) > 0 {
		extraJSON, err := json.Marshal(extra)
		if err != nil {
			stdLogger.Printf("[%s] [%s] [%s] %s (extra fields failed to marshal: %v)",
				time.Now().UTC().Format(time.RFC3339), levelStr, subsystem, msg, err)
		} else {
			stdLogger.Printf("[%s] [%s] [%s] %s %s",
				time.Now().UTC().Format(time.RFC3339), levelStr, subsystem, msg, string(extraJSON))
		}
	} else {
		stdLogger.Printf("[%s] [%s] [%s] %s",
			time.Now().UTC().Format(time.RFC3339), levelStr, subsystem, msg)
	}

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
	"github.com/vmihailenco/msgpack/v5"


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

		// 1. Try JSON unmarshal first (for legacy text frames and tool calls)
		var frame map[string]interface{}
		if err := json.Unmarshal(msg, &frame); err == nil {
			// Check for pending RPC reply (text JSON response)
			id, _ := frame["id"].(string)
			if id != "" {
				s.mu.Lock()
				ch, ok := s.pending[id]
				s.mu.Unlock()
				if ok {
					reply, _ := frame["reply"].(string)
					if reply == "" {
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
			continue
		}

		// 2. Binary frame (HBP v2 MsgPack frame)
		var hbpFrame struct {
			V   uint8                  `msgpack:"v"`
			T   uint8                  `msgpack:"t"`
			ID  string                 `msgpack:"id"`
			Mod string                 `msgpack:"mod"`
			Op  string                 `msgpack:"op"`
			Ts  uint64                 `msgpack:"ts"`
			P   []byte                 `msgpack:"p"`
			Err map[string]interface{} `msgpack:"err"`
		}
		if err := msgpack.Unmarshal(msg, &hbpFrame); err == nil && hbpFrame.ID != "" {
			s.mu.Lock()
			ch, ok := s.pending[hbpFrame.ID]
			s.mu.Unlock()
			if ok {
				var reply string
				if len(hbpFrame.P) > 0 {
					var payload map[string]interface{}
					if err := msgpack.Unmarshal(hbpFrame.P, &payload); err == nil {
						if r, ok := payload["reply"].(string); ok {
							reply = r
						} else {
							b, _ := json.Marshal(payload)
							reply = string(b)
						}
					} else {
						// Fallback: raw UTF-8 string
						reply = string(hbpFrame.P)
					}
				}
				ch <- reply
				s.mu.Lock()
				delete(s.pending, hbpFrame.ID)
				s.mu.Unlock()
				continue
			}
		}

		// Forward unhandled HBP binary frame to handler
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
	if model, ok := payload["model"].(string); ok && model != "" {
		frame["model"] = model
	}
	if offload, ok := payload["offload_device_url"].(string); ok && offload != "" {
		frame["offload_device_url"] = offload
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
	case <-time.After(120 * time.Second):
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

