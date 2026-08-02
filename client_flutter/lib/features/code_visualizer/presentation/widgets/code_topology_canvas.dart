// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _CodeTopologyCanvasState extends ConsumerState<CodeTopologyCanvas>
    with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  PhysicsSimulation? _physicsSim;
  GraphLayout? _cachedStaticLayout;
  LayoutMode? _cachedMode;
  TopologyGraphDataModel? _cachedData;

  final TransformationController _transformController =
      TransformationController();
  String? _draggedNodeId;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    _initSimulation();
  }

  @override
  void didUpdateWidget(covariant CodeTopologyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graphData, widget.graphData)) {
      _initSimulation();
    }
  }

  void _initSimulation() {
    _physicsSim = PhysicsSimulation(
      nodes: widget.graphData.nodes,
      edges: widget.graphData.edges,
    );
    _cachedStaticLayout = null;
    _cachedData = widget.graphData;
    _startTickerIfNeeded();
  }

  void _startTickerIfNeeded() {
    final mode = ref.read(selectedLayoutModeProvider);
    if (mode == LayoutMode.physics && !_ticker.isTicking) {
      _physicsSim?.wakeUp();
      _ticker.start();
    }
  }

  void _onTick(Duration elapsed) {
    final mode = ref.read(selectedLayoutModeProvider);
    if (mode != LayoutMode.physics || _physicsSim == null) {
      if (_ticker.isTicking) _ticker.stop();
      return;
    }

    final isMoving = _physicsSim!.step(0.016);
    setState(() {});

    if (!isMoving && _draggedNodeId == null && _ticker.isTicking) {
      _ticker.stop(); // Thermal cooling pause (0% CPU when idle)
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformController.dispose();
    super.dispose();
  }

  GraphLayout _currentLayout(LayoutMode mode) {
    if (mode == LayoutMode.physics) {
      return _physicsSim?.toLayout() ??
          GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    }

    if (_cachedStaticLayout != null &&
        _cachedMode == mode &&
        identical(_cachedData, widget.graphData)) {
      return _cachedStaticLayout!;
    }

    final layout =
        GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    _cachedStaticLayout = layout;
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

  List<String>? _findShortestPath(String fromId, String toId) {
    if (fromId == toId) return [fromId];

    final adj = <String, List<String>>{};
    for (final e in widget.graphData.edges) {
      adj.putIfAbsent(e.from, () => []).add(e.to);
      adj.putIfAbsent(e.to, () => []).add(e.from);
    }

    final parent = <String, String>{};
    final visited = <String>{fromId};
    final queue = <String>[fromId];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      if (curr == toId) {
        final path = <String>[];
        String? step = toId;
        while (step != null) {
          path.insert(0, step);
          step = parent[step];
        }
        return path;
      }

      for (final next in adj[curr] ?? const <String>[]) {
        if (!visited.contains(next)) {
          visited.add(next);
          parent[next] = curr;
          queue.add(next);
        }
      }
    }
    return null; // Disconnected
  }

  bool _passesFilter(
    TopologyNodeModel n,
    Set<InsightFilter> activeFilters,
    bool matchAll,
    String query,
  ) {
    if (query.isNotEmpty &&
        !n.qualifiedName.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    if (activeFilters.isEmpty) return true;

    final matches = [
      if (activeFilters.contains(InsightFilter.godFunctions) && n.isGodFunction) true,
      if (activeFilters.contains(InsightFilter.hubs) && n.isHub) true,
      if (activeFilters.contains(InsightFilter.highRisk) && n.isHighRisk) true,
      if (activeFilters.contains(InsightFilter.deadCode) && n.isDeadCode) true,
      if (activeFilters.contains(InsightFilter.publicApis) && n.isPublicApi) true,
    ];

    if (matchAll) {
      return matches.length == activeFilters.length;
    }
    return matches.contains(true);
  }

  TopologyNodeModel? _hitTest(Offset localPoint, GraphLayout layout) {
    for (final n in widget.graphData.nodes.reversed) {
      final pos = layout.positions[n.id];
      if (pos == null) continue;
      if ((pos - localPoint).distance <= _nodeRadius(n) + 6) return n;
    }
    return null;
  }

  Offset _transformViewportToContent(Offset viewportPoint) {
    final matrix = _transformController.value;
    final inverted = Matrix4.inverted(matrix);
    return MatrixUtils.transformPoint(inverted, viewportPoint);
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedLayoutModeProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final query = ref.watch(searchQueryProvider);
    final selected = ref.watch(selectedNodeProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    _startTickerIfNeeded();
    final layout = _currentLayout(mode);

    // Calculate highlighted neighborhood or shortest path
    Set<String>? highlighted;
    List<String>? pathNodes;

    if (pathStart != null && pathEnd != null) {
      pathNodes = _findShortestPath(pathStart.id, pathEnd.id);
      if (pathNodes != null) highlighted = pathNodes.toSet();
    } else if (selected != null) {
      highlighted = _neighborhoodOf(selected.id);
    }

    final width = max(layout.contentSize.width, 1200.0);
    final height = max(layout.contentSize.height, 900.0);

    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF0E1116),
        child: InteractiveViewer(
          transformationController: _transformController,
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
                final contentPoint = _transformViewportToContent(details.localPosition);
                final tapped = _hitTest(contentPoint, layout);
                ref.read(selectedNodeProvider.notifier).state = tapped;
              },
              onPanStart: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null) return;
                final contentPoint = _transformViewportToContent(details.localPosition);
                final hit = _hitTest(contentPoint, layout);
                if (hit != null) {
                  _draggedNodeId = hit.id;
                  _physicsSim!.pinnedIds.add(hit.id);
                  _startTickerIfNeeded();
                }
              },
              onPanUpdate: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null || _draggedNodeId == null) return;
                final contentPoint = _transformViewportToContent(details.localPosition);
                final p = _physicsSim!.particles[_draggedNodeId];
                if (p != null) {
                  p.position = contentPoint;
                  _physicsSim!.wakeUp();
                  _startTickerIfNeeded();
                }
              },
              onPanEnd: (_) {
                if (_draggedNodeId != null) {
                  _physicsSim?.pinnedIds.remove(_draggedNodeId);
                  _draggedNodeId = null;
                }
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _TopologyPainter(
                  graphData: widget.graphData,
                  layout: layout,
                  activeFilters: activeFilters,
                  matchAll: matchAll,
                  query: query,
                  selectedId: selected?.id,
                  highlighted: highlighted,
                  pathNodes: pathNodes,
                  passesFilter: _passesFilter,
                ),
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
  final Set<InsightFilter> activeFilters;
  final bool matchAll;
  final String query;
  final String? selectedId;
  final Set<String>? highlighted;
  final List<String>? pathNodes;
  final bool Function(TopologyNodeModel, Set<InsightFilter>, bool, String) passesFilter;

  _TopologyPainter({
    required this.graphData,
    required this.layout,
    required this.activeFilters,
    required this.matchAll,
    required this.query,
    required this.selectedId,
    required this.highlighted,
    required this.pathNodes,
    required this.passesFilter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final visibleIds = {
      for (final n in graphData.nodes)
        if (passesFilter(n, activeFilters, matchAll, query)) n.id,
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
    final pathEdgeSet = <String>{};
    if (pathNodes != null && pathNodes!.length >= 2) {
      for (int i = 0; i < pathNodes!.length - 1; i++) {
        pathEdgeSet.add('${pathNodes![i]}->${pathNodes![i + 1]}');
        pathEdgeSet.add('${pathNodes![i + 1]}->${pathNodes![i]}');
      }
    }

    for (final e in graphData.edges) {
      if (!visibleIds.contains(e.from) || !visibleIds.contains(e.to)) {
        continue;
      }
      final from = layout.positions[e.from];
      final to = layout.positions[e.to];
      if (from == null || to == null) continue;

      final isPathEdge = pathEdgeSet.contains('${e.from}->${e.to}') ||
          pathEdgeSet.contains('${e.to}->${e.from}');
      final isHighlighted = highlighted != null &&
          highlighted!.contains(e.from) &&
          highlighted!.contains(e.to);
      final dimmed = highlighted != null && !isHighlighted;

      final baseColor = isPathEdge
          ? const Color(0xFF00E676) // Glowing green path
          : (e.relation == 'Imports' ? const Color(0xFF64B5F6) : const Color(0xFFFFAB40));

      final opacity = dimmed ? 0.08 : (isPathEdge ? 1.0 : (isHighlighted ? 0.95 : 0.55));
      final strokeWidth = isPathEdge ? 3.2 : (isHighlighted ? 2.4 : 1.2);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = baseColor.withValues(alpha: opacity);

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
      if (isDimmed) fill = fill.withValues(alpha: 0.16);

      if (n.isHub && !isDimmed) {
        final halo = Paint()
          ..color = fill.withValues(alpha: 0.25)
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
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) => true;
}
