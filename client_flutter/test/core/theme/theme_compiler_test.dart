import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/core/theme/theme_compiler.dart';
import 'package:client_flutter/core/theme/theme_preset_registry.dart';
import 'package:client_flutter/core/theme/presets/cyber_obsidian.dart';
import 'package:client_flutter/core/theme/presets/creamy_latte.dart';
import 'package:client_flutter/core/theme/presets/oled_pure_black.dart';
import 'package:client_flutter/core/theme/app_effects_theme.dart';
import 'package:client_flutter/core/theme/app_semantic_palette.dart';

void main() {
  group('ThemeCompiler & Modular Presets', () {
    test('Compiles CyberObsidian preset into valid ThemeData and extensions', () {
      final preset = CyberObsidianPreset();
      final theme = ThemeCompiler.compile(
        preset: preset,
        brightness: Brightness.dark,
      );

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, equals(Brightness.dark));
      expect(theme.extension<AppEffectsTheme>(), isNotNull);
      expect(theme.extension<AppSemanticPalette>(), isNotNull);
    });

    test('Applies explicit preset scaffold background colors cleanly', () {
      final obsidian = ThemeCompiler.compile(
        preset: CyberObsidianPreset(),
        brightness: Brightness.dark,
      );
      expect(obsidian.scaffoldBackgroundColor, equals(const Color(0xFF090D14)));

      final oled = ThemeCompiler.compile(
        preset: OledPureBlackPreset(),
        brightness: Brightness.dark,
      );
      expect(oled.scaffoldBackgroundColor, equals(Colors.black));

      final creamy = ThemeCompiler.compile(
        preset: CreamyLattePreset(),
        brightness: Brightness.light,
      );
      expect(creamy.scaffoldBackgroundColor, equals(const Color(0xFFFBF8F3)));
    });

    test('Registry contains all 7 theme presets', () {
      expect(ThemePresetRegistry.allPresets.length, equals(7));
      final found = ThemePresetRegistry.getById('creamy_latte');
      expect(found.name, equals('Creamy Latte'));
    });
  });
}
