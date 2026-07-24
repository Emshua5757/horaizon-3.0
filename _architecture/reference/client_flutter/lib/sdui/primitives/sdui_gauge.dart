import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// SduiGauge - Type ID 27
/// 
/// High-performance data telemetry visualization primitive rendering Radial speedometer
/// dials or Linear thermometer levels dynamically from HBP payloads.
class SduiGauge extends StatelessWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiGauge({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Retrieve behaviors
    final double? width = node.behavior<double>(HbpBehavior.WIDTH) ?? node.behavior<int>(HbpBehavior.WIDTH)?.toDouble();
    final double? height = node.behavior<double>(HbpBehavior.HEIGHT) ?? node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble();
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 8.0;

    // Scale boundaries
    final double minValue = node.behavior<double>(HbpBehavior.MIN_VALUE) ?? node.behavior<int>(HbpBehavior.MIN_VALUE)?.toDouble() ?? 0.0;
    final double maxValue = node.behavior<double>(HbpBehavior.MAX_VALUE) ?? node.behavior<int>(HbpBehavior.MAX_VALUE)?.toDouble() ?? 100.0;
    
    // progress_mode: 0=linear, 1=circular, 2=radial (default to radial)
    final int progressMode = node.behavior<int>(HbpBehavior.PROGRESS_MODE) ?? 2;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final Color accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // Value and label resolution
    final double value = node.contentVal<double>(HbpContent.VALUE) ?? node.contentVal<int>(HbpContent.VALUE)?.toDouble() ?? minValue;
    final String? title = node.contentVal<String>(HbpContent.LABEL);

    // Clamp value to min/max safety boundaries
    final double clampedValue = value.clamp(minValue, maxValue);

    Widget gaugeWidget;
    if (progressMode == 0) {
      // Linear Gauge
      gaugeWidget = _buildLinearGauge(clampedValue, minValue, maxValue, accentColor, colorScheme, theme);
    } else {
      // Radial Gauge (default)
      gaugeWidget = _buildRadialGauge(clampedValue, minValue, maxValue, accentColor, colorScheme, theme);
    }

    return RepaintBoundary(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? (progressMode == 0 ? 110.0 : 200.0),
        margin: const EdgeInsets.symmetric(vertical: 6.0),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(borderRadiusVal),
          border: Border.all(
            color: colorScheme.outline.withAlpha(50),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null && title.isNotEmpty) ...[
              Text(
                title,
                textAlign: progressMode == 0 ? TextAlign.start : TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Expanded(child: gaugeWidget),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialGauge(
    double value,
    double min,
    double max,
    Color accentColor,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SfRadialGauge(
      enableLoadingAnimation: true,
      animationDuration: 800,
      axes: <RadialAxis>[
        RadialAxis(
          minimum: min,
          maximum: max,
          showLabels: true,
          showTicks: true,
          axisLineStyle: AxisLineStyle(
            thickness: 10,
            color: colorScheme.surfaceContainerHighest,
            thicknessUnit: GaugeSizeUnit.logicalPixel,
          ),
          majorTickStyle: MajorTickStyle(
            length: 8,
            thickness: 1.5,
            color: colorScheme.outline.withAlpha(128),
          ),
          minorTickStyle: MinorTickStyle(
            length: 4,
            thickness: 1.0,
            color: colorScheme.outline.withAlpha(80),
          ),
          axisLabelStyle: GaugeTextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 10,
            fontFamily: theme.textTheme.bodySmall?.fontFamily,
          ),
          pointers: <GaugePointer>[
            // Accent colored progress arc
            RangePointer(
              value: value,
              width: 10,
              color: accentColor,
              enableAnimation: true,
              animationDuration: 800,
              gradient: SweepGradient(
                colors: [accentColor.withAlpha(150), accentColor],
                stops: const [0.0, 1.0],
              ),
            ),
            // Fine needle pointer
            NeedlePointer(
              value: value,
              needleLength: 0.8,
              needleStartWidth: 3,
              needleEndWidth: 1,
              needleColor: colorScheme.onSurface,
              knobStyle: KnobStyle(
                knobRadius: 0.08,
                sizeUnit: GaugeSizeUnit.factor,
                color: colorScheme.onSurface,
              ),
              enableAnimation: true,
              animationDuration: 800,
            ),
          ],
          annotations: <GaugeAnnotation>[
            GaugeAnnotation(
              angle: 90,
              positionFactor: 0.7,
              widget: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value.toStringAsFixed(1),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinearGauge(
    double value,
    double min,
    double max,
    Color accentColor,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return SfLinearGauge(
      minimum: min,
      maximum: max,
      orientation: LinearGaugeOrientation.horizontal,
      animateRange: true,
      animationDuration: 800,
      axisTrackStyle: LinearAxisTrackStyle(
        thickness: 8,
        color: colorScheme.surfaceContainerHighest,
        edgeStyle: LinearEdgeStyle.startCurve,
      ),
      labelPosition: LinearLabelPosition.outside,
      tickPosition: LinearElementPosition.outside,
      majorTickStyle: LinearTickStyle(
        length: 8,
        color: colorScheme.outline.withAlpha(128),
      ),
      minorTickStyle: LinearTickStyle(
        length: 4,
        color: colorScheme.outline.withAlpha(80),
      ),
      axisLabelStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 10,
        fontFamily: theme.textTheme.bodySmall?.fontFamily,
      ),
      barPointers: <LinearBarPointer>[
        LinearBarPointer(
          value: value,
          thickness: 8,
          color: accentColor,
          edgeStyle: LinearEdgeStyle.startCurve,
          animationDuration: 800,
          enableAnimation: true,
        ),
      ],
      markerPointers: <LinearMarkerPointer>[
        LinearShapePointer(
          value: value,
          shapeType: LinearShapePointerType.invertedTriangle,
          color: colorScheme.onSurface,
          position: LinearElementPosition.cross,
          width: 12,
          height: 12,
          animationDuration: 800,
          enableAnimation: true,
        ),
      ],
    );
  }
}
