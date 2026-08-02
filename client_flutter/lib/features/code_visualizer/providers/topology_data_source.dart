// File: client_flutter/lib/features/code_visualizer/providers/topology_data_source.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/topology_models.dart';

/// Pre-indexed graph lookup structure built once per TopologyGraphDataModel snapshot
class GraphIndex {
  final TopologyGraphDataModel graphData;
  final Map<String, TopologyNodeModel> nodeMap;
  final Map<String, List<String>> forwardAdjacency;
  final Map<String, List<String>> reverseAdjacency;
  final Map<String, List<String>> undirectedAdjacency;

  GraphIndex._({
    required this.graphData,
    required this.nodeMap,
    required this.forwardAdjacency,
    required this.reverseAdjacency,
    required this.undirectedAdjacency,
  });

  factory GraphIndex.build(TopologyGraphDataModel data) {
    final nodeMap = {for (final n in data.nodes) n.id: n};
    final fwd = <String, List<String>>{};
    final rev = <String, List<String>>{};
    final undir = <String, List<String>>{};

    for (final e in data.edges) {
      fwd.putIfAbsent(e.from, () => []).add(e.to);
      rev.putIfAbsent(e.to, () => []).add(e.from);

      undir.putIfAbsent(e.from, () => []).add(e.to);
      undir.putIfAbsent(e.to, () => []).add(e.from);
    }

    return GraphIndex._(
      graphData: data,
      nodeMap: nodeMap,
      forwardAdjacency: fwd,
      reverseAdjacency: rev,
      undirectedAdjacency: undir,
    );
  }

  /// Fast client-side BFS shortest path tracer fallback
  List<String>? tracePathLocal(String fromId, String toId, {bool directed = false}) {
    if (fromId == toId) return [fromId];
    final adj = directed ? forwardAdjacency : undirectedAdjacency;

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

  /// Fast client-side BFS blast radius N-hop caller calculation fallback
  Set<String> blastRadiusLocal(String nodeId, {int maxDepth = 3}) {
    final affected = <String>{nodeId};
    var queue = <String>[nodeId];

    for (int depth = 0; depth < maxDepth; depth++) {
      final nextQueue = <String>[];
      for (final curr in queue) {
        for (final caller in reverseAdjacency[curr] ?? const <String>[]) {
          if (affected.add(caller)) {
            nextQueue.add(caller);
          }
        }
      }
      queue = nextQueue;
      if (queue.isEmpty) break;
    }
    return affected;
  }
}

/// Abstract data source interface decoupling Standalone vs Managed Subprocess modes
abstract class TopologyDataSource {
  Future<TopologyGraphDataModel> loadSnapshot();
  Stream<TopologyDeltaEvent>? get deltaStream;
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false});
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3});
}

/// Standalone Mode Data Source (reads CLI stdout / local disk export)
class StandaloneDataSource implements TopologyDataSource {
  final String workspacePath;
  StandaloneDataSource({required this.workspacePath});

  @override
  Stream<TopologyDeltaEvent>? get deltaStream => null;

  @override
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false}) async => null;

  @override
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3}) async => {nodeId};

  @override
  Future<TopologyGraphDataModel> loadSnapshot() async {
    const binaryPath = 'c:/horaizon-3.0/shua_code_visualizer/target/debug/shua_code_visualizer.exe';

    // 1. Try running shua_code_visualizer CLI and reading output
    try {
      final tempOut = '${Directory.systemTemp.path}/code_viz_dynamic_graph.json';
      if (await File(binaryPath).exists()) {
        final res = await Process.run(binaryPath, [
          '--workspace-root',
          workspacePath,
          '--export-graph',
          tempOut,
        ]);

        if (res.exitCode == 0) {
          final file = File(tempOut);
          if (await file.exists()) {
            final text = await file.readAsString();
            final jsonMap = jsonDecode(text) as Map<String, dynamic>;
            return TopologyGraphDataModel.fromJson(jsonMap);
          }
        } else {
          debugPrint('StandaloneDataSource process error: ${res.stderr}');
        }
      }
    } catch (e) {
      debugPrint('StandaloneDataSource subprocess exception: $e');
    }

    // 2. Fallback: Read pre-exported file from root disk
    try {
      const diskPath = 'c:/horaizon-3.0/code_viz_graph_output.json';
      final file = File(diskPath);
      if (await file.exists()) {
        final text = await file.readAsString();
        final jsonMap = jsonDecode(text) as Map<String, dynamic>;
        return TopologyGraphDataModel.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('StandaloneDataSource disk fallback exception: $e');
    }

    // 3. Asset fallback
    try {
      final assetStr = await rootBundle.loadString('assets/code_viz_graph_output.json');
      final jsonMap = jsonDecode(assetStr) as Map<String, dynamic>;
      return TopologyGraphDataModel.fromJson(jsonMap);
    } catch (_) {}

    return const TopologyGraphDataModel(nodes: [], edges: []);
  }
}

/// Managed Subprocess Mode Data Source (Connects over HBP v2 WebSocket IPC)
class ManagedDataSource implements TopologyDataSource {
  final String wsUrl;
  WebSocket? _socket;
  final _deltaController = StreamController<TopologyDeltaEvent>.broadcast();

  ManagedDataSource({this.wsUrl = 'ws://127.0.0.1:7700/hbp'});

  @override
  Stream<TopologyDeltaEvent> get deltaStream => _deltaController.stream;

  @override
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false}) async {
    return null;
  }

  @override
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3}) async {
    return {nodeId};
  }

  @override
  Future<TopologyGraphDataModel> loadSnapshot() async {
    try {
      _socket = await WebSocket.connect(wsUrl);
      _socket!.listen((data) {
        if (data is String) {
          final jsonMap = jsonDecode(data) as Map<String, dynamic>;
          if (jsonMap.containsKey('affected_node_ids')) {
            _deltaController.add(TopologyDeltaEvent.fromJson(jsonMap));
          }
        }
      });
    } catch (e) {
      debugPrint('ManagedDataSource WebSocket connect error: $e');
    }
    return StandaloneDataSource(workspacePath: 'c:/horaizon-3.0/shua_code_visualizer/src').loadSnapshot();
  }

  void dispose() {
    _socket?.close();
    _deltaController.close();
  }
}
