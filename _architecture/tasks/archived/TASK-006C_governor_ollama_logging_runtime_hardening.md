# TASK-006C — Governor Ollama Lifecycle, Telemetry Logging & Runtime Hardening

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 1 Follow-up |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/broker/dispatcher.rs`, `shua_governor/src/ai_router/`, `shua_governor/src/logging/`, `shua_governor/src/main.rs` |
| **Blocks** | TASK-013 (Local AI Coding Agent Infrastructure) |
| **Prerequisites** | TASK-006 (Governor Ollama AI Router), TASK-006B (Governor MCP Aggregator) |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/` |

---

## Architectural Context & Hardware Optimization (Raspberry Pi 5)

> [!IMPORTANT]
> **Raspberry Pi 5 Resource & Thread Pool Isolation**:
> - **Hardware**: Raspberry Pi 5 (8GB RAM, 4-core ARM Cortex-A76).
> - **Concurrency & Isolation**: To prevent heavy LLM inference operations (local Ollama or offload HTTP calls) from starving critical system components (HBP broker, WebSocket PING/PONG heartbeats, log flushes, dream loop), `shua_governor` isolates Tokio runtimes:
>   - **Core Runtime**: 2 worker threads dedicated to high-priority system telemetry, RPC broker, log flushes, and process registry.
>   - **AI Runtime**: 2 worker threads dedicated exclusively to LLM requests and MCP agent loops.
> - **Time & Space Complexity**:
>   - **Timestamp Normalization & DB Operations**: $O(1)$ timestamp conversion; SQLite prunes execute in $O(\log N)$ with index scans on `ts`.
>   - **Agent Loop Execution**: Bounded at $O(K)$ turns where $K \le 5$; total memory overhead $O(M)$ bounded by prompt context length ($M \le 8192$ tokens).
>   - **RAM Allocation**: RAM capped strictly via `OllamaLifecycle` ($RAM \le 4096\text{ MB}$), enforced with single-model mutual exclusion ($O(1)$ lock).

---

## Problem Breakdown & Technical Requirements

### P0-1: `ai.route` Ollama Lifecycle Bypass & Model Thrash Fix
- **Root Cause**: `dispatcher.rs` calls `McpAgentLoop::run` directly without calling `OllamaLifecycle::load()`. In addition, `agent_loop.rs` passes `keep_alive = 0`, causing immediate model eviction after each turn.
- **Fix**:
  - In `dispatcher.rs`, invoke `self.ollama.load(&budget.model).await?` before `McpAgentLoop::run` when `budget.offload_url` is `None`. Return `ERR_MODEL_TOO_LARGE` / `ERR_OLLAMA_LOAD` error responses on failure.
  - In `agent_loop.rs`, pass `-1` for `keep_alive` in `client.chat_with_tools(...)` (delegating eviction to `OllamaLifecycle`).
  - Audit direct `OllamaClient` usage across `dispatcher.rs` to ensure `self.ollama` is the unified lifecycle entry point.
  - Add documentation on `OllamaLifecycle::load()` highlighting it as the sole entry point for local inference.

### P0-2: Logging Timestamp Unit Mismatch (Seconds vs Milliseconds)
- **Root Cause**: `logging/bridge.rs` stamps `ts` in seconds, while client logs and auto-prune logic in `logging/flush.rs` operate in milliseconds. All bridge-sourced log entries look like 55-year-old timestamps and get immediately pruned.
- **Fix**:
  - Standardize `ts` on milliseconds across `logging/bridge.rs`, `logging/listener.rs`, and all `LogEntry` instantiations (`.as_millis() as u64`).
  - Execute DB migration logic on boot to scale existing second-based timestamps ($ts < 10,000,000,000$) to milliseconds ($ts \times 1000$).
  - Add unit test asserting `LogEntry` timestamp parity between tracing bridge and direct instantiations.

### P0-3: Telemetry Log Channel Overflow & Drop Counter
- **Root Cause**: `try_send` silently discards log entries when the bounded log channel (4096) overflows under high load or crash bursts.
- **Fix**:
  - Add an `AtomicU64` drop counter incremented on every channel `try_send` failure.
  - Periodically emit a `tracing::warn!` telemetry alert when dropped logs $> 0$ and reset the counter.

### P0-4: Thread-Pool Split (Core vs AI Runtime) & Heartbeat Pipeline
- **Root Cause**: A single multi-threaded Tokio runtime shares worker threads across HBP broker heartbeats, log flushes, and slow Ollama/offload HTTP calls. Stuck HTTP calls stall broker PING/PONG.
- **Fix**:
  - Split runtime into **Core Runtime** (`worker_threads = 2` for broker, heartbeat, logs, registry) and **AI Runtime** (`worker_threads = 2` for Ollama/MCP inference).
  - Dispatch `McpAgentLoop::run` onto the AI Runtime via `oneshot` channel from `dispatcher.rs`.
  - Wrap blocking SQLite calls in `governor.logs.query` inside `tokio::task::spawn_blocking`.
  - Add a dedicated periodic background heartbeat task emitting telemetry frames at configured intervals.

### P1: Hardened N-Turn MCP Agent Loop (`MAX_AGENT_ITERATIONS = 5`)
- **Fix**:
  - Define `const MAX_AGENT_ITERATIONS: usize = 5;` in `agent_loop.rs`.
  - Wrap LLM inference calls with `tokio::time::timeout` for per-iteration timeouts.
  - Add iteration-level telemetry logging (turn index, tool request status, exit reason).
  - Protect local inference concurrency using a `tokio::sync::Semaphore` (1 permit).
  - Add unit/integration tests verifying exact 5-iteration termination and non-empty final response handling.

### P2: Performance & Diagnostics Backlog
- Cache `McpAggregator::get_system_tools()` schemas.
- Cache `OllamaClient` instances per base URL.
- Fix intent classifier regex / word-boundary matching to prevent substring false-positives.
- Log intent classification rules and matching decisions.

---

## Acceptance Criteria

- [x] Two consecutive `ai.route` requests for the same model do not re-trigger Ollama model loads.
- [x] Direct tracer logs survive hourly DB prune boundaries and remain queryable via `governor.logs.query`.
- [x] Flooded log channels trigger telemetry warnings detailing total dropped entries.
- [x] Stalled offload HTTP targets do not block broker HBP heartbeats or `governor.logs.query` responses.
- [x] Agent loops hitting 5 iterations terminate gracefully with logged exit status and single-permit semaphore protection.
- [x] Zero compiler warnings (`cargo check`, `cargo build`).
