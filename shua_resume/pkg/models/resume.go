package models

// ResumeMatrix is the canonical resume data model for horAIzon 3.0.
type ResumeMatrix struct {
	Basics       Basics        `json:"basics" msgpack:"basics"`
	Work         []WorkItem    `json:"work" msgpack:"work"`
	Education    []Education   `json:"education" msgpack:"education"`
	Projects     []ProjectItem `json:"projects" msgpack:"projects"`
	Skills       []Skill       `json:"skills" msgpack:"skills"`
	Certificates []Certificate `json:"certificates" msgpack:"certificates"`
	Awards       []Award       `json:"awards" msgpack:"awards"`
}

// Basics holds primary contact and identity information.
type Basics struct {
	Name     string    `json:"name" msgpack:"name"`
	Label    string    `json:"label" msgpack:"label"`
	Email    string    `json:"email" msgpack:"email"`
	Phone    string    `json:"phone" msgpack:"phone"`
	Url      string    `json:"url" msgpack:"url"`
	Summary  string    `json:"summary" msgpack:"summary"`
	Location Location  `json:"location" msgpack:"location"`
	Profiles []Profile `json:"profiles" msgpack:"profiles"`
}

// Location holds city, region, and country code.
type Location struct {
	Address     string `json:"address,omitempty" msgpack:"address,omitempty"`
	City        string `json:"city" msgpack:"city"`
	Region      string `json:"region" msgpack:"region"`
	CountryCode string `json:"countryCode" msgpack:"country_code"`
}

// Profile holds a social/professional profile link.
type Profile struct {
	Network  string `json:"network" msgpack:"network"`
	Username string `json:"username" msgpack:"username"`
	Url      string `json:"url" msgpack:"url"`
}

// WorkItem holds a single work experience entry.
type WorkItem struct {
	Id         string   `json:"id" msgpack:"id"`
	Name       string   `json:"name" msgpack:"name"`
	Position   string   `json:"position" msgpack:"position"`
	Url        string   `json:"url" msgpack:"url"`
	StartDate  string   `json:"startDate" msgpack:"start_date"`
	EndDate    string   `json:"endDate" msgpack:"end_date"`
	Summary    string   `json:"summary" msgpack:"summary"`
	Highlights []string `json:"highlights" msgpack:"highlights"`
	Skills     []string `json:"skills" msgpack:"skills"`
	Active     bool     `json:"active" msgpack:"active"`
}

// Education holds a single education entry.
type Education struct {
	Id          string   `json:"id" msgpack:"id"`
	Institution string   `json:"institution" msgpack:"institution"`
	Url         string   `json:"url" msgpack:"url"`
	Area        string   `json:"area" msgpack:"area"`
	StudyType   string   `json:"studyType" msgpack:"study_type"`
	StartDate   string   `json:"startDate" msgpack:"start_date"`
	EndDate     string   `json:"endDate" msgpack:"end_date"`
	Score       string   `json:"score" msgpack:"score"`
	Courses     []string `json:"courses" msgpack:"courses"`
}

// ProjectItem holds a single project entry.
type ProjectItem struct {
	Id          string   `json:"id" msgpack:"id"`
	Name        string   `json:"name" msgpack:"name"`
	Description string   `json:"description" msgpack:"description"`
	Highlights  []string `json:"highlights" msgpack:"highlights"`
	Url         string   `json:"url" msgpack:"url"`
	Exhibits    []string `json:"exhibits" msgpack:"exhibits"`
	Active      bool     `json:"active" msgpack:"active"`
}

// Skill holds a skill group with keywords.
type Skill struct {
	Id       string   `json:"id" msgpack:"id"`
	Name     string   `json:"name" msgpack:"name"`
	Level    string   `json:"level" msgpack:"level"`
	Keywords []string `json:"keywords" msgpack:"keywords"`
}

// Certificate holds a professional certificate.
type Certificate struct {
	Id     string `json:"id" msgpack:"id"`
	Name   string `json:"name" msgpack:"name"`
	Issuer string `json:"issuer" msgpack:"issuer"`
	Date   string `json:"date" msgpack:"date"`
	Url    string `json:"url" msgpack:"url"`
}

// Award holds an award or recognition.
type Award struct {
	Id      string `json:"id" msgpack:"id"`
	Title   string `json:"title" msgpack:"title"`
	Date    string `json:"date" msgpack:"date"`
	Sender  string `json:"awarder" msgpack:"awarder"`
	Summary string `json:"summary" msgpack:"summary"`
}

// HistoryItem is a single PDF compilation record stored in resume_history.
type HistoryItem struct {
	ExhibitId  string   `json:"exhibit_id" msgpack:"exhibit_id"`
	VaultUrl   string   `json:"vault_url" msgpack:"vault_url"`
	TemplateId string   `json:"template_id" msgpack:"template_id"`
	JobDesc    string   `json:"job_desc" msgpack:"job_desc"`
	TailorScore *float32 `json:"tailor_score,omitempty" msgpack:"tailor_score"`
	AiEnhanced bool     `json:"ai_enhanced" msgpack:"ai_enhanced"`
	DurationMs uint32   `json:"duration_ms" msgpack:"duration_ms"`
	CompiledAt string   `json:"compiled_at" msgpack:"compiled_at"`
}
