import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/widgets/code_topology_canvas.dart';
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
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                const Spacer(),

                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Rescan Repository',
                  onPressed: () => ref.invalidate(codeTopologyProvider),
                ),
              ],
            ),
          ),

          // Main View (Canvas + Inspector Drawer)
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
              data: (graphData) => Row(
                children: [
                  Expanded(
                    child: CodeTopologyCanvas(graphData: graphData),
                  ),
                  if (selectedNode != null)
                    SymbolInspectorDrawer(node: selectedNode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
