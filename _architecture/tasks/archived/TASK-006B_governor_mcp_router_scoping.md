# TASK-006B — Governor MCP Tool Aggregator & Context Scope Router

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 1 Follow-up |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_governor/src/mcp/`, `shua_governor/src/broker/dispatcher.rs` |
| **Blocks** | TASK-018 |
| **Prerequisites** | TASK-006 (Ollama AI Intent Router), TASK-007 (AppConfig), `_architecture/contracts/mcp/mcp_master_spec.md` |
| **References** | `_architecture/contracts/mcp/mcp_master_spec.md` |

---

## Architectural Context & Scope Filtering Directive

> [!IMPORTANT]
> **Centralized AI Intent Router + Strict Context Scope Filter**:
> - `shua_governor` is the **single point of LLM inference** for the entire system. All microservices (`shua_diary`, `shua_resume`) and `client_flutter` send prompts through the Governor's AI Router.
> - **Scope Filtering**: To prevent 8B local Ollama models from getting confused by 30+ tools, `shua_governor` filters tool schemas based on the `scope` parameter in the AI request:
>   - `scope: "governor"` → Ollama receives `governor_*` tools ONLY (process control, RAM metrics, module wake/sleep).
>   - `scope: "diary"` → Ollama receives `diary_*` tools ONLY (create/update/delete/reorder blocks).
>   - `scope: "resume"` → Ollama receives `resume_*` tools ONLY.
> - Submodules (`shua_diary`, `shua_resume`) do NOT maintain Ollama or Gemini connections; they delegate LLM tool execution to `shua_governor`.

---

## Key Modules & Components (`shua_governor/src/mcp/`)

1. **`mcp/mod.rs`**:
   - Module entrypoint exposing MCP tool registration, scope filtering, and execution.
2. **`mcp/aggregator.rs`**:
   - System MCP tool definitions (`governor_get_metrics`, `governor_wake_module`, `governor_sleep_module`, `governor_load_ollama_model`, `governor_query_logs`).
   - Dynamic registration interface for submodule MCP tool manifests (`diary_*`, `resume_*`).
3. **`mcp/scope_filter.rs`**:
   - Filter function `get_tools_for_scope(scope: &str) -> Vec<McpToolSchema>`.
4. **`mcp/executor.rs`**:
   - Dispatches tool calls chosen by Ollama/Gemini to the local Governor handler or submodule WebSocket RPC via HBP v2 broker.
5. **Broker Integration (`src/broker/dispatcher.rs`)**:
   - Exposes `governor.mcp.tools` and `governor.mcp.call` RPC handlers over HBP v2.

---

## RPC Endpoints Added to Governor HBP v2 Broker

- `governor.mcp.register`: Submodule registers its MCP tool manifest.
- `governor.mcp.tools`: Queries context-scoped MCP tool schemas.
- `governor.mcp.call`: Dispatches and executes selected MCP tool calls.

---

## Acceptance Criteria

- [x] `mcp/aggregator.rs` registers system `governor_*` MCP tools
- [x] `mcp/scope_filter.rs` correctly filters tools per `scope` ("governor", "diary", "resume")
- [x] Ollama 8B receives strictly context-scoped tools, preventing cross-module command confusion
- [x] Centralized Gemini API key configuration in AppConfig provides cloud AI fallback for all modules
- [x] Zero compiler warnings (`cargo check`)
- [x] Automated tests for scope filter and tool dispatch
