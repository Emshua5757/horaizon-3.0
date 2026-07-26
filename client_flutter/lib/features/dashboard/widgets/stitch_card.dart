import 'package:flutter/material.dart';

/// Reusable obsidian glassmorphic card matching Google Stitch specifications.
class StitchCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final Color? backgroundColor;
  final bool isGlowing;
  final EdgeInsetsGeometry padding;

  const StitchCard({
    super.key,
    required this.child,
    this.borderColor,
    this.backgroundColor,
    this.isGlowing = false,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ??
        (isGlowing
            ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.08));

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFF12121A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: effectiveBorderColor, width: 1),
        boxShadow: isGlowing
            ? [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}
