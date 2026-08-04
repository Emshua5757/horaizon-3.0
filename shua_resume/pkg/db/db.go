package db

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
	_ "modernc.org/sqlite"

	"shua_resume/pkg/logger"
)

var (
	// DB is the global SQLite connection (WAL mode, single writer).
	DB   *sql.DB
	once sync.Once
)

// InitDB opens the SQLite database at dbPath, applies migrations, and seeds baseline data.
// Safe to call multiple times — the sync.Once ensures a single open.
func InitDB(dbPath string) error {
	var initErr error
	once.Do(func() {
		var err error
		DB, err = sql.Open("sqlite", dbPath+"?_journal_mode=WAL&_foreign_keys=on")
		if err != nil {
			initErr = fmt.Errorf("failed to open database: %w", err)
			return
		}
		if err = DB.Ping(); err != nil {
			initErr = fmt.Errorf("failed to ping SQLite: %w", err)
			return
		}
		// Bounded pool — single writer model for Pi 5
		DB.SetMaxOpenConns(1)
		DB.SetMaxIdleConns(1)

		if err = runMigrations(); err != nil {
			initErr = fmt.Errorf("migration failure: %w", err)
			return
		}
		if err = seedDatabase(); err != nil {
			initErr = fmt.Errorf("seed failure: %w", err)
			return
		}
		logger.Info("database", "Database initialized and migrated", map[string]interface{}{
			"path": dbPath,
		})
	})
	return initErr
}

func runMigrations() error {
	statements := []string{
		`CREATE TABLE IF NOT EXISTS resume_basics (
			user_id       TEXT PRIMARY KEY DEFAULT 'shua',
			name          TEXT NOT NULL DEFAULT '',
			label         TEXT NOT NULL DEFAULT '',
			email         TEXT NOT NULL DEFAULT '',
			phone         TEXT NOT NULL DEFAULT '',
			url           TEXT NOT NULL DEFAULT '',
			summary       TEXT NOT NULL DEFAULT '',
			city          TEXT NOT NULL DEFAULT '',
			region        TEXT NOT NULL DEFAULT '',
			country_code  TEXT NOT NULL DEFAULT '',
			profiles_json TEXT NOT NULL DEFAULT '[]',
			updated_at    TEXT NOT NULL
		);`,
		`CREATE TABLE IF NOT EXISTS resume_work (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			name        TEXT NOT NULL DEFAULT '',
			position    TEXT NOT NULL DEFAULT '',
			url         TEXT NOT NULL DEFAULT '',
			start_date  TEXT NOT NULL DEFAULT '',
			end_date    TEXT NOT NULL DEFAULT '',
			summary     TEXT NOT NULL DEFAULT '',
			highlights  TEXT NOT NULL DEFAULT '[]',
			skills      TEXT NOT NULL DEFAULT '[]',
			active      INTEGER NOT NULL DEFAULT 1,
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_education (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			institution TEXT NOT NULL DEFAULT '',
			url         TEXT NOT NULL DEFAULT '',
			area        TEXT NOT NULL DEFAULT '',
			study_type  TEXT NOT NULL DEFAULT '',
			start_date  TEXT NOT NULL DEFAULT '',
			end_date    TEXT NOT NULL DEFAULT '',
			score       TEXT NOT NULL DEFAULT '',
			courses     TEXT NOT NULL DEFAULT '[]',
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_projects (
			id          TEXT PRIMARY KEY,
			user_id     TEXT NOT NULL DEFAULT 'shua',
			name        TEXT NOT NULL DEFAULT '',
			description TEXT NOT NULL DEFAULT '',
			highlights  TEXT NOT NULL DEFAULT '[]',
			url         TEXT NOT NULL DEFAULT '',
			exhibits    TEXT NOT NULL DEFAULT '[]',
			active      INTEGER NOT NULL DEFAULT 1,
			sort_order  INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_skills (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			name       TEXT NOT NULL DEFAULT '',
			level      TEXT NOT NULL DEFAULT '',
			keywords   TEXT NOT NULL DEFAULT '[]',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_certificates (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			name       TEXT NOT NULL DEFAULT '',
			issuer     TEXT NOT NULL DEFAULT '',
			date       TEXT NOT NULL DEFAULT '',
			url        TEXT NOT NULL DEFAULT '',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_awards (
			id         TEXT PRIMARY KEY,
			user_id    TEXT NOT NULL DEFAULT 'shua',
			title      TEXT NOT NULL DEFAULT '',
			date       TEXT NOT NULL DEFAULT '',
			awarder    TEXT NOT NULL DEFAULT '',
			summary    TEXT NOT NULL DEFAULT '',
			sort_order INTEGER NOT NULL DEFAULT 0
		);`,
		`CREATE TABLE IF NOT EXISTS resume_history (
			exhibit_id   TEXT PRIMARY KEY,
			vault_url    TEXT NOT NULL,
			template_id  TEXT NOT NULL DEFAULT '',
			job_desc     TEXT NOT NULL DEFAULT '',
			tailor_score REAL,
			ai_enhanced  INTEGER NOT NULL DEFAULT 0,
			duration_ms  INTEGER NOT NULL DEFAULT 0,
			compiled_at  TEXT NOT NULL
		);`,
	}

	for _, stmt := range statements {
		if _, err := DB.Exec(stmt); err != nil {
			return fmt.Errorf("migration error: %w", err)
		}
	}

	// Additive migrations for existing deployments — idempotent via IF NOT EXISTS / IGNORE.
	additiveMigrations := []string{
		`ALTER TABLE resume_work ADD COLUMN keywords TEXT NOT NULL DEFAULT '[]'`,
		`ALTER TABLE resume_projects ADD COLUMN keywords TEXT NOT NULL DEFAULT '[]'`,
		`CREATE TABLE IF NOT EXISTS resume_organizations (
			id           TEXT PRIMARY KEY,
			user_id      TEXT NOT NULL DEFAULT 'shua',
			organization TEXT NOT NULL DEFAULT '',
			role         TEXT NOT NULL DEFAULT '',
			start_date   TEXT NOT NULL DEFAULT '',
			end_date     TEXT NOT NULL DEFAULT '',
			summary      TEXT NOT NULL DEFAULT '',
			highlights   TEXT NOT NULL DEFAULT '[]',
			active       INTEGER NOT NULL DEFAULT 1,
			sort_order   INTEGER NOT NULL DEFAULT 0
		);`,
	}
	for _, stmt := range additiveMigrations {
		// Ignore errors — ALTER TABLE fails harmlessly if column already exists.
		_, _ = DB.Exec(stmt)
	}

	return nil
}

