import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Windows Task Manager Performance Tab Style Mini Sparkline Chart Widget.
/// Renders a rolling line chart with grid background and gradient fill under the line.
class TelemetrySparkline extends StatelessWidget {
  final List<double> values;
  final Color lineColor;
  final double height;
  final double? maxVal;
  final double? minVal;
  final bool showGrid;

  const TelemetrySparkline({
    super.key,
    required this.values,
    required this.lineColor,
    this.height = 36.0,
    this.maxVal,
    this.minVal,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          lineColor: lineColor,
          maxVal: maxVal,
          minVal: minVal,
          showGrid: showGrid,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color lineColor;
  final double? maxVal;
  final double? minVal;
  final bool showGrid;

  _SparklinePainter({
    required this.values,
    required this.lineColor,
    this.maxVal,
    this.minVal,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // Draw Task Manager subtle background grid lines
    if (showGrid) {
      final gridPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.12)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      // Horizontal grid lines (top, middle, bottom)
      canvas.drawLine(Offset(0, height * 0.25), Offset(width, height * 0.25), gridPaint);
      canvas.drawLine(Offset(0, height * 0.50), Offset(width, height * 0.50), gridPaint);
      canvas.drawLine(Offset(0, height * 0.75), Offset(width, height * 0.75), gridPaint);

      // Vertical grid lines
      const cols = 4;
      final stepX = width / cols;
      for (int i = 1; i < cols; i++) {
        canvas.drawLine(Offset(i * stepX, 0), Offset(i * stepX, height), gridPaint);
      }
    }

    // Determine min/max values
    double min = minVal ?? values.reduce((a, b) => a < b ? a : b);
    double max = maxVal ?? values.reduce((a, b) => a > b ? a : b);
    if (max == min) {
      max = min + 1.0;
    }

    final range = max - min;
    final stepX = values.length > 1 ? width / (values.length - 1) : width;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalizedY = (values[i] - min) / range;
      final y = height - (normalizedY * (height - 4)) - 2; // Padding 2px
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // 1. Draw Task Manager Gradient Fill Under Line
    final fillPath = Path.from(path)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, height),
        [
          lineColor.withValues(alpha: 0.35),
          lineColor.withValues(alpha: 0.02),
        ],
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Draw Task Manager High-Contrast Stroke Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // 3. Draw End Point Glowing Dot (Current Value)
    if (points.isNotEmpty) {
      final last = points.last;
      final dotGlowPaint = Paint()
        ..color = lineColor.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      final dotPaint = Paint()..color = lineColor;

      canvas.drawCircle(last, 3.5, dotGlowPaint);
      canvas.drawCircle(last, 2.0, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.lineColor != lineColor;
  }
}
