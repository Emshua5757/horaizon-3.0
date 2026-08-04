// Default ATS-friendly single-column Typst resume template.
// Font: IBM Plex Sans — good ATS scanner compatibility.
// Margin: 1.5cm. Line-height: 1.2. Accent: #1a1a2e (dark navy).
#let resume_template(data) = {
  set document(title: data.basics.name + " — Resume")
  set page(margin: 1.5cm)
  set text(font: "IBM Plex Sans", size: 10pt, lang: "en")
  set par(leading: 0.55em)
  show heading: it => {
    set text(size: 10pt, weight: "bold", fill: rgb("#1a1a2e"))
    upper(it.body)
    v(-3pt)
    line(length: 100%, stroke: 0.5pt + rgb("#1a1a2e"))
    v(3pt)
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  align(center)[
    #text(size: 22pt, weight: "bold")[#data.basics.name]
    #v(-4pt)
    #text(size: 11pt, fill: rgb("#444444"))[#data.basics.label]
    #v(-2pt)
    #text(size: 9pt)[
      #data.basics.email
      #h(6pt) | #h(6pt)
      #data.basics.phone
      #if data.basics.profiles.len() > 0 [
        #h(6pt) | #h(6pt)
        #data.basics.profiles.map(p => p.network + ": " + p.url).join("  |  ")
      ]
    ]
  ]

  v(6pt)

  // ── Summary ────────────────────────────────────────────────────────────────
  if data.basics.summary != "" {
    heading(level: 2)[Summary]
    text(size: 9.5pt)[#data.basics.summary]
    v(4pt)
  }

  // ── Experience ─────────────────────────────────────────────────────────────
  let active_work = data.work.filter(w => w.active)
  if active_work.len() > 0 {
    heading(level: 2)[Experience]
    for w in active_work {
      grid(
        columns: (1fr, auto),
        text(weight: "bold")[#w.name],
        text(size: 9pt, fill: rgb("#666666"))[#w.start_date – #w.end_date]
      )
      text(size: 9.5pt, style: "italic")[#w.position]
      v(2pt)
      if w.summary != "" {
        text(size: 9pt)[#w.summary]
        v(2pt)
      }
      for h in w.highlights {
        [• #h \ ]
      }
      if w.keywords.len() > 0 {
        v(1pt)
        text(size: 8pt, fill: rgb("#888888"), style: "italic")[Keywords: #w.keywords.join(", ")]
      }
      v(4pt)
    }
  }

  // ── Organizational Experience ───────────────────────────────────────────────
  let active_orgs = data.organizations.filter(o => o.active)
  if active_orgs.len() > 0 {
    heading(level: 2)[Organizational Experience]
    for o in active_orgs {
      grid(
        columns: (1fr, auto),
        text(weight: "bold")[#o.organization],
        text(size: 9pt, fill: rgb("#666666"))[#o.start_date – #o.end_date]
      )
      text(size: 9.5pt, style: "italic")[#o.role]
      v(2pt)
      if o.summary != "" {
        text(size: 9pt)[#o.summary]
        v(2pt)
      }
      for h in o.highlights {
        [• #h \ ]
      }
      v(4pt)
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  let active_projects = data.projects.filter(p => p.active)
  if active_projects.len() > 0 {
    heading(level: 2)[Projects]
    for p in active_projects {
      grid(
        columns: (1fr, auto),
        text(weight: "bold")[#p.name],
        text(size: 9pt, fill: rgb("#666666"))[#if p.url != "" { link(p.url)[#p.url] }]
      )
      text(size: 9.5pt)[#p.description]
      v(2pt)
      for h in p.highlights {
        [• #h \ ]
      }
      if p.keywords.len() > 0 {
        v(1pt)
        text(size: 8pt, fill: rgb("#888888"), style: "italic")[Keywords: #p.keywords.join(", ")]
      }
      v(4pt)
    }
  }

  // ── Education ──────────────────────────────────────────────────────────────
  if data.education.len() > 0 {
    heading(level: 2)[Education]
    for e in data.education {
      grid(
        columns: (1fr, auto),
        text(weight: "bold")[#e.institution],
        text(size: 9pt, fill: rgb("#666666"))[#e.start_date – #e.end_date]
      )
      text(size: 9.5pt)[#e.study_type, #e.area #if e.score != "" [ | #e.score]]
      v(4pt)
    }
  }

  // ── Skills ─────────────────────────────────────────────────────────────────
  if data.skills.len() > 0 {
    heading(level: 2)[Skills]
    for s in data.skills {
      [*#s.name:* #s.keywords.join(", ") \ ]
    }
    v(4pt)
  }

  // ── Certifications & Awards (two-column) ───────────────────────────────────
  let has_certs = data.certificates.len() > 0
  let has_awards = data.awards.len() > 0

  if has_certs or has_awards {
    grid(
      columns: (1fr, 1fr),
      gutter: 12pt,
      {
        if has_certs {
          heading(level: 2)[Certifications]
          for c in data.certificates {
            [• #c.name — #c.issuer (#c.date) \ ]
          }
        }
      },
      {
        if has_awards {
          heading(level: 2)[Awards & Recognition]
          for a in data.awards {
            [• *#a.title* (#a.date) \ ]
          }
        }
      }
    )
  }
}
