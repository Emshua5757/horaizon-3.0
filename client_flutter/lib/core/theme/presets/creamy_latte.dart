import 'package:flutter/material.dart';
import '../app_effects_theme.dart';
import '../app_semantic_palette.dart';
import '../app_theme_preset.dart';

class CreamyLattePreset implements AppThemePreset {
  @override String get id => 'creamy_latte';
  @override String get name => 'Creamy Latte';
  @override String get description => 'Warm Ceramic & Espresso Tactile Feel';
  @override IconData get icon => Icons.coffee_rounded;
  @override bool get supportsCircadianShift => true;

  @override
  PresetVariant getVariant(Brightness brightness) {
    if (brightness == Brightness.light) {
      return const PresetVariant(
        brightness: Brightness.light,
        scaffoldBg: Color(0xFFFBF8F3),
        cardBg: Color(0xFFF3ECE3),
        primary: Color(0xFF7C5C43),
        secondary: Color(0xFFD97706),
        onSurface: Color(0xFF2D2422),
        onSurfaceVariant: Color(0xFF665753),
        fontFamily: 'Lora',
        effects: AppEffectsTheme(
          cardShadow: [
            BoxShadow(color: Color(0x1F4A3E3D), blurRadius: 14, offset: Offset(0, 4)),
          ],
          cardBorder: BorderSide(color: Color(0x40C4B2A0), width: 1.0),
          cardRadius: 20.0,
          buttonRadius: 14.0,
          backdropBlur: 0.0,
          noiseOpacity: 0.02,
          enableNeonGlow: false,
          useStatusHalo: false,
          animDuration: Duration(milliseconds: 350),
          animCurve: Curves.easeInOutSine,
        ),
        semantic: AppSemanticPalette(
          success: Color(0xFF3D7A5A),
          warning: Color(0xFFC86D3B),
          critical: Color(0xFFA83232),
          info: Color(0xFF5D4037),
          chart: [Color(0xFF7C5C43), Color(0xFFD97706), Color(0xFF3D7A5A), Color(0xFFC86D3B)],
        ),
      );
    }

    // Dark Roasted Mocha Variant
    return const PresetVariant(
      brightness: Brightness.dark,
      scaffoldBg: Color(0xFF1E1714),
      cardBg: Color(0xFF2A211D),
      primary: Color(0xFFD4A373),
      secondary: Color(0xFFFAEDCD),
      onSurface: Color(0xFFFAEDCD),
      onSurfaceVariant: Color(0xFFCCD5AE),
      fontFamily: 'Lora',
      effects: AppEffectsTheme(
        cardShadow: [
          BoxShadow(color: Color(0x3D000000), blurRadius: 14, offset: Offset(0, 4)),
        ],
        cardBorder: BorderSide(color: Color(0x33D4A373), width: 1.0),
        cardRadius: 20.0,
        buttonRadius: 14.0,
        backdropBlur: 0.0,
        noiseOpacity: 0.03,
        enableNeonGlow: false,
        useStatusHalo: false,
        animDuration: Duration(milliseconds: 350),
        animCurve: Curves.easeInOutSine,
      ),
      semantic: AppSemanticPalette(
        success: Color(0xFF81B29A),
        warning: Color(0xFFF2CC8F),
        critical: Color(0xFFE07A5F),
        info: Color(0xFFD4A373),
        chart: [Color(0xFFD4A373), Color(0xFFF2CC8F), Color(0xFF81B29A), Color(0xFFE07A5F)],
      ),
    );
  }
}
