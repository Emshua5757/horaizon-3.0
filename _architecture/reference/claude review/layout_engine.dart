// File: client_flutter/lib/features/code_visualizer/presentation/widgets/layout_engine.dart
//
// Pure positioning logic — no painting, no widgets. Given a graph and a
// mode, produce a screen-space position for every node (plus, for the
// file-grouped mode, bounding boxes for the file "containers").

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/topology_models.dart';

enum LayoutMode { physics, fileGrouped, callFlow }

class GraphLayout {
  final Map<String, Offset> positions;
  final Map<String, Rect> fileGroups;
  final Size contentSize;

  const GraphLayout({
    required this.positions,
    this.fileGroups = const {},
    required this.contentSize,
  });
}

class _PhysicsNode {
  final TopologyNodeModel node;
  Offset position;
  Offset velocity;
  _PhysicsNode(this.node, this.position) : velocity = Offset.zero;
}

class GraphLayoutEngine {
  const GraphLayoutEngine._();

  static GraphLayout compute({
    required TopologyGraphDataModel data,
    required LayoutMode mode,
    Size canvasSize = const Size(1600, 1200),
  }) {
    if (data.nodes.isEmpty) {
      return GraphLayout(positions: const {}, contentSize: canvasSize);
    }
    switch (mode) {
      case LayoutMode.physics:
        return _physicsLayout(data, canvasSize);
      case LayoutMode.fileGrouped:
        return _fileGroupedLayout(data);
      case LayoutMode.callFlow:
        return _callFlowLayout(data);
    }
  }

