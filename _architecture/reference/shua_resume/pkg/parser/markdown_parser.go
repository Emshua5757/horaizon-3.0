package parser

import (
	"bufio"
	"regexp"
	"strings"

	"shua_resume/pkg/models"
)

const (
	stateRoot = iota
	stateYAML
	stateWork
	stateProjects
	stateEducation
	stateSkills
	stateCertificates
	stateAwards
)

var (
	dateRegex  = regexp.MustCompile(`\*([^*]+)\*`)
	mediaRegex = regexp.MustCompile(`\[media:\s*([a-fA-F0-9-]{36})\]`)
)

// ParseMarkdown parses a Markdown resume with YAML frontmatter into a ResumeMatrix struct
func ParseMarkdown(mdContent string) (*models.ResumeMatrix, error) {
	matrix := &models.ResumeMatrix{
		Work:         []models.WorkItem{},
		Education:    []models.Education{},
		Projects:     []models.ProjectItem{},
		Skills:       []models.Skill{},
		Certificates: []models.Certificate{},
		Awards:       []models.Award{},
	}

	scanner := bufio.NewScanner(strings.NewReader(mdContent))
	state := stateRoot

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())

		// Handle YAML boundaries
		if line == "---" {
			if state == stateRoot {
				state = stateYAML
				continue
			} else if state == stateYAML {
				state = stateRoot
				continue
			}
		}

		if state == stateYAML {
			parseYAML(line, &matrix.Basics)
			continue
		}

		// Handle Section transitions
		if strings.HasPrefix(line, "## ") {
			title := strings.ToLower(line[3:])
			switch {
			case strings.Contains(title, "work") || strings.Contains(title, "experience"):
				state = stateWork
			case strings.Contains(title, "project"):
				state = stateProjects
			case strings.Contains(title, "education") || strings.Contains(title, "academic"):
				state = stateEducation
			case strings.Contains(title, "skill"):
				state = stateSkills
			case strings.Contains(title, "certif"):
				state = stateCertificates
			case strings.Contains(title, "award"):
				state = stateAwards
			default:
				state = stateRoot
			}
			continue
		}

		// Handle Entity creation
		if strings.HasPrefix(line, "### ") {
			headerContent := strings.TrimSpace(line[4:])
			parts := strings.SplitN(headerContent, "|", 2)
			for i := range parts {
				parts[i] = strings.TrimSpace(parts[i])
			}

			switch state {
			case stateWork:
				pos := ""
				if len(parts) > 1 {
					pos = parts[1]
				}
				matrix.Work = append(matrix.Work, models.WorkItem{
					Name:       parts[0],
					Position:   pos,
					Highlights: []string{},
					Skills:     []string{},
					Active:     true,
				})
			case stateProjects:
				matrix.Projects = append(matrix.Projects, models.ProjectItem{
					Name:       parts[0],
					Highlights: []string{},
					Exhibits:   []string{},
					Active:     true,
				})
			case stateEducation:
				area := ""
				if len(parts) > 1 {
					area = parts[1]
				}
				matrix.Education = append(matrix.Education, models.Education{
					Institution: parts[0],
					Area:        area,
					Courses:     []string{},
				})
			case stateSkills:
				level := ""
				if len(parts) > 1 {
					level = parts[1]
				}
				matrix.Skills = append(matrix.Skills, models.Skill{
					Name:     parts[0],
					Level:    level,
					Keywords: []string{},
				})
			case stateCertificates:
				issuer := ""
				if len(parts) > 1 {
					issuer = parts[1]
				}
				matrix.Certificates = append(matrix.Certificates, models.Certificate{
					Name:   parts[0],
					Issuer: issuer,
				})
			case stateAwards:
				sender := ""
				if len(parts) > 1 {
					sender = parts[1]
				}
				matrix.Awards = append(matrix.Awards, models.Award{
					Title:  parts[0],
					Sender: sender,
				})
			}
			continue
		}

		// Parse dates from italicized pattern *2024-01-01* to *Present*
		if (state == stateWork || state == stateEducation || state == stateCertificates || state == stateAwards) && dateRegex.MatchString(line) {
			matches := dateRegex.FindAllStringSubmatch(line, -1)
			if len(matches) > 0 {
				start := matches[0][1]
				end := ""
				if len(matches) > 1 {
					end = matches[1][1]
				}

				switch state {
				case stateWork:
					if len(matrix.Work) > 0 {
						idx := len(matrix.Work) - 1
						matrix.Work[idx].StartDate = start
						matrix.Work[idx].EndDate = end
					}
				case stateEducation:
					if len(matrix.Education) > 0 {
						idx := len(matrix.Education) - 1
						matrix.Education[idx].StartDate = start
						matrix.Education[idx].EndDate = end
					}
				case stateCertificates:
					if len(matrix.Certificates) > 0 {
						idx := len(matrix.Certificates) - 1
						matrix.Certificates[idx].Date = start
					}
				case stateAwards:
					if len(matrix.Awards) > 0 {
						idx := len(matrix.Awards) - 1
						matrix.Awards[idx].Date = start
					}
				}
				continue
			}
		}

		// Handle list items / bullet points
		if strings.HasPrefix(line, "* ") || strings.HasPrefix(line, "- ") {
			bulletText := strings.TrimSpace(line[2:])

			switch state {
			case stateWork:
				if len(matrix.Work) > 0 {
					idx := len(matrix.Work) - 1
					// Extract parsed skills if highlighted as: "Skills: Go, Rust"
					if strings.HasPrefix(strings.ToLower(bulletText), "skills:") {
						skillList := strings.TrimSpace(bulletText[7:])
						for _, sk := range strings.Split(skillList, ",") {
							matrix.Work[idx].Skills = append(matrix.Work[idx].Skills, strings.TrimSpace(sk))
						}
					} else {
						matrix.Work[idx].Highlights = append(matrix.Work[idx].Highlights, bulletText)
					}
				}
			case stateProjects:
				if len(matrix.Projects) > 0 {
					idx := len(matrix.Projects) - 1
					// Check for media tag
					if mediaRegex.MatchString(bulletText) {
						mediaMatches := mediaRegex.FindStringSubmatch(bulletText)
						if len(mediaMatches) > 1 {
							matrix.Projects[idx].Exhibits = append(matrix.Projects[idx].Exhibits, mediaMatches[1])
						}
					} else {
						matrix.Projects[idx].Highlights = append(matrix.Projects[idx].Highlights, bulletText)
						if matrix.Projects[idx].Description == "" {
							matrix.Projects[idx].Description = bulletText
						}
					}
				}
			case stateEducation:
				if len(matrix.Education) > 0 {
					idx := len(matrix.Education) - 1
					if strings.HasPrefix(strings.ToLower(bulletText), "degree:") || strings.HasPrefix(strings.ToLower(bulletText), "studytype:") {
						parts := strings.SplitN(bulletText, ":", 2)
						if len(parts) > 1 {
							matrix.Education[idx].StudyType = strings.TrimSpace(parts[1])
						}
					} else if strings.HasPrefix(strings.ToLower(bulletText), "score:") || strings.HasPrefix(strings.ToLower(bulletText), "gpa:") {
						parts := strings.SplitN(bulletText, ":", 2)
						if len(parts) > 1 {
							matrix.Education[idx].Score = strings.TrimSpace(parts[1])
						}
					} else {
						matrix.Education[idx].Courses = append(matrix.Education[idx].Courses, bulletText)
					}
				}
			case stateSkills:
				if len(matrix.Skills) > 0 {
					idx := len(matrix.Skills) - 1
					keywords := strings.Split(bulletText, ",")
					for _, k := range keywords {
						trimmed := strings.TrimSpace(k)
						if trimmed != "" {
							matrix.Skills[idx].Keywords = append(matrix.Skills[idx].Keywords, trimmed)
						}
					}
				}
			case stateCertificates:
				if len(matrix.Certificates) > 0 {
					idx := len(matrix.Certificates) - 1
					if strings.HasPrefix(strings.ToLower(bulletText), "url:") {
						matrix.Certificates[idx].Url = strings.TrimSpace(bulletText[4:])
					} else if strings.HasPrefix(strings.ToLower(bulletText), "id:") {
						matrix.Certificates[idx].Id = strings.TrimSpace(bulletText[3:])
					}
				}
			case stateAwards:
				if len(matrix.Awards) > 0 {
					idx := len(matrix.Awards) - 1
					matrix.Awards[idx].Summary = bulletText
				}
			}
		}
	}

	return matrix, nil
}

func parseYAML(line string, basics *models.Basics) {
	parts := strings.SplitN(line, ":", 2)
	if len(parts) < 2 {
		return
	}
	key := strings.ToLower(strings.TrimSpace(parts[0]))
	val := strings.TrimSpace(parts[1])

	switch key {
	case "name":
		basics.Name = val
	case "label":
		basics.Label = val
	case "email":
		basics.Email = val
	case "phone":
		basics.Phone = val
	case "url":
		basics.Url = val
	case "summary":
		basics.Summary = val
	case "location":
		locParts := strings.SplitN(val, ",", 2)
		if len(locParts) > 0 {
			basics.Location.City = strings.TrimSpace(locParts[0])
		}
		if len(locParts) > 1 {
			basics.Location.CountryCode = strings.TrimSpace(locParts[1])
		}
	}
}
