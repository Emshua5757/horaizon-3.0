package ai

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"regexp"
	"sort"
	"strings"
	"time"

	"shua_resume/pkg/logger"
	"shua_resume/pkg/models"
)

var wordRegex = regexp.MustCompile(`[a-zA-Z0-9+#.-]+`)

// Tokenize processes raw text, splits it into lowercase alphanumeric tokens, and returns a unique set.
func Tokenize(text string) map[string]bool {
	tokens := make(map[string]bool)
	matches := wordRegex.FindAllString(strings.ToLower(text), -1)
	for _, match := range matches {
		cleaned := strings.TrimRight(match, ".,!?;:")
		if len(cleaned) > 1 { // skip single letter noise
			tokens[cleaned] = true
		}
	}
	return tokens
}

// JaccardSimilarity calculates similarity score between two token sets.
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

// TailorConfig contains options to dynamically adjust the relevance filtering and AI tailoring pass.
type TailorConfig struct {
	WorkLimit    int     `json:"work_limit"`
	ProjectLimit int     `json:"project_limit"`
	MinScore     float64 `json:"min_score"`
	UseAI        bool    `json:"use_ai"`
}

// DefaultTailorConfig returns the default tailoring configuration values.
func DefaultTailorConfig() TailorConfig {
	return TailorConfig{
		WorkLimit:    3,
		ProjectLimit: 2,
		MinScore:     0.0,
		UseAI:        true,
	}
}

// FilterResume ranks and activates work items and projects based on relevance score and configuration thresholds.
func FilterResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix {
	if strings.TrimSpace(jobDescription) == "" {
		// If no job description is provided, keep everything active by default
		for i := range matrix.Work {
			matrix.Work[i].Active = true
		}
		for i := range matrix.Projects {
			matrix.Projects[i].Active = true
		}
		return matrix
	}

	jdTokens := Tokenize(jobDescription)

	// 1. Filter Work Items
	type workScore struct {
		index int
		score float64
	}
	workScores := make([]workScore, 0, len(matrix.Work))
	for i, item := range matrix.Work {
		content := strings.Join([]string{
			item.Name,
			item.Position,
			item.Summary,
			strings.Join(item.Highlights, " "),
			strings.Join(item.Skills, " "),
		}, " ")
		itemTokens := Tokenize(content)
		score := JaccardSimilarity(jdTokens, itemTokens)
		if score >= config.MinScore {
			workScores = append(workScores, workScore{
				index: i,
				score: score,
			})
		}
	}

	// Stable sort by score descending
	sort.SliceStable(workScores, func(i, j int) bool {
		return workScores[i].score > workScores[j].score
	})

	for i := range matrix.Work {
		matrix.Work[i].Active = false
	}
	// Activate up to WorkLimit
	for i := 0; i < len(workScores) && i < config.WorkLimit; i++ {
		matrix.Work[workScores[i].index].Active = true
	}

	// 2. Filter Projects
	type projectScore struct {
		index int
		score float64
	}
	projectScores := make([]projectScore, 0, len(matrix.Projects))
	for i, item := range matrix.Projects {
		content := strings.Join([]string{
			item.Name,
			item.Description,
			strings.Join(item.Highlights, " "),
		}, " ")
		itemTokens := Tokenize(content)
		score := JaccardSimilarity(jdTokens, itemTokens)
		if score >= config.MinScore {
			projectScores = append(projectScores, projectScore{
				index: i,
				score: score,
			})
		}
	}

	sort.SliceStable(projectScores, func(i, j int) bool {
		return projectScores[i].score > projectScores[j].score
	})

	for i := range matrix.Projects {
		matrix.Projects[i].Active = false
	}
	// Activate up to ProjectLimit
	for i := 0; i < len(projectScores) && i < config.ProjectLimit; i++ {
		matrix.Projects[projectScores[i].index].Active = true
	}

	return matrix
}

// OllamaRequest represents the request body schema for the Governor AI inference endpoint.
type OllamaRequest struct {
	Model  string `json:"model"`
	Prompt string `json:"prompt"`
	Stream bool   `json:"stream"`
}

// OllamaResponse represents the response body schema from the Governor AI inference endpoint.
type OllamaResponse struct {
	Response string `json:"response"`
	Error    string `json:"error"`
}

// TailorResume attempts to connect to Governor's /api/ai/infer to rewrite bullet points.
// If it fails or times out, it falls back gracefully to the original resume highlights.
func TailorResume(matrix *models.ResumeMatrix, jobDescription string, config TailorConfig) *models.ResumeMatrix {
	if !config.UseAI || strings.TrimSpace(jobDescription) == "" {
		return matrix
	}

	client := &http.Client{
		Timeout: 6 * time.Second, // Tight timeout to prevent blocking UI
	}

	// Use model qwen3.5:4b which is installed locally
	modelName := "qwen3.5:4b"

	for i, work := range matrix.Work {
		if !work.Active || len(work.Highlights) == 0 {
			continue
		}

		prompt := fmt.Sprintf(`You are a professional resume writer. Rewrite the bullet points (highlights) for the role of "%s" at "%s" to emphasize skills and experience matching the target Job Description.

Target Job Description:
%s

Original Highlights:
%s

Constraints:
1. Do NOT invent new jobs, projects, skills, dates, or metrics.
2. Preserve the truth of the original highlights.
3. Output ONLY the rewritten bullet points, one per line starting with "* ". Do not include introductions, explanations, explanations of changes, or markdown code blocks.`, 
			work.Position, work.Name, jobDescription, strings.Join(work.Highlights, "\n"))

		reqBody, err := json.Marshal(OllamaRequest{
			Model:  modelName,
			Prompt: prompt,
			Stream: false,
		})
		if err != nil {
			logger.Error("ai_tailor", "Failed to marshal Ollama request payload", err, nil)
			continue
		}

		resp, err := client.Post("http://127.0.0.1:3000/api/ai/infer", "application/json", bytes.NewBuffer(reqBody))
		if err != nil {
			// Fail-safe: log warning and proceed with original highlights
			logger.Error("ai_tailor", fmt.Sprintf("Failed to query Governor AI proxy for work item %d (falling back to original)", i), err, nil)
			continue
		}

		var ollamaResp OllamaResponse
		err = json.NewDecoder(resp.Body).Decode(&ollamaResp)
		resp.Body.Close()

		if err != nil {
			logger.Error("ai_tailor", "Failed to decode Ollama response", err, nil)
			continue
		}

		if resp.StatusCode != http.StatusOK {
			logger.Error("ai_tailor", fmt.Sprintf("Governor AI proxy returned status code %d: %s", resp.StatusCode, ollamaResp.Error), nil, nil)
			continue
		}

		// Parse the bullet points from the model's text response
		lines := strings.Split(ollamaResp.Response, "\n")
		var newHighlights []string
		for _, line := range lines {
			line = strings.TrimSpace(line)
			if strings.HasPrefix(line, "* ") || strings.HasPrefix(line, "- ") {
				cleaned := strings.TrimSpace(line[2:])
				if cleaned != "" {
					newHighlights = append(newHighlights, cleaned)
				}
			}
		}

		if len(newHighlights) > 0 {
			logger.Info("ai_tailor", fmt.Sprintf("Successfully tailored highlights for %s at %s", work.Position, work.Name), nil)
			matrix.Work[i].Highlights = newHighlights
		} else {
			logger.Error("ai_tailor", "Model output did not match bullet format constraints; using original highlights", nil, map[string]interface{}{
				"raw_response": ollamaResp.Response,
			})
		}
	}

	return matrix
}
