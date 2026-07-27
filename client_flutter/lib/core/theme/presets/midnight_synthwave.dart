import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class MidnightSynthwavePreset implements AppThemePreset {
  @override String get id => 'midnight_synthwave';
  @override String get name => 'Midnight Synthwave';
  @override String get description => 'Deep Space Nebula & Pulsing Synth Pink';
  @override IconData get icon => Icons.auto_awesome_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        scaffoldBg: Color(0xFF0A0A16),
        cardBg: Color(0xFF1A162B),
        primary: Color(0xFFA855F7),
        secondary: Color(0xFFEC4899),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFD8B4FE),
        fontFamily: 'Outfit',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x66A855F7), blurRadius: 20, spreadRadius: 1),
          ],
          cardBorder: BorderSide(color: Color(0x77A855F7), width: 1.5),
          cardRadius: 16.0,
          buttonRadius: 16.0,
          backdropBlur: 20.0,
          noiseOpacity: 0.04,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 250),
          animCurve: Curves.easeOutBack,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF34D399),
          warning: Color(0xFFFBBF24),
          critical: Color(0xFFF43F5E),
          info: Color(0xFF38BDF8),
          chart: [Color(0xFFA855F7), Color(0xFFEC4899), Color(0xFF38BDF8), Color(0xFF34D399)],
        ),
      );
    }

    // Solar Flare Light Variant
    return const PresetVariant(
      brightness: Brightness.light,
      scaffoldBg: Color(0xFFFAF5FF),
      cardBg: Color(0xFFFFFFFF),
      primary: Color(0xFF9333EA),
      secondary: Color(0xFFDB2777),
      onSurface: Color(0xFF3B0764),
      onSurfaceVariant: Color(0xFF6B21A8),
      fontFamily: 'Outfit',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x229333EA), blurRadius: 12, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x339333EA), width: 1.0),
        cardRadius: 16.0,
        buttonRadius: 16.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 250),
        animCurve: Curves.easeOutBack,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        critical: Color(0xFFE11D48),
        info: Color(0xFF0284C7),
        chart: [Color(0xFF9333EA), Color(0xFFDB2777), Color(0xFF0284C7), Color(0xFF059669)],
      ),
    );
  }
}
