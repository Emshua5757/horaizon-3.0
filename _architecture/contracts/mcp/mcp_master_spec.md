# Master MCP Specification Matrix — horAIzon 3.0

| Field | Value |
| :--- | :--- |
| **Contract Version** | 3.2.0 |
| **Protocol** | Model Context Protocol (MessagePack over HBP v2 WS port 7700 / JSON IPC WS port 7701 / JSON-RPC 2.0 Stdio) |
| **Spec Directory** | `_architecture/contracts/mcp/` |
| **Canonical Modules** | `shua.governor`, `shua.diary`, `shua.code_visualizer`, `shua.resume`, `shua.gym`, `shua.crypto` |

---

## 1. Architectural Principles & Transport Framing

1. **Dual-Port WebSocket Architecture**:
   - **HBP v2 Core Broker (`ws://host:7700/hbp`)**: High-performance MessagePack binary framing for telemetry, UI state streams (`stream.chunk`, `stream.step`), and client RPCs.
   - **Submodule JSON IPC Listener (`ws://127.0.0.1:7701/ipc`)**: Dedicated JSON text WebSocket listener on loopback port 7701. Managed submodules connect, authenticate via OS PID (`SO_PEERCRED`), and register tool manifests over this channel.
   - **Stdio / Local CLI**: Standard JSON-RPC 2.0 UTF-8 text line streams for local Ollama and Claude CLI tools.

2. **Canonical Module Naming & Dynamic Registration**:
   - Module namespaces MUST use dotted notation: `shua.governor`, `shua.diary`, `shua.code_visualizer`, `shua.resume`, `shua.gym`, `shua.crypto`.
   - Submodules self-register tool manifests dynamically via `governor.mcp.register` carrying `module_id`, `version`, `scope`, and array of `McpToolSchema` objects (including optional per-tool `timeout_s`).
   - `ProcessManager` acts as the single source of truth for process lifecycle and registered MCP tools.

3. **Dynamic Extensible Scope Filtering**:
   - `ScopeFilter::filter_tools(tools, scope)` filters system + registered submodule tools based on request context scope.
   - Standard scopes: `governor`, `diary`, `code`, `resume`, `gym`, `crypto`, `all`.
   - Discovery operation `governor.scopes` returns live connected scopes and tool counts to client UIs.

4. **Scope-Isolated Persistent Memory (`scope_memory`)**:
   - Persistent facts and domain knowledge are isolated per context scope in SQLite (`activity.db`, table `scope_memory`).
   - The AI Agent Loop queries `ScopeMemoryStore::load(scope)` and injects a `PERSISTENT CONTEXT FOR '<scope>'` block into system prompts, ensuring cross-domain memory isolation (e.g. code topology facts do not pollute diary sessions).

5. **Model Lifecycle & Memory Constraints**:
   - Switching scopes evicts active Ollama models when necessary (`keep_alive: 0`) to enforce the 8GB Pi 5 RAM ceiling.
   - Per-tool call execution timeout (`timeout_s`, default 15s) prevents long-running tool queries from hanging inference loops.

---

## 2. Context Scope Definitions

```
                     ┌────────────────────────────────────────┐
                     │          HORAIZON AI ROUTER            │
                     │  (Selects scope based on active route) │
                     └───────────────────┬────────────────────┘
                                         │
 ┌─────────────────┬───────────────┬─────┴─────────┬────────────────┬─────────────────┐
 ▼                 ▼               ▼               ▼                ▼                 ▼
┌────────────┐   ┌───────────┐   ┌───────────┐   ┌────────────┐   ┌───────────┐   ┌────────────┐
│   scope:   │   │  scope:   │   │  scope:   │   │   scope:   │   │  scope:   │   │   scope:   │
│"governor"  │   │  "diary"  │   │  "code"   │   │  "resume"  │   │  "gym"    │   │  "crypto"  │
└────────────┘   └───────────┘   └───────────┘   └────────────┘   └───────────┘   └────────────┘
 governor_*       diary_*         code_*          resume_*         gym_*           crypto_*
 Process/RAM      36 Blocks/FTS   AST/Topology    Typst/Jaccard    Workout data    Vault/Keys
```

---

## 3. Master MCP Tool Specifications

### Scope 1: `governor_*` (`shua.governor`)

#### `governor_get_metrics`
- **Description**: Fetches real-time Pi 5 CPU %, RAM allocation, system temperature, NVMe status, uptime, and active module states.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

