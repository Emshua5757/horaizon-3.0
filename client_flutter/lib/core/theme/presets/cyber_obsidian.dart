import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class CyberObsidianPreset implements AppThemePreset {
  @override String get id => 'cyber_obsidian';
  @override String get name => 'Cyber Obsidian';
  @override String get description => 'Cyberpunk Glassmorphism & Neon Cyan';
  @override IconData get icon => Icons.memory_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const PresetVariant(
        brightness: Brightness.dark,
        scaffoldBg: Color(0xFF090D14),
        cardBg: Color(0xFF122131),
        primary: Color(0xFF00E5FF),
        secondary: Color(0xFF00E5A0),
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        fontFamily: 'Outfit',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x4400E5FF), blurRadius: 16, spreadRadius: 1),
          ],
          cardBorder: BorderSide(color: Color(0x6600E5FF), width: 1.5),
          cardRadius: 12.0,
          buttonRadius: 12.0,
          backdropBlur: 16.0,
          noiseOpacity: 0.03,
          enableNeonGlow: true,
          useStatusHalo: true,
          animDuration: Duration(milliseconds: 200),
          animCurve: Curves.easeOutCubic,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF00E5A0),
          warning: Color(0xFFF59E0B),
          critical: Color(0xFFEF4444),
          info: Color(0xFF00E5FF),
          chart: [Color(0xFF00E5FF), Color(0xFF00E5A0), Color(0xFF9D4EDD), Color(0xFFFF6B6B)],
        ),
      );
    }

    // Light Cyber Slate Variant
    return const PresetVariant(
      brightness: Brightness.light,
      scaffoldBg: Color(0xFFF0F4F8),
      cardBg: Color(0xFFFFFFFF),
      primary: Color(0xFF00838F),
      secondary: Color(0xFF00897B),
      onSurface: Color(0xFF0F172A),
      onSurfaceVariant: Color(0xFF475569),
      fontFamily: 'Outfit',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x1F00838F), blurRadius: 10, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x3300838F), width: 1.0),
        cardRadius: 12.0,
        buttonRadius: 12.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.0,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 200),
        animCurve: Curves.easeOutCubic,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF00897B),
        warning: Color(0xFFD97706),
        critical: Color(0xFFDC2626),
        info: Color(0xFF00838F),
        chart: [Color(0xFF00838F), Color(0xFF00897B), Color(0xFF7C3AED), Color(0xFFE11D48)],
      ),
    );
  }
}
