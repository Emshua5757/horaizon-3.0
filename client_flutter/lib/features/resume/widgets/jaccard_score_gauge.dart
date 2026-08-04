import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated arc gauge displaying the live Jaccard keyword match score.
///
/// Color interpolation:
///   0–30%  → red    #E53935
///   31–60% → amber  #FFA000
///   61–100%→ green  #43A047
///
/// Uses [AnimationController] + [Tween<double>] for smooth arc transitions.
class JaccardScoreGauge extends StatefulWidget {
  /// Match score in [0.0, 1.0].
  final double score;

  const JaccardScoreGauge({super.key, required this.score});

  @override
  State<JaccardScoreGauge> createState() => _JaccardScoreGaugeState();
}

class _JaccardScoreGaugeState extends State<JaccardScoreGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = Tween<double>(begin: 0.0, end: widget.score.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(JaccardScoreGauge old) {
    super.didUpdateWidget(old);
    if (old.score != widget.score) {
      _anim = Tween<double>(
        begin: _anim.value,
        end: widget.score.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _gaugeColor(double score) {
    if (score <= 0.30) return const Color(0xFFE53935);
    if (score <= 0.60) {
      final t = (score - 0.30) / 0.30;
      return Color.lerp(const Color(0xFFE53935), const Color(0xFFFFA000), t)!;
    }
    final t = (score - 0.60) / 0.40;
    return Color.lerp(const Color(0xFFFFA000), const Color(0xFF43A047), t)!;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final val = _anim.value;
        final pct = (val * 100).round();
        final color = _gaugeColor(val);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 140,
              height: 100,
              child: CustomPaint(
                painter: _ArcPainter(
                  value: val,
                  color: color,
                  trackColor: theme.colorScheme.surfaceContainerHighest,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Text(
                      '$pct%',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Match: $pct%',
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            Text(
              '(live keyword analysis)',
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.outline),
            ),
          ],
        );
      },
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;   // 0.0 – 1.0
  final Color color;
  final Color trackColor;

  const _ArcPainter({
    required this.value,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = size.width / 2 - strokeWidth / 2;

    // Track arc (180° from left to right)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      trackPaint,
    );

    if (value > 0) {
      final valuePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * value,
        false,
        valuePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.value != value || old.color != color;
}
