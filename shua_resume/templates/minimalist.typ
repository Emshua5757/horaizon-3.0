// Minimalist compact one-page Typst resume template.
// Layout: Tight margins (1.2cm), 9pt body text, em-dash bullet points,
// flat section headings with thin top rule. Designed to fit content on exactly 1 page.
#let resume_template(data) = {
  set document(title: data.basics.name + " — Resume")
  set page(margin: (x: 1.2cm, y: 1.2cm))
  set text(font: "Inter", size: 9pt, lang: "en")
  set par(leading: 0.45em)

  let dark_gray = rgb("#333333")
  let accent = rgb("#555555")

  show heading: it => {
    v(4pt)
    set text(size: 8pt, weight: "bold", fill: accent)
    upper(it.body)
    v(-4pt)
    line(length: 100%, stroke: 0.4pt + rgb("#cccccc"))
    v(2pt)
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  grid(
    columns: (1fr, auto),
    [
      #text(size: 16pt, weight: "bold", fill: dark_gray)[#data.basics.name] \
      #text(size: 9.5pt, style: "italic", fill: accent)[#data.basics.label]
    ],
    align(right)[
      #text(size: 8pt)[
        #data.basics.email \
        #data.basics.phone \
        #data.basics.location.city, #data.basics.location.region
      ]
    ]
  )

  v(2pt)

  // ── Summary ────────────────────────────────────────────────────────────────
  if data.basics.summary != "" {
    heading(level: 2)[Summary]
    text(size: 8.5pt)[#data.basics.summary]
  }

  // ── Experience ─────────────────────────────────────────────────────────────
  let active_work = data.work.filter(w => w.active)
  if active_work.len() > 0 {
    heading(level: 2)[Experience]
    for w in active_work {
      grid(
        columns: (1fr, auto),
        [*#w.position* — #text(style: "italic")[#w.name]],
        text(size: 8pt, fill: accent)[#w.start_date – #w.end_date]
      )
      v(1pt)
      for h in w.highlights {
        [— #h \ ]
      }
      v(2pt)
    }
  }

  // ── Projects ───────────────────────────────────────────────────────────────
  let active_projects = data.projects.filter(p => p.active)
  if active_projects.len() > 0 {
    heading(level: 2)[Projects]
    for p in active_projects {
      grid(
        columns: (1fr, auto),
        [*#p.name* — #p.description],
        text(size: 8pt, fill: accent)[#if p.url != "" { p.url }]
      )
      v(1pt)
      for h in p.highlights {
        [— #h \ ]
      }
      v(2pt)
    }
  }

  // ── Education ──────────────────────────────────────────────────────────────
  if data.education.len() > 0 {
    heading(level: 2)[Education]
    for e in data.education {
      grid(
        columns: (1fr, auto),
        [*#e.institution* — #e.study_type, #e.area #if e.score != "" [ (#e.score) ]],
        text(size: 8pt, fill: accent)[#e.start_date – #e.end_date]
      )
    }
  }

  // ── Skills ─────────────────────────────────────────────────────────────────
  if data.skills.len() > 0 {
    heading(level: 2)[Skills]
    let all_keywords = ()
    for s in data.skills {
      all_keywords = all_keywords + s.keywords
    }
    text(size: 8.5pt)[#all_keywords.join(" • ")]
  }

  // ── Certifications & Awards ────────────────────────────────────────────────
  let has_certs = data.certificates.len() > 0
  let has_awards = data.awards.len() > 0

  if has_certs or has_awards {
    heading(level: 2)[Certifications & Honors]
    if has_certs {
      for c in data.certificates {
        [— *#c.name* (#c.issuer, #c.date) \ ]
      }
    }
    if has_awards {
      for a in data.awards {
        [— *#a.title* (#a.awarder, #a.date) \ ]
      }
    }
  }
}
