package ai

import (
	"shua_resume/pkg/models"
	"testing"
)

func TestTailorResumeViaGovernor_MockIPC(t *testing.T) {
	matrix := &models.ResumeMatrix{
		Basics: models.Basics{Name: "Joshua Ygot"},
	}

	mockIpcSend := func(op string, payload map[string]interface{}) (string, error) {
		if op != "ai.route" {
			t.Fatalf("expected op 'ai.route', got '%s'", op)
		}

		prompt, ok := payload["prompt"].(string)
		if !ok || len(prompt) == 0 {
			t.Fatal("fail: prompt was missing or empty in payload!")
		}

		t.Logf("SUCCESS! Intercepted prompt length: %d", len(prompt))

		return `{"basics":{"name":"Joshua Ygot - AI Enhanced"}}`, nil
	}

	config := TailorConfig{
		UseAI: true,
		Model: "qwen2.5-coder:7b",
	}

	result := TailorResumeViaGovernor(matrix, "Golang and Flutter developer", config, mockIpcSend)

	if result.Basics.Name != "Joshua Ygot - AI Enhanced" {
		t.Fatal("fail: AI response was not merged correctly")
	}
}
