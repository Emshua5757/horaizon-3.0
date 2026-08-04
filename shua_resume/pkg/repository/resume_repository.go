// Package repository provides CRUD operations against the SQLite resume tables.
// All functions use the shared db.DB connection (WAL mode, single open connection).
//
// Time Complexity: O(n) on row count per table, n <= 100 rows total.
// Space Complexity: O(n) for returned slices; O(1) per scalar operation.
package repository

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"

	"shua_resume/pkg/db"
	"shua_resume/pkg/models"
)

// GetMatrix loads the full ResumeMatrix for the given userId from all tables.
func GetMatrix(userID string) (*models.ResumeMatrix, error) {
	matrix := &models.ResumeMatrix{}
	var err error

	// Basics
	matrix.Basics, err = getBasics(userID)
	if err != nil {
		return nil, fmt.Errorf("get basics: %w", err)
	}

	// Work
	matrix.Work, err = getWork(userID)
	if err != nil {
		return nil, fmt.Errorf("get work: %w", err)
	}

	// Education
	matrix.Education, err = getEducation(userID)
	if err != nil {
		return nil, fmt.Errorf("get education: %w", err)
	}

	// Projects
	matrix.Projects, err = getProjects(userID)
	if err != nil {
		return nil, fmt.Errorf("get projects: %w", err)
	}

	// Skills
	matrix.Skills, err = getSkills(userID)
	if err != nil {
		return nil, fmt.Errorf("get skills: %w", err)
	}

	// Certificates
	matrix.Certificates, err = getCertificates(userID)
	if err != nil {
		return nil, fmt.Errorf("get certificates: %w", err)
	}

	// Awards
	matrix.Awards, err = getAwards(userID)
	if err != nil {
		return nil, fmt.Errorf("get awards: %w", err)
	}

	// Organizations
	matrix.Organizations, err = getOrganizations(userID)
	if err != nil {
		return nil, fmt.Errorf("get organizations: %w", err)
	}

	return matrix, nil
}

func getBasics(userID string) (models.Basics, error) {
	var b models.Basics
	var profilesJSON string
	err := db.DB.QueryRow(`SELECT name,label,email,phone,url,summary,city,region,country_code,profiles_json FROM resume_basics WHERE user_id=?`, userID).
		Scan(&b.Name, &b.Label, &b.Email, &b.Phone, &b.Url, &b.Summary,
			&b.Location.City, &b.Location.Region, &b.Location.CountryCode, &profilesJSON)
	if err == sql.ErrNoRows {
		return b, nil
	}
	if err != nil {
		return b, err
	}
	_ = json.Unmarshal([]byte(profilesJSON), &b.Profiles)
	return b, nil
}

