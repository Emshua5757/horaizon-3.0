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
