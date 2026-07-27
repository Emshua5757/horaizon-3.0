import 'dart:ui';
import 'package:flutter/material.dart';

/// Custom ThemeExtension specifying dynamic visual effects per theme vibe:
/// - Shadows (Neon outer glow vs soft natural drop shadow vs flat)
/// - Borders (Glowing neon side vs soft ceramic outline vs solid contrast)
/// - Backdrop blur sigma for glassmorphism
/// - Noise grain intensity overlay
/// - Status LED halo blur flag
class AppEffectsTheme extends ThemeExtension<AppEffectsTheme> {
  final List<BoxShadow> cardShadow;
  final BorderSide cardBorder;
  final double cardRadius;
  final double buttonRadius;
  final double backdropBlur;
  final double noiseOpacity;
  final bool enableNeonGlow;
  final bool useStatusHalo;
  final Duration animDuration;
  final Curve animCurve;

  const AppEffectsTheme({
    required this.cardShadow,
    required this.cardBorder,
    required this.cardRadius,
    required this.buttonRadius,
    required this.backdropBlur,
    required this.noiseOpacity,
    required this.enableNeonGlow,
    required this.useStatusHalo,
    required this.animDuration,
    required this.animCurve,
  });

  @override
  AppEffectsTheme copyWith({
    List<BoxShadow>? cardShadow,
    BorderSide? cardBorder,
    double? cardRadius,
    double? buttonRadius,
    double? backdropBlur,
    double? noiseOpacity,
    bool? enableNeonGlow,
    bool? useStatusHalo,
    Duration? animDuration,
    Curve? animCurve,
  }) {
    return AppEffectsTheme(
      cardShadow: cardShadow ?? this.cardShadow,
      cardBorder: cardBorder ?? this.cardBorder,
      cardRadius: cardRadius ?? this.cardRadius,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      backdropBlur: backdropBlur ?? this.backdropBlur,
      noiseOpacity: noiseOpacity ?? this.noiseOpacity,
      enableNeonGlow: enableNeonGlow ?? this.enableNeonGlow,
      useStatusHalo: useStatusHalo ?? this.useStatusHalo,
      animDuration: animDuration ?? this.animDuration,
      animCurve: animCurve ?? this.animCurve,
    );
  }

  @override
  AppEffectsTheme lerp(ThemeExtension<AppEffectsTheme>? other, double t) {
    if (other is! AppEffectsTheme) return this;
    return AppEffectsTheme(
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t) ?? cardShadow,
      cardBorder: BorderSide.lerp(cardBorder, other.cardBorder, t),
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t) ?? cardRadius,
      buttonRadius: lerpDouble(buttonRadius, other.buttonRadius, t) ?? buttonRadius,
      backdropBlur: lerpDouble(backdropBlur, other.backdropBlur, t) ?? backdropBlur,
      noiseOpacity: lerpDouble(noiseOpacity, other.noiseOpacity, t) ?? noiseOpacity,
      enableNeonGlow: t < 0.5 ? enableNeonGlow : other.enableNeonGlow,
      useStatusHalo: t < 0.5 ? useStatusHalo : other.useStatusHalo,
      animDuration: t < 0.5 ? animDuration : other.animDuration,
      animCurve: t < 0.5 ? animCurve : other.animCurve,
    );
  }
}
