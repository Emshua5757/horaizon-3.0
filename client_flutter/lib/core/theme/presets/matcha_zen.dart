import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class MatchaZenPreset implements AppThemePreset {
  @override String get id => 'matcha_zen';
  @override String get name => 'Matcha Zen';
  @override String get description => 'Deep Forest Pine & Fresh Bio-Tech Green';
  @override IconData get icon => Icons.eco_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        scaffoldBg: Color(0xFF0A1410),
        cardBg: Color(0xFF12241C),
        primary: Color(0xFF4ADE80),
        secondary: Color(0xFF14B8A6),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFA7F3D0),
        fontFamily: 'Outfit',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x444ADE80), blurRadius: 14, spreadRadius: 1),
          ],
          cardBorder: BorderSide(color: Color(0x554ADE80), width: 1.5),
          cardRadius: 16.0,
          buttonRadius: 16.0,
          backdropBlur: 12.0,
          noiseOpacity: 0.02,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 300),
          animCurve: Curves.easeInOut,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF4ADE80),
          warning: Color(0xFFFACC15),
          critical: Color(0xFFF87171),
          info: Color(0xFF14B8A6),
          chart: [Color(0xFF4ADE80), Color(0xFF14B8A6), Color(0xFF38BDF8), Color(0xFFFACC15)],
        ),
      );
    }

    // Light Matcha Tea Variant
    return const PresetVariant(
      brightness: Brightness.light,
      scaffoldBg: Color(0xFFF0FDF4),
      cardBg: Color(0xFFDCFCE7),
      primary: Color(0xFF166534),
      secondary: Color(0xFF0F766E),
      onSurface: Color(0xFF064E3B),
      onSurfaceVariant: Color(0xFF14532D),
      fontFamily: 'Outfit',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x1F166534), blurRadius: 10, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x33166534), width: 1.0),
        cardRadius: 16.0,
        buttonRadius: 16.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 300),
        animCurve: Curves.easeInOut,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF15803D),
        warning: Color(0xFFB45309),
        critical: Color(0xFFB91C1C),
        info: Color(0xFF0F766E),
        chart: [Color(0xFF166534), Color(0xFF0F766E), Color(0xFF0369A1), Color(0xFFB45309)],
      ),
    );
  }
}
