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

// findModuleRoot traverses upwards from the current directory to find the module root (containing go.mod)
func findModuleRoot() string {
	cwd, err := os.Getwd()
	if err != nil {
		return "."
	}
	dir := cwd
	for {
		if _, err := os.Stat(filepath.Join(dir, "go.mod")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			break
		}
		dir = parent
	}
	return "."
}

// resolveTypstPath attempts to locate the typst binary in system PATH, falling back to local user WinGet links
func resolveTypstPath() string {
	path, err := exec.LookPath("typst")
	if err == nil {
		return path
	}

	// Fallback for Windows
	userProfile := os.Getenv("USERPROFILE")
	if userProfile != "" {
		winGetLink := filepath.Join(userProfile, "AppData", "Local", "Microsoft", "WinGet", "Links", "typst.exe")
		if _, err := os.Stat(winGetLink); err == nil {
			return winGetLink
		}
	}

	// Fallback for Linux (e.g. Pi 5 when run under systemd, missing .cargo/bin from user path)
	for _, fallback := range []string{
		"/home/shua/.cargo/bin/typst",
		"/usr/local/bin/typst",
		"/usr/bin/typst",
	} {
		if _, err := os.Stat(fallback); err == nil {
			return fallback
		}
	}

	// Default to invoking raw command and let system resolve
	return "typst"
}

// CompileTypst takes a ResumeMatrix, template name, and compiles it to a PDF byte slice.
// It executes the typst CLI under a strict 500ms timeout context.
func CompileTypst(matrix *models.ResumeMatrix, templateName string) ([]byte, error) {
	jsonData, err := json.Marshal(matrix)
	if err != nil {
		return nil, fmt.Errorf("failed to marshal resume matrix: %w", err)
	}

	// Escape JSON for Typst string literal
	escapedJSON := string(jsonData)
	escapedJSON = strings.ReplaceAll(escapedJSON, "\\", "\\\\")
	escapedJSON = strings.ReplaceAll(escapedJSON, "\"", "\\\"")

	// Construct the stdin document that imports the template and invokes it.
	// We use the relative path starting from the module root.
	typstInput := fmt.Sprintf(`#import "pkg/templates/%s.typ": resume_template
#let data = json(bytes("%s"))
#show: doc => resume_template(data)
`, templateName, escapedJSON)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	typstBin := resolveTypstPath()
	cmd := exec.CommandContext(ctx, typstBin, "compile", "--ignore-system-fonts", "-", "-")
	cmd.Stdin = strings.NewReader(typstInput)
	
	// Enforce the command's working directory to be the module root where pkg/templates lives
	cmd.Dir = findModuleRoot()

	var stdoutBuf bytes.Buffer
	var stderrBuf bytes.Buffer
	cmd.Stdout = &stdoutBuf
	cmd.Stderr = &stderrBuf

	startTime := time.Now()
	err = cmd.Run()
	latency := time.Since(startTime).Milliseconds()

	if err != nil {
		logger.Error("compiler", "typst compilation failed", err, map[string]interface{}{
			"template":   templateName,
			"latency_ms": latency,
			"stderr":     stderrBuf.String(),
		})
		if ctx.Err() == context.DeadlineExceeded {
			return nil, fmt.Errorf("typst compile timeout (3s exceeded)")
		}
		return nil, fmt.Errorf("typst compile error: %w (stderr: %s)", err, stderrBuf.String())
	}

	logger.Info("compiler", "typst compiled successfully", map[string]interface{}{
		"template":   templateName,
		"latency_ms": latency,
		"pdf_bytes":  stdoutBuf.Len(),
	})

	return stdoutBuf.Bytes(), nil
}
