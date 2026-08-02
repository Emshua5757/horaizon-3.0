// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'models/topology_insights.dart';
import 'models/topology_models.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/layout_engine.dart';
import 'presentation/widgets/path_tracer_panel.dart';
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
      ref.read(pathStartNodeProvider.notifier).state = null;
      ref.read(pathEndNodeProvider.notifier).state = null;
      ref.invalidate(codeTopologyProvider);
    }
  }

  int _countForFilter(TopologyGraphDataModel? data, InsightFilter? filter) {
    if (data == null || data.nodes.isEmpty) return 0;
    if (filter == null) return data.nodes.length;
    switch (filter) {
      case InsightFilter.godFunctions:
        return data.nodes.where((n) => n.isGodFunction).length;
      case InsightFilter.hubs:
        return data.nodes.where((n) => n.isHub).length;
      case InsightFilter.highRisk:
        return data.nodes.where((n) => n.isHighRisk).length;
      case InsightFilter.deadCode:
        return data.nodes.where((n) => n.isDeadCode).length;
      case InsightFilter.publicApis:
        return data.nodes.where((n) => n.isPublicApi).length;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topologyAsync = ref.watch(codeTopologyProvider);
    final selectedNode = ref.watch(selectedNodeProvider);
    final activePath = ref.watch(activeWorkspacePathProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final currentLayout = ref.watch(selectedLayoutModeProvider);
    final isolationDepth = ref.watch(isolationDepthProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final graphData = topologyAsync.valueOrNull;

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
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () => _pickRepositoryFolder(ref),
                  ),
                  const SizedBox(width: 12),

                  // Layout Mode Segmented Control
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
                    width: 170,
                    height: 36,
                    child: TextField(
                      onChanged: (val) {
                        ref.read(searchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search symbol...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 16),
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // N-Hop Subgraph Isolation Depth Dropdown
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cs.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: isolationDepth,
                        style: TextStyle(fontSize: 11, color: cs.onSurface),
                        dropdownColor: cs.surface,
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('🌐 Global Graph')),
                          DropdownMenuItem(value: 1, child: Text('🎯 1-Hop Isolation')),
                          DropdownMenuItem(value: 2, child: Text('🕸️ 2-Hop Isolation')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(isolationDepthProvider.notifier).state = val;
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Multi-Select Insight Filter Chips with Dynamic Count Badges
                  _FilterChip(
                    label: 'All',
                    count: _countForFilter(graphData, null),
                    isSelected: activeFilters.isEmpty,
                    onSelected: (_) {
                      ref.read(activeFiltersProvider.notifier).state = {};
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '👑 God Functions',
                    count: _countForFilter(graphData, InsightFilter.godFunctions),
                    isSelected: activeFilters.contains(InsightFilter.godFunctions),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.godFunctions) : updated.remove(InsightFilter.godFunctions);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '🔥 Hubs',
                    count: _countForFilter(graphData, InsightFilter.hubs),
                    isSelected: activeFilters.contains(InsightFilter.hubs),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.hubs) : updated.remove(InsightFilter.hubs);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '⚠️ High Risk',
                    count: _countForFilter(graphData, InsightFilter.highRisk),
                    isSelected: activeFilters.contains(InsightFilter.highRisk),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.highRisk) : updated.remove(InsightFilter.highRisk);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 6),
                  _FilterChip(
                    label: '💀 Dead Code',
                    count: _countForFilter(graphData, InsightFilter.deadCode),
                    isSelected: activeFilters.contains(InsightFilter.deadCode),
                    onSelected: (val) {
                      final updated = Set<InsightFilter>.from(activeFilters);
                      val ? updated.add(InsightFilter.deadCode) : updated.remove(InsightFilter.deadCode);
                      ref.read(activeFiltersProvider.notifier).state = updated;
                    },
                  ),
                  const SizedBox(width: 8),

                  // AND / OR Toggle Button
                  if (activeFilters.length > 1)
                    InputChip(
                      avatar: Icon(matchAll ? Icons.rule_rounded : Icons.alt_route_rounded, size: 14),
                      label: Text(matchAll ? 'MATCH ALL (AND)' : 'MATCH ANY (OR)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      selected: matchAll,
                      onPressed: () {
                        ref.read(filterMatchAllProvider.notifier).state = !matchAll;
                      },
                    ),

                  const SizedBox(width: 12),

                  // Path Tracer Reset Button
                  if (pathStart != null || pathEnd != null)
                    ActionChip(
                      avatar: const Icon(Icons.route_rounded, size: 14),
                      label: Text('Path: ${pathStart?.qualifiedName ?? '?'} ➔ ${pathEnd?.qualifiedName ?? '?'}'),
                      onPressed: () {
                        ref.read(pathStartNodeProvider.notifier).state = null;
                        ref.read(pathEndNodeProvider.notifier).state = null;
                      },
                    ),

                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Rescan Repository',
                    onPressed: () => ref.invalidate(codeTopologyProvider),
                  ),
                ],
              ),
            ),
          ),

          // Main View (Canvas + Inspector Drawer + Path Tracer Panel)
          Expanded(
            child: topologyAsync.when(
              loading: () => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(
                      'Parsing repository symbols and building topology graph...',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              error: (err, stack) => Center(child: Text('Error loading topology: $err')),
              data: (data) => Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CodeTopologyCanvas(graphData: data),
                      ),
                      if (selectedNode != null)
                        SymbolInspectorDrawer(node: selectedNode),
                    ],
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: PathTracerPanel(graphData: data),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)', style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
