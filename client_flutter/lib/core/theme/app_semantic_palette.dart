import 'package:flutter/material.dart';

/// Harmonized semantic palette for data visualization (telemetry charts, gauges, temperature badges, SIGSTOP pills):
/// Prevents neon green/cyan from clashing when switching from Cyberpunk Dark to Creamy Latte or Vintage Parchment.
class AppSemanticPalette extends ThemeExtension<AppSemanticPalette> {
  final Color success;      // Online / RPi5 link / Normal temp
  final Color warning;      // Sleeping SIGSTOP / High temp warning
  final Color critical;     // Offline / Error crash
  final Color info;         // Ping RTT / WebSocket metadata
  final List<Color> chart;  // 4-color palette for telemetry line & bar charts

  const AppSemanticPalette({
    required this.success,
    required this.warning,
    required this.critical,
    required this.info,
    required this.chart,
  });

  @override
  AppSemanticPalette copyWith({
    Color? success,
    Color? warning,
    Color? critical,
    Color? info,
    List<Color>? chart,
  }) {
    return AppSemanticPalette(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      critical: critical ?? this.critical,
      info: info ?? this.info,
      chart: chart ?? this.chart,
    );
  }

  @override
  AppSemanticPalette lerp(ThemeExtension<AppSemanticPalette>? other, double t) {
    if (other is! AppSemanticPalette) return this;
    return AppSemanticPalette(
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      critical: Color.lerp(critical, other.critical, t)!,
      info: Color.lerp(info, other.info, t)!,
      chart: List.generate(
        chart.length,
        (i) => Color.lerp(chart[i], other.chart[i % other.chart.length], t)!,
      ),
    );
  }
}
