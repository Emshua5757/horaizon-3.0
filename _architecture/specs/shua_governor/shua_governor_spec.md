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
6. **Dream Loop Scheduler** — nightly cron-triggered background inference jobs & disaster recovery backups
7. **Log Aggregator** — collects structured logs from all modules and streams to client

---

## Hardware Topology (3-Node Active + Deferred Pi 2)

horAIzon 3.0 operates across a primary **3-Node Federated Compute Architecture** (with optional Pi 2 hardware expansion deferred for future setup):

```
Active Core Nodes:
  1. MSI Laptop (16GB RAM / GTX 1650 4GB VRAM) ──► Heavy AI Offload Engine (30-50 tok/s LLM inference)
  2. Raspberry Pi 5 (BCM2712 / 8GB RAM / M.2 NVMe) ──► Orchestrator & Brain Stem (shua_governor)
  3. Moto G84 5G (Snapdragon 695 / 12GB RAM)   ──► Mobile Edge Client UI (Flutter & local STT)

Deferred Node (Future Expansion):
  4. Raspberry Pi 2 B ──► Physical Out-of-Band Hardware Relay Watchdog (Optional Phase 5 setup)
```

```
                   ┌───────────────────────────────────┐
                   │        Tailscale Mesh VPN         │
                   │     (WireGuard — 100.x.y.z)       │
                   └─────────────────┬─────────────────┘
                                     │
        ┌────────────────────────────┴────────────────────────────┐
        ▼                                                         ▼
┌──────────────┐            ┌─────────────────┐          ┌─────────────────┐
│  MSI Laptop  │            │  Raspberry Pi 5 │          │    Moto G84     │
│ GTX 1650 4GB │◄──stream──►│  shua_governor  │◄──HBP───►│  Flutter Client │
│ [Heavy LLM]  │            │  [Orchestrator] │          │  [Mobile Edge]  │
└──────────────┘            └─────────────────┘          └─────────────────┘
```

---

## Raspberry Pi 2 Out-of-Band Physical Hardware Relay Watchdog (Deferred Optional Expansion)

> [!NOTE]
> **Deferred Hardware Node**: The Raspberry Pi 2 Watchdog integration is optional and deferred. Core system operation, HBP v2 broker, and systemd daemon auto-restarts run 100% autonomously on the Pi 5 without requiring the Pi 2.

To guarantee 100% uptime for the 24/7 Raspberry Pi 5 Orchestrator:
- **Heartbeat Monitoring**: The Pi 2 polls `GET http://horaizon-pi5:7700/hbp` every 30 seconds.
- **Stage 1 (Soft SSH Reset)**: After 3 consecutive HTTP failures (90s), Pi 2 attempts `ssh root@horaizon-pi5 "reboot"`.
- **Stage 2 (Hard Relayed Reset)**: If Pi 5 remains frozen for 120s, Pi 2 triggers **GPIO 17 (Pin 11)** HIGH for 5 seconds to energize a 5V mechanical relay on the Pi 5's USB-C power line.
- **NC Terminals**: Relay is wired via **Normally Closed (NC)** terminals so if Pi 2 loses power, the circuit remains closed and Pi 5 stays powered.

---

## System Architecture & Single Point of Failure (SPOF) Rationale

> [!NOTE]
> **Architectural Trade-Off: Intentional Single Point of Failure (SPOF)**:
> The Governor is intentionally designed as the sole persistent entry point. Binding port 7700 directly as the single WebSocket broker eliminates complex HA cluster overhead. Systemd daemonization (`Restart=always`, `RestartSec=3s`), Pi 2 Physical Relay Watchdog, and client-side exponential reconnect backoff (`HbpClient`) provide complete resilience for a single-user system.

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
            └── Nightly cron (02:00 & 03:00 Asia/Manila)
                    ├── 02:00: Summary, Compaction, UMAP Projection
                    └── 03:00: Live SQLite Snapshot & Encrypted Archive Sync (ADR-002)
