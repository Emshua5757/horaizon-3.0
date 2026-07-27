import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class VintageParchmentPreset implements AppThemePreset {
  @override String get id => 'vintage_parchment';
  @override String get name => 'Vintage Parchment';
  @override String get description => 'Classic Sepia Ink & Deckled Paper Aesthetics';
  @override IconData get icon => Icons.menu_book_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const PresetVariant(
        brightness: Brightness.light,
        scaffoldBg: Color(0xFFF4EFE6),
        cardBg: Color(0xFFEBE3D5),
        primary: Color(0xFF8B263E),
        secondary: Color(0xFF6B4226),
        onSurface: Color(0xFF2B251F),
        onSurfaceVariant: Color(0xFF5A4D41),
        fontFamily: 'Lora',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x1F2B251F), blurRadius: 10, offset: Offset(0, 3)),
          ],
          cardBorder: BorderSide(color: Color(0x558B6F57), width: 1.0),
          cardRadius: 10.0,
          buttonRadius: 10.0,
          backdropBlur: 0.0,
          noiseOpacity: 0.04,
          enableNeonGlow: false,
          useStatusHalo: false,
          animDuration: Duration(milliseconds: 250),
          animCurve: Curves.easeInOut,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF556B2F),
          warning: Color(0xFFB8860B),
          critical: Color(0xFF8B0000),
          info: Color(0xFF4A3B32),
          chart: [Color(0xFF8B263E), Color(0xFF6B4226), Color(0xFF556B2F), Color(0xFFB8860B)],
        ),
      );
    }

    // Dark Sepia Leather Variant
    return const PresetVariant(
      brightness: Brightness.dark,
      scaffoldBg: Color(0xFF1F1A15),
      cardBg: Color(0xFF2B241E),
      primary: Color(0xFFD48396),
      secondary: Color(0xFFC49A78),
      onSurface: Color(0xFFF4EFE6),
      onSurfaceVariant: Color(0xFFD5CBBF),
      fontFamily: 'Lora',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x44000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x44D48396), width: 1.0),
        cardRadius: 10.0,
        buttonRadius: 10.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.05,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 250),
        animCurve: Curves.easeInOut,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF8FA36A),
        warning: Color(0xFFE5B85C),
        critical: Color(0xFFC75555),
        info: Color(0xFFC49A78),
        chart: [Color(0xFFD48396), Color(0xFFC49A78), Color(0xFF8FA36A), Color(0xFFE5B85C)],
      ),
    );
  }
}
