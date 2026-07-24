import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiDropdown extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiDropdown({super.key, required this.node, required this.dispatcher});

  @override
  ConsumerState<SduiDropdown> createState() => _SduiDropdownState();
}

class _SduiDropdownState extends ConsumerState<SduiDropdown> {
  bool _isEditing = false;
  late TextEditingController _labelController;
  late TextEditingController _optionsController;

  @override
  void initState() {
    super.initState();
    final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
    String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? '';
    List<String> options = _parseNodeOptions();

    if (vaultValue is String && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        label = parsed['label']?.toString() ?? label;
        if (parsed['options'] is List) {
          options = (parsed['options'] as List)
              .map((e) => e.toString())
              .toList();
        }
      } catch (e) {
        // Ignore fallback
      }
    }
    _labelController = TextEditingController(text: label);
    _optionsController = TextEditingController(text: options.join(', '));
  }

  @override
  void didUpdateWidget(covariant SduiDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.id != oldWidget.node.id) {
      final vaultValue = ref.read(sduiStateVaultProvider)[widget.node.id];
      String label = widget.node.contentVal<String>(HbpContent.LABEL) ?? '';
      List<String> options = _parseNodeOptions();

      if (vaultValue is String && vaultValue.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(vaultValue);
          label = parsed['label']?.toString() ?? label;
          if (parsed['options'] is List) {
            options = (parsed['options'] as List)
                .map((e) => e.toString())
                .toList();
          }
        } catch (e) {
          // Ignore
        }
      }
      _labelController.text = label;
      _optionsController.text = options.join(', ');
    }
  }

  List<String> _parseNodeOptions() {
    final String rawData =
        widget.node.contentVal<String>(HbpContent.DATA) ?? '[]';
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (e) {
      // Fallback
    }
    return ['Option A', 'Option B', 'Option C'];
  }

  @override
  void dispose() {
    _labelController.dispose();
    _optionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Behaviors
    final int interactiveMode =
        node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final bool isInteractive = interactiveMode == 1;
    final bool borderless = node.behavior<int>(99) == 1;

    final int? accentToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final Color? accentColor = SduiStyleResolver.resolveColor(
      context,
      accentToken,
    );

    // 2. Content & Vault
    final String baseLabel = node.contentVal<String>(HbpContent.LABEL) ?? '';
    final String? hint = node.contentVal<String>(HbpContent.PLACEHOLDER);
    final String? nodeValue = node.contentVal<String>(HbpContent.VALUE);

    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((s) => s[node.id] as String?),
    );

    String label = baseLabel;
    List<String> options = _parseNodeOptions();
    String? currentValue = nodeValue;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        label = parsed['label']?.toString() ?? label;
        if (parsed['options'] is List) {
          options = (parsed['options'] as List)
              .map((e) => e.toString())
              .toList();
        }
        currentValue = parsed['value']?.toString();
      } catch (e) {
        currentValue = vaultValue;
      }
    }

    if (currentValue != null &&
        currentValue.isNotEmpty &&
        !options.contains(currentValue)) {
      currentValue = null;
    }
    if (currentValue != null && currentValue.isEmpty) {
      currentValue = null;
    }

    void updateState(String lbl, List<String> opts, String? val) {
      final payload = jsonEncode({
        'label': lbl,
        'options': opts,
        'value': val ?? '',
      });
      ref.read(sduiStateVaultProvider.notifier).set(node.id, payload);
      widget.dispatcher.onStateChange(node.id, payload);
    }

    Widget buildDropdownField() {
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              key: ValueKey(currentValue),
              initialValue: currentValue,
              items: options.map((String val) {
                return DropdownMenuItem<String>(value: val, child: Text(val));
              }).toList(),
              onChanged: isInteractive
                  ? (String? newValue) {
                      updateState(label, options, newValue);
                    }
                  : null,
              decoration: InputDecoration(
                labelText: label.isNotEmpty ? label : null,
                hintText: hint,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                border: borderless
                    ? InputBorder.none
                    : const OutlineInputBorder(),
                contentPadding: borderless
                    ? EdgeInsets.zero
                    : const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                isDense: borderless,
                filled: !borderless,
                fillColor: borderless
                    ? Colors.transparent
                    : theme.colorScheme.surfaceContainerHighest.withAlpha(76),
                focusedBorder: borderless
                    ? InputBorder.none
                    : OutlineInputBorder(
                        borderSide: BorderSide(
                          color: accentColor ?? colorScheme.primary,
                          width: 2.0,
                        ),
                      ),
              ),
              iconEnabledColor: accentColor ?? colorScheme.primary,
              dropdownColor: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          if (isInteractive && !_isEditing) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withAlpha(30),
              child: IconButton(
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: colorScheme.primary,
                ),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit Options',
              ),
            ),
          ],
        ],
      );
    }

    if (isInteractive && _isEditing) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(
            color: colorScheme.outline.withAlpha(40),
            width: 1.0,
          ),
        ),
        color: colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Dropdown Options',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green,
                    ),
                    onPressed: () => setState(() => _isEditing = false),
                    tooltip: 'Done',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _labelController,
                decoration: const InputDecoration(
                  labelText: 'Dropdown Label',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  updateState(val, options, currentValue);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _optionsController,
                decoration: const InputDecoration(
                  labelText: 'Options (comma-separated)',
                  isDense: true,
                  border: OutlineInputBorder(),
                  helperText: 'Example: Yes, No, Maybe',
                ),
                onChanged: (val) {
                  final newOpts = val
                      .split(',')
                      .map((e) => e.trim())
                      .filter((e) => e.isNotEmpty)
                      .toList();
                  updateState(label, newOpts, currentValue);
                },
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: buildDropdownField(),
    );
  }
}

// Inline extension helper to filter elements (equivalent to where + cast)
extension _FilterList<T> on Iterable<T> {
  Iterable<T> filter(bool Function(T) test) {
    return where(test);
  }
}
