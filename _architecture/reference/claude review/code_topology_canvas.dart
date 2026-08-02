// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';
import '../../providers/code_topology_provider.dart';
import 'layout_engine.dart';

class CodeTopologyCanvas extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;
  const CodeTopologyCanvas({super.key, required this.graphData});

  @override
  ConsumerState<CodeTopologyCanvas> createState() =>
      _CodeTopologyCanvasState();
}

class _CodeTopologyCanvasState extends ConsumerState<CodeTopologyCanvas> {
  GraphLayout? _cachedLayout;
  LayoutMode? _cachedMode;
  TopologyGraphDataModel? _cachedData;

  GraphLayout _layoutFor(LayoutMode mode) {
    if (_cachedLayout != null &&
        _cachedMode == mode &&
        identical(_cachedData, widget.graphData)) {
      return _cachedLayout!;
    }
    final layout =
        GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    _cachedLayout = layout;
    _cachedMode = mode;
    _cachedData = widget.graphData;
    return layout;
  }

  Set<String> _neighborhoodOf(String nodeId) {
    final ids = <String>{nodeId};
    for (final e in widget.graphData.edges) {
      if (e.from == nodeId) ids.add(e.to);
      if (e.to == nodeId) ids.add(e.from);
    }
    return ids;
  }

