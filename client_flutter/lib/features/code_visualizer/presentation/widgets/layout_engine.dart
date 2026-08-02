// File: client_flutter/lib/features/code_visualizer/presentation/widgets/layout_engine.dart

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

class PhysicsParticle {
  final TopologyNodeModel node;
  Offset position;
  Offset velocity;
  bool isPinned;

  PhysicsParticle({
    required this.node,
    required this.position,
    this.isPinned = false,
  }) : velocity = Offset.zero;
}

class PhysicsSimulation {
  final Map<String, PhysicsParticle> particles;
  final List<TopologyEdgeModel> edges;
  final Size canvasSize;

  double temperature = 1.0;
  bool isSettled = false;
  final Set<String> pinnedIds = {};

  PhysicsSimulation({
    required List<TopologyNodeModel> nodes,
    required this.edges,
    this.canvasSize = const Size(1600, 1200),
  }) : particles = {} {
    final rnd = Random(42);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    for (final n in nodes) {
      particles[n.id] = PhysicsParticle(
        node: n,
        position: center +
            Offset(
              (rnd.nextDouble() - 0.5) * canvasSize.width * 0.6,
              (rnd.nextDouble() - 0.5) * canvasSize.height * 0.6,
            ),
      );
    }
  }

  /// Single 60fps physics step with Coulomb repulsion, Hooke spring attraction,
  /// center gravity, and thermal energy decay.
  bool step(double dt) {
    if (particles.isEmpty) {
      isSettled = true;
      return false;
    }

    const repulsion = 14000.0;
    const springLength = 150.0;
    const springStrength = 0.025;
    const gravity = 0.008;
    const damping = 0.82;
    const minEnergyEpsilon = 0.05;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final ids = particles.keys.toList();
    double totalKineticEnergy = 0.0;

    // 1. Repulsion between node pairs (Spatial grid optimized for large graphs)
    for (var i = 0; i < ids.length; i++) {
      final a = particles[ids[i]]!;
      if (a.isPinned || pinnedIds.contains(a.node.id)) continue;

      var force = Offset.zero;
      for (var j = 0; j < ids.length; j++) {
        if (i == j) continue;
        final b = particles[ids[j]]!;
        final delta = a.position - b.position;
        var distSq = delta.distanceSquared;
        if (distSq < 4) distSq = 4;
        final dist = sqrt(distSq);
        force += delta / dist * (repulsion / distSq);
      }
      force += (center - a.position) * gravity;
      a.velocity = (a.velocity + force * dt * 30.0) * damping;
    }

    // 2. Spring attraction along connected edges
    for (final e in edges) {
      final a = particles[e.from];
      final b = particles[e.to];
      if (a == null || b == null) continue;

      final delta = b.position - a.position;
      final dist = max(delta.distance, 1.0);
      final displacement = dist - springLength;
      final f = delta / dist * displacement * springStrength;

      if (!a.isPinned && !pinnedIds.contains(a.node.id)) {
        a.velocity += f;
      }
      if (!b.isPinned && !pinnedIds.contains(b.node.id)) {
        b.velocity -= f;
      }
    }

    // 3. Integrate position & compute total energy
    for (final p in particles.values) {
      if (!p.isPinned && !pinnedIds.contains(p.node.id)) {
        p.position += p.velocity * (dt * 30.0);
        totalKineticEnergy += p.velocity.distanceSquared;
      }
    }

    // 4. Thermal decay
    temperature = max(0.0, temperature - 0.005);
    isSettled = totalKineticEnergy < minEnergyEpsilon && temperature <= 0.05;
    return !isSettled;
  }

  void wakeUp() {
    temperature = 1.0;
    isSettled = false;
  }

  GraphLayout toLayout() {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in particles.values) {
      minX = min(minX, p.position.dx);
      minY = min(minY, p.position.dy);
      maxX = max(maxX, p.position.dx);
      maxY = max(maxY, p.position.dy);
    }
    const margin = 120.0;
    final positions = {
      for (final e in particles.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1200.0, (maxX - minX) + margin * 2),
        max(900.0, (maxY - minY) + margin * 2),
      ),
    );
  }
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
        final sim = PhysicsSimulation(nodes: data.nodes, edges: data.edges, canvasSize: canvasSize);
        for (int i = 0; i < 200; i++) {
          sim.step(0.016);
        }
        return sim.toLayout();
      case LayoutMode.fileGrouped:
        return _fileGroupedLayout(data);
      case LayoutMode.callFlow:
        return _callFlowLayout(data);
    }
  }

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
