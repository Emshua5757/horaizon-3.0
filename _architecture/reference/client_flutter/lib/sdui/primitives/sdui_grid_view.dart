import 'dart:convert';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

class SduiGridView extends StatelessWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiGridView({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Read layout behaviors
    final scrollDirection = _int(50) == 1 ? Axis.horizontal : Axis.vertical;
    final crossAxisCount = _int(51) ?? 2;
    final forceShrinkWrap = node.behavior<bool>(55) ?? false;
    final padding = SduiStyleResolver.resolveEdgeInsets(node.behavior(30)) ?? EdgeInsets.zero;
    
    // Grid specific dimensions
    final mainAxisSpacing = _num(114) ?? 0.0;
    final crossAxisSpacing = _num(115) ?? 0.0;
    final childAspectRatio = _num(116) ?? 1.0;

    // 2. Determine mode (template mode vs static children fallback)
    final children = node.children ?? [];
    final rawData = node.contentVal<String>(6);
    final bool useTemplateMode = rawData != null && rawData.isNotEmpty && children.isNotEmpty;
    
    List<dynamic> rows = [];
    if (useTemplateMode) {
      try {
        rows = jsonDecode(rawData) as List<dynamic>;
      } catch (e) {
        gLog.log(HbpLogLevel.ERROR, 'sdui_grid_view', 'Failed to parse data JSON array: $e', tags: HbpLogTag.SDUI);
      }
    }

    final int itemCount = useTemplateMode ? rows.length : children.length;

    if (itemCount == 0) {
      return const SizedBox.shrink();
    }

    // 3. LayoutBuilder Guard (Prevents Infinite Height Crash)
    return LayoutBuilder(
      builder: (context, constraints) {
        final isInfiniteHeight = constraints.maxHeight == double.infinity;
        final safeShrinkWrap = forceShrinkWrap || (scrollDirection == Axis.vertical && isInfiniteHeight);

        // 4. Render grid dynamically
        return GridView.builder(
          scrollDirection: scrollDirection,
          shrinkWrap: safeShrinkWrap,
          physics: safeShrinkWrap ? const NeverScrollableScrollPhysics() : null,
          padding: padding,
          itemCount: itemCount,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: mainAxisSpacing,
            crossAxisSpacing: crossAxisSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            if (useTemplateMode) {
              final rowData = Map<String, dynamic>.from(rows[index] as Map);
              final resolvedNode = children.first.interpolate(rowData);
              return SduiRenderer(
                key: ValueKey(resolvedNode.id),
                node: resolvedNode,
                dispatcher: dispatcher,
              );
            } else {
              final childNode = children[index];
              return SduiRenderer(
                key: ValueKey(childNode.id),
                node: childNode,
                dispatcher: dispatcher,
              );
            }
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