```

---

## Technology Stack

| Concern | Crate | Usage |
| :--- | :--- | :--- |
| Async runtime | `tokio` (multi-thread scheduler) | Event loop & asynchronous tasks |
| WebSocket server | `tokio-tungstenite` | HBP v2 client connections |
| MessagePack | `rmp-serde` | Frame envelope & DTO serialization |
| Process management | `std::process` + `nix` crate | SIGSTOP/SIGCONT process signals |
| cgroups v2 | `cgroups-rs` or direct `/sys/fs/cgroup/` | Memory ceilings & Linux cgroup limits |
| HTTP client | `reqwest` | Ollama local REST API client & laptop offload |
| Scheduled jobs | `tokio-cron-scheduler` | Nightly 02:00/03:00 Dream Loop & Backup tasks |
| Structured logging | `tracing` + `tracing-subscriber` | Subsystem telemetry logging |

---

## Process Registry & Global System RAM Safeguard

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

### Global System RAM Ceiling Check (7,168 MB Ceiling)

Before issuing `SIGCONT` to wake a sleeping module, Governor evaluates total active RAM footprint (`active_module_ram + requested_module_ram_limit`):
1. If total active allocation exceeds **7,168 MB** (7GB ceiling, reserving 1GB for OS kernel & Tailscale):
2. Governor identifies the **Least Recently Used (LRU)** sleeping/idle module.
3. Governor issues `SIGSTOP` / cgroup freeze to the LRU module before resuming the requested module.

---

## Cross-Platform Dev Fallback Contract (`MockDevDriver`)

When running on non-Linux operating systems (Windows MSI laptop or macOS dev host):
- `cgroup_manager` activates `MockDevDriver` mode:
  - Process state transitions (`Running`, `Sleeping`, `Stopped`) are simulated in-memory.
  - Telemetry queries fall back to `sysinfo` crate for CPU/RAM measurements.
  - Process signals (`SIGSTOP`/`SIGCONT`) log structured `tracing::info!` messages without executing Linux-specific kernel calls.

---

## Dream Loop Interruption & Transaction Safety Guarantees

When a client connects mid-run during the nightly 02:00 AM Dream Loop / 03:00 AM Backup:

| Job | Description | Interruption Strategy |
| :--- | :--- | :--- |
| **Job 1: Diary Summary Generation** | LLM summary of yesterday's entries | **Stateless**: Safe to SIGSTOP/kill. Resumes cleanly from last unsummarized entry timestamp. |
| **Job 2: Memory Compaction** | FTS5 & identity matrix consolidation | **Atomic Transaction**: Executed inside SQLite `BEGIN IMMEDIATE... COMMIT`. Safe to interrupt; SQLite automatically rolls back uncommitted WAL state. |
| **Job 3: Code Topology Delta Scan** | Tree-sitter AST scan | **Checkpointing**: Saves checkpoint after each directory batch. Safe to defer. |
| **Job 4: UMAP Embedding Projection** | 2D/3D identity point layout | **State Preservation**: Preserves iteration matrix progress; resumes upon client disconnect. |
| **Job 5: Live Snapshot & Backup Sync** | SQLite `VACUUM INTO` + Zstd tar sync | **Atomic Snapshot**: SQLite `VACUUM INTO` creates independent file; encrypted archive synced to MSI laptop (ADR-002). |

---

## Structured Logging & Telemetry

All logs across `shua_governor`, microservices, AI inference, and Flutter clients are ingested, filtered, and persisted via the centralized logging subsystem defined in `_architecture/contracts/hbp/hbp_logging_spec.md`.

- **IPC Ingress**: UDS (`/tmp/horaizon_logs.sock`) & TCP Loopback (`127.0.0.1:5001`).
- **Client Ingress & Egress**: WebSocket HBP v2 `governor.log.emit`, `governor.logs.subscribe`, `governor.logs.query`, and `governor.log_event` frames.
- **SQLite LTM**: All logs stored in `activity.db` with indexed lookup and 7-day auto-purge.
- **Audit File**: Actionable high-severity events (`ERROR`, `FATAL`, `TAG_IMPORTANT`, `TAG_SECURITY`) appended to `important.log` (10MB rotation). Transient `WARN` logs are excluded from disk file noise.
- **Server-Side Filter**: `LogBroadcaster` evaluates client `LogFilter` (`min_level`, `modules`, `tag_mask`) in $\mathcal{O}(1)$ time before WebSocket broadcast.

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
│   │   └── cgroup_manager.rs   ← cgroups v2 memory limits & MockDevDriver
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
│   │       ├── memory_compaction.rs
│   │       └── backup_snapshot.rs
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
- [ ] Global System RAM Check auto-freezes LRU module when total RSS allocation exceeds 7,168 MB
- [ ] Live logs stream to connected clients via EVENT frames
- [ ] Dream Loop scheduler wakes at 02:00 and 03:00 for maintenance and atomic backup snapshot (ADR-002)
- [ ] Config reloads from `/etc/horaizon/governor/config.toml` without restart
- [ ] `cargo check` and `cargo test` succeed on Windows dev host with 0 warnings

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — Wire protocol spec
- `_architecture/contracts/mcp/mcp_master_spec.md` — Master MCP spec
- `_architecture/decisions/ADR-001_native_over_sdui.md` — Architecture rationale
- `_architecture/decisions/ADR-002_backup_policy.md` — Backup & Disaster Recovery policy
