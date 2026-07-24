import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiRadio extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiRadio({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiRadio> createState() => _SduiRadioState();
}

class _SduiRadioState extends ConsumerState<SduiRadio> {
  bool _isEditing = false;
  late TextEditingController _labelController;
  late TextEditingController _groupController;

  @override
  void initState() {
    super.initState();
    final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
    String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Option';
    String group = widget.node.behavior<String>(HbpBehavior.GROUP_ID) ?? 'poll_block';

    if (vaultValue is String && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        label = parsed['label']?.toString() ?? label;
        group = parsed['group']?.toString() ?? group;
      } catch (e) {
        // Ignore fallback
      }
    }
    _labelController = TextEditingController(text: label);
    _groupController = TextEditingController(text: group);
  }

  @override
  void didUpdateWidget(covariant SduiRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.id != oldWidget.node.id) {
      final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
      String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Option';
      String group = widget.node.behavior<String>(HbpBehavior.GROUP_ID) ?? 'poll_block';

      if (vaultValue is String && vaultValue.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(vaultValue);
          label = parsed['label']?.toString() ?? label;
          group = parsed['group']?.toString() ?? group;
        } catch (e) {
          // Ignore
        }
      }
      _labelController.text = label;
      _groupController.text = group;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;

    // 1. Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final String baseGroupId = node.behavior<String>(HbpBehavior.GROUP_ID) ?? 'poll_block';
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

    String labelText = nodeLabel ?? 'Option';
    bool isChecked = nodeChecked ?? false;
    String groupId = baseGroupId;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        labelText = parsed['label']?.toString() ?? labelText;
        isChecked = parsed['checked'] == true;
        groupId = parsed['group']?.toString() ?? groupId;
      } catch (e) {
        // Fallback for legacy state
        if (vaultValue == 'true' || vaultValue == 'false') {
          isChecked = vaultValue == 'true';
        } else {
          labelText = vaultValue;
        }
      }
    }

    void updateState(String label, bool checked, String group) {
      final payload = jsonEncode({
        'label': label,
        'checked': checked,
        'group': group,
      });
      ref.read(sduiStateVaultProvider.notifier).set(node.id, payload);
      widget.dispatcher.onStateChange(node.id, payload);
    }

    void handleSelect() {
      if (interactiveMode != 1 || isChecked) return;
      updateState(labelText, true, groupId);

      final actionPayload = node.behavior<Map<int, dynamic>>(HbpBehavior.ACTION_PAYLOAD);
      if (actionPayload != null) {
        widget.dispatcher.onAction(actionPayload);
      }
    }

    Widget buildRadioRow() {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<bool>(
              value: true,
              // ignore: deprecated_member_use
              groupValue: isChecked ? true : false,
              activeColor: activeColor,
              // ignore: deprecated_member_use
              onChanged: interactiveMode == 1 ? (bool? val) => handleSelect() : null,
              toggleable: false,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: InkWell(
                onTap: interactiveMode == 1 && !isChecked ? handleSelect : null,
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
                tooltip: 'Edit Radio Option',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _labelController,
                      decoration: const InputDecoration(
                        labelText: 'Radio Option Label',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) {
                        updateState(val, isChecked, groupId);
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
              const SizedBox(height: 8),
              TextField(
                controller: _groupController,
                decoration: const InputDecoration(
                  labelText: 'Mutex Group Name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  updateState(labelText, isChecked, val);
                },
              ),
            ],
          ),
        ),
      );
    }

    return buildRadioRow();
  }
}
