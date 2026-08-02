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
    this.canvasSize = const Size(1800, 1400),
  }) : particles = {} {
    final rnd = Random(42);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Initial seeding: Group by module or dagLevel radially for zero initial overlap jank
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final angle = (i / max(1, nodes.length)) * 2 * pi;
      final radius = 180.0 + (n.dagLevel * 90.0) + rnd.nextDouble() * 100.0;

      particles[n.id] = PhysicsParticle(
        node: n,
        position: center + Offset(cos(angle) * radius, sin(angle) * radius),
      );
    }
  }

  void togglePin(String id) {
    if (pinnedIds.contains(id)) {
      pinnedIds.remove(id);
      if (particles.containsKey(id)) {
        particles[id]!.isPinned = false;
      }
    } else {
      pinnedIds.add(id);
      if (particles.containsKey(id)) {
        particles[id]!.isPinned = true;
      }
    }
  }

  /// Single 60fps physics step with Coulomb repulsion, Hooke spring attraction,
  /// center gravity, and thermal energy decay.
  bool step(double dt) {
    if (particles.isEmpty || isSettled) {
      return false;
    }

    const repulsion = 18000.0;
    const springLength = 140.0;
    const springStrength = 0.03;
    const gravity = 0.005;
    const damping = 0.85;
    const minEnergyEpsilon = 0.04;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final ids = particles.keys.toList();
    double totalKineticEnergy = 0.0;

    // 1. Repulsion between node pairs
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

    // 2. Spring attraction along connected edges (adjusted by callCount)
    for (final e in edges) {
      final a = particles[e.from];
      final b = particles[e.to];
      if (a == null || b == null) continue;

      final delta = b.position - a.position;
      final dist = max(delta.distance, 1.0);
      final displacement = dist - springLength;
      final mult = max(1.0, e.callCount * 0.8);
      final f = delta / dist * displacement * springStrength * mult;

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

    // 4. Thermal decay (0% CPU at idle when settled)
    temperature = max(0.0, temperature - 0.006);
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
    const margin = 140.0;
    final positions = {
      for (final e in particles.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1400.0, (maxX - minX) + margin * 2),
        max(1000.0, (maxY - minY) + margin * 2),
      ),
    );
  }
}

class GraphLayoutEngine {
  const GraphLayoutEngine._();

  static GraphLayout compute({
    required TopologyGraphDataModel data,
    required LayoutMode mode,
    Size canvasSize = const Size(1800, 1400),
  }) {
    if (data.nodes.isEmpty) {
      return GraphLayout(positions: const {}, contentSize: canvasSize);
    }
    switch (mode) {
      case LayoutMode.physics:
        final sim = PhysicsSimulation(nodes: data.nodes, edges: data.edges, canvasSize: canvasSize);
        for (int i = 0; i < 220; i++) {
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

    const cols = 2;
    const padding = 50.0;
    const nodeSpacingX = 140.0;
    const nodeSpacingY = 90.0;

    final positions = <String, Offset>{};
    final fileGroups = <String, Rect>{};

    var currentY = padding;
    var maxColumnX = 0.0;

    for (var i = 0; i < files.length; i += cols) {
      var maxHeightInRow = 0.0;
      var currentX = padding;

      for (var c = 0; c < cols && (i + c) < files.length; c++) {
        final file = files[i + c];
        final members = byFile[file]!;

        final colsInBox = sqrt(members.length).ceil().clamp(2, 5);
        final rowsInBox = (members.length / colsInBox).ceil().clamp(1, 999);
        final boxWidth = max(420.0, colsInBox * nodeSpacingX + 60.0);
        final boxHeight = max(240.0, rowsInBox * nodeSpacingY + 80.0);

        fileGroups[file] = Rect.fromLTWH(currentX, currentY, boxWidth, boxHeight);

        for (var k = 0; k < members.length; k++) {
          final r = k ~/ colsInBox;
          final colIdx = k % colsInBox;
          positions[members[k].id] = Offset(
            currentX + 60 + colIdx * nodeSpacingX,
            currentY + 60 + r * nodeSpacingY,
          );
        }

        currentX += boxWidth + padding;
        maxHeightInRow = max(maxHeightInRow, boxHeight);
      }

      maxColumnX = max(maxColumnX, currentX);
      currentY += maxHeightInRow + padding;
    }

    return GraphLayout(
      positions: positions,
      fileGroups: fileGroups,
      contentSize: Size(
        max(1600.0, maxColumnX),
        max(1200.0, currentY + 100),
      ),
    );
  }

  static GraphLayout _callFlowLayout(TopologyGraphDataModel data) {
    final byLevel = <int, List<TopologyNodeModel>>{};
    for (final n in data.nodes) {
      byLevel.putIfAbsent(n.dagLevel, () => []).add(n);
    }

    const levelHeight = 190.0;
    const nodeGap = 140.0;
    const paddingX = 100.0;
    const paddingY = 80.0;

    final positions = <String, Offset>{};
    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    var maxWidth = 0.0;

    for (var lvl = 0; lvl <= maxLevel; lvl++) {
      final nodesAtLevel = byLevel[lvl] ?? const <TopologyNodeModel>[];
      nodesAtLevel.sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));

      for (var i = 0; i < nodesAtLevel.length; i++) {
        positions[nodesAtLevel[i].id] = Offset(
          paddingX + i * nodeGap,
          paddingY + lvl * levelHeight,
        );
      }
      maxWidth = max(maxWidth, nodesAtLevel.length * nodeGap);
    }

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1600.0, maxWidth + paddingX * 2),
        max(1200.0, (maxLevel + 1) * levelHeight + paddingY * 2),
      ),
    );
  }
}
