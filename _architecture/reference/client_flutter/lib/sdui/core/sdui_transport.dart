import 'dart:convert';
import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';

class SduiTransport {
  /// Decode a MessagePack byte array into a list of root SduiNodes
  static List<SduiNode> decode(Uint8List bytes) {
    final dynamic decoded = deserialize(bytes);
    return _parseList(decoded);
  }

  /// Fallback JSON decoder for testing
  static List<SduiNode> decodeJson(String jsonString) {
    final dynamic decoded = jsonDecode(jsonString);
    return _parseList(decoded);
  }

  /// Applies a partial delta map to an existing node tree (immutable)
  static SduiNode patch(SduiNode existing, Map<String, dynamic> delta) {
    // Basic patch implementation: merge behaviors and contents
    // In a real robust system, this would do deep diffing and handle children
    final Map<int, dynamic> newBehaviors = Map.from(existing.behaviors);
    if (delta.containsKey('3')) {
      final bDelta = delta['3'] as Map;
      bDelta.forEach((k, v) {
        newBehaviors[int.parse(k.toString())] = v;
      });
    }

    final Map<int, dynamic> newContents = Map.from(existing.content);
    if (delta.containsKey('4')) {
      final cDelta = delta['4'] as Map;
      cDelta.forEach((k, v) {
        newContents[int.parse(k.toString())] = v;
      });
    }

    return SduiNode(
      id: existing.id,
      typeId: existing.typeId,
      behaviors: newBehaviors,
      content: newContents,
      children: existing.children,
    );
  }

  /// Apply a decoded MsgPack delta event to a flat node tree.
  /// Returns a new list — fully immutable, no in-place mutation.
  ///
  /// Delta ops:
  ///   insert: { op:'insert', node:{...}, after_id: String? }
  ///   remove: { op:'remove', node_id: String }
  ///   patch:  { op:'patch',  node_id: String, behaviors?:{...}, content?:{...} }
  ///   batch:  { op:'batch',  ops: [ ...patch/insert/remove ops ] }
  ///           Applies all ops atomically — single Flutter setState, avoids
  ///           re-entrant layout crashes when the server sends rapid deltas.
  static List<SduiNode> applyDelta(List<SduiNode> tree, dynamic rawDelta) {
    if (rawDelta is! Map) return tree;
    final op = rawDelta['op']?.toString() ?? '';

    switch (op) {
      case 'batch':
        // Apply all nested ops against the same tree snapshot sequentially
        // so the caller only needs one setState for the entire batch.
        final ops = rawDelta['ops'];
        if (ops is! List) return tree;
        var result = tree;
        for (final subOp in ops) {
          result = applyDelta(result, subOp);
        }
        return result;

      case 'remove':
        final nodeId = rawDelta['node_id']?.toString();
        if (nodeId == null) return tree;
        return _removeNodeFromTree(tree, nodeId);

      case 'insert':
        final nodeMap = rawDelta['node'];
        if (nodeMap is! Map) return tree;
        final newNode = _nodeFromMap(nodeMap);
        final afterId = rawDelta['after_id']?.toString();
        return _insertAfterInTree(tree, newNode, afterId);

      case 'patch':
        final nodeId = rawDelta['node_id']?.toString();
        if (nodeId == null) return tree;
        return _patchNodeInTree(
          tree,
          nodeId,
          rawDelta['behaviors'] as Map?,
          rawDelta['content'] as Map?,
        );

      default:
        return tree;
    }
  }

  static List<SduiNode> _removeNodeFromTree(List<SduiNode> tree, String nodeId) {
    final result = <SduiNode>[];
    for (final node in tree) {
      if (node.id == nodeId) continue; // drop this node
      final newChildren = node.children != null
          ? _removeNodeFromTree(node.children!, nodeId)
          : null;
      result.add(SduiNode(
        id: node.id, typeId: node.typeId,
        behaviors: node.behaviors, content: node.content,
        children: newChildren,
      ));
    }
    return result;
  }

  static List<SduiNode> _insertAfterInTree(
    List<SduiNode> tree, SduiNode newNode, String? afterId,
  ) {
    // afterId == null → prepend at start of the top-level list
    if (afterId == null) return [newNode, ...tree];

    // Attempt recursive insert; returns (updatedList, wasInserted)
    final (updated, found) = _insertAfterRecursive(tree, newNode, afterId);
    return found ? updated : tree; // no-op if afterId not found anywhere
  }

