// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/copilot_chat_drawer.dart';
import '../governor/governor_provider.dart';
import 'models/topology_insights.dart';
import 'models/topology_models.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/layout_engine.dart';
import 'presentation/widgets/path_tracer_panel.dart';
import 'presentation/widgets/symbol_inspector_drawer.dart';
import 'providers/code_topology_provider.dart';

final isAiCopilotOpenProvider = StateProvider<bool>((ref) => false);

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

  void _showPhysicsTuningDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final repulsion = ref.watch(physicsRepulsionProvider);
            final spring = ref.watch(physicsSpringProvider);
            final modulePull = ref.watch(physicsModuleAttractorProvider);
            final gravity = ref.watch(physicsGravityProvider);
            final maxVel = ref.watch(physicsMaxVelocityProvider);
            final damping = ref.watch(physicsDampingProvider);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Physics Simulation Tuning',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Divider(height: 16, color: cs.outlineVariant),

                    // Max Velocity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Max Particle Speed Limit:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text('${maxVel.toInt()} px/frame', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: maxVel,
                        min: 10.0,
                        max: 100.0,
                        divisions: 45,
                        onChanged: (val) {
                          ref.read(physicsMaxVelocityProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Friction Damping Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Friction Damping:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(damping.toStringAsFixed(2), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: damping,
                        min: 0.50,
                        max: 0.95,
                        divisions: 45,
                        onChanged: (val) {
                          ref.read(physicsDampingProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Repulsion Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Repulsion Force:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text('${repulsion.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: repulsion,
                        min: 3000,
                        max: 50000,
                        divisions: 47,
                        onChanged: (val) {
                          ref.read(physicsRepulsionProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Spring Attraction Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spring Attraction:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(spring.toStringAsFixed(3), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: spring,
                        min: 0.005,
                        max: 0.20,
                        divisions: 39,
                        onChanged: (val) {
                          ref.read(physicsSpringProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Module Galaxy Pull Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Module Constellation Pull:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(modulePull.toStringAsFixed(3), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: modulePull,
                        min: 0.005,
                        max: 0.10,
                        divisions: 38,
                        onChanged: (val) {
                          ref.read(physicsModuleAttractorProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Center Gravity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Center Gravity:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(gravity.toStringAsFixed(4), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: gravity,
                        min: 0.0005,
                        max: 0.01,
                        divisions: 38,
                        onChanged: (val) {
                          ref.read(physicsGravityProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
    final isCopilotOpen = ref.watch(isAiCopilotOpenProvider);

    final graphData = topologyAsync.valueOrNull;

    final governorAsync = ref.watch(governorStatusProvider);
    final governorStatus = governorAsync.valueOrNull;
    final codeModule = governorStatus?.modules.firstWhere(
      (m) => m.name.contains('code'),
      orElse: () => const ModuleStatus(name: 'shua_code_visualizer', state: ModuleState.running, ramMb: 245.0, cpuPercent: 0.8),
    );
    final isBackendFrozen = codeModule?.state == ModuleState.sleeping || codeModule?.state == ModuleState.stopped;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            if (isBackendFrozen)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Microservice Backend is ${codeModule?.state == ModuleState.stopped ? "Stopped (0 MB RAM)" : "Frozen (SIGSTOP)"}. Live AST analysis is paused.',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF59E0B),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: () {
                        ref.read(governorStatusProvider.notifier).wakeModule('shua_code_visualizer');
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 16),
                      label: const Text('▷ Wake Microservice', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            // Clean 2-Tier Header Toolbar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier 1: Title, Full Workspace Path Breadcrumb, Change Folder Button, and Metric Badge
                  Row(
                    children: [
                      Icon(Icons.hub_rounded, color: cs.primary, size: 22),
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

                      // Full Path Breadcrumb Pill
                      Expanded(
                        child: Tooltip(
                          message: activePath.isEmpty ? 'No path selected' : activePath,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_rounded, size: 14, color: cs.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    activePath.isEmpty ? 'Select Workspace Folder...' : activePath,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Folder Picker Button
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.folder_open_rounded, size: 14),
                        label: const Text('Change Folder', style: TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _pickRepositoryFolder(ref),
                      ),
                      const SizedBox(width: 8),

                      // Graph Nodes & Edges Metric Badge
                      if (graphData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${graphData.nodes.length} Nodes · ${graphData.edges.length} Edges',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tier 2: Viewport Controls & Filter Chips (Wrap Layout)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                      // Layout Mode Segmented Control
                      SegmentedButton<LayoutMode>(
                        style: SegmentedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: LayoutMode.physics,
                            label: Text('⚡ Physics Cluster'),
                          ),
                          ButtonSegment(
                            value: LayoutMode.fileGrouped,
                            label: Text('📁 File Grouped'),
                          ),
                          ButtonSegment(
                            value: LayoutMode.callFlow,
                            label: Text('🌲 Call Flow'),
                          ),
                        ],
                        selected: {currentLayout},
                        onSelectionChanged: (set) {
                          ref.read(selectedLayoutModeProvider.notifier).state = set.first;
                        },
                      ),

                      // Search Bar
                      SizedBox(
                        width: 160,
                        height: 32,
                        child: TextField(
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                          style: TextStyle(fontSize: 12, color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search symbol...',
                            hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search_rounded, size: 14, color: cs.onSurfaceVariant),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                          ),
                        ),
                      ),

                      // N-Hop Subgraph Isolation Depth Dropdown
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
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

                      // Physics Tuning Slider Button
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        tooltip: 'Adjust Physics Sliders',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showPhysicsTuningDialog(context, ref),
                      ),

                      // Multi-Select Insight Filter Chips with Dynamic Count Badges
                      _FilterChip(
                        label: 'All',
                        count: _countForFilter(graphData, null),
                        isSelected: activeFilters.isEmpty,
                        onSelected: (_) {
                          ref.read(activeFiltersProvider.notifier).state = {};
                        },
                      ),
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

                      // AND / OR Toggle Button
                      if (activeFilters.length > 1)
                        InputChip(
                          avatar: Icon(matchAll ? Icons.rule_rounded : Icons.alt_route_rounded, size: 12),
                          label: Text(
                            matchAll ? 'MATCH ALL' : 'MATCH ANY',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          selected: matchAll,
                          onPressed: () {
                            ref.read(filterMatchAllProvider.notifier).state = !matchAll;
                          },
                        ),

                      // Path Tracer Reset Button
                      if (pathStart != null || pathEnd != null)
                        ActionChip(
                          avatar: const Icon(Icons.route_rounded, size: 12),
                          label: Text(
                            'Path: ${pathStart?.qualifiedName ?? '?'} ➔ ${pathEnd?.qualifiedName ?? '?'}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          onPressed: () {
                            ref.read(pathStartNodeProvider.notifier).state = null;
                            ref.read(pathEndNodeProvider.notifier).state = null;
                          },
                        ),

                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Rescan Repository',
                        onPressed: () => ref.invalidate(codeTopologyProvider),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCopilotOpen ? cs.primary : cs.primaryContainer,
                          foregroundColor: isCopilotOpen ? cs.onPrimary : cs.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          ref.read(isAiCopilotOpenProvider.notifier).state = !isCopilotOpen;
                        },
                        icon: const Icon(Icons.smart_toy_rounded, size: 16),
                        label: const Text('🤖 JOSH Copilot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main View (Canvas + Inspector Drawer + Path Tracer Panel + Copilot Drawer)
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
                        if (selectedNode != null && !isCopilotOpen)
                          SymbolInspectorDrawer(node: selectedNode),
                        if (isCopilotOpen)
                          CopilotChatDrawer(
                            contextHint: 'code',
                            onClose: () => ref.read(isAiCopilotOpenProvider.notifier).state = false,
                          ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: PathTracerPanel(graphData: data),
                    ),
                    if (!isCopilotOpen)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.extended(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          onPressed: () => ref.read(isAiCopilotOpenProvider.notifier).state = true,
                          icon: const Icon(Icons.smart_toy_rounded, size: 18),
                          label: const Text('JOSH AI Copilot', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
      label: Text('$label ($count)', style: const TextStyle(fontSize: 10)),
      selected: isSelected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
