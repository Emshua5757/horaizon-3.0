import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

/// Preset 9: Amethyst Dusk
/// Velvet Violet & Astral Indigo Nebula covering the Purple spectrum.
class AmethystDuskPreset implements AppThemePreset {
  @override String get id => 'amethyst_dusk';
  @override String get name => 'Amethyst Dusk';
  @override String get description => 'Velvet Violet & Astral Indigo Nebula';
  @override IconData get icon => Icons.auto_awesome_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        primary: Color(0xFFA855F7),
        secondary: Color(0xFFC084FC),
        scaffoldBg: Color(0xFF0F0916),
        cardBg: Color(0xFF1B0E2A),
        onSurface: Color(0xFFF3E8FF),
        onSurfaceVariant: Color(0xFFC4B5FD),
        fontFamily: 'Inter',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(
              color: Color(0x44A855F7),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
          cardBorder: BorderSide(color: Color(0x66A855F7), width: 1.5),
          cardRadius: 16.0,
          buttonRadius: 12.0,
          backdropBlur: 16.0,
          noiseOpacity: 0.04,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 300),
          animCurve: Curves.easeInOutCubic,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF34D399),
          warning: Color(0xFFFBBF24),
          critical: Color(0xFFF87171),
          info: Color(0xFFA855F7),
          chart: [
            Color(0xFFA855F7),
            Color(0xFFC084FC),
            Color(0xFF34D399),
            Color(0xFF60A5FA),
          ],
        ),
      );
    }

    return const PresetVariant(
      brightness: Brightness.light,
      primary: Color(0xFF7E22CE),
      secondary: Color(0xFF9333EA),
      scaffoldBg: Color(0xFFFAF5FF),
      cardBg: Color(0xFFF3E8FF),
      onSurface: Color(0xFF2E1065),
      onSurfaceVariant: Color(0xFF6B21A8),
      fontFamily: 'Inter',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(
            color: Color(0x227E22CE),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
        cardBorder: BorderSide(color: Color(0x447E22CE), width: 1.0),
        cardRadius: 16.0,
        buttonRadius: 12.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 300),
        animCurve: Curves.easeInOutCubic,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF059669),
        warning: Color(0xFFD97706),
        critical: Color(0xFFDC2626),
        info: Color(0xFF7E22CE),
        chart: [
          Color(0xFF7E22CE),
          Color(0xFF9333EA),
          Color(0xFF059669),
          Color(0xFF2563EB),
        ],
      ),
    );
  }
}
