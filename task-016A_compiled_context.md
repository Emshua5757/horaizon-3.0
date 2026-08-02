# TASK-016A — Compiled Context & Architecture Package

> **Purpose**: Compiled context artifact containing task specifications, sample exported JSON schema, Graphify multi-view requirements, and complete Flutter codebase for `lib/features/code_visualizer/`.

---

## 1. Active Task Specification (`TASK-016A_flutter_code_topology_canvas.md`)

```markdown
# TASK-016A — client_flutter Native Code Topology & Graphify Multi-View Engine

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
```

---

## 2. Sample Graph JSON Output (`code_viz_graph_output.json`)

```json
{
  "nodes": [
    {
      "id": "shua_code_visualizer/src/broker/ipc_client.rs:IpcClient::start_ipc_loop",
      "kind": "function",
      "qualified_name": "IpcClient::start_ipc_loop",
      "file": "shua_code_visualizer/src/broker/ipc_client.rs",
      "line": 16,
      "params": [
        { "name": "ipc_port", "type_name": "u16", "is_optional": false },
        { "name": "graph", "type_name": "Arc<Mutex<CodeGraph>>", "is_optional": false }
      ],
      "return_type": "mpsc::UnboundedSender<TopologyDeltaEvent>",
      "complexity": 4,
      "side_effects": ["io", "lock", "stateMutation"],
      "intent": "Connects to parent governor IPC WebSocket server, auto-registers tools, and enters duplex message loop.",
      "loc": 116,
      "is_public": true,
      "is_test": false,
      "fan_in": 2,
      "fan_out": 0,
      "risk_score": 8.0,
      "is_orphan": false,
      "exceeds_param_threshold": false,
      "exceeds_complexity_threshold": false,
      "exceeds_loc_threshold": false
    },
    {
      "id": "shua_code_visualizer/src/broker/parent_link.rs:ParentLink::spawn_parent_death_monitor",
      "kind": "function",
      "qualified_name": "ParentLink::spawn_parent_death_monitor",
      "file": "shua_code_visualizer/src/broker/parent_link.rs",
      "line": 35,
      "params": [{ "name": "parent_pid", "type_name": "u32", "is_optional": false }],
      "return_type": null,
      "complexity": 2,
      "side_effects": ["io"],
      "intent": "Spawns a background task monitoring parent_pid. If parent process terminates, self-terminates.",
      "loc": 14,
      "is_public": true,
      "is_test": false,
      "fan_in": 1,
      "fan_out": 1,
      "risk_score": 2.0,
      "is_orphan": false
    }
  ],
  "edges": [
    {
      "from": "shua_code_visualizer/src/main.rs:main",
      "to": "shua_code_visualizer/src/broker/ipc_client.rs:IpcClient::start_ipc_loop",
      "relation": "Calls"
    },
    {
      "from": "shua_code_visualizer/src/main.rs:main",
      "to": "shua_code_visualizer/src/broker/parent_link.rs:ParentLink::spawn_parent_death_monitor",
      "relation": "Calls"
    }
  ]
}
```

---

## 3. Flutter Data Models (`topology_models.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/models/topology_models.dart

class ParamModel {
  final String name;
  final String typeName;
  final bool isOptional;

  const ParamModel({
    required this.name,
    required this.typeName,
    this.isOptional = false,
  });

  factory ParamModel.fromJson(Map<String, dynamic> json) {
    return ParamModel(
      name: json['name'] as String? ?? '',
      typeName: json['type_name'] as String? ?? 'dynamic',
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

## 4. State Provider (`code_topology_provider.dart`)

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

## 5. Main Screen (`code_topology_screen.dart`)

```dart
// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      ref.invalidate(codeTopologyProvider);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topologyAsync = ref.watch(codeTopologyProvider);
    final selectedNode = ref.watch(selectedNodeProvider);
    final activePath = ref.watch(activeWorkspacePathProvider);
    final currentFilter = ref.watch(graphFilterModeProvider);
    final currentLayout = ref.watch(selectedLayoutModeProvider);

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
                    onPressed: () => _pickRepositoryFolder(ref),
                  ),
                  const SizedBox(width: 12),

                  // View Mode Selector (Physics Cluster / File Grouped / Call Flow)
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Filter Segmented Buttons
                  SegmentedButton<GraphFilterMode>(
                    segments: const [
                      ButtonSegment(value: GraphFilterMode.all, label: Text('All')),
                      ButtonSegment(value: GraphFilterMode.mostCalled, label: Text('🔥 Most Called')),
                      ButtonSegment(value: GraphFilterMode.highRisk, label: Text('⚠️ High Risk')),
                      ButtonSegment(value: GraphFilterMode.deadCode, label: Text('💀 Dead Code')),
                    ],
                    selected: {currentFilter},
                    onSelectionChanged: (set) {
                      ref.read(graphFilterModeProvider.notifier).state = set.first;
                    },
                  ),
                  const SizedBox(width: 16),

                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => ref.invalidate(codeTopologyProvider),
                  ),
                ],
              ),
            ),
          ),

          // Main Canvas & Drawer
          Expanded(
            child: topologyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (graphData) => Row(
                children: [
                  Expanded(child: CodeTopologyCanvas(graphData: graphData)),
                  if (selectedNode != null) SymbolInspectorDrawer(node: selectedNode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Summary of Planned Architectural Improvements

1. **Graphify Force-Directed Physics Clustering**:
   - Coulomb's inverse-square repulsion between non-connected nodes ($F = k/d^2$).
   - Hooke's spring attraction along `Calls` and `Imports` edges ($F = k \cdot (d - d_0)$).
   - Center gravity pull ($F = k \cdot \Delta_{center}$) preventing node drift.
2. **3 Visual Layout Modes**:
   - `⚡ Physics Cluster`: Floating organic communities.
   - `📁 File Grouped`: Modular file containers.
   - `🌲 Call Flow`: Multi-tier call hierarchy DAG tree.
3. **Neighborhood Highlighting**:
   - Clicking a node highlights all direct caller/callee connections in primary/secondary accent colors while dimming unrelated nodes.
