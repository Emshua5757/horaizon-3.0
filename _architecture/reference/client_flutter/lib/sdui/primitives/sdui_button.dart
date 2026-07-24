import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';

class SduiButton extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiButton({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int variant = node.behavior<int>(112) ?? 0; // 0=elevated, 1=outlined, 2=text, 3=icon_only, 4=filled_tonal
    
    final String label = node.contentVal<String>(1) ?? '';
    final String? iconName = node.contentVal<String>(3);
    final bool isLoading = node.contentVal<bool>(4) ?? false;

    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(96));
    final Color? textColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(97));

    void handleTap() {
      if (isLoading) return;
      final actionPayload = node.behavior<Map<int, dynamic>>(70);
      if (actionPayload != null) {
        dispatcher.onAction(actionPayload, context);
      }
    }

    void handleLongPress() {
      if (isLoading) return;
      final actionPayload = node.behavior<Map<int, dynamic>>(71);
      if (actionPayload != null) {
        dispatcher.onAction(actionPayload, context);
      }
    }

    Widget content;
    if (isLoading) {
      content = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2.0),
      );
    } else if (iconName != null && variant != 3) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SduiIconRegistry.resolve(iconName), size: 18),
          const SizedBox(width: 8),
          Text(label),
        ],
      );
    } else if (variant == 3 && iconName != null) {
      content = Icon(SduiIconRegistry.resolve(iconName));
    } else {
      content = Text(label);
    }

    final Color? foregroundColor = textColor ?? (accentColor != null ? Theme.of(context).colorScheme.onPrimary : null);

    switch (variant) {
      case 1:
        return OutlinedButton(
          onPressed: handleTap,
          onLongPress: handleLongPress,
          style: OutlinedButton.styleFrom(
            foregroundColor: textColor ?? accentColor,
            side: accentColor != null ? BorderSide(color: accentColor) : null,
          ),
          child: content,
        );
      case 2:
        return TextButton(
          onPressed: handleTap,
          onLongPress: handleLongPress,
          style: TextButton.styleFrom(
            foregroundColor: textColor ?? accentColor,
          ),
          child: content,
        );
      case 3:
        return IconButton(
          onPressed: handleTap,
          icon: content,
          color: textColor ?? accentColor,
        );
      case 4:
        return FilledButton.tonal(
          onPressed: handleTap,
          onLongPress: handleLongPress,
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: foregroundColor,
          ),
          child: content,
        );
      case 0:
      default:
        return ElevatedButton(
          onPressed: handleTap,
          onLongPress: handleLongPress,
          style: ElevatedButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor: foregroundColor,
          ),
          child: content,
        );
    }
  }
}
