import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/core/theme/theme_compiler.dart';

void main() {
  group('ThemeCompiler', () {
    test('Compiles primary seed color into valid ThemeData ColorScheme', () {
      const primarySeed = Color(0xFF00E5FF);
      final theme = ThemeCompiler.compile(
        brightness: Brightness.dark,
        primarySeed: primarySeed,
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
    });

    test('Applies explicit surface modes cleanly', () {
      final obsidian = ThemeCompiler.compile(
        brightness: Brightness.dark,
        primarySeed: const Color(0xFF00E5FF),
        surfaceMode: SurfaceMode.cyberObsidian,
      );
      expect(obsidian.scaffoldBackgroundColor, equals(const Color(0xFF0D0D12)));

      final oled = ThemeCompiler.compile(
        brightness: Brightness.dark,
        primarySeed: const Color(0xFF00E5FF),
        surfaceMode: SurfaceMode.oledPureBlack,
      );
      expect(oled.scaffoldBackgroundColor, equals(Colors.black));
    });

    test('Grafts explicit secondary seed when provided', () {
      const primary = Color(0xFF00E5FF);
      const secondary = Color(0xFF00E5A0);
      final theme = ThemeCompiler.compile(
        brightness: Brightness.dark,
        primarySeed: primary,
        secondarySeed: secondary,
      );

      expect(theme.colorScheme.secondary, equals(secondary));
    });
  });
}
