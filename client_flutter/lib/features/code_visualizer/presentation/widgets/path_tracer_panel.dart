// File: client_flutter/lib/features/code_visualizer/presentation/widgets/path_tracer_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';

class PathTracerPanel extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;
  const PathTracerPanel({super.key, required this.graphData});

  @override
  ConsumerState<PathTracerPanel> createState() => _PathTracerPanelState();
}

class _PathTracerPanelState extends ConsumerState<PathTracerPanel> {
  bool _directed = false;

  @override
  Widget build(BuildContext context) {
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);
    final index = ref.watch(graphIndexProvider);

    if (pathStart == null && pathEnd == null) {
      return const SizedBox.shrink();
    }

    final path = (pathStart != null && pathEnd != null && index != null)
        ? index.tracePathLocal(pathStart.id, pathEnd.id, directed: _directed)
        : null;

    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Shortest Path Tracer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                onPressed: () {
                  ref.read(pathStartNodeProvider.notifier).state = null;
                  ref.read(pathEndNodeProvider.notifier).state = null;
                },
              ),
            ],
          ),
          const Divider(color: Color(0xFF30363D)),

          // Start & End Pickers
          _NodePickerTile(
            label: 'Start (A)',
            node: pathStart,
            color: const Color(0xFF42A5F5),
            onClear: () => ref.read(pathStartNodeProvider.notifier).state = null,
          ),
          const SizedBox(height: 6),
          _NodePickerTile(
            label: 'Target (B)',
            node: pathEnd,
            color: const Color(0xFFAB47BC),
            onClear: () => ref.read(pathEndNodeProvider.notifier).state = null,
          ),
          const SizedBox(height: 10),

          // Directed Toggle
          Row(
            children: [
              const Text(
                'Directed Call Edges',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Switch(
                value: _directed,
                onChanged: (val) => setState(() => _directed = val),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hop-by-Hop Call Chain Sequence List
          if (path != null && path.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x2200E676),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Path Found: ${path.length - 1} Call Hop(s)',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: path.length,
                separatorBuilder: (_, __) => const Icon(
                  Icons.south_rounded,
                  size: 14,
                  color: Color(0xFF00E676),
                ),
                itemBuilder: (context, i) {
                  final nodeId = path[i];
                  final node = index?.nodeMap[nodeId];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${i + 1}. ${node?.qualifiedName ?? nodeId}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ] else if (pathStart != null && pathEnd != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No call path connects Start and Target.',
                style: TextStyle(color: Color(0xFFEF5350), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NodePickerTile extends StatelessWidget {
  final String label;
  final TopologyNodeModel? node;
  final Color color;
  final VoidCallback onClear;

  const _NodePickerTile({
    required this.label,
    required this.node,
    required this.color,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node?.qualifiedName ?? 'Select from canvas...',
              style: TextStyle(
                color: node != null ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: node != null ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (node != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
            ),
        ],
      ),
    );
  }
}
