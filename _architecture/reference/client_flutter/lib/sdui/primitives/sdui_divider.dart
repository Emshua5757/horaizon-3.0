import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiDivider extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiDivider({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiDivider> createState() => _SduiDividerState();
}

class _SduiDividerState extends ConsumerState<SduiDivider> {
  double? _customThickness;
  double? _customIndent;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Retrieve Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    
    // Retrieve base values
    final double baseThickness = node.behavior<double>(HbpBehavior.BORDER_WIDTH) ?? 
                                 node.behavior<int>(HbpBehavior.BORDER_WIDTH)?.toDouble() ?? 1.0;
    
    final dynamic rawPadding = node.behavior<dynamic>(HbpBehavior.PADDING);
    final EdgeInsets? paddingInsets = SduiStyleResolver.resolveEdgeInsets(rawPadding) as EdgeInsets?;
    final double baseIndent = paddingInsets != null && paddingInsets.left > 0 ? paddingInsets.left : 0.0;

    final accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.outlineVariant;

    // 2. Retrieve State from Vault
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey] as String?));
    
    double thickness = baseThickness;
    double indent = baseIndent;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        thickness = (parsed['thickness'] as num?)?.toDouble() ?? baseThickness;
        indent = (parsed['indent'] as num?)?.toDouble() ?? baseIndent;
      } catch (e) {
        // Silent fallback on parse error
      }
    }

    _customThickness ??= thickness;
    _customIndent ??= indent;

    void updateState(double t, double ind) {
      setState(() {
        _customThickness = t;
        _customIndent = ind;
      });
      final payload = jsonEncode({
        'thickness': t,
        'indent': ind,
      });
      ref.read(sduiStateVaultProvider.notifier).set(bindKey, payload);
      widget.dispatcher.onStateChange(bindKey, payload);
    }

    Widget buildDividerLine() {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: _customIndent!),
        child: Divider(
          thickness: _customThickness,
          color: accentColor,
          height: _customThickness! + 12.0,
        ),
      );
    }

    if (interactiveMode == 1) {
      if (_isEditing) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
            side: BorderSide(color: colorScheme.outline.withAlpha(60), width: 1.0),
          ),
          color: colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.horizontal_rule_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Divider Sandbox (Editing)',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                      onPressed: () => setState(() => _isEditing = false),
                      tooltip: 'Done Editing',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                buildDividerLine(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thickness: ${_customThickness!.toStringAsFixed(1)}dp',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          SliderTheme(
                            data: theme.sliderTheme.copyWith(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.outlineVariant,
                              thumbColor: colorScheme.primary,
                            ),
                            child: Slider(
                              value: _customThickness!,
                              min: 1.0,
                              max: 12.0,
                              onChanged: (val) => updateState(val, _customIndent!),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Indent: ${_customIndent!.toStringAsFixed(0)}dp',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          SliderTheme(
                            data: theme.sliderTheme.copyWith(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
                              activeTrackColor: colorScheme.primary,
                              inactiveTrackColor: colorScheme.outlineVariant,
                              thumbColor: colorScheme.primary,
                            ),
                            child: Slider(
                              value: _customIndent!,
                              min: 0.0,
                              max: 80.0,
                              onChanged: (val) => updateState(_customThickness!, val),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: buildDividerLine(),
            ),
            Positioned(
              right: 8,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Divider',
                ),
              ),
            ),
          ],
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: buildDividerLine(),
    );
  }
}
