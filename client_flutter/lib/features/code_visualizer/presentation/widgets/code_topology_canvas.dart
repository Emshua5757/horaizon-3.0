import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_semantic_palette.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';
import 'layout_engine.dart';

class CodeTopologyCanvas extends ConsumerWidget {
  final TopologyGraphDataModel graphData;

  const CodeTopologyCanvas({super.key, required this.graphData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final selectedNode = ref.watch(selectedNodeProvider);
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase();

    // 1. Calculate positions
    final positionedNodes = LayoutEngine.computeLayout(graphData.nodes);
    final posMap = {for (var p in positionedNodes) p.node.id: p.offset};

    return Container(
      color: cs.surfaceContainerLowest,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(1000),
        minScale: 0.2,
        maxScale: 3.5,
        child: SizedBox(
          width: 2400,
          height: 1800,
          child: Stack(
            children: [
              // Layer 1: Edge Canvas Painter (Curved relationship arrows)
              Positioned.fill(
                child: CustomPaint(
                  painter: EdgePainter(
                    edges: graphData.edges,
                    posMap: posMap,
                    selectedNodeId: selectedNode?.id,
                    primaryColor: cs.primary,
                    secondaryColor: cs.secondary,
                    disabledColor: cs.outlineVariant,
                  ),
                ),
              ),

              // Layer 2: Interactive Node Cards
              ...positionedNodes.map((pn) {
                final isSelected = selectedNode?.id == pn.node.id;
                final isMatch = searchQuery.isNotEmpty &&
                    pn.node.qualifiedName.toLowerCase().contains(searchQuery);

                return Positioned(
                  left: pn.offset.dx,
                  top: pn.offset.dy,
                  child: GestureDetector(
                    onTap: () {
                      ref.read(selectedNodeProvider.notifier).state = pn.node;
                    },
                    child: _NodeCard(
                      node: pn.node,
                      isSelected: isSelected,
                      isMatch: isMatch,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

/// CustomPainter rendering directional bezier curved arrows for edges
class EdgePainter extends CustomPainter {
  final List<TopologyEdgeModel> edges;
  final Map<String, Offset> posMap;
  final String? selectedNodeId;
  final Color primaryColor;
  final Color secondaryColor;
  final Color disabledColor;

  EdgePainter({
    required this.edges,
    required this.posMap,
    required this.selectedNodeId,
    required this.primaryColor,
    required this.secondaryColor,
    required this.disabledColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const nodeWidth = 220.0;
    const nodeHeight = 70.0;

    for (final edge in edges) {
      final startPos = posMap[edge.from];
      final endPos = posMap[edge.to];

      if (startPos == null || endPos == null) continue;

      final start = startPos + const Offset(nodeWidth / 2, nodeHeight / 2);
      final end = endPos + const Offset(nodeWidth / 2, nodeHeight / 2);

      final isConnected = selectedNodeId != null &&
          (edge.from == selectedNodeId || edge.to == selectedNodeId);

      final color = isConnected
          ? (edge.relation == 'Calls' ? primaryColor : secondaryColor)
          : (selectedNodeId != null ? disabledColor.withValues(alpha: 0.3) : disabledColor);

      final strokeWidth = isConnected ? 2.5 : 1.2;

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      // Draw curved bezier path
      final path = Path();
      final controlPoint1 = Offset(start.dx + (end.dx - start.dx) / 2, start.dy);
      final controlPoint2 = Offset(start.dx + (end.dx - start.dx) / 2, end.dy);

      path.moveTo(start.dx, start.dy);
      path.cubicTo(
        controlPoint1.dx,
        controlPoint1.dy,
        controlPoint2.dx,
        controlPoint2.dy,
        end.dx,
        end.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) => true;
}

class _NodeCard extends StatelessWidget {
  final TopologyNodeModel node;
  final bool isSelected;
  final bool isMatch;

  const _NodeCard({
    required this.node,
    required this.isSelected,
    required this.isMatch,
  });

  Color _getComplexityColor(int complexity, AppSemanticPalette? semantic) {
    if (complexity < 5) return semantic?.success ?? const Color(0xFF10B981);
    if (complexity <= 10) return semantic?.warning ?? Colors.amber.shade700;
    return semantic?.critical ?? const Color(0xFFF43F5E);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final compColor = _getComplexityColor(node.complexity, semantic);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected ? cs.primaryContainer : cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : (isMatch ? Colors.amber : cs.outlineVariant),
          width: isSelected || isMatch ? 2.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Kind & Complexity Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.kind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: compColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'CC ${node.complexity}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: compColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Row 2: Qualified Name
          Text(
            node.qualifiedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          const SizedBox(height: 4),

          // Row 3: File Base Name
          Text(
            node.file.split(RegExp(r'[/\\]')).last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
