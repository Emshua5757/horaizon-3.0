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
  final bool enableHoverScaling;
  final double hoverScaleFactor;
  final int circadianDayStartHour;
  final int circadianNightStartHour;
  final double telemetryPollingSeconds;

  ThemeState({
    required this.presetId,
    this.brightnessMode = BrightnessMode.circadianAuto,
    this.customPrimary,
    this.customSecondary,
    this.animationMs = 300,
    this.textScale = 1.0,
    this.enableGlowBorders = true,
    this.enableHoverScaling = true,
    this.hoverScaleFactor = 1.008,
    this.circadianDayStartHour = 6,
    this.circadianNightStartHour = 18,
    this.telemetryPollingSeconds = 2.0,
  });

  AppThemePreset get preset => ThemePresetRegistry.getById(presetId);

  /// Resolves the current active Brightness based on BrightnessMode & solar time of day
  Brightness get activeBrightness {
    return switch (brightnessMode) {
      BrightnessMode.light => Brightness.light,
      BrightnessMode.dark => Brightness.dark,
      BrightnessMode.system => WidgetsBinding.instance.platformDispatcher.platformBrightness,
      BrightnessMode.circadianAuto => calculateCircadianBrightness(circadianDayStartHour, circadianNightStartHour),
    };
  }

  /// Calculates daytime (dayStart .. nightStart -> Light) vs nighttime (nightStart .. dayStart -> Dark)
  static Brightness calculateCircadianBrightness(int dayStart, int nightStart) {
    final hour = DateTime.now().hour;
    if (dayStart < nightStart) {
      return (hour >= dayStart && hour < nightStart) ? Brightness.light : Brightness.dark;
    } else {
      return (hour >= dayStart || hour < nightStart) ? Brightness.light : Brightness.dark;
    }
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
    bool? enableHoverScaling,
    double? hoverScaleFactor,
    int? circadianDayStartHour,
    int? circadianNightStartHour,
    double? telemetryPollingSeconds,
  }) {
    return ThemeState(
      presetId: presetId ?? this.presetId,
      brightnessMode: brightnessMode ?? this.brightnessMode,
      customPrimary: customPrimary ?? this.customPrimary,
      customSecondary: customSecondary ?? this.customSecondary,
      animationMs: animationMs ?? this.animationMs,
      textScale: textScale ?? this.textScale,
      enableGlowBorders: enableGlowBorders ?? this.enableGlowBorders,
      enableHoverScaling: enableHoverScaling ?? this.enableHoverScaling,
      hoverScaleFactor: hoverScaleFactor ?? this.hoverScaleFactor,
      circadianDayStartHour: circadianDayStartHour ?? this.circadianDayStartHour,
      circadianNightStartHour: circadianNightStartHour ?? this.circadianNightStartHour,
      telemetryPollingSeconds: telemetryPollingSeconds ?? this.telemetryPollingSeconds,
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
          enableHoverScaling: m['h_scale'] as bool? ?? true,
          hoverScaleFactor: (m['h_fac'] as num?)?.toDouble() ?? 1.008,
          circadianDayStartHour: m['c_day'] as int? ?? 6,
          circadianNightStartHour: m['c_night'] as int? ?? 18,
          telemetryPollingSeconds: (m['t_poll'] as num?)?.toDouble() ?? 2.0,
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
      'h_scale': state.enableHoverScaling,
      'h_fac': state.hoverScaleFactor,
      'c_day': state.circadianDayStartHour,
      'c_night': state.circadianNightStartHour,
      't_poll': state.telemetryPollingSeconds,
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

  void setCircadianHours({required int dayStart, required int nightStart}) {
    state = state.copyWith(
      circadianDayStartHour: dayStart,
      circadianNightStartHour: nightStart,
    );
    _saveToPrefs();
  }

  void setTelemetryPollingSeconds(double seconds) {
    state = state.copyWith(telemetryPollingSeconds: seconds);
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

  void toggleHoverScaling({required bool enabled}) {
    state = state.copyWith(enableHoverScaling: enabled);
    _saveToPrefs();
  }

  void setHoverScaleFactor(double factor) {
    state = state.copyWith(hoverScaleFactor: factor);
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
