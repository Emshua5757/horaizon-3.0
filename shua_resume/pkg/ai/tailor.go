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

	reply, err := ipcSend("governor.ai.route", payload)
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
