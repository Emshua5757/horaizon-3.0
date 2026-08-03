# TASK-016D — Universal Submodule MCP Tool Wiring, Scope Memory & Governor Hardening

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 3 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/`, `shua_code_visualizer/src/broker/` |
| **Prerequisites** | TASK-016C complete (CopilotChatDrawer integrated), TASK-015B complete |
| **Branch** | `task/TASK-016D-governor-mcp-wiring` |

---

## Context & Overview

The JOSH Copilot Chat UI (TASK-016C) is fully wired to `shua_governor`'s `ai.route` endpoint and
the agent loop is functional for governor-scoped tools. This task resolves three structural
correctness gaps, adds a universal submodule registration system, hardens the governor for
production, and lays the memory infrastructure for scope-aware JOSH conversations.

### Correctness Gaps Being Fixed

1. **Scope filtering is bypassed.** `agent_loop.rs` calls `aggregator.get_system_tools()` directly
   and never runs `ScopeFilter::filter_tools`. The `context_hint: "code"` from Flutter only
   affects system prompt wording — the model always sees only the 5 governor tools regardless.

2. **Submodule tools are unreachable.** `McpAggregator::register_submodule_manifest` and
   `get_all_submodule_tools` are `#[allow(dead_code)]` stubs. The governor has no handler for
   the `governor.mcp.register` op that `shua_code_visualizer`'s `IpcClient` already sends
   on connect. The 8 `code_*` tools are completely invisible to JOSH.

3. **No governor-side IPC requester exists.** `McpExecutor` has no mechanism to forward a tool
   call over IPC to a running submodule and await the JSON result.

### Hardening Problems Also Fixed

4. **Process orphan leak.** `ProcessManager::start` calls `std::mem::forget(child)` — the
   governor has no watchdog. Crashed modules are never detected or restarted. `restart_count`
   in `ModuleEntry` is a dead field that is never incremented.

5. **`ModuleState::Running` is ambiguous.** A module can be `Running` (process alive) but have
   no IPC connection and zero registered tools. The Flutter UI and JOSH both make decisions
   based on `state` — they need to distinguish "process up" from "MCP-ready".

6. **Zero IPC authentication.** Any process on the machine can connect to port 7701 and claim
   to be `"shua.code_visualizer"`, overwriting its registered tool list. The connecting
   process PID must match the PID the governor spawned.

### New Capabilities Added

7. **Scope-scoped persistent memory stub.** `CopilotChatDrawer` is a shared widget across
   screens. Each screen passes a different `contextHint` (`"code"`, `"diary"`, `"governor"`).
   JOSH needs persistent, scope-isolated memory so facts learned in the Code Visualizer
   session do not contaminate the Diary session. The stub provides the SQLite schema,
   the load path, and the system prompt injection — memory formation is deferred to a
   future task.

8. **`governor.scopes` discovery op.** Flutter currently hardcodes `contextHint` per screen.
   The governor should expose which scopes are live (IPC-connected) so the UI can eventually
   render a dynamic scope selector on `CopilotChatDrawer`.

### Design Principle: Zero Governor Changes for New Modules

Once TASK-016D is complete, adding `shua.diary` or any future module requires:
1. Declare it in `config.toml` `[[modules.entry]]` (already required for process lifecycle).
2. Implement `IpcClient` + `governor.mcp.register` in the new module — same pattern as
   `shua_code_visualizer`, different `module_id` and `tools` array.
3. That is all. The governor never needs to be recompiled or modified.

---

## Architecture: `ProcessManager` as the Single Source of Truth

