# TASK-015A-1 — `shua_code_visualizer` Pre-flight Contracts & Wire DTO Foundation

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust / TOML / Markdown |
| **Target** | `shua_code_visualizer/`, `_architecture/contracts/` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | `_architecture/contracts/mcp/mcp_master_spec.md`, `_architecture/contracts/hbp/schema/hbp_code_viz.toml` |

---

## Key Subtasks

### 1. Architectural Contract Synchronization
- [x] 1.1 `hbp_code_viz.toml`: Collapse `scan` and `topology.get` ops into generic `mcp.tool_call`. Keep `watch.start`, `watch.stop`, and `changed` HBP ops.
- [x] 1.2 `hbp_code_viz.toml`: Replace flat `TopologyExportResponse` with structured `GraphNode`, `GraphEdge`, `ParamDto`, and updated response structs.
- [x] 1.3 `mcp_master_spec.md`: Fix `code_parse_ast` input parameter field (`file_path`).
- [x] 1.4 `mcp_master_spec.md`: Add definitions for `code_blast_radius`, `code_find_callers`, `code_find_dead_code`, `code_find_god_functions`, and `code_check_contract_drift`.
- [x] 1.5 `mcp_master_spec.md`: Clarify generic `mcp.tool_call` envelope handling for scope `code`.

### 2. Rust Crate Setup & Wire DTO Models (`shua_code_visualizer/`)
- [x] 2.1 Initialize `shua_code_visualizer` Rust crate shell (`Cargo.toml`, `src/lib.rs`, `src/main.rs`).
- [x] 2.2 Define Wire DTO structs in `src/mcp/schema.rs` (`GraphNode`, `GraphEdge`, `TopologyExportResponse`, `TopologyDeltaEvent`, `ThresholdConfig`, enums, params).
- [x] 2.3 Derive `Serialize`, `Deserialize`, `Debug`, `Clone`, and `schemars::JsonSchema` on all wire DTOs.
- [x] 2.4 Implement `--export-schema` flag in binary to export JSON schemas to disk / stdout for continuous schema sync validation.

---

## Acceptance Criteria
- [x] `hbp_code_viz.toml` and `mcp_master_spec.md` updated cleanly without contract drift.
- [x] `shua_code_visualizer` compiles in workspace root with zero compiler warnings (`cargo check`).
- [x] `cargo test` passes for wire DTO serialization and schema exports (3/3 unit tests passing).
- [x] `--export-schema` CLI flag outputs valid JSON Schemas matching contracts.
