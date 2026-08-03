// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_insights.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';
import '../../providers/topology_data_source.dart';
import 'layout_engine.dart';

class CodeTopologyCanvas extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;

  const CodeTopologyCanvas({
    super.key,
    required this.graphData,
  });

  @override
  ConsumerState<CodeTopologyCanvas> createState() => _CodeTopologyCanvasState();
}

class _CodeTopologyCanvasState extends ConsumerState<CodeTopologyCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  PhysicsSimulation? _physicsSim;
  String? _draggedNodeId;
  Offset? _dragGrabOffset;

  final TransformationController _transformController = TransformationController();

  GraphLayout? _cachedStaticLayout;
  LayoutMode? _cachedMode;
  TopologyGraphDataModel? _cachedData;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((dt) {
      if (_physicsSim != null && !_physicsSim!.isSettled) {
        final changed = _physicsSim!.step(0.016);
        if (changed) {
          setState(() {});
        } else {
          _ticker.stop();
        }
      } else {
        _ticker.stop();
      }
    });

    _initSimulation();
  }

  @override
  void didUpdateWidget(CodeTopologyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graphData, widget.graphData)) {
      _initSimulation();
      _cachedStaticLayout = null;
    }
  }

  void _initSimulation() {
    final repulsion = ref.read(physicsRepulsionProvider);
    final spring = ref.read(physicsSpringProvider);
    final modulePull = ref.read(physicsModuleAttractorProvider);
    final gravity = ref.read(physicsGravityProvider);
    final maxVel = ref.read(physicsMaxVelocityProvider);
    final damping = ref.read(physicsDampingProvider);

    _physicsSim = PhysicsSimulation(
      nodes: widget.graphData.nodes,
      edges: widget.graphData.edges,
      repulsion: repulsion,
      springStrength: spring,
      moduleAttractorStrength: modulePull,
      centerGravity: gravity,
      maxVelocity: maxVel,
      damping: damping,
    );
    _startTickerIfNeeded();
  }

  void _startTickerIfNeeded() {
    if (_physicsSim != null && !_physicsSim!.isSettled && !_ticker.isActive) {
      _ticker.start();
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
    final node = widget.graphData.nodes.firstWhere((n) => n.id == nodeId, orElse: () => widget.graphData.nodes.first);
    final qname = node.qualifiedName;

    for (final e in widget.graphData.edges) {
      if (e.from == nodeId || e.from == qname) {
        ids.add(e.to);
      }
      if (e.to == nodeId || e.to == qname) {
        ids.add(e.from);
      }
    }
    return ids;
  }

  List<String>? _findShortestPath(String fromId, String toId) {
    final index = ref.read(graphIndexProvider);
    if (index != null) {
      return index.tracePathLocal(fromId, toId);
    }
    return [fromId];
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
      if ((pos - localPoint).distance <= _nodeRadius(n) + 12.0) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedLayoutModeProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final query = ref.watch(searchQueryProvider);
    final isolationDepth = ref.watch(isolationDepthProvider);
    final graphIndex = ref.watch(graphIndexProvider);
    final selected = ref.watch(selectedNodeProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final repulsion = ref.watch(physicsRepulsionProvider);
    final spring = ref.watch(physicsSpringProvider);
    final modulePull = ref.watch(physicsModuleAttractorProvider);
    final gravity = ref.watch(physicsGravityProvider);
    final maxVel = ref.watch(physicsMaxVelocityProvider);
    final damping = ref.watch(physicsDampingProvider);

    if (_physicsSim != null) {
      if (_physicsSim!.repulsion != repulsion ||
          _physicsSim!.springStrength != spring ||
          _physicsSim!.moduleAttractorStrength != modulePull ||
          _physicsSim!.centerGravity != gravity ||
          _physicsSim!.maxVelocity != maxVel ||
          _physicsSim!.damping != damping) {
        _physicsSim!.repulsion = repulsion;
        _physicsSim!.springStrength = spring;
        _physicsSim!.moduleAttractorStrength = modulePull;
        _physicsSim!.centerGravity = gravity;
        _physicsSim!.maxVelocity = maxVel;
        _physicsSim!.damping = damping;
        _physicsSim!.wakeUp();
        _startTickerIfNeeded();
      }
    }

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

    final width = max(layout.contentSize.width, 1400.0);
    final height = max(layout.contentSize.height, 1000.0);
    final isSimulating = mode == LayoutMode.physics && _physicsSim != null && !_physicsSim!.isSettled;

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
                final tapped = _hitTest(details.localPosition, layout);
                ref.read(selectedNodeProvider.notifier).state = tapped;
              },
              onPanStart: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null) return;
                final hit = _hitTest(details.localPosition, layout);
                if (hit != null) {
                  _draggedNodeId = hit.id;
                  final p = _physicsSim!.particles[hit.id];
                  if (p != null) {
                    _dragGrabOffset = details.localPosition - p.position;
                  }
                  _physicsSim!.pinnedIds.add(hit.id);
                  _startTickerIfNeeded();
                }
              },
              onPanUpdate: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null || _draggedNodeId == null) return;
                final p = _physicsSim!.particles[_draggedNodeId];
                if (p != null) {
                  p.position = details.localPosition - (_dragGrabOffset ?? Offset.zero);
                  _physicsSim!.wakeUp();
                  _startTickerIfNeeded();
                }
              },
              onPanEnd: (_) {
                if (_draggedNodeId != null) {
                  _physicsSim?.pinnedIds.remove(_draggedNodeId);
                  _draggedNodeId = null;
                  _dragGrabOffset = null;
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
                  isolationDepth: isolationDepth,
                  graphIndex: graphIndex,
                  selectedId: selected?.id,
                  highlighted: highlighted,
                  pathNodes: pathNodes,
                  passesFilter: _passesFilter,
                  isSimulating: isSimulating,
                  transformController: _transformController,
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
  final int isolationDepth;
  final GraphIndex? graphIndex;
  final String? selectedId;
  final Set<String>? highlighted;
  final List<String>? pathNodes;
  final bool Function(TopologyNodeModel, Set<InsightFilter>, bool, String) passesFilter;
  final bool isSimulating;
  final TransformationController transformController;

  static final Map<String, TextPainter> _labelCache = {};

  _TopologyPainter({
    required this.graphData,
    required this.layout,
    required this.activeFilters,
    required this.matchAll,
    required this.query,
    required this.isolationDepth,
    required this.graphIndex,
    required this.selectedId,
    required this.highlighted,
    required this.pathNodes,
    required this.passesFilter,
    required this.isSimulating,
    required this.transformController,
  });

  Set<String> _computeVisibleIds() {
    if (isolationDepth > 0 && graphIndex != null) {
      final isolatedIds = <String>{};

      if (query.isNotEmpty) {
        final searchMatches = graphData.nodes
            .where((n) => n.qualifiedName.toLowerCase().contains(query.toLowerCase()));
        for (final matchNode in searchMatches) {
          final nbrs = graphIndex!.blastRadiusLocal(matchNode.id, maxDepth: isolationDepth);
          isolatedIds.addAll(nbrs);
        }
      } else if (selectedId != null) {
        final nbrs = graphIndex!.blastRadiusLocal(selectedId!, maxDepth: isolationDepth);
        isolatedIds.addAll(nbrs);
      }

      if (isolatedIds.isNotEmpty) {
        return isolatedIds;
      }
    }

    return {
      for (final n in graphData.nodes)
        if (passesFilter(n, activeFilters, matchAll, query)) n.id,
    };
  }

  Rect _computeVisibleViewportRect(Size canvasSize) {
    final matrix = transformController.value;
    final inverted = Matrix4.inverted(matrix);
    // Transform viewport screen coordinates back to content canvas space
    final transformed = MatrixUtils.transformRect(inverted, Offset.zero & canvasSize);
    return transformed.inflate(180.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final visibleIds = _computeVisibleIds();
    final visibleViewportRect = _computeVisibleViewportRect(size);

    _paintFileGroups(canvas);
    _paintEdges(canvas, visibleIds, visibleViewportRect);
    _paintNodes(canvas, visibleIds, visibleViewportRect);
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
      final tp = _labelCache.putIfAbsent(
        'group_$label',
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xAAE0E0E0),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      tp.paint(canvas, entry.value.topLeft + const Offset(12, 8));
    }
  }

  void _paintEdges(Canvas canvas, Set<String> visibleIds, Rect viewportRect) {
    final pathEdgeSet = <String>{};
    if (pathNodes != null && pathNodes!.length >= 2) {
      for (int i = 0; i < pathNodes!.length - 1; i++) {
        pathEdgeSet.add('${pathNodes![i]}->${pathNodes![i + 1]}');
        pathEdgeSet.add('${pathNodes![i + 1]}->${pathNodes![i]}');
      }
    }

    for (final e in graphData.edges) {
      final fromPos = layout.positions[e.from];
      final toPos = layout.positions[e.to];
      if (fromPos == null || toPos == null) continue;

      // Real Viewport Inverse Edge Culling: Skip edges outside visible viewport
      if (!viewportRect.contains(fromPos) && !viewportRect.contains(toPos)) {
        continue;
      }

      final isPathEdge = pathEdgeSet.contains('${e.from}->${e.to}') ||
          pathEdgeSet.contains('${e.to}->${e.from}');
      final isHighlighted = highlighted != null &&
          (highlighted!.contains(e.from) || highlighted!.contains(e.to));
      final dimmed = highlighted != null && !isHighlighted;

      final relLower = e.relation.toLowerCase();
      final baseColor = isPathEdge
          ? const Color(0xFF00E676)
          : (relLower == 'imports' ? const Color(0xFF40C4FF) : const Color(0xFFFFB74D));

      final opacity = dimmed ? 0.08 : (isPathEdge ? 1.0 : (isHighlighted ? 0.95 : 0.45));
      final strokeWidth = isPathEdge ? 3.2 : (isHighlighted ? 2.4 : 1.4);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = baseColor.withValues(alpha: opacity);

      // Fast Direct Line Segments during active 60fps live physics simulation for 0 jank
      if (isSimulating) {
        canvas.drawLine(fromPos, toPos, paint);
      } else {
        final mid = Offset((fromPos.dx + toPos.dx) / 2, (fromPos.dy + toPos.dy) / 2);
        final control =
            mid + Offset((toPos.dy - fromPos.dy) * 0.15, (fromPos.dx - toPos.dx) * 0.15);
        final path = Path()
          ..moveTo(fromPos.dx, fromPos.dy)
          ..quadraticBezierTo(control.dx, control.dy, toPos.dx, toPos.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintNodes(Canvas canvas, Set<String> visibleIds, Rect viewportRect) {
    for (final n in graphData.nodes) {
      if (!visibleIds.contains(n.id)) continue;
      final pos = layout.positions[n.id];
      if (pos == null) continue;

      // Real Viewport Node Culling
      if (!viewportRect.contains(pos)) continue;

      final isSelected = n.id == selectedId;
      final isDimmed = highlighted != null && !highlighted!.contains(n.id);
      final radius = _nodeRadius(n);

      final baseColor = _nodeColor(n);
      final color = isDimmed ? baseColor.withValues(alpha: 0.15) : baseColor;

      // Selection Halo
      if (isSelected) {
        final haloPaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 10, haloPaint);

        final ringPaint = Paint()
          ..color = const Color(0xFF00E676)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(pos, radius + 5, ringPaint);
      }

      // Outer glow for high risk or god functions
      if (n.isGodFunction || n.isHighRisk) {
        final glowColor = n.isGodFunction ? const Color(0xFFFF5252) : const Color(0xFFFFAB00);
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 6, glowPaint);
      }

      // Main Node Fill
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, fillPaint);

      // Node Border Stroke
      final borderPaint = Paint()
        ..color = isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 : 1.0;
      canvas.drawCircle(pos, radius, borderPaint);

      // Node Title Label (Cached TextPainter)
      final label = n.qualifiedName.split('.').last;
      final cacheKey = '${n.id}_${isDimmed}_$isSelected';
      final tp = _labelCache.putIfAbsent(
        cacheKey,
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isDimmed
                  ? Colors.white.withValues(alpha: 0.2)
                  : (isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.9)),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      tp.paint(canvas, pos + Offset(-tp.width / 2, radius + 3));
    }
  }

  Color _nodeColor(TopologyNodeModel n) {
    switch (n.kind.toLowerCase()) {
      case 'class':
        return const Color(0xFF42A5F5); // Blue
      case 'enum':
        return const Color(0xFFAB47BC); // Purple
      case 'module':
        return const Color(0xFF26A69A); // Teal
      case 'trait':
        return const Color(0xFFFF7043); // Orange
      case 'function':
      default:
        if (n.isGodFunction) return const Color(0xFFEF5350); // Red
        if (n.isHub) return const Color(0xFFFFA726); // Amber
        if (n.isDeadCode) return const Color(0xFF78909C); // Grey
        return const Color(0xFF29B6F6); // Cyan
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.query != query ||
        oldDelegate.activeFilters != activeFilters ||
        oldDelegate.isolationDepth != isolationDepth ||
        oldDelegate.isSimulating != isSimulating ||
        oldDelegate.pathNodes != pathNodes ||
        oldDelegate.matchAll != matchAll ||
        oldDelegate.graphIndex != graphIndex;
  }
}
