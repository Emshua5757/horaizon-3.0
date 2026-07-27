import 'app_theme_preset.dart';
import 'presets/cyber_obsidian.dart';
import 'presets/creamy_latte.dart';
import 'presets/oled_pure_black.dart';
import 'presets/midnight_synthwave.dart';
import 'presets/matcha_zen.dart';
import 'presets/cyber_amber.dart';
import 'presets/vintage_parchment.dart';

/// Dynamic registry listing all available 7 multi-dimensional theme presets.
class ThemePresetRegistry {
  static final List<AppThemePreset> allPresets = [
    CyberObsidianPreset(),
    CreamyLattePreset(),
    OledPureBlackPreset(),
    MidnightSynthwavePreset(),
    MatchaZenPreset(),
    CyberAmberPreset(),
    VintageParchmentPreset(),
  ];

  static AppThemePreset getById(String id) {
    return allPresets.firstWhere(
      (p) => p.id == id,
      orElse: () => CyberObsidianPreset(),
    );
  }
}