func getWork(userID string) ([]models.WorkItem, error) {
	rows, err := db.DB.Query(`SELECT id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active FROM resume_work WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.WorkItem
	for rows.Next() {
		var item models.WorkItem
		var highlightsJSON, keywordsJSON, skillsJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Name, &item.Position, &item.Url, &item.StartDate, &item.EndDate, &item.Summary, &highlightsJSON, &keywordsJSON, &skillsJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highlightsJSON), &item.Highlights)
		_ = json.Unmarshal([]byte(keywordsJSON), &item.Keywords)
		_ = json.Unmarshal([]byte(skillsJSON), &item.Skills)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		if item.Skills == nil {
			item.Skills = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.WorkItem{}
	}
	return items, rows.Err()
}

func getEducation(userID string) ([]models.Education, error) {
	rows, err := db.DB.Query(`SELECT id,institution,url,area,study_type,start_date,end_date,score,courses FROM resume_education WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Education
	for rows.Next() {
		var item models.Education
		var coursesJSON string
		if err := rows.Scan(&item.Id, &item.Institution, &item.Url, &item.Area, &item.StudyType, &item.StartDate, &item.EndDate, &item.Score, &coursesJSON); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(coursesJSON), &item.Courses)
		if item.Courses == nil {
			item.Courses = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Education{}
	}
	return items, rows.Err()
}

func getProjects(userID string) ([]models.ProjectItem, error) {
	rows, err := db.DB.Query(`SELECT id,name,description,highlights,keywords,url,exhibits,active FROM resume_projects WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.ProjectItem
	for rows.Next() {
		var item models.ProjectItem
		var highJSON, kwJSON, exhibJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Name, &item.Description, &highJSON, &kwJSON, &item.Url, &exhibJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highJSON), &item.Highlights)
		_ = json.Unmarshal([]byte(kwJSON), &item.Keywords)
		_ = json.Unmarshal([]byte(exhibJSON), &item.Exhibits)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		if item.Exhibits == nil {
			item.Exhibits = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.ProjectItem{}
	}
	return items, rows.Err()
}

func getSkills(userID string) ([]models.Skill, error) {
	rows, err := db.DB.Query(`SELECT id,name,level,keywords FROM resume_skills WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Skill
	for rows.Next() {
		var item models.Skill
		var kwJSON string
		if err := rows.Scan(&item.Id, &item.Name, &item.Level, &kwJSON); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(kwJSON), &item.Keywords)
		if item.Keywords == nil {
			item.Keywords = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Skill{}
	}
	return items, rows.Err()
}

func getCertificates(userID string) ([]models.Certificate, error) {
	rows, err := db.DB.Query(`SELECT id,name,issuer,date,url FROM resume_certificates WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Certificate
	for rows.Next() {
		var item models.Certificate
		if err := rows.Scan(&item.Id, &item.Name, &item.Issuer, &item.Date, &item.Url); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Certificate{}
	}
	return items, rows.Err()
}

func getAwards(userID string) ([]models.Award, error) {
	rows, err := db.DB.Query(`SELECT id,title,date,awarder,summary FROM resume_awards WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.Award
	for rows.Next() {
		var item models.Award
		if err := rows.Scan(&item.Id, &item.Title, &item.Date, &item.Sender, &item.Summary); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.Award{}
	}
	return items, rows.Err()
}

func getOrganizations(userID string) ([]models.OrgItem, error) {
	rows, err := db.DB.Query(`SELECT id,organization,role,start_date,end_date,summary,highlights,active FROM resume_organizations WHERE user_id=? ORDER BY sort_order ASC`, userID)
	if err != nil {
		// Table may not exist on older deployments — return empty gracefully.
		return []models.OrgItem{}, nil
	}
	defer rows.Close()

	var items []models.OrgItem
	for rows.Next() {
		var item models.OrgItem
		var highJSON string
		var active int
		if err := rows.Scan(&item.Id, &item.Organization, &item.Role, &item.StartDate, &item.EndDate, &item.Summary, &highJSON, &active); err != nil {
			return nil, err
		}
		item.Active = active != 0
		_ = json.Unmarshal([]byte(highJSON), &item.Highlights)
		if item.Highlights == nil {
			item.Highlights = []string{}
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.OrgItem{}
	}
	return items, rows.Err()
}

// UpdateSection handles upsert, delete, and reorder actions for a named section.
func UpdateSection(userID, section, action string, item map[string]interface{}, id string) (string, error) {
	switch section {
	case "basics":
		return upsertBasics(userID, item)
	case "work":
		return upsertWork(userID, action, item, id)
	case "education":
		return upsertEducation(userID, action, item, id)
	case "projects":
		return upsertProject(userID, action, item, id)
	case "skills":
		return upsertSkill(userID, action, item, id)
	case "certificates":
		return upsertCertificate(userID, action, item, id)
	case "awards":
		return upsertAward(userID, action, item, id)
	case "organizations":
		return upsertOrganization(userID, action, item, id)
	default:
		return "", fmt.Errorf("unknown section: %s", section)
	}
}

func upsertBasics(userID string, item map[string]interface{}) (string, error) {
	now := time.Now().UTC().Format(time.RFC3339)

	// Unmarshal location and profiles from nested fields
	locMap, _ := item["location"].(map[string]interface{})
	city, _ := locMap["city"].(string)
	region, _ := locMap["region"].(string)
	countryCode, _ := locMap["country_code"].(string)

	profilesJSON := "[]"
	if p, ok := item["profiles"]; ok {
		b, _ := json.Marshal(p)
		profilesJSON = string(b)
	}

	_, err := db.DB.Exec(`INSERT INTO resume_basics
		(user_id,name,label,email,phone,url,summary,city,region,country_code,profiles_json,updated_at)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(user_id) DO UPDATE SET
			name=excluded.name, label=excluded.label, email=excluded.email,
			phone=excluded.phone, url=excluded.url, summary=excluded.summary,
			city=excluded.city, region=excluded.region, country_code=excluded.country_code,
			profiles_json=excluded.profiles_json, updated_at=excluded.updated_at`,
		userID,
		strField(item, "name"), strField(item, "label"),
		strField(item, "email"), strField(item, "phone"),
		strField(item, "url"), strField(item, "summary"),
		city, region, countryCode, profilesJSON, now,
	)
	return userID, err
}

func upsertWork(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_work WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	k, _ := json.Marshal(jsonArray(item, "keywords"))
	s, _ := json.Marshal(jsonArray(item, "skills"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_work
		(id,user_id,name,position,url,start_date,end_date,summary,highlights,keywords,skills,active)
		VALUES (?,?,?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name, position=excluded.position, url=excluded.url,
			start_date=excluded.start_date, end_date=excluded.end_date, summary=excluded.summary,
			highlights=excluded.highlights, keywords=excluded.keywords, skills=excluded.skills, active=excluded.active`,
		itemID, userID,
		strField(item, "name"), strField(item, "position"), strField(item, "url"),
		strField(item, "start_date"), strField(item, "end_date"), strField(item, "summary"),
		string(h), string(k), string(s), active,
	)
	return itemID, err
}

func upsertEducation(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_education WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	c, _ := json.Marshal(jsonArray(item, "courses"))
	_, err := db.DB.Exec(`INSERT INTO resume_education
		(id,user_id,institution,url,area,study_type,start_date,end_date,score,courses)
		VALUES (?,?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			institution=excluded.institution, url=excluded.url, area=excluded.area,
			study_type=excluded.study_type, start_date=excluded.start_date,
			end_date=excluded.end_date, score=excluded.score, courses=excluded.courses`,
		itemID, userID,
		strField(item, "institution"), strField(item, "url"), strField(item, "area"),
		strField(item, "study_type"), strField(item, "start_date"), strField(item, "end_date"),
		strField(item, "score"), string(c),
	)
	return itemID, err
}

func upsertProject(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_projects WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	k, _ := json.Marshal(jsonArray(item, "keywords"))
	e, _ := json.Marshal(jsonArray(item, "exhibits"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_projects
		(id,user_id,name,description,highlights,keywords,url,exhibits,active)
		VALUES (?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			name=excluded.name, description=excluded.description,
			highlights=excluded.highlights, keywords=excluded.keywords, url=excluded.url,
			exhibits=excluded.exhibits, active=excluded.active`,
		itemID, userID,
		strField(item, "name"), strField(item, "description"), string(h),
		string(k), strField(item, "url"), string(e), active,
	)
	return itemID, err
}

func upsertSkill(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_skills WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	kw, _ := json.Marshal(jsonArray(item, "keywords"))
	_, err := db.DB.Exec(`INSERT INTO resume_skills (id,user_id,name,level,keywords) VALUES (?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET name=excluded.name, level=excluded.level, keywords=excluded.keywords`,
		itemID, userID, strField(item, "name"), strField(item, "level"), string(kw),
	)
	return itemID, err
}

func upsertCertificate(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_certificates WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	_, err := db.DB.Exec(`INSERT INTO resume_certificates (id,user_id,name,issuer,date,url) VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET name=excluded.name, issuer=excluded.issuer, date=excluded.date, url=excluded.url`,
		itemID, userID,
		strField(item, "name"), strField(item, "issuer"), strField(item, "date"), strField(item, "url"),
	)
	return itemID, err
}

func upsertAward(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_awards WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	_, err := db.DB.Exec(`INSERT INTO resume_awards (id,user_id,title,date,awarder,summary) VALUES (?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET title=excluded.title, date=excluded.date, awarder=excluded.awarder, summary=excluded.summary`,
		itemID, userID,
		strField(item, "title"), strField(item, "date"), strField(item, "awarder"), strField(item, "summary"),
	)
	return itemID, err
}

func upsertOrganization(userID, action string, item map[string]interface{}, id string) (string, error) {
	if action == "delete" {
		_, err := db.DB.Exec("DELETE FROM resume_organizations WHERE id=? AND user_id=?", id, userID)
		return id, err
	}
	itemID := strField(item, "id")
	if itemID == "" {
		itemID = uuid.New().String()
	}
	h, _ := json.Marshal(jsonArray(item, "highlights"))
	active := 1
	if v, ok := item["active"].(bool); ok && !v {
		active = 0
	}
	_, err := db.DB.Exec(`INSERT INTO resume_organizations
		(id,user_id,organization,role,start_date,end_date,summary,highlights,active)
		VALUES (?,?,?,?,?,?,?,?,?)
		ON CONFLICT(id) DO UPDATE SET
			organization=excluded.organization, role=excluded.role,
			start_date=excluded.start_date, end_date=excluded.end_date,
			summary=excluded.summary, highlights=excluded.highlights, active=excluded.active`,
		itemID, userID,
		strField(item, "organization"), strField(item, "role"),
		strField(item, "start_date"), strField(item, "end_date"),
		strField(item, "summary"), string(h), active,
	)
	return itemID, err
}

// ListHistory returns all PDF compilation history rows, newest first.
func ListHistory() ([]models.HistoryItem, error) {
	rows, err := db.DB.Query(`SELECT exhibit_id,vault_url,template_id,job_desc,tailor_score,ai_enhanced,duration_ms,compiled_at FROM resume_history ORDER BY compiled_at DESC LIMIT 50`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []models.HistoryItem
	for rows.Next() {
		var item models.HistoryItem
		var aiEnhanced int
		var tailorScore sql.NullFloat64
		if err := rows.Scan(&item.ExhibitId, &item.VaultUrl, &item.TemplateId, &item.JobDesc, &tailorScore, &aiEnhanced, &item.DurationMs, &item.CompiledAt); err != nil {
			return nil, err
		}
		item.AiEnhanced = aiEnhanced != 0
		if tailorScore.Valid {
			v := float32(tailorScore.Float64)
			item.TailorScore = &v
		}
		items = append(items, item)
	}
	if items == nil {
		items = []models.HistoryItem{}
	}
	return items, rows.Err()
}

// SaveHistory inserts a PDF compilation record into resume_history.
func SaveHistory(h models.HistoryItem) error {
	aiInt := 0
	if h.AiEnhanced {
		aiInt = 1
	}
	var tailorScore interface{}
	if h.TailorScore != nil {
		tailorScore = *h.TailorScore
	}
	_, err := db.DB.Exec(`INSERT INTO resume_history
		(exhibit_id,vault_url,template_id,job_desc,tailor_score,ai_enhanced,duration_ms,compiled_at) VALUES (?,?,?,?,?,?,?,?)
		ON CONFLICT(exhibit_id) DO UPDATE SET
			vault_url=excluded.vault_url, template_id=excluded.template_id, compiled_at=excluded.compiled_at`,
		h.ExhibitId, h.VaultUrl, h.TemplateId, h.JobDesc, tailorScore, aiInt, h.DurationMs, h.CompiledAt,
	)
	return err
}

// ── helpers ──────────────────────────────────────────────────────────────────

func strField(m map[string]interface{}, key string) string {
	if v, ok := m[key]; ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return ""
}

func jsonArray(m map[string]interface{}, key string) []string {
	v, ok := m[key]
	if !ok {
		return []string{}
	}
	switch t := v.(type) {
	case []interface{}:
		out := make([]string, 0, len(t))
		for _, el := range t {
			if s, ok := el.(string); ok {
				out = append(out, s)
			}
		}
		return out
	case []string:
		return t
	}
	return []string{}
}
