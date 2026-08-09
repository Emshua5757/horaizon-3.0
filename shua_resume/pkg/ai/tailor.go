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
	logger.Info("ai_tailor", "🔍 DEBUG FINAL PROMPT CHECK", map[string]interface{}{
		"prompt_length":  len(prompt),
		"prompt_preview": prompt[:min(100, len(prompt))],
		"payload_map":    payload,
	})
	reply, err := ipcSend("ai.route", payload)
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
