import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/governor/governor_metrics_provider.dart';

class SduiProgressBar extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiProgressBar({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Content: value(0)=null -> indeterminate, label(1)
    double? rawValue = node.contentVal<double>(0) ?? node.contentVal<int>(0)?.toDouble();
    String? label = node.contentVal<String>(1);

    if (node.id == 'dashboard:cpu_progress') {
      final metricsAsync = ref.watch(governorMetricsProvider);
      metricsAsync.whenData((snapshot) {
        rawValue = snapshot.cpuPct / 100.0;
        label = 'CPU Load: ${snapshot.cpuPct.toStringAsFixed(1)}% (RPi 5 Quad-Core ARM)';
      });
    } else if (node.id == 'dashboard:ram_progress') {
      final metricsAsync = ref.watch(governorMetricsProvider);
      metricsAsync.whenData((snapshot) {
        rawValue = snapshot.ramPct;
        label = 'Active RSS RAM: ${snapshot.ramMb.toStringAsFixed(1)} MB / 8 GB';
      });
    } else if (node.id == 'dashboard:nas_storage_progress') {
      // Phase 8: NAS storage stats injected by Rust dashboard handler via keys 83 & 84.
      // Falls back to blueprint static defaults until the first 60s disk monitor cycle.
      final liveRatio = node.contentVal<double>(83) ?? node.contentVal<int>(83)?.toDouble();
      final liveLabel = node.contentVal<String>(84);
      if (liveRatio != null) rawValue = liveRatio;
      if (liveLabel != null) label = liveLabel;
    }


    // 2. Behavior: progress_mode(123), min(44), max(45), accent(96)
    final int progressMode = node.behavior<int>(123) ?? 0; // 0=linear, 1=circular
    final double minVal = node.behavior<double>(44) ?? node.behavior<int>(44)?.toDouble() ?? 0.0;
    final double maxVal = node.behavior<double>(45) ?? node.behavior<int>(45)?.toDouble() ?? 1.0;
    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(96));

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final activeColor = accentColor ?? colorScheme.primary;

    double? normalizedValue;
    final double? finalVal = rawValue;
    if (finalVal != null) {
      final range = maxVal - minVal;
      normalizedValue = range > 0 ? ((finalVal - minVal) / range).clamp(0.0, 1.0) : 0.0;
    }

    Widget progressWidget;
    if (progressMode == 1) { // circular
      progressWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircularProgressIndicator(
            value: normalizedValue,
            strokeWidth: 4.0,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(activeColor),
          ),
        ),
      );
    } else { // linear
      progressWidget = ClipRRect(
        borderRadius: BorderRadius.circular(4.0),
        child: LinearProgressIndicator(
          value: normalizedValue,
          minHeight: 8.0,
          backgroundColor: colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
        ),
      );
    }

    final String? finalLabel = label;
    if (finalLabel != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(finalLabel, style: theme.textTheme.labelMedium),
          const SizedBox(height: 8.0),
          progressWidget,
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: progressWidget,
    );
  }
}
