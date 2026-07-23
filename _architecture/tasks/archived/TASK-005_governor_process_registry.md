# TASK-005 — `shua_governor` Process Registry + cgroups v2

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Completed Date** | 2026-07-24 |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/registry/` |
| **Blocks** | TASK-007 |
| **Prerequisites** | TASK-004 complete (broker compiles) |
| **Branch** | `task/TASK-005-process-registry` (merged `--no-ff` into `main`) |

---

## Context & Overview

Implemented the process registry that tracks all `shua` microservice processes, cgroups v2 manager for RAM limits (`memory.max`), SIGSTOP/SIGCONT power state transitions, and live telemetry fields (`cpu_percent`, `ram_mb`, `ram_limit_mb`, `uptime_s`, `health_ok`, `restart_count`, `last_error`).

### Highlights:
1. **`ModuleEntry` & Telemetry Schema**: Extended schema in `hbp_governor.toml` with 10 explicit indexed fields (`cpu_percent`, `ram_mb`, `ram_limit_mb`, `uptime_s`, `health_ok`, `restart_count`, `last_error`).
2. **`CgroupManager`**: Manages `/sys/fs/cgroup/horaizon/<module>`, `memory.max`, and `cgroup.procs` with cross-platform dev fallback stubs.
3. **`ProcessManager`**: Async supervisor controlling startup, `SIGSTOP` sleep, `SIGCONT` wake, `/proc` process probing, and live RAM snapshot calculation.
4. **Dispatcher & Main Integration**: Wired real handlers for `governor.status`, `governor.module.wake`, and `governor.module.sleep`.
5. **Zero Warnings & 8/8 Unit Tests Passing**.
