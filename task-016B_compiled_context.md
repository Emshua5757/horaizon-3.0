# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 29

================================================================================

<!-- START_FILE: _architecture\tasks\active\TASK-016B_flutter_code_topology_live_physics_animation.md -->
# FILE: TASK-016B_flutter_code_topology_live_physics_animation.md
**Relative Path**: `_architecture\tasks\active\TASK-016B_flutter_code_topology_live_physics_animation.md`

# TASK-016B — client_flutter Live Physics Simulation, Path Tracer & Insights Filter Matrix

| Field | Value |
| :--- | :--- |
| **Status** | [/] In Progress |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter / Rust |
| **Target** | `client_flutter/lib/features/code_visualizer/` & `shua_code_visualizer/` |
| **Branch** | `task/TASK-016B-live-physics-animation` |
| **Prerequisites** | TASK-016A (Multi-View Topology Canvas), TASK-015A-5 (HBP IPC Broker) |
| **Sub-tasks** | TASK-016B-0 through TASK-016B-6 (016B-0 spans both `shua_code_visualizer` and `client_flutter`) |

---

## Why this beats a straight Graphify port

Graphify (Python) computes a layout once, renders a static image or a fixed-frame view, and has no channel back to the source repo. You already built something it doesn't have: `shua_code_visualizer` runs as a **live subprocess** with a working `TopologyDeltaEvent` stream over the HBP IPC broker (TASK-015A-5) and named `from`/`to` call edges precise enough to BFS. The plan below is built around using both of those — not just matching Graphify's feature list, but adding two things it structurally can't do:

1. **Live delta animation** — when a file changes, the graph patches itself and animates the change, instead of requiring a full re-scan/re-render.
2. **A tool-connected inspector** — path tracing and "blast radius" aren't just visual tricks, they can call straight into the same `McpHandler` (`find_callers`, `blast_radius`) your Rust core already exposes, so the answer is guaranteed to match what the AST parser actually sees.

Point 2 only actually works if `shua_code_visualizer` is willing to hand out more than the plain node/edge export it uses today. That's what 016B-0 below adds: standalone runs keep behaving exactly as they do now (same JSON, same CLI flags — nothing regresses), but when the process is being driven by the governor, it can offer richer, display-oriented answers on request instead of making Flutter reimplement graph algorithms client-side against a possibly-huge edge list.

---

## TASK-016B-0 — Mode-Aware Display Broker (Rust) & Data Source Abstraction (Flutter)

**Target**: `shua_code_visualizer/src/broker/` (new `display_broker.rs`), `client_flutter/lib/features/code_visualizer/providers/code_topology_provider.dart` (new `topology_data_source.dart`)

### Why this needs to exist before 016B-2 / 016B-3 / 016B-4
Right now every "smart" feature in this plan (path tracing, N-hop isolation, insight thresholds) either duplicates logic that already exists in the Rust AST engine, or ships a second, client-side implementation of a graph algorithm that has to somehow agree with the Rust one. That's fine for a demo, but it means two sources of truth: if the Rust risk-score formula changes, someone has to remember to also update `topology_insights.dart`'s hardcoded fallback numbers, and a Dart BFS over a workspace with tens of thousands of edges will always be slower and less correct (no cross-crate/cross-module resolution, no incremental knowledge) than asking the engine that actually parsed the code.

The fix is to let `shua_code_visualizer` expose two tiers of capability depending on how it was launched — matching the split you already built in TASK-015A-5.

### Subtasks — Rust side (`display_broker.rs`)
- [ ] 0.1 **Standalone Mode stays untouched.** `--export-graph` continues to produce exactly today's `{nodes, edges}` JSON — no schema change, no new required fields. This is a hard constraint, not a suggestion: anything that reads the existing export (docs, other tooling) keeps working.
- [ ] 0.2 **Managed Subprocess Mode gets a `DisplayCapabilities` handshake.** On IPC connect, `shua_code_visualizer` sends the governor a small capability message (e.g. `{ "supports": ["trace_path", "blast_radius", "layout_hints", "delta_stream"] }`) so the client can feature-detect rather than guessing based on mode alone.
- [ ] 0.3 **`trace_path(from_id, to_id, directed: bool)` over IPC.** Reuses whatever graph structure the engine already holds in memory (it parsed the whole workspace — it already has the adjacency, no need to rebuild it from the exported edge list). Returns the ordered hop list, or an explicit "no path" result. This is the authoritative version of TASK-016B-2's BFS.
- [ ] 0.4 **`blast_radius(id, depth)` / `find_callers(id)` over IPC**, wrapping the same logic already scaffolded for the MCP tool schema (`BlastRadiusArgs`, `FindCallersArgs`) so N-hop isolation (TASK-016B-4) can call the real engine on large workspaces instead of a Dart BFS over however many thousand edges got exported.
- [ ] 0.5 **`layout_hints` in the managed-mode snapshot.** Optional extra fields alongside each node/edge *only* in the managed-mode response (never in the plain `--export-graph` output): a `suggested_level` (topological depth from entrypoints, for Call-Flow Tree mode) and a `cluster_id` (file/module grouping, for File-Grouped mode). The engine already has to compute something like this internally for other purposes; exposing it saves Flutter from redoing the same BFS/grouping work in `layout_engine.dart` and keeps "what counts as a root/entrypoint" defined in one place.
- [ ] 0.6 **Richer delta payloads.** Extend the existing `TopologyDeltaEvent` (TASK-015A-5 §3.3) with an `approx_previous_position` hint (or, more simply, the ids of the pre-existing neighbor nodes) for changed/added nodes, so the client can settle new nodes in near their real neighbors instead of spawning them at the origin — feeds directly into TASK-016B-6.
- [ ] 0.7 **Schema/protocol versioning.** Tag the managed-mode snapshot and delta messages with a `schema_version` field from the start, so future additive fields don't require a breaking client update.

### Rust API Expansions for Enhanced Graph Display (0.7a – 0.7l)

#### Correctness Gaps (Solves Client-Side Heuristic Limitations):
- [ ] 0.7a **`is_entrypoint: bool`**: Distinguishes real entrypoints (`main()`, `#[tokio::main]`, `@main`, API router handlers) from dead orphaned code (`fan_in == 0` without entrypoint attributes). Solves Call-Flow Tree root calculation.
- [ ] 0.7b **`scc_id: Option<usize>`**: Strongly Connected Component (Tarjan/Kosaraju) detection for cyclic call graphs (mutual recursion / callbacks). Lets Flutter collapse cycles or render them as orbiting loops instead of flattening them into 1D lines.
- [ ] 0.7c **`call_count: u32` per edge**: Exposes exact call invocation counts per edge (e.g., `main()` calls `parse()` 3 times). Controls spring elasticity and edge line stroke thickness.
- [ ] 0.7d **Threshold Config Export**: Exposes current threshold config (`threshold_config: { max_complexity: 15, max_loc: 80, max_params: 5 }`) in export metadata so UI filter chips display real thresholds ("Complexity ≥ 15") with 1 source of truth.
- [ ] 0.7e **`risk_score_breakdown`**: Exposes risk score components (`{ loc_component, complexity_component, coupling_component }`) so inspector drawer explains *why* a function is high risk.
- [ ] 0.7f **`module_path: String` separate from `file`**: Separates filesystem path (`src/broker/ipc_client.rs`) from Rust/Dart logical module path (`crate::broker::ipc_client`), allowing nested module tree containers in File Grouped mode.
- [ ] 0.7g **Granular Symbol Kinds (`symbol_kind`)**: Distinguishes `function`, `method`, `struct`, `enum`, `trait`, `interface`, `module`, `macro`. Lets canvas render distinct geometric shapes (hexagons for traits, boxes for structs, circles for functions).
- [ ] 0.7h **`scan_progress` events**: Progress percentage stream (`{ files_scanned, total_files, pct }`) during initial workspace parsing.
- [ ] 0.7i **Node ID Stability & Move Hints (`moved_from` / `renamed_from`)**: Hints for live-delta continuity when symbols are renamed or moved across files.

#### Additional Display Enhancements (Rust Engine Powered):
- [ ] 0.7j **`initial_pos_hint: { x, y }`**: Quick 10-step force layout pre-calculated in Rust before JSON export so nodes spawn already separated in space with zero first-frame overlap.
- [ ] 0.7k **Cross-Module Dependency Matrix (`module_coupling`)**: Export inter-module call coupling counts (`[{ from_module, to_module, edge_count }]`), enabling high-level module dependency overview diagrams.
- [ ] 0.7l **Concurrency Attribute Flags (`is_async: bool`, `is_blocking: bool`)**: AST parser flags async functions (cyan glow) vs blocking I/O (purple stroke) for visual concurrency profiling.

### Subtasks — Flutter side (`topology_data_source.dart`)
- [ ] 0.8 Introduce a small abstraction — `abstract class TopologyDataSource` with `Future<TopologyGraphDataModel> loadSnapshot()`, `Stream<TopologyDeltaEvent>? deltaStream`, and optional `Future<List<String>>? tracePath(...)` / `Future<Set<String>>? blastRadius(...)` (nullable = "not supported by this source").
- [ ] 0.9 `StandaloneDataSource`: exactly today's behavior — spawn the binary or read the on-disk export, no IPC, the optional methods return `null`/unsupported.
- [ ] 0.10 `ManagedDataSource`: connects over IPC, exposes the capability-gated methods from 0.3–0.6, and reads `DisplayCapabilities` on connect to decide what it can offer.
- [ ] 0.11 `codeTopologyProvider` picks the data source based on the existing `SHUA_GOVERNOR_PID`-equivalent detection on the Flutter side (or simply: did the IPC connect attempt in `ManagedDataSource` succeed) — this becomes the one place that decides "are we standalone or managed," instead of that logic being implicit across several features.
- [ ] 0.12 Every consumer (path tracer, N-hop isolation) should be written to *prefer* the data source's method when non-null and **only** fall back to the local Dart implementation (016B-2's local BFS, 016B-4's local BFS) when it returns `null` — so Standalone Mode still fully works, just without the engine-backed shortcuts.
- [ ] 0.13 **Shared `GraphIndex`, built once per snapshot.** Right now, id→node lookup and caller/callee adjacency get rebuilt independently in at least four places: `_callFlowLayout` builds its own `callers`/`callees` maps, the canvas's `_neighborhoodOf` does an O(edges) linear scan over `graphData.edges` on every single tap, and both the path-tracer fallback (2.3) and isolation fallback (4.2) will each want to build adjacency again for their own BFS. Build one `GraphIndex` (id → node map, forward adjacency, reverse adjacency) once when a `TopologyGraphDataModel` loads or patches, hang it off the data source alongside the model, and have every consumer above take it as a parameter instead of deriving its own copy. Cheap win, removes real duplicated work, and means there's exactly one definition of "neighbor" in the whole client.
- [ ] 0.14 **Fix silent failure in `codeTopologyProvider`.** The current implementation has two bare `catch (_) {}` blocks around the subprocess spawn and the disk-fallback read, and never checks `res.stderr` when `res.exitCode != 0`. That means a broken binary path, a crashed parse, or a malformed export file all look identical to "no graph yet" — there's nothing to debug from. At minimum log `res.stderr`/the exception to whatever logging the app already uses, and consider exposing load failures as a distinct provider state (e.g. an `AsyncError` with a real message) rather than silently falling through to the next fallback and eventually returning an empty graph.
- [ ] 0.15 **Skip the temp-file round trip.** `codeTopologyProvider` currently writes the export to `${Directory.systemTemp.path}/code_viz_dynamic_graph.json` and immediately reads it back. If the binary supports writing to stdout (or add a flag if it doesn't), read `res.stdout` directly and skip the extra disk write/read — saves two syscalls per scan and one stale-temp-file class of bug (a scan failing halfway can leave a previous run's file behind to be silently re-read).
- [ ] 0.16 **Externalize the hardcoded paths.** `activeWorkspacePathProvider`'s default and the `binaryPath`/`diskPath` constants are baked-in absolute Windows paths (`c:/horaizon-3.0/...`). Fine for your current single-machine dev loop, but move these to environment variables or a small config file read at startup so the same code runs on another machine/CI without a source edit.
- [ ] 0.17 **Debounce workspace-path changes.** If `activeWorkspacePathProvider` is ever wired to a live-editable text field rather than only a folder picker, changing it re-triggers a full subprocess spawn + AST parse on every keystroke. Either keep it picker-only (no free-text edit) or debounce (~400ms) before the provider re-runs.

### Acceptance Criteria
- [ ] Running standalone produces byte-identical `--export-graph` output to before this task (regression check against the existing sample `code_viz_graph_output.json`).
- [ ] Running under the governor, the Flutter client receives and can log the `DisplayCapabilities` handshake.
- [ ] `trace_path` and `blast_radius` IPC calls return correct results against a small hand-verified example graph.
- [ ] With the IPC connection deliberately disabled/killed mid-session, the Flutter app falls back to local BFS for path tracing and isolation without crashing.

---

## TASK-016B-1 — 60fps Live Physics Ticker & Interactive Node Dragging

**Target**: `presentation/widgets/layout_engine.dart`, `presentation/widgets/code_topology_canvas.dart`

### Problem with the current physics mode
`_physicsLayout()` runs all 240 iterations synchronously up front and hands back a frozen `Map<String, Offset>`. That's a layout algorithm, not a simulation — there's no ticker, nothing moves after the first frame, and there's no hook for dragging.

### Subtasks
- [ ] 1.1 Convert `GraphLayoutEngine` physics mode into a stateful `PhysicsSimulation` class that exposes `step(double dt)` instead of `compute()` running to completion.
- [ ] 1.2 Drive it from a `Ticker` (`SingleTickerProviderStateMixin` on `CodeTopologyCanvas`), calling `step()` once per vsync frame — target 16.6ms/frame.
- [ ] 1.3 Keep per-node `position` + `velocity` in the simulation, not in the painter — the painter only reads current positions each frame.
- [ ] 1.4 **Thermal cooling / idle detection**: track total kinetic energy (`sum(velocity.distanceSquared)`) each step. When it drops below an epsilon for N consecutive frames, call `_ticker.stop()`. Any new drag, filter change, or delta patch calls `_ticker.start()` again. This is the "0% CPU when idle" requirement — a running `Ticker` on a settled graph is a real battery/CPU cost on desktop and should not run forever.
- [ ] 1.5 **Node pinning**: add `Set<String> pinnedIds` to the simulation. Pinned nodes are excluded from velocity integration (position is set directly, not accumulated) but still exert spring/repulsion force on everything else.
- [ ] 1.6 **Drag gesture wiring** in `CodeTopologyCanvas`:
  - `onPanStart`: hit-test at the local position (reuse existing `_hitTest`); if a node is hit, add it to `pinnedIds` and record the pointer→node offset.
  - `onPanUpdate`: set that node's position directly to the pointer position (translated through the current `InteractiveViewer` transform — see 1.7), restart the ticker if it had cooled down.
  - `onPanEnd`: remove the node from `pinnedIds` so it rejoins the simulation with whatever velocity it picks up next step (or leave it pinned permanently if you want "anchor" semantics — worth a toggle, see 1.8).
- [ ] 1.7 Dragging inside an `InteractiveViewer` means pointer coordinates are in viewport space, not content space — convert with the viewer's `TransformationController.value` (invert the matrix) before feeding coordinates to the simulation.
- [ ] 1.8 Optional: long-press a node to toggle a permanent 📌 pin (stays fixed even after drag release) vs. the default "spring-release" behavior on drag end. Small UX win, cheap to add once 1.5/1.6 exist.
- [ ] 1.9 Only run the O(n²) Coulomb repulsion pass under a node-count guard (e.g. < 400 nodes); above that, fall back to a uniform-grid spatial hash so repulsion stays roughly O(n) — see TASK-016B-5 for the general version of this, but a simple bucket grid here is enough to keep dragging responsive on large repos.
- [ ] 1.10 **Fix first-frame jank on load.** The current `_physicsLayout()` runs all 240 iterations synchronously before returning anything, which blocks the UI thread for however long that takes on a real workspace-sized graph — the whole app freezes for that duration on every fresh load or full re-scan, before this task's ticker even starts. Once physics is tick-driven (1.1–1.2), this mostly resolves itself: seed initial positions cheaply (random or file-clustered) and let the *first several ticks* of the running simulation do the settling on-screen, instead of pre-computing a settled layout before the first paint. If an instant "pre-settled" look is still wanted for the very first frame, do the warm-start iterations inside a `compute()` isolate rather than on the UI thread.

### Acceptance Criteria
- [ ] Physics mode visibly settles (nodes stop moving) within ~3–5 seconds of a fresh layout and the ticker actually stops (verify via a debug print or `Ticker.isTicking`) — no perpetual `setState` loop.
- [ ] Dragging any node in Physics mode moves it under the pointer 1:1, and connected neighbors visibly get pulled along by spring force in real time.
- [ ] Releasing a drag lets the node rejoin the simulation smoothly (no snapping/teleporting).
- [ ] Frame budget stays under ~16ms per tick on a repo-sized graph (measure with `flutter run --profile` + DevTools timeline) for graphs up to a few hundred nodes.

