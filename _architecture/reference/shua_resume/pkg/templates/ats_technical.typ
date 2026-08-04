#let resume_template(data, theme: (primary: rgb("1a2a3a"))) = {
  // Retrieve properties safely
  let basics = data.at("basics", default: none)
  let work-history = data.at("work", default: ())
  if work-history == none { work-history = () }
  let academic-history = data.at("education", default: ())
  if academic-history == none { academic-history = () }
  let projects = data.at("projects", default: ())
  if projects == none { projects = () }
  let skills = data.at("skills", default: ())
  if skills == none { skills = () }
  let certificates = data.at("certificates", default: ())
  if certificates == none { certificates = () }
  let awards = data.at("awards", default: ())
  if awards == none { awards = () }

  // Configure margins & fonts
  set page(
    paper: "us-letter",
    margin: (x: 1.5cm, y: 1.5cm),
  )
  set text(
    font: "Liberation Sans", // Standard safe default on Linux/Pi 5/Windows
    size: 10pt,
    fill: rgb("#333333"),
  )

  // Layout formatting
  if basics != none {
    align(center)[
      #text(size: 20pt, weight: "bold", fill: theme.primary)[#basics.at("name", default: "")]
      \
      #text(size: 11pt, weight: "medium", fill: rgb("#555555"))[#basics.at("label", default: "")]
      \
      #text(size: 9pt)[
        #basics.at("email", default: "") | #basics.at("phone", default: "") | #basics.at("url", default: "")
        #if basics.at("location", default: none) != none [
          | #basics.location.at("city", default: "")#if basics.location.at("countryCode", default: "") != "" [, #basics.location.at("countryCode")]
        ]
      ]
    ]
  }

  // Experience Section
  if work-history.len() > 0 {
    heading(level: 2, numbering: none)[Experience]
    line(length: 100%, stroke: 0.5pt + theme.primary)
    
    for job in work-history {
      if job.at("active", default: true) {
        block(width: 100%, breakable: false)[
          #grid(
            columns: (1fr, auto),
            [*#job.at("position")* --- #job.at("name")],
            [_#job.at("startDate") to #job.at("endDate")_]
          )
          #if job.at("summary", default: "") != "" [
            #text(size: 9.5pt, style: "italic")[#job.at("summary")]
          ]
          #list(..job.at("highlights", default: ()).map(point => point))
        ]
      }
    }
  }

  // Projects Section
  if projects.len() > 0 {
    heading(level: 2, numbering: none)[Projects]
    line(length: 100%, stroke: 0.5pt + theme.primary)
    
    for proj in projects {
      if proj.at("active", default: true) {
        block(width: 100%, breakable: false)[
          #grid(
            columns: (1fr, auto),
            [*#proj.at("name")*],
            [_#proj.at("url", default: "")_]
          )
          #if proj.at("description", default: "") != "" [
            #text(size: 9.5pt)[#proj.at("description")]
          ]
          #list(..proj.at("highlights", default: ()).map(point => point))
        ]
      }
    }
  }

  // Education Section
  if academic-history.len() > 0 {
    heading(level: 2, numbering: none)[Education]
    line(length: 100%, stroke: 0.5pt + theme.primary)
    
    for edu in academic-history {
      block(width: 100%, breakable: false)[
        #grid(
          columns: (1fr, auto),
          [*#edu.at("institution")* --- #edu.at("area") (#edu.at("studyType", default: ""))],
          [_#edu.at("startDate") to #edu.at("endDate")_]
        )
        #if edu.at("score", default: "") != "" [
          #text(size: 9.5pt)[GPA: #edu.at("score")]
        ]
        #if edu.at("courses", default: ()).len() > 0 [
          #text(size: 9pt)[Courses: #edu.at("courses").join(", ")]
        ]
      ]
    }
  }

  // Skills Section
  if skills.len() > 0 {
    heading(level: 2, numbering: none)[Skills]
    line(length: 100%, stroke: 0.5pt + theme.primary)
    
    for s in skills {
      [*#s.at("name")* (#s.at("level", default: "")): #s.at("keywords", default: ()).join(", ") \ ]
    }
  }
}
