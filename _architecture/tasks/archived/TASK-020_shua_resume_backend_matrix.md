# TASK-020 — `shua_resume` Go Microservice: Resume Matrix, Typst Engine & MCP Server

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Go / SQLite / Typst |
| **Target** | `shua_resume/` |
| **Blocks** | TASK-021 |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-006B (Governor MCP Router), TASK-022 (Governor Media Vault) |
| **References** | `_architecture/contracts/hbp/hbp_v2_spec.md`, `_architecture/contracts/hbp/API_REFERENCE.md`, `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/reference/shua_resume/` |

---

## Architectural Directives (READ BEFORE WRITING A SINGLE LINE)

> [!IMPORTANT]
> **NO SDUI. NO BLUEPRINTS. NO SCREEN ASSEMBLERS. NO PER-MODULE HTTP SERVER.**
>
> The horAIzon 2.0 `shua_resume` contained:
> - `pkg/handlers/sdui_blueprint_loader.go` — `LoadAndHydrateBlueprint`, `assembleScreen`, `hydrateValue`, `hydrateString`. **DELETE ALL.**
> - `pkg/handlers/resume_handler.go` — HTTP/Fiber REST handlers on their own port. **DELETE ALL.**
> - `pkg/handlers/websocket_handler.go` — old RPC over raw WebSocket. **DELETE.**
> - Direct Ollama HTTP calls in `pkg/ai/tailor.go`. **REPLACE** with Governor AI Router RPC.
>
> `shua_resume` in 3.0 is ONLY:
> 1. A SQLite persistence layer for the Resume Matrix.
> 2. A Typst PDF compilation engine.
> 3. A Jaccard AI tailoring engine.
> 4. A HBP v2 RPC endpoint (via Governor broker — NOT a standalone WebSocket server).
> 5. An MCP tool provider (registers with Governor over IPC port 7701).
>
> **PDF files are deposited into the Governor Media Vault (TASK-022) via IPC — `shua_resume` does NOT run its own HTTP file server.**
> **UI rendering is entirely `client_flutter` (TASK-021). The backend has zero UI concerns.**

> [!NOTE]
> **Port Strategy from 2.0 Reference (`_architecture/reference/shua_resume/`)**:
> - **KEEP & PORT**: `pkg/ai/tailor.go` — `Tokenize`, `JaccardSimilarity`, `FilterResume`, `TailorConfig`. Replace the direct `OllamaRequest` HTTP call with `governor.ai.route` HBP v2 RPC.
> - **KEEP & PORT**: `pkg/compiler/typst_compiler.go` — `CompileTypst`, `resolveTypstPath`, `findModuleRoot`. Preserve the `[]byte` PDF output contract. Typst was working in 2.0 — port as-is, update path resolution for horAIzon 3.0 directory layout.
> - **KEEP & PORT**: `pkg/models/resume.go` — All 8 structs are the canonical data model. Add `Id string` fields where missing for SQLite keying.
> - **KEEP & PORT**: `pkg/db/db.go` — `InitDB`, `runMigrations`, `seedDatabase`. Rewrite seed data from `_architecture/reference/shua_resume/master_profile.json` (Joshua B. Ygot profile).
> - **DELETE ENTIRELY**: `pkg/handlers/sdui_blueprint_loader.go`
> - **DELETE**: `pkg/handlers/websocket_handler.go`, `pkg/handlers/resume_handler.go`
> - **REWRITE**: `cmd/main.go` — connect to Governor IPC (7701), register MCP, start HBP handler loop.

---

## Target File Structure