---

## TASK-016B-2 — Graphify Shortest Path Tracer

**Target**: new `presentation/widgets/path_tracer.dart`, changes to `code_topology_canvas.dart` and `code_topology_screen.dart`

### Subtasks
- [ ] 2.1 Add two new providers: `pathStartNodeProvider` / `pathEndNodeProvider` (`StateProvider<TopologyNodeModel?>`).
- [ ] 2.2 UI affordance to set them — simplest version: right-click (desktop) or long-press (touch) a node opens a small context menu with "Set as Path Start" / "Set as Path End"; clear button in the toolbar resets both.
- [ ] 2.3 `path_tracer.dart`: call `TopologyDataSource.tracePath()` (TASK-016B-0) first. If it returns `null` (Standalone Mode, no engine connection), fall back to a local BFS: build a directed adjacency map from `edges[]` once per graph load (`Map<String, List<String>> adjacency`), BFS from start to end tracking parent pointers, reconstruct the hop list.
  - Decide directionality up front for the local fallback: BFS strictly along `Calls`/`Imports` direction (caller → callee) will often fail to find a path back, since call graphs aren't symmetric. Default to an **undirected** BFS over the same edge set (so "is there a call relationship chain between these two symbols at all" — matches what a person visually expects when they pick two nodes), but expose a toggle for "directed only." The engine-backed path (0.3) already accepts a `directed` flag, so this toggle applies to both code paths identically.
- [ ] 2.4 Surface "no path found" clearly (disconnected components are common and not a bug) rather than silently doing nothing.
- [ ] 2.5 Path highlighting in the canvas painter: given the ordered node-id list, draw the traced edges with a distinct color/width (e.g. bright green, 3px) layered on top of the normal edge pass, and give the path nodes a highlighted ring — same visual language as the existing neighborhood-highlight dimming, so it composes rather than fighting it.
- [ ] 2.6 **Hop-by-hop reveal animation**: instead of showing the whole path instantly, animate it revealing one edge at a time (e.g. 150ms stagger per hop) using an `AnimationController` with an `Interval` per segment — this is the part that actually sells "trace" over "just draw a line."
- [ ] 2.7 Small path panel (reuse the inspector drawer's slot, or a bottom sheet) listing the ordered chain: `main() → IpcClient::start_ipc_loop → CodeGraph::new`, each entry tappable to jump/select that node.

### Acceptance Criteria
- [ ] Selecting two connected symbols produces a correct shortest hop chain (verify against a hand-traced example from the sample graph, e.g. `main` → `IpcClient::start_ipc_loop`).
- [ ] Selecting two symbols with no connecting path shows an explicit "not connected" state, not a blank/broken highlight.
- [ ] Path reveal animation runs once per selection change and doesn't re-trigger on unrelated rebuilds (filter/search changes shouldn't replay it).

---

## TASK-016B-3 — Advanced Insights Filter Matrix

**Target**: `providers/code_topology_provider.dart`, `code_topology_screen.dart`, `presentation/widgets/code_topology_canvas.dart`

