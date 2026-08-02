import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topology_models.dart';

final selectedNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');

final codeTopologyProvider = FutureProvider<TopologyGraphDataModel>((ref) async {
  // 1. Try reading exported JSON from local disk
  try {
    const diskPath = 'c:/horaizon-3.0/code_viz_graph_output.json';
    final file = File(diskPath);
    if (await file.exists()) {
      final text = await file.readAsString();
      final jsonMap = jsonDecode(text) as Map<String, dynamic>;
      return TopologyGraphDataModel.fromJson(jsonMap);
    }
  } catch (_) {}

  // 2. Try loading from Flutter assets fallback
  try {
    final assetStr = await rootBundle.loadString('assets/code_viz_graph_output.json');
    final jsonMap = jsonDecode(assetStr) as Map<String, dynamic>;
    return TopologyGraphDataModel.fromJson(jsonMap);
  } catch (_) {}

  // 3. Built-in Fallback Graph Data
  return const TopologyGraphDataModel(
    nodes: [
      TopologyNodeModel(
        id: "shua_code_visualizer/src/main.rs:main",
        kind: "function",
        qualifiedName: "main",
        file: "shua_code_visualizer/src/main.rs",
        line: 40,
        params: [],
        returnType: "Result<(), Box<dyn Error>>",
        complexity: 12,
        sideEffects: ["IO", "Network"],
        intent: "Daemon entry point & event loop assembly",
        loc: 110,
        isPublic: true,
        isTest: false,
        fanIn: 0,
        fanOut: 5,
        riskScore: 60.0,
        isOrphan: false,
        exceedsComplexityThreshold: true,
        exceedsLocThreshold: true,
      ),
      TopologyNodeModel(
        id: "shua_code_visualizer/src/graph/store.rs:CodeGraph::new",
        kind: "function",
        qualifiedName: "CodeGraph::new",
        file: "shua_code_visualizer/src/graph/store.rs",
        line: 38,
        params: [],
        returnType: "Self",
        complexity: 1,
        sideEffects: [],
        intent: "Initializes an empty CodeGraph",
        loc: 6,
        isPublic: true,
        isTest: false,
        fanIn: 4,
        fanOut: 0,
        riskScore: 4.0,
        isOrphan: false,
      ),
      TopologyNodeModel(
        id: "shua_code_visualizer/src/mcp/handler.rs:McpHandler::handle_tool_call",
        kind: "function",
        qualifiedName: "McpHandler::handle_tool_call",
        file: "shua_code_visualizer/src/mcp/handler.rs",
        line: 23,
        params: [
          ParamModel(name: "tool_name", type: "&str"),
          ParamModel(name: "args", type: "&Value")
        ],
        returnType: "Result<Value, String>",
        complexity: 8,
        sideEffects: [],
        intent: "Dispatches incoming MCP tool call by name",
        loc: 18,
        isPublic: true,
        isTest: false,
        fanIn: 2,
        fanOut: 7,
        riskScore: 16.0,
        isOrphan: false,
        exceedsComplexityThreshold: false,
      ),
      TopologyNodeModel(
        id: "shua_code_visualizer/src/watch/watcher.rs:CodeWatcher::poll_and_apply_patch",
        kind: "function",
        qualifiedName: "CodeWatcher::poll_and_apply_patch",
        file: "shua_code_visualizer/src/watch/watcher.rs",
        line: 65,
        params: [ParamModel(name: "graph", type: "&mut CodeGraph")],
        returnType: "Option<TopologyDeltaEvent>",
        complexity: 6,
        sideEffects: ["IO"],
        intent: "Non-blocking poll for path debounced file events",
        loc: 32,
        isPublic: true,
        isTest: false,
        fanIn: 1,
        fanOut: 2,
        riskScore: 6.0,
        isOrphan: false,
      ),
    ],
    edges: [
      TopologyEdgeModel(
        from: "shua_code_visualizer/src/main.rs:main",
        to: "shua_code_visualizer/src/graph/store.rs:CodeGraph::new",
        relation: "Calls",
      ),
      TopologyEdgeModel(
        from: "shua_code_visualizer/src/main.rs:main",
        to: "shua_code_visualizer/src/watch/watcher.rs:CodeWatcher::poll_and_apply_patch",
        relation: "Calls",
      ),
      TopologyEdgeModel(
        from: "shua_code_visualizer/src/mcp/handler.rs:McpHandler::handle_tool_call",
        to: "shua_code_visualizer/src/graph/store.rs:CodeGraph::new",
        relation: "Calls",
      ),
    ],
  );
});
