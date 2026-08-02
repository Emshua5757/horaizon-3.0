# TASK-016A — `client_flutter` Native Code Topology Visualizer Canvas & UI

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |
| **Sub-tasks** | TASK-016A (UI Canvas & Local JSON Visualizer), TASK-016T (MCP Integration & Golden Test) |
| **Prerequisites** | TASK-015A (`shua_code_visualizer` Core Engine & Exported Graph JSON) |

---

## Overview

Build the native Flutter **Code Topology Visualizer Screen** (`/code/topology`), interactive node-graph canvas (`CustomPainter` + `InteractiveViewer`), symbol inspector drawer, and local JSON graph loader.

---

## Key Deliverables

### 1. Topology Data Models & Local Asset Loader (`lib/features/code_visualizer/`)
- [x] 1.1 `TopologyNodeModel`, `TopologyEdgeModel`, `TopologyGraphDataModel` JSON DTOs matching `shua_code_visualizer` wire schema.
- [x] 1.2 `codeTopologyProvider`: Riverpod state provider loading topology data from local JSON asset/file (`code_viz_graph_output.json`) or mock fallback.

### 2. Node Layout Engine & Canvas Painter (`lib/features/code_visualizer/presentation/widgets/`)
- [x] 2.1 Layered/force-directed 2D layout calculation placing nodes smoothly on grid (`layout_engine.dart`).
- [x] 2.2 `InteractiveViewer` with smooth pan, pinch-zoom, and boundary constraints.
- [x] 2.3 `CustomPainter` rendering directional curved arrows (`Calls` = cyan, `Imports` = purple).
- [x] 2.4 Interactive node cards color-coded by complexity score (Green < 5, Amber 5-10, Red > 10).

### 3. Symbol Inspector Drawer (`lib/features/code_visualizer/presentation/widgets/`)
- [x] 3.1 Slide-over side drawer displaying detailed symbol metrics: signature, parameters, doc intent, side-effect badges, risk score, and file location.

### 4. Router Integration (`lib/router/app_router.dart`)
- [x] 4.1 Register `/code/topology` in `app_router.dart` inside `ShellScaffold`.
- [x] 4.2 Link Dashboard `▷ Wake & Launch` card in `microservices_section.dart` to open `/code/topology`.

---

## Acceptance Criteria

- [x] Navigating to `/code/topology` or clicking `▷ Wake & Launch` loads interactive graph canvas.
- [x] Pan and zoom gestures smoothly transform the canvas on Windows and mobile.
- [x] Tapping a node opens the symbol inspector side drawer with parameter types, intent, and side-effects.
- [x] `flutter analyze` — 0 errors.
