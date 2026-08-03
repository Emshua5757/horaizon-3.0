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

  double repulsion;
  double springStrength;
  double moduleAttractorStrength;
  double centerGravity;
  double maxVelocity;
  double damping;

  double temperature = 1.0;
  bool isSettled = false;
  final Set<String> pinnedIds = {};
  final Map<String, Offset> moduleAttractors = {};

  PhysicsSimulation({
    required List<TopologyNodeModel> nodes,
    required this.edges,
    this.canvasSize = const Size(2400, 1800),
    this.repulsion = 12000.0,
    this.springStrength = 0.05,
    this.moduleAttractorStrength = 0.035,
    this.centerGravity = 0.003,
    this.maxVelocity = 32.0,
    this.damping = 0.80,
  }) : particles = {} {
    final rnd = Random(42);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Group modules into distinct galaxy constellation sectors around center
    final modules = <String, List<TopologyNodeModel>>{};
    for (final n in nodes) {
      modules.putIfAbsent(n.modulePath, () => []).add(n);
    }

    final modKeys = modules.keys.toList()..sort();
    for (int i = 0; i < modKeys.length; i++) {
      final modAngle = (i / max(1, modKeys.length)) * 2 * pi;
      final modRadius = 520.0 + (i % 3) * 180.0;
      moduleAttractors[modKeys[i]] = center + Offset(cos(modAngle) * modRadius, sin(modAngle) * modRadius);
    }

    // Seed particles around their module attractor centers
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final modCenter = moduleAttractors[n.modulePath] ?? center;
      final offsetAngle = rnd.nextDouble() * 2 * pi;
      final offsetRadius = rnd.nextDouble() * 90.0;

      particles[n.id] = PhysicsParticle(
        node: n,
        position: modCenter + Offset(cos(offsetAngle) * offsetRadius, sin(offsetAngle) * offsetRadius),
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

  /// Single 60fps physics step with configurable Max Velocity & Friction Damping
  bool step(double dt) {
    if (particles.isEmpty || isSettled) {
      return false;
    }

    const springLength = 65.0;
    const minEnergyEpsilon = 0.03;
    const cellSize = 220.0;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    double totalKineticEnergy = 0.0;

    // 1. Build Spatial Hash Grid Buckets for O(N) Repulsion
    final grid = <int, List<PhysicsParticle>>{};
    int cellKey(int cx, int cy) => (cx * 73856093) ^ (cy * 19349663);

    for (final p in particles.values) {
      final cx = (p.position.dx / cellSize).floor();
      final cy = (p.position.dy / cellSize).floor();
      grid.putIfAbsent(cellKey(cx, cy), () => []).add(p);
    }

    // 2. Compute Repulsion against adjacent 3x3 grid cells + Module Attractor Pull
    for (final a in particles.values) {
      if (a.isPinned || pinnedIds.contains(a.node.id)) continue;

      var force = Offset.zero;
      final acx = (a.position.dx / cellSize).floor();
      final acy = (a.position.dy / cellSize).floor();

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final neighbors = grid[cellKey(acx + dx, acy + dy)];
          if (neighbors == null) continue;

          for (final b in neighbors) {
            if (identical(a, b)) continue;
            final delta = a.position - b.position;
            var distSq = delta.distanceSquared;
            if (distSq < 16) distSq = 16;
            if (distSq > cellSize * cellSize) continue;
            final dist = sqrt(distSq);

            // Bounded force clamp prevents infinity explosions
            final repMag = min(repulsion / distSq, 600.0);
            force += delta / dist * repMag;
          }
        }
      }

      // Strong pull toward module galaxy constellation center
      final modCenter = moduleAttractors[a.node.modulePath] ?? center;
      force += (modCenter - a.position) * moduleAttractorStrength;
      force += (center - a.position) * centerGravity;

      a.velocity = (a.velocity + force * dt * 30.0) * damping;

      // Dynamic Velocity Clamping
      final speed = a.velocity.distance;
      if (speed > maxVelocity) {
        a.velocity = (a.velocity / speed) * maxVelocity;
      }
    }

    // 3. Pure O(1) Hooke spring attraction pulling connected call/import nodes into tight clusters
    for (final e in edges) {
      final a = particles[e.from];
      final b = particles[e.to];
      if (a == null || b == null || identical(a, b)) continue;

      final delta = b.position - a.position;
      final dist = max(delta.distance, 1.0);
      final displacement = dist - springLength;
      final mult = max(1.0, e.callCount * 1.0);
      final f = delta / dist * min(displacement * springStrength * mult, 250.0);

      if (!a.isPinned && !pinnedIds.contains(a.node.id)) {
        a.velocity += f;
        final speedA = a.velocity.distance;
        if (speedA > maxVelocity) {
          a.velocity = (a.velocity / speedA) * maxVelocity;
        }
      }
      if (!b.isPinned && !pinnedIds.contains(b.node.id)) {
        b.velocity -= f;
        final speedB = b.velocity.distance;
        if (speedB > maxVelocity) {
          b.velocity = (b.velocity / speedB) * maxVelocity;
        }
      }
    }

    // 4. Integrate position & compute total energy
    for (final p in particles.values) {
      if (!p.isPinned && !pinnedIds.contains(p.node.id)) {
        p.position += p.velocity * (dt * 30.0);
        totalKineticEnergy += p.velocity.distanceSquared;
      }
    }

    // 5. Thermal decay
    temperature = max(0.0, temperature - 0.008);
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
    const margin = 160.0;
    final positions = {
      for (final e in particles.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1800.0, (maxX - minX) + margin * 2),
        max(1400.0, (maxY - minY) + margin * 2),
      ),
    );
  }
}

class GraphLayoutEngine {
  const GraphLayoutEngine._();

  static GraphLayout compute({
    required TopologyGraphDataModel data,
    required LayoutMode mode,
    Size canvasSize = const Size(2400, 1800),
  }) {
    if (data.nodes.isEmpty) {
      return GraphLayout(positions: const {}, contentSize: canvasSize);
    }
    switch (mode) {
      case LayoutMode.physics:
        final sim = PhysicsSimulation(nodes: data.nodes, edges: data.edges, canvasSize: canvasSize);
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
