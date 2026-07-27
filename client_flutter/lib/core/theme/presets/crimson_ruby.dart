import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

/// Preset 8: Crimson Ruby
/// High-Tech Crimson Red & Warm Garnet Glassmorphism covering the Red spectrum.
class CrimsonRubyPreset implements AppThemePreset {
  @override String get id => 'crimson_ruby';
  @override String get name => 'Crimson Ruby';
  @override String get description => 'High-Tech Crimson Red & Garnet Glassmorphism';
  @override IconData get icon => Icons.whatshot_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        primary: Color(0xFFFF2A55),
        secondary: Color(0xFFFF5277),
        scaffoldBg: Color(0xFF14080B),
        cardBg: Color(0xFF220D12),
        onSurface: Color(0xFFFDE8EC),
        onSurfaceVariant: Color(0xFFF4A2B2),
        fontFamily: 'Inter',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(
              color: Color(0x44FF2A55),
              blurRadius: 18,
              spreadRadius: 0,
            ),
          ],
          cardBorder: BorderSide(color: Color(0x66FF2A55), width: 1.5),
          cardRadius: 14.0,
          buttonRadius: 10.0,
          backdropBlur: 14.0,
          noiseOpacity: 0.04,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 300),
          animCurve: Curves.easeInOutCubic,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF10B981),
          warning: Color(0xFFF59E0B),
          critical: Color(0xFFFF2A55),
          info: Color(0xFF3B82F6),
          chart: [
            Color(0xFFFF2A55),
            Color(0xFFFF708F),
            Color(0xFF10B981),
            Color(0xFF3B82F6),
          ],
        ),
      );
    }

    return const PresetVariant(
      brightness: Brightness.light,
      primary: Color(0xFFD91438),
      secondary: Color(0xFFE13052),
      scaffoldBg: Color(0xFFFFF5F6),
      cardBg: Color(0xFFFFEBF0),
      onSurface: Color(0xFF3A060E),
      onSurfaceVariant: Color(0xFF8A3040),
      fontFamily: 'Inter',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(
            color: Color(0x22D91438),
            blurRadius: 12,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
        cardBorder: BorderSide(color: Color(0x44D91438), width: 1.0),
        cardRadius: 14.0,
        buttonRadius: 10.0,
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
        critical: Color(0xFFD91438),
        info: Color(0xFF2563EB),
        chart: [
          Color(0xFFD91438),
          Color(0xFFE13052),
          Color(0xFF059669),
          Color(0xFF2563EB),
        ],
      ),
    );
  }
}
