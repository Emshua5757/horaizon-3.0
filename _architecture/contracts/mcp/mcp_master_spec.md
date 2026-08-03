# Master MCP Specification Matrix — horAIzon 3.0

| Field | Value |
| :--- | :--- |
| **Contract Version** | 3.1.0 |
| **Protocol** | Model Context Protocol (MessagePack over HBP v2 WS / JSON-RPC 2.0 over Stdio) |
| **Spec Directory** | `_architecture/contracts/mcp/` |
| **Canonical Modules** | `shua.governor`, `shua.diary`, `shua.code_visualizer`, `shua.resume`, `shua.gym`, `shua.crypto` |

---

## 1. Architectural Principles & Transport Framing

1. **Zero Double-Serialization Framing**:
   - **Over HBP v2 WebSocket (`ws://host:7700/hbp`)**: MCP tool calls between `shua_governor` and submodules are serialized directly as MessagePack maps (NOT JSON string bytes inside MessagePack) within `HbpFrame.p`, with `mod: "shua.<submodule>"` and `op: "mcp.tool_call"`.
   - **Over Stdio / Local CLI**: Uses standard JSON-RPC 2.0 UTF-8 text line streams for local Ollama and Claude CLI tools.
2. **Canonical Module Naming**:
   - Module namespaces MUST use dotted notation: `shua.governor`, `shua.diary`, `shua.code_visualizer`, `shua.resume`, `shua.gym`, `shua.crypto`.
   - MCP tool prefixes use short domain identifiers: `governor_*`, `diary_*`, `code_*`, `resume_*`, `gym_*`, `crypto_*`.
3. **Dynamic Extensible Scope Filtering**:
   - Submodules register their tool manifests dynamically via `governor.mcp.register` specifying a `scope` tag.
   - Initial scopes: `governor`, `diary`, `code`, `resume`, `gym`, `crypto`.
4. **Model Lifecycle & Scope Switching Latency**:
   - Switching scopes (e.g. `diary` → `code`) evicts the active Ollama model (`keep_alive: 0`) to preserve Pi 5 RAM budget (8GB RAM ceiling).
   - Scope switches carry a documented 1.5s–3.5s model reload latency hit. The client UI displays an "AI Model Loading..." indicator during transitions.
5. **Local Inference Optimization & Constrained Loop Engineering**:
   - **Static Byte-Identical Prompt Headers**: System prompt headers for each context scope (`scope: diary`, `scope: code`, etc.) MUST remain byte-identical across tool loop iterations to enable Ollama KV-cache reuse, dropping prompt evaluation times from ~1.2s to ~150ms on Pi 5 ARM.
   - **Grammar & Schema-Constrained Sampling**: Ollama chat calls MUST pass `format: <json_schema>` parameters derived from MCP tool schemas. Parameter generation is constrained at sampling level, preventing malformed enum values before tool execution.
   - **Deterministic Output Caching (`activity.db`)**: Tool loop responses are cached in SQLite with primary key `SHA256(model + static_prompt + input_payload)`. Duplicate queries return pre-computed tool call results with zero LLM inference overhead.
   - **Telemetry Circuit Breaker (`TAG_AI_INFERENCE`)**: Emits structured `tracing` logs (`info!`, `warn!`, `error!`) tagged with `subsystem: "ai_router"` and `trace_id`. If a tool loop hits `maxIterations` 3 consecutive times, the governor flags pipeline status as `degraded` and halts auto-retries.

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
- **Description**: Fetches real-time Pi 5 CPU %, RAM allocation, disk usage, and active process count.
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
- **Description**: Sends `SIGTERM`/`SIGKILL` signal to terminate a microservice process and drop its memory footprint to 0 MB RAM.
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
- **Description**: Loads a specified LLM weights file into Pi 5 RAM or offloaded Laptop GPU VRAM.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "model_name": { "type": "string", "example": "llama3.1:8b" },
    "target_device": { "type": "string", "enum": ["pi5_ram", "laptop_gpu"] }
  },
  "required": ["model_name"]
}
```

---

### Scope 2: `diary_*` (`shua.diary`)

#### `diary_create_block`
- **Description**: Inserts a new native Flutter block widget into an entry.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "entry_id": { "type": "string", "format": "uuid" },
    "block_type": { "type": "string" },
    "content": { "type": "string" },
    "after_block_id": { "type": "string", "format": "uuid" }
  },
  "required": ["entry_id", "block_type", "content"]
}
```

