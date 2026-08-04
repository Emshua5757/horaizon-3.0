# TASK-023 — Resume Matrix Polish & Schema Expansion

| Field | Value |
| :--- | :--- |
| **Status** | [ ] In Progress |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Go, Dart/Flutter |
| **Branch** | `task/TASK-023-resume-matrix-polish` |
| **Depends On** | TASK-020, TASK-021 |

---

## Goal

Harden and expand the `shua_resume` feature set based on real-world usage feedback:
fix date inconsistencies that break Typst compilation, expand the Basics schema with
dynamic social profile links, clarify the `highlights` vs `summary` distinction,
add `keywords` to projects/work, add an Organizational Experience section, unify Go
logging into the Governor telemetry pipeline, remove the Resume nav item from the sidebar,
and add a Markdown export from the History screen.

---

## Sub-Tasks

### 1. Fix JSON Tags — snake_case for Typst Compatibility (Go)
**Problem:** Typst templates reference `start_date`, `end_date`, `study_type`, `country_code`
in snake_case, but `resume.go` emits them in camelCase JSON.
- `WorkItem`: `startDate` → `start_date`, `endDate` → `end_date`
- `Education`: `studyType` → `study_type`, `startDate` → `start_date`, `endDate` → `end_date`
- `Location`: `countryCode` → `country_code`

### 2. Date Normalization Middleware (Go)
**Problem:** User types dates in freeform ("Aug 2024", "2024-08", "August 2024", "Present")
and Typst crashes on unexpected/missing formats.
- Create `pkg/dateutil/normalize.go` — `NormalizeDate(input string) string`
- Accept: `YYYY-MM-DD`, `YYYY-MM`, `YYYY`, `Month YYYY`, `Mon YYYY`, `MM/YYYY`,
  `Present`/`Current`/empty → output `"MMM YYYY"` (e.g. `"Aug 2024"`) or `"Present"` / `""`.
- Call `NormalizeDate` on all date fields before saving to SQLite and before Typst compilation.

### 3. Schema Expansion — Dynamic Profile Links (Go + Dart)
- Remove single `Basics.Url` field (deprecate with `omitempty`).
- The existing `Basics.Profiles []Profile{Network, Username, Url}` is the canonical schema.
- **Flutter:** Replace single "Website URL" field with a dynamic list editor — user can
  add/remove entries with `Network` label (e.g. "GitHub", "LinkedIn") and `URL`.
- **Typst:** Update header to iterate all profiles, render separated by `|`.

### 4. Schema Expansion — Highlights / Summary / Keywords Clarification (Go + Dart)
- **Summary**: 1–3 sentence prose description (on Work & Project).
- **Highlights**: Ordered list of bullet-point achievements. Example: `"Led migration of
  legacy PHP monolith to Go microservices, reducing p99 latency by 40%"`. Each = one bullet.
- **Keywords**: ATS-targeted technology/skill tags (e.g. `["Go", "gRPC", "Docker"]`).
- Add `Keywords []string` to `WorkItem` and `ProjectItem`.
- Add hint/placeholder text in Flutter editor cards so the user understands each field.
- Update Typst templates to render keywords as a subtle tag line.
- Update Markdown export to include keywords.

### 5. Schema Expansion — Organizational Experience Section (Go + Dart)
- Add `Organizations []OrgItem` to `ResumeMatrix`.
- `OrgItem`: `{Id, Organization, Role, StartDate, EndDate, Summary, Highlights []string, Active bool}`
- New tab "Org Experience" in the Flutter 7-tab editor.
- Typst rendering block (similar to Work section) + Markdown export block.

### 6. Remove Resume from Shell Scaffold Sidebar (Flutter)
- Remove `_Dest` entry for `/resume` from `_destinations` in `shell_scaffold.dart`.
- Keep the `/resume` route registered in `app_router.dart`.
- `microservices_section.dart` `onLaunch` remains the sole entry point.

### 7. Markdown Export (Flutter + Go)
- Add "Export as Markdown" button to `ResumeHistoryScreen`.
- New HBP RPC op `shua.resume.export.markdown` → Go calls `MatrixToMarkdown(matrix)` and
  returns the string as payload.
- Flutter: write to downloads / share via `share_plus`.
- Add op to `hbp_ops.dart` and `hbp_handler.go`.

### 8. Unify Go Logging into Governor Telemetry (Go + Rust)
- Verify Governor's `ProcessSupervisor` pipes `shua_resume` stdout into the telemetry
  ingestion path.
- `shua_resume` already emits valid structured JSON logs — ensure they flow through.

### 9. Template Preview — Static Images (Flutter)
- Commit 3 static preview PNG files to `shua_resume/templates/previews/`.
- Bundle as Flutter assets.
- Show thumbnail on template picker in the Compile screen.

---

## Data Storage Note
The SQLite `resume.db` lives on the **Raspberry Pi 5** in the `shua_resume` working directory.
It is NOT local to Windows. All data flows over HBP v2 / Tailscale (100.67.11.0).

---

## Verification Plan
1. `go build ./...` in `shua_resume/` — zero errors.
2. `flutter analyze` — zero warnings.
3. Enter date "August 2024" → renders as "Aug 2024" in PDF.
4. Add GitHub profile → appears in PDF header.
5. Add org experience entry → appears in PDF and Markdown.
6. Resume no longer in sidebar nav; accessible from Dashboard card only.
7. "Export as Markdown" writes/shares a valid `.md` file.
8. `shua.resume` log events appear in Flutter Telemetry screen.
