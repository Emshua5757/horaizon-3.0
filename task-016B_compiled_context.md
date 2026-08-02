# TASK-016B — Master Compiled Context & Architecture Package

> **Purpose**: Master compiled context artifact for Claude Code to implement **TASK-016B**: 60fps Live Physics Ticker Animation, Interactive Mouse/Touch Node Dragging, Graphify Shortest Path Tracer, Advanced Filter Matrix, and Live WebSocket Delta Streaming in `client_flutter/lib/features/code_visualizer/`.

---

## 1. Master Task Specification (`TASK-016B_flutter_code_topology_live_physics_animation.md`)

```markdown
# TASK-016B — client_flutter Live Physics Simulation, Path Tracer & Insights Filter Matrix

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
```

---

## 2. File 1: Data Models (`models/topology_models.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/models/topology_models.dart

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
      type: json['type_name'] as String? ?? json['type'] as String? ?? 'dynamic',
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }
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
    return TopologyNodeModel(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'symbol',
      qualifiedName: json['qualified_name'] as String? ?? json['id'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: json['line'] as int? ?? 1,
      params: (json['params'] as List<dynamic>?)
              ?.map((e) => ParamModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      returnType: json['return_type'] as String?,
      complexity: json['complexity'] as int? ?? 1,
      sideEffects: (json['side_effects'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      intent: json['intent'] as String?,
      loc: json['loc'] as int? ?? 1,
      isPublic: json['is_public'] as bool? ?? false,
      isTest: json['is_test'] as bool? ?? false,
      fanIn: json['fan_in'] as int? ?? 0,
      fanOut: json['fan_out'] as int? ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      isOrphan: json['is_orphan'] as bool? ?? false,
      exceedsParamThreshold: json['exceeds_param_threshold'] as bool? ?? false,
      exceedsComplexityThreshold: json['exceeds_complexity_threshold'] as bool? ?? false,
      exceedsLocThreshold: json['exceeds_loc_threshold'] as bool? ?? false,
    );
  }
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
}

class TopologyGraphDataModel {
  final List<TopologyNodeModel> nodes;
  final List<TopologyEdgeModel> edges;

  const TopologyGraphDataModel({
    required this.nodes,
    required this.edges,
  });

  factory TopologyGraphDataModel.fromJson(Map<String, dynamic> json) {
    return TopologyGraphDataModel(
      nodes: (json['nodes'] as List<dynamic>?)
              ?.map((e) => TopologyNodeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      edges: (json['edges'] as List<dynamic>?)
              ?.map((e) => TopologyEdgeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
```

---

## 3. File 2: Topology Insights Extension (`models/topology_insights.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/models/topology_insights.dart

import 'topology_models.dart';

extension TopologyNodeInsights on TopologyNodeModel {
  bool get isGodFunction =>
      (exceedsComplexityThreshold && exceedsLocThreshold) ||
      (complexity >= 15 && loc >= 80) ||
      (fanOut >= 8 && params.length >= 5);

  bool get isHub => (fanIn + fanOut) >= 6;
  bool get isDeadCode => isOrphan && !isPublic && !isTest;
  bool get isHighRisk => riskScore >= 7.0;
  bool get isPublicApi => isPublic && !isTest;

  String get primaryBadgeLabel {
    if (isGodFunction) return 'God Function';
    if (isDeadCode) return 'Dead Code';
    if (isHighRisk) return 'High Risk';
    if (isHub) return 'Hub';
    return '';
  }

  String get primaryBadgeEmoji {
    if (isGodFunction) return '👑';
    if (isDeadCode) return '💀';
    if (isHighRisk) return '⚠️';
    if (isHub) return '🔥';
    return '';
  }
}
```

---

## 4. File 3: State Providers (`providers/code_topology_provider.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/providers/code_topology_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topology_models.dart';
import '../presentation/widgets/layout_engine.dart';

enum GraphFilterMode { all, mostCalled, highRisk, deadCode }

final selectedNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final activeWorkspacePathProvider =
    StateProvider<String>((ref) => 'c:/horaizon-3.0/shua_code_visualizer/src');
final graphFilterModeProvider =
    StateProvider<GraphFilterMode>((ref) => GraphFilterMode.all);
final selectedLayoutModeProvider =
    StateProvider<LayoutMode>((ref) => LayoutMode.physics);

final codeTopologyProvider = FutureProvider<TopologyGraphDataModel>((ref) async {
  final targetPath = ref.watch(activeWorkspacePathProvider);

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

  try {
    const diskPath = 'c:/horaizon-3.0/code_viz_graph_output.json';
    final file = File(diskPath);
    if (await file.exists()) {
      final text = await file.readAsString();
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return TopologyGraphDataModel.fromJson(jsonMap);
    }
  } catch (_) {}

  return const TopologyGraphDataModel(nodes: [], edges: []);
});
```

---

## 5. File 4: Layout Engine (`presentation/widgets/layout_engine.dart`)

```dart
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
        return _physicsLayout(data, canvasSize);
      case LayoutMode.fileGrouped:
        return _fileGroupedLayout(data);
      case LayoutMode.callFlow:
        return _callFlowLayout(data);
    }
  }

  static GraphLayout _physicsLayout(TopologyGraphDataModel data, Size size) { ... }
  static GraphLayout _fileGroupedLayout(TopologyGraphDataModel data) { ... }
  static GraphLayout _callFlowLayout(TopologyGraphDataModel data) { ... }
}
```

---

## 6. File 5: Code Topology Canvas (`presentation/widgets/code_topology_canvas.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
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
```

---

## 7. File 6: Symbol Inspector Drawer (`presentation/widgets/symbol_inspector_drawer.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/presentation/widgets/symbol_inspector_drawer.dart

import 'package:flutter/material.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';

class SymbolInspectorDrawer extends StatelessWidget {
  final TopologyNodeModel node;
  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context) { ... }
}
```

---

## 8. File 7: Main Screen (`code_topology_screen.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/symbol_inspector_drawer.dart';
import 'providers/code_topology_provider.dart';

class CodeTopologyScreen extends ConsumerWidget { ... }
```