```
config.toml [[modules.entry]]
    name = "shua.code_visualizer"   ← single declaration point for everything
    binary = "...", auto_start, ram_limit_mb

ProcessManager (Arc<RwLock<HashMap<String, ModuleEntry>>>)
    ModuleEntry {
        // --- Existing fields (unchanged) ---
        name, binary, state, pid, cgroup_path, ram_limit_mb,
        ram_mb, cpu_percent, uptime_s, health_ok, restart_count, last_error

        // --- NEW: process lifecycle ---
        child_handle: Option<tokio::process::Child>  ← enables watchdog

        // --- NEW: IPC runtime state (None until module connects) ---
        ipc_tx:       Option<mpsc::UnboundedSender<String>>
        tools:        Vec<McpToolSchema>
        module_scope: Option<String>       ← e.g. "code", declared at registration
        manifest_version: Option<String>   ← semver of submodule's IPC manifest
        pending_calls: PendingCallMap      ← oneshot map for in-flight tool calls
    }

IpcServer (port 7701, JSON WebSocket, runs alongside HBP binary broker on 7700)
    on connect:    extract peer PID via SO_PEERCRED, match against entry.pid
    on register:   set ipc_tx + tools + module_scope; state → IpcConnected
    on tool_reply: resolve pending_calls[id] oneshot
    on disconnect: clear ipc_tx + tools; state → Running

ScopeMemoryStore (new module, scope_memory table in activity.db)
    load(scope) → Vec<ScopeMemoryEntry>   ← injected into system prompt
    upsert(...)                           ← stub / TODO future task

McpAggregator (simplified)
    get_system_tools() → hardcoded governor_* tools (unchanged)
    get_all_submodule_tools() + register_submodule_manifest() → DELETED (replaced by ProcessManager read)

agent_loop.rs
    all_tools = system_tools + entry.tools from ProcessManager (per-entry read)
    filtered  = ScopeFilter::filter_tools(all_tools, scope)
    memory    = ScopeMemoryStore::load(db_path, scope)
    system_prompt = dynamic (tools + memory block injected)

McpExecutor::execute(call, process_manager)
    governor_* → existing local match arms
    _          → scan ProcessManager entries for tool owner → forward via ipc_tx → oneshot(timeout_s)
```

---

## Deliverables

### 1. `shua_code_visualizer` — Full Registration Manifest
**File:** `shua_code_visualizer/src/broker/ipc_client.rs`

Update the `governor.mcp.register` frame from a plain name list to a structured manifest.
All future modules follow this exact same frame format.

```json
{
  "op": "governor.mcp.register",
  "module_id": "shua.code_visualizer",
  "version": "0.3.1",
  "scope": "code",
  "tools": [
    { "name": "code_parse_ast",            "description": "Parses a source file and returns the full AST symbol and edge extraction payload.", "scope": "code", "timeout_s": 60, "input_schema": { "type": "object", "properties": { "file_path": { "type": "string" } }, "required": ["file_path"] } },
    { "name": "code_read_file",            "description": "Fetches raw source text or a line-range snippet from a target file path.", "scope": "code", "timeout_s": 10, "input_schema": { "type": "object", "properties": { "file_path": { "type": "string" }, "start_line": { "type": "integer" }, "end_line": { "type": "integer" } }, "required": ["file_path"] } },
    { "name": "code_render_graph",         "description": "Renders filtered topology graph export by module path and max call depth.", "scope": "code", "timeout_s": 15, "input_schema": { "type": "object", "properties": { "module_path": { "type": "string" }, "max_depth": { "type": "integer" } }, "required": [] } },
    { "name": "code_blast_radius",         "description": "BFS caller-depth search for a target symbol — returns all callers up to max_depth.", "scope": "code", "timeout_s": 20, "input_schema": { "type": "object", "properties": { "qualified_name": { "type": "string" }, "max_depth": { "type": "integer" } }, "required": ["qualified_name"] } },
    { "name": "code_find_callers",         "description": "Returns all direct caller symbols of a given qualified function name.", "scope": "code", "timeout_s": 10, "input_schema": { "type": "object", "properties": { "qualified_name": { "type": "string" } }, "required": ["qualified_name"] } },
    { "name": "code_find_dead_code",       "description": "Returns all private non-test non-entrypoint symbols with zero fan-in (unreferenced dead code).", "scope": "code", "timeout_s": 30, "input_schema": { "type": "object", "properties": {}, "required": [] } },
    { "name": "code_find_god_functions",   "description": "Returns functions exceeding LOC, complexity, or parameter count thresholds.", "scope": "code", "timeout_s": 15, "input_schema": { "type": "object", "properties": {}, "required": [] } },
    { "name": "code_check_contract_drift", "description": "Verifies AST symbol signatures against HBP contract schemas and reports drift.", "scope": "code", "timeout_s": 20, "input_schema": { "type": "object", "properties": {}, "required": [] } }
  ]
}
```

