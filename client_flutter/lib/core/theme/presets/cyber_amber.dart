import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class CyberAmberPreset implements AppThemePreset {
  @override String get id => 'cyber_amber';
  @override String get name => 'Cyber Amber';
  @override String get description => 'Deus Ex Industrial Slate & Amber Gold';
  @override IconData get icon => Icons.workspace_premium_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        scaffoldBg: Color(0xFF121110),
        cardBg: Color(0xFF1E1A16),
        primary: Color(0xFFF59E0B),
        secondary: Color(0xFFD97706),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFFDE68A),
        fontFamily: 'JetBrains Mono',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x55F59E0B), blurRadius: 16, spreadRadius: 1),
          ],
          cardBorder: BorderSide(color: Color(0x77F59E0B), width: 1.5),
          cardRadius: 8.0,
          buttonRadius: 8.0,
          backdropBlur: 14.0,
          noiseOpacity: 0.03,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 180),
          animCurve: Curves.easeOutQuad,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF10B981),
          warning: Color(0xFFF59E0B),
          critical: Color(0xFFEF4444),
          info: Color(0xFFD97706),
          chart: [Color(0xFFF59E0B), Color(0xFFD97706), Color(0xFF10B981), Color(0xFFEF4444)],
        ),
      );
    }

    // Amber Sand Light Variant
    return const PresetVariant(
      brightness: Brightness.light,
      scaffoldBg: Color(0xFFFFFBEB),
      cardBg: Color(0xFFFEF3C7),
      primary: Color(0xFFB45309),
      secondary: Color(0xFF92400E),
      onSurface: Color(0xFF451A03),
      onSurfaceVariant: Color(0xFF78350F),
      fontFamily: 'JetBrains Mono',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x1FB45309), blurRadius: 10, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x33B45309), width: 1.0),
        cardRadius: 8.0,
        buttonRadius: 8.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 180),
        animCurve: Curves.easeOutQuad,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF047857),
        warning: Color(0xFFB45309),
        critical: Color(0xFFB91C1C),
        info: Color(0xFF92400E),
        chart: [Color(0xFFB45309), Color(0xFF92400E), Color(0xFF047857), Color(0xFFB91C1C)],
      ),
    );
  }
}
