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
