# TASK-006 — `shua_governor` Ollama Lifecycle + AI Router + Dream Loop

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Completed Date** | 2026-07-24 |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/ollama/`, `src/ai_router/`, `src/dream_loop/` |
| **Blocks** | TASK-007 |
| **Prerequisites** | TASK-005 complete |
| **Branch** | `task/TASK-006-ollama-ai-dreamloop` (merged `--no-ff` into `main`) |

---

## Context & Overview

Implemented the AI execution infrastructure for `shua_governor`:
1. **Ollama Lifecycle Manager**: One-model-at-a-time rule, 4GB RAM cap enforcement, load & eviction (`keep_alive: 0`).
2. **AI Intent Router**: Keyword heuristic classifier (`FactualPrecision`, `ReflectiveDialogue`, `CodeAst`, `CopilotCommand`) with support for local Pi5 vs laptop offload node URLs.
3. **Dream Loop Scheduler**: Nightly cron job at 02:00 Asia/Manila (18:00 UTC) executing log auto-pruning and maintenance checks with Phase 3 stub placeholders.

### Highlights:
- `OllamaClient`: Configurable HTTP client supporting local Pi 5 (`127.0.0.1:11434`) and remote laptop offload nodes.
- `IntentClassifier`: Sub-microsecond prompt intent classification.
- `DreamLoopScheduler`: `tokio-cron-scheduler` job scheduled for 02:00 AM Manila time.
- Dispatcher handlers for `governor.ollama.load`, `governor.ollama.evict`, and `governor.ai.route`.
- **0 compiler warnings, 9/9 unit tests passing**.