```
shua_resume/
├── cmd/
│   └── main.go                          # Entrypoint: init DB, register MCP tools, connect to Governor IPC
├── pkg/
│   ├── models/
│   │   └── resume.go                    # ResumeMatrix, Basics, WorkItem, Education, ProjectItem, Skill, Certificate, Award
│   ├── db/
│   │   └── db.go                        # InitDB, runMigrations, seedDatabase
│   ├── repository/
│   │   └── resume_repository.go         # GetMatrix, UpdateSection, ListHistory, SaveHistory CRUD
│   ├── ai/
│   │   └── tailor.go                    # Tokenize, JaccardSimilarity, FilterResume, TailorResume (Governor AI Router)
│   ├── compiler/
│   │   └── typst_compiler.go            # CompileTypst: matrix -> Typst markup -> exec typst -> []byte PDF
│   ├── hbp/
│   │   └── hbp_handler.go               # HBP v2 frame router: decode msgpack, dispatch op, encode response
│   └── mcp/
│       └── mcp_server.go                # IPC registration + tool call dispatch
├── templates/
│   ├── default.typ                      # Default Typst template (see spec below)
│   ├── modern.typ                       # Modern two-column Typst template
│   └── minimalist.typ                   # Minimalist tight-layout Typst template
├── go.mod
└── go.sum
```

**Time Complexity**: O(n) on resume matrix size (n <= 100 rows total across all tables).
**Space Complexity**: O(n) matrix in memory; O(pdf_size) transient during Typst compilation.

---

## SQLite Schema (`pkg/db/db.go` — `runMigrations`)

```sql
CREATE TABLE IF NOT EXISTS resume_basics (
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
);

CREATE TABLE IF NOT EXISTS resume_work (
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
);

CREATE TABLE IF NOT EXISTS resume_education (
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
);

CREATE TABLE IF NOT EXISTS resume_projects (
  id          TEXT PRIMARY KEY,
  user_id     TEXT NOT NULL DEFAULT 'shua',
  name        TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  highlights  TEXT NOT NULL DEFAULT '[]',
  url         TEXT NOT NULL DEFAULT '',
  exhibits    TEXT NOT NULL DEFAULT '[]',
  active      INTEGER NOT NULL DEFAULT 1,
  sort_order  INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS resume_skills (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL DEFAULT 'shua',
  name       TEXT NOT NULL DEFAULT '',
  level      TEXT NOT NULL DEFAULT '',
  keywords   TEXT NOT NULL DEFAULT '[]',
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS resume_certificates (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL DEFAULT 'shua',
  name       TEXT NOT NULL DEFAULT '',
  issuer     TEXT NOT NULL DEFAULT '',
  date       TEXT NOT NULL DEFAULT '',
  url        TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS resume_awards (
  id         TEXT PRIMARY KEY,
  user_id    TEXT NOT NULL DEFAULT 'shua',
  title      TEXT NOT NULL DEFAULT '',
  date       TEXT NOT NULL DEFAULT '',
  awarder    TEXT NOT NULL DEFAULT '',
  summary    TEXT NOT NULL DEFAULT '',
  sort_order INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS resume_history (
  exhibit_id   TEXT PRIMARY KEY,   -- SHA256 from Governor Media Vault
  vault_url    TEXT NOT NULL,       -- http://{pi5}:7702/vault/resume/...
  template_id  TEXT NOT NULL DEFAULT '',
  job_desc     TEXT NOT NULL DEFAULT '',
  tailor_score REAL,
  ai_enhanced  INTEGER NOT NULL DEFAULT 0,
  duration_ms  INTEGER NOT NULL DEFAULT 0,
  compiled_at  TEXT NOT NULL
);
```

**Seed data** is sourced from `_architecture/reference/shua_resume/master_profile.json`. `seedDatabase` checks `resume_basics` row count before inserting — idempotent.

---

## PDF Storage: Governor Media Vault Integration

> [!IMPORTANT]
> `shua_resume` MUST NOT write PDF files to disk directly. After `CompileTypst` returns `[]byte`:
>
> 1. Send `vault.upload` over IPC (port 7701) to the Governor:
>    ```json
>    {
>      "op": "vault.upload",
>      "id": "{uuid}",
>      "module": "resume",
>      "file_name": "resume_{timestamp}.pdf",
>      "mime_type": "application/pdf",
>      "data_base64": "{base64 PDF bytes}"
>    }
>    ```
> 2. Governor responds: `{ "sha256_hash": "...", "url": "http://{pi5}:7702/vault/resume/..." }`
> 3. Store `sha256_hash` as `exhibit_id` and `url` as `vault_url` in `resume_history`.
> 4. Return `exhibit_id` and `vault_url` to Flutter client in `ResumeCompileResponse`.

