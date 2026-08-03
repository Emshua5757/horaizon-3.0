# TASK-016 — `client_flutter` Native Code Topology & AST Viewer Screen

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |
| **Blocks** | None |
| **Prerequisites** | TASK-010 (GoRouter & Theme), TASK-015 (`shua_code_visualizer` Engine) |

---

## Overview

Build the native Flutter **Code Topology Screen** (`/code/topology`) and **File Watcher Control Screen** (`/code/watch`). 

The Code Topology screen renders an interactive, zoomable node-graph visualizer representing source code AST dependency hypergraphs parsed by `shua_code_visualizer` (Rust) over HBP v2 (`shua.code_visualizer.topology.get` / `code_render_graph`).

---

## Technical Specifications

1. **Interactive Node Graph Canvas (`code_topology_canvas.dart`)**:
   - Built using custom `CustomPainter` with pan/zoom gestures (`InteractiveViewer`).
   - Renders AST node nodes (functions, structs, classes) and directional dependency edges.
   - Node color-coding based on cyclomatic complexity score (Green = <5, Amber = 5-10, Red = >10).
2. **Symbol Inspector Drawer (`symbol_inspector_drawer.dart`)**:
   - Tapping an AST node opens a side drawer displaying symbol signature, caller references (`code_find_callers`), side-effect flags (IO, network, state mutation), and file line number.
3. **File Watcher Control (`code_watch_screen.dart`)**:
   - Controls active file watching daemon (`shua.code_visualizer.watch.start` / `stop`).
   - Displays real-time delta change stream (`TopologyDeltaEvent`).

---

## Acceptance Criteria

- [x] Navigating to `/code/topology` loads hypergraph data from `shua_code_visualizer` via `hbpClientProvider`
- [x] Pan and zoom gestures smoothly transform the graph canvas on Windows and Android
- [x] Tapping a node highlights connected caller edges and opens symbol details side drawer
- [x] Real-time `TopologyDeltaEvent` triggers animated node graph refresh
- [x] `flutter analyze` — 0 errors
