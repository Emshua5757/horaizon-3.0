import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum SurfaceMode { cyberObsidian, oledPureBlack, midnightSpace, warmLight }

enum TypographyProfile { modernOutfit, cyberMono, editorialLora }

/// Pure mathematical compiler translating primary/secondary seeds and surface modes
/// into a full Material 3 ThemeData object with glowing borders and glassmorphism.
///
/// Time Complexity: O(1) — pure mathematical color transformation.
/// Space Complexity: O(1) — no allocations beyond ThemeData.
class ThemeCompiler {
  static ThemeData compile({
    required Brightness brightness,
    required Color primarySeed,
    Color? secondarySeed,
    SurfaceMode surfaceMode = SurfaceMode.cyberObsidian,
    TypographyProfile typography = TypographyProfile.modernOutfit,
    double textScale = 1.0,
    bool enableGlowBorders = true,
  }) {
    // 1. Primary HCT scheme generation
    var scheme = ColorScheme.fromSeed(
      seedColor: primarySeed,
      brightness: brightness,
    );

    // 2. Graft explicit secondary seed if specified to bypass HCT shifting
    if (secondarySeed != null) {
      final secScheme = ColorScheme.fromSeed(
        seedColor: secondarySeed,
        brightness: brightness,
      );
      scheme = scheme.copyWith(
        secondary: secondarySeed,
        onSecondary: secScheme.onPrimary,
        secondaryContainer: secScheme.primaryContainer,
        onSecondaryContainer: secScheme.onPrimaryContainer,
      );
    }

    // 3. Customize scaffold & canvas based on SurfaceMode
    final scaffoldBg = switch (surfaceMode) {
      SurfaceMode.cyberObsidian => const Color(0xFF0D0D12),
      SurfaceMode.oledPureBlack => Colors.black,
      SurfaceMode.midnightSpace => const Color(0xFF121826),
      SurfaceMode.warmLight     => const Color(0xFFF7F5F0),
    };

    scheme = scheme.copyWith(
      surface: scaffoldBg,
      onSurface: brightness == Brightness.dark ? Colors.white : Colors.black87,
    );

    // 4. Typography profile selection
    final textTheme = _buildTextTheme(typography, brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow.withValues(alpha: 0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: enableGlowBorders
                ? primarySeed.withValues(alpha: 0.35)
                : scheme.outlineVariant.withValues(alpha: 0.3),
            width: enableGlowBorders ? 1.5 : 1.0,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: scaffoldBg,
        selectedIconTheme: IconThemeData(color: primarySeed),
        selectedLabelTextStyle: TextStyle(
          color: primarySeed,
          fontWeight: FontWeight.bold,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }

  static TextTheme _buildTextTheme(TypographyProfile profile, Brightness brightness) {
    final base = brightness == Brightness.dark ? ThemeData.dark().textTheme : ThemeData.light().textTheme;
    final family = switch (profile) {
      TypographyProfile.modernOutfit   => 'Outfit',
      TypographyProfile.cyberMono     => 'JetBrainsMono',
      TypographyProfile.editorialLora => 'Lora',
    };
    return base.apply(fontFamily: family);
  }
}
