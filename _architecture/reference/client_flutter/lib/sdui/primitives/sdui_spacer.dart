import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiSpacer extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiSpacer({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiSpacer> createState() => _SduiSpacerState();
}

class _SduiSpacerState extends ConsumerState<SduiSpacer> {
  double? _customWidth;
  double? _customHeight;
  int? _customFlex;
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Retrieve Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    
    // Retrieve base values
    final double? baseWidth = node.behavior<double>(HbpBehavior.WIDTH) ?? 
                             node.behavior<int>(HbpBehavior.WIDTH)?.toDouble();
    final double? baseHeight = node.behavior<double>(HbpBehavior.HEIGHT) ?? 
                              node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble();
    final int? baseFlex = node.behavior<int>(HbpBehavior.FLEX);

    // 2. Retrieve State from Vault
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey] as String?));
    
    double? width = baseWidth;
    double? height = baseHeight;
    int? flex = baseFlex;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        width = parsed['width'] != null ? (parsed['width'] as num).toDouble() : baseWidth;
        height = parsed['height'] != null ? (parsed['height'] as num).toDouble() : baseHeight;
        flex = parsed['flex'] != null ? (parsed['flex'] as num).toInt() : baseFlex;
      } catch (e) {
        // Silent fallback
      }
    }

    _customWidth ??= width;
    _customHeight ??= height;
    _customFlex ??= flex;

    void updateState(double? w, double? h, int? f) {
      setState(() {
        _customWidth = w;
        _customHeight = h;
        _customFlex = f;
      });
      final payload = jsonEncode({
        'width': w,
        'height': h,
        'flex': f,
      });
      ref.read(sduiStateVaultProvider.notifier).set(bindKey, payload);
      widget.dispatcher.onStateChange(bindKey, payload);
      
      // Update flex directly on the node's behavior map so that SduiRenderer dynamically adjusts the Expanded wrapper
      if (f != null) {
        node.behaviors[HbpBehavior.FLEX] = f;
      } else {
        node.behaviors.remove(HbpBehavior.FLEX);
      }
    }

    if (interactiveMode == 1) {
      final bool isFlexSpacer = _customFlex != null && _customFlex! > 0;
      
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.space_bar_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isFlexSpacer 
                            ? 'Flex Spacer Sandbox (flex: $_customFlex)'
                            : 'Fixed Spacer Sandbox',
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
                const SizedBox(height: 10),
                
                CustomPaint(
                  painter: DashedBorderPainter(color: colorScheme.primary.withAlpha(150), gap: 4.0),
                  child: Container(
                    width: isFlexSpacer ? double.infinity : (_customWidth ?? 40.0),
                    height: _customHeight ?? 40.0,
                    color: colorScheme.primary.withAlpha(10),
                    child: Center(
                      child: Text(
                        isFlexSpacer ? 'Flex Spacer ($_customFlex)' : '${(_customWidth ?? 0.0).toStringAsFixed(0)} x ${(_customHeight ?? 0.0).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                if (isFlexSpacer) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Flex Weight:', style: theme.textTheme.bodyMedium),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _customFlex! > 1 
                              ? () => updateState(_customWidth, _customHeight, _customFlex! - 1)
                              : null,
                          ),
                          Text('$_customFlex', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => updateState(_customWidth, _customHeight, _customFlex! + 1),
                          ),
                        ],
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Width: ${(_customWidth ?? 0.0).toStringAsFixed(0)}dp',
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
                                value: _customWidth ?? 0.0,
                                min: 0.0,
                                max: 160.0,
                                onChanged: (val) => updateState(val, _customHeight, _customFlex),
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
                              'Height: ${(_customHeight ?? 0.0).toStringAsFixed(0)}dp',
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
                                value: _customHeight ?? 0.0,
                                min: 0.0,
                                max: 160.0,
                                onChanged: (val) => updateState(_customWidth, val, _customFlex),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      } else {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CustomPaint(
                painter: DashedBorderPainter(color: colorScheme.primary.withAlpha(120), gap: 4.0),
                child: Container(
                  width: isFlexSpacer ? 120.0 : (_customWidth ?? 40.0),
                  height: _customHeight ?? 40.0,
                  color: colorScheme.primary.withAlpha(8),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        isFlexSpacer ? 'Flex ($_customFlex)' : '${(_customWidth ?? 0.0).toStringAsFixed(0)}x${(_customHeight ?? 0.0).toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 8,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primary.withAlpha(40),
                child: IconButton(
                  icon: Icon(Icons.edit_rounded, size: 10, color: colorScheme.primary),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Spacer',
                ),
              ),
            ],
          ),
        );
      }
    }

    if (_customFlex != null && _customFlex! > 0) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: _customWidth,
      height: _customHeight,
    );
  }
}

class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    for (double i = 0; i < size.width; i += gap * 2) {
      path.moveTo(i, 0);
      path.lineTo((i + gap).clamp(0.0, size.width), 0);
    }
    
    for (double i = 0; i < size.height; i += gap * 2) {
      path.moveTo(size.width, i);
      path.lineTo(size.width, (i + gap).clamp(0.0, size.height));
    }
    
    for (double i = 0; i < size.width; i += gap * 2) {
      path.moveTo(size.width - i, size.height);
      path.lineTo((size.width - i - gap).clamp(0.0, size.width), size.height);
    }
    
    for (double i = 0; i < size.height; i += gap * 2) {
      path.moveTo(0, size.height - i);
      path.lineTo(0, (size.height - i - gap).clamp(0.0, size.height));
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
