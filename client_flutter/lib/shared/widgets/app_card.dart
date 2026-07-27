import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_effects_theme.dart';
import '../../core/theme/theme_provider.dart';

/// Adaptive, stateful container card wrapper listening to ThemeExtension<AppEffectsTheme>
/// and ThemeNotifier settings for configurable MouseRegion hover spring scaling,
/// dynamic border glow, procedural glassmorphic noise grain painter, and backdrop blur.
class AppCard extends ConsumerStatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool enableHoverScale;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
    this.height,
    this.enableHoverScale = true,
  });

  @override
  ConsumerState<AppCard> createState() => _AppCardState();
}

class _AppCardState extends ConsumerState<AppCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeProvider);
    final cs = Theme.of(context).colorScheme;
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final radius = effects?.cardRadius ?? 16.0;
    final blur = effects?.backdropBlur ?? 0.0;
    final baseBorder = effects?.cardBorder ?? BorderSide(color: cs.outlineVariant);
    final shadows = effects?.cardShadow ?? [];
    final noiseOpacity = effects?.noiseOpacity ?? 0.0;
    final isGlow = themeState.enableGlowBorders && (effects?.enableNeonGlow ?? false);

    final isScalingEnabled = widget.enableHoverScale && themeState.enableHoverScaling;
    final targetScale = (isScalingEnabled && _isHovered) ? themeState.hoverScaleFactor : 1.0;

    // Enhance border & shadow on Desktop hover
    final effectiveBorderColor = _isHovered
        ? cs.primary.withValues(alpha: 0.5)
        : baseBorder.color;
    final effectiveBorderWidth = _isHovered ? baseBorder.width + 0.5 : baseBorder.width;

    final effectiveShadows = _isHovered && isGlow
        ? [
            ...shadows,
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.25),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ]
        : shadows;

    Widget cardBody = AnimatedContainer(
      duration: Duration(milliseconds: themeState.animationMs > 0 ? (themeState.animationMs / 2).round() : 150),
      curve: Curves.easeOutCubic,
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: blur > 0 ? 0.75 : 0.95),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: effectiveBorderColor, width: effectiveBorderWidth),
        boxShadow: effectiveShadows,
      ),
      child: Stack(
        children: [
          // Procedural glassmorphic noise grain texture painter
          if (noiseOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: noiseOpacity,
                  child: CustomPaint(
                    painter: _NoisePainter(color: cs.onSurface),
                  ),
                ),
              ),
            ),
          widget.child,
        ],
      ),
    );

    if (blur > 0) {
      cardBody = ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: cardBody,
        ),
      );
    }

    cardBody = AnimatedScale(
      scale: targetScale,
      duration: Duration(milliseconds: themeState.animationMs > 0 ? (themeState.animationMs / 2).round() : 150),
      curve: Curves.easeOutCubic,
      child: cardBody,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: widget.onTap != null
          ? InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(radius),
              child: cardBody,
            )
          : cardBody,
    );
  }
}

/// CustomPainter generating a fine procedural noise grain texture to give
/// glassmorphism tactile depth and prevent color banding on dark OLED & deep gradients.
class _NoisePainter extends CustomPainter {
  final Color color;

  const _NoisePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    final random = Random(42); // Deterministic seed for zero frame jitter
    final pointsCount = (size.width * size.height * 0.005).clamp(20.0, 300.0).toInt();

    for (int i = 0; i < pointsCount; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      canvas.drawPoints(PointMode.points, [Offset(dx, dy)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter oldDelegate) => oldDelegate.color != color;
}