---

## HBP v2 RPC Operations

All operations use the HBP v2 envelope (see `hbp_v2_spec.md`). `pkg/hbp/hbp_handler.go` decodes the outer frame and dispatches on `op`.

### `shua.resume.matrix.get`

**Request payload**: empty msgpack bytes
**Response payload** (`ResumeMatrixDto`):

```msgpack
{
  "basics": {
    "name": str, "label": str, "email": str, "phone": str,
    "url": str, "summary": str,
    "location": { "city": str, "region": str, "country_code": str },
    "profiles": [{ "network": str, "username": str, "url": str }]
  },
  "work": [{ "id": str, "name": str, "position": str, "url": str,
    "start_date": str, "end_date": str, "summary": str,
    "highlights": [str], "skills": [str], "active": bool }],
  "education": [{ "id": str, "institution": str, "url": str, "area": str,
    "study_type": str, "start_date": str, "end_date": str,
    "score": str, "courses": [str] }],
  "projects": [{ "id": str, "name": str, "description": str,
    "highlights": [str], "url": str, "exhibits": [str], "active": bool }],
  "skills": [{ "id": str, "name": str, "level": str, "keywords": [str] }],
  "certificates": [{ "id": str, "name": str, "issuer": str, "date": str, "url": str }],
  "awards": [{ "id": str, "title": str, "date": str, "awarder": str, "summary": str }]
}
```

### `shua.resume.matrix.update`

**Request payload**:
```msgpack
{
  "section": str,  -- "basics"|"work"|"education"|"projects"|"skills"|"certificates"|"awards"
  "action":  str,  -- "upsert"|"delete"|"reorder"
  "item":    map,  -- Section-specific DTO matching get response shape
  "id":      str?  -- Required for "delete"
}
```

**Response payload**: `{ "ok": bool, "id": str }`

### `shua.resume.compile`

**Compilation pipeline**:
1. `ResumeRepository.GetMatrix("shua")` — fetch matrix from SQLite.
2. If `tailor == true && job_desc != ""`: `FilterResume(matrix, job_desc, DefaultTailorConfig())` — compute `tailor_score`.
3. If `ai_enhance == true`: `TailorResume(matrix, job_desc, config)` — call `governor.ai.route` RPC.
4. `CompileTypst(matrix, template)` — returns `[]byte` PDF.
5. **Typst fallback**: If Typst binary absent or compile fails, generate formatted Markdown export of matrix. Log `warn!`. Return `ERR_TYPST_UNAVAILABLE` in HBP `err` field with Markdown in `p`.
6. Send `vault.upload` IPC to Governor → receive `sha256_hash` + `vault_url`.
7. Insert row into `resume_history`.
8. Return `ResumeCompileResponse`.

**Request payload** (index-keyed per `API_REFERENCE.md`):
```msgpack
{ 1: str, 2: str, 3: str?, 4: bool, 5: bool }
-- matrix_id, template, job_desc, tailor, ai_enhance
```

**Response payload** (index-keyed per `API_REFERENCE.md`):
```msgpack
{ 1: str, 2: str, 3: u32, 4: f32? }
-- exhibit_id (SHA256), pdf_url (vault URL), duration_ms, tailor_score
```

### `shua.resume.history.list`

**Response payload**:
```msgpack
{
  "items": [{
    "exhibit_id": str, "vault_url": str, "template_id": str,
    "job_desc": str, "tailor_score": f32?, "ai_enhanced": bool,
    "duration_ms": u32, "compiled_at": str
  }]
}
```

### `shua.resume.templates.list`

