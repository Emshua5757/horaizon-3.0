import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme_preset.dart';

enum SurfaceMode { cyberObsidian, oledPureBlack, midnightSpace, warmLight }

enum TypographyProfile { modernOutfit, cyberMono, editorialLora }

/// Pure mathematical compiler translating any AppThemePreset + Brightness variant
/// into a full Material 3 ThemeData object with distinct GoogleFonts per preset.
class ThemeCompiler {
  static ThemeData compile({
    required AppThemePreset preset,
    required Brightness brightness,
    Color? customPrimarySeed,
    Color? customSecondarySeed,
    double textScale = 1.0,
  }) {
    final variant = preset.getVariant(brightness);

    final primaryColor = customPrimarySeed ?? variant.primary;
    final secondaryColor = customSecondarySeed ?? variant.secondary;

    var scheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: brightness,
    );

    scheme = scheme.copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: variant.scaffoldBg,
      surfaceContainerLow: variant.cardBg,
      onSurface: variant.onSurface,
      onSurfaceVariant: variant.onSurfaceVariant,
      outlineVariant: variant.effects.cardBorder.color,
    );

    final textTheme = _buildTextTheme(variant.fontFamily, brightness, textScale);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: variant.scaffoldBg,
      textTheme: textTheme,
      extensions: [
        variant.effects,
        variant.semantic,
      ],
      cardTheme: CardThemeData(
        elevation: 0,
        color: variant.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(variant.effects.cardRadius),
          side: variant.effects.cardBorder,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: variant.scaffoldBg,
        foregroundColor: variant.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: brightness == Brightness.dark ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(variant.effects.buttonRadius),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: variant.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(variant.effects.buttonRadius),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: variant.cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(variant.effects.buttonRadius),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(variant.effects.buttonRadius),
          borderSide: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(variant.effects.buttonRadius),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(String fontFamily, Brightness brightness, double scale) {
    final base = brightness == Brightness.dark ? Typography.whiteMountainView : Typography.blackMountainView;

    TextTheme tt = base;
    try {
      tt = GoogleFonts.getTextTheme(fontFamily, base);
    } catch (_) {
      tt = base.apply(fontFamily: fontFamily);
    }

    if (scale == 1.0) return tt;

    return tt.copyWith(
      displayLarge: tt.displayLarge?.copyWith(fontSize: (tt.displayLarge?.fontSize ?? 57) * scale),
      displayMedium: tt.displayMedium?.copyWith(fontSize: (tt.displayMedium?.fontSize ?? 45) * scale),
      displaySmall: tt.displaySmall?.copyWith(fontSize: (tt.displaySmall?.fontSize ?? 36) * scale),
      headlineLarge: tt.headlineLarge?.copyWith(fontSize: (tt.headlineLarge?.fontSize ?? 32) * scale),
      headlineMedium: tt.headlineMedium?.copyWith(fontSize: (tt.headlineMedium?.fontSize ?? 28) * scale),
      headlineSmall: tt.headlineSmall?.copyWith(fontSize: (tt.headlineSmall?.fontSize ?? 24) * scale),
      titleLarge: tt.titleLarge?.copyWith(fontSize: (tt.titleLarge?.fontSize ?? 22) * scale),
      titleMedium: tt.titleMedium?.copyWith(fontSize: (tt.titleMedium?.fontSize ?? 16) * scale),
      titleSmall: tt.titleSmall?.copyWith(fontSize: (tt.titleSmall?.fontSize ?? 14) * scale),
      bodyLarge: tt.bodyLarge?.copyWith(fontSize: (tt.bodyLarge?.fontSize ?? 16) * scale),
      bodyMedium: tt.bodyMedium?.copyWith(fontSize: (tt.bodyMedium?.fontSize ?? 14) * scale),
      bodySmall: tt.bodySmall?.copyWith(fontSize: (tt.bodySmall?.fontSize ?? 12) * scale),
    );
  }
}