---

### 2. `shua_governor` — `McpToolSchema` Extended
**File:** `shua_governor/src/mcp/mod.rs`

Add `timeout_s: Option<u64>` to `McpToolSchema`. The executor reads this per-tool when
building the oneshot timeout. Default (None) falls back to 15 seconds.

```rust
pub struct McpToolSchema {
    pub name:         String,
    pub description:  String,
    pub scope:        String,
    pub input_schema: serde_json::Value,
    pub timeout_s:    Option<u64>,  // NEW — per-tool call timeout override
}
```

---

### 3. `shua_governor` — Enrich `ModuleEntry` + New `IpcConnected` State
**File:** `shua_governor/src/registry/module_entry.rs`

Add `IpcConnected` to `ModuleState` and three IPC runtime fields to `ModuleEntry`.
All new fields use `#[serde(skip)]` so they are never serialized into telemetry payloads.

```rust
pub enum ModuleState {
    Running,
    IpcConnected,  // NEW: process alive AND MCP tools registered over IPC
    Sleeping,
    Stopped,
    Unknown,
}

pub type PendingCallMap = Arc<Mutex<HashMap<String, oneshot::Sender<serde_json::Value>>>>;

pub struct ModuleEntry {
    // ... all existing fields unchanged ...

    /// OS child handle — enables watchdog. Was previously std::mem::forgot-ten.
    #[serde(skip)]
    pub child_handle: Option<tokio::process::Child>,

    /// IPC write channel to this module's WebSocket connection. None if not connected.
    #[serde(skip)]
    pub ipc_tx: Option<mpsc::UnboundedSender<String>>,

    /// MCP tool schemas self-reported at registration. Empty if not IPC-connected.
    #[serde(skip)]
    pub tools: Vec<McpToolSchema>,

    /// Module-level scope declared at registration (e.g. "code", "diary").
    #[serde(skip)]
    pub module_scope: Option<String>,

    /// Semver string reported by the submodule in its registration manifest.
    #[serde(skip)]
    pub manifest_version: Option<String>,

    /// In-flight MCP tool call oneshot senders keyed by UUID request ID.
    #[serde(skip)]
    pub pending_calls: PendingCallMap,
}
```

`ModuleEntry::new` initialises all new fields to `None` / empty / `Arc::new(Mutex::new(HashMap::new()))`.

---

### 4. `shua_governor` — Process Watchdog (Fix `std::mem::forget`)
**File:** `shua_governor/src/registry/process_manager.rs`

Remove `std::mem::forget(child)` from `ProcessManager::start`. Store the child handle in
`entry.child_handle` and spawn a per-module watchdog task that:

1. Awaits the child's exit status (`child.wait().await`).
2. On exit: sets `entry.state = ModuleState::Stopped`, increments `entry.restart_count`,
   records `entry.last_error = Some(format!("Exited with status: {status}"))`.
3. Emits structured telemetry: `warn!(subsystem="process_manager", module=name, status=?status, restart_count, "Module process exited unexpectedly")`.
4. If `restart_count < 3` (configurable): waits 2 seconds and calls `self.start(name)` recursively.
5. If `restart_count >= 3`: emits `error!` and remains stopped — prevents crash-loop spam.

