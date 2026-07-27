import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/theme/app_effects_theme.dart';

/// Adaptive container card wrapper that listens to ThemeExtension<AppEffectsTheme>
/// to automatically render shadows, corner radius, borders, noise grain, and backdrop blur.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final radius = effects?.cardRadius ?? 16.0;
    final blur = effects?.backdropBlur ?? 0.0;
    final border = effects?.cardBorder ?? BorderSide(color: cs.outlineVariant);
    final shadows = effects?.cardShadow ?? [];
    final noiseOpacity = effects?.noiseOpacity ?? 0.0;

    Widget cardBody = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: blur > 0 ? 0.75 : 0.95),
        borderRadius: BorderRadius.circular(radius),
        border: Border.fromBorderSide(border),
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          // Optional frosted noise texture overlay
          if (noiseOpacity > 0)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: noiseOpacity,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: RadialGradient(
                        colors: [cs.onSurface.withValues(alpha: 0.1), Colors.transparent],
                        radius: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          child,
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: cardBody,
      );
    }

    return cardBody;
  }
}