  // ---------------------------------------------------------------------
  // Mode 2: ⚡ Organic Force-Directed Physics Cluster
  // Coulomb repulsion (all pairs) + Hooke spring attraction (edges only)
  // + gentle center gravity so the whole graph doesn't drift off-canvas.
  // ---------------------------------------------------------------------
  static GraphLayout _physicsLayout(TopologyGraphDataModel data, Size size) {
    final rnd = Random(42); // deterministic layout between refreshes
    final center = Offset(size.width / 2, size.height / 2);
    final nodes = <String, _PhysicsNode>{
      for (final n in data.nodes)
        n.id: _PhysicsNode(
          n,
          center +
              Offset(
                (rnd.nextDouble() - 0.5) * size.width * 0.6,
                (rnd.nextDouble() - 0.5) * size.height * 0.6,
              ),
        ),
    };

    const repulsion = 14000.0;
    const springLength = 150.0;
    const springStrength = 0.02;
    const gravity = 0.008;
    const damping = 0.82;
    const iterations = 240;

    final ids = nodes.keys.toList();

    for (var iter = 0; iter < iterations; iter++) {
      // Coulomb repulsion between every pair of nodes.
      for (var i = 0; i < ids.length; i++) {
        final a = nodes[ids[i]]!;
        var force = Offset.zero;
        for (var j = 0; j < ids.length; j++) {
          if (i == j) continue;
          final b = nodes[ids[j]]!;
          final delta = a.position - b.position;
          var distSq = delta.distanceSquared;
          if (distSq < 4) distSq = 4;
          final dist = sqrt(distSq);
          force += delta / dist * (repulsion / distSq);
        }
        force += (center - a.position) * gravity;
        a.velocity = (a.velocity + force) * damping;
      }

      // Hooke spring attraction along Calls/Imports edges.
      for (final e in data.edges) {
        final a = nodes[e.from];
        final b = nodes[e.to];
        if (a == null || b == null) continue;
        final delta = b.position - a.position;
        final dist = max(delta.distance, 1.0);
        final displacement = dist - springLength;
        final f = delta / dist * displacement * springStrength;
        a.velocity += f;
        b.velocity -= f;
      }

      for (final n in nodes.values) {
        n.position += n.velocity;
      }
    }

    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final n in nodes.values) {
      minX = min(minX, n.position.dx);
      minY = min(minY, n.position.dy);
      maxX = max(maxX, n.position.dx);
      maxY = max(maxY, n.position.dy);
    }
    const margin = 120.0;
    final positions = {
      for (final e in nodes.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        (maxX - minX) + margin * 2,
        (maxY - minY) + margin * 2,
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Mode 1: 📁 File Hierarchy Grouped
  // Each file becomes a bounded container; symbols are packed in a small
  // grid inside it. Containers are tiled left-to-right, top-to-bottom.
  // ---------------------------------------------------------------------
  static GraphLayout _fileGroupedLayout(TopologyGraphDataModel data) {
    final byFile = <String, List<TopologyNodeModel>>{};
    for (final n in data.nodes) {
      byFile.putIfAbsent(n.file, () => []).add(n);
    }
    final files = byFile.keys.toList()..sort();

    const cols = 3;
    const cellW = 420.0;
    const cellH = 300.0;
    const padding = 40.0;
    const perRow = 3;
    const nodeSpacingX = 110.0;
    const nodeSpacingY = 80.0;

    final positions = <String, Offset>{};
    final fileGroups = <String, Rect>{};

    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      final col = i % cols;
      final row = i ~/ cols;
      final originX = padding + col * (cellW + padding);
      final originY = padding + row * (cellH + padding);

      final members = byFile[file]!;
      final rowsNeeded = (members.length / perRow).ceil().clamp(1, 999);
      final boxHeight = max(cellH, 70.0 + rowsNeeded * nodeSpacingY);
      fileGroups[file] = Rect.fromLTWH(originX, originY, cellW, boxHeight);

      for (var k = 0; k < members.length; k++) {
        final r = k ~/ perRow;
        final c = k % perRow;
        positions[members[k].id] = Offset(
          originX + 60 + c * nodeSpacingX,
          originY + 60 + r * nodeSpacingY,
        );
      }
    }

    final totalRows = (files.length / cols).ceil().clamp(1, 999);
    final contentSize = Size(
      cols * (cellW + padding) + padding,
      totalRows * (cellH + padding) + padding + 200,
    );

    return GraphLayout(
      positions: positions,
      fileGroups: fileGroups,
      contentSize: contentSize,
    );
  }

  // ---------------------------------------------------------------------
  // Mode 3: 🌲 Architecture Call-Flow Tree
  // BFS layering from entrypoints (nodes nobody calls) down through
  // callees. Ties within a level are ordered alphabetically for stability.
  // ---------------------------------------------------------------------
  static GraphLayout _callFlowLayout(TopologyGraphDataModel data) {
    final callers = <String, List<String>>{};
    final callees = <String, List<String>>{};
    for (final e in data.edges) {
      callees.putIfAbsent(e.from, () => []).add(e.to);
      callers.putIfAbsent(e.to, () => []).add(e.from);
    }

    final roots = data.nodes.where((n) => (callers[n.id]?.isEmpty ?? true));
    final level = <String, int>{};
    final queue = <String>[];

    for (final r in roots) {
      level[r.id] = 0;
      queue.add(r.id);
    }
    var head = 0;
    while (head < queue.length) {
      final cur = queue[head++];
      final d = level[cur]!;
      for (final next in callees[cur] ?? const <String>[]) {
        if (!level.containsKey(next) || level[next]! < d + 1) {
          level[next] = d + 1;
          queue.add(next);
        }
      }
    }
    // Anything unreached (isolated nodes, pure cycles) still needs a slot.
    for (final n in data.nodes) {
      level.putIfAbsent(n.id, () => 0);
    }

    final byLevel = <int, List<String>>{};
    for (final entry in level.entries) {
      byLevel.putIfAbsent(entry.value, () => []).add(entry.key);
    }

    const levelHeight = 170.0;
    const nodeGap = 120.0;
    const paddingX = 90.0;
    const paddingY = 70.0;

    final positions = <String, Offset>{};
    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    var maxWidth = 0.0;

    for (var lvl = 0; lvl <= maxLevel; lvl++) {
      final idsAtLevel = byLevel[lvl] ?? const <String>[];
      idsAtLevel.sort();
      for (var i = 0; i < idsAtLevel.length; i++) {
        positions[idsAtLevel[i]] = Offset(
          paddingX + i * nodeGap,
          paddingY + lvl * levelHeight,
        );
      }
      maxWidth = max(maxWidth, idsAtLevel.length * nodeGap);
    }

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        maxWidth + paddingX * 2,
        (maxLevel + 1) * levelHeight + paddingY * 2,
      ),
    );
  }
}
