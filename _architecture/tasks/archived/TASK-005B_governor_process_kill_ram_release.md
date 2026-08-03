# TASK-005B — `shua_governor` Process Kill, RAM Release & Dashboard Control Alignment

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Completed Date** | 2026-08-03 |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Rust / Dart (Flutter) |
| **Target** | `shua_governor/src/registry/`, `shua_governor/src/mcp/`, `client_flutter/lib/features/` |
| **Prerequisites** | TASK-005, TASK-011 complete |
| **Branch** | `task/TASK-005B-process-kill-ram-release` (merged `--no-ff` into `main`) |

---

## Context & Overview

Extended the `shua_governor` process supervisor to support `SIGTERM`/`SIGKILL` process termination (`process.stop` / `process.kill`) and `governor_stop_module` MCP tool, dropping process RAM footprint to 0 MB. Updated Flutter `MicroserviceCard` with 3-way lifecycle controls (Wake, Freeze, Stop/Kill) and enforced frozen backend access guards in `CodeTopologyScreen`.

## Deliverables

1. **`ProcessManager` Terminate Method (`process_manager.rs`)**:
   - Implemented `stop(&self, name: &str) -> Result<()>` sending `SIGTERM`/`SIGKILL`.
   - Detached PID, updated state to `ModuleState::Stopped`, set `ram_mb = Some(0.0)`.

2. **MCP Tool Registration (`mcp/executor.rs` & `mcp_master_spec.md`)**:
   - Registered `governor_stop_module` MCP tool allowing AI agent to terminate microservices to free RAM.
   - Updated canonical specification in `_architecture/contracts/mcp/mcp_master_spec.md`.

3. **HBP Broker Dispatcher (`dispatcher.rs`)**:
   - Added RPC handlers for `module.stop`, `governor.module.stop`, `process.stop`, `process.kill`.

4. **Flutter Dashboard Controls & Access Guard**:
   - Added `stopModule()` in `GovernorStatusNotifier`.
   - Updated `MicroserviceCard` with 3-way action buttons (Wake, Freeze, Stop & Free RAM) and accurate status labels.
   - Enforced backend access guard banner in `CodeTopologyScreen` offering one-click auto-wake when backend is frozen.

---

## Complexity Analysis

- **Time Complexity**: $O(1)$ signal dispatch (`SIGKILL`/`SIGTERM`) and HBP v2 payload framing.
- **Space Complexity**: $O(1)$ stack/heap allocation; terminating a microservice releases up to 245+ MB RAM per process on Pi 5 ARM.
