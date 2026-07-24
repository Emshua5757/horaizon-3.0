import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';

class SduiToggle extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiToggle({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool currentValue = ref.watch(
      sduiStateVaultProvider.select((state) => state[node.id] as bool?),
    ) ?? node.contentVal<bool>(0) ?? false;
    final String? label = node.contentVal<String>(1);

    // 2. Behaviors
    final int interactiveMode = node.behavior<int>(95) ?? 1; // 0=readonly, 1=editable
    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(96));

    final theme = Theme.of(context);
    
    void handleToggle() {
      if (interactiveMode != 1) return;
      final newValue = !currentValue;
      dispatcher.onStateChange(node.id, newValue);
      
      final actionPayload = node.behavior<Map<int, dynamic>>(70);
      if (actionPayload != null) {
        dispatcher.onAction(actionPayload);
      }
    }

    Widget toggle = Switch(
      value: currentValue,
      activeThumbColor: accentColor ?? theme.colorScheme.primary,
      onChanged: interactiveMode == 1 ? (bool val) => handleToggle() : null,
    );

    if (label != null) {
      return InkWell(
        onTap: interactiveMode == 1 ? handleToggle : null,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(child: Text(label, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: 8),
              toggle,
            ],
          ),
        ),
      );
    }

    return toggle;
  }
}