Also add `ipc_port: u16` to `ProcessManager::new()`. Inject env vars before `cmd.spawn()`:
```rust
cmd.env("SHUA_GOVERNOR_PID",      std::process::id().to_string());
cmd.env("SHUA_GOVERNOR_IPC_PORT", self.ipc_port.to_string());
```

---

### 5. `shua_governor` — IpcServer with PID Authentication
**Files:** `shua_governor/src/broker/ipc_server.rs` [NEW], `shua_governor/src/broker/mod.rs`

A dedicated JSON WebSocket listener on port `7701`. All submodule IPC uses plain JSON text
frames over this port — never mixed with the HBP MessagePack binary broker on port `7700`.

`IpcServer::run(addr, Arc<ProcessManager>)` — `ProcessManager` is the only shared state.

#### Connection Lifecycle

```
1. TCP accept → extract peer PID via SO_PEERCRED (Linux) or skip check on non-Linux
2. Wait for first frame: must be { "op": "governor.mcp.register", "module_id": "...", ... }
3. Look up module_id in ProcessManager (read lock)
   → if not found: close connection, warn!(subsystem="ipc_server", "Unknown module_id")
   → if found but entry.pid != Some(peer_pid): close, warn!("PID mismatch — auth rejected")
   → if found and PID matches: proceed
4. Write lock ProcessManager:
   → entry.ipc_tx       = Some(per-connection mpsc sender)
   → entry.tools        = parsed Vec<McpToolSchema> from frame
   → entry.module_scope = frame["scope"].as_str()
   → entry.manifest_version = frame["version"].as_str()
   → entry.state        = ModuleState::IpcConnected
   → log version mismatch warning if manifest_version differs from expected
5. info!(subsystem="ipc_server", module=module_id, tools=tool_count, version, "MCP tools registered")

6. Duplex select! loop:
   INCOMING:
   → { "id": "...", "status": "ok"/"error", "result": ... }
     Read ProcessManager → find entry by module_id → resolve entry.pending_calls[id] oneshot
   → { "op": "changed", "event": {...} }
     info!(subsystem="ipc_server", "Topology delta received") — Phase 4 concern
   → { "op": "governor.mcp.register", ... } again
     Hot-reload: update entry.tools in place (module restarted its watcher)

   OUTGOING:
   → Per-connection mpsc receiver drains tool call dispatch frames from McpExecutor

7. On disconnect:
   Write lock ProcessManager:
   → entry.ipc_tx       = None
   → entry.tools        = vec![]
   → entry.module_scope = None
   → entry.state        = ModuleState::Running  (process may still be alive)
   → warn!(subsystem="ipc_server", module=module_id, "IPC connection lost — tools unregistered")
```

---

### 6. `shua_governor` — Scope-Scoped Persistent Memory Stub
**Files:** `shua_governor/src/ai_router/scope_memory.rs` [NEW]

The `CopilotChatDrawer` is shared across all screens. Each screen passes a different
`contextHint`. JOSH needs persistent memory that is scoped to each domain so that facts
learned in the Code Visualizer never pollute the Diary context.

#### SQLite Table (added to `activity.db` via `logging/flush.rs` schema migration)
```sql
CREATE TABLE IF NOT EXISTS scope_memory (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    scope      TEXT    NOT NULL,          -- "code", "diary", "governor", etc.
    key        TEXT    NOT NULL,          -- short label e.g. "serialization_format"
    value      TEXT    NOT NULL,          -- free-form string, max 500 chars
    source     TEXT    NOT NULL DEFAULT 'agent_synthesized',
                                          -- "user_explicit" | "agent_synthesized" | "tool_result"
    session_id TEXT,                      -- which session created it (NULL = global)
    created_at INTEGER NOT NULL,
    UNIQUE(scope, key) ON CONFLICT REPLACE
);
```

#### `scope_memory.rs` Stub

