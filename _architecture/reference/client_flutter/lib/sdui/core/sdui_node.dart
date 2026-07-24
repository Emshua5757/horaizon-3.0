import 'package:flutter/foundation.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

/// The immutable, pure-data abstract syntax tree node for SDUI-4.
/// Note that no Flutter Widgets are imported or returned here.
@immutable
class SduiNode {
  /// Stable UUID from the backend for O(1) widget tree diffing.
  final String id;

  /// Integer primitive mapping (1-17) for zero-allocation builder lookups.
  final int typeId;

  /// Integer-keyed visual and layout modifiers (keys 10-129).
  final Map<int, dynamic> behaviors;

  /// Integer-keyed content and state (keys 0-9).
  final Map<int, dynamic> content;

  /// Optional nested children for containers, rows, or lists.
  final List<SduiNode>? children;

  const SduiNode({
    required this.id,
    required this.typeId,
    this.behaviors = const {},
    this.content = const {},
    this.children,
  });

  /// Convenience accessor for behavior values with O(1) lookup.
  T? behavior<T>(int key) {
    final val = behaviors[key];
    if (val == null) return null;
    if (val is T) return val;
    if (val is String && val.startsWith('{{') && val.endsWith('}}')) return null;

    final typeStr = T.toString();
    final isInt = typeStr.startsWith('int');
    final isDouble = typeStr.startsWith('double');
    final isBool = typeStr.startsWith('bool');

    // Numerical Coercion
    if (val is num) {
      if (isDouble) return val.toDouble() as T;
      if (isInt) return val.toInt() as T;
    }

    // String Coercion
    if (val is String) {
      if (isInt) {
        final parsed = int.tryParse(val);
        if (parsed != null) return parsed as T;
        return null;
      }
      if (isDouble) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed as T;
        return null;
      }
      if (isBool) {
        if (val.toLowerCase() == 'true') return true as T;
        if (val.toLowerCase() == 'false') return false as T;
        return null;
      }
    }

    if (val is Map && val is! Map<int, dynamic>) {
      try {
        final converted = val.map((k, v) => MapEntry(int.parse(k.toString()), v));
        if (converted is T) {
          return converted as T;
        }
      } catch (_) {
        // Fallback to direct cast if key parsing fails
      }
    }

    try {
      return val as T;
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_node', 'Failed type cast for behavior key $key (val: $val, expected type: $T): $e', tags: HbpLogTag.SDUI);
      return null;
    }
  }

  /// Convenience accessor for content values with O(1) lookup.
  T? contentVal<T>(int key) {
    final val = content[key];
    if (val == null) return null;
    if (val is T) return val;
    if (val is String && val.startsWith('{{') && val.endsWith('}}')) return null;

    final typeStr = T.toString();
    final isInt = typeStr.startsWith('int');
    final isDouble = typeStr.startsWith('double');
    final isBool = typeStr.startsWith('bool');

    // Numerical Coercion
    if (val is num) {
      if (isDouble) return val.toDouble() as T;
      if (isInt) return val.toInt() as T;
    }

    // String Coercion
    if (val is String) {
      if (isInt) {
        final parsed = int.tryParse(val);
        if (parsed != null) return parsed as T;
        return null;
      }
      if (isDouble) {
        final parsed = double.tryParse(val);
        if (parsed != null) return parsed as T;
        return null;
      }
      if (isBool) {
        if (val.toLowerCase() == 'true') return true as T;
        if (val.toLowerCase() == 'false') return false as T;
        return null;
      }
    }

    try {
      return val as T;
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_node', 'Failed type cast for content key $key (val: $val, expected type: $T): $e', tags: HbpLogTag.SDUI);
      return null;
    }
  }

  /// Recursively interpolates any string bindings or dynamic placeholders in the node's properties
  /// using the provided key-value context map.
  SduiNode interpolate(Map<String, dynamic> context) {
    dynamic interpolateValue(dynamic val) {
      if (val == null) return null;
      if (val is String) {
        // Exact match: "{{key}}" -> return typed value from context directly
        final exactMatch = RegExp(r'^\{\{([^}]+)\}\}$').firstMatch(val);
        if (exactMatch != null) {
          final key = exactMatch.group(1)!;
          return context[key] ?? val;
        }

        // Inline replacement: "Hello {{name}}" -> String
        return val.replaceAllMapped(RegExp(r'\{\{([^}]+)\}\}'), (match) {
          final key = match.group(1)!;
          return context[key]?.toString() ?? '';
        });
      }
      if (val is List) {
        return val.map((v) => interpolateValue(v)).toList();
      }
      if (val is Map) {
        final Map<dynamic, dynamic> result = {};
        for (final entry in val.entries) {
          result[interpolateValue(entry.key)] = interpolateValue(entry.value);
        }
        return result;
      }
      return val;
    }

    final newBehaviors = behaviors.map((k, v) => MapEntry(k, interpolateValue(v)));
    final newContent = content.map((k, v) => MapEntry(k, interpolateValue(v)));
    final newChildren = children?.map((child) => child.interpolate(context)).toList();
    final newId = interpolateValue(id) as String;

    return SduiNode(
      id: newId,
      typeId: typeId,
      behaviors: Map<int, dynamic>.from(newBehaviors),
      content: Map<int, dynamic>.from(newContent),
      children: newChildren,
    );
  }

  /// Recursively parses the binary JSON/MsgPack payload into an AST tree.
  factory SduiNode.fromJson(Map<String, dynamic> json) {
    // MsgPack maps keys as integers if configured, or strings if JSON. We cast safely.
    dynamic parseIntMap(dynamic value) {
      if (value == null) return null;
      if (value is Map<int, dynamic>) return value;
      if (value is Map) {
        // Only convert to Map<int, dynamic> if every key is parseable as an integer
        final canParseAllKeys = value.keys.every((k) => int.tryParse(k.toString()) != null);
        if (canParseAllKeys) {
          final Map<int, dynamic> result = {};
          for (final entry in value.entries) {
            result[int.parse(entry.key.toString())] = parseIntMap(entry.value);
          }
          return result;
        } else {
          // Keep as string-keyed map, but recursively parse nested items
          final Map<String, dynamic> result = {};
          for (final entry in value.entries) {
            result[entry.key.toString()] = parseIntMap(entry.value);
          }
          return result;
        }
      }
      if (value is List) {
        return value.map((v) => parseIntMap(v)).toList();
      }
      return value;
    }

    return SduiNode(
      id: json['id'] as String,
      typeId: json['typeId'] as int,
      behaviors: parseIntMap(json['behaviors']) as Map<int, dynamic>? ?? const <int, dynamic>{},
      content: parseIntMap(json['content']) as Map<int, dynamic>? ?? const <int, dynamic>{},
      children: json['children'] != null
          ? (json['children'] as List)
                .map((c) => SduiNode.fromJson(c as Map<String, dynamic>))
                .toList()
          : null,
    );
  }
}
