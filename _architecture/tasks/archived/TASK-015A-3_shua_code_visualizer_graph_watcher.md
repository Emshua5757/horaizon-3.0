# TASK-015A-3 — `shua_code_visualizer` Graph Store, Hash Cache & File Watcher Engine

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_code_visualizer/src/graph/`, `shua_code_visualizer/src/watch/` |
| **Parent Task** | TASK-015A (`shua_code_visualizer` Core Engine) |
| **Prerequisites** | TASK-015A-2 (Multi-Language AST Parser & Symbol Extractor) |

---

## Key Subtasks

### 1. Graph Store Engine (`src/graph/store.rs`)
- [x] 1.1 `petgraph::stable_graph::StableDiGraph` adjacency graph (`StableDiGraph<GraphNode, GraphEdge>`) with symbol interning and $\mathcal{O}(1)$ lookup (`HashMap<QualifiedName, NodeIndex>`).
- [x] 1.2 Fail-closed handling for dangling / unresolved callee edges (`self.foo()`, `worker.run()`): drop or tag unresolved target edges without panicking or skewing `fan_in` counts.
- [x] 1.3 `TopologyExportResponse` rendering with BFS bounded `max_depth` filtering and module path boundary checks.

### 2. Persistent Hash Index & File Watcher (`src/watch/`)
- [x] 2.1 `xxh64` per-file content hash index persisted to disk (`.hash_cache.json`).
- [x] 2.2 Boot sequence diff: compare filesystem hashes against index to reparse changed/new/deleted files only.
- [x] 2.3 `notify` crate file watcher daemon with non-blocking channel polling and 100ms path debouncing (`pending_events: HashMap<PathBuf, Instant>`).
- [x] 2.4 Incremental single-file graph patch execution (`apply_incremental_file_patch`) emitting `TopologyDeltaEvent` on the `changed` HBP event stream.

---

## Acceptance Criteria
- [x] Graph store constructs `petgraph` dependency graph from `ParseResult` payloads.
- [x] Unresolved callee edges complete cleanly without panics.
- [x] Multi-symbol file node removals use `StableDiGraph` tombstoning without index swap-remove corruption.
- [x] File watcher path debouncing runs 100% non-blockingly without `std::thread::sleep`.
- [x] `cargo check` and `cargo test` pass with zero warnings (11/11 unit tests passing).
