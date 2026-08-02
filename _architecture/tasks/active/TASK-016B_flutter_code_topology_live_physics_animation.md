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
