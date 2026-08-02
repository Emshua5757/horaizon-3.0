# TASK-016A — `client_flutter` Native Code Topology & Graphify Multi-View Engine

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |

---

## Overview

Redesign the native Flutter **Code Topology Visualizer Screen** (`/code/topology`) based on Graphify-style interactive topology concepts. Provide 3 distinct dynamic view modes, real force-directed physics cluster placement, native folder scanning, and interactive node neighborhood highlighting.

---

## Key Deliverables

### 1. 3 Dynamic View Modes (`layout_engine.dart`)
- [x] **Mode 1: 📁 File Hierarchy Grouped View**: Nodes grouped in file/module containers connected across files with visible bezier relationship lines.
- [x] **Mode 2: ⚡ Organic Force-Directed Physics Cluster View**: Real iterative physics simulation (Coulomb repulsion + Hooke's spring attraction + center gravity) pulling closely related functions/structs together into floating star-constellation clusters.
- [x] **Mode 3: 🌲 Architecture Call-Flow Tree View**: Layered DAG tree flow from entrypoints (left/top) down to leaf dependencies.

### 2. Connected Graph Canvas & Subgraph Highlighting (`code_topology_canvas.dart`)
- [x] Circular / pill-shaped visual nodes connected by explicit directional bezier curves (`Calls`, `Imports`).
- [x] Neighborhood highlighting: tapping a node highlights its entire caller/callee neighborhood and dims non-connected nodes.
- [x] Prominent node sizing: Hub symbols with high call count (`fanIn + fanOut`) rendered with larger scale and pulsing accent halos.

### 3. Repository Folder Picker & Live Scanner (`code_topology_provider.dart`)
- [x] Native folder picker button (`📁 Select Repository...`) allowing user to pick any folder on their computer.
- [x] Background execution of `shua_code_visualizer.exe --workspace-root <folder> --export-graph <temp_out>` to dynamically render any codebase.
