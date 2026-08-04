// Modern two-column Typst resume template.
// Sidebar (30%): dark navy background, white text — contact, skills, certs.
// Main (70%): white background — name, experience, projects, education, awards.
// Font: Inter.
#let resume_template(data) = {
  set document(title: data.basics.name + " — Resume")
  set page(margin: 0pt)
  set text(font: "Inter", size: 9.5pt, lang: "en")

  let navy = rgb("#1a1a2e")
  let white = rgb("#ffffff")
  let light_gray = rgb("#f4f4f8")

  // ── Sidebar ────────────────────────────────────────────────────────────────
  let sidebar = {
    set text(fill: white)
    v(24pt)
    h(16pt)
    rect(fill: none, width: 100%, height: 0pt)

    // Photo placeholder box
    align(center)[
      #rect(width: 64pt, height: 64pt, fill: rgb("#2a2a4e"), radius: 32pt)
    ]
    v(8pt)

    // Contact
    align(center)[
      #text(size: 10pt, weight: "bold")[#data.basics.name]
      #v(-2pt)
      #text(size: 8.5pt, fill: rgb("#aaaacc"))[#data.basics.label]
    ]
    v(12pt)
    pad(left: 14pt, right: 8pt)[
      #text(size: 8pt, weight: "bold", fill: rgb("#aaaacc"))[CONTACT]
      #v(4pt)
      #text(size: 8pt)[#sym.envelope #h(4pt) #data.basics.email \ ]
      #text(size: 8pt)[#sym.phone #h(4pt) #data.basics.phone \ ]
      #if data.basics.profiles.len() > 0 [
        #text(size: 8pt)[#sym.link #h(4pt) #data.basics.profiles.first().url \ ]
      ]
      #text(size: 8pt)[
        #data.basics.location.city, #data.basics.location.region
      ]
    ]

    v(12pt)
    // Skills
    if data.skills.len() > 0 {
      pad(left: 14pt, right: 8pt)[
        #text(size: 8pt, weight: "bold", fill: rgb("#aaaacc"))[SKILLS]
        #v(4pt)
        #for s in data.skills {
          text(size: 8pt, weight: "semibold")[#s.name] + linebreak()
          text(size: 7.5pt, fill: rgb("#ccccee"))[#s.keywords.join(", ")] + v(4pt)
        }
      ]
    }

    v(12pt)
    // Certificates
    if data.certificates.len() > 0 {
      pad(left: 14pt, right: 8pt)[
        #text(size: 8pt, weight: "bold", fill: rgb("#aaaacc"))[CERTIFICATIONS]
        #v(4pt)
        #for c in data.certificates {
          text(size: 7.5pt)[#c.name \ ]
          text(size: 7pt, fill: rgb("#aaaacc"))[#c.issuer \ ]
          v(2pt)
        }
      ]
    }
  }

  // ── Main Content ───────────────────────────────────────────────────────────
  let main_content = {
    set text(fill: rgb("#1a1a1a"))
    pad(left: 20pt, right: 20pt, top: 24pt)[

      // Header
      text(size: 24pt, weight: "bold")[#data.basics.name]
      v(-4pt)
      text(size: 11pt, fill: navy)[#data.basics.label]
      v(8pt)

      // Summary
      if data.basics.summary != "" {
        text(size: 9pt)[#data.basics.summary]
        v(10pt)
      }

      // Experience
      let active_work = data.work.filter(w => w.active)
      if active_work.len() > 0 {
        text(size: 10pt, weight: "bold", fill: navy)[EXPERIENCE]
        line(length: 100%, stroke: 0.5pt + navy)
        v(4pt)
        for w in active_work {
          grid(
            columns: (1fr, auto),
            text(weight: "bold", size: 9.5pt)[#w.name],
            text(size: 8.5pt, fill: rgb("#888888"))[#w.start_date – #w.end_date]
          )
          text(size: 9pt, style: "italic")[#w.position]
          v(2pt)
          for h in w.highlights {
            text(size: 8.5pt)[• #h \ ]
          }
          v(6pt)
        }
      }

      // Projects
      let active_projects = data.projects.filter(p => p.active)
      if active_projects.len() > 0 {
        text(size: 10pt, weight: "bold", fill: navy)[PROJECTS]
        line(length: 100%, stroke: 0.5pt + navy)
        v(4pt)
        for p in active_projects {
          text(weight: "bold", size: 9.5pt)[#p.name]
          v(1pt)
          text(size: 8.5pt)[#p.description]
          v(2pt)
          for h in p.highlights {
            text(size: 8.5pt)[• #h \ ]
          }
          v(6pt)
        }
      }

      // Education
      if data.education.len() > 0 {
        text(size: 10pt, weight: "bold", fill: navy)[EDUCATION]
        line(length: 100%, stroke: 0.5pt + navy)
        v(4pt)
        for e in data.education {
          grid(
            columns: (1fr, auto),
            text(weight: "bold", size: 9.5pt)[#e.institution],
            text(size: 8.5pt, fill: rgb("#888888"))[#e.start_date – #e.end_date]
          )
          text(size: 8.5pt)[#e.study_type, #e.area #if e.score != "" [ | #e.score]]
          v(5pt)
        }
      }

      // Awards
      if data.awards.len() > 0 {
        text(size: 10pt, weight: "bold", fill: navy)[AWARDS]
        line(length: 100%, stroke: 0.5pt + navy)
        v(4pt)
        for a in data.awards {
          text(weight: "bold", size: 9pt)[#a.title] + text(size: 8.5pt)[ — #a.awarder (#a.date) \ ]
        }
      }
    ]
  }

  // ── Two-Column Layout ──────────────────────────────────────────────────────
  grid(
    columns: (30%, 70%),
    rect(fill: navy, width: 100%, height: 100%)[#sidebar],
    rect(fill: white, width: 100%, height: 100%)[#main_content]
  )
}