```rust
use crate::logging::flush::resolved_db_path;

pub struct ScopeMemoryEntry {
    pub scope:      String,
    pub key:        String,
    pub value:      String,
    pub source:     String,
}

pub struct ScopeMemoryStore;

impl ScopeMemoryStore {
    /// Loads all memory entries for a given scope, ordered by created_at DESC.
    /// Returns empty vec gracefully on first run (table may not exist yet).
    /// Injected into agent_loop system prompt as a PERSISTENT CONTEXT block.
    pub fn load(scope: &str) -> Vec<ScopeMemoryEntry> {
        let db_path = resolved_db_path();
        // TODO: implement SQLite SELECT from scope_memory WHERE scope = ?
        // Use rusqlite (already a governor dependency via logging) — no new deps.
        let _ = (db_path, scope);
        vec![]
    }

    /// Persists or replaces a memory entry for a scope.
    /// Called by memory formation logic — deferred to future task.
    pub fn upsert(_entry: &ScopeMemoryEntry) {
        // TODO: TASK-future — memory formation, agent-synthesized storage,
        //       user-explicit "remember that..." command handling.
    }
}
```

#### Agent Loop Integration (`agent_loop.rs`)

After scope-filtering tools and before constructing `system_prompt`:

```rust
use crate::ai_router::scope_memory::ScopeMemoryStore;

let scope_memories = ScopeMemoryStore::load(scope);
let memory_block = if scope_memories.is_empty() {
    String::new()
} else {
    let lines = scope_memories.iter()
        .map(|m| format!("- [{}] {}", m.key, m.value))
        .collect::<Vec<_>>()
        .join("\n");
    format!("\n\nPERSISTENT CONTEXT FOR '{}' SCOPE (remember these facts):\n{}", scope, lines)
};

// memory_block is appended to system_prompt — empty string = zero prompt overhead when no memory
let system_prompt = format!("...existing prompt...{}", memory_block);
```

This means:
- `scope: "code"` session → JOSH receives code-domain memory only
- `scope: "diary"` session → JOSH receives diary-domain memory only
- `scope: "governor"` session → JOSH receives governor-domain memory only
- No cross-scope pollution

---

### 7. `shua_governor` — Agent Loop: Scope-Filtered Tool Merge + Dynamic Prompt
**File:** `shua_governor/src/ai_router/agent_loop.rs`

1. Accept `process_manager: Arc<ProcessManager>` as new parameter to `McpAgentLoop::run`.
2. Merge system tools + all submodule tools from live `ProcessManager` entries:
   ```rust
   let mut all_tools = aggregator.get_system_tools();
   {
       let modules = process_manager.modules.read().await;
       for entry in modules.values() {
           all_tools.extend(entry.tools.clone()); // only populated if IpcConnected
       }
   }
   let mcp_schemas = ScopeFilter::filter_tools(all_tools, scope);
   ```
3. Build `tools_json` from `mcp_schemas` (unchanged structure).
4. Replace the hardcoded 5-tool system prompt enumeration with a dynamic list generated
   from `mcp_schemas.iter()` mapping each tool's `name` and `description`.
5. Append `memory_block` from `ScopeMemoryStore::load(scope)` to the system prompt.
6. Remove the local `McpAggregator::new()` call from inside `run()` — the aggregator
   is now only used for `get_system_tools()` and is passed in as an `Arc` parameter.

Also remove `McpAggregator::register_submodule_manifest` and `get_all_submodule_tools` stubs
and the internal `submodule_tools` HashMap from `aggregator.rs` — these are no longer needed
since `ProcessManager` is the live tool registry.

---

### 8. `shua_governor` — McpExecutor: Dynamic Tool Routing with Per-Tool Timeout
**File:** `shua_governor/src/mcp/executor.rs`

