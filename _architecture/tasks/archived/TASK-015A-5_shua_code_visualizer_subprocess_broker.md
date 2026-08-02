# TASK-015A-5 — `shua_code_visualizer` Subprocess Parent Link & HBP IPC Broker

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/src/broker/`, `shua_code_visualizer/src/main.rs` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | TASK-015A-1, TASK-015A-2, TASK-015A-3, TASK-015A-4 |

---

## Key Subtasks

### 1. Standalone vs Governor Spawn Auto-Detection (`src/broker/parent_link.rs`)
- [x] 1.1 Check environment for `SHUA_GOVERNOR_PID` and `SHUA_GOVERNOR_IPC_PORT`.
- [x] 1.2 If `SHUA_GOVERNOR_PID` is missing: run in **Standalone Mode** (zero network port scanning, zero governor connection attempts).
- [x] 1.3 If `SHUA_GOVERNOR_PID` is present: run in **Managed Subprocess Mode** and monitor parent PID for lifetime termination.

### 2. Parent-Death Lifetime Link
- [x] 2.1 Background thread/task polling parent governor PID status.
- [x] 2.2 If parent `shua_governor` process exits or crashes, `shua_code_visualizer` automatically self-terminates (preventing zombie processes).

### 3. HBP IPC Broker Connection (`src/broker/ipc_client.rs`)
- [x] 3.1 Connect to `SHUA_GOVERNOR_IPC_PORT` over WebSocket / TCP only when running in Managed Subprocess Mode.
- [x] 3.2 Dispatch incoming `mcp.tool_call` requests to `McpHandler`.
- [x] 3.3 Stream live `TopologyDeltaEvent` patches on the `changed` HBP event stream.

---

## Acceptance Criteria
- [x] Manual execution without `SHUA_GOVERNOR_PID` runs 100% Standalone with ZERO network port scanning.
- [x] Execution with `SHUA_GOVERNOR_PID` connects to parent governor and self-terminates if parent exits.
- [x] `cargo check` and `cargo test` pass with zero warnings (14/14 unit tests passing).
