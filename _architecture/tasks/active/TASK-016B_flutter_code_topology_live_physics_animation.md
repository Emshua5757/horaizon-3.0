# TASK-016B — `client_flutter` Live Physics Simulation, Path Tracer & Insights Filter Matrix

| Field | Value |
| :--- | :--- |
| **Status** | [/] In Progress |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |
| **Branch** | `task/TASK-016B-live-physics-animation` |
| **Prerequisites** | TASK-016A (Multi-View Topology Canvas), TASK-015A-5 (HBP IPC Broker) |
| **Sub-tasks** | TASK-016B-1 through TASK-016B-6 |

---

## Why this beats a straight Graphify port

Graphify (Python) computes a layout once, renders a static image or a fixed-frame view, and has no channel back to the source repo. You already built something it doesn't have: `shua_code_visualizer` runs as a **live subprocess** with a working `TopologyDeltaEvent` stream over the HBP IPC broker (TASK-015A-5) and named `from`/`to` call edges precise enough to BFS. The plan below is built around using both of those — not just matching Graphify's feature list, but adding two things it structurally can't do:

1. **Live delta animation** — when a file changes, the graph patches itself and animates the change, instead of requiring a full re-scan/re-render.
2. **A tool-connected inspector** — path tracing and "blast radius" aren't just visual tricks, they can call straight into the same `McpHandler` (`find_callers`, `blast_radius`) your Rust core already exposes, so the answer is guaranteed to match what the AST parser actually sees.

---

## Subtasks Breakdown

### TASK-016B-1 — 60fps Live Physics Ticker & Interactive Node Dragging
- [ ] 1.1 Convert `GraphLayoutEngine` physics mode into a stateful `PhysicsSimulation` class exposing `step(double dt)`.
- [ ] 1.2 Drive from `Ticker` (`SingleTickerProviderStateMixin` on `CodeTopologyCanvas`) targeting 16.6ms/frame.
- [ ] 1.3 Keep per-node `position` + `velocity` in the simulation state, not in painter.
- [ ] 1.4 **Thermal cooling / idle detection**: track total kinetic energy (`sum(velocity.distanceSquared)`). Pause ticker when settled for 0% CPU consumption when idle.
- [ ] 1.5 **Node pinning**: add `Set<String> pinnedIds` for fixed nodes during drag.
- [ ] 1.6 **Drag gesture wiring** on `CodeTopologyCanvas` using viewport to content matrix transformation.
- [ ] 1.7 Long-press to toggle permanent pin vs spring release.

### TASK-016B-2 — Graphify Shortest Path Tracer
- [ ] 2.1 Add `pathStartNodeProvider` / `pathEndNodeProvider`.
- [ ] 2.2 Right-click / context menu to set path start/end.
- [ ] 2.3 `path_tracer.dart`: BFS shortest path finder over undirected/directed call graph.
- [ ] 2.4 Surface "no path found" state clearly.
- [ ] 2.5 Animated hop-by-hop path highlight drawing bright green 3px path lines over canvas.
- [ ] 2.6 Interactive path chain drawer panel listing ordered hops.

### TASK-016B-3 — Advanced Insights Filter Matrix
- [ ] 3.1 `Set<InsightFilter> activeFilters` matrix (`godFunctions`, `hubs`, `highRisk`, `deadCode`, `publicApis`).
- [ ] 3.2 OR/AND toggle logic for combining filters.
- [ ] 3.3 Replace SegmentedButton with live count badge toggle chips (🌐 All · 👑 God Functions · 🔥 Hubs · ⚠️ High Risk · 💀 Dead Code · 📦 Public APIs).

### TASK-016B-4 — Search & N-Hop Subgraph Isolation
- [ ] 4.1 Add `isolationDepthProvider` (0/1/2 = off / 1-hop / 2-hop).
- [ ] 4.2 Search query auto-isolates N-hop caller/callee neighborhood and dims outside graph.
- [ ] 4.3 Debounce search `TextField` inputs (150ms).

### TASK-016B-5 — Performance Pass for Larger Graphs
- [ ] 5.1 Wrap canvas `CustomPaint` in `RepaintBoundary`.
- [ ] 5.2 Uniform spatial grid bucket algorithm for >300 node graphs.
- [ ] 5.3 Optional Isolate worker offloading.

### TASK-016B-6 — Live Delta Animation
- [ ] 6.1 `StreamProvider<TopologyDeltaEvent>` listening to governor IPC WebSocket port.
- [ ] 6.2 Apply incremental node/edge patches to `TopologyGraphDataModel` on file save.
- [ ] 6.3 Auto-wake physics ticker for added nodes with scale-in glow animations.