Add `process_manager: Arc<ProcessManager>` to `McpExecutor::execute`. Replace the `_ =>`
fallthrough with a dynamic owner lookup — no hardcoded prefixes, no module-specific code:

```rust
_ => {
    let modules = process_manager.modules.read().await;

    // Find which module owns this tool name
    let owner = modules.values()
        .find(|e| e.tools.iter().any(|t| t.name == call.name));

    match owner {
        None => {
            warn!(subsystem="mcp_executor", tool=%call.name, "Tool not registered by any module");
            McpToolResponse { success: false,
                error: Some(format!("Unknown tool: '{}' — not registered by any connected module", call.name)),
                ..
            }
        }
        Some(entry) if entry.ipc_tx.is_none() => {
            // Module is in config but not IPC-connected (Stopped or Running but not IpcConnected)
            McpToolResponse { success: false,
                error: Some(format!(
                    "'{}' owns tool '{}' but is not connected. Use governor_wake_module(\"{}\") first.",
                    entry.name, call.name, entry.name
                )),
                ..
            }
        }
        Some(entry) => {
            // Read per-tool timeout from schema, fallback to 15s
            let timeout_secs = entry.tools.iter()
                .find(|t| t.name == call.name)
                .and_then(|t| t.timeout_s)
                .unwrap_or(15);

            let req_id = uuid::Uuid::new_v4().to_string();
            let (tx, rx) = oneshot::channel::<serde_json::Value>();
            entry.pending_calls.lock().await.insert(req_id.clone(), tx);

            let dispatch_frame = serde_json::json!({
                "op":   "mcp.tool_call",
                "id":   req_id,
                "tool": call.name,
                "args": call.arguments,
            });

            if entry.ipc_tx.as_ref().unwrap().send(dispatch_frame.to_string()).is_err() {
                return McpToolResponse { success: false, error: Some("IPC send channel closed".into()), .. };
            }

            drop(modules); // release read lock before blocking await

            match tokio::time::timeout(Duration::from_secs(timeout_secs), rx).await {
                Ok(Ok(result)) => McpToolResponse { tool_name: call.name.clone(), success: true, result, error: None },
                Ok(Err(_))     => McpToolResponse { success: false, error: Some("Submodule oneshot channel dropped".into()), .. },
                Err(_)         => McpToolResponse { success: false, error: Some(format!("Tool '{}' timed out after {}s", call.name, timeout_secs)), .. },
            }
        }
    }
}
```

---

### 9. `shua_governor` — `governor.scopes` Discovery Op
**File:** `shua_governor/src/broker/dispatcher.rs`

Add a new HBP op `"governor.scopes"` that returns the live scope registry derived from
`ProcessManager`. Flutter uses this to eventually render a dynamic scope selector in
`CopilotChatDrawer` instead of per-screen hardcoded `contextHint` values.

```json
Response payload:
{
  "scopes": [
    { "id": "governor", "label": "System",         "tools_count": 5, "module": null,                    "connected": true  },
    { "id": "code",     "label": "Code Visualizer", "tools_count": 8, "module": "shua.code_visualizer", "connected": true  },
    { "id": "diary",    "label": "Diary",           "tools_count": 0, "module": "shua.diary",           "connected": false },
    { "id": "resume",   "label": "Resume",          "tools_count": 0, "module": "shua.resume",          "connected": false }
  ]
}
```

Implementation: read `ProcessManager` entries (read lock), group by `entry.module_scope`,
emit a scope entry per module. Governor system tools are emitted as scope `"governor"` always.

---

### 10. `shua_governor` — `main.rs` Wiring
**File:** `shua_governor/src/main.rs`

- Add `ipc_port: u16` config field (default `7701`) to `GovernorConfig` in `config.rs`.
- Pass `ipc_port` to `ProcessManager::new(ipc_port)`.
- Spawn `IpcServer::run(ipc_addr, Arc::clone(&process_manager))` as a background task.
- Pass `Arc::clone(&process_manager)` into `Dispatcher::new`.
- `Dispatcher` propagates `process_manager` into `McpExecutor::execute` calls and
  the new `governor.scopes` handler.

