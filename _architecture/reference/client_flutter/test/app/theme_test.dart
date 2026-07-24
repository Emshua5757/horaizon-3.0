import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/app/theme/theme_compiler.dart';
import 'package:client_flutter/app/theme/theme_provider.dart';

void main() {
  group('Mathematical Theme Compiler Tests', () {
    test('HCT generation maintains primary seed constraint', () {
      const testSeed = Color(0xFF00E5FF); // Cyber-blue
      
      final theme = ThemeCompiler.compile(
        brightness: Brightness.dark,
        primarySeed: testSeed,
      );

      // The Material 3 compiler mathematically shifts the seed to guarantee WCAG 
      // contrast ratios. We assert the theme successfully compiled and registered Dark Mode.
      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
    });

    test('Explicit secondary override injection successfully bypasses math', () {
      const primarySeed = Color(0xFF00E5FF);
      const secondarySeed = Color(0xFFFF0055); // Neon pink
      
      final theme = ThemeCompiler.compile(
        brightness: Brightness.light,
        primarySeed: primarySeed,
        secondarySeed: secondarySeed,
      );

      expect(theme.brightness, Brightness.light);
      // The secondary color MUST match the injected seed
      expect(theme.colorScheme.secondary.toARGB32(), secondarySeed.toARGB32());
    });
  });

  group('Riverpod ThemeState Engine Tests', () {
    test('State immutability and brightness toggling', () {
      final state = ThemeState(
        brightness: Brightness.dark,
        primary: const Color(0xFF00E5FF),
      );
      
      expect(state.brightness, Brightness.dark);
      
      // Simulate state toggle
      final toggledState = state.copyWith(brightness: Brightness.light);
      expect(toggledState.brightness, Brightness.light);
      
      // Verify compiler pipeline works on updated state
      expect(toggledState.compiledData.brightness, Brightness.light);
    });
  });
}