  /// Recursively walks [tree] looking for a node whose id == [afterId].
  /// Returns the mutated list and a bool indicating success.
  static (List<SduiNode>, bool) _insertAfterRecursive(
    List<SduiNode> tree, SduiNode newNode, String afterId,
  ) {
    final result = <SduiNode>[];
    bool inserted = false;
    for (final node in tree) {
      if (inserted) {
        result.add(node);
        continue;
      }
      if (node.children != null) {
        final (newChildren, foundInChildren) =
            _insertAfterRecursive(node.children!, newNode, afterId);
        if (foundInChildren) {
          result.add(SduiNode(
            id: node.id, typeId: node.typeId,
            behaviors: node.behaviors, content: node.content,
            children: newChildren,
          ));
          inserted = true;
          continue;
        }
      }
      result.add(node);
      if (node.id == afterId) {
        result.add(newNode);
        inserted = true;
      }
    }
    return (result, inserted);
  }

  static List<SduiNode> _patchNodeInTree(
    List<SduiNode> tree, String nodeId, Map? bDelta, Map? cDelta,
  ) {
    return tree.map((node) {
      if (node.id == nodeId) {
        final newBehaviors = Map<int, dynamic>.from(node.behaviors);
        bDelta?.forEach((k, v) => newBehaviors[int.parse(k.toString())] = v);
        final newContent = Map<int, dynamic>.from(node.content);
        cDelta?.forEach((k, v) => newContent[int.parse(k.toString())] = v);
        return SduiNode(
          id: node.id, typeId: node.typeId,
          behaviors: newBehaviors, content: newContent,
          children: node.children,
        );
      }
      if (node.children != null) {
        return SduiNode(
          id: node.id, typeId: node.typeId,
          behaviors: node.behaviors, content: node.content,
          children: _patchNodeInTree(node.children!, nodeId, bDelta, cDelta),
        );
      }
      return node;
    }).toList();
  }

  static List<SduiNode> _parseList(dynamic decodedList) {
    if (decodedList is! List) return [];
    
    final List<SduiNode> nodes = [];
    for (var item in decodedList) {
      if (item is Map) {
        nodes.add(_nodeFromMap(item));
      }
    }
    return nodes;
  }

  static int _idCounter = 0;

  static SduiNode _nodeFromMap(Map map) {
    final typeIdStr = map['0']?.toString() ?? map[0]?.toString() ?? map['typeId']?.toString();
    final typeId = typeIdStr != null ? int.tryParse(typeIdStr) ?? 0 : 0;
    
    final Map<int, dynamic> behaviors = {};
    final bMap = map['3'] ?? map[3] ?? map['behaviors'];
    if (bMap is Map) {
      bMap.forEach((k, v) {
        behaviors[int.parse(k.toString())] = v;
      });
    }

    // Top-level "5" key encodes the node's initial visibility (true = visible, false = hidden).
    // Inject into behaviors[5] so the renderer can apply Offstage without an extra field.
    final visibleRaw = map['5'] ?? map[5];
    if (visibleRaw != null) {
      bool? visible;
      if (visibleRaw is bool) {
        visible = visibleRaw;
      } else if (visibleRaw is String) {
        visible = visibleRaw.toLowerCase() == 'true';
      }
      if (visible != null) {
        behaviors[5] = visible;
      }
    }

    final Map<int, dynamic> content = {};
    final cMap = map['4'] ?? map[4] ?? map['content'];
    if (cMap is Map) {
      cMap.forEach((k, v) {
        content[int.parse(k.toString())] = v;
      });
    }

    final List<SduiNode> children = [];
    final childList = map['2'] ?? map[2] ?? map['children'];
    if (childList is List) {
      for (var childMap in childList) {
        if (childMap is Map) {
          children.add(_nodeFromMap(childMap));
        }
      }
    }

    final idVal = map['id'] ?? map['1'] ?? map[1];
    final id = idVal?.toString() ?? 'temp_node_${++_idCounter}';

    return SduiNode(
      id: id,
      typeId: typeId,
      behaviors: behaviors,
      content: content,
      children: children,
    );
  }
}
