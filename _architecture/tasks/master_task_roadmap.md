# horAIzon 3.0 — Master Task Roadmap

Complete master task index for horAIzon 3.0, mapping all core infrastructure and feature microservices into executable tasks.
This roadmap enforces **ADR-001 (Native Flutter over SDUI)**: all UI screens are 100% native Flutter Dart widgets, and all backend microservices are clean Data APIs with zero SDUI/blueprint logic.

---

## Phase 1: Core Governor & Native Flutter Client Baseline

| Task ID | Component | Language/Stack | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-001** | `shua_governor` | Bash / SSH | Pi 5 SSH & Workspace Cleanup | [x] Completed |
| **TASK-002** | Workspace | VSCode | VSCode & Multi-root Configuration | [x] Completed |
| **TASK-003** | `shua_governor` | Rust | Rust Scaffold, Tokio Event Loop & System Tracing | [x] Completed |
| **TASK-004** | `shua_governor` | Rust | HBP v2 Binary Protocol Broker & MessagePack Encoder | [x] Completed |
| **TASK-004B** | Architecture | Markdown | HBP Contract Schema Engine & Modularization | [x] Completed |
| **TASK-005** | `shua_governor` | Rust | Process Registry & Linux cgroups v2 Manager | [x] Completed |
| **TASK-006** | `shua_governor` | Rust | Ollama Lifecycle, AI Router & Dream Loop Scheduler | [x] Completed |
| **TASK-007** | `shua_governor` | Rust + bash | AppConfig Hierarchy & Systemd Daemonization on Pi 5 | [x] Completed |
| **TASK-008** | `client_flutter` | Dart / Flutter | Project Scaffold & Pubspec Dependency Graph | [ ] Next Up |
| **TASK-009** | `client_flutter` | Dart / Flutter | Core HBP v2 Client, WebSocket Channel & MessagePack Codec | [ ] Planned |
| **TASK-010** | `client_flutter` | Dart / Flutter | GoRouter, Splash Screen & Material 3 HCT Dark Theme | [ ] Planned |
| **TASK-011** | `client_flutter` | Dart / Flutter | Dashboard & Governor Process Manager Screens | [ ] Planned |
| **TASK-012** | `client_flutter` | Dart / Flutter | Settings Screen & Connection Quality Banner | [ ] Planned |
| **TASK-013** | Infrastructure | Rust + Ollama | Local AI Coding Agent Pipeline & Context Injection | [ ] Planned |
| **TASK-014** | `shua_aspnet_portal` | C# / ASP.NET Core | Remote Web Portal for Governor & Telemetry Dashboard | [ ] Planned |

---

## Phase 2: Code Topology & Visualizer Engine

| Task ID | Component | Language/Stack | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-015** | `shua_code_visualizer` | **Rust** | Multi-language AST Parser (Tree-sitter), Complexity Engine & Call Graph Builder | [ ] Planned |
| **TASK-016** | `client_flutter` | Dart / Flutter | Native Code Topology Screen (Interactive CustomPainter symbol graph UI) | [ ] Planned |

---

## Phase 3: AI Diary Microservice & Native Flutter Editor

| Task ID | Component | Language/Stack | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-017** | `shua_diary` | **Node.js / TypeScript** (Express + WebSocket + better-sqlite3) | Clean Data API microservice, Pi 5 Deduplicated Media Vault & Governor HBP telemetry | [ ] Planned |
| **TASK-018** | `shua_diary` | **Node.js / TypeScript** | Ollama AI assistant & entry analysis pipeline (Ollama-first, Gemini fallback) | [ ] Planned |
| **TASK-019** | `client_flutter` | Dart / Flutter | Native Flutter Diary Screen & 37 Native Block Widgets Library | [ ] Planned |

---

## Phase 4: AI Resume Matrix Engine

| Task ID | Component | Language/Stack | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-020** | `shua_resume` | **Go** (SQLite + Typst) | Port horAIzon 2.0 resume module — data API, Jaccard AI tailoring, Typst PDF compiler | [ ] Planned |
| **TASK-021** | `client_flutter` | Dart / Flutter | Native Flutter Resume Builder — matrix editor & live PDF preview screen | [ ] Planned |

---

## Phase 5: Health & Vault Microservices

| Task ID | Component | Language/Stack | Description | Status |
| :--- | :--- | :--- | :--- | :--- |
| **TASK-022** | `shua_gym` | TBD | Workout & Physical Activity Tracking Service + Native Flutter Screen | [ ] Planned |
| **TASK-023** | `shua_crypto` | TBD | Decentralized Vault & Key Manager Service + Native Flutter Screen | [ ] Planned |

---

## Architectural Rules (ADR-001 Summary)

1. **NO SDUI**: All screens are 100% native Flutter Dart widgets powered by Riverpod.
2. **Backends are Data APIs**: Microservices expose strongly-typed JSON/MessagePack DTOs over WebSocket/HBP v2. Backends contain **zero UI blueprint or layout code**.
3. **No Offline Sync Complexity**: Single source of truth is the Pi 5 database. All client interactions are direct online RPC over LAN/Tailscale.
