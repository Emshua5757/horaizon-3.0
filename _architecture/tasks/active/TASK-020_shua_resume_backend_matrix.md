# TASK-020 — `shua_resume` Go Microservice & Typst PDF Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Go / SQLite / Typst |
| **Target** | `shua_modules/shua_resume/` |
| **Blocks** | TASK-021 |
| **Prerequisites** | TASK-004 (HBP v2 Broker), TASK-006 (Ollama Lifecycle) |

---

## Overview

Build the `shua_resume` Go microservice that manages a centralized Resume Matrix database, performs Jaccard similarity & LLM keyword tailoring against job descriptions, and compiles publication-quality resumes using Typst.

---

## Key Modules & Specifications

1. **Resume Matrix Database (`pkg/db/`)**:
   - Work experience, project portfolio, technical skills, education, certifications.
2. **AI Tailoring Engine (`pkg/ai/tailor.go`)**:
   - Tokenization & Jaccard similarity scoring.
   - LLM bullet point tailoring via `shua_governor` AI Intent Router (`governor.ai.route`).
3. **Typst PDF Compiler (`pkg/pdf/builder.go`)**:
   - Dynamic Typst markup generation & local PDF rendering on Pi 5.
4. **HBP v2 RPC Operations**:
   - `resume.matrix.get`, `resume.matrix.update`, `resume.tailor`, `resume.pdf.compile`.
