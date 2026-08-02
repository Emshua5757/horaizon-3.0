import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/symbol_inspector_drawer.dart';
import 'providers/code_topology_provider.dart';

class CodeTopologyScreen extends ConsumerWidget {
  const CodeTopologyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topologyAsync = ref.watch(codeTopologyProvider);
    final selectedNode = ref.watch(selectedNodeProvider);

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
                  'Code Topology Visualizer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 16),

                // Search Bar
                SizedBox(
                  width: 220,
                  height: 36,
                  child: TextField(
                    onChanged: (val) {
                      ref.read(searchQueryProvider.notifier).state = val;
                    },
                    decoration: InputDecoration(
                      hintText: 'Search symbol...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 18),
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Spacer(),

                // Module Controls (Start / Freeze / Stop)
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: const Text('Start Daemon'),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.ac_unit_rounded, size: 16),
                  label: const Text('Freeze (cgroup)'),
                  onPressed: () {},
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Reload Graph',
                  onPressed: () => ref.invalidate(codeTopologyProvider),
                ),
              ],
            ),
          ),

          // Main View (Canvas + Inspector Drawer)
          Expanded(
            child: topologyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
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
