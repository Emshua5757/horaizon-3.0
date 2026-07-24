import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiCheckbox extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiCheckbox({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiCheckbox> createState() => _SduiCheckboxState();
}

class _SduiCheckboxState extends ConsumerState<SduiCheckbox> {
  bool _isEditing = false;
  late TextEditingController _labelController;

  @override
  void initState() {
    super.initState();
    final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
    String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Checkbox';

    if (vaultValue is String && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        label = parsed['label']?.toString() ?? label;
      } catch (e) {
        // Ignore fallback
      }
    }
    _labelController = TextEditingController(text: label);
  }

  @override
  void didUpdateWidget(covariant SduiCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.id != oldWidget.node.id) {
      final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
      String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Checkbox';

      if (vaultValue is String && vaultValue.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(vaultValue);
          label = parsed['label']?.toString() ?? label;
        } catch (e) {
          // Ignore
        }
      }
      _labelController.text = label;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    // 1. Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = accentColor ?? theme.colorScheme.primary;

    // 2. Content & State
    final String? nodeLabel = node.contentVal<String>(HbpContent.LABEL);
    final bool? nodeChecked = node.contentVal<bool>(HbpContent.VALUE);

    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((state) => state[node.id] as String?),
    );

    String labelText = nodeLabel ?? 'Checkbox';
    bool isChecked = nodeChecked ?? false;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        labelText = parsed['label']?.toString() ?? labelText;
        isChecked = parsed['checked'] == true;
      } catch (e) {
        // Fallback for raw boolean values
        if (vaultValue == 'true' || vaultValue == 'false') {
          isChecked = vaultValue == 'true';
        } else {
          labelText = vaultValue;
        }
      }
    }

    void updateState(String label, bool checked) {
      final payload = jsonEncode({
        'label': label,
        'checked': checked,
      });
      ref.read(sduiStateVaultProvider.notifier).set(node.id, payload);
      widget.dispatcher.onStateChange(node.id, payload);
    }

    void handleToggle() {
      if (interactiveMode != 1) return;
      updateState(labelText, !isChecked);

      final actionPayload = node.behavior<Map<int, dynamic>>(HbpBehavior.ACTION_PAYLOAD);
      if (actionPayload != null) {
        widget.dispatcher.onAction(actionPayload);
      }
    }

    Widget buildCheckboxRow() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: isChecked,
              activeColor: activeColor,
              onChanged: interactiveMode == 1 ? (bool? val) => handleToggle() : null,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: InkWell(
                onTap: interactiveMode == 1 ? handleToggle : null,
                borderRadius: BorderRadius.circular(4.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                  child: Text(labelText, style: theme.textTheme.bodyMedium),
                ),
              ),
            ),
            if (interactiveMode == 1 && !_isEditing) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 14),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit Label',
              ),
            ],
          ],
        ),
      );
    }

    if (interactiveMode == 1 && _isEditing) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: BorderSide(color: colorScheme.outline.withAlpha(40), width: 1.0),
        ),
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Checkbox Label',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    updateState(val, isChecked);
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                onPressed: () => setState(() => _isEditing = false),
                tooltip: 'Done',
              ),
            ],
          ),
        ),
      );
    }

    return buildCheckboxRow();
  }
}
