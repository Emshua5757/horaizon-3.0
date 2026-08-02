# TASK-015A-4 — `shua_code_visualizer` Daemon Assembly, Boot Sequence & HBP/MCP Server Wiring

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/src/main.rs`, `shua_code_visualizer/src/mcp/handler.rs` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | TASK-015A-1, TASK-015A-2, TASK-015A-3 |

---

## Key Subtasks

### 1. Boot Sequence & Daemon Loop (`src/main.rs`)
- [x] 1.1 `HashCache::load_from_disk` ➔ `diff_directory` ➔ full scan of source files for 100% graph coverage across restarts ➔ build initial `CodeGraph` ➔ `save_to_disk`.
- [x] 1.2 Start `CodeWatcher` live directory file watcher background task (with graceful fallback to read-only query mode if inotify fails).
- [x] 1.3 Auto-registration log stub for `shua_governor` integration (HBP IPC wired in TASK-015H).

### 2. MCP Tool Handler Implementation (`src/mcp/handler.rs`)
- [x] 2.1 `code_parse_ast`: Return raw AST breakdown for single source file (`ParseAstArgs`).
- [x] 2.2 `code_render_graph`: Return module/depth subgraph (`RenderGraphArgs`).
- [x] 2.3 `code_blast_radius`: Perform BFS caller depth search for target symbol (`BlastRadiusArgs`).
- [x] 2.4 `code_find_callers`: Return direct callers of target symbol (`FindCallersArgs`).
- [x] 2.5 `code_find_dead_code`: Return unreferenced symbols excluding `pub`, `test`, `main`, and constructors using real `is_public` / `is_test` flags.
- [x] 2.6 `code_find_god_functions`: Return functions exceeding `max_loc`, `max_complexity`, or `max_params` thresholds (`ThresholdConfig`).
- [x] 2.7 `code_check_contract_drift`: Return `"status": "not_implemented"` stub.

---

## Acceptance Criteria
- [x] Daemon boot sequence executes complete rescan, persistent hash cache save, and watcher start.
- [x] All 7 `code_*` MCP tools return valid structured responses matching `mcp_master_spec.md`.
- [x] `cargo check` and `cargo test` pass with zero warnings (12/12 unit tests passing).
