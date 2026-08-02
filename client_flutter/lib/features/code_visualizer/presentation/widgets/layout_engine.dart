import 'package:flutter/material.dart';
import '../../models/topology_models.dart';

class NodePosition {
  final TopologyNodeModel node;
  final Offset offset;
  final Size size;

  const NodePosition({
    required this.node,
    required this.offset,
    required this.size,
  });
}

class LayoutEngine {
  /// Computes 2D grid/layered layout positions for nodes on the canvas
  static List<NodePosition> computeLayout(List<TopologyNodeModel> nodes) {
    if (nodes.isEmpty) return [];

    final result = <NodePosition>[];
    const double colWidth = 290.0;
    const double rowHeight = 150.0;
    const int maxCols = 4;

    // Group nodes by file/module
    final grouped = <String, List<TopologyNodeModel>>{};
    for (final node in nodes) {
      final key = node.file.isEmpty ? 'root' : node.file;
      grouped.putIfAbsent(key, () => []).add(node);
    }

    int colIndex = 0;
    int rowIndex = 0;

    grouped.forEach((fileKey, groupNodes) {
      for (final node in groupNodes) {
        final totalCalls = node.fanIn + node.fanOut;
        final isHub = totalCalls >= 3 || node.riskScore >= 10.0;

        final width = isHub ? 250.0 : 210.0;
        final height = isHub ? 80.0 : 65.0;

        final x = colIndex * colWidth + 60.0;
        final y = rowIndex * rowHeight + 60.0;

        result.add(NodePosition(
          node: node,
          offset: Offset(x, y),
          size: Size(width, height),
        ));

        colIndex++;
        if (colIndex >= maxCols) {
          colIndex = 0;
          rowIndex++;
        }
      }
    });

    return result;
  }
}
