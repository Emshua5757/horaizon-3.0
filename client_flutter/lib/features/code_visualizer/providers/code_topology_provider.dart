// File: client_flutter/lib/features/code_visualizer/providers/code_topology_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topology_models.dart';
import '../models/topology_insights.dart';
import '../presentation/widgets/layout_engine.dart';
import 'topology_data_source.dart';

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

/// Provider constructing the active TopologyDataSource (Standalone vs Managed)
final topologyDataSourceProvider = Provider<TopologyDataSource>((ref) {
  final targetPath = ref.watch(activeWorkspacePathProvider);
  return StandaloneDataSource(workspacePath: targetPath);
});

/// FutureProvider loading the current TopologyGraphDataModel snapshot
final codeTopologyProvider = FutureProvider<TopologyGraphDataModel>((ref) async {
  final dataSource = ref.watch(topologyDataSourceProvider);
  return dataSource.loadSnapshot();
});

/// Provider computing and caching the GraphIndex structure once per graph snapshot
final graphIndexProvider = Provider<GraphIndex?>((ref) {
  final topologyAsync = ref.watch(codeTopologyProvider);
  return topologyAsync.when(
    data: (graphData) => GraphIndex.build(graphData),
    loading: () => null,
    error: (_, __) => null,
  );
});