**Response payload**:
```msgpack
{
  "templates": [
    { "id": "default",     "name": "Default",     "description": "Clean ATS-friendly single-column layout" },
    { "id": "modern",      "name": "Modern",       "description": "Two-column with sidebar for skills and education" },
    { "id": "minimalist",  "name": "Minimalist",   "description": "Compact tight-layout for one-page resumes" }
  ]
}
```

---

## Typst Templates (`templates/`)

Templates were lost from horAIzon 2.0 — write new ones. All 3 templates accept the same JSON-serialized `ResumeMatrix` passed as a Typst data dictionary via stdin or temp file. The `CompileTypst` function serializes the matrix and passes it to the template.

### `default.typ` — Clean ATS Single-Column

Layout spec:
```
┌─────────────────────────────────┐
│  JOSHUA B. YGOT                 │  <- name (28pt bold)
│  Computer Engineer              │  <- label (12pt)
│  email | phone | LinkedIn       │  <- contact row (9pt)
├─────────────────────────────────┤
│  SUMMARY                        │  <- section heading (11pt caps, rule below)
│  [summary text]                 │
├─────────────────────────────────┤
│  EXPERIENCE                     │
│  Company Name          Date     │  <- name + date right-aligned
│  Position Title                 │  <- italic
│  • Highlight bullet             │  <- 9pt bullets
├─────────────────────────────────┤
│  PROJECTS                       │
│  Project Name          URL      │
│  • Highlight bullet             │
├─────────────────────────────────┤
│  EDUCATION                      │
│  Institution           Date     │
│  Degree, Area | GWA: x.xx       │
├─────────────────────────────────┤
│  SKILLS                         │
│  Category: keyword, keyword     │  <- inline keyword list per group
├─────────────────────────────────┤
│  CERTIFICATIONS  |  AWARDS      │  <- two columns for short sections
└─────────────────────────────────┘
```

Font: `IBM Plex Sans` (free, good ATS scanning). Margins: 1.5cm. Line height: 1.2. Accent color: `#1a1a2e` (dark navy). Section headings: small-caps, 0.5pt rule below.

### `modern.typ` — Two-Column with Sidebar

Layout spec:
```
┌──────────────┬────────────────────┐
│  SIDEBAR     │  MAIN CONTENT      │
│  (30% width) │  (70% width)       │
│              │                    │
│  [Photo box] │  JOSHUA B. YGOT   │
│  -- blank -- │  Computer Engineer │
│              │                    │
│  CONTACT     │  EXPERIENCE        │
│  email       │  [work items]      │
│  phone       │                    │
│  LinkedIn    │  PROJECTS          │
│              │  [project items]   │
│  SKILLS      │                    │
│  [skill      │  EDUCATION         │
│   keywords]  │  [education items] │
│              │                    │
│  CERTS       │  AWARDS            │
│  [certs]     │  [awards]          │
└──────────────┴────────────────────┘
```

Sidebar background: `#1a1a2e`. Sidebar text: white. Main content: standard black on white. Font: `Inter`. Header: 24pt bold name, 11pt label.

### `minimalist.typ` — Compact One-Page

Layout spec:
- No section dividers — only 8pt bold section labels in gray (`#888888`) with a thin top border.
- All bullets replaced with em-dash (—) for compactness.
- Font size: 9pt body, 10pt company/institution names, 18pt name.
- Margins: 1.2cm all sides.
- No sidebar — pure single column but tighter spacing than `default`.
- Skills rendered as comma-separated keyword strings (no group headings) to save vertical space.
- Target: forces everything onto exactly one page for junior positions.

---

## MCP Server Registration (`pkg/mcp/mcp_server.go`)

Connect to `ws://127.0.0.1:7701/ipc` on startup. Send registration:

```json
{
  "op": "governor.mcp.register",
  "module_id": "shua.resume",
  "version": "3.0.0",
  "scope": "resume",
  "tools": [
    {
      "name": "resume_tailor_jaccard",
      "description": "Filters the active resume matrix against a job description using Jaccard token similarity. Returns a filtered ResumeMatrix with match score.",
      "scope": "resume",
      "timeout_s": 15,
      "input_schema": {
        "type": "object",
        "properties": {
          "job_desc":  { "type": "string" },
          "threshold": { "type": "number", "description": "Minimum Jaccard score (0.0-1.0, default 0.15)" }
        },
        "required": ["job_desc"]
      }
    },
    {
      "name": "resume_compile_pdf",
      "description": "Compiles the active resume matrix into a Typst PDF. Returns exhibit_id and vault URL for the PDF on Pi 5.",
      "scope": "resume",
      "timeout_s": 60,
      "input_schema": {
        "type": "object",
        "properties": {
          "template":   { "type": "string", "enum": ["default", "modern", "minimalist"] },
          "job_desc":   { "type": "string" },
          "tailor":     { "type": "boolean" },
          "ai_enhance": { "type": "boolean" }
        },
        "required": ["template"]
      }
    }
  ]
}
```

---

## AI Tailoring Pipeline (`pkg/ai/tailor.go`)

Port from `_architecture/reference/shua_resume/pkg/ai/tailor.go`.

**`TailorResume` change**: Replace direct Ollama HTTP with `governor.ai.route` HBP v2 RPC:
```go
// Build prompt
prompt := fmt.Sprintf("Enhance this resume JSON for the following job. Return ONLY the modified JSON:\n%s\nJob description:\n%s", matrixJSON, jobDesc)
// Send HBP v2 REQUEST to Governor ws://127.0.0.1:7700/hbp
// op: "governor.ai.route", payload: AiRouteRequest{ prompt, context_hint: "resume" }
// Parse AiRouteResponse.reply as JSON into *ResumeMatrix
```

All other functions (`Tokenize`, `JaccardSimilarity`, `FilterResume`, `DefaultTailorConfig`) — zero changes from 2.0.

**Time Complexity**:
- `Tokenize`: O(n), n = token count
- `JaccardSimilarity`: O(|A| + |B|)
- `FilterResume`: O((W + P) * T), W = work items, P = projects, T = avg token set size
- `TailorResume`: O(network) — bounded by Ollama inference time

---

## Telemetry Logging

```go
logger.Info("hbp_handler", "resume.compile dispatched", map[string]interface{}{ "template": template, "tailor": tailor })
logger.Info("mcp_server",  "resume MCP tools registered with governor", nil)
logger.Warn("compiler",    "typst binary not found — markdown fallback activated", nil, nil)
logger.Error("vault_ipc",  "vault.upload IPC failed", err, map[string]interface{}{ "exhibit_id": id })
```

Emit `info!`: startup, MCP registration, every RPC dispatch.
Emit `warn!`: Typst fallback activated.
Emit `error!`: DB failure, Governor IPC disconnect, vault upload failure, MsgPack decode error.

---

## Acceptance Criteria

- [ ] `pkg/handlers/sdui_blueprint_loader.go` does NOT exist
- [ ] `shua_resume` connects to Governor IPC port 7701 and registers 2 MCP tools on startup
- [ ] `shua.resume.matrix.get` returns Joshua B. Ygot profile seeded from `master_profile.json`
- [ ] `shua.resume.matrix.update` action `upsert` persists to SQLite and returns `{ ok: true }`
- [ ] `shua.resume.compile` calls `vault.upload` IPC; returned `vault_url` is a port-7702 HTTP URL
- [ ] `shua.resume.compile` with `tailor: true` returns non-null `tailor_score`
- [ ] Typst fallback: missing binary returns Markdown text in `p` + `ERR_TYPST_UNAVAILABLE` in `err`
- [ ] All 3 Typst templates (`default.typ`, `modern.typ`, `minimalist.typ`) compile valid PDFs with Joshua Ygot profile data
- [ ] `resume_tailor_jaccard` MCP tool call returns filtered matrix + Jaccard score
- [ ] `go build ./...` 0 errors, `go vet ./...` 0 issues
