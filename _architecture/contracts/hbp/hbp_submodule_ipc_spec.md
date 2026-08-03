# HBP Submodule IPC Specification — horAIzon 3.0

| Field | Value |
| :--- | :--- |
| **Contract Version** | 1.0.0 |
| **Transport** | JSON WebSocket over TCP Loopback (`ws://127.0.0.1:7701/ipc`) |
| **Governor Listener** | `shua_governor::broker::ipc_server` |
| **Canonical Clients** | `shua.code_visualizer`, `shua.diary`, `shua.resume`, `shua.gym`, `shua.crypto` |

---

## 1. Overview & Architectural Principles

1. **Dedicated IPC Port (7701)**:
   - `shua_governor` runs a dedicated JSON text WebSocket listener on loopback port `7701`.
   - Client UI traffic uses HBP v2 MessagePack binary framing on port `7700`. Submodule inter-process control (IPC) traffic uses plain JSON text framing on port `7701`.

2. **Single Source of Truth (`ProcessManager`)**:
   - `shua_governor` manages process lifecycle and registered tools in `ProcessManager`.
   - Submodules self-report their tool manifests upon connecting over IPC.
   - Disconnects automatically revert module state from `IpcConnected` to `Running` and unregister active tools.

3. **PID Authentication (`SO_PEERCRED`)**:
   - On Linux / Raspberry Pi 5, the IPC server inspects socket credentials (`SO_PEERCRED`) to verify that the connecting process PID matches the PID recorded by `ProcessManager` when spawning the process.

---

## 2. Frame Schemas

### 2.1 Registration Manifest Frame (`submodule` → `governor`)
Sent immediately upon WebSocket connection establishment.

```json
{
  "op": "governor.mcp.register",
  "module_id": "shua.code_visualizer",
  "version": "0.3.1",
  "scope": "code",
  "tools": [
    {
      "name": "code_parse_ast",
      "description": "Parses a single source file and returns AST symbol and edge extraction payload.",
      "scope": "code",
      "timeout_s": 60,
      "input_schema": {
        "type": "object",
        "properties": {
          "file_path": { "type": "string" }
        },
        "required": ["file_path"]
      }
    }
  ]
}
```

### 2.2 Tool Call Dispatch Frame (`governor` → `submodule`)
Dispatched by `McpExecutor` when an LLM selects a tool owned by the submodule.

```json
{
  "op": "mcp.tool_call",
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "tool": "code_blast_radius",
  "args": {
    "qualified_name": "McpAgentLoop::run",
    "max_depth": 3
  }
}
```

### 2.3 Tool Call Response Frame (`submodule` → `governor`)
Returned by the submodule after executing the tool call.

#### Success Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "ok",
  "result": [
    {
      "id": "src/main.rs:main",
      "qualified_name": "main",
      "file": "src/main.rs",
      "line": 32
    }
  ]
}
```

#### Error Response:
```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "status": "error",
  "error": "Symbol 'McpAgentLoop::run' not found in code graph"
}
```

### 2.4 Live Event Push (`submodule` → `governor`)
Pushed asynchronously by submodules on filesystem mutations.

```json
{
  "op": "changed",
  "event": {
    "file_path": "src/lib.rs",
    "change_type": "modified",
    "affected_node_ids": ["src/lib.rs:parse_file"]
  }
}
```

---

## 3. Scope Memory Database Schema (`activity.db`)

Persistent domain facts are isolated per scope in SQLite:

```sql
CREATE TABLE IF NOT EXISTS scope_memory (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    scope      TEXT    NOT NULL,
    key        TEXT    NOT NULL,
    value      TEXT    NOT NULL,
    source     TEXT    NOT NULL DEFAULT 'agent_synthesized',
    session_id TEXT,
    created_at INTEGER NOT NULL,
    UNIQUE(scope, key) ON CONFLICT REPLACE
);
```
