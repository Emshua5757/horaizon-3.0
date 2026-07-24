import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';

class SduiChip extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiChip({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int chipMode = node.behavior<int>(113) ?? 0; // 0=read_only, 1=selectable, 2=deletable, 3=suggestion
    
    final bool isSelected = ref.watch(
      sduiStateVaultProvider.select((state) => state[node.id] as bool?),
    ) ?? node.contentVal<bool>(0) ?? false;
    final String label = node.contentVal<String>(1) ?? '';
    final String? iconName = node.contentVal<String>(3);

    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(96));
    final Color? textColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(97));

    final theme = Theme.of(context);
    final textStyle = textColor != null ? TextStyle(color: textColor) : null;
    final avatar = iconName != null ? Icon(SduiIconRegistry.resolve(iconName), size: 18) : null;

    void handleTap() {
      final actionPayload = node.behavior<Map<int, dynamic>>(70);
      if (actionPayload != null) {
        dispatcher.onAction(actionPayload, context);
      }
    }

    void handleSelect(bool selected) {
      dispatcher.onStateChange(node.id, selected);
      handleTap();
    }

    switch (chipMode) {
      case 1: // selectable
        return FilterChip(
          label: Text(label, style: textStyle),
          labelStyle: textStyle,
          selected: isSelected,
          onSelected: handleSelect,
          avatar: avatar,
          selectedColor: accentColor?.withAlpha(51) ?? theme.colorScheme.primaryContainer,
          checkmarkColor: accentColor ?? theme.colorScheme.primary,
        );
      case 2: // deletable
        return InputChip(
          label: Text(label, style: textStyle),
          labelStyle: textStyle,
          avatar: avatar,
          onDeleted: handleTap,
          deleteIconColor: accentColor ?? theme.colorScheme.error,
        );
      case 3: // suggestion
        return ActionChip(
          label: Text(label, style: textStyle),
          labelStyle: textStyle,
          avatar: avatar,
          onPressed: handleTap,
          backgroundColor: accentColor?.withAlpha(25) ?? theme.colorScheme.surfaceContainerHighest,
        );
      case 0: // read_only
      default:
        return Chip(
          label: Text(label, style: textStyle),
          labelStyle: textStyle,
          avatar: avatar,
          backgroundColor: accentColor?.withAlpha(25) ?? theme.colorScheme.surfaceContainerHighest,
        );
    }
  }
}
