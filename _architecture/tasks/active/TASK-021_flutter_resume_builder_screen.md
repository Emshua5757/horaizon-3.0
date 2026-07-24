# TASK-021 — `client_flutter` Native Resume Builder & Live PDF Preview Screen

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Planned |
| **Phase** | Phase 4 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/resume/` |
| **Blocks** | None |
| **Prerequisites** | TASK-010 (GoRouter & Theme), TASK-020 (`shua_resume` Microservice) |

---

## Overview

Build the native Flutter **Resume Builder Screens**:
1. **Matrix Editor (`/resume/editor`)**: Structured CRUD form for work experience, project portfolio, skills, and education.
2. **Compile & Tailor Screen (`/resume/compile`)**: Job description input box, Typst template picker, Jaccard keyword match score meter, and AI enhancement toggle.
3. **Live PDF History & Viewer (`/resume/history`)**: Downloadable history list of compiled PDF exhibits with built-in PDF viewer widget (`pdfx` or `printing`).

---

## Technical Specifications

1. **Resume Matrix Editor (`resume_editor_screen.dart`)**:
   - Tabbed native forms for Experience, Projects, Skills, Education.
   - Saves updates via `shua.resume.matrix.update` RPC.
2. **AI Tailoring & Typst Compiler Controls (`resume_compile_screen.dart`)**:
   - Pastes target Job Description text to trigger real-time `resume_tailor_jaccard` tool score.
   - Typst template selector dropdown (`default`, `modern`, `minimalist`).
   - "Compile PDF" button dispatches `shua.resume.compile` RPC.
3. **Live PDF Exhibit Viewer (`resume_history_screen.dart`)**:
   - Renders compiled PDF preview directly within Flutter app canvas.
   - Download & Share buttons for Windows file system export and Android share intent.

---

## Acceptance Criteria

- [ ] Navigating to `/resume/editor` loads and persists resume matrix data via `shua_resume` Go backend
- [ ] Job Description input updates Jaccard match percentage gauge dynamically
- [ ] Clicking "Compile PDF" triggers Typst compilation on Pi 5 and renders compiled PDF bytes in live viewer
- [ ] Compilation history lists past exhibits with download buttons
- [ ] `flutter analyze` — 0 errors
