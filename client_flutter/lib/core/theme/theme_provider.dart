import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme_preset.dart';
import 'theme_compiler.dart';
import 'theme_preset_registry.dart';

enum BrightnessMode { system, light, dark, circadianAuto }

class ThemeState {
  final String presetId;
  final BrightnessMode brightnessMode;
  final Color? customPrimary;
  final Color? customSecondary;
  final int animationMs;
  final double textScale;
  final bool enableGlowBorders;

  ThemeState({
    required this.presetId,
    this.brightnessMode = BrightnessMode.circadianAuto,
    this.customPrimary,
    this.customSecondary,
    this.animationMs = 300,
    this.textScale = 1.0,
    this.enableGlowBorders = true,
  });

  AppThemePreset get preset => ThemePresetRegistry.getById(presetId);

  /// Resolves the current active Brightness based on BrightnessMode & solar time of day
  Brightness get activeBrightness {
    return switch (brightnessMode) {
      BrightnessMode.light => Brightness.light,
      BrightnessMode.dark => Brightness.dark,
      BrightnessMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
      BrightnessMode.circadianAuto => _calculateCircadianBrightness(),
    };
  }

  /// Calculates daytime (06:00 - 18:00 -> Light) vs nighttime (18:00 - 06:00 -> Dark)
  static Brightness _calculateCircadianBrightness() {
    final hour = DateTime.now().hour;
    return (hour >= 6 && hour < 18) ? Brightness.light : Brightness.dark;
  }

  /// Instantly compiles the preset + active brightness into a Flutter ThemeData.
  ThemeData get compiledData => ThemeCompiler.compile(
        preset: preset,
        brightness: activeBrightness,
        customPrimarySeed: customPrimary,
        customSecondarySeed: customSecondary,
        textScale: textScale,
      );

  ThemeState copyWith({
    String? presetId,
    BrightnessMode? brightnessMode,
    Color? customPrimary,
    Color? customSecondary,
    int? animationMs,
    double? textScale,
    bool? enableGlowBorders,
  }) {
    return ThemeState(
      presetId: presetId ?? this.presetId,
      brightnessMode: brightnessMode ?? this.brightnessMode,
      customPrimary: customPrimary ?? this.customPrimary,
      customSecondary: customSecondary ?? this.customSecondary,
      animationMs: animationMs ?? this.animationMs,
      textScale: textScale ?? this.textScale,
      enableGlowBorders: enableGlowBorders ?? this.enableGlowBorders,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _prefKey = 'horaizon_theme_settings_v4';
  Timer? _circadianTimer;

  @override
  ThemeState build() {
    _loadFromPrefs();
    _startCircadianTicker();
    ref.onDispose(() => _circadianTimer?.cancel());
    return ThemeState(
      presetId: 'cyber_obsidian',
      brightnessMode: BrightnessMode.circadianAuto,
    );
  }

  void _startCircadianTicker() {
    _circadianTimer?.cancel();
    // Check every minute if circadian brightness state needs to transition
    _circadianTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (state.brightnessMode == BrightnessMode.circadianAuto) {
        // Trigger state rebuild if circadian brightness changes
        state = state.copyWith();
      }
    });
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null) {
        final m = jsonDecode(str) as Map<String, dynamic>;
        state = ThemeState(
          presetId: m['p_id'] as String? ?? 'cyber_obsidian',
          brightnessMode: BrightnessMode.values[m['bm'] as int? ?? 3],
          customPrimary: m['cp'] != null ? Color(m['cp'] as int) : null,
          customSecondary: m['cs'] != null ? Color(m['cs'] as int) : null,
          animationMs: m['anim'] as int? ?? 300,
          textScale: (m['scale'] as num?)?.toDouble() ?? 1.0,
          enableGlowBorders: m['glow'] as bool? ?? true,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'p_id': state.presetId,
      'bm': state.brightnessMode.index,
      'cp': state.customPrimary?.toARGB32(),
      'cs': state.customSecondary?.toARGB32(),
      'anim': state.animationMs,
      'scale': state.textScale,
      'glow': state.enableGlowBorders,
    };
    await prefs.setString(_prefKey, jsonEncode(m));
  }

  void selectPreset(String id) {
    state = state.copyWith(presetId: id);
    _saveToPrefs();
  }

  void setBrightnessMode(BrightnessMode mode) {
    state = state.copyWith(brightnessMode: mode);
    _saveToPrefs();
  }

  void updatePrimary(Color? c) {
    state = state.copyWith(customPrimary: c);
    _saveToPrefs();
  }

  void updateSecondary(Color? c) {
    state = state.copyWith(customSecondary: c);
    _saveToPrefs();
  }

  void toggleGlowBorders({required bool enabled}) {
    state = state.copyWith(enableGlowBorders: enabled);
    _saveToPrefs();
  }

  void setAnimationMs(int ms) {
    state = state.copyWith(animationMs: ms);
    _saveToPrefs();
  }

  void setTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    _saveToPrefs();
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
