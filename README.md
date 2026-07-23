# horAIzon 3.0

> **A fully offline, AI-native personal operating system running on a Raspberry Pi 5.**
> Manages processes, orchestrates local LLMs, and serves a cross-platform Flutter client — rebuilt from the ground up.

---

## What is horAIzon?

horAIzon is a personal software ecosystem built around a single idea: **your own AI, on your own hardware, under your own control.** No cloud dependency. No subscription. No data leaving your network.

It lives on a **Raspberry Pi 5** connected via [Tailscale](https://tailscale.com/) mesh VPN, and is controlled from a **Flutter mobile/desktop client** over a custom binary protocol (HBP v2). A local Ollama instance provides all AI capabilities — code generation, diary analysis, resume tailoring, and an autonomous overnight coding agent.

---

## horAIzon 2.0 → 3.0: What Changed

### horAIzon 2.0 — What it was

The 2.0 system was a working but fragmented collection of separate Node.js, Go, Rust, and Python services. Each module ran independently with no unified supervisor:

| Module | Language | Role |
|---|---|---|
| `shua_governor` | Rust (Axum) | HTTP + SSE process supervisor |
| `shua_diary` | TypeScript (Node.js) | AI-assisted personal diary with SDUI renderer |
| `shua_resume` | Go | AI resume tailoring + Typst PDF compiler |
| `shua_code_visualizer` | Rust | Tree-sitter AST parser + code graph export |
| `client_flutter` | Dart/Flutter | SDUI-driven mobile UI (server-driven UI over WebSocket) |

**2.0 pain points:**
- The Flutter client was **SDUI-driven** (Server-Driven UI v4) — every screen was dynamically described by the server. This made development slow, debugging painful, and animations impossible.
- Modules communicated over untyped WebSocket JSON with no schema enforcement.
- No process lifecycle management — restarting one module could orphan others.
- No offline AI pipeline — all AI calls went to Gemini (cloud) with rate limiting hacks.
- Deployments were manual shell scripts with no systemd integration.

---

### horAIzon 3.0 — The Rewrite

3.0 is a complete architectural redesign. The core principles:

**1. Native Flutter, not SDUI**
The client is a proper native Flutter app with GoRouter, Riverpod state management, and hand-coded screens. See [ADR-001](./_architecture/decisions/ADR-001_native_over_sdui.md).

**2. Unified Governor over HBP v2**
All modules are launched, monitored, and killed by a single `shua_governor` Rust binary. They communicate over **HBP v2** (horAIzon Binary Protocol) — a length-prefixed binary WebSocket protocol with TOML-defined operations and auto-generated client stubs in Dart, Rust, Go, Python, and TypeScript.

**3. 100% Offline AI**
All LLM calls use local [Ollama](https://ollama.com/) models (`qwen2.5-coder:7b`, `qwen2.5:1.5b`, `nomic-embed-text`). No API keys required at runtime.

**4. Autonomous Overnight Agent**
An AI coding agent runs overnight using `aider` + Ollama. It reads approved task files (`_architecture/tasks/active/`), writes code, and commits. Planning is handled by a multi-agent n8n workflow with a Reviewer Agent that quality-gates generated tasks before they reach the queue.

**5. cgroups v2 Resource Control**
The governor uses Linux cgroups v2 to enforce per-module CPU/memory limits on the Pi5 — no module can starve others.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  MSI Laptop (Windows 11)          Tailscale VPN Mesh         │
│                                                             │
│  ┌─────────────────┐              ┌─────────────────────┐   │
│  │  client_flutter │─── HBP v2 ──►│   Raspberry Pi 5    │   │
│  │  (Dart/Flutter) │  WebSocket   │                     │   │
│  └─────────────────┘              │  ┌───────────────┐  │   │
│                                   │  │ shua_governor │  │   │
│  ┌─────────────────┐              │  │   (Rust)      │  │   │
│  │  n8n + Qdrant   │              │  └──────┬────────┘  │   │
│  │  (Docker)       │              │         │ spawns     │   │
│  │                 │              │  ┌──────▼────────┐  │   │
│  │  Planner Agent  │              │  │   Modules     │  │   │
│  │  Reviewer Agent │              │  │ shua_diary    │  │   │
│  └─────────────────┘              │  │ shua_resume   │  │   │
│                                   │  │ shua_gym      │  │   │
│  ┌─────────────────┐              │  │ shua_crypto   │  │   │
│  │ overnight_agent │              │  └──────┬────────┘  │   │
│  │ (aider + Ollama)│              │         │            │   │
│  └─────────────────┘              │  ┌──────▼────────┐  │   │
│                                   │  │    Ollama     │  │   │
│                                   │  │ qwen2.5-coder │  │   │
│                                   │  │ nomic-embed   │  │   │
│                                   │  └───────────────┘  │   │
│                                   └─────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
horaizon-3.0/
│
├── _architecture/                  # All planning, specs, and task tracking
│   ├── contracts/hbp/              # HBP v2 protocol spec (TOML + Markdown)
│   ├── decisions/                  # Architecture Decision Records (ADRs)
│   ├── diagrams/                   # System diagrams
│   ├── progress/                   # Weekly progress logs
│   ├── reference/                  # horAIzon 2.0 codebase exports (read-only context)
│   ├── specs/                      # Per-module technical specifications
│   │   ├── shua_governor/
│   │   ├── client_flutter/
│   │   ├── shua_diary/
│   │   ├── shua_resume/
│   │   ├── shua_gym/
│   │   └── shua_crypto/
│   └── tasks/                      # Task board
│       ├── active/                 # Approved tasks (ready to execute)
│       ├── proposed/               # AI-generated candidates (awaiting review)
│       ├── review_needed/          # Auto-rejected by Reviewer Agent
│       └── archived/               # Completed tasks
│
├── tools/                          # Developer tooling (not shipped to Pi5)
│   ├── overnight_planner.py        # Standalone AI task planner (Ollama)
│   ├── overnight_agent.py          # Autonomous coding agent (aider + Ollama)
│   ├── setup_overnight_agent.py    # One-time environment setup
│   ├── schedule_overnight.ps1      # Windows Task Scheduler setup
│   ├── gen_workflow.py             # n8n workflow generator
│   ├── repo_index.py               # Generates _architecture/repo_index.md
│   ├── n8n_overnight_workflow.json # n8n workflow export
│   ├── start_n8n.ps1               # Starts n8n Docker stack
│   ├── toggle_view.py              # TASK file view toggler
│   └── sync_contracts/             # HBP v2 contract code generator
│       └── generators/             # Dart / Rust / Go / Python / TS generators
│
│   [Planned — not yet scaffolded]
├── shua_governor/                  # Rust — Pi5 process supervisor + HBP server
├── client_flutter/                 # Dart/Flutter — cross-platform client
├── shua_diary/                     # TypeScript — AI personal diary backend
├── shua_resume/                    # Go — AI resume tailoring + Typst compiler
├── shua_portal/                    # C# ASP.NET Core — interview prep portal
├── shua_gym/                       # (Phase 3) Workout tracker
└── shua_crypto/                    # (Phase 3) Crypto portfolio tracker
```

---

## Modules

### `shua_governor` (Rust) — *In Progress*
The central hub on the Pi5. Responsible for:
- Launching, monitoring, and restarting all child modules
- Serving the **HBP v2 WebSocket** on port `7700`
- Routing HBP frames to the correct module handler
- Enforcing **cgroups v2** CPU/memory limits per module
- Exposing an **Ollama AI Dream Loop** — a background thread that does self-reflection when idle
- Config via `config.toml`, deployment via `systemd`

### `client_flutter` (Dart/Flutter) — *In Progress*
Native cross-platform app (Android, Windows, Linux):
- Connects to governor via HBP v2 WebSocket over Tailscale
- GoRouter navigation with named routes
- Riverpod state management
- Real-time dashboard showing module health / metrics
- Settings screen for connection config

### `shua_diary` (TypeScript) — *Phase 3*
AI-assisted personal diary. Key 3.0 changes from 2.0:
- Drops Gemini dependency — uses local Ollama exclusively
- Native UI via Flutter client (drops SDUI protocol entirely)
- Structured journaling with mood tracking and AI-generated summaries

### `shua_resume` (Go) — *Phase 3*
AI resume tailoring engine:
- Job-description analysis + keyword scoring (Jaccard similarity)
- Local Ollama-powered resume rewriting
- Typst compiler integration for PDF output
- WebSocket streaming for live compilation feedback

### `shua_code_visualizer` (Rust) — *Phase 2*
Tree-sitter based code analysis tool:
- Parses Rust, Go, TypeScript, Dart, Python
- Extracts AST declarations, cyclomatic complexity, side-effect tags
- Generates the `_architecture/reference/` exports used as 2.0 context

### `shua_portal` (C# / ASP.NET Core) — *Active*
Interview prep simulator:
- ASP.NET Core 9 Minimal APIs
- EF Core + SQLite for question/answer storage
- Local Ollama integration for AI grading
- Teaches DI, middleware, and EF Core patterns by building them

### `shua_gym` / `shua_crypto` — *Phase 3 (Planned)*
Workout tracker and crypto portfolio tracker. Specs in `_architecture/specs/`.

---

## HBP v2 — horAIzon Binary Protocol

All client <-> governor communication uses a custom binary protocol over WebSocket:

```
┌──────────┬────────────┬──────────┬──────────────────────────┐
│  op_id   │  msg_id    │ payload  │  payload bytes...        │
│  (u16)   │  (u32)     │ len (u32)│                          │
└──────────┴────────────┴──────────┴──────────────────────────┘
```

Operations are defined in TOML (`tools/sync_contracts/schema/hbp_operations.toml`) and compiled to client stubs in **Dart, Rust, Go, Python, and TypeScript** via `tools/sync_contracts/`.

---

## Overnight AI Agent

The autonomous coding agent runs locally using:
- **[aider](https://aider.chat/)** — AI pair programmer with git integration
- **Ollama** (`qwen2.5-coder:7b`) — local LLM, no internet required
- **n8n** (Docker) — visual workflow orchestration
- **Qdrant** (Docker) — local vector store for RAG

**Planning pipeline:**
1. `overnight_planner.py` (standalone) or **n8n Planner Agent** reads repo context
2. Drafts `TASK-XXX.md` files in `_architecture/tasks/proposed/`
3. **n8n Reviewer Agent** scores each task (1-10) and routes: `pass -> proposed/`, `fail -> review_needed/`
4. Joshua reviews and promotes approved tasks to `active/`
5. `overnight_agent.py` executes active tasks using aider on idle

**Schedule:** Planner runs at 22:00 Asia/Manila. Agent triggers after 15 minutes of system idle.

---

## Task Board

| # | Task | Status |
|---|---|---|
| TASK-001 | Pi5 SSH Setup + horAIzon 2.0 Cleanup | `[ ] Not started` |
| TASK-002 | VSCode Workspace Setup | `[ ] Not started` |
| TASK-003 | `shua_governor` Cargo Scaffold | `[ ] Not started` |
| TASK-004 | `shua_governor` HBP v2 Frame + WebSocket Broker | `[ ] Not started` |
| TASK-005 | `shua_governor` Process Registry + cgroups v2 | `[ ] Not started` |
| TASK-006 | `shua_governor` Ollama Lifecycle + AI Dream Loop | `[ ] Not started` |
| TASK-007 | `shua_governor` config.toml + systemd Deploy | `[ ] Not started` |
| TASK-008 | `client_flutter` Project Scaffold | `[ ] Not started` |
| TASK-009 | `client_flutter` HBP v2 Client | `[ ] Not started` |
| TASK-010 | `client_flutter` GoRouter + Splash + Theme | `[ ] Not started` |
| TASK-011 | `client_flutter` Dashboard + Governor Screens | `[ ] Not started` |
| TASK-012 | `client_flutter` Settings + Connection Banner | `[ ] Not started` |
| TASK-013 | Local AI Agent Infrastructure (n8n + RAG + Multi-Agent) | `[ ] Deferred` |
| TASK-014 | `shua_portal` C# ASP.NET Core Interview Prep Portal | `[ ] Not started` |

Full task files: [`_architecture/tasks/active/`](./_architecture/tasks/active/)

---

## Prerequisites

| Tool | Purpose | Required For |
|---|---|---|
| Rust + Cargo | Build `shua_governor` | TASK-003+ |
| Flutter SDK | Build `client_flutter` | TASK-008+ |
| Python 3.11+ | Dev tooling in `tools/` | Now |
| Ollama | Local LLM runtime | Agent + modules |
| Docker Desktop | n8n + Qdrant containers | TASK-013 |
| Tailscale | VPN mesh to Pi5 | TASK-001+ |
| .NET 9 SDK | `shua_portal` | TASK-014 |
| aider | Autonomous coding agent | `overnight_agent.py` |

---

## Getting Started

```powershell
# 1. Clone the repo
git clone <repo-url> c:\horaizon-3.0
cd c:\horaizon-3.0

# 2. Install Python tooling dependencies
pip install requests

# 3. Regenerate the repo index (gives AI agents full context)
python tools/repo_index.py

# 4. Regenerate HBP contract stubs after schema changes
python -m tools.sync_contracts

# 5. Set up the overnight agent (one-time)
python tools/setup_overnight_agent.py
```

---

## Architecture Decisions

| ADR | Decision |
|---|---|
| ADR-001 | Native Flutter UI over SDUI-4 — dropped server-driven rendering |

---

## License

Private repository — Joshua B. Ygot. All rights reserved.
