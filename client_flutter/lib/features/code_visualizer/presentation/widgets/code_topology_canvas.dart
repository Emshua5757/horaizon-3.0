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
    final filterMode = ref.watch(graphFilterModeProvider);

    // Apply Filter Mode
    var filteredNodes = graphData.nodes;
    switch (filterMode) {
      case GraphFilterMode.mostCalled:
        filteredNodes = graphData.nodes
            .where((n) => n.fanIn > 0 || n.fanOut > 0)
            .toList()
          ..sort((a, b) => (b.fanIn + b.fanOut).compareTo(a.fanIn + a.fanOut));
        break;
      case GraphFilterMode.highRisk:
        filteredNodes = graphData.nodes.where((n) => n.riskScore > 0.0).toList()
          ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
        break;
      case GraphFilterMode.deadCode:
        filteredNodes = graphData.nodes.where((n) => n.isOrphan).toList();
        break;
      case GraphFilterMode.all:
        break;
    }

    // 1. Calculate positions
    final positionedNodes = LayoutEngine.computeLayout(filteredNodes);
    final posMap = {for (var p in positionedNodes) p.node.id: p};

    return Container(
      color: cs.surfaceContainerLowest,
      child: InteractiveViewer(
        boundaryMargin: const EdgeInsets.all(1200),
        minScale: 0.15,
        maxScale: 3.5,
        child: SizedBox(
          width: 2600,
          height: 2000,
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
                      position: pn,
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
  final Map<String, NodePosition> posMap;
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
    for (final edge in edges) {
      final startPos = posMap[edge.from];
      final endPos = posMap[edge.to];

      if (startPos == null || endPos == null) continue;

      final start = startPos.offset + Offset(startPos.size.width / 2, startPos.size.height / 2);
      final end = endPos.offset + Offset(endPos.size.width / 2, endPos.size.height / 2);

      final isConnected = selectedNodeId != null &&
          (edge.from == selectedNodeId || edge.to == selectedNodeId);

      final color = isConnected
          ? (edge.relation == 'Calls' ? primaryColor : secondaryColor)
          : (selectedNodeId != null ? disabledColor.withValues(alpha: 0.2) : disabledColor.withValues(alpha: 0.6));

      final strokeWidth = isConnected ? 3.0 : 1.5;

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
  final NodePosition position;
  final bool isSelected;
  final bool isMatch;

  const _NodeCard({
    required this.position,
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
    final node = position.node;
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final compColor = _getComplexityColor(node.complexity, semantic);

    final totalCalls = node.fanIn + node.fanOut;
    final isHub = totalCalls >= 3 || node.riskScore >= 10.0;

    return Container(
      width: position.size.width,
      constraints: BoxConstraints(minHeight: position.size.height),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? cs.primaryContainer
            : (isHub ? cs.surfaceContainerHighest : cs.surface),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? cs.primary
              : (isMatch
                  ? Colors.amber
                  : (isHub ? cs.primary.withValues(alpha: 0.6) : cs.outlineVariant)),
          width: isSelected || isMatch ? 2.5 : (isHub ? 1.8 : 1.0),
        ),
        boxShadow: [
          if (isHub || isSelected)
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.18),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: ClipRect(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Row 1: Kind & Call Count Badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  node.kind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              if (totalCalls > 0) ...[
                Icon(Icons.call_made_rounded, size: 10, color: cs.primary),
                const SizedBox(width: 2),
                Text(
                  '${node.fanIn} in / ${node.fanOut} out',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: compColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Row 2: Qualified Name
          Text(
            node.qualifiedName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: isHub ? 12 : 11,
              fontWeight: FontWeight.bold,
              color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),

          // Row 3: File Path
          Text(
            node.file.split(RegExp(r'[/\\]')).last,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    ),
    );
  }
}
