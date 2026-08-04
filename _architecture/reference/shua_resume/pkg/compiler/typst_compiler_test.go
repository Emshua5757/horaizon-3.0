package compiler

import (
	"bytes"
	"testing"

	"shua_resume/pkg/models"
)

func TestCompileTypst(t *testing.T) {
	matrix := &models.ResumeMatrix{
		Basics: models.Basics{
			Name:  "Test Compiler User",
			Label: "Software Architect",
			Email: "test@example.com",
			Phone: "123-456-7890",
			Url:   "https://example.com",
		},
		Work: []models.WorkItem{
			{
				Name:       "Test Comp Inc",
				Position:   "Developer",
				StartDate:  "2023-01-01",
				EndDate:    "Present",
				Summary:    "Compiling resumes under Pi 5 guidelines",
				Highlights: []string{"High performance Go and Typst pipeline"},
				Active:     true,
			},
		},
	}

	pdfBytes, err := CompileTypst(matrix, "ats_technical")
	if err != nil {
		t.Fatalf("CompileTypst failed: %v", err)
	}

	if len(pdfBytes) < 4 {
		t.Fatalf("Compiled PDF bytes are too short: %d bytes", len(pdfBytes))
	}

	// Verify standard PDF header magic bytes (%PDF)
	pdfMagic := []byte("%PDF")
	if !bytes.HasPrefix(pdfBytes, pdfMagic) {
		t.Errorf("Expected PDF header prefix %v, got %v", pdfMagic, pdfBytes[:4])
	}
}