#### `governor_wake_module`
- **Description**: Sends `SIGCONT` signal via Linux cgroups v2 to resume a sleeping microservice.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_name": { 
      "type": "string", 
      "enum": ["shua.diary", "shua.code_visualizer", "shua.resume", "shua.gym", "shua.crypto"] 
    }
  },
  "required": ["module_name"]
}
```

#### `governor_sleep_module`
- **Description**: Sends `SIGSTOP` signal via Linux cgroups v2 to pause a running microservice and free RAM/CPU.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_name": { 
      "type": "string", 
      "enum": ["shua.diary", "shua.code_visualizer", "shua.resume", "shua.gym", "shua.crypto"] 
    }
  },
  "required": ["module_name"]
}
```

#### `governor_stop_module`
- **Description**: Sends `SIGTERM`/`SIGKILL` signal to terminate a microservice process and release RAM budget.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_name": { 
      "type": "string", 
      "enum": ["shua.diary", "shua.code_visualizer", "shua.resume", "shua.gym", "shua.crypto"] 
    }
  },
  "required": ["module_name"]
}
```

#### `governor_load_ollama_model`
- **Description**: Loads a specified LLM model into Pi 5 RAM or offloaded GPU VRAM.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "model_name": { "type": "string" },
    "target_device": { "type": "string", "enum": ["pi5_ram", "laptop_gpu"] }
  },
  "required": ["model_name"]
}
```

#### `governor_query_logs`
- **Description**: Queries recent system logs, telemetry metrics, and events from `activity.db`.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "subsystem": { "type": "string" },
    "limit": { "type": "integer" }
  },
  "required": []
}
```

---

### Scope 2: `code_*` (`shua.code_visualizer`)

#### `code_parse_ast`
- **Description**: Parses single source file and returns AST symbol and edge extraction payload.
- **Timeout**: 60s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "file_path": { "type": "string" }
  },
  "required": ["file_path"]
}
```

#### `code_read_file`
- **Description**: Fetches raw source code text or line-range snippet for target file.
- **Timeout**: 10s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "file_path": { "type": "string" },
    "start_line": { "type": "integer" },
    "end_line": { "type": "integer" }
  },
  "required": ["file_path"]
}
```

#### `code_render_graph`
- **Description**: Renders filtered topology graph export by module path and max call depth.
- **Timeout**: 15s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_path": { "type": "string" },
    "max_depth": { "type": "integer" }
  },
  "required": []
}
```

#### `code_blast_radius`
- **Description**: Performs BFS caller-depth search for target qualified symbol name. Returns all callers up to max_depth.
- **Timeout**: 20s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "qualified_name": { "type": "string" },
    "max_depth": { "type": "integer" }
  },
  "required": ["qualified_name"]
}
```

#### `code_find_callers`
- **Description**: Returns all direct caller symbols of a given qualified function name.
- **Timeout**: 10s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "qualified_name": { "type": "string" }
  },
  "required": ["qualified_name"]
}
```

#### `code_find_dead_code`
- **Description**: Scans code graph and returns unreferenced non-pub, non-test symbols with zero fan-in.
- **Timeout**: 30s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

#### `code_find_god_functions`
- **Description**: Returns functions exceeding configurable thresholds for lines-of-code, complexity, or parameter count.
- **Timeout**: 15s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

#### `code_check_contract_drift`
- **Description**: Verifies AST symbol signatures against HBP contract schemas and reports drift.
- **Timeout**: 20s
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {},
  "required": []
}
```

---

## 4. Submodule Registration Protocol & Manifest Schema

Submodules register with `shua_governor` over JSON IPC WebSocket (`ws://127.0.0.1:7701`) on startup:

```json
{
  "op": "governor.mcp.register",
  "module_id": "shua.code_visualizer",
  "version": "0.3.1",
  "scope": "code",
  "tools": [
    {
      "name": "code_parse_ast",
      "description": "Parses a single source file and returns symbol definitions.",
      "scope": "code",
      "timeout_s": 60,
      "input_schema": { ... }
    }
  ]
}
```

---

## 5. Master MCP Resources (`uri` Schemas)

| URI Pattern | Subsystem | Read Payload |
| :--- | :--- | :--- |
| `governor://status` | `shua.governor` | Process tree, RAM/CPU metrics, active Ollama model |
| `governor://logs/recent` | `shua.governor` | Last 100 system log entries |
| `governor://scopes` | `shua.governor` | Array of live registered context scopes and tool counts |
| `diary://entries/{id}` | `shua.diary` | Full `DiaryEntryDto` with array of `DiaryBlockDto` |
| `diary://mood/timeline` | `shua.diary` | Array of `{ date, mood_score, energy_level }` records |
| `code://graph/{module}` | `shua.code_visualizer` | Hypergraph JSON payload (nodes, edges, weights) |
| `resume://preview/latest` | `shua.resume` | Typst compiled PDF preview DTO |
