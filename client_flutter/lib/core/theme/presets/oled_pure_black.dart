import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class OledPureBlackPreset implements AppThemePreset {
  @override String get id => 'oled_pure_black';
  @override String get name => 'OLED Pure Black';
  @override String get description => 'Tactical Monochrome & Zero Battery Drain';
  @override IconData get icon => Icons.contrast_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        scaffoldBg: Colors.black,
        cardBg: Color(0xFF0E0E10),
        primary: Colors.white,
        secondary: Color(0xFFA1A1AA),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFA1A1AA),
        fontFamily: 'JetBrains Mono',
        effects: AppEffectsTheme(
          cardShadow: [],
          cardBorder: BorderSide(color: Color(0xFF27272A), width: 1.0),
          cardRadius: 4.0,
          buttonRadius: 4.0,
          backdropBlur: 0.0,
          noiseOpacity: 0.0,
          enableNeonGlow: false,
          useStatusHalo: false,
          animDuration: Duration(milliseconds: 100),
          animCurve: Curves.linear,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF22C55E),
          warning: Color(0xFFEAB308),
          critical: Color(0xFFEF4444),
          info: Color(0xFF38BDF8),
          chart: [Colors.white, Color(0xFFA1A1AA), Color(0xFF38BDF8), Color(0xFF22C55E)],
        ),
      );
    }

    // High Contrast White Variant
    return const PresetVariant(
      brightness: Brightness.light,
      scaffoldBg: Colors.white,
      cardBg: Color(0xFFF4F4F5),
      primary: Colors.black,
      secondary: Color(0xFF52525B),
      onSurface: Colors.black,
      onSurfaceVariant: Color(0xFF52525B),
      fontFamily: 'JetBrains Mono',
      effects: AppEffectsTheme(
        cardShadow: [],
        cardBorder: BorderSide(color: Color(0xFFE4E4E7), width: 1.0),
        cardRadius: 4.0,
        buttonRadius: 4.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 100),
        animCurve: Curves.linear,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF16A34A),
        warning: Color(0xFFCA8A04),
        critical: Color(0xFFDC2626),
        info: Color(0xFF0284C7),
        chart: [Colors.black, Color(0xFF52525B), Color(0xFF0284C7), Color(0xFF16A34A)],
      ),
    );
  }
}