// seedDatabase inserts Joshua B. Ygot's master profile if tables are empty.
func seedDatabase() error {
	var count int
	if err := DB.QueryRow("SELECT COUNT(*) FROM resume_basics").Scan(&count); err != nil {
		return err
	}
	if count > 0 {
		return nil // already seeded
	}

	now := time.Now().UTC().Format(time.RFC3339)

	// ── Basics ──────────────────────────────────────────────────────────────────
	profiles, _ := json.Marshal([]map[string]string{
		{"network": "LinkedIn", "username": "joshua-ygot-298a5736a", "url": "https://www.linkedin.com/in/joshua-ygot-298a5736a"},
	})
	if _, err := DB.Exec(`INSERT INTO resume_basics
		(user_id,name,label,email,phone,url,summary,city,region,country_code,profiles_json,updated_at) VALUES
		(?,?,?,?,?,?,?,?,?,?,?,?)`,
		"shua",
		"Joshua B. Ygot",
		"Computer Engineer & Embedded Systems Specialist",
		"ygot.joshua5142004@gmail.com",
		"09615981753",
		"https://www.linkedin.com/in/joshua-ygot-298a5736a",
		"Computer Engineering student and systems engineer specializing in hardware-software co-design, embedded systems, and mobile client integrations. Certified in Java Programming, Internet of Things, Creative Web Design, and Data Analytics. Experienced in custom firmware optimization, hardware prototyping, and edge-native ML deployment.",
		"Mandaue City",
		"Cebu",
		"PH",
		string(profiles),
		now,
	); err != nil {
		return fmt.Errorf("seed basics: %w", err)
	}

	// ── Work ────────────────────────────────────────────────────────────────────
	type workSeed struct {
		name, position, startDate, endDate, summary string
		highlights, skills                          []string
	}
	workItems := []workSeed{
		{
			name: "Sustainable Center for Engineering and Next-Generation Technology",
			position: "Project Research Assistant (Intern)",
			startDate: "2026-02-01", endDate: "2026-05-01",
			summary: "Research and systems engineering for the Agri3D automated horticulture platform.",
			highlights: []string{
				"Embedded Firmware: Customized the GRBL motion control engine on an ATmega328P, stripping unused modules to optimize Flash footprint and interfacing stepper drivers via custom routines.",
				"Hardware Co-design: Routed a custom PCB shield in KiCAD for an Arduino Nano host to drive stepper control circuits.",
				"Dynamic Modeling & Kinematics: Modeled mechanical linkages and 3D-printed components using Autodesk Inventor and Fusion 360, with animation in Blender.",
				"Client Integration: Integrated hardware state telemetry with a cross-platform mobile client built in Flutter.",
				"TinyML & Computer Vision: Engineered and trained an edge-native classification model using Edge Impulse for real-time weed detection, deploying the optimized C++ model library onto an ESP32 node for localized, low-latency inferencing.",
			},
			skills: []string{"Research and Development (R&D)", "Embedded Systems", "Mechatronics", "Flutter"},
		},
		{
			name: "Department of Science and Technology (DOST)",
			position: "On-the-Job Trainee – Quality Assurance (Intern)",
			startDate: "2025-07-01", endDate: "2025-08-01",
			summary: "Participated in the League of Developers Initiative (Project LODI), supporting quality assurance and system compliance workflows for the Information Technology Division.",
			highlights: []string{
				"Test Specification Engineering: Translated technical requirements into structured test case specifications to validate system behavior against functional specifications.",
				"Defect Isolation: Executed systematic test protocols, logging results and verifying compliance boundaries for remote software services.",
				"SDLC Standards: Maintained requirement-to-test traceability matrices in accordance with agency engineering and documentation standards.",
			},
			skills: []string{"Quality Assurance"},
		},
	}
	for i, w := range workItems {
		h, _ := json.Marshal(w.highlights)
		s, _ := json.Marshal(w.skills)
		kw, _ := json.Marshal([]string{})
		if _, err := DB.Exec(`INSERT INTO resume_work (id,user_id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", w.name, w.position, "", w.startDate, w.endDate, w.summary, string(h), string(kw), string(s), 1, i,
		); err != nil {
			return fmt.Errorf("seed work: %w", err)
		}
	}

	// ── Education ───────────────────────────────────────────────────────────────
	type eduSeed struct {
		institution, area, studyType, startDate, endDate, score string
		courses                                                  []string
	}
	eduItems := []eduSeed{
		{"Cebu Technological University Main Campus", "Computer Engineering", "Bachelor of Science", "2022-08-01", "2026-07-01", "GWA: 1.35",
			[]string{"Embedded Systems", "Microprocessors", "Hardware Description Languages", "Data Structures and Algorithms"}},
		{"Mandaue City Science High School", "Secondary Education (High School)", "With Honors", "2016-06-01", "2022-05-01", "With Honors", []string{}},
		{"Opao Elementary School", "Primary Education (Elementary)", "Valedictorian", "2010-06-01", "2016-03-01", "Valedictorian", []string{}},
	}
	for i, e := range eduItems {
		c, _ := json.Marshal(e.courses)
		if _, err := DB.Exec(`INSERT INTO resume_education (id,user_id,institution,url,area,study_type,start_date,end_date,score,courses,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", e.institution, "", e.area, e.studyType, e.startDate, e.endDate, e.score, string(c), i,
		); err != nil {
			return fmt.Errorf("seed education: %w", err)
		}
	}

	// ── Projects ────────────────────────────────────────────────────────────────
	projHighlights, _ := json.Marshal([]string{
		"Constructed firmware optimizations to yield higher execution speeds on restricted 8-bit microcontrollers.",
		"Modeled multi-axis linkages using Autodesk systems to print structural joints.",
	})
	projKeywords, _ := json.Marshal([]string{"Flutter", "Embedded Systems", "GRBL", "ESP32", "Edge AI"})
	projExhibits, _ := json.Marshal([]string{"e5a6f2b4-7c9d-4e8f-9a1b-3c5d7e9f1a2b"})
	if _, err := DB.Exec(`INSERT INTO resume_projects (id,user_id,name,description,highlights,keywords,url,exhibits,active,sort_order) VALUES (?,?,?,?,?,?,?,?,?,?)`,
		uuid.New().String(), "shua",
		"Agri3D Platform",
		"Automated horticulture platform incorporating custom embedded motion controls, spatial design, and Edge AI.",
		string(projHighlights), string(projKeywords), "", string(projExhibits), 1, 0,
	); err != nil {
		return fmt.Errorf("seed projects: %w", err)
	}

	// ── Skills ──────────────────────────────────────────────────────────────────
	type skillSeed struct{ name, level string; keywords []string }
	skills := []skillSeed{
		{"Mechatronics & Embedded Systems", "Expert", []string{"ATmega328P", "ESP32", "Arduino", "GRBL", "KiCAD", "PCB Routing", "Autodesk Inventor", "Fusion 360", "Microcontrollers", "Hardware design"}},
		{"Software Development", "Expert", []string{"Flutter", "Dart", "Java", "C++", "C", "Go", "TypeScript", "HTML", "CSS", "Creative Web Design"}},
		{"Data Analysis", "Intermediate", []string{"Data Analytics", "Microsoft Power BI", "Data Wrangling", "Visualization"}},
		{"Quality Assurance", "Intermediate", []string{"Test Cases", "Traceability Matrices", "SDLC Standards", "Defect Isolation"}},
	}
	for i, sk := range skills {
		kw, _ := json.Marshal(sk.keywords)
		if _, err := DB.Exec(`INSERT INTO resume_skills (id,user_id,name,level,keywords,sort_order) VALUES (?,?,?,?,?,?)`,
			uuid.New().String(), "shua", sk.name, sk.level, string(kw), i,
		); err != nil {
			return fmt.Errorf("seed skills: %w", err)
		}
	}

	// ── Certificates ────────────────────────────────────────────────────────────
	type certSeed struct{ id, name, issuer, date string }
	certs := []certSeed{
		{"YJB-04-174-07022-001-java", "Programming (Java) NC III", "TESDA: Technical Education and Skills Development Authority", "2025-02-01"},
		{"YJB-04-174-07022-002-iot", "Internet of Things (TESDA NC)", "TESDA: Technical Education and Skills Development Authority", "2024-02-01"},
		{"YJB-04-174-07022-003-web", "Creative Web Design (TESDA NC)", "TESDA: Technical Education and Skills Development Authority", "2023-10-01"},
		{"YJB-04-174-07022-004-da", "Data Analytics Level III", "TESDA: Technical Education and Skills Development Authority", "2026-04-01"},
	}
	for i, c := range certs {
		if _, err := DB.Exec(`INSERT INTO resume_certificates (id,user_id,name,issuer,date,url,sort_order) VALUES (?,?,?,?,?,?,?)`,
			c.id, "shua", c.name, c.issuer, c.date, "", i,
		); err != nil {
			return fmt.Errorf("seed certificates: %w", err)
		}
	}

	// ── Awards ──────────────────────────────────────────────────────────────────
	type awardSeed struct{ title, date, awarder, summary string }
	awards := []awardSeed{
		{"DOST-SEI Scholar (JLSS-RA 10612)", "2024-10-01", "Department of Science and Technology – Science Education Institute (DOST-SEI)", "Awarded junior level science scholarship for high academic performance in computer engineering."},
		{"Deans Lister Awardee", "2024-05-01", "Cebu Technological University", "Academic honor recipient during Second Year, GWA: 1.40, and served as ICpEP.SE CTU-MC Secretary."},
		{"Academic Excellence - First Year", "2023-05-01", "Cebu Technological University", "GWA - 1.28 (First Semester), GWA - 1.32 (Second Semester), and served as ICpEP.SE CTU-MC Secretary."},
		{"Secondary Education With Honors", "2022-05-01", "Mandaue City Science High School", "Graduated secondary education with honors."},
		{"Elementary Valedictorian", "2016-03-01", "Opao Elementary School", "Graduated primary education as class valedictorian."},
	}
	for i, a := range awards {
		if _, err := DB.Exec(`INSERT INTO resume_awards (id,user_id,title,date,awarder,summary,sort_order) VALUES (?,?,?,?,?,?,?)`,
			uuid.New().String(), "shua", a.title, a.date, a.awarder, a.summary, i,
		); err != nil {
			return fmt.Errorf("seed awards: %w", err)
		}
	}

	logger.Info("database", "Seeded master profile (Joshua B. Ygot) into all resume tables", nil)
	return nil
}
