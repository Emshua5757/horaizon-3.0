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

// MatrixToMarkdown generates a plain-text Markdown fallback when Typst is unavailable.
func MatrixToMarkdown(matrix *models.ResumeMatrix) string {
	var sb strings.Builder

	sb.WriteString(fmt.Sprintf("# %s\n\n", matrix.Basics.Name))
	sb.WriteString(fmt.Sprintf("**%s** | %s | %s | %s\n\n",
		matrix.Basics.Label, matrix.Basics.Email, matrix.Basics.Phone,
		matrix.Basics.Location.City+", "+matrix.Basics.Location.Region))

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
			for _, h := range w.Highlights {
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
		sb.WriteString("## Awards\n\n")
		for _, a := range matrix.Awards {
			sb.WriteString(fmt.Sprintf("- **%s** (%s) — %s\n", a.Title, a.Date, a.Sender))
		}
		sb.WriteString("\n")
	}

	return sb.String()
}
