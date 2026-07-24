import 'dart:convert';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

class SduiListView extends StatelessWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiListView({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Read layout behaviors
    final scrollDirection = _int(50) == 1 ? Axis.horizontal : Axis.vertical;
    final itemExtent = _num(52);
    final separatorHeight = _num(53);
    final forceShrinkWrap = node.behavior<bool>(55) ?? false;
    final padding = SduiStyleResolver.resolveEdgeInsets(node.behavior(30)) ?? EdgeInsets.zero;

    // 2. Read data and item template
    final templateNode = (node.children?.isNotEmpty == true) ? node.children!.first : null;
    final rawData = node.contentVal<String>(6) ?? "[]";
    
    List<dynamic> rows = [];
    try {
      rows = jsonDecode(rawData) as List<dynamic>;
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_list_view', 'Failed to parse data JSON array: $e', tags: HbpLogTag.SDUI);
    }

    if (templateNode == null || rows.isEmpty) {
      return const SizedBox.shrink();
    }

    // 3. LayoutBuilder Guard (Prevents Infinite Height Crash)
    return LayoutBuilder(
      builder: (context, constraints) {
        final isInfiniteHeight = constraints.maxHeight == double.infinity;
        final safeShrinkWrap = forceShrinkWrap || (scrollDirection == Axis.vertical && isInfiniteHeight);

        // 4. Render O(1) lazy list
        if (separatorHeight == null && itemExtent != null) {
          return ListView.builder(
            key: PageStorageKey('list_${node.id}'),
            scrollDirection: scrollDirection,
            shrinkWrap: safeShrinkWrap,
            padding: padding,
            itemCount: rows.length,
            itemExtent: itemExtent,
            itemBuilder: (context, index) {
              final rowData = Map<String, dynamic>.from(rows[index] as Map);
              final resolvedNode = templateNode.interpolate(rowData);
              return SduiRenderer(
                key: ValueKey(resolvedNode.id),
                node: resolvedNode,
                dispatcher: dispatcher,
              );
            },
          );
        }

        return ListView.separated(
          key: PageStorageKey('list_${node.id}'),
          scrollDirection: scrollDirection,
          shrinkWrap: safeShrinkWrap,
          padding: padding,
          itemCount: rows.length,
          itemBuilder: (context, index) {
            final rowData = Map<String, dynamic>.from(rows[index] as Map);
            final resolvedNode = templateNode.interpolate(rowData);
            return SduiRenderer(
              key: ValueKey(resolvedNode.id),
              node: resolvedNode,
              dispatcher: dispatcher,
            );
          },
          separatorBuilder: (context, index) {
            if (separatorHeight != null) {
              return SizedBox(height: separatorHeight);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  // Safe numeric extractors
  int? _int(int key) {
    final raw = node.behavior(key);
    if (raw is num) return raw.toInt();
    return null;
  }

  double? _num(int key) {
    final raw = node.behavior(key);
    if (raw is num) return raw.toDouble();
    return null;
  }
}
