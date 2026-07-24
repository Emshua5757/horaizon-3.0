# TASK-020 — `shua_resume` Go Microservice, Typst Engine & MCP Server

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Go / SQLite / Typst |
| **Target** | `shua_modules/shua_resume/` |
| **Blocks** | TASK-021 |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-006B (Governor MCP Router), `_architecture/contracts/mcp/mcp_master_spec.md` |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md` |

---

## Architectural Directives & MCP Contract Compliance

> [!IMPORTANT]
> **MCP Contract Compliance**: `shua_resume` implements the `resume_*` tools and `resume://` resources specified in `_architecture/contracts/mcp/mcp_master_spec.md`:
> - Tools: `resume_tailor_jaccard`, `resume_compile_pdf`.
> - Resources: `resume://preview/latest`.
> - Registers MCP tool definitions with `shua_governor` via `governor.mcp.register` on boot.

---

## Key Modules & Specifications

1. **Resume Matrix Database (`pkg/db/`)**:
   - Work experience, project portfolio, technical skills, education, certifications in SQLite.
2. **AI Tailoring Engine & MCP Server (`pkg/mcp/server.go`)**:
   - Implements `resume_tailor_jaccard` tool using Jaccard token similarity + Governor AI Router inference.
   - Implements `resume_compile_pdf` tool.
3. **Typst PDF Compiler & Raw Export Fallback (`pkg/pdf/builder.go`)**:
   - Dynamic Typst markup generation & local PDF rendering on Pi 5.
   - **Fallback Policy**: If Typst compilation fails (missing Typst binary or syntax error), `shua_resume` automatically generates and returns a formatted Markdown/JSON raw exhibit payload (`ResumeMatrixDto`) so the user can copy/paste or view their tailored resume text immediately.
4. **HBP v2 RPC Operations**:
   - `resume.matrix.get`, `resume.matrix.update`, `resume.tailor`, `resume.pdf.compile`.

