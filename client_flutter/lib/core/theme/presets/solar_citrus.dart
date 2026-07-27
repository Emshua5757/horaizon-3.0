import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

/// Preset 10: Solar Citrus
/// Energetic Solar Yellow & Fresh Citrus Warmth covering the Yellow spectrum.
class SolarCitrusPreset implements AppThemePreset {
  @override String get id => 'solar_citrus';
  @override String get name => 'Solar Citrus';
  @override String get description => 'Energetic Solar Yellow & Fresh Citrus Warmth';
  @override IconData get icon => Icons.wb_sunny_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        primary: Color(0xFFFACC15),
        secondary: Color(0xFFFDE047),
        scaffoldBg: Color(0xFF141208),
        cardBg: Color(0xFF221F0D),
        onSurface: Color(0xFFFEFCE8),
        onSurfaceVariant: Color(0xFFEAB308),
        fontFamily: 'Inter',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(
              color: Color(0x44FACC15),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
          cardBorder: BorderSide(color: Color(0x66FACC15), width: 1.5),
          cardRadius: 12.0,
          buttonRadius: 8.0,
          backdropBlur: 10.0,
          noiseOpacity: 0.03,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 300),
          animCurve: Curves.easeInOutCubic,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF10B981),
          warning: Color(0xFFFACC15),
          critical: Color(0xFFEF4444),
          info: Color(0xFF3B82F6),
          chart: [
            Color(0xFFFACC15),
            Color(0xFFFDE047),
            Color(0xFF10B981),
            Color(0xFF3B82F6),
          ],
        ),
      );
    }

    return const PresetVariant(
      brightness: Brightness.light,
      primary: Color(0xFFCA8A04),
      secondary: Color(0xFFEAB308),
      scaffoldBg: Color(0xFFFEFCE8),
      cardBg: Color(0xFFFEF9C3),
      onSurface: Color(0xFF422006),
      onSurfaceVariant: Color(0xFF854D0E),
      fontFamily: 'Inter',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(
            color: Color(0x22CA8A04),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
        cardBorder: BorderSide(color: Color(0x44CA8A04), width: 1.0),
        cardRadius: 12.0,
        buttonRadius: 8.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 300),
        animCurve: Curves.easeInOutCubic,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF059669),
        warning: Color(0xFFCA8A04),
        critical: Color(0xFFDC2626),
        info: Color(0xFF2563EB),
        chart: [
          Color(0xFFCA8A04),
          Color(0xFFEAB308),
          Color(0xFF059669),
          Color(0xFF2563EB),
        ],
      ),
    );
  }
}
