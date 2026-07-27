import 'package:flutter/material.dart';
import 'app_effects_theme.dart';
import 'app_semantic_palette.dart';

/// Abstract contract for all multi-dimensional theme presets.
/// Each preset owns both a Light Variant and a Dark Variant, along with
/// its colors, typography, iconography style, card geometry, and semantic palette.
abstract class AppThemePreset {
  String get id;
  String get name;
  String get description;
  IconData get icon;

  /// Returns true if this preset supports circadian time-of-day auto shifting
  bool get supportsCircadianShift => true;

  /// Palette & effects configuration for specified brightness (Light vs Dark)
  PresetVariant getVariant(Brightness brightness);
}

/// Holds complete styling tokens for a specific brightness variant of a preset.
class PresetVariant {
  final Brightness brightness;
  final Color scaffoldBg;
  final Color cardBg;
  final Color primary;
  final Color secondary;
  final Color onSurface;
  final Color onSurfaceVariant;
  final String fontFamily;
  final AppEffectsTheme effects;
  final AppSemanticPalette semantic;

  const PresetVariant({
    required this.brightness,
    required this.scaffoldBg,
    required this.cardBg,
    required this.primary,
    required this.secondary,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.fontFamily,
    required this.effects,
    required this.semantic,
  });
}
