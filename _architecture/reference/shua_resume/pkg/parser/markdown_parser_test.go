package parser

import (
	"testing"
)

func TestParseMarkdown(t *testing.T) {
	mdContent := `---
name: Joshua B. Ygot
label: Principal Systems Architect
email: joshua@example.com
phone: +63 9XX XXX XXXX
url: https://github.com/joshua
location: Manila, PH
summary: Core developer of horAIzon.
---

## Work Experience
### horAIzon Project | Lead Systems Engineer
*2024-01-01* to *Present*
* Migrated 12 microservices from JSON to MessagePack RPC.
* Built dynamic memory-capped supervisor targeting Pi 5.
* Skills: Go, Rust, C++

## Projects
### agri3d bot | Lead Robotics Developer
* Spatial agricultural robotics platform featuring 3D obstacle avoidance.
* [media: e5a6f2b4-7c9d-4e8f-9a1b-3c5d7e9f1a2b]

## Education
### State University | Computer Engineering
*2022-06-01* to *2026-06-01*
* StudyType: Bachelor of Science
* GPA: 1.2
* Advanced Systems Programming

## Skills
### Systems Programming | Master
* Rust, Go, C++, Cgroup v2, Linux Assembly

## Certificates
### Advanced Embedded Systems Architect | IEEE
*2025-10-15*
* URL: https://ieee.org/cert/123
* ID: CERT-98765

## Awards
### Outstanding Developer | Google
*2026-05-01*
* Received award for core runtime supervisor optimization.
`

	matrix, err := ParseMarkdown(mdContent)
	if err != nil {
		t.Fatalf("ParseMarkdown returned error: %v", err)
	}

	// 1. Basics Verification
	if matrix.Basics.Name != "Joshua B. Ygot" {
		t.Errorf("Expected Name 'Joshua B. Ygot', got '%s'", matrix.Basics.Name)
	}
	if matrix.Basics.Location.City != "Manila" || matrix.Basics.Location.CountryCode != "PH" {
		t.Errorf("Expected Location Manila, PH; got %s, %s", matrix.Basics.Location.City, matrix.Basics.Location.CountryCode)
	}

	// 2. Work Experience Verification
	if len(matrix.Work) != 1 {
		t.Fatalf("Expected 1 work item, got %d", len(matrix.Work))
	}
	work := matrix.Work[0]
	if work.Name != "horAIzon Project" || work.Position != "Lead Systems Engineer" {
		t.Errorf("Unexpected work details: %+v", work)
	}
	if work.StartDate != "2024-01-01" || work.EndDate != "Present" {
		t.Errorf("Unexpected work dates: %s to %s", work.StartDate, work.EndDate)
	}
	if len(work.Highlights) != 2 || work.Highlights[0] != "Migrated 12 microservices from JSON to MessagePack RPC." {
		t.Errorf("Unexpected highlights: %v", work.Highlights)
	}
	if len(work.Skills) != 3 || work.Skills[0] != "Go" || work.Skills[1] != "Rust" {
		t.Errorf("Unexpected work skills: %v", work.Skills)
	}

	// 3. Projects Verification
	if len(matrix.Projects) != 1 {
		t.Fatalf("Expected 1 project, got %d", len(matrix.Projects))
	}
	proj := matrix.Projects[0]
	if proj.Name != "agri3d bot" {
		t.Errorf("Expected project name 'agri3d bot', got '%s'", proj.Name)
	}
	if proj.Description != "Spatial agricultural robotics platform featuring 3D obstacle avoidance." {
		t.Errorf("Unexpected project description: '%s'", proj.Description)
	}
	if len(proj.Exhibits) != 1 || proj.Exhibits[0] != "e5a6f2b4-7c9d-4e8f-9a1b-3c5d7e9f1a2b" {
		t.Errorf("Unexpected project exhibits: %v", proj.Exhibits)
	}

	// 4. Education Verification
	if len(matrix.Education) != 1 {
		t.Fatalf("Expected 1 education item, got %d", len(matrix.Education))
	}
	edu := matrix.Education[0]
	if edu.Institution != "State University" || edu.Area != "Computer Engineering" {
		t.Errorf("Unexpected education headers: %+v", edu)
	}
	if edu.StudyType != "Bachelor of Science" || edu.Score != "1.2" {
		t.Errorf("Unexpected education study type/score: studyType='%s', score='%s'", edu.StudyType, edu.Score)
	}
	if len(edu.Courses) != 1 || edu.Courses[0] != "Advanced Systems Programming" {
		t.Errorf("Unexpected education courses: %v", edu.Courses)
	}

	// 5. Skills Verification
	if len(matrix.Skills) != 1 {
		t.Fatalf("Expected 1 skill block, got %d", len(matrix.Skills))
	}
	skill := matrix.Skills[0]
	if skill.Name != "Systems Programming" || skill.Level != "Master" {
		t.Errorf("Unexpected skill headers: %+v", skill)
	}
	if len(skill.Keywords) != 5 || skill.Keywords[0] != "Rust" || skill.Keywords[4] != "Linux Assembly" {
		t.Errorf("Unexpected skill keywords: %v", skill.Keywords)
	}

	// 6. Certificates Verification
	if len(matrix.Certificates) != 1 {
		t.Fatalf("Expected 1 certificate, got %d", len(matrix.Certificates))
	}
	cert := matrix.Certificates[0]
	if cert.Name != "Advanced Embedded Systems Architect" || cert.Issuer != "IEEE" || cert.Date != "2025-10-15" {
		t.Errorf("Unexpected cert details: %+v", cert)
	}
	if cert.Url != "https://ieee.org/cert/123" || cert.Id != "CERT-98765" {
		t.Errorf("Unexpected cert URL/ID: URL='%s', ID='%s'", cert.Url, cert.Id)
	}

	// 7. Awards Verification
	if len(matrix.Awards) != 1 {
		t.Fatalf("Expected 1 award, got %d", len(matrix.Awards))
	}
	award := matrix.Awards[0]
	if award.Title != "Outstanding Developer" || award.Sender != "Google" || award.Date != "2026-05-01" {
		t.Errorf("Unexpected award details: %+v", award)
	}
	if award.Summary != "Received award for core runtime supervisor optimization." {
		t.Errorf("Unexpected award summary: '%s'", award.Summary)
	}
}
