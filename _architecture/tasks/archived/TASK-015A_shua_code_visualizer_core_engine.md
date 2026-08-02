# TASK-015A — `shua_code_visualizer` Core Engine (Parser, Graph, Metrics, MCP Server)

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/` |
| **Supersedes** | TASK-015 (original, retired — split into 015A/015B) |
| **Blocks** | TASK-016 (Flutter Code Topology Screen) |
| **Splits Into** | TASK-015B (deferred: churn, dedup, API-diff, ghost imports) |
| **Prerequisites** | TASK-004 (HBP v2 Broker), `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/schema/hbp_code_viz.toml` |
| **Sub-tasks** | TASK-015A-1, TASK-015A-2, TASK-015A-3, TASK-015A-4 (all completed) |

---

## Deliverables Summary
- **TASK-015A-1**: Pre-flight contracts and DTO schemas (`hbp_code_viz.toml`, `mcp_master_spec.md`, `ThresholdConfig`).
- **TASK-015A-2**: Multi-language Tree-sitter AST symbol and edge extractor for Rust, Dart, Go, Python, and TypeScript.
- **TASK-015A-3**: `petgraph::stable_graph::StableDiGraph` graph store with fail-closed dangling edge handling, BFS `max_depth` filtering, `xxh64` persistent disk hash cache, and live non-blocking path-debouncing file watcher.
- **TASK-015A-4**: `shua_code_visualizer` executable daemon assembly (`main.rs`) with full boot rescan for 100% graph coverage across restarts, and complete 7-tool MCP server handler (`src/mcp/handler.rs`).
