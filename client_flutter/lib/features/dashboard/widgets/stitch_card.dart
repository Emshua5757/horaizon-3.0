import 'package:flutter/material.dart';
import '../../../shared/widgets/app_card.dart';

/// Reusable glassmorphic card matching active theme preset and Google Stitch specifications.
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
    return AppCard(
      padding: padding,
      child: child,
    );
  }
}
