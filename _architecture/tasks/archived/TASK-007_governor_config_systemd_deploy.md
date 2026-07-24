# TASK-007 — `shua_governor` config.toml + systemd Deploy to Pi5

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Completed Date** | 2026-07-24 |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust + bash |
| **Target** | `shua_governor/src/config.rs`, `config.toml`, `deploy/shua-governor.service` |
| **Blocks** | Nothing (this completes 100% of Governor backend!) |
| **Prerequisites** | TASK-001–006 complete |
| **Branch** | `task/TASK-007-governor-config` (merged `--no-ff` into `main`) |

---

## Context & Overview

Implemented the final component for `shua_governor`:
1. **Multi-Path Config Loader (`src/config.rs`)**: Searches `--config <path>`, `/etc/horaizon/governor/config.toml` (Pi5 production), `./config.toml` (Windows dev), and `AppConfig::default()` in-memory fallback to prevent panics.
2. **Settings RPC Operations (`governor.config.get` & `governor.config.update`)**: Allows Flutter Settings screen to fetch and persist settings dynamically (`offload_device_url`, `ollama_ram_cap_mb`, `dream_loop_enabled`, `log_retention_days`).
3. **Dynamic Boot Registration**: Reads `[[modules.entry]]` and `[[ollama.models]]` from `config.toml` on startup and populates `ProcessManager` and `ModelRegistry` dynamically without requiring Rust re-compilation.
4. **Hardened Systemd Unit (`deploy/shua-governor.service`)**: `Restart=always`, `RestartSec=3s`, `LimitNOFILE=65536`.
5. **0 compiler warnings, 9/9 unit tests passing**.