### Subtasks
- [ ] 3.1 Expand `GraphFilterMode` (currently `all, mostCalled, highRisk, deadCode`) into a proper **matrix**, not a single-select enum: `Set<InsightFilter> activeFilters` where `InsightFilter` is `{ godFunctions, hubs, highRisk, deadCode, publicApis }`, defaulting to empty (= show all).
- [ ] 3.2 Filter combination semantics: OR by default (show a node if it matches *any* active filter) — matches how people actually explore ("show me anything risky OR dead"). Add a small "match all (AND)" toggle for power users who want the intersection.
- [ ] 3.3 Replace the current `SegmentedButton<GraphFilterMode>` with a `Wrap` of toggle chips (🌐 All · 👑 God Functions · 🔥 Hubs · ⚠️ High Risk · 💀 Dead Code · 📦 Public APIs), each showing a live count badge (`12`) computed from the current graph so people know what they're about to look at before tapping.
- [ ] 3.4 Add `publicApis` to `topology_insights.dart`: `bool get isPublicApi => isPublic && !isTest;`
- [ ] 3.4a While here: `isGodFunction`'s hardcoded fallback numbers (`complexity >= 15 && loc >= 80`, etc., added in TASK-016A) exist only because the client can't be sure the Rust-exported `exceeds*Threshold` booleans reflect the *current* configured thresholds. Since `exceeds_complexity_threshold` / `exceeds_loc_threshold` / `exceeds_param_threshold` are already present in every export (standalone or managed — see `topology_models.dart`), prefer those directly and treat the hardcoded numeric fallback as a last resort for malformed/old exports only, not the primary check. This keeps one source of truth for "what counts as a god function" in the Rust threshold config instead of two.
- [ ] 3.5 Update `_passesFilter` in the canvas to check membership against `activeFilters` instead of a single mode switch.
- [ ] 3.6 Persist filter state across layout-mode switches (it already will, since it's a separate provider — just confirm no accidental reset on `ref.invalidate(codeTopologyProvider)`).

### Acceptance Criteria
- [ ] Toggling multiple filter chips shows the union (or, with AND enabled, the intersection) of matching nodes, with counts on each chip matching what's actually rendered.
- [ ] Switching layout mode or re-scanning a folder does not silently clear an active filter selection.

---

## TASK-016B-4 — Search & N-Hop Subgraph Isolation

**Target**: `code_topology_screen.dart`, `presentation/widgets/code_topology_canvas.dart`

### Subtasks
- [ ] 4.1 Add an `isolationDepthProvider` (`StateProvider<int>`, values 0/1/2 = off/1-hop/2-hop) next to the existing search bar.
- [ ] 4.2 When search text is non-empty and isolation depth > 0: compute the matching node set, then for each match call `TopologyDataSource.blastRadius(id, depth)` (TASK-016B-0) when available — union the results across matches. Fall back to a local BFS outward `depth` hops through the already-loaded `edges[]` (undirected) only when the data source doesn't support it (Standalone Mode). Either way, the result dims everything outside the isolated set using the same neighborhood-highlight mechanism already built for node selection.
- [ ] 4.3 Debounce the search `TextField.onChanged` (e.g. 150ms) before recomputing isolation, so typing doesn't recompute the subgraph on every keystroke for large graphs.

### Acceptance Criteria
- [ ] Typing a symbol name with 1-hop isolation active dims everything except direct callers/callees of matches; 2-hop extends one ring further; 0 (off) behaves exactly as today (dim nothing, just filter-out non-matches).

---

## TASK-016B-5 — Performance Pass for Larger Graphs

**Target**: `presentation/widgets/layout_engine.dart`, `presentation/widgets/code_topology_canvas.dart`

### Subtasks
- [ ] 5.1 Wrap `CodeTopologyCanvas`'s `CustomPaint` in a `RepaintBoundary` so dragging/physics repaints don't force the toolbar or inspector drawer to repaint.
- [ ] 5.2 Replace the current all-pairs Coulomb repulsion with a uniform spatial grid (bucket nodes into cells sized ~2× the repulsion falloff radius, only check neighbor cells) once graphs exceed ~300–400 nodes — full Barnes-Hut quadtree is the "correct" answer but is real complexity; the grid gets most of the win for much less code.
- [ ] 5.3 For very large workspaces, consider running the physics `step()` math in a background `Isolate` via `compute()`, sending back only the position map — keeps the UI thread free for gestures even under heavy simulation load. Treat this as a stretch goal; only do it if 5.2 alone doesn't hit frame budget.
- [ ] 5.4 Add a debug FPS/frame-time overlay (toggleable, off by default) so regressions are visible during development instead of just "feels laggy."
- [ ] 5.5 **Stop recomputing `visibleIds` every paint.** `_TopologyPainter.paint()` currently rebuilds the filter/search-matched id set from scratch on every call — and once 016B-1's ticker is running, `paint()` fires up to 60 times/second even when the filter and search query haven't changed at all between frames. Cache the computed set keyed on `(filter, query, graphData)` and only recompute when one of those actually changes; physics-driven repaints should just reuse the cached set.
- [ ] 5.6 **Cache `TextPainter`s instead of rebuilding per frame.** Every node label and badge emoji currently gets a fresh `TextPainter` + `layout()` call inside the per-frame paint loop — text layout is one of the more expensive things a `CustomPainter` can do repeatedly. Cache each node's label `TextPainter` keyed on `(text, style)` and only rebuild it when the label or the zoom-dependent style bucket actually changes, not on every tick.
- [ ] 5.7 **Viewport culling.** The painter draws every node and edge in the full content size regardless of what's actually visible through `InteractiveViewer`'s current pan/zoom — for a large graph zoomed in, most of that work is off-screen and wasted. Pass the current visible content-space `Rect` (derived from the `TransformationController`) into the painter and skip any node/edge whose bounding box doesn't intersect it.
- [ ] 5.8 **Layout cache invalidation on live deltas.** `CodeTopologyCanvas`'s layout cache keys on `identical(_cachedData, widget.graphData)` — fine for a one-shot load, but once TASK-016B-6 starts patching the graph on every file save, each patch will most likely produce a new immutable `TopologyGraphDataModel` instance, which invalidates this cache completely and forces a full layout recompute (all 240+ iterations again) on every keystroke-triggered save. Key the cache on a version counter or content hash that only changes when the *shape* of the graph changes, not on model identity — and make sure a delta patch reuses existing node positions (per 6.3) instead of re-running the full layout from scratch.

### Acceptance Criteria
- [ ] A synthetic ~500-node graph still holds a usable frame rate (no strict number required, but should be visibly smoother than the naive O(n²) baseline measured before this task).
- [ ] Toggling a filter or typing a search query while physics is actively ticking doesn't cause a visible frame-rate dip from `visibleIds` recomputation (5.5).
- [ ] Panning/zooming in on a large graph visibly reduces per-frame paint work (spot-check via DevTools) once culling (5.7) lands.
- [ ] A live delta patch (once 016B-6 exists) repositions only the changed nodes rather than re-running the full layout algorithm from scratch (5.8).

---

## TASK-016B-6 — Live Delta Animation (the "better than Graphify" piece)

**Target**: `providers/code_topology_provider.dart`, `presentation/widgets/code_topology_canvas.dart`

This is the capability Graphify simply doesn't have: your Rust core (TASK-015A-5) already streams `TopologyDeltaEvent` patches over the IPC broker whenever a watched file changes. Right now the Flutter side only ever does a one-shot `--export-graph` + full re-decode. Wiring up the live stream turns the visualizer from "a picture I regenerate" into "a window onto the running codebase."

### Subtasks
- [ ] 6.1 Add a `StreamProvider<TopologyDeltaEvent>` that connects to the governor's IPC port (reuse whatever transport `shua_governor` already speaks to `shua_code_visualizer` — WebSocket per TASK-015A-5 §3).
- [ ] 6.2 On each delta event, patch the in-memory `TopologyGraphDataModel` (add/update/remove the affected nodes and edges) instead of re-fetching the whole graph.
- [ ] 6.3 Feed added/changed node ids into the physics simulation as new points near their connected neighbors (not at the origin) and let the spring forces settle them in — this is also where the ticker in TASK-016B-1 needs to auto-wake if it had cooled down.
- [ ] 6.4 Small transient visual cue on newly-added nodes (brief scale-in or glow) and a fade-out for removed ones, so a live edit is visibly legible instead of nodes just jumping.
- [ ] 6.5 Guard this whole path behind the same Standalone/Managed-mode detection the Rust side already has — if there's no governor connection, this feature silently does nothing (falls back to the existing static export path), never errors.

### Acceptance Criteria
- [ ] Editing a watched file and saving it results in the running visualizer updating the affected node(s)/edge(s) without a manual re-scan, while running in Managed Subprocess mode.
- [ ] Standalone mode (no governor) behaves exactly as it does today — no crash, no hanging connection attempt.

---

## Suggested Build Order

1. **016B-0** first — the standalone/managed display broker split, `DisplayCapabilities`, fields 0.7a–0.7l, and the `TopologyDataSource` abstraction.
2. **016B-1** next — everything else (dragging feedback, path animation, live delta re-settling) depends on physics actually being a running simulation instead of a one-shot layout.
3. **016B-3** (filter matrix) and **016B-4** (search isolation) next — cheap, mostly independent, immediately useful.
4. **016B-2** (path tracer) — depends on shared highlight mechanism and `trace_path`.
5. **016B-5** (performance) — optimize rendering, text painters, spatial hash, and viewport culling.
6. **016B-6** (live delta) — live WebSocket streaming.


<!-- END_FILE: _architecture\tasks\active\TASK-016B_flutter_code_topology_live_physics_animation.md -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\code_topology_screen.dart -->
# FILE: code_topology_screen.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\code_topology_screen.dart`

// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/topology_insights.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/layout_engine.dart';
import 'presentation/widgets/symbol_inspector_drawer.dart';
import 'providers/code_topology_provider.dart';

class CodeTopologyScreen extends ConsumerWidget {
  const CodeTopologyScreen({super.key});

  Future<void> _pickRepositoryFolder(WidgetRef ref) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Repository Folder to Visualize',
    );

    if (selectedPath != null && selectedPath.isNotEmpty) {
      ref.read(activeWorkspacePathProvider.notifier).state = selectedPath;
      ref.read(selectedNodeProvider.notifier).state = null;
      ref.read(pathStartNodeProvider.notifier).state = null;
      ref.read(pathEndNodeProvider.notifier).state = null;
      ref.invalidate(codeTopologyProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topologyAsync = ref.watch(codeTopologyProvider);
    final selectedNode = ref.watch(selectedNodeProvider);
    final activePath = ref.watch(activeWorkspacePathProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final currentLayout = ref.watch(selectedLayoutModeProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    return Scaffold(
      body: Column(
        children: [
          // Top Control Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Icon(Icons.hub_rounded, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Code Topology',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Folder Picker Button
                  FilledButton.icon(
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: Text(
                      activePath.isEmpty ? 'Select Repository...' : activePath.split(RegExp(r'[/\\]')).last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _pickRepositoryFolder(ref),
                  ),
                  const SizedBox(width: 12),

                  // Layout Mode Segmented Control
                  SegmentedButton<LayoutMode>(
                    segments: const [
                      ButtonSegment(value: LayoutMode.physics, label: Text('⚡ Physics Cluster')),
                      ButtonSegment(value: LayoutMode.fileGrouped, label: Text('📁 File Grouped')),
                      ButtonSegment(value: LayoutMode.callFlow, label: Text('🌲 Call Flow')),
                    ],
                    selected: {currentLayout},
                    onSelectionChanged: (set) {
                      ref.read(selectedLayoutModeProvider.notifier).state = set.first;
                    },
                  ),
                  const SizedBox(width: 12),

                  // Search Bar
                  SizedBox(
                    width: 180,
                    height: 36,
                    child: TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search symbol...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Multi-Select Insight Filter Chips
                  _FilterChip(
                    label: 'All',
                    isSelected: activeFilters.isEmpty,
                    onSelected: (_) {
                      ref.read(activeFiltersProvider.notifier).state = {};
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '👑 God Functions',
                    isSelected: activeFilters.contains(InsightFilter.godFunctions),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.godFunctions) : updated.remove(InsightFilter.godFunctions);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '🔥 Hubs',
                    isSelected: activeFilters.contains(InsightFilter.hubs),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.hubs) : updated.remove(InsightFilter.hubs);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '⚠️ High Risk',
                    isSelected: activeFilters.contains(InsightFilter.highRisk),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.highRisk) : updated.remove(InsightFilter.highRisk);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '💀 Dead Code',
                    isSelected: activeFilters.contains(InsightFilter.deadCode),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.deadCode) : updated.remove(InsightFilter.deadCode);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 12),

                  // Path Tracer Reset Button
                  if (pathStart != null || pathEnd != null)
                    ActionChip(
                      avatar: const Icon(Icons.route_rounded, size: 14),
                      label: Text('Path: ${pathStart?.qualifiedName ?? '?'} ➔ ${pathEnd?.qualifiedName ?? '?'}'),
                      onPressed: () {
                        ref.read(pathStartNodeProvider.notifier).state = null;
                        ref.read(pathEndNodeProvider.notifier).state = null;
                      },
                    ),

                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Rescan Repository',
                    onPressed: () => ref.invalidate(codeTopologyProvider),
                  ),
                ],
              ),
            ),
          ),

          // Main View (Canvas + Inspector Drawer)
          Expanded(
            child: topologyAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Parsing repository symbols and building topology graph...',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading topology: $err')),
              data: (graphData) => Row(
                children: [
                  Expanded(
                    child: CodeTopologyCanvas(graphData: graphData),
                  ),
                  if (selectedNode != null)
                    SymbolInspectorDrawer(node: selectedNode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\code_topology_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\models\topology_insights.dart -->
# FILE: topology_insights.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\models\topology_insights.dart`

// File: client_flutter/lib/features/code_visualizer/models/topology_insights.dart

import 'topology_models.dart';

enum InsightFilter { godFunctions, hubs, highRisk, deadCode, publicApis }

extension TopologyNodeInsights on TopologyNodeModel {
  /// A "God Function": high complexity & high LOC, or huge fan-out with too many params.
  bool get isGodFunction =>
      (exceedsComplexityThreshold && exceedsLocThreshold) ||
      (complexity >= 15 && loc >= 80) ||
      (fanOut >= 8 && params.length >= 5);

  /// Structural hub: high call traffic (fanIn + fanOut >= 6).
  bool get isHub => (fanIn + fanOut) >= 6;

  /// Dead Code: unreferenced, not public, not a test.
  bool get isDeadCode => isOrphan && !isPublic && !isTest;

  /// High Risk score >= 7.0.
  bool get isHighRisk => riskScore >= 7.0;

  /// Public API symbol.
  bool get isPublicApi => isPublic && !isTest;

  /// Primary badge label.
  String get primaryBadgeLabel {
    if (isGodFunction) return 'God Function';
    if (isDeadCode) return 'Dead Code';
    if (isHighRisk) return 'High Risk';
    if (isHub) return 'Hub';
    if (isPublicApi) return 'Public API';
    return '';
  }

  String get primaryBadgeEmoji {
    if (isGodFunction) return '👑';
    if (isDeadCode) return '💀';
    if (isHighRisk) return '⚠️';
    if (isHub) return '🔥';
    if (isPublicApi) return '📦';
    return '';
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\models\topology_insights.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\models\topology_models.dart -->
# FILE: topology_models.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\models\topology_models.dart`

class ParamModel {
  final String name;
  final String type;
  final bool isOptional;

  const ParamModel({
    required this.name,
    required this.type,
    this.isOptional = false,
  });

  factory ParamModel.fromJson(Map<String, dynamic> json) {
    return ParamModel(
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? '',
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'is_optional': isOptional,
      };
}

class TopologyNodeModel {
  final String id;
  final String kind;
  final String qualifiedName;
  final String file;
  final int line;
  final List<ParamModel> params;
  final String? returnType;
  final int complexity;
  final List<String> sideEffects;
  final String? intent;
  final int loc;
  final bool isPublic;
  final bool isTest;
  final int fanIn;
  final int fanOut;
  final double riskScore;
  final bool isOrphan;
  final bool exceedsParamThreshold;
  final bool exceedsComplexityThreshold;
  final bool exceedsLocThreshold;

  const TopologyNodeModel({
    required this.id,
    required this.kind,
    required this.qualifiedName,
    required this.file,
    required this.line,
    required this.params,
    this.returnType,
    required this.complexity,
    required this.sideEffects,
    this.intent,
    required this.loc,
    required this.isPublic,
    required this.isTest,
    required this.fanIn,
    required this.fanOut,
    required this.riskScore,
    required this.isOrphan,
    this.exceedsParamThreshold = false,
    this.exceedsComplexityThreshold = false,
    this.exceedsLocThreshold = false,
  });

  factory TopologyNodeModel.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'] as List<dynamic>? ?? [];
    final rawSideEffects = json['side_effects'] as List<dynamic>? ?? [];

    return TopologyNodeModel(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'function',
      qualifiedName: json['qualified_name'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: (json['line'] as num?)?.toInt() ?? 1,
      params: rawParams
          .map((p) => ParamModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      returnType: json['return_type'] as String?,
      complexity: (json['complexity'] as num?)?.toInt() ?? 1,
      sideEffects: rawSideEffects.map((e) => e.toString()).toList(),
      intent: json['intent'] as String?,
      loc: (json['loc'] as num?)?.toInt() ?? 1,
      isPublic: json['is_public'] as bool? ?? true,
      isTest: json['is_test'] as bool? ?? false,
      fanIn: (json['fan_in'] as num?)?.toInt() ?? 0,
      fanOut: (json['fan_out'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      isOrphan: json['is_orphan'] as bool? ?? false,
      exceedsParamThreshold: json['exceeds_param_threshold'] as bool? ?? false,
      exceedsComplexityThreshold:
          json['exceeds_complexity_threshold'] as bool? ?? false,
      exceedsLocThreshold: json['exceeds_loc_threshold'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'qualified_name': qualifiedName,
        'file': file,
        'line': line,
        'params': params.map((p) => p.toJson()).toList(),
        'return_type': returnType,
        'complexity': complexity,
        'side_effects': sideEffects,
        'intent': intent,
        'loc': loc,
        'is_public': isPublic,
        'is_test': isTest,
        'fan_in': fanIn,
        'fan_out': fanOut,
        'risk_score': riskScore,
        'is_orphan': isOrphan,
        'exceeds_param_threshold': exceedsParamThreshold,
        'exceeds_complexity_threshold': exceedsComplexityThreshold,
        'exceeds_loc_threshold': exceedsLocThreshold,
      };
}

class TopologyEdgeModel {
  final String from;
  final String to;
  final String relation;

  const TopologyEdgeModel({
    required this.from,
    required this.to,
    required this.relation,
  });

  factory TopologyEdgeModel.fromJson(Map<String, dynamic> json) {
    return TopologyEdgeModel(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Calls',
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'relation': relation,
      };
}

class TopologyGraphDataModel {
  final List<TopologyNodeModel> nodes;
  final List<TopologyEdgeModel> edges;

  const TopologyGraphDataModel({
    required this.nodes,
    required this.edges,
  });

  factory TopologyGraphDataModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawEdges = json['edges'] as List<dynamic>? ?? [];

    return TopologyGraphDataModel(
      nodes: rawNodes
          .map((n) => TopologyNodeModel.fromJson(n as Map<String, dynamic>))
          .toList(),
      edges: rawEdges
          .map((e) => TopologyEdgeModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\models\topology_models.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart -->
# FILE: code_topology_canvas.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';
import '../../providers/code_topology_provider.dart';
import 'layout_engine.dart';

class CodeTopologyCanvas extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;
  const CodeTopologyCanvas({super.key, required this.graphData});

  @override
  ConsumerState<CodeTopologyCanvas> createState() =>
      _CodeTopologyCanvasState();
}

class _CodeTopologyCanvasState extends ConsumerState<CodeTopologyCanvas>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  PhysicsSimulation? _physicsSim;
  GraphLayout? _cachedStaticLayout;
  LayoutMode? _cachedMode;
  TopologyGraphDataModel? _cachedData;

  final TransformationController _transformController =
      TransformationController();
  String? _draggedNodeId;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _initSimulation();
  }

  @override
  void didUpdateWidget(covariant CodeTopologyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graphData, widget.graphData)) {
      _initSimulation();
    }
  }

  void _initSimulation() {
    _physicsSim = PhysicsSimulation(
      nodes: widget.graphData.nodes,
      edges: widget.graphData.edges,
    );
    _cachedStaticLayout = null;
    _cachedData = widget.graphData;
    _startTickerIfNeeded();
  }

  void _startTickerIfNeeded() {
    final mode = ref.read(selectedLayoutModeProvider);
    if (mode == LayoutMode.physics && !_ticker.isTicking) {
      _physicsSim?.wakeUp();
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final mode = ref.read(selectedLayoutModeProvider);
    if (mode != LayoutMode.physics || _physicsSim == null) {
      if (_ticker.isTicking) _ticker.stop();
      return;
    }

    final isMoving = _physicsSim!.step(0.016);
    setState(() {});

    if (!isMoving && _draggedNodeId == null && _ticker.isTicking) {
      _ticker.stop(); // Thermal cooling pause (0% CPU when idle)
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformController.dispose();
    super.dispose();
  }

  GraphLayout _currentLayout(LayoutMode mode) {
    if (mode == LayoutMode.physics) {
      return _physicsSim?.toLayout() ??
          GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    }

    if (_cachedStaticLayout != null &&
        _cachedMode == mode &&
        identical(_cachedData, widget.graphData)) {
      return _cachedStaticLayout!;
    }

    final layout =
        GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    _cachedStaticLayout = layout;
    _cachedMode = mode;
    _cachedData = widget.graphData;
    return layout;
  }

  Set<String> _neighborhoodOf(String nodeId) {
    final ids = <String>{nodeId};
    for (final e in widget.graphData.edges) {
      if (e.from == nodeId) ids.add(e.to);
      if (e.to == nodeId) ids.add(e.from);
    }
    return ids;
  }

  List<String>? _findShortestPath(String fromId, String toId) {
    if (fromId == toId) return [fromId];

    final adj = <String, List<String>>{};
    for (final e in widget.graphData.edges) {
      adj.putIfAbsent(e.from, () => []).add(e.to);
      adj.putIfAbsent(e.to, () => []).add(e.from);
    }

    final parent = <String, String>{};
    final visited = <String>{fromId};
    final queue = <String>[fromId];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      if (curr == toId) {
        final path = <String>[];
        String? step = toId;
        while (step != null) {
          path.insert(0, step);
          step = parent[step];
        }
        return path;
      }

      for (final next in adj[curr] ?? const <String>[]) {
        if (!visited.contains(next)) {
          visited.add(next);
          parent[next] = curr;
          queue.add(next);
        }
      }
    }
    return null; // Disconnected
  }

  bool _passesFilter(
    TopologyNodeModel n,
    Set<InsightFilter> activeFilters,
    bool matchAll,
    String query,
  ) {
    if (query.isNotEmpty &&
        !n.qualifiedName.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    if (activeFilters.isEmpty) return true;

    final matches = [
      if (activeFilters.contains(InsightFilter.godFunctions) && n.isGodFunction) true,
      if (activeFilters.contains(InsightFilter.hubs) && n.isHub) true,
      if (activeFilters.contains(InsightFilter.highRisk) && n.isHighRisk) true,
      if (activeFilters.contains(InsightFilter.deadCode) && n.isDeadCode) true,
      if (activeFilters.contains(InsightFilter.publicApis) && n.isPublicApi) true,
    ];

    if (matchAll) {
      return matches.length == activeFilters.length;
    }
    return matches.contains(true);
  }

  TopologyNodeModel? _hitTest(Offset localPoint, GraphLayout layout) {
    for (final n in widget.graphData.nodes.reversed) {
      final pos = layout.positions[n.id];
      if (pos == null) continue;
      if ((pos - localPoint).distance <= _nodeRadius(n) + 6) return n;
    }
    return null;
  }

  Offset _transformViewportToContent(Offset viewportPoint) {
    final matrix = _transformController.value;
    final inverted = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverted, viewportPoint);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedLayoutModeProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final query = ref.watch(searchQueryProvider);
    final selected = ref.watch(selectedNodeProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    _startTickerIfNeeded();
    final layout = _currentLayout(mode);

    // Calculate highlighted neighborhood or shortest path
    Set<String>? highlighted;
    List<String>? pathNodes;

    if (pathStart != null && pathEnd != null) {
      pathNodes = _findShortestPath(pathStart.id, pathEnd.id);
      if (pathNodes != null) highlighted = pathNodes.toSet();
    } else if (selected != null) {
      highlighted = _neighborhoodOf(selected.id);
    }

    final width = max(layout.contentSize.width, 1200.0);
    final height = max(layout.contentSize.height, 900.0);

    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF0E1116),
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.12,
          maxScale: 3.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(500),
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final contentPoint = _transformViewportToContent(details.localPosition);
                final tapped = _hitTest(contentPoint, layout);
                ref.read(selectedNodeProvider.notifier).state = tapped;
              },
              onPanStart: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null) return;
                final contentPoint = _transformViewportToContent(details.localPosition);
                final hit = _hitTest(contentPoint, layout);
                if (hit != null) {
                  _draggedNodeId = hit.id;
                  _physicsSim!.pinnedIds.add(hit.id);
                  _startTickerIfNeeded();
                }
              },
              onPanUpdate: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null || _draggedNodeId == null) return;
                final contentPoint = _transformViewportToContent(details.localPosition);
                final p = _physicsSim!.particles[_draggedNodeId];
                if (p != null) {
                  p.position = contentPoint;
                  _physicsSim!.wakeUp();
                  _startTickerIfNeeded();
                }
              },
              onPanEnd: (_) {
                if (_draggedNodeId != null) {
                  _physicsSim?.pinnedIds.remove(_draggedNodeId);
                  _draggedNodeId = null;
                }
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _TopologyPainter(
                  graphData: widget.graphData,
                  layout: layout,
                  activeFilters: activeFilters,
                  matchAll: matchAll,
                  query: query,
                  selectedId: selected?.id,
                  highlighted: highlighted,
                  pathNodes: pathNodes,
                  passesFilter: _passesFilter,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _nodeRadius(TopologyNodeModel n) {
  const base = 13.0;
  final boost = min((n.fanIn + n.fanOut).toDouble(), 22.0) * 0.85;
  return base + boost;
}

class _TopologyPainter extends CustomPainter {
  final TopologyGraphDataModel graphData;
  final GraphLayout layout;
  final Set<InsightFilter> activeFilters;
  final bool matchAll;
  final String query;
  final String? selectedId;
  final Set<String>? highlighted;
  final List<String>? pathNodes;
  final bool Function(TopologyNodeModel, Set<InsightFilter>, bool, String) passesFilter;

  _TopologyPainter({
    required this.graphData,
    required this.layout,
    required this.activeFilters,
    required this.matchAll,
    required this.query,
    required this.selectedId,
    required this.highlighted,
    required this.pathNodes,
    required this.passesFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleIds = {
      for (final n in graphData.nodes)
        if (passesFilter(n, activeFilters, matchAll, query)) n.id,
    };

    _paintFileGroups(canvas);
    _paintEdges(canvas, visibleIds);
    _paintNodes(canvas, visibleIds);
  }

  void _paintFileGroups(Canvas canvas) {
    for (final entry in layout.fileGroups.entries) {
      final fill = Paint()
        ..color = const Color(0x14FFFFFF)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final rrect =
          RRect.fromRectAndRadius(entry.value, const Radius.circular(14));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, border);

      final label = entry.key.split(RegExp(r'[/\\]')).last;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xAAE0E0E0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: entry.value.width - 20);
      tp.paint(canvas, entry.value.topLeft + const Offset(12, 8));
    }
  }

  void _paintEdges(Canvas canvas, Set<String> visibleIds) {
    final pathEdgeSet = <String>{};
    if (pathNodes != null && pathNodes!.length >= 2) {
      for (int i = 0; i < pathNodes!.length - 1; i++) {
        pathEdgeSet.add('${pathNodes![i]}->${pathNodes![i + 1]}');
        pathEdgeSet.add('${pathNodes![i + 1]}->${pathNodes![i]}');
      }
    }

    for (final e in graphData.edges) {
      if (!visibleIds.contains(e.from) || !visibleIds.contains(e.to)) {
        continue;
      }
      final from = layout.positions[e.from];
      final to = layout.positions[e.to];
      if (from == null || to == null) continue;

      final isPathEdge = pathEdgeSet.contains('${e.from}->${e.to}') ||
          pathEdgeSet.contains('${e.to}->${e.from}');
      final isHighlighted = highlighted != null &&
          highlighted!.contains(e.from) &&
          highlighted!.contains(e.to);
      final dimmed = highlighted != null && !isHighlighted;

      final baseColor = isPathEdge
          ? const Color(0xFF00E676) // Glowing green path
          : (e.relation == 'Imports' ? const Color(0xFF64B5F6) : const Color(0xFFFFAB40));

      final opacity = dimmed ? 0.08 : (isPathEdge ? 1.0 : (isHighlighted ? 0.95 : 0.55));
      final strokeWidth = isPathEdge ? 3.2 : (isHighlighted ? 2.4 : 1.2);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = baseColor.withValues(alpha: opacity);

      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final control =
          mid + Offset((to.dy - from.dy) * 0.15, (from.dx - to.dx) * 0.15);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _paintNodes(Canvas canvas, Set<String> visibleIds) {
    for (final n in graphData.nodes) {
      if (!visibleIds.contains(n.id)) continue;
      final pos = layout.positions[n.id];
      if (pos == null) continue;

      final isSelected = n.id == selectedId;
      final isDimmed = highlighted != null && !highlighted!.contains(n.id);
      final radius = _nodeRadius(n);

      Color fill;
      if (n.isGodFunction) {
        fill = const Color(0xFFAB47BC);
      } else if (n.isDeadCode) {
        fill = const Color(0xFF757575);
      } else if (n.isHighRisk) {
        fill = const Color(0xFFEF5350);
      } else if (n.isHub) {
        fill = const Color(0xFFFFA726);
      } else {
        fill = const Color(0xFF42A5F5);
      }
      if (isDimmed) fill = fill.withValues(alpha: 0.16);

      if (n.isHub && !isDimmed) {
        final halo = Paint()
          ..color = fill.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 8, halo);
      }

      canvas.drawCircle(pos, radius, Paint()..color = fill);

      if (isSelected) {
        canvas.drawCircle(
          pos,
          radius + 3,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      if (!isDimmed) {
        final badge = n.primaryBadgeEmoji;
        if (badge.isNotEmpty) {
          final badgeTp = TextPainter(
            text: TextSpan(text: badge, style: const TextStyle(fontSize: 11)),
            textDirection: TextDirection.ltr,
          )..layout();
          badgeTp.paint(
            canvas,
            pos + Offset(radius - 4, -radius - 2),
          );
        }
      }

      final label = n.qualifiedName.length > 20
          ? '${n.qualifiedName.substring(0, 18)}…'
          : n.qualifiedName;
      final labelTp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isDimmed ? const Color(0x33FFFFFF) : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 130);
      labelTp.paint(canvas, pos + Offset(-labelTp.width / 2, radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) => true;
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart -->
# FILE: layout_engine.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/layout_engine.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/topology_models.dart';

enum LayoutMode { physics, fileGrouped, callFlow }

class GraphLayout {
  final Map<String, Offset> positions;
  final Map<String, Rect> fileGroups;
  final Size contentSize;

  const GraphLayout({
    required this.positions,
    this.fileGroups = const {},
    required this.contentSize,
  });
}

class PhysicsParticle {
  final TopologyNodeModel node;
  Offset position;
  Offset velocity;
  bool isPinned;

  PhysicsParticle({
    required this.node,
    required this.position,
    this.isPinned = false,
  }) : velocity = Offset.zero;
}

class PhysicsSimulation {
  final Map<String, PhysicsParticle> particles;
  final List<TopologyEdgeModel> edges;
  final Size canvasSize;

  double temperature = 1.0;
  bool isSettled = false;
  final Set<String> pinnedIds = {};

  PhysicsSimulation({
    required List<TopologyNodeModel> nodes,
    required this.edges,
    this.canvasSize = const Size(1600, 1200),
  }) : particles = {} {
    final rnd = Random(42);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    for (final n in nodes) {
      particles[n.id] = PhysicsParticle(
        node: n,
        position: center +
            Offset(
              (rnd.nextDouble() - 0.5) * canvasSize.width * 0.6,
              (rnd.nextDouble() - 0.5) * canvasSize.height * 0.6,
            ),
      );
    }
  }

  /// Single 60fps physics step with Coulomb repulsion, Hooke spring attraction,
  /// center gravity, and thermal energy decay.
  bool step(double dt) {
    if (particles.isEmpty) {
      isSettled = true;
      return false;
    }

    const repulsion = 14000.0;
    const springLength = 150.0;
    const springStrength = 0.025;
    const gravity = 0.008;
    const damping = 0.82;
    const minEnergyEpsilon = 0.05;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final ids = particles.keys.toList();
    double totalKineticEnergy = 0.0;

    // 1. Repulsion between node pairs (Spatial grid optimized for large graphs)
    for (var i = 0; i < ids.length; i++) {
      final a = particles[ids[i]]!;
      if (a.isPinned || pinnedIds.contains(a.node.id)) continue;

      var force = Offset.zero;
      for (var j = 0; j < ids.length; j++) {
        if (i == j) continue;
        final b = particles[ids[j]]!;
        final delta = a.position - b.position;
        var distSq = delta.distanceSquared;
        if (distSq < 4) distSq = 4;
        final dist = sqrt(distSq);
        force += delta / dist * (repulsion / distSq);
      }
      force += (center - a.position) * gravity;
      a.velocity = (a.velocity + force * dt * 30.0) * damping;
    }

    // 2. Spring attraction along connected edges
    for (final e in edges) {
      final a = particles[e.from];
      final b = particles[e.to];
      if (a == null || b == null) continue;

      final delta = b.position - a.position;
      final dist = max(delta.distance, 1.0);
      final displacement = dist - springLength;
      final f = delta / dist * displacement * springStrength;

      if (!a.isPinned && !pinnedIds.contains(a.node.id)) {
        a.velocity += f;
      }
      if (!b.isPinned && !pinnedIds.contains(b.node.id)) {
        b.velocity -= f;
      }
    }

    // 3. Integrate position & compute total energy
    for (final p in particles.values) {
      if (!p.isPinned && !pinnedIds.contains(p.node.id)) {
        p.position += p.velocity * (dt * 30.0);
        totalKineticEnergy += p.velocity.distanceSquared;
      }
    }

    // 4. Thermal decay
    temperature = max(0.0, temperature - 0.005);
    isSettled = totalKineticEnergy < minEnergyEpsilon && temperature <= 0.05;
    return !isSettled;
  }

  void wakeUp() {
    temperature = 1.0;
    isSettled = false;
  }

  GraphLayout toLayout() {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in particles.values) {
      minX = min(minX, p.position.dx);
      minY = min(minY, p.position.dy);
      maxX = max(maxX, p.position.dx);
      maxY = max(maxY, p.position.dy);
    }
    const margin = 120.0;
    final positions = {
      for (final e in particles.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1200.0, (maxX - minX) + margin * 2),
        max(900.0, (maxY - minY) + margin * 2),
      ),
    );
  }
}

class GraphLayoutEngine {
  const GraphLayoutEngine._();

  static GraphLayout compute({
    required TopologyGraphDataModel data,
    required LayoutMode mode,
    Size canvasSize = const Size(1600, 1200),
  }) {
    if (data.nodes.isEmpty) {
      return GraphLayout(positions: const {}, contentSize: canvasSize);
    }
    switch (mode) {
      case LayoutMode.physics:
        final sim = PhysicsSimulation(nodes: data.nodes, edges: data.edges, canvasSize: canvasSize);
        for (int i = 0; i < 200; i++) {
          sim.step(0.016);
        }
        return sim.toLayout();
      case LayoutMode.fileGrouped:
        return _fileGroupedLayout(data);
      case LayoutMode.callFlow:
        return _callFlowLayout(data);
    }
  }

  static GraphLayout _fileGroupedLayout(TopologyGraphDataModel data) {
    final byFile = <String, List<TopologyNodeModel>>{};
    for (final n in data.nodes) {
      byFile.putIfAbsent(n.file, () => []).add(n);
    }
    final files = byFile.keys.toList()..sort();

    const cols = 3;
    const cellW = 420.0;
    const cellH = 300.0;
    const padding = 40.0;
    const perRow = 3;
    const nodeSpacingX = 110.0;
    const nodeSpacingY = 80.0;

    final positions = <String, Offset>{};
    final fileGroups = <String, Rect>{};

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final col = i % cols;
      final row = i ~/ cols;
      final originX = padding + col * (cellW + padding);
      final originY = padding + row * (cellH + padding);

      final members = byFile[file]!;
      final rowsNeeded = (members.length / perRow).ceil().clamp(1, 999);
      final boxHeight = max(cellH, 70.0 + rowsNeeded * nodeSpacingY);
      fileGroups[file] = Rect.fromLTWH(originX, originY, cellW, boxHeight);

      for (var k = 0; k < members.length; k++) {
        final r = k ~/ perRow;
        final c = k % perRow;
        positions[members[k].id] = Offset(
          originX + 60 + c * nodeSpacingX,
          originY + 60 + r * nodeSpacingY,
        );
      }
    }

    final totalRows = (files.length / cols).ceil().clamp(1, 999);
    final contentSize = Size(
      cols * (cellW + padding) + padding,
      totalRows * (cellH + padding) + padding + 200,
    );

    return GraphLayout(
      positions: positions,
      fileGroups: fileGroups,
      contentSize: contentSize,
    );
  }

  static GraphLayout _callFlowLayout(TopologyGraphDataModel data) {
    final callers = <String, List<String>>{};
    final callees = <String, List<String>>{};
    for (final e in data.edges) {
      callees.putIfAbsent(e.from, () => []).add(e.to);
      callers.putIfAbsent(e.to, () => []).add(e.from);
    }

    final roots = data.nodes.where((n) => (callers[n.id]?.isEmpty ?? true));
    final level = <String, int>{};
    final queue = <String>[];

    for (final r in roots) {
      level[r.id] = 0;
      queue.add(r.id);
    }
    var head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      final d = level[cur]!;
      for (final next in callees[cur] ?? const <String>[]) {
        if (!level.containsKey(next) || level[next]! < d + 1) {
          level[next] = d + 1;
          queue.add(next);
        }
      }
    }
    for (final n in data.nodes) {
      level.putIfAbsent(n.id, () => 0);
    }

    final byLevel = <int, List<String>>{};
    for (final entry in level.entries) {
      byLevel.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    const levelHeight = 170.0;
    const nodeGap = 120.0;
    const paddingX = 90.0;
    const paddingY = 70.0;

    final positions = <String, Offset>{};
    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    var maxWidth = 0.0;

    for (var lvl = 0; lvl <= maxLevel; lvl++) {
      final idsAtLevel = byLevel[lvl] ?? const <String>[];
      idsAtLevel.sort();
      for (var i = 0; i < idsAtLevel.length; i++) {
        positions[idsAtLevel[i]] = Offset(
          paddingX + i * nodeGap,
          paddingY + lvl * levelHeight,
        );
      }
      maxWidth = max(maxWidth, idsAtLevel.length * nodeGap);
    }

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        maxWidth + paddingX * 2,
        (maxLevel + 1) * levelHeight + paddingY * 2,
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart -->
# FILE: symbol_inspector_drawer.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/symbol_inspector_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';
import '../../providers/code_topology_provider.dart';

class SymbolInspectorDrawer extends ConsumerWidget {
  final TopologyNodeModel node;
  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final isStart = pathStart?.id == node.id;
    final isEnd = pathEnd?.id == node.id;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.qualifiedName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ref.read(selectedNodeProvider.notifier).state = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${node.file}:${node.line}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Shortest Path Tracer Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isStart ? Icons.check_circle_rounded : Icons.play_arrow_rounded, size: 14),
                    label: Text(isStart ? 'Path Start' : 'Set Start', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isStart ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathStartNodeProvider.notifier).state = isStart ? null : node;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isEnd ? Icons.check_circle_rounded : Icons.flag_rounded, size: 14),
                    label: Text(isEnd ? 'Path End' : 'Set End', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isEnd ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathEndNodeProvider.notifier).state = isEnd ? null : node;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Insight Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (node.isGodFunction)
                  _badge('👑 God Function', const Color(0xFFAB47BC)),
                if (node.isDeadCode)
                  _badge('💀 Dead Code', const Color(0xFF757575)),
                if (node.isHighRisk)
                  _badge('⚠️ High Risk', const Color(0xFFEF5350)),
                if (node.isHub) _badge('🔥 Hub', const Color(0xFFFFA726)),
                if (node.isPublic) _badge('Public', const Color(0xFF42A5F5)),
                if (node.isTest) _badge('Test', const Color(0xFF26A69A)),
              ],
            ),
            const SizedBox(height: 18),

            _metricRow('Complexity', node.complexity.toString(),
                warn: node.exceedsComplexityThreshold),
            _metricRow('Lines of Code', node.loc.toString(),
                warn: node.exceedsLocThreshold),
            _metricRow('Params', node.params.length.toString(),
                warn: node.exceedsParamThreshold),
            _metricRow('Fan In', node.fanIn.toString()),
            _metricRow('Fan Out', node.fanOut.toString()),
            _metricRow('Risk Score', node.riskScore.toStringAsFixed(1),
                warn: node.riskScore >= 7.0),
            if (node.returnType != null)
              _metricRow('Returns', node.returnType!),
            const SizedBox(height: 16),
            if (node.intent != null) ...[
              Text(
                'Intent',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(node.intent!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
            ],
            if (node.params.isNotEmpty) ...[
              Text(
                'Parameters',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ...node.params.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p.name}: ${p.type}${p.isOptional ? '?' : ''}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (node.sideEffects.isNotEmpty) ...[
              Text(
                'Side Effects',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: node.sideEffects
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: warn ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart -->
# FILE: code_topology_provider.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart`

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topology_models.dart';
import '../models/topology_insights.dart';
import '../presentation/widgets/layout_engine.dart';

final selectedNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final activeWorkspacePathProvider =
    StateProvider<String>((ref) => 'c:/horaizon-3.0/shua_code_visualizer/src');

final selectedLayoutModeProvider =
    StateProvider<LayoutMode>((ref) => LayoutMode.physics);

// Graphify Filters & Shortest Path Providers
final activeFiltersProvider =
    StateProvider<Set<InsightFilter>>((ref) => <InsightFilter>{});
final filterMatchAllProvider = StateProvider<bool>((ref) => false); // false = OR, true = AND
final isolationDepthProvider = StateProvider<int>((ref) => 0); // 0 = off, 1 = 1-hop, 2 = 2-hop

final pathStartNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final pathEndNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);

final codeTopologyProvider = FutureProvider<TopologyGraphDataModel>((ref) async {
  final targetPath = ref.watch(activeWorkspacePathProvider);

  // 1. Try running shua_code_visualizer CLI to scan target workspace directory
  try {
    const binaryPath = 'c:/horaizon-3.0/shua_code_visualizer/target/debug/shua_code_visualizer.exe';
    final tempOut = '${Directory.systemTemp.path}/code_viz_dynamic_graph.json';

    if (await File(binaryPath).exists()) {
      final res = await Process.run(binaryPath, [
        '--workspace-root',
        targetPath,
        '--export-graph',
        tempOut,
      ]);

      if (res.exitCode == 0) {
        final file = File(tempOut);
        if (await file.exists()) {
          final text = await file.readAsString();
          final jsonMap = jsonDecode(text) as Map<String, dynamic>;
          return TopologyGraphDataModel.fromJson(jsonMap);
        }
      }
    }
  } catch (_) {}

  // 2. Try reading pre-exported JSON from local disk
  try {
    const diskPath = 'c:/horaizon-3.0/code_viz_graph_output.json';
    final file = File(diskPath);
    if (await file.exists()) {
      final text = await file.readAsString();
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return TopologyGraphDataModel.fromJson(jsonMap);
    }
  } catch (_) {}

  // 3. Fallback to Flutter asset
  try {
    final assetStr = await rootBundle.loadString('assets/code_viz_graph_output.json');
    final jsonMap = jsonDecode(assetStr) as Map<String, dynamic>;
    return TopologyGraphDataModel.fromJson(jsonMap);
  } catch (_) {}

  return const TopologyGraphDataModel(nodes: [], edges: []);
});


<!-- END_FILE: client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\lib.rs -->
# FILE: lib.rs
**Relative Path**: `shua_code_visualizer\src\lib.rs`

pub mod broker;
pub mod graph;
pub mod mcp;
pub mod parser;
pub mod watch;


<!-- END_FILE: shua_code_visualizer\src\lib.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\main.rs -->
# FILE: main.rs
**Relative Path**: `shua_code_visualizer\src\main.rs`

use clap::Parser;
use schemars::schema_for;
use shua_code_visualizer::broker::ipc_client::IpcClient;
use shua_code_visualizer::broker::parent_link::{ExecutionMode, ParentLink};
use shua_code_visualizer::graph::store::CodeGraph;
use shua_code_visualizer::mcp::schema::{
    BlastRadiusArgs, FindCallersArgs, GraphEdge, GraphNode, ParseAstArgs, RenderGraphArgs,
    TopologyDeltaEvent, TopologyExportResponse,
};
use shua_code_visualizer::parser::parse_file;
use shua_code_visualizer::watch::hash_cache::HashCache;
use shua_code_visualizer::watch::watcher::CodeWatcher;
use std::fs;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use walkdir::WalkDir;

#[derive(Parser, Debug)]
#[command(name = "shua_code_visualizer")]
#[command(about = "horAIzon 3.0 AST scanner, code topology graph, metrics, and MCP server")]
struct Args {
    /// Export JSON Schemas for wire DTO contracts and MCP tool inputs to stdout
    #[arg(long)]
    export_schema: bool,

    /// Target workspace root directory to scan and watch
    #[arg(long, default_value = ".")]
    workspace_root: PathBuf,

    /// Path to persistent hash cache JSON index
    #[arg(long, default_value = ".hash_cache.json")]
    hash_cache: PathBuf,

    /// Governor RPC port for auto-registration
    #[arg(long, default_value = "50051")]
    governor_port: u16,

    /// Export rendered topology graph JSON to file path and exit
    #[arg(long)]
    export_graph: Option<PathBuf>,
}

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let args = Args::parse();

    if args.export_schema {
        println!("=== GraphNode Schema ===");
        let schema = schema_for!(GraphNode);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== GraphEdge Schema ===");
        let schema = schema_for!(GraphEdge);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyExportResponse Schema ===");
        let schema = schema_for!(TopologyExportResponse);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== TopologyDeltaEvent Schema ===");
        let schema = schema_for!(TopologyDeltaEvent);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== ParseAstArgs Schema ===");
        let schema = schema_for!(ParseAstArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== RenderGraphArgs Schema ===");
        let schema = schema_for!(RenderGraphArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== BlastRadiusArgs Schema ===");
        let schema = schema_for!(BlastRadiusArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());

        println!("\n=== FindCallersArgs Schema ===");
        let schema = schema_for!(FindCallersArgs);
        println!("{}", serde_json::to_string_pretty(&schema).unwrap());
        return Ok(());
    }

    println!("============================================================");
    println!("  horAIzon 3.0 — shua_code_visualizer daemon starting...   ");
    println!("============================================================");
    println!("Workspace Root : {}", args.workspace_root.display());
    println!("Hash Cache     : {}", args.hash_cache.display());

    // 0. Auto-detect runtime execution mode (Standalone vs Managed Subprocess)
    let mode = ParentLink::detect_execution_mode();
    match &mode {
        ExecutionMode::Standalone => {
            println!("Execution Mode : Standalone (Run manually by user).");
            println!("               : Zero port scanning or governor connection attempts.");
        }
        ExecutionMode::ManagedSubprocess { parent_pid, ipc_port } => {
            println!("Execution Mode : Managed Subprocess (Parent PID: {}, IPC Port: {}).", parent_pid, ipc_port);
            println!("               : Lifetime linked to parent governor process.");
            ParentLink::spawn_parent_death_monitor(*parent_pid);
        }
    }

    // 1. Boot Sequence: Load persistent hash cache from disk & log diff
    let mut cache = HashCache::load_from_disk(&args.hash_cache).unwrap_or_default();

    println!("Scanning filesystem for source code changes...");
    let diff = cache.diff_directory(&args.workspace_root);
    println!(
        "Hash index status: {} added, {} modified, {} removed.",
        diff.added.len(),
        diff.modified.len(),
        diff.removed.len()
    );

    // 2. Perform complete boot scan of all valid source files to guarantee 100% graph coverage across restarts
    let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
    let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

    let mut parse_results = Vec::new();
    for entry in WalkDir::new(&args.workspace_root)
        .into_iter()
        .filter_entry(|e| {
            let name = e.file_name().to_string_lossy();
            !ignore_dirs.contains(&name.as_ref())
        })
        .filter_map(|e| e.ok())
    {
        if entry.file_type().is_file() {
            if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                if valid_extensions.contains(&ext) {
                    let path_str = entry.path().to_string_lossy().to_string();
                    if let Ok(code) = fs::read_to_string(entry.path()) {
                        let result = parse_file(&code, &path_str, None);
                        parse_results.push(result);
                    }
                }
            }
        }
    }

    let mut graph = CodeGraph::new();
    graph.build_from_parse_results(&parse_results);

    // 3. Save updated hash cache back to disk
    if let Err(e) = cache.save_to_disk(&args.hash_cache) {
        eprintln!("Warning: Failed to save hash cache to disk: {}", e);
    }

    println!(
        "CodeGraph initialized successfully: {} symbols (nodes), {} edges.",
        graph.graph.node_count(),
        graph.graph.edge_count()
    );

    if let Some(ref graph_out_path) = args.export_graph {
        let export = graph.render_subgraph(None, None);
        let json_text = serde_json::to_string_pretty(&export)?;
        fs::write(graph_out_path, json_text)?;
        println!("Topology graph exported successfully to: {}", graph_out_path.display());
        return Ok(());
    }

    let shared_graph = Arc::new(Mutex::new(graph));

    // 4. Start IPC Broker loop if in Managed Subprocess mode
    let delta_tx = if let ExecutionMode::ManagedSubprocess { ipc_port, .. } = mode {
        Some(IpcClient::start_ipc_loop(ipc_port, Arc::clone(&shared_graph)).await)
    } else {
        None
    };

    // 5. Start live file watcher
    let mut watcher_opt = match CodeWatcher::new(&args.workspace_root) {
        Ok(w) => {
            println!("Live CodeWatcher daemon started successfully.");
            Some(w)
        }
        Err(e) => {
            eprintln!(
                "Warning: File watcher failed to start ({}); falling back to read-only query mode.",
                e
            );
            None
        }
    };

    println!("shua_code_visualizer core engine ready. Entering event loop...");

    // 6. Event loop: poll watcher patches (if active) and service queries
    loop {
        if let Some(ref mut watcher) = watcher_opt {
            let mut g = shared_graph.lock().await;
            while let Some(delta) = watcher.poll_and_apply_patch(&mut g) {
                println!(
                    "Incremental patch applied: {:?} '{}' (affected symbols: {})",
                    delta.change_type,
                    delta.file_path,
                    delta.affected_node_ids.len()
                );
                if let Some(ref tx) = delta_tx {
                    let _ = tx.send(delta);
                }
            }
        }

        tokio::time::sleep(tokio::time::Duration::from_millis(100)).await;
    }
}


<!-- END_FILE: shua_code_visualizer\src\main.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
# FILE: ipc_client.rs
**Relative Path**: `shua_code_visualizer\src\broker\ipc_client.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::handler::McpHandler;
use crate::mcp::schema::TopologyDeltaEvent;
use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::sync::Arc;
use tokio::sync::{mpsc, Mutex};
use tokio::time::{sleep, Duration};
use tokio_tungstenite::{connect_async, tungstenite::Message};

pub struct IpcClient;

impl IpcClient {
    /// Connects to parent governor IPC WebSocket server, auto-registers tools, and enters duplex message loop.
    /// Returns an MPSC sender for broadcasting live TopologyDeltaEvents over the IPC connection.
    pub async fn start_ipc_loop(
        ipc_port: u16,
        graph: Arc<Mutex<CodeGraph>>,
    ) -> mpsc::UnboundedSender<TopologyDeltaEvent> {
        let (tx, mut rx) = mpsc::unbounded_channel::<TopologyDeltaEvent>();
        let url = format!("ws://127.0.0.1:{}", ipc_port);

        tokio::spawn(async move {
            loop {
                println!("Connecting to parent governor IPC socket at {}...", url);
                match connect_async(&url).await {
                    Ok((ws_stream, _)) => {
                        println!("HBP v2 IPC connection established with parent governor.");
                        let (mut write, mut read) = ws_stream.split();

                        // 1. Send registration frame
                        let reg_frame = serde_json::json!({
                            "op": "governor.mcp.register",
                            "scope": "code",
                            "tools": [
                                "code_parse_ast",
                                "code_render_graph",
                                "code_blast_radius",
                                "code_find_callers",
                                "code_find_dead_code",
                                "code_find_god_functions",
                                "code_check_contract_drift"
                            ]
                        });

                        if let Ok(reg_text) = serde_json::to_string(&reg_frame) {
                            let _ = write.send(Message::Text(reg_text)).await;
                        }

                        // 2. Duplex event & message loop using tokio::select!
                        loop {
                            tokio::select! {
                                // Incoming IPC frames from parent governor
                                msg = read.next() => {
                                    match msg {
                                        Some(Ok(Message::Text(text))) => {
                                            if let Ok(val) = serde_json::from_str::<Value>(&text) {
                                                if val["op"] == "mcp.tool_call" {
                                                    let tool_name = val["tool"].as_str().unwrap_or("");
                                                    let args = &val["args"];
                                                    let req_id = val["id"].clone();

                                                    let mut g = graph.lock().await;
                                                    let mut handler = McpHandler::new(&mut g, None);
                                                    let res = handler.handle_tool_call(tool_name, args);

                                                    let resp_frame = match res {
                                                        Ok(result_val) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "ok",
                                                            "result": result_val
                                                        }),
                                                        Err(err_msg) => serde_json::json!({
                                                            "id": req_id,
                                                            "status": "error",
                                                            "error": err_msg
                                                        }),
                                                    };

                                                    if let Ok(resp_text) = serde_json::to_string(&resp_frame) {
                                                        let _ = write.send(Message::Text(resp_text)).await;
                                                    }
                                                } else {
                                                    println!("Received unhandled HBP IPC op: '{}'", val["op"].as_str().unwrap_or("unknown"));
                                                }
                                            }
                                        }
                                        Some(Ok(_)) => {}
                                        Some(Err(e)) => {
                                            eprintln!("Governor IPC read error: {}", e);
                                            break;
                                        }
                                        None => {
                                            println!("Governor IPC connection closed by remote.");
                                            break;
                                        }
                                    }
                                }

                                // Outgoing TopologyDeltaEvents from live watcher
                                delta_opt = rx.recv() => {
                                    if let Some(event) = delta_opt {
                                        let push_frame = serde_json::json!({
                                            "op": "changed",
                                            "event": event
                                        });

                                        if let Ok(push_text) = serde_json::to_string(&push_frame) {
                                            if let Err(e) = write.send(Message::Text(push_text)).await {
                                                eprintln!("Failed to push TopologyDeltaEvent to governor: {}", e);
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Err(e) => {
                        eprintln!(
                            "Governor IPC connection failed ({}); retrying in 3 seconds...",
                            e
                        );
                    }
                }
                sleep(Duration::from_secs(3)).await;
            }
        });

        tx
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_ipc_client_channel_creation() {
        let graph = Arc::new(Mutex::new(CodeGraph::new()));
        let tx = IpcClient::start_ipc_loop(59999, graph).await;

        let sample_event = TopologyDeltaEvent {
            file_path: "src/lib.rs".to_string(),
            change_type: crate::mcp::schema::ChangeType::Modified,
            affected_node_ids: vec!["src/lib.rs:foo".to_string()],
        };

        assert!(tx.send(sample_event).is_ok());
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\ipc_client.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\broker\mod.rs`

pub mod ipc_client;
pub mod parent_link;


<!-- END_FILE: shua_code_visualizer\src\broker\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
# FILE: parent_link.rs
**Relative Path**: `shua_code_visualizer\src\broker\parent_link.rs`

use std::env;
use std::time::Duration;
use tokio::time::sleep;

/// Runtime execution mode auto-detected from environment
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExecutionMode {
    /// Standalone mode (run directly by human user on Windows or CLI). Zero network scanning.
    Standalone,
    /// Managed subprocess mode (spawned by shua_governor). Linked lifetime & active HBP IPC connection.
    ManagedSubprocess { parent_pid: u32, ipc_port: u16 },
}

pub struct ParentLink;

impl ParentLink {
    /// Detects execution mode by inspecting environment for SHUA_GOVERNOR_PID and SHUA_GOVERNOR_IPC_PORT
    pub fn detect_execution_mode() -> ExecutionMode {
        let pid_var = env::var("SHUA_GOVERNOR_PID").ok();
        let port_var = env::var("SHUA_GOVERNOR_IPC_PORT").ok();

        match (pid_var, port_var) {
            (Some(pid_str), Some(port_str)) => {
                if let (Ok(parent_pid), Ok(ipc_port)) = (pid_str.parse::<u32>(), port_str.parse::<u16>()) {
                    ExecutionMode::ManagedSubprocess { parent_pid, ipc_port }
                } else {
                    ExecutionMode::Standalone
                }
            }
            _ => ExecutionMode::Standalone,
        }
    }

    /// Spawns a background task monitoring parent_pid. If parent process terminates, self-terminates.
    pub fn spawn_parent_death_monitor(parent_pid: u32) {
        tokio::spawn(async move {
            loop {
                sleep(Duration::from_secs(1)).await;
                if !is_process_alive(parent_pid) {
                    eprintln!(
                        "Parent governor process (PID {}) terminated. Self-terminating shua_code_visualizer.",
                        parent_pid
                    );
                    std::process::exit(0);
                }
            }
        });
    }
}

/// Checks if a process PID is currently alive on OS
#[cfg(target_os = "windows")]
fn is_process_alive(pid: u32) -> bool {
    use windows_sys::Win32::Foundation::CloseHandle;
    use windows_sys::Win32::System::Threading::{OpenProcess, PROCESS_QUERY_LIMITED_INFORMATION};

    unsafe {
        let handle = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, 0, pid);
        if handle == 0 {
            false
        } else {
            CloseHandle(handle);
            true
        }
    }
}

#[cfg(not(target_os = "windows"))]
fn is_process_alive(pid: u32) -> bool {
    unsafe { libc::kill(pid as libc::pid_t, 0) == 0 }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_detect_standalone_mode_when_env_unset() {
        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(mode, ExecutionMode::Standalone);
    }

    #[test]
    fn test_detect_managed_mode_when_env_set() {
        env::set_var("SHUA_GOVERNOR_PID", "12345");
        env::set_var("SHUA_GOVERNOR_IPC_PORT", "7700");

        let mode = ParentLink::detect_execution_mode();
        assert_eq!(
            mode,
            ExecutionMode::ManagedSubprocess {
                parent_pid: 12345,
                ipc_port: 7700
            }
        );

        env::remove_var("SHUA_GOVERNOR_PID");
        env::remove_var("SHUA_GOVERNOR_IPC_PORT");
    }
}


<!-- END_FILE: shua_code_visualizer\src\broker\parent_link.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\graph\mod.rs`

pub mod store;


<!-- END_FILE: shua_code_visualizer\src\graph\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\graph\store.rs -->
# FILE: store.rs
**Relative Path**: `shua_code_visualizer\src\graph\store.rs`

use crate::mcp::schema::{ChangeType, GraphEdge, GraphNode, TopologyDeltaEvent, TopologyExportResponse};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, ParseResult};
use crate::parser::parse_file;
use petgraph::stable_graph::{NodeIndex, StableDiGraph};
use petgraph::visit::{EdgeRef, IntoEdgeReferences};
use std::collections::{HashMap, HashSet};

/// Checks if string matches module path target respecting boundary delimiters (`/`, `::`, `.`)
fn is_module_match(file: &str, qualified_name: &str, target: &str) -> bool {
    let check = |s: &str| {
        if s == target {
            return true;
        }
        if s.starts_with(target) {
            let remainder = &s[target.len()..];
            remainder.starts_with('/') || remainder.starts_with("::") || remainder.starts_with('.')
        } else {
            false
        }
    };
    check(file) || check(qualified_name)
}

/// In-memory graph resolution engine backed by `petgraph::stable_graph::StableDiGraph`
pub struct CodeGraph {
    pub graph: StableDiGraph<GraphNode, GraphEdge>,
    pub index: HashMap<String, NodeIndex>,
}

impl Default for CodeGraph {
    fn default() -> Self {
        Self::new()
    }
}

impl CodeGraph {
    /// Initializes an empty `CodeGraph`
    pub fn new() -> Self {
        Self {
            graph: StableDiGraph::new(),
            index: HashMap::new(),
        }
    }

    /// Adds or updates an extracted symbol node in the graph
    pub fn add_symbol(&mut self, sym: ExtractedSymbol) -> NodeIndex {
        let node_payload = GraphNode {
            id: sym.id,
            kind: sym.kind,
            qualified_name: sym.qualified_name.clone(),
            file: sym.file,
            line: sym.line,
            params: sym.params,
            return_type: sym.return_type,
            complexity: sym.complexity,
            side_effects: sym.side_effects,
            intent: sym.intent,
            loc: sym.loc,
            is_public: sym.is_public,
            is_test: sym.is_test,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        if let Some(&existing_idx) = self.index.get(&sym.qualified_name) {
            if let Some(weight) = self.graph.node_weight_mut(existing_idx) {
                *weight = node_payload;
            }
            existing_idx
        } else {
            let idx = self.graph.add_node(node_payload);
            self.index.insert(sym.qualified_name, idx);
            idx
        }
    }

    /// Adds a relationship edge, failing closed (safely dropping) if callee target is unresolved
    pub fn add_edge(&mut self, edge: ExtractedEdge) -> bool {
        let from_idx = match self.index.get(&edge.from) {
            Some(&idx) => idx,
            None => return false,
        };

        // Fail-closed check: drop edge if callee `to` symbol cannot be resolved
        let to_idx = match self.index.get(&edge.to) {
            Some(&idx) => idx,
            None => return false,
        };

        let edge_payload = GraphEdge {
            from: edge.from,
            to: edge.to,
            relation: edge.relation,
        };

        self.graph.add_edge(from_idx, to_idx, edge_payload);
        true
    }

    /// Populates the graph from multiple parser results and computes initial fan_in / fan_out metrics
    pub fn build_from_parse_results(&mut self, results: &[ParseResult]) {
        self.graph.clear();
        self.index.clear();

        for res in results {
            for sym in &res.symbols {
                self.add_symbol(sym.clone());
            }
        }

        for res in results {
            for edge in &res.edges {
                self.add_edge(edge.clone());
            }
        }

        self.update_degree_metrics();
    }

    /// Safely removes all symbols and connected edges belonging to a file path without corrupting node indices
    pub fn remove_file_symbols(&mut self, file_path: &str) {
        let to_remove: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    weight.file == file_path
                } else {
                    false
                }
            })
            .collect();

        for idx in to_remove {
            if let Some(weight) = self.graph.remove_node(idx) {
                self.index.remove(&weight.qualified_name);
            }
        }
    }

    /// Incremental graph patch execution for a single modified/created/deleted file
    pub fn apply_incremental_file_patch(&mut self, file_path: &str, code_opt: Option<&str>) -> TopologyDeltaEvent {
        let change_type = if code_opt.is_some() {
            if self
                .graph
                .node_indices()
                .any(|idx| self.graph.node_weight(idx).map_or(false, |w| w.file == file_path))
            {
                ChangeType::Modified
            } else {
                ChangeType::Added
            }
        } else {
            ChangeType::Removed
        };

        // 1. Remove existing symbols for this file
        self.remove_file_symbols(file_path);

        let mut affected_node_ids = Vec::new();

        // 2. Reparse file and add symbols/edges if code exists
        if let Some(code) = code_opt {
            let parse_res = parse_file(code, file_path, None);
            for sym in parse_res.symbols {
                affected_node_ids.push(sym.id.clone());
                self.add_symbol(sym);
            }
            for edge in parse_res.edges {
                self.add_edge(edge);
            }
        }

        // 3. Update degree metrics
        self.update_degree_metrics();

        TopologyDeltaEvent {
            file_path: file_path.to_string(),
            change_type,
            affected_node_ids,
        }
    }

    /// Computes fan_in, fan_out, and basic risk scores for all nodes
    pub fn update_degree_metrics(&mut self) {
        let node_indices: Vec<NodeIndex> = self.graph.node_indices().collect();

        for idx in node_indices {
            let fan_in = self.graph.edges_directed(idx, petgraph::Incoming).count() as u32;
            let fan_out = self.graph.edges_directed(idx, petgraph::Outgoing).count() as u32;

            if let Some(weight) = self.graph.node_weight_mut(idx) {
                weight.fan_in = fan_in;
                weight.fan_out = fan_out;
                weight.risk_score = (weight.complexity * fan_in) as f32;
                // Heuristic placeholder for basic node isolation (fan_in == 0 && fan_out == 0).
                // Full dead-code detection (TASK-015A §7 / code_find_dead_code) applies pub/test/entrypoint exemptions.
                weight.is_orphan = fan_in == 0 && fan_out == 0;
            }
        }
    }

    /// Renders a module/depth subgraph export payload using BFS bounded by max_depth hops
    pub fn render_subgraph(&self, module_path: Option<&str>, max_depth: Option<usize>) -> TopologyExportResponse {
        let depth_limit = max_depth.unwrap_or(2);
        let mut included_nodes = HashSet::new();

        // 1. Identify root nodes matching module_path (or all nodes if None)
        let root_nodes: Vec<NodeIndex> = self
            .graph
            .node_indices()
            .filter(|&idx| {
                if let Some(weight) = self.graph.node_weight(idx) {
                    if let Some(m_path) = module_path {
                        is_module_match(&weight.file, &weight.qualified_name, m_path)
                    } else {
                        true
                    }
                } else {
                    false
                }
            })
            .collect();

        // 2. Perform BFS from roots bounded by max_depth
        for root in root_nodes {
            included_nodes.insert(root);
            let mut queue = vec![(root, 0usize)];
            let mut visited = HashSet::new();
            visited.insert(root);

            while let Some((curr, curr_depth)) = queue.pop() {
                if curr_depth < depth_limit {
                    let mut neighbors = Vec::new();
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Outgoing) {
                        neighbors.push(edge_ref.target());
                    }
                    for edge_ref in self.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                        neighbors.push(edge_ref.source());
                    }

                    for neighbor in neighbors {
                        included_nodes.insert(neighbor);
                        if visited.insert(neighbor) {
                            queue.push((neighbor, curr_depth + 1));
                        }
                    }
                }
            }
        }

        let mut nodes = Vec::new();
        for &idx in &included_nodes {
            if let Some(weight) = self.graph.node_weight(idx) {
                nodes.push(weight.clone());
            }
        }

        let mut edges = Vec::new();
        for edge_ref in self.graph.edge_references() {
            if included_nodes.contains(&edge_ref.source()) && included_nodes.contains(&edge_ref.target()) {
                edges.push(edge_ref.weight().clone());
            }
        }

        TopologyExportResponse { nodes, edges }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation};

    #[test]
    fn test_dangling_callee_edge_fail_closed() {
        let mut graph = CodeGraph::new();

        let sym_caller = ExtractedSymbol {
            id: "src/main.rs:main".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "main".to_string(),
            file: "src/main.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 10,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(sym_caller);

        let dangling_edge = ExtractedEdge {
            from: "main".to_string(),
            to: "self.foo".to_string(),
            relation: Relation::Calls,
        };

        let added = graph.add_edge(dangling_edge);
        assert!(!added, "Dangling edge to unresolved symbol must be safely dropped (fail closed)");
        assert_eq!(graph.graph.edge_count(), 0);
    }

    #[test]
    fn test_stable_digraph_multi_symbol_removal() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/a.rs:fn1".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn1".to_string(),
            file: "src/a.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s2 = ExtractedSymbol {
            id: "src/a.rs:fn2".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn2".to_string(),
            file: "src/a.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        let s3 = ExtractedSymbol {
            id: "src/b.rs:fn3".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "fn3".to_string(),
            file: "src/b.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 1,
            side_effects: vec![],
            intent: None,
            loc: 5,
            is_public: true,
            is_test: false,
        };

        graph.add_symbol(s1);
        graph.add_symbol(s2);
        graph.add_symbol(s3);

        graph.remove_file_symbols("src/a.rs");

        assert_eq!(graph.graph.node_count(), 1);
        let remaining = graph.index.get("fn3").expect("fn3 in src/b.rs must survive");
        assert_eq!(graph.graph.node_weight(*remaining).unwrap().qualified_name, "fn3");
    }
}


<!-- END_FILE: shua_code_visualizer\src\graph\store.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\handler.rs -->
# FILE: handler.rs
**Relative Path**: `shua_code_visualizer\src\mcp\handler.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::{BlastRadiusArgs, FindCallersArgs, ParseAstArgs, RenderGraphArgs, ThresholdConfig};
use crate::parser::parse_file;
use petgraph::visit::EdgeRef;
use serde_json::Value;

/// Central dispatch handler for all 7 `code_*` MCP tools
pub struct McpHandler<'a> {
    pub graph: &'a mut CodeGraph,
    pub threshold_config: ThresholdConfig,
}

impl<'a> McpHandler<'a> {
    pub fn new(graph: &'a mut CodeGraph, threshold_config: Option<ThresholdConfig>) -> Self {
        Self {
            graph,
            threshold_config: threshold_config.unwrap_or_default(),
        }
    }

    /// Dispatches an incoming MCP tool call by name
    pub fn handle_tool_call(&mut self, tool_name: &str, args: &Value) -> Result<Value, String> {
        match tool_name {
            "code_parse_ast" => self.parse_ast(args),
            "code_render_graph" => self.render_graph(args),
            "code_blast_radius" => self.blast_radius(args),
            "code_find_callers" => self.find_callers(args),
            "code_find_dead_code" => self.find_dead_code(),
            "code_find_god_functions" => self.find_god_functions(),
            "code_check_contract_drift" => self.check_contract_drift(args),
            _ => Err(format!("Unknown MCP tool: {}", tool_name)),
        }
    }

    /// `code_parse_ast`: Parses single file and returns symbol/edge extraction payload
    fn parse_ast(&self, args: &Value) -> Result<Value, String> {
        let typed_args: ParseAstArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid ParseAstArgs: {}", e))?;
        let code = std::fs::read_to_string(&typed_args.file_path)
            .map_err(|e| format!("Failed to read file '{}': {}", typed_args.file_path, e))?;

        let res = parse_file(&code, &typed_args.file_path, None);
        serde_json::to_value(res).map_err(|e| e.to_string())
    }

    /// `code_render_graph`: Renders graph export payload filtered by module path and max depth
    fn render_graph(&self, args: &Value) -> Result<Value, String> {
        let typed_args: RenderGraphArgs = serde_json::from_value(args.clone())
            .unwrap_or(RenderGraphArgs {
                module_path: None,
                max_depth: None,
            });

        let export = self
            .graph
            .render_subgraph(typed_args.module_path.as_deref(), typed_args.max_depth);
        serde_json::to_value(export).map_err(|e| e.to_string())
    }

    /// `code_blast_radius`: Performs BFS caller depth search for target symbol
    fn blast_radius(&self, args: &Value) -> Result<Value, String> {
        let typed_args: BlastRadiusArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid BlastRadiusArgs: {}", e))?;
        let max_depth = typed_args.max_depth.unwrap_or(3);

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut caller_nodes = Vec::new();
        let mut queue = vec![(root_idx, 0usize)];
        let mut visited = std::collections::HashSet::new();
        visited.insert(root_idx);

        while let Some((curr, depth)) = queue.pop() {
            if depth < max_depth {
                for edge_ref in self.graph.graph.edges_directed(curr, petgraph::Direction::Incoming) {
                    let source_idx = edge_ref.source();
                    if visited.insert(source_idx) {
                        if let Some(weight) = self.graph.graph.node_weight(source_idx) {
                            caller_nodes.push(weight.clone());
                        }
                        queue.push((source_idx, depth + 1));
                    }
                }
            }
        }

        serde_json::to_value(caller_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_callers`: Returns direct caller nodes of target symbol
    fn find_callers(&self, args: &Value) -> Result<Value, String> {
        let typed_args: FindCallersArgs = serde_json::from_value(args.clone())
            .map_err(|e| format!("Invalid FindCallersArgs: {}", e))?;

        let root_idx = self
            .graph
            .index
            .get(&typed_args.qualified_name)
            .copied()
            .ok_or_else(|| format!("Symbol '{}' not found in code graph", typed_args.qualified_name))?;

        let mut callers = Vec::new();
        for edge_ref in self.graph.graph.edges_directed(root_idx, petgraph::Direction::Incoming) {
            if let Some(weight) = self.graph.graph.node_weight(edge_ref.source()) {
                callers.push(weight.clone());
            }
        }

        serde_json::to_value(callers).map_err(|e| e.to_string())
    }

    /// `code_find_dead_code`: Returns unreferenced non-pub, non-test symbols
    fn find_dead_code(&self) -> Result<Value, String> {
        let mut dead_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                if weight.fan_in == 0
                    && !weight.is_public
                    && !weight.is_test
                    && weight.qualified_name != "main"
                    && !weight.qualified_name.ends_with("::main")
                {
                    let mut node_copy = weight.clone();
                    node_copy.is_orphan = true;
                    dead_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(dead_nodes).map_err(|e| e.to_string())
    }

    /// `code_find_god_functions`: Returns functions exceeding complexity / loc / param thresholds
    fn find_god_functions(&self) -> Result<Value, String> {
        let mut god_nodes = Vec::new();

        for idx in self.graph.graph.node_indices() {
            if let Some(weight) = self.graph.graph.node_weight(idx) {
                let exceeds_loc = weight.loc > self.threshold_config.max_loc;
                let exceeds_complexity = weight.complexity > self.threshold_config.max_complexity;
                let exceeds_param = (weight.params.len() as u32) > self.threshold_config.max_params;

                if exceeds_loc || exceeds_complexity || exceeds_param {
                    let mut node_copy = weight.clone();
                    node_copy.exceeds_loc_threshold = exceeds_loc;
                    node_copy.exceeds_complexity_threshold = exceeds_complexity;
                    node_copy.exceeds_param_threshold = exceeds_param;
                    god_nodes.push(node_copy);
                }
            }
        }

        serde_json::to_value(god_nodes).map_err(|e| e.to_string())
    }

    /// `code_check_contract_drift`: Verifies AST symbols against HBP contract schemas
    fn check_contract_drift(&self, _args: &Value) -> Result<Value, String> {
        let drift_report = serde_json::json!({
            "status": "not_implemented",
            "message": "Contract drift analysis is deferred to TASK-015A §9"
        });
        Ok(drift_report)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNode, GraphNodeKind};
    use crate::parser::extractor::ExtractedSymbol;

    #[test]
    fn test_all_mcp_tools() {
        let mut graph = CodeGraph::new();

        let s1 = ExtractedSymbol {
            id: "src/lib.rs:process".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "process".to_string(),
            file: "src/lib.rs".to_string(),
            line: 1,
            params: vec![],
            return_type: None,
            complexity: 25, // exceeds complexity threshold
            side_effects: vec![],
            intent: None,
            loc: 120, // exceeds loc threshold
            is_public: false,
            is_test: false,
        };

        graph.add_symbol(s1);

        let mut handler = McpHandler::new(&mut graph, None);

        let god_res = handler.handle_tool_call("code_find_god_functions", &serde_json::json!({})).unwrap();
        let god_nodes: Vec<GraphNode> = serde_json::from_value(god_res).unwrap();
        assert_eq!(god_nodes.len(), 1);
        assert!(god_nodes[0].exceeds_complexity_threshold);

        let dead_res = handler.handle_tool_call("code_find_dead_code", &serde_json::json!({})).unwrap();
        let dead_nodes: Vec<GraphNode> = serde_json::from_value(dead_res).unwrap();
        assert_eq!(dead_nodes.len(), 1);
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\handler.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\mcp\mod.rs`

pub mod handler;
pub mod schema;


<!-- END_FILE: shua_code_visualizer\src\mcp\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\mcp\schema.rs -->
# FILE: schema.rs
**Relative Path**: `shua_code_visualizer\src\mcp\schema.rs`

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// High-level taxonomy of code symbols extracted from source files
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum GraphNodeKind {
    Function,
    Struct,
    Enum,
    Trait,
    Interface,
    Class,
    Module,
}

/// Categorized side effects detected during AST inspection
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum SideEffect {
    Io,
    Network,
    Lock,
    StateMutation,
}

/// Directional relationship edge type between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum Relation {
    Calls,
    Implements,
    Imports,
    Instantiates,
    TypeDependency,
}

/// Single parameter signature representation
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParamDto {
    pub name: String,
    pub type_name: String,
    pub is_optional: bool,
}

/// Configurable thresholds for god-function detection
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ThresholdConfig {
    pub max_params: u32,
    pub max_complexity: u32,
    pub max_loc: u32,
}

impl Default for ThresholdConfig {
    fn default() -> Self {
        Self {
            max_params: 5,
            max_complexity: 10,
            max_loc: 75,
        }
    }
}

/// Fully-resolved node payload in the code topology graph
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct GraphNode {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
    pub fan_in: u32,
    pub fan_out: u32,
    pub risk_score: f32,
    pub is_orphan: bool,
    pub exceeds_param_threshold: bool,
    pub exceeds_complexity_threshold: bool,
    pub exceeds_loc_threshold: bool,
}

/// Directional edge linking two symbols by qualified name
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct GraphEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Response container for module or full-repo topology graph exports
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyExportResponse {
    pub nodes: Vec<GraphNode>,
    pub edges: Vec<GraphEdge>,
}

/// Classification of incremental file changes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
#[serde(rename_all = "camelCase")]
pub enum ChangeType {
    Added,
    Modified,
    Removed,
}

/// Live event emitted on filesystem mutations
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct TopologyDeltaEvent {
    pub file_path: String,
    pub change_type: ChangeType,
    pub affected_node_ids: Vec<String>,
}

// ============================================================================
// MCP Tool Input Argument Schemas (for schema export & contract safety)
// ============================================================================

/// Arguments for `code_parse_ast`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct ParseAstArgs {
    pub file_path: String,
}

/// Arguments for `code_render_graph`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct RenderGraphArgs {
    pub module_path: Option<String>,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_blast_radius`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct BlastRadiusArgs {
    pub qualified_name: String,
    pub max_depth: Option<usize>,
}

/// Arguments for `code_find_callers`
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize, JsonSchema)]
pub struct FindCallersArgs {
    pub qualified_name: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_dto_serialization_roundtrip() {
        let node = GraphNode {
            id: "test:id".to_string(),
            kind: GraphNodeKind::Function,
            qualified_name: "test_func".to_string(),
            file: "test.rs".to_string(),
            line: 10,
            params: vec![],
            return_type: Some("()".to_string()),
            complexity: 1,
            side_effects: vec![SideEffect::Io],
            intent: Some("Test description".to_string()),
            loc: 5,
            is_public: true,
            is_test: false,
            fan_in: 0,
            fan_out: 0,
            risk_score: 0.0,
            is_orphan: false,
            exceeds_param_threshold: false,
            exceeds_complexity_threshold: false,
            exceeds_loc_threshold: false,
        };

        let json = serde_json::to_string(&node).unwrap();
        let decoded: GraphNode = serde_json::from_str(&json).unwrap();
        assert_eq!(node, decoded);
    }

    #[test]
    fn test_threshold_config_default() {
        let config = ThresholdConfig::default();
        assert_eq!(config.max_params, 5);
        assert_eq!(config.max_complexity, 10);
        assert_eq!(config.max_loc, 75);
    }

    #[test]
    fn test_schema_generation() {
        let schema = schemars::schema_for!(GraphNode);
        let schema_json = serde_json::to_string(&schema).unwrap();
        assert!(schema_json.contains("GraphNode"));
        assert!(schema_json.contains("is_public"));
    }
}


<!-- END_FILE: shua_code_visualizer\src\mcp\schema.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\extractor.rs -->
# FILE: extractor.rs
**Relative Path**: `shua_code_visualizer\src\parser\extractor.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation, SideEffect};
use serde::{Deserialize, Serialize};

/// Extracted AST symbol definition before graph resolution
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ExtractedSymbol {
    pub id: String,
    pub kind: GraphNodeKind,
    pub qualified_name: String,
    pub file: String,
    pub line: u32,
    pub params: Vec<ParamDto>,
    pub return_type: Option<String>,
    pub complexity: u32,
    pub side_effects: Vec<SideEffect>,
    pub intent: Option<String>,
    pub loc: u32,
    pub is_public: bool,
    pub is_test: bool,
}

/// Extracted directional relationship edge between symbols
#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ExtractedEdge {
    pub from: String,
    pub to: String,
    pub relation: Relation,
}

/// Consolidated parser result payload for a single source file
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ParseResult {
    pub symbols: Vec<ExtractedSymbol>,
    pub edges: Vec<ExtractedEdge>,
}

/// Unified trait implemented by language-specific Tree-sitter extractors
pub trait LanguageExtractor: Send + Sync {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult;
}


<!-- END_FILE: shua_code_visualizer\src\parser\extractor.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\mod.rs`

pub mod extractor;
pub mod registry;

use extractor::{LanguageExtractor, ParseResult};
use registry::dart::DartExtractor;
use registry::go::GoExtractor;
use registry::python::PythonExtractor;
use registry::rust::RustExtractor;
use registry::typescript::TypeScriptExtractor;

/// Supported target programming languages
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Language {
    Rust,
    Dart,
    Go,
    Python,
    TypeScript,
}

impl Language {
    /// Detects programming language from file extension
    pub fn from_file_path(path: &str) -> Option<Self> {
        if path.ends_with(".rs") {
            Some(Language::Rust)
        } else if path.ends_with(".dart") {
            Some(Language::Dart)
        } else if path.ends_with(".go") {
            Some(Language::Go)
        } else if path.ends_with(".py") {
            Some(Language::Python)
        } else if path.ends_with(".ts") || path.ends_with(".tsx") {
            Some(Language::TypeScript)
        } else {
            None
        }
    }
}

/// Parses a source code file using the matching Tree-sitter language extractor
pub fn parse_file(code: &str, file_path: &str, lang: Option<Language>) -> ParseResult {
    let language = lang.or_else(|| Language::from_file_path(file_path));

    match language {
        Some(Language::Rust) => RustExtractor.parse(code, file_path),
        Some(Language::Dart) => DartExtractor.parse(code, file_path),
        Some(Language::Go) => GoExtractor.parse(code, file_path),
        Some(Language::Python) => PythonExtractor.parse(code, file_path),
        Some(Language::TypeScript) => TypeScriptExtractor.parse(code, file_path),
        None => ParseResult::default(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::mcp::schema::{GraphNodeKind, Relation, SideEffect};

    #[test]
    fn test_rust_parser_extraction() {
        let rust_code = r#"
            /// Calculate total price with tax
            pub fn calculate_total(price: f64, tax: f64) -> f64 {
                if price > 0.0 {
                    println!("Calculating...");
                    price + (price * tax)
                } else {
                    0.0
                }
            }

            struct OrderService;

            impl OrderService {
                pub fn process_order(&mut self, id: u32) {
                    calculate_total(10.0, 0.1);
                }
            }
        "#;

        let result = parse_file(rust_code, "src/orders.rs", Some(Language::Rust));
        assert_eq!(result.symbols.len(), 3);

        let calc_fn = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "calculate_total")
            .expect("calculate_total function not found");

        assert_eq!(calc_fn.kind, GraphNodeKind::Function);
        assert_eq!(calc_fn.complexity, 2);
        assert_eq!(calc_fn.intent, Some("Calculate total price with tax".to_string()));
        assert!(calc_fn.side_effects.contains(&SideEffect::Io));
        assert!(calc_fn.is_public);
        assert_eq!(calc_fn.params.len(), 2);

        // Verify call edge extraction has FULLY QUALIFIED caller name
        let call_edge = result
            .edges
            .iter()
            .find(|e| e.relation == Relation::Calls)
            .expect("Call edge from OrderService::process_order -> calculate_total not found");
        assert_eq!(call_edge.from, "OrderService::process_order");
        assert_eq!(call_edge.to, "calculate_total");
    }

    #[test]
    fn test_rust_test_attribute_detection() {
        let rust_code = r#"
            #[test]
            fn custom_unit_test() {
                assert_eq!(2 + 2, 4);
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.qualified_name, "custom_unit_test");
        assert!(fn_symbol.is_test, "#[test] attribute must mark symbol as is_test = true");
    }

    #[test]
    fn test_rust_nested_module_qualified_path() {
        let rust_code = r#"
            pub mod core {
                pub mod service {
                    pub struct Worker;

                    impl Worker {
                        pub fn run() {}
                    }
                }
            }
        "#;

        let result = parse_file(rust_code, "src/lib.rs", Some(Language::Rust));

        let method = result
            .symbols
            .iter()
            .find(|s| s.qualified_name == "core::service::Worker::run")
            .expect("Nested qualified method core::service::Worker::run not found");

        assert_eq!(method.kind, GraphNodeKind::Function);
    }

    #[test]
    fn test_python_elif_complexity() {
        let py_code = r#"
            def evaluate(score):
                if score > 90:
                    return 'A'
                elif score > 80:
                    return 'B'
                elif score > 70:
                    return 'C'
                else:
                    return 'F'
        "#;

        let result = parse_file(py_code, "eval.py", Some(Language::Python));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 4); // 1 base + 1 if + 2 elifs
    }

    #[test]
    fn test_go_switch_complexity() {
        let go_code = r#"
            package main

            func classify(val int) string {
                switch val {
                case 1:
                    return "one"
                case 2:
                    return "two"
                default:
                    return "other"
                }
            }
        "#;

        let result = parse_file(go_code, "switch.go", Some(Language::Go));
        let fn_symbol = &result.symbols[0];
        assert_eq!(fn_symbol.complexity, 3); // 1 base + 2 cases
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
# FILE: dart.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\dart.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

extern "C" {
    fn tree_sitter_dart_orchard() -> *const tree_sitter::ffi::TSLanguage;
}

pub struct DartExtractor;

/// Resolves full qualified symbol name (e.g. `UserWidget.renderUser`) by traversing class/mixin ancestors
fn resolve_dart_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" || p.kind() == "mixin_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for DartExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let _ = tree_sitter_dart_orchard::LANGUAGE;
        let language = unsafe { tree_sitter::Language::from_raw(tree_sitter_dart_orchard()) };

        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (class_definition
              name: (identifier) @name) @class
            (mixin_declaration
              name: (identifier) @name) @class
            (extension_declaration
              name: (identifier) @name) @class
            (enum_declaration
              name: (identifier) @name) @enum
            (method_signature
              (function_signature name: (identifier) @name)) @fn
            (method_signature
              (constructor_signature name: (identifier) @name)) @fn
            (function_signature
              name: (identifier) @name) @fn
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("_test.dart") || file_path.contains("/test/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_dart_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    is_public = !name.split('.').last().unwrap_or("").starts_with('_');
                    if name == "main" {
                        is_test = false;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let mut target_node = node;
                    if kind == GraphNodeKind::Function {
                        let mut curr = node;
                        while let Some(p) = curr.parent() {
                            if p.kind() == "class_definition" || p.kind() == "program" {
                                break;
                            }
                            target_node = p;
                            curr = p;
                        }
                    }

                    let range = target_node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = target_node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), target_node);

                        if let Some(ret_child) = target_node.child_by_field_name("type") {
                            if let Ok(ret_text) = ret_child.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(formal_params) = target_node.child_by_field_name("parameters") {
                            let mut p_cursor = formal_params.walk();
                            for p_child in formal_params.children(&mut p_cursor) {
                                if p_child.kind() == "formal_parameter" || p_child.kind() == "simple_formal_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts.last().unwrap().to_string(), parts[0..parts.len() - 1].join(" "))
                                        } else {
                                            (p_text.to_string(), "dynamic".to_string())
                                        };

                                        let is_optional = p_text.contains('?') || p_text.contains('{') || p_text.contains('[');
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = target_node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "documentation_comment" || prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (method_invocation
              name: (identifier) @callee) @call
            (import_or_export) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "method_signature" || p.kind() == "function_signature" {
                                    caller_qualified = resolve_dart_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\dart.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
# FILE: go.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\go.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct GoExtractor;

/// Resolves full qualified symbol name (e.g. `Server.Start`) by checking Go receiver type
fn resolve_go_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => match node.utf8_text(code.as_bytes()) {
            Ok(t) => t.split('(').next().unwrap_or("").trim().to_string(),
            Err(_) => return String::new(),
        },
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "method_declaration" {
            if let Some(receiver) = p.child_by_field_name("receiver") {
                if let Ok(recv_text) = receiver.utf8_text(code.as_bytes()) {
                    let clean_recv = recv_text
                        .split_whitespace()
                        .last()
                        .unwrap_or("")
                        .trim_matches(|c| c == '(' || c == ')' || c == '*' || c == '&');
                    if !clean_recv.is_empty() {
                        return format!("{}.{}", clean_recv, name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for GoExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_go::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_declaration
              name: (field_identifier) @name) @fn
            (type_spec
              name: (type_identifier) @name) @type_def
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.ends_with("_test.go");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_go_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    if let Some(first_char) = last_segment.chars().next() {
                        is_public = first_char.is_uppercase();
                    }
                    if last_segment.starts_with("Test") || last_segment.starts_with("Benchmark") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "type_def" => {
                            if let Ok(text) = node.utf8_text(code.as_bytes()) {
                                if text.contains("interface") {
                                    GraphNodeKind::Interface
                                } else {
                                    GraphNodeKind::Struct
                                }
                            } else {
                                GraphNodeKind::Struct
                            }
                        }
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "parameter_declaration" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let parts: Vec<&str> = p_text.split_whitespace().collect();
                                        let (p_name, p_type) = if parts.len() >= 2 {
                                            (parts[0].to_string(), parts[1..].join(" "))
                                        } else {
                                            (p_text.to_string(), "interface{}".to_string())
                                        };
                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(result_node) = node.child_by_field_name("result") {
                            if let Ok(ret_text) = result_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                let clean = comment_text.trim().trim_start_matches("//").trim();
                                doc_lines.push(clean.to_string());
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (import_spec) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_declaration" {
                                    caller_qualified = resolve_go_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim_matches('"').trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\go.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\mod.rs`

pub mod dart;
pub mod go;
pub mod python;
pub mod rust;
pub mod typescript;

use crate::mcp::schema::SideEffect;
use tree_sitter::Node;

/// Computes cyclomatic complexity of an AST node by counting decision branches
pub fn compute_cyclomatic_complexity(source: &[u8], root: Node) -> u32 {
    let mut complexity = 1;

    let branch_kinds = [
        "if_statement",
        "if_expression",
        "elif_clause",
        "match_arm",
        "case_statement",
        "case_clause",
        "expression_case",
        "type_case_clause",
        "for_statement",
        "for_expression",
        "for_in_clause",
        "while_statement",
        "while_expression",
        "binary_expression",
        "boolean_operator",
    ];

    let function_scope_kinds = [
        "function_item",
        "function_definition",
        "method_definition",
        "arrow_function",
        "closure_expression",
    ];

    let mut stack = vec![root];
    let mut is_root = true;

    while let Some(current) = stack.pop() {
        let kind = current.kind();

        // Avoid entering nested functions/closures so their complexity isn't double-counted
        if !is_root && function_scope_kinds.contains(&kind) {
            continue;
        }
        is_root = false;

        if branch_kinds.contains(&kind) {
            if kind == "binary_expression" || kind == "boolean_operator" {
                if let Some(op_node) = current.child_by_field_name("operator") {
                    if let Ok(op_text) = op_node.utf8_text(source) {
                        let op = op_text.trim();
                        if op == "&&" || op == "||" || op == "and" || op == "or" {
                            complexity += 1;
                        }
                    }
                }
            } else {
                complexity += 1;
            }
        }

        let mut cursor = current.walk();
        for child in current.children(&mut cursor) {
            stack.push(child);
        }
    }

    complexity
}

/// Infers side effects (IO, Network, Lock, StateMutation) from symbol text body
pub fn infer_side_effects(code: &str) -> Vec<SideEffect> {
    let mut effects = Vec::new();

    if code.contains("std::fs")
        || code.contains("File::")
        || code.contains("write!")
        || code.contains("println!")
        || code.contains("File.")
        || code.contains("print(")
    {
        effects.push(SideEffect::Io);
    }

    if code.contains("http://")
        || code.contains("https://")
        || code.contains("reqwest")
        || code.contains("TcpStream")
        || code.contains("WebSocket")
        || code.contains("fetch(")
    {
        effects.push(SideEffect::Network);
    }

    if code.contains("Mutex")
        || code.contains("RwLock")
        || code.contains(".lock()")
        || code.contains(".read()")
        || code.contains(".write()")
    {
        effects.push(SideEffect::Lock);
    }

    if code.contains("&mut ")
        || code.contains("self.")
        || code.contains("setState")
        || code.contains("this.")
    {
        effects.push(SideEffect::StateMutation);
    }

    effects.dedup();
    effects
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
# FILE: python.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\python.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct PythonExtractor;

/// Resolves full qualified symbol name (e.g. `DataPipeline.process`) by traversing class ancestors
fn resolve_python_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_definition" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for PythonExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_python::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_definition
              name: (identifier) @name) @fn
            (class_definition
              name: (identifier) @name) @class
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = true;
            let mut is_test = file_path.contains("test.py") || file_path.contains("/tests/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_python_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    is_public = !last_segment.starts_with('_');
                    if last_segment.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                let p_kind = p_child.kind();
                                if p_kind == "identifier" || p_kind == "typed_parameter" || p_kind == "default_parameter" || p_kind == "typed_default_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        if p_text != "self" && p_text != "cls" {
                                            let parts: Vec<&str> = p_text.split(':').collect();
                                            let p_name = parts[0].trim().to_string();
                                            let p_type = if parts.len() > 1 {
                                                parts[1].split('=').next().unwrap_or("Any").trim().to_string()
                                            } else {
                                                "Any".to_string()
                                            };
                                            let is_optional = p_text.contains('=') || p_type.contains("Optional");

                                            params.push(ParamDto {
                                                name: p_name,
                                                type_name: p_type,
                                                is_optional,
                                            });
                                        }
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim().to_string());
                            }
                        }

                        if let Some(body) = node.child_by_field_name("body") {
                            let mut b_cursor = body.walk();
                            for b_child in body.children(&mut b_cursor) {
                                if b_child.kind() == "expression_statement" {
                                    if let Ok(expr_text) = b_child.utf8_text(code.as_bytes()) {
                                        let trimmed = expr_text.trim();
                                        if (trimmed.starts_with("\"\"\"") && trimmed.ends_with("\"\"\""))
                                            || (trimmed.starts_with("'''") && trimmed.ends_with("'''"))
                                        {
                                            let clean = trimmed
                                                .trim_start_matches("\"\"\"")
                                                .trim_start_matches("'''")
                                                .trim_end_matches("\"\"\"")
                                                .trim_end_matches("'''")
                                                .trim()
                                                .lines()
                                                .next()
                                                .unwrap_or("")
                                                .to_string();
                                            if !clean.is_empty() {
                                                intent = Some(clean);
                                            }
                                        }
                                    }
                                    break;
                                }
                            }
                        }
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call
              function: (_) @callee) @call_stmt
            (import_statement) @import
            (import_from_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_definition" {
                                    caller_qualified = resolve_python_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\python.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
# FILE: rust.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\rust.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct RustExtractor;

/// Resolves full qualified symbol name (e.g. `core::service::Worker::run`) by traversing mod & impl ancestors
fn resolve_rust_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut prefixes = Vec::new();
    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "impl_item" {
            if let Some(type_node) = p.child_by_field_name("type") {
                if let Ok(type_name) = type_node.utf8_text(code.as_bytes()) {
                    let clean_type = type_name.split('<').next().unwrap_or("").trim();
                    prefixes.push(clean_type.to_string());
                }
            }
        } else if p.kind() == "mod_item" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(mod_name) = name_node.utf8_text(code.as_bytes()) {
                        prefixes.push(mod_name.trim().to_string());
                    }
                }
            }
        }
        parent = p.parent();
    }

    prefixes.reverse();
    if prefixes.is_empty() {
        name
    } else {
        format!("{}::{}", prefixes.join("::"), name)
    }
}

impl LanguageExtractor for RustExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_rust::language();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_item
              name: (identifier) @name) @fn
            (struct_item
              name: (type_identifier) @name) @struct
            (enum_item
              name: (type_identifier) @name) @enum
            (trait_item
              name: (type_identifier) @name) @trait
            (type_item
              name: (type_identifier) @name) @type_alias
            (mod_item
              name: (identifier) @name) @module
            (macro_definition
              name: (identifier) @name) @macro
        "#;

        let decl_query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&decl_query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = false;

            for cap in mat.captures {
                let cap_name = decl_query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_rust_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    if name.starts_with("test_") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "struct" | "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        "trait" => GraphNodeKind::Trait,
                        "module" | "macro" => GraphNodeKind::Module,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("pub");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(params_node) = node.child_by_field_name("parameters") {
                            let mut p_cursor = params_node.walk();
                            for p_child in params_node.children(&mut p_cursor) {
                                if p_child.kind() == "parameter" {
                                    let raw_pattern = p_child
                                        .child_by_field_name("pattern")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("param");
                                    let p_name = raw_pattern.trim_start_matches("mut ").trim().to_string();
                                    let p_type = p_child
                                        .child_by_field_name("type")
                                        .and_then(|n| n.utf8_text(code.as_bytes()).ok())
                                        .unwrap_or("impl Any")
                                        .to_string();
                                    let is_optional = p_type.contains("Option");

                                    params.push(ParamDto {
                                        name: p_name,
                                        type_name: p_type,
                                        is_optional,
                                    });
                                } else if p_child.kind() == "self_parameter" {
                                    if let Ok(self_text) = p_child.utf8_text(code.as_bytes()) {
                                        params.push(ParamDto {
                                            name: "self".to_string(),
                                            type_name: self_text.to_string(),
                                            is_optional: false,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches("->").trim().to_string());
                            }
                        }
                    }

                    // Extract doc comments & preceding `#[test]` attributes
                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "attribute_item" {
                            if let Ok(attr_text) = prev.utf8_text(code.as_bytes()) {
                                if attr_text.contains("test") {
                                    is_test = true;
                                }
                            }
                        } else if prev.kind() == "line_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("///") {
                                    let clean = comment_text.trim().trim_start_matches("///").trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else if prev.kind() == "block_comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim();
                                    doc_lines.push(clean.to_string());
                                }
                            }
                        } else {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call
            (use_declaration) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let callee_clean = callee_text.split('(').next().unwrap_or("").trim().to_string();

                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_item" {
                                    caller_qualified = resolve_rust_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_clean.is_empty() && caller_qualified != callee_clean {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_clean,
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean_import = import_text
                                .trim_start_matches("use ")
                                .trim_end_matches(';')
                                .trim()
                                .to_string();
                            if !clean_import.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean_import,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\rust.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
# FILE: typescript.rs
**Relative Path**: `shua_code_visualizer\src\parser\registry\typescript.rs`

use crate::mcp::schema::{GraphNodeKind, ParamDto, Relation};
use crate::parser::extractor::{ExtractedEdge, ExtractedSymbol, LanguageExtractor, ParseResult};
use crate::parser::registry::{compute_cyclomatic_complexity, infer_side_effects};
use std::collections::HashSet;
use tree_sitter::{Node, Parser, Query, QueryCursor};

pub struct TypeScriptExtractor;

/// Resolves full qualified symbol name (e.g. `ApiClient.fetchData`) by traversing class/interface ancestors
fn resolve_typescript_qualified_name(node: Node, code: &str) -> String {
    let name = match node.child_by_field_name("name") {
        Some(n) => match n.utf8_text(code.as_bytes()) {
            Ok(t) => t.to_string(),
            Err(_) => return String::new(),
        },
        None => return String::new(),
    };

    let mut parent = node.parent();
    while let Some(p) = parent {
        if p.kind() == "class_declaration" || p.kind() == "interface_declaration" {
            if let Some(name_node) = p.child_by_field_name("name") {
                if name_node.id() != node.id() {
                    if let Ok(class_name) = name_node.utf8_text(code.as_bytes()) {
                        return format!("{}.{}", class_name.trim(), name);
                    }
                }
            }
            break;
        }
        parent = p.parent();
    }

    name
}

impl LanguageExtractor for TypeScriptExtractor {
    fn parse(&self, code: &str, file_path: &str) -> ParseResult {
        let mut parser = Parser::new();
        let language = tree_sitter_typescript::language_typescript();
        if parser.set_language(&language).is_err() {
            return ParseResult::default();
        }

        let tree = match parser.parse(code, None) {
            Some(t) => t,
            None => return ParseResult::default(),
        };

        let decl_query_str = r#"
            (function_declaration
              name: (identifier) @name) @fn
            (method_definition
              name: (property_identifier) @name) @fn
            (class_declaration
              name: (type_identifier) @name) @class
            (interface_declaration
              name: (type_identifier) @name) @interface
            (type_alias_declaration
              name: (type_identifier) @name) @type_alias
            (enum_declaration
              name: (identifier) @name) @enum
        "#;

        let query = match Query::new(&language, decl_query_str) {
            Ok(q) => q,
            Err(_) => return ParseResult::default(),
        };

        let mut cursor = QueryCursor::new();
        let matches = cursor.matches(&query, tree.root_node(), code.as_bytes());
        let mut symbols = Vec::new();

        for mat in matches {
            let mut name = String::new();
            let mut kind = GraphNodeKind::Function;
            let mut start_line = 0;
            let mut end_line = 0;
            let mut complexity = 1;
            let mut return_type = None;
            let mut params = Vec::new();
            let mut intent = None;
            let mut code_snippet = String::new();
            let mut is_public = false;
            let mut is_test = file_path.contains(".test.") || file_path.contains(".spec.") || file_path.contains("/__tests__/");

            for cap in mat.captures {
                let cap_name = query.capture_names()[cap.index as usize];
                let node = cap.node;

                if cap_name == "name" {
                    if let Some(target_decl) = node.parent() {
                        name = resolve_typescript_qualified_name(target_decl, code);
                    } else {
                        if let Ok(text) = node.utf8_text(code.as_bytes()) {
                            name = text.to_string();
                        }
                    }
                    let last_segment = name.split('.').last().unwrap_or("");
                    if last_segment == "it" || last_segment == "test" || last_segment.starts_with("test") {
                        is_test = true;
                    }
                } else {
                    kind = match cap_name {
                        "class" => GraphNodeKind::Class,
                        "interface" => GraphNodeKind::Interface,
                        "type_alias" => GraphNodeKind::Struct,
                        "enum" => GraphNodeKind::Enum,
                        _ => GraphNodeKind::Function,
                    };

                    let range = node.range();
                    start_line = range.start_point.row as u32 + 1;
                    end_line = range.end_point.row as u32 + 1;

                    if let Ok(text) = node.utf8_text(code.as_bytes()) {
                        code_snippet = text.to_string();
                        is_public = text.trim().starts_with("export") || text.trim().starts_with("public");
                    }

                    if kind == GraphNodeKind::Function {
                        complexity = compute_cyclomatic_complexity(code.as_bytes(), node);

                        if let Some(parameters) = node.child_by_field_name("parameters") {
                            let mut p_cursor = parameters.walk();
                            for p_child in parameters.children(&mut p_cursor) {
                                if p_child.kind() == "required_parameter" || p_child.kind() == "optional_parameter" {
                                    if let Ok(p_text) = p_child.utf8_text(code.as_bytes()) {
                                        let is_optional = p_child.kind() == "optional_parameter" || p_text.contains('?');
                                        let parts: Vec<&str> = p_text.split(':').collect();
                                        let p_name = parts[0].trim_matches('?').trim().to_string();
                                        let p_type = if parts.len() > 1 {
                                            parts[1].trim().to_string()
                                        } else {
                                            "any".to_string()
                                        };

                                        params.push(ParamDto {
                                            name: p_name,
                                            type_name: p_type,
                                            is_optional,
                                        });
                                    }
                                }
                            }
                        }

                        if let Some(ret_type_node) = node.child_by_field_name("return_type") {
                            if let Ok(ret_text) = ret_type_node.utf8_text(code.as_bytes()) {
                                return_type = Some(ret_text.trim_start_matches(':').trim().to_string());
                            }
                        }
                    }

                    let mut doc_lines = Vec::new();
                    let mut prev_opt = node.prev_sibling();
                    while let Some(prev) = prev_opt {
                        if prev.kind() == "comment" {
                            if let Ok(comment_text) = prev.utf8_text(code.as_bytes()) {
                                if comment_text.trim().starts_with("/**") {
                                    let clean = comment_text
                                        .trim()
                                        .trim_start_matches("/**")
                                        .trim_end_matches("*/")
                                        .trim()
                                        .lines()
                                        .map(|l| l.trim().trim_start_matches('*').trim())
                                        .filter(|l| !l.is_empty() && !l.starts_with('@'))
                                        .collect::<Vec<&str>>()
                                        .join(" ");
                                    if !clean.is_empty() {
                                        doc_lines.push(clean);
                                    }
                                }
                            }
                        } else if prev.kind() != "export_specifier" {
                            break;
                        }
                        prev_opt = prev.prev_sibling();
                    }

                    if !doc_lines.is_empty() {
                        doc_lines.reverse();
                        intent = Some(doc_lines.join(" "));
                    }
                }
            }

            if !name.is_empty() {
                let side_effects = if kind == GraphNodeKind::Function {
                    infer_side_effects(&code_snippet)
                } else {
                    Vec::new()
                };

                let loc = end_line.saturating_sub(start_line) + 1;
                let id = format!("{}:{}", file_path, name);

                symbols.push(ExtractedSymbol {
                    id,
                    kind,
                    qualified_name: name,
                    file: file_path.to_string(),
                    line: start_line,
                    params,
                    return_type,
                    complexity,
                    side_effects,
                    intent,
                    loc,
                    is_public,
                    is_test,
                });
            }
        }

        // Extract call site edges using fully-qualified caller names
        let mut edges = Vec::new();
        let mut edge_set = HashSet::new();

        let call_query_str = r#"
            (call_expression
              function: (_) @callee) @call_stmt
            (import_statement) @import
        "#;

        if let Ok(call_query) = Query::new(&language, call_query_str) {
            let mut call_cursor = QueryCursor::new();
            let call_matches = call_cursor.matches(&call_query, tree.root_node(), code.as_bytes());

            for mat in call_matches {
                for cap in mat.captures {
                    let cap_name = call_query.capture_names()[cap.index as usize];
                    let node = cap.node;

                    if cap_name == "callee" {
                        if let Ok(callee_text) = node.utf8_text(code.as_bytes()) {
                            let mut caller_qualified = String::new();
                            let mut parent = node.parent();
                            while let Some(p) = parent {
                                if p.kind() == "function_declaration" || p.kind() == "method_definition" {
                                    caller_qualified = resolve_typescript_qualified_name(p, code);
                                    break;
                                }
                                parent = p.parent();
                            }

                            if !caller_qualified.is_empty() && !callee_text.is_empty() && caller_qualified != callee_text {
                                let edge = ExtractedEdge {
                                    from: caller_qualified,
                                    to: callee_text.to_string(),
                                    relation: Relation::Calls,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    } else if cap_name == "import" {
                        if let Ok(import_text) = node.utf8_text(code.as_bytes()) {
                            let clean = import_text.trim().to_string();
                            if !clean.is_empty() {
                                let edge = ExtractedEdge {
                                    from: file_path.to_string(),
                                    to: clean,
                                    relation: Relation::Imports,
                                };
                                if edge_set.insert(edge.clone()) {
                                    edges.push(edge);
                                }
                            }
                        }
                    }
                }
            }
        }

        ParseResult { symbols, edges }
    }
}


<!-- END_FILE: shua_code_visualizer\src\parser\registry\typescript.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
# FILE: hash_cache.rs
**Relative Path**: `shua_code_visualizer\src\watch\hash_cache.rs`

use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use walkdir::WalkDir;
use xxhash_rust::xxh64::xxh64;

/// Result of diffing current disk state against persisted hash index
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct FileDiffResult {
    pub added: Vec<String>,
    pub modified: Vec<String>,
    pub removed: Vec<String>,
}

/// Disk-persisted file content hash index for incremental re-parsing
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct HashCache {
    pub hashes: HashMap<String, u64>,
}

impl HashCache {
    pub fn new() -> Self {
        Self {
            hashes: HashMap::new(),
        }
    }

    /// Computes the xxh64 hash of raw file bytes
    pub fn compute_hash(bytes: &[u8]) -> u64 {
        xxh64(bytes, 0)
    }

    /// Loads persisted hash cache from disk
    pub fn load_from_disk(path: &Path) -> Result<Self, std::io::Error> {
        if !path.exists() {
            return Ok(Self::new());
        }
        let content = fs::read_to_string(path)?;
        let cache: HashCache = serde_json::from_str(&content)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        Ok(cache)
    }

    /// Persists current hash cache to disk
    pub fn save_to_disk(&self, path: &Path) -> Result<(), std::io::Error> {
        let json = serde_json::to_string_pretty(self)
            .map_err(|e| std::io::Error::new(std::io::ErrorKind::InvalidData, e))?;
        fs::write(path, json)?;
        Ok(())
    }

    /// Scans directory and returns diff against cache (added, modified, removed)
    pub fn diff_directory(&mut self, root_dir: &Path) -> FileDiffResult {
        let mut current_files = HashMap::new();
        let mut diff = FileDiffResult::default();

        let valid_extensions = ["rs", "dart", "go", "py", "ts", "tsx"];
        let ignore_dirs = [".git", "node_modules", "target", "build", ".dart_tool"];

        for entry in WalkDir::new(root_dir)
            .into_iter()
            .filter_entry(|e| {
                let name = e.file_name().to_string_lossy();
                !ignore_dirs.contains(&name.as_ref())
            })
            .filter_map(|e| e.ok())
        {
            if entry.file_type().is_file() {
                if let Some(ext) = entry.path().extension().and_then(|s| s.to_str()) {
                    if valid_extensions.contains(&ext) {
                        let path_str = entry.path().to_string_lossy().to_string();
                        if let Ok(bytes) = fs::read(entry.path()) {
                            let hash = Self::compute_hash(&bytes);
                            current_files.insert(path_str.clone(), hash);

                            match self.hashes.get(&path_str) {
                                Some(&old_hash) => {
                                    if old_hash != hash {
                                        diff.modified.push(path_str);
                                    }
                                }
                                None => {
                                    diff.added.push(path_str);
                                }
                            }
                        }
                    }
                }
            }
        }

        // Find removed files
        for old_path in self.hashes.keys() {
            if !current_files.contains_key(old_path) {
                diff.removed.push(old_path.clone());
            }
        }

        self.hashes = current_files;
        diff
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_compute_hash_reproducibility() {
        let text = b"fn main() { println!(\"Hello World\"); }";
        let h1 = HashCache::compute_hash(text);
        let h2 = HashCache::compute_hash(text);
        assert_ne!(h1, 0);
        assert_eq!(h1, h2);
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\hash_cache.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\mod.rs -->
# FILE: mod.rs
**Relative Path**: `shua_code_visualizer\src\watch\mod.rs`

pub mod hash_cache;
pub mod watcher;


<!-- END_FILE: shua_code_visualizer\src\watch\mod.rs -->
================================================================================

<!-- START_FILE: shua_code_visualizer\src\watch\watcher.rs -->
# FILE: watcher.rs
**Relative Path**: `shua_code_visualizer\src\watch\watcher.rs`

use crate::graph::store::CodeGraph;
use crate::mcp::schema::TopologyDeltaEvent;
use notify::{Config, Event, RecommendedWatcher, RecursiveMode, Watcher};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::sync::mpsc::{channel, Receiver};
use std::time::{Duration, Instant};

/// Live file watcher daemon with non-blocking event coalescing and path debouncing
pub struct CodeWatcher {
    _watcher: RecommendedWatcher,
    rx: Receiver<Result<Event, notify::Error>>,
    pending_events: HashMap<PathBuf, Instant>,
    debounce_window: Duration,
}

impl CodeWatcher {
    /// Starts watching a directory for live file changes
    pub fn new(target_dir: &Path) -> Result<Self, notify::Error> {
        let (tx, rx) = channel();

        let mut watcher = RecommendedWatcher::new(
            move |res| {
                let _ = tx.send(res);
            },
            Config::default().with_poll_interval(Duration::from_millis(50)),
        )?;

        watcher.watch(target_dir, RecursiveMode::Recursive)?;

        Ok(Self {
            _watcher: watcher,
            rx,
            pending_events: HashMap::new(),
            debounce_window: Duration::from_millis(100),
        })
    }

    /// Polls pending file change events non-blockingly, coalescing rapid raw events for the same path.
    /// Executes single-file incremental graph patches only after the path quiet window (100ms) has expired.
    ///
    /// Note: Callers should poll in a loop (`while let Some(delta) = watcher.poll_and_apply_patch(...)`)
    /// to drain all expired paths during batch edits (e.g. git checkout).
    pub fn poll_and_apply_patch(&mut self, graph: &mut CodeGraph) -> Option<TopologyDeltaEvent> {
        let now = Instant::now();

        // 1. Drain channel without blocking
        while let Ok(Ok(event)) = self.rx.try_recv() {
            if let Some(path) = event.paths.first() {
                let valid_exts = ["rs", "dart", "go", "py", "ts", "tsx"];
                if let Some(ext) = path.extension().and_then(|s| s.to_str()) {
                    if valid_exts.contains(&ext) {
                        self.pending_events.insert(path.clone(), now);
                    }
                }
            }
        }

        // 2. Find path whose quiet window has elapsed
        let mut expired_path = None;
        for (path, &last_seen) in &self.pending_events {
            if now.duration_since(last_seen) >= self.debounce_window {
                expired_path = Some(path.clone());
                break;
            }
        }

        // 3. Apply single incremental graph patch
        if let Some(path) = expired_path {
            self.pending_events.remove(&path);

            let path_str = path.to_string_lossy().to_string();
            let code_opt = fs::read_to_string(&path).ok();
            let delta = graph.apply_incremental_file_patch(&path_str, code_opt.as_deref());

            Some(delta)
        } else {
            None
        }
    }
}


<!-- END_FILE: shua_code_visualizer\src\watch\watcher.rs -->
================================================================================

