# TASK-015B — `shua_code_visualizer` Advanced Analysis & History (Deferred)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Deferred — not started |
| **Phase** | Phase 2 (or later — not required for TASK-016 to ship) |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_modules/shua_code_visualizer/` (extends TASK-015A) |
| **Blocks** | None |
| **Prerequisites** | TASK-015A complete, registered with `shua_governor`, and in real use for at least one refactor cycle (recommended, not mandatory) |
| **References** | `_architecture/reference/shua_code_visualizer/src/debug/ghost_imports.rs`, `src/export/git_diff.rs` (horAIzon 2.0 — revived here) |

---

## Purpose

TASK-015A gives you the live signature/risk map. TASK-015B adds *history and cross-cutting analysis* on top of it — the features that need either git history, snapshots over time, or cross-file/cross-language pattern matching, none of which are required for TASK-016's initial UI to function. Explicitly deferred, not dropped.

---

## Key Modules & Subtasks

### 1. Git Churn Integration (`src/history/git_diff.rs`)

- [ ] 1.1 Port git-diff-chunk → symbol mapping from horAIzon 2.0's `git_diff.rs` (logic is directly reusable, only the output shape needs to change to match TASK-015A's `GraphNode`/qualified-path model).
- [ ] 1.2 Track per-symbol churn count (number of commits touching that symbol's line range) over a configurable window (default: last 90 days).
- [ ] 1.3 `priority_score = risk_score * churn_count` — combines "risky and messy" (TASK-015A §6) with "changes constantly," which is the actual top-of-list refactor target.
- [ ] 1.4 New MCP tool: `code_top_priority_refactors` — input `{module_path: Option<string>, limit: u32 = 20}`, returns nodes sorted by `priority_score` descending.

### 2. Ghost Import / Unused Import Detector (`src/debug/ghost_imports.rs`)

- [ ] 2.1 Port detection logic from horAIzon 2.0's `debug/ghost_imports.rs` directly — this module needs minimal changes since it operates independently of the graph/risk work in 015A.
- [ ] 2.2 New MCP tool: `code_find_unused_imports` — input `{module_path: Option<string>}`, returns per-file list of unused imports.

### 3. Duplicate / Near-Duplicate Signature Clustering (`src/graph/duplicates.rs`)

- [ ] 3.1 Normalized signature similarity metric: name similarity (edit distance or token overlap) + param-shape similarity (count, type sequence).
- [ ] 3.2 Configurable clustering threshold (default: flag pairs above 0.85 similarity).
- [ ] 3.3 Cross-language mode (optional flag): compare normalized signatures across a Rust/Dart pair, useful for catching intentional-boundary-mirror vs accidental-copy-paste-drift, distinct from TASK-015A's `code_check_contract_drift` (which checks *tagged* boundary pairs; this checks *untagged*, opportunistically discovered similarity).
- [ ] 3.4 New MCP tool: `code_find_duplicate_signatures` — input `{module_path: Option<string>, cross_language: bool = false}`, returns clusters of similar signatures.

### 4. Public API Diff / Breaking-Change Detector (`src/history/api_diff.rs`)

- [ ] 4.1 Snapshot all `pub`/exported signatures on each full scan, keyed by git ref (or timestamp if no git context available), persisted alongside the §4 hash index from TASK-015A.
- [ ] 4.2 Diff logic: compare two snapshots, classify each symbol as `Added`, `Removed`, or `Changed` (with the specific field/type that changed for `Changed`).
- [ ] 4.3 New MCP tool: `code_diff_public_api` — input `{from_ref: string, to_ref: string}` (git refs) or `{from_snapshot_id, to_snapshot_id}`, returns the classified diff list.

### 5. Automatic Contract-Drift Discovery (extends TASK-015A §9)

- [ ] 5.1 Replace TASK-015A's manual `@hbp_boundary` tagging requirement with heuristic discovery: cross-reference struct names appearing in `hbp_*.toml` schema files and `mcp_master_spec.md` against parsed Rust/Dart/TS struct definitions, and auto-pair by name match.
- [ ] 5.2 Fall back to manual tagging (TASK-015A §9.1) for anything the heuristic can't confidently pair.
- [ ] 5.3 `code_check_contract_drift` (TASK-015A §9.3) gains an optional `{auto_discover: bool}` input flag — when true, skips the `boundary_tag` requirement and runs the full auto-discovered pair set.

---

## Acceptance Criteria

- [ ] `code_top_priority_refactors`, `code_find_unused_imports`, `code_find_duplicate_signatures`, `code_diff_public_api` are registered with `shua_governor` as MCP tools under scope `"code"`.
- [ ] Churn tracking correctly attributes commits to symbol qualified-paths across a file rename (i.e. doesn't silently lose churn history when a file moves).
- [ ] Duplicate-signature clustering produces zero false positives on TASK-015A's own codebase above the default 0.85 threshold (sanity check before shipping the default).
- [ ] `code_diff_public_api` correctly flags a deliberately introduced breaking change (manual test: rename a `pub fn` param) between two git refs.
- [ ] Auto-discovered contract-drift pairing correctly identifies the `GraphNode` Rust↔Dart↔toml relationship from TASK-015A without manual tagging.
- [ ] All new tools' schemas are exported via TASK-015A §3.2's schema-sync mechanism — no hand-written schema docs.
