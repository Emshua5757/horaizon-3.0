import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/registry/sdui_type_registry.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// Provides flex-parent context to child containers so they can safely
/// wrap themselves in [Expanded] without crashing Flutter's layout system.
///
/// This solves the critical constraint: [Expanded] and [Flexible] are only
/// valid as direct children of [Row], [Column], or [Flex]. By propagating
/// this context via an [InheritedWidget], child containers can query whether
/// their immediate parent is a flex container before wrapping.
class SduiFlexContext extends InheritedWidget {
  /// Whether the immediate parent widget is a Row or Column (flex parent).
  final bool isFlexParent;

  const SduiFlexContext({
    super.key,
    required this.isFlexParent,
    required super.child,
  });

  static SduiFlexContext? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<SduiFlexContext>();
  }

  @override
  bool updateShouldNotify(SduiFlexContext oldWidget) {
    return oldWidget.isFlexParent != isFlexParent;
  }
}

/// The universal recursive renderer. Every composite primitive uses this
/// to build its children rather than calling [SduiTypeRegistry] directly.
/// This prevents circular import errors (composites importing the registry
/// that registers them).
class SduiRenderer extends StatelessWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  SduiRenderer({
    Key? key,
    required this.node,
    required this.dispatcher,
  }) : super(key: key ?? ValueKey(node.id));

  @override
  Widget build(BuildContext context) {
    Widget child = SduiTypeRegistry.buildNode(node, dispatcher, context);

    // Apply margin padding centrally to all widgets EXCEPT Container (typeId 6)
    // Container handles its margins internally within its decoration/sizing box.
    if (node.typeId != 6) {
      final rawMargin = node.behaviors[HbpBehavior.MARGIN];
      if (rawMargin != null) {
        final marginInsets = SduiStyleResolver.resolveEdgeInsets(rawMargin);
        if (marginInsets != null && marginInsets != EdgeInsets.zero) {
          child = Padding(padding: marginInsets, child: child);
        }
      }
    }

    // Dynamic Flex/Expanded wrapper for all SDUI primitive and composite nodes
    final raw14 = node.behaviors[HbpBehavior.FLEX];
    final int? flex = raw14 is num ? raw14.toInt() : null;
    if (flex != null && flex > 0) {
      final parentCtx = SduiFlexContext.of(context);
      if (parentCtx != null && parentCtx.isFlexParent) {
        child = Expanded(flex: flex, child: child);
      }
    }

    // Behaviors key 5 encodes visibility (true = visible, false = hidden).
    // Populated from the blueprint top-level "5" field or patched server-side
    // via {"behaviors": {"5": false/true}}. Returns SizedBox.shrink() when
    // hidden so the node occupies zero space and can be shown again later.
    final visibleRaw = node.behaviors[5];
    if (visibleRaw != null) {
      final bool visible = visibleRaw is bool ? visibleRaw : visibleRaw != 0;
      if (!visible) return const SizedBox.shrink();
    }

    return child;
  }
}

