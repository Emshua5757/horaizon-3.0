import 'app_theme_preset.dart';
import 'presets/cyber_obsidian.dart';
import 'presets/creamy_latte.dart';
import 'presets/oled_pure_black.dart';
import 'presets/midnight_synthwave.dart';
import 'presets/matcha_zen.dart';
import 'presets/cyber_amber.dart';
import 'presets/vintage_parchment.dart';
import 'presets/crimson_ruby.dart';
import 'presets/amethyst_dusk.dart';
import 'presets/solar_citrus.dart';

/// Dynamic registry listing all 10 Rainbow spectrum theme presets.
class ThemePresetRegistry {
  static final List<AppThemePreset> allPresets = [
    CyberObsidianPreset(),
    CreamyLattePreset(),
    OledPureBlackPreset(),
    MidnightSynthwavePreset(),
    MatchaZenPreset(),
    CyberAmberPreset(),
    VintageParchmentPreset(),
    CrimsonRubyPreset(),
    AmethystDuskPreset(),
    SolarCitrusPreset(),
  ];

  static AppThemePreset getById(String id) {
    return allPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => CyberObsidianPreset(),
    );
  }
}
