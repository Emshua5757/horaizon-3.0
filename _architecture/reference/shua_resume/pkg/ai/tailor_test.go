package ai

import (
	"testing"

	"shua_resume/pkg/models"
)

func TestTokenize(t *testing.T) {
	text := "Go, Rust, C++ & TinyML! Cgroup v2."
	tokens := Tokenize(text)

	expected := []string{"go", "rust", "c++", "tinyml", "cgroup", "v2"}
	for _, exp := range expected {
		if !tokens[exp] {
			t.Errorf("Expected token '%s' to be present", exp)
		}
	}
}

func TestJaccardSimilarity(t *testing.T) {
	setA := map[string]bool{"rust": true, "go": true, "systems": true}
	setB := map[string]bool{"rust": true, "systems": true, "embedded": true}

	// Intersection: rust, systems (2)
	// Union: rust, go, systems, embedded (4)
	// Similarity: 2/4 = 0.5
	score := JaccardSimilarity(setA, setB)
	if score != 0.5 {
		t.Errorf("Expected Jaccard similarity to be 0.5, got %f", score)
	}
}

func TestFilterResume(t *testing.T) {
	matrix := &models.ResumeMatrix{
		Work: []models.WorkItem{
			{Name: "Alpha", Summary: "Web dev JavaScript React", Active: true},
			{Name: "Beta", Summary: "Embedded systems firmware C++ microcontrollers", Active: true},
			{Name: "Gamma", Summary: "System programming Rust Go kernels Linux", Active: true},
			{Name: "Delta", Summary: "Machine learning Python PyTorch TinyML programmer", Active: true},
		},
		Projects: []models.ProjectItem{
			{Name: "Proj1", Description: "Robotics computer vision ROS C++", Active: true},
			{Name: "Proj2", Description: "Web blog database CSS HTML", Active: true},
			{Name: "Proj3", Description: "Compiler interpreter assembly Rust", Active: true},
		},
	}

	// Filter with target job description emphasizing Rust and Systems kernel
	jd := "Looking for a systems programmer with experience in Go, Rust, kernel, and Linux architectures."
	filtered := FilterResume(matrix, jd, DefaultTailorConfig())

	// Gamma (Rust, Go, Systems, Linux) should have high Jaccard and be active.
	// Alpha (JavaScript, React) should be inactive as it has lowest score and we select top 3.
	if !filtered.Work[2].Active {
		t.Errorf("Expected Gamma (index 2) to be active (high similarity to systems programming)")
	}
	if filtered.Work[0].Active {
		t.Errorf("Expected Alpha (index 0) to be inactive (low similarity to systems programming)")
	}

	// Projects: Proj3 (Rust compile assembly) and Proj1 (ROS C++ robotics) should be active, Proj2 (web CSS) should be inactive.
	if !filtered.Projects[2].Active {
		t.Errorf("Expected Proj3 (index 2) to be active")
	}
	if filtered.Projects[1].Active {
		t.Errorf("Expected Proj2 (index 1) to be inactive")
	}
}
