package models

type ResumeMatrix struct {
	Basics       Basics        `json:"basics"`
	Work         []WorkItem    `json:"work"`
	Education    []Education   `json:"education"`
	Projects     []ProjectItem `json:"projects"`
	Skills       []Skill       `json:"skills"`
	Certificates []Certificate `json:"certificates"`
	Awards       []Award       `json:"awards"`
}

type Basics struct {
	Name     string    `json:"name"`
	Label    string    `json:"label"`
	Email    string    `json:"email"`
	Phone    string    `json:"phone"`
	Url      string    `json:"url"`
	Summary  string    `json:"summary"`
	Location Location  `json:"location"`
	Profiles []Profile `json:"profiles"`
}

type Location struct {
	City        string `json:"city"`
	Region      string `json:"region"`
	CountryCode string `json:"countryCode"`
}

type Profile struct {
	Network  string `json:"network"`
	Username string `json:"username"`
	Url      string `json:"url"`
}

type WorkItem struct {
	Id         string   `json:"id"`
	Name       string   `json:"name"`
	Position   string   `json:"position"`
	Url        string   `json:"url"`
	StartDate  string   `json:"startDate"`
	EndDate    string   `json:"endDate"`
	Summary    string   `json:"summary"`
	Highlights []string `json:"highlights"`
	Skills     []string `json:"skills"`
	Active     bool     `json:"active"`
}

type Education struct {
	Id          string   `json:"id"`
	Institution string   `json:"institution"`
	Url         string   `json:"url"`
	Area        string   `json:"area"`
	StudyType   string   `json:"studyType"`
	StartDate   string   `json:"startDate"`
	EndDate     string   `json:"endDate"`
	Score       string   `json:"score"`
	Courses     []string `json:"courses"`
}

type ProjectItem struct {
	Id          string   `json:"id"`
	Name        string   `json:"name"`
	Description string   `json:"description"`
	Highlights  []string `json:"highlights"`
	Url         string   `json:"url"`
	Exhibits    []string `json:"exhibits"`
	Active      bool     `json:"active"`
}

type Skill struct {
	Id       string   `json:"id"`
	Name     string   `json:"name"`
	Level    string   `json:"level"`
	Keywords []string `json:"keywords"`
}

type Certificate struct {
	Name   string `json:"name"`
	Issuer string `json:"issuer"`
	Date   string `json:"date"`
	Url    string `json:"url"`
	Id     string `json:"id"`
}

type Award struct {
	Id      string `json:"id"`
	Title   string `json:"title"`
	Date    string `json:"date"`
	Sender  string `json:"awarder"`
	Summary string `json:"summary"`
}