#### `diary_update_block`
- **Description**: Edits block content with optimistic concurrency version checking.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "block_id": { "type": "string", "format": "uuid" },
    "content": { "type": "string" },
    "version": { "type": "integer", "minimum": 1 }
  },
  "required": ["block_id", "content", "version"]
}
```

---

### Scope 3: `code_*` (`shua.code_visualizer`)

#### `code_parse_ast`
- **Description**: Parses source code file using Tree-sitter and returns symbol definitions and imports.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "file_path": { "type": "string" },
    "language": { "type": "string", "enum": ["rust", "dart", "typescript", "go", "python"] }
  },
  "required": ["file_path", "language"]
}
```

#### `code_render_graph`
- **Description**: Constructs dependency hypergraph dataset for a module.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_path": { "type": "string" },
    "depth": { "type": "integer", "default": 2 }
  },
  "required": ["module_path"]
}
```

#### `code_blast_radius`
- **Description**: Performs BFS caller depth search to calculate downstream/upstream impact for a target symbol.
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
- **Description**: Finds all incoming caller nodes for a qualified symbol path.
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
- **Description**: Identifies non-exported, unreferenced orphan symbols across the codebase.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_path": { "type": "string" }
  },
  "required": []
}
```

#### `code_find_god_functions`
- **Description**: Identifies complex functions exceeding parameters, LOC, or complexity thresholds.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "module_path": { "type": "string" },
    "thresholds": {
      "type": "object",
      "properties": {
        "max_params": { "type": "integer", "default": 5 },
        "max_complexity": { "type": "integer", "default": 10 },
        "max_loc": { "type": "integer", "default": 75 }
      }
    }
  },
  "required": []
}
```

#### `code_check_contract_drift`
- **Description**: Verifies signature alignment across tagged cross-boundary structs (e.g. Rust struct ↔ Dart model).
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "boundary_tag": { "type": "string" }
  },
  "required": ["boundary_tag"]
}
```

#### `code_read_file`
- **Description**: Fetches raw source code text or line-range snippet for a target file path.
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


---

### Scope 4: `resume_*` (`shua.resume`)

#### `resume_tailor_jaccard`
- **Description**: Calculates keyword overlap similarity against a target job description.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "target_job_description": { "type": "string" }
  },
  "required": ["target_job_description"]
}
```

#### `resume_compile_pdf`
- **Description**: Compiles Typst source template into PDF binary bytes.
- **Input Schema**:
```json
{
  "type": "object",
  "properties": {
    "template_id": { "type": "string", "default": "default" }
  },
  "required": []
}
```

---

## 4. Master MCP Resources (`uri` Schemas)

| URI Pattern | Subsystem | Read Payload |
| :--- | :--- | :--- |
| `governor://status` | `shua.governor` | Process tree, RAM/CPU metrics, active Ollama model |
| `governor://logs/recent` | `shua.governor` | Last 100 system log entries |
| `diary://entries/{id}` | `shua.diary` | Full `DiaryEntryDto` with array of `DiaryBlockDto` |
| `diary://mood/timeline` | `shua.diary` | Array of `{ date, mood_score, energy_level }` records |
| `code://graph/{module}` | `shua.code_visualizer` | Hypergraph JSON payload (nodes, edges, weights) |
| `resume://preview/latest` | `shua.resume` | Typst compiled PDF preview DTO |
