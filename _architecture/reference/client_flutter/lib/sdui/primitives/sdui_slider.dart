import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';

class SduiSlider extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiSlider({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiSlider> createState() => _SduiSliderState();
}

class _SduiSliderState extends ConsumerState<SduiSlider> {
  double? _localSingleValue;
  RangeValues? _localRangeValues;

  @override
  void didUpdateWidget(covariant SduiSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final double? oldStart = oldWidget.node.contentVal<double>(0);
    final double? newStart = widget.node.contentVal<double>(0);
    final double? oldEnd = oldWidget.node.contentVal<double>(6);
    final double? newEnd = widget.node.contentVal<double>(6);
    
    if (widget.node.id != oldWidget.node.id || oldStart != newStart || oldEnd != newEnd) {
      setState(() {
        _localSingleValue = null;
        _localRangeValues = null;
      });
    }
  }

  double _normalize(double raw, double min, double max, bool normalize) {
    if (!normalize) return raw;
    final double span = max - min;
    if (span == 0) return 0.0;
    return (raw - min) / span;
  }

  @override
  Widget build(BuildContext context) {
    // Behaviors
    final int sliderMode = widget.node.behavior<int>(122) ?? 0; // 0=single, 1=range
    final double minValue = widget.node.behavior<double>(44) ?? 0.0;
    final double maxValue = widget.node.behavior<double>(45) ?? 1.0;
    final double? step = widget.node.behavior<double>(46);
    final bool normalizeOutput = widget.node.behavior<int>(47) == 1;
    final bool showLabel = widget.node.behavior<int>(121) == 1;
    final int interactiveMode = widget.node.behavior<int>(95) ?? 1;
    
    final Color? accentColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(96));
    final theme = Theme.of(context);
    final activeColor = accentColor ?? theme.colorScheme.primary;

    // Content
    final String? labelText = widget.node.contentVal<String>(1);

    // Calculate divisions
    int? divisions;
    if (step != null && step > 0) {
      divisions = ((maxValue - minValue) / step).round();
    }

    Widget sliderWidget;

    final rawVaultVal = ref.watch(
      sduiStateVaultProvider.select((state) => state[widget.node.id]),
    );

    if (sliderMode == 1) {
      // RANGE SLIDER
      double startVal = widget.node.contentVal<double>(0) ?? minValue;
      double endVal = widget.node.contentVal<double>(6) ?? maxValue;
      
      if (rawVaultVal is List && rawVaultVal.length >= 2) {
        startVal = (rawVaultVal[0] as num).toDouble();
        endVal = (rawVaultVal[1] as num).toDouble();
      } else if (rawVaultVal is Map) {
        startVal = (rawVaultVal['start'] as num?)?.toDouble() ?? startVal;
        endVal = (rawVaultVal['end'] as num?)?.toDouble() ?? endVal;
      }

      final currentRange = _localRangeValues ?? RangeValues(startVal, endVal);

      sliderWidget = SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        ),
        child: RangeSlider(
          values: currentRange,
          min: minValue,
          max: maxValue,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: activeColor.withAlpha(51), // 0.2 opacity
          labels: RangeLabels(
            currentRange.start.toStringAsFixed(1),
            currentRange.end.toStringAsFixed(1),
          ),
          onChanged: interactiveMode == 1
              ? (values) {
                  setState(() => _localRangeValues = values);
                }
              : null,
          onChangeEnd: interactiveMode == 1
              ? (values) {
                  final outStart = _normalize(values.start, minValue, maxValue, normalizeOutput);
                  final outEnd = _normalize(values.end, minValue, maxValue, normalizeOutput);
                  widget.dispatcher.onStateChange(widget.node.id, [outStart, outEnd]);
                  
                  final actionPayload = widget.node.behavior<Map<int, dynamic>>(70);
                  if (actionPayload != null) {
                    widget.dispatcher.onAction(actionPayload);
                  }
                }
              : null,
        ),
      );
    } else {
      // SINGLE SLIDER
      double currentVal = widget.node.contentVal<double>(0) ?? minValue;
      if (rawVaultVal is num) {
        currentVal = rawVaultVal.toDouble();
      }

      final displayVal = _localSingleValue ?? currentVal;

      sliderWidget = SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.0,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.0),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
        ),
        child: Slider(
          value: displayVal.clamp(minValue, maxValue),
          min: minValue,
          max: maxValue,
          divisions: divisions,
          activeColor: activeColor,
          inactiveColor: activeColor.withAlpha(51),
          label: displayVal.toStringAsFixed(1),
          onChanged: interactiveMode == 1
              ? (v) {
                  setState(() => _localSingleValue = v);
                }
              : null,
          onChangeEnd: interactiveMode == 1
              ? (v) {
                  final outVal = _normalize(v, minValue, maxValue, normalizeOutput);
                  widget.dispatcher.onStateChange(widget.node.id, outVal);
                  
                  final actionPayload = widget.node.behavior<Map<int, dynamic>>(70);
                  if (actionPayload != null) {
                    widget.dispatcher.onAction(actionPayload);
                  }
                }
              : null,
        ),
      );
    }

    if (!showLabel && labelText == null) return sliderWidget;

    final String valueText;
    if (sliderMode == 1) {
      final r = _localRangeValues ?? RangeValues(minValue, maxValue);
      valueText = '${r.start.round()}-${r.end.round()}';
    } else {
      final v = _localSingleValue ?? minValue;
      valueText = v.round().toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (labelText != null)
              Text(
                labelText,
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            if (showLabel)
              Text(
                valueText,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'JetBrainsMono',
                  color: activeColor,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        sliderWidget,
      ],
    );
  }
}
