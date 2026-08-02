# TASK-016B — `client_flutter` Live Physics Simulation, Path Tracer & Insights Filter Matrix

| Field | Value |
| :--- | :--- |
| **Status** | [x] Completed |
| **Phase** | Phase 2 |
| **Type** | AI-executable |
| **Language** | Dart / Flutter |
| **Target** | `client_flutter/lib/features/code_visualizer/` |

---

## Overview

Upgraded the **Code Topology Visualizer** (`/code/topology`) with real-time **60fps Physics Simulation**, **Interactive Mouse/Touch Node Dragging**, **Graphify Shortest Path Tracing**, **Advanced Filter Matrix**, and **3 Dynamic View Modes**.

---

## Technical Specifications & Features

### 1. 3 Dynamic View Modes (`layout_engine.dart`)
- [x] **Mode 1: ⚡ Organic Force-Directed Physics Cluster View**: Real-time 60fps tick simulation ($v_{t+1} = (v_t + a) \cdot damping$, $p_{t+1} = p_t + v_{t+1}$) with Coulomb repulsion, Hooke spring attraction, center gravity, interactive node dragging, and thermal cooling (0% CPU when idle).
- [x] **Mode 2: 📁 File Hierarchy Grouped Container View**: Translucent rounded file containers (`RRect`) with file header labels (e.g. `ipc_client.rs`, `store.rs`), member nodes packed in mini-grids, and inter-file bezier relationship arrows.
- [x] **Mode 3: 🌲 Architecture Call-Flow Tree View**: Multi-tier DAG layout flowing from root entrypoints (`fanIn = 0`, `main()`, MCP handlers) at the top down to leaf callees at the bottom.

### 2. Graphify Shortest Path Tracer & Query Tool (`code_topology_canvas.dart` & `code_topology_screen.dart`)
- [x] **Shortest Path Tracing**: Select any two symbols (Node A and Node B) to run BFS shortest path tracing, highlighting the hop-by-hop call chain (e.g. `main()` $\to$ `IpcClient::start_ipc_loop` $\to$ `CodeGraph::new`).
- [x] **Interactive Search & Subgraph Isolation**: Real-time symbol search with auto-highlighting isolating candidate symbols and their 1-hop / 2-hop caller/callee neighborhood.

### 3. Advanced Insights Filter Matrix
- [x] 🌐 **`All Symbols`**: Complete hypergraph topology.
- [x] 👑 **`God Functions`**: Overloaded functions (`exceedsComplexityThreshold && exceedsLocThreshold` or complexity $\ge 15$, LOC $\ge 80$).
- [x] 🔥 **`Hubs`**: High call traffic nodes (`fanIn + fanOut >= 6`).
- [x] ⚠️ **`High Risk`**: High risk score nodes ($\text{riskScore} \ge 7.0$).
- [x] 💀 **`Dead Code`**: Unreferenced non-public non-test orphans.
- [x] 📦 **`Public APIs`**: Exported public interface symbols.

---

## Acceptance Criteria

- [x] Expose 3 view modes in top control bar (`⚡ Physics Cluster`, `📁 File Grouped`, `🌲 Call Flow`).
- [x] 60fps physics simulation ticker running smooth organic floating motion in `Physics Cluster` mode.
- [x] Interactive node dragging (`onPanStart`, `onPanUpdate`, `onPanEnd`) pinning dragged nodes while connected spring edges pull neighbors.
- [x] Thermal cooling pausing physics ticker when nodes settle into resting equilibrium (0% CPU idle).
- [x] Shortest path tracing tool highlighting hop-by-hop call chains between 2 selected nodes.
- [x] Advanced filter matrix (`All`, `God Functions`, `Hubs`, `High Risk`, `Dead Code`, `Public APIs`).
- [x] `flutter analyze` — 0 errors, 0 warnings.
