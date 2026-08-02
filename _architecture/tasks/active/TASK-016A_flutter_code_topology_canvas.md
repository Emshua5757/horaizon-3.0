# TASK-016A — `client_flutter` Native Code Topology & Graphify Multi-View Engine

| Field | Value |
| :--- | :--- |
| **Status** | [/] In Progress (Reopened) |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |
| **Branch** | `task/TASK-016A-code-visualizer-canvas` |

---

## Overview

Redesign the native Flutter **Code Topology Visualizer Screen** (`/code/topology`) based on Graphify-style interactive topology concepts. Provide 3 distinct dynamic view modes, real force-directed physics cluster placement, native folder scanning, and interactive node neighborhood highlighting.

---

## Key Deliverables

### 1. 3 Dynamic View Modes (`layout_engine.dart`)
- **Mode 1: 📁 File Hierarchy Grouped View**: Nodes grouped in file/module containers connected across files with visible bezier relationship lines.
- **Mode 2: ⚡ Organic Force-Directed Physics Cluster View**: Real iterative physics simulation (Coulomb repulsion + Hooke's spring attraction + center gravity) pulling closely related functions/structs together into floating star-constellation clusters.
- **Mode 3: 🌲 Architecture Call-Flow Tree View**: Layered DAG tree flow from entrypoints (left/top) down to leaf dependencies.

### 2. Connected Graph Canvas & Subgraph Highlighting (`code_topology_canvas.dart`)
- Circular / pill-shaped visual nodes connected by explicit directional bezier curves (`Calls`, `Imports`).
- Neighborhood highlighting: tapping a node highlights its entire caller/callee neighborhood and dims non-connected nodes.
- Prominent node sizing: Hub symbols with high call count (`fanIn + fanOut`) rendered with larger scale and pulsing accent halos.

### 3. Repository Folder Picker & Live Scanner (`code_topology_provider.dart`)
- Native folder picker button (`📁 Select Repository...`) allowing user to pick any folder on their computer.
- Background execution of `shua_code_visualizer.exe --workspace-root <folder> --export-graph <temp_out>` to dynamically render any codebase.

---

## Acceptance Criteria

- [ ] User can switch between 3 view modes: `File Grouped`, `Organic Physics Cluster`, and `Call-Flow Tree`.
- [ ] Organic Physics Cluster layout smoothly places closely related functions next to each other based on edge connections.
- [ ] Tapping a node highlights connected caller/callee lines and dims non-connected nodes.
- [ ] User can pick any local folder via `📁 Select Repository...` button and visualize its graph topology.
- [ ] `flutter analyze` — 0 errors, 0 warnings.