---

### 11. Architecture Contracts Documentation
**File:** `_architecture/contracts/hbp/hbp_submodule_ipc_spec.md` [NEW]

Document:
- Registration manifest schema (all fields, types, required/optional)
- Tool call round-trip protocol (dispatch → response, UUID correlation)
- Hot-reload / re-registration on watcher restart
- Disconnect and cleanup behaviour
- PID authentication mechanism
- `scope_memory` table schema and future formation contract

---

## How Adding a New Module Looks After This Task

To add `shua.diary` in the future:

**1. `config.toml`** (one new block — already required for lifecycle):
```toml
[[modules.entry]]
name = "shua.diary"
binary = "/usr/local/bin/shua_diary"
auto_start = true
ram_limit_mb = 256
```

**2. `shua_diary/src/broker/ipc_client.rs`** — copy `shua_code_visualizer`'s `IpcClient`.
Change `module_id`, `scope`, and the `tools` array. The governor receives and routes everything
automatically.

**3. Done.** No governor changes. No executor changes. No aggregator changes.
JOSH's `contextHint: "diary"` session will automatically receive only `diary_*` tools and
diary-scoped memory.

---

## Files Changed Summary

| File | Action | Notes |
| :--- | :--- | :--- |
| `shua_code_visualizer/src/broker/ipc_client.rs` | MODIFY | Full 8-tool manifest with version, scope, timeout_s per tool |
| `shua_governor/src/mcp/mod.rs` | MODIFY | Add `timeout_s: Option<u64>` to `McpToolSchema` |
| `shua_governor/src/registry/module_entry.rs` | MODIFY | Add `IpcConnected` state; add `child_handle`, `ipc_tx`, `tools`, `module_scope`, `manifest_version`, `pending_calls` fields |
| `shua_governor/src/registry/process_manager.rs` | MODIFY | Remove `forget(child)`; add watchdog task per module; add `ipc_port`; inject env vars on spawn |
| `shua_governor/src/broker/ipc_server.rs` | NEW | JSON IPC WebSocket listener; PID auth; reads/writes ProcessManager entries directly |
| `shua_governor/src/broker/mod.rs` | MODIFY | Expose `ipc_server` module |
| `shua_governor/src/mcp/aggregator.rs` | MODIFY | Remove dead `submodule_tools` HashMap and both `#[allow(dead_code)]` stubs |
| `shua_governor/src/ai_router/scope_memory.rs` | NEW | Scope-scoped persistent memory stub; SQLite load + upsert |
| `shua_governor/src/ai_router/agent_loop.rs` | MODIFY | Accept `Arc<ProcessManager>`; merge tools from entries; apply `ScopeFilter`; dynamic prompt; inject memory block |
| `shua_governor/src/mcp/executor.rs` | MODIFY | Dynamic O(M×T) tool owner lookup; per-tool timeout; IPC forward + oneshot await |
| `shua_governor/src/broker/dispatcher.rs` | MODIFY | Add `governor.scopes` HBP op handler |
| `shua_governor/src/config.rs` | MODIFY | Add `ipc_port: u16` to `GovernorConfig` (default 7701) |
| `shua_governor/src/main.rs` | MODIFY | Spawn `IpcServer`; pass `ipc_port` to `ProcessManager::new`; wire `process_manager` into `Dispatcher` |
| `shua_governor/src/logging/flush.rs` | MODIFY | Add `scope_memory` table to `activity.db` schema migration |
| `_architecture/contracts/hbp/hbp_submodule_ipc_spec.md` | NEW | Complete IPC frame contract and protocol documentation |

---

## IPC Frame Contracts (JSON over WebSocket port 7701)

