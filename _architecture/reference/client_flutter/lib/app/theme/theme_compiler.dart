import 'package:flutter/material.dart';

/// A pure mathematical compiler that translates seed colors into a full
/// Material 3 HCT (Hue, Chroma, Tone) schema without pre-allocating static palettes.
class ThemeCompiler {
  static ThemeData compile({
    required Brightness brightness,
    required Color primarySeed,
    Color? secondarySeed,
    double textScale = 1.0,
  }) {
    // 1. Generate the foundational ColorScheme using the primary seed.
    // This instantly calculates 30+ tonal variants for surfaces, text, and containers.
    var scheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: brightness,
    );

    // 2. If the user explicitly defines a secondary color, we forcefully
    // inject it by deriving a parallel tonal palette and grafting it into the schema.
    if (secondarySeed != null) {
      final secondaryScheme = ColorScheme.fromSeed(
        seedColor: secondarySeed,
        brightness: brightness,
      );
      scheme = scheme.copyWith(
        secondary: secondarySeed, // Force exact hex to bypass HCT shifting
        onSecondary: secondaryScheme.onPrimary,
        secondaryContainer: secondaryScheme.primaryContainer,
        onSecondaryContainer: secondaryScheme.onPrimaryContainer,
      );
    }

    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      // Enforce zero-layout-shift strict sizing
      visualDensity: VisualDensity.standard,
    );
  }
}
