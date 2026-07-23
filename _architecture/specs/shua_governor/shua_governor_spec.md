# shua_governor — Specification

| Field | Value |
| :--- | :--- |
| **Language** | Rust |
| **Phase** | Phase 1 |
| **Runs On** | RPI5 (horaizon-pi5, 100.67.11.0) |
| **Power State** | Always-On (never SIGSTOP'd) |
| **Port** | 7700 (HBP v2 WebSocket broker) |
| **Crate Type** | Binary (async, tokio runtime) |

---

## Role in horAIzon 3.0

`shua_governor` is the **spine of the entire system**. It is the first process that starts on Pi5 boot and the last to shut down. Every other shua module is a child or sibling process that the Governor supervises.

Responsibilities:
1. **HBP v2 WebSocket Broker** — accepts client connections, routes frames to module processes
2. **Process Registry** — tracks which modules are running, sleeping, or stopped
3. **cgroups v2 Power States** — SIGSTOP/SIGCONT for module suspend/resume cycles
4. **Ollama Lifecycle Manager** — model load/evict, RAM budget enforcement
5. **AI Intent Router** — routes prompts to the right model based on intent classification
6. **Dream Loop Scheduler** — nightly cron-triggered background inference jobs
7. **Log Aggregator** — collects structured logs from all modules and streams to client

---

## System Architecture on Pi5

```
Pi5 Boot
    │
    ▼
shua_governor (Always-On, port 7700)
    │
    ├── HBP v2 Broker
    │       └── WebSocket listener (Tailscale TLS + LAN ws://)
    │
    ├── Process Registry
    │       ├── shua_resume      (Go binary)       ← SIGSTOP/SIGCONT
    │       ├── shua_diary       (Node process)    ← SIGSTOP/SIGCONT
    │       ├── shua_code_viz    (Rust binary)     ← SIGSTOP/SIGCONT
    │       ├── shua_gym         (Python process)  ← SIGSTOP/SIGCONT
    │       └── shua_crypto      (Python process)  ← SIGSTOP/SIGCONT
    │
    ├── Ollama Lifecycle
    │       └── /usr/bin/ollama  (managed process)
    │               └── keep_alive: 0 eviction on idle
    │
    └── Dream Loop Scheduler
            └── Nightly cron (02:00 Asia/Manila)
                    └── Inference jobs → Morning review queue
```

---

## Technology Stack

| Concern | Crate |
| :--- | :--- |
| Async runtime | `tokio` (multi-thread scheduler) |
| WebSocket server | `tokio-tungstenite` |
| MessagePack encode/decode | `rmp-serde` |
| Process management | `std::process` + `nix` crate (SIGSTOP/SIGCONT) |
| cgroups v2 | `cgroups-rs` crate or direct `/sys/fs/cgroup/` file writes |
| HTTP client (Ollama API) | `reqwest` (async) |
| Scheduled jobs (Dream Loop) | `tokio-cron-scheduler` |
| Structured logging | `tracing` + `tracing-subscriber` |
| Config file | `toml` + `serde` |
| Serialization | `serde` + `serde_json` (internal) + `rmp-serde` (HBP wire) |

---

## Process Registry

Each registered module has a `ModuleEntry`:

```rust
struct ModuleEntry {
    name:         String,        // e.g. "shua.resume"
    binary:       PathBuf,       // e.g. /opt/horaizon/shua_resume/shua_resume
    state:        ModuleState,   // Running | Sleeping | Stopped | Unknown
    pid:          Option<u32>,
    auto_start:   bool,          // Start on Governor boot?
    cgroup_path:  PathBuf,       // /sys/fs/cgroup/horaizon/shua_resume
    ram_limit_mb: Option<u32>,   // cgroup memory.max
}

enum ModuleState {
    Running,   // Process exists, not stopped
    Sleeping,  // SIGSTOP sent — frozen, no CPU
    Stopped,   // Process not running at all
    Unknown,   // PID not found or unresponsive
}
```

### Wake/Sleep Cycle

```rust
// Wake a sleeping module
fn wake_module(pid: u32) {
    nix::sys::signal::kill(pid, SIGCONT)
}

// Sleep a module
fn sleep_module(pid: u32) {
    nix::sys::signal::kill(pid, SIGSTOP)
}
```

Modules with `auto_start: true` are started by the Governor at boot. All others start on first client request (lazy activation).

---

## Ollama Lifecycle Manager

Ollama runs as a managed subprocess. The Governor enforces a strict **one-model-at-a-time** rule with RAM budget enforcement.

### Model Registry (config.toml)

```toml
[ollama]
binary = "/usr/bin/ollama"
host   = "127.0.0.1:11434"

[[ollama.models]]
name       = "qwen2.5:1.5b"
ram_mb     = 980
role       = "primary_dialogue"
keep_alive = 0              # evict immediately after inference

[[ollama.models]]
name       = "llama3.2:3b"
ram_mb     = 2000
role       = "text_generator"
keep_alive = 0

[[ollama.models]]
name       = "nomic-embed-text"
ram_mb     = 270
role       = "embeddings"
keep_alive = 0
```

### Load/Evict Flow

```
Client: governor.ollama.load { model: "qwen2.5:1.5b" }
    │
    ▼
Governor checks: is another model loaded?
    │
    ├── Yes → POST /api/chat { keep_alive: 0 } → waits for eviction
    │
    └── No → continue
    │
    ▼
POST /api/pull (if not cached) or
POST /api/chat { keep_alive: -1, stream: false } → loads weights
    │
    ▼
Response: governor.ollama.load SUCCESS { loaded_model, ram_mb }
```

### RAM Budget Rule

The Pi5 has 8GB RAM. Hard limit for all Ollama models: **4GB** (leaving 4GB for modules + OS).
If a requested model exceeds 4GB RAM, Governor returns `ERR_MODEL_TOO_LARGE`.

---

## AI Intent Router

The Governor classifies incoming prompts and routes them to the appropriate model and context partition, implementing the DPB-HG (Dynamic Prompt Budgeting + Hallucination Guard) concept from the 1.0 vision.

```
client: governor.ai.route { prompt: "...", context_hint: "diary" }
    │
    ▼
IntentClassifier (fast Rust heuristic, no LLM required)
    │
    ├── FACTUAL_PRECISION    → qwen2.5:1.5b, temp=0.0, DB context 60%
    ├── REFLECTIVE_DIALOGUE  → qwen2.5:1.5b, temp=0.7, history 60%
    ├── CODE_AST             → llama3.2:3b,  temp=0.2, AST context 60%
    └── COPILOT_COMMAND      → qwen2.5:1.5b, temp=0.1, schema 40%
    │
    ▼
Load model if not loaded (via Ollama Lifecycle Manager)
    │
    ▼
Stream response back to client via EVENT frames
```

Intent classification uses keyword heuristics (fast) in Phase 1. A quantized DistilBERT gate is planned for Phase 3+.

---

## Dream Loop Scheduler

Runs nightly at 02:00 (Asia/Manila). The Pi5 is always-on; the Dream Loop uses idle time for background inference.

```
02:00 Cron fires
    │
    ▼
Check: are any client WebSockets connected?
    │
    ├── Yes → defer by 30 min and retry
    │
    └── No → proceed
    │
    ▼
Execute Dream Loop jobs (in order):
    1. UMAP embedding projection (nomic-embed-text)
    2. Daily diary summary generation (qwen2.5:1.5b)
    3. Memory compaction (merge near-duplicate memories)
    4. Code topology delta scan (shua_code_visualizer)
    │
    ▼
Store results in Dream Loop queue (SQLite)
    │
    ▼
Evict all Ollama models (keep_alive: 0)
    │
    ▼
Morning: client connects → Governor sends EVENT: dream_loop.results_ready
```

If a client connects mid-Dream-Loop:
1. SIGSTOP the UMAP process (not killed — progress preserved)
2. Evict Ollama model
3. Serve client normally
4. On client disconnect → SIGCONT the UMAP process

---

## HBP v2 Broker Implementation

The Governor is the **single WebSocket entry point** for all clients. It routes frames internally to module processes (not via network — via Rust channels or Unix sockets for localhost modules).

```
Client WebSocket frame arrives
    │
    ▼
Governor HBP Dispatcher
    │
    ├── mod == "shua.governor" → handle locally
    │
    ├── mod == "shua.resume"   → forward to shua_resume channel
    │         (if sleeping: auto-wake first, then forward)
    │
    ├── mod == "shua.diary"    → forward to shua_diary channel
    │
    └── mod unknown            → return ERR_UNKNOWN_MODULE
```

Module processes communicate with the Governor via **internal IPC** (tokio channels), not external network sockets. Only the Governor binds to port 7700. This means:

- No port conflicts between modules
- Governor can intercept, log, and rate-limit all traffic
- Module auth is implicit (the Governor's process boundary is the trust boundary)

---

## Config File (`config.toml`)

Lives at `/etc/horaizon/governor/config.toml` on Pi5.

```toml
[governor]
port       = 7700
log_level  = "info"
timezone   = "Asia/Manila"

[dream_loop]
enabled    = true
cron       = "0 2 * * *"    # 02:00 every night

[modules]
# Each module registered here
[[modules.entry]]
name       = "shua.resume"
binary     = "/opt/horaizon/shua_resume/shua_resume"
auto_start = false
ram_limit_mb = 256

[[modules.entry]]
name       = "shua.diary"
binary     = "/opt/horaizon/shua_diary/start.sh"
auto_start = false
ram_limit_mb = 512

[[modules.entry]]
name       = "shua.code_visualizer"
binary     = "/opt/horaizon/shua_code_visualizer/shua_code_visualizer"
auto_start = false
ram_limit_mb = 512
```

---

## Structured Logging

All logs emit as structured JSON via `tracing`:

```json
{
  "timestamp": "2026-07-21T11:00:00.000Z",
  "level": "INFO",
  "module": "shua.governor",
  "subsystem": "ollama_lifecycle",
  "message": "Model loaded",
  "fields": {
    "model": "qwen2.5:1.5b",
    "ram_mb": 980,
    "duration_ms": 1240
  }
}
```

Logs are streamed to connected clients via `governor.logs` EVENT frames in real time.

---

## Folder Structure

```
shua_governor/
├── src/
│   ├── main.rs
│   ├── config.rs               ← TOML config loader
│   ├── broker/
│   │   ├── mod.rs
│   │   ├── server.rs           ← tokio-tungstenite WebSocket listener
│   │   ├── dispatcher.rs       ← Frame routing logic
│   │   └── frame.rs            ← HBP v2 encode/decode
│   ├── registry/
│   │   ├── mod.rs
│   │   ├── module_entry.rs     ← ModuleEntry struct + ModuleState enum
│   │   ├── process_manager.rs  ← spawn, SIGSTOP, SIGCONT, health check
│   │   └── cgroup_manager.rs   ← cgroups v2 memory limits
│   ├── ollama/
│   │   ├── mod.rs
│   │   ├── client.rs           ← reqwest HTTP to Ollama API
│   │   ├── lifecycle.rs        ← load/evict orchestration
│   │   └── model_registry.rs   ← registered models from config
│   ├── ai_router/
│   │   ├── mod.rs
│   │   ├── intent_classifier.rs← heuristic classifier (Phase 1)
│   │   └── prompt_budget.rs    ← context window partitioning
│   ├── dream_loop/
│   │   ├── mod.rs
│   │   ├── scheduler.rs        ← tokio-cron-scheduler
│   │   └── jobs/
│   │       ├── umap_projection.rs
│   │       ├── diary_summary.rs
│   │       └── memory_compaction.rs
│   └── logger/
│       ├── mod.rs
│       └── log_broadcaster.rs  ← streams logs to HBP clients
│
├── Cargo.toml
└── README.md
```

---

## Phase 1 Acceptance Criteria

- [ ] `shua_governor` starts on Pi5 boot (systemd service unit)
- [ ] WebSocket server accepts connections from MSI laptop via Tailscale (`100.90.83.12` → `100.67.11.0:7700`)
- [ ] WebSocket server accepts connections from Moto G84 via Tailscale (`100.111.230.72` → `100.67.11.0:7700`)
- [ ] `governor.status` returns correct module states
- [ ] `governor.ping` returns `PONG` within 50ms
- [ ] `governor.ollama.load` successfully loads `qwen2.5:1.5b` on Pi5
- [ ] `governor.ollama.evict` successfully evicts a loaded model
- [ ] `governor.module.wake` SIGCONT's a SIGSTOP'd process
- [ ] `governor.module.sleep` SIGSTOP's a running process
- [ ] Live logs stream to connected clients via EVENT frames
- [ ] Dream Loop scheduler wakes at 02:00 and generates a diary summary (integration test)
- [ ] Config reloads from `/etc/horaizon/governor/config.toml` without restart

---

## Pre-Deployment Checklist (Pi5)

- [ ] SSH configured (public key from MSI copied to Pi5)
- [ ] Old horAIzon 2.0 processes stopped and binaries removed from Pi5
- [ ] `/etc/horaizon/governor/` directory created with correct permissions
- [ ] `systemd` service unit written (`/etc/systemd/system/shua-governor.service`)
- [ ] Ollama installed and tested (`ollama pull qwen2.5:1.5b`)
- [ ] Port 7700 not blocked by `ufw` (or rule added)
- [ ] cgroups v2 confirmed active (`cat /sys/fs/cgroup/cgroup.controllers`)

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire protocol spec
- `_architecture/decisions/ADR-001_native_over_sdui.md` — Architecture rationale
- `_architecture/reference/shua_governor.md` — 2.0 Governor topology (historical)
- horAIzon 1.0 vision: Dream Loop, cgroups power states, TinyML gate