### Registration (submodule → governor, on connect)
```json
{ "op": "governor.mcp.register", "module_id": "shua.code_visualizer",
  "version": "0.3.1", "scope": "code",
  "tools": [ { "name": "code_blast_radius", "description": "...", "scope": "code",
               "timeout_s": 20, "input_schema": { ... } } ] }
```

### Tool call dispatch (governor → submodule)
```json
{ "op": "mcp.tool_call", "id": "uuid-v4", "tool": "code_blast_radius",
  "args": { "qualified_name": "McpAgentLoop::run", "max_depth": 3 } }
```

### Tool call response (submodule → governor)
```json
{ "id": "uuid-v4", "status": "ok",    "result": { ... } }
{ "id": "uuid-v4", "status": "error", "error": "Symbol not found in graph" }
```

### Live event push (submodule → governor, async)
```json
{ "op": "changed", "event": { "file_path": "src/lib.rs", "change_type": "modified",
                               "affected_node_ids": ["src/lib.rs:run"] } }
```

---

## Complexity Analysis

| Operation | Complexity | Notes |
| :--- | :--- | :--- |
| IpcServer registration | $O(T)$ write, $T \leq 10$ | Single write lock per connect |
| Agent loop tool merge | $O(M \cdot T)$ read | $M \leq 5$ modules, $T \leq 10$ tools — constant |
| `ScopeFilter::filter_tools` | $O(M \cdot T)$ | Already implemented, just unwired |
| `ScopeMemoryStore::load` | $O(K)$ SQLite read | $K \leq 20$ memory entries per scope |
| McpExecutor routing | $O(M \cdot T)$ scan | Bounded constant; upgradeable to $O(1)$ flat HashMap if $M > 10$ |
| Oneshot IPC round-trip | $O(1)$ + loopback RTT | < 1 ms on RPi5 loopback |
| Watchdog task | $O(1)$ per module | One `tokio::spawn` per spawned child |
| Space: ProcessManager | $O(N \cdot T)$ | $N \leq 5$ modules × $T \leq 10$ tools — Pi5-safe |
| Space: PendingCallMap | $O(C)$ per module | $C \leq 5$ concurrent in-flight calls |

---

## Verification Plan

### Automated Tests
```bash
cargo test -p shua_governor         # all unit tests pass
cargo test -p shua_code_visualizer  # all unit tests pass
cargo build -p shua_governor 2>&1 | grep "^warning" | wc -l   # expect 0
cargo build -p shua_code_visualizer 2>&1 | grep "^warning" | wc -l  # expect 0
```

### Integration Verification (Manual — on Raspberry Pi 5)
1. Start `shua_governor` → confirm log: `JSON IPC listener bound on 0.0.0.0:7701`.
2. Start `shua_code_visualizer` in managed mode → confirm governor log:
   `MCP tools registered: module=shua.code_visualizer tools=8 version=0.3.1`.
3. Verify `ModuleState` is `IpcConnected` for `shua.code_visualizer` in `governor_get_metrics` response.
4. Flutter Code Visualizer — open JOSH Copilot (`contextHint: "code"`), ask
   **"Find all god functions"** → verify:
   - `stream.step` shows `tool_name: "code_find_god_functions"` and `success: true`.
   - JOSH replies with a Markdown table of god functions from the live code graph.
5. Governor-scoped chat — ask **"What is my CPU temperature?"** → verify only `governor_*`
   tools are offered (scope filter bidirectionally enforced; `code_*` absent from tools_json).
6. Kill `shua_code_visualizer` process → confirm governor log:
   `Module process exited unexpectedly — restarting (restart_count=1)`.
7. After 3 crashes → confirm `restart_count=3` and state stays `Stopped` (no crash loop).
8. Query `governor.scopes` HBP op → confirm `shua.code_visualizer` shows `connected: false`
   after kill, `connected: true` after restart + re-registration.
9. Verify `scope_memory` table exists in `activity.db` with zero rows (stub, no formation yet).