  bool _passesFilter(
    TopologyNodeModel n,
    GraphFilterMode filter,
    String query,
  ) {
    if (query.isNotEmpty &&
        !n.qualifiedName.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    switch (filter) {
      case GraphFilterMode.all:
        return true;
      case GraphFilterMode.mostCalled:
        return (n.fanIn + n.fanOut) >= 4;
      case GraphFilterMode.highRisk:
        return n.isHighRisk || n.isGodFunction;
      case GraphFilterMode.deadCode:
        return n.isDeadCode;
    }
  }

  TopologyNodeModel? _hitTest(Offset point, GraphLayout layout) {
    for (final n in widget.graphData.nodes.reversed) {
      final pos = layout.positions[n.id];
      if (pos == null) continue;
      if ((pos - point).distance <= _nodeRadius(n) + 4) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedLayoutModeProvider);
    final filter = ref.watch(graphFilterModeProvider);
    final query = ref.watch(searchQueryProvider);
    final selected = ref.watch(selectedNodeProvider);
    final layout = _layoutFor(mode);
    final highlighted =
        selected != null ? _neighborhoodOf(selected.id) : null;

    final width = max(layout.contentSize.width, 900.0);
    final height = max(layout.contentSize.height, 700.0);

    return Container(
      color: const Color(0xFF0E1116),
      child: InteractiveViewer(
        minScale: 0.12,
        maxScale: 3.0,
        constrained: false,
        boundaryMargin: const EdgeInsets.all(500),
        child: SizedBox(
          width: width,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final tapped = _hitTest(details.localPosition, layout);
              ref.read(selectedNodeProvider.notifier).state = tapped;
            },
            child: CustomPaint(
              size: Size(width, height),
              painter: _TopologyPainter(
                graphData: widget.graphData,
                layout: layout,
                filter: filter,
                query: query,
                selectedId: selected?.id,
                highlighted: highlighted,
                passesFilter: _passesFilter,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _nodeRadius(TopologyNodeModel n) {
  const base = 13.0;
  final boost = min((n.fanIn + n.fanOut).toDouble(), 22.0) * 0.85;
  return base + boost;
}

class _TopologyPainter extends CustomPainter {
  final TopologyGraphDataModel graphData;
  final GraphLayout layout;
  final GraphFilterMode filter;
  final String query;
  final String? selectedId;
  final Set<String>? highlighted;
  final bool Function(TopologyNodeModel, GraphFilterMode, String) passesFilter;

  _TopologyPainter({
    required this.graphData,
    required this.layout,
    required this.filter,
    required this.query,
    required this.selectedId,
    required this.highlighted,
    required this.passesFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleIds = {
      for (final n in graphData.nodes)
        if (passesFilter(n, filter, query)) n.id,
    };

    _paintFileGroups(canvas);
    _paintEdges(canvas, visibleIds);
    _paintNodes(canvas, visibleIds);
  }

  void _paintFileGroups(Canvas canvas) {
    for (final entry in layout.fileGroups.entries) {
      final fill = Paint()
        ..color = const Color(0x14FFFFFF)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final rrect =
          RRect.fromRectAndRadius(entry.value, const Radius.circular(14));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, border);

      final label = entry.key.split(RegExp(r'[/\\]')).last;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Color(0xAAE0E0E0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: entry.value.width - 20);
      tp.paint(canvas, entry.value.topLeft + const Offset(12, 8));
    }
  }

  void _paintEdges(Canvas canvas, Set<String> visibleIds) {
    for (final e in graphData.edges) {
      if (!visibleIds.contains(e.from) || !visibleIds.contains(e.to)) {
        continue;
      }
      final from = layout.positions[e.from];
      final to = layout.positions[e.to];
      if (from == null || to == null) continue;

      final isHighlighted = highlighted != null &&
          highlighted!.contains(e.from) &&
          highlighted!.contains(e.to);
      final dimmed = highlighted != null && !isHighlighted;

      final baseColor =
          e.relation == 'Imports' ? const Color(0xFF64B5F6) : const Color(0xFFFFAB40);
      final opacity = dimmed ? 0.08 : (isHighlighted ? 0.95 : 0.55);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = isHighlighted ? 2.4 : 1.2
        ..color = baseColor.withOpacity(opacity);

      final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2);
      final control =
          mid + Offset((to.dy - from.dy) * 0.15, (from.dx - to.dx) * 0.15);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(control.dx, control.dy, to.dx, to.dy);
      canvas.drawPath(path, paint);
    }
  }

  void _paintNodes(Canvas canvas, Set<String> visibleIds) {
    for (final n in graphData.nodes) {
      if (!visibleIds.contains(n.id)) continue;
      final pos = layout.positions[n.id];
      if (pos == null) continue;

      final isSelected = n.id == selectedId;
      final isDimmed = highlighted != null && !highlighted!.contains(n.id);
      final radius = _nodeRadius(n);

      Color fill;
      if (n.isGodFunction) {
        fill = const Color(0xFFAB47BC);
      } else if (n.isDeadCode) {
        fill = const Color(0xFF757575);
      } else if (n.isHighRisk) {
        fill = const Color(0xFFEF5350);
      } else if (n.isHub) {
        fill = const Color(0xFFFFA726);
      } else {
        fill = const Color(0xFF42A5F5);
      }
      if (isDimmed) fill = fill.withOpacity(0.16);

      if (n.isHub && !isDimmed) {
        final halo = Paint()
          ..color = fill.withOpacity(0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 8, halo);
      }

      canvas.drawCircle(pos, radius, Paint()..color = fill);

      if (isSelected) {
        canvas.drawCircle(
          pos,
          radius + 3,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5,
        );
      }

      if (!isDimmed) {
        final badge = n.primaryBadgeEmoji;
        if (badge.isNotEmpty) {
          final badgeTp = TextPainter(
            text: TextSpan(text: badge, style: const TextStyle(fontSize: 11)),
            textDirection: TextDirection.ltr,
          )..layout();
          badgeTp.paint(
            canvas,
            pos + Offset(radius - 4, -radius - 2),
          );
        }
      }

      final label = n.qualifiedName.length > 20
          ? '${n.qualifiedName.substring(0, 18)}…'
          : n.qualifiedName;
      final labelTp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isDimmed ? const Color(0x33FFFFFF) : Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: 130);
      labelTp.paint(canvas, pos + Offset(-labelTp.width / 2, radius + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.filter != filter ||
        oldDelegate.query != query ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.highlighted != highlighted ||
        !identical(oldDelegate.layout, layout);
  }
}
