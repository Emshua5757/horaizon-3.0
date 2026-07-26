import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_compiler.dart';

class ThemeState {
  final Brightness brightness;
  final Color primary;
  final Color? secondary;
  final SurfaceMode surfaceMode;
  final TypographyProfile typography;
  final int animationMs;
  final double textScale;
  final bool enableGlowBorders;
  final bool useSystemWallpaper;

  ThemeState({
    required this.brightness,
    required this.primary,
    this.secondary,
    this.surfaceMode = SurfaceMode.cyberObsidian,
    this.typography = TypographyProfile.modernOutfit,
    this.animationMs = 300,
    this.textScale = 1.0,
    this.enableGlowBorders = true,
    this.useSystemWallpaper = false,
  });

  /// Instantly compiles the mathematical seed + mode into a Flutter ThemeData.
  ThemeData get compiledData => ThemeCompiler.compile(
        brightness: brightness,
        primarySeed: primary,
        secondarySeed: secondary,
        surfaceMode: surfaceMode,
        typography: typography,
        textScale: textScale,
        enableGlowBorders: enableGlowBorders,
      );

  ThemeState copyWith({
    Brightness? brightness,
    Color? primary,
    Color? secondary,
    SurfaceMode? surfaceMode,
    TypographyProfile? typography,
    int? animationMs,
    double? textScale,
    bool? enableGlowBorders,
    bool? useSystemWallpaper,
  }) {
    return ThemeState(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      surfaceMode: surfaceMode ?? this.surfaceMode,
      typography: typography ?? this.typography,
      animationMs: animationMs ?? this.animationMs,
      textScale: textScale ?? this.textScale,
      enableGlowBorders: enableGlowBorders ?? this.enableGlowBorders,
      useSystemWallpaper: useSystemWallpaper ?? this.useSystemWallpaper,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  static const _prefKey = 'horaizon_theme_settings_v3';

  @override
  ThemeState build() {
    _loadFromPrefs();
    return ThemeState(
      brightness: Brightness.dark,
      primary: const Color(0xFF00E5FF),    // Cyber Blue default
      secondary: const Color(0xFF00E5A0),  // Cyber Emerald secondary
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null) {
        final m = jsonDecode(str) as Map<String, dynamic>;
        state = ThemeState(
          brightness:       m['b'] == 'light' ? Brightness.light : Brightness.dark,
          primary:          Color(m['p'] as int),
          secondary:        m['s'] != null ? Color(m['s'] as int) : null,
          surfaceMode:      SurfaceMode.values[m['sm'] as int? ?? 0],
          typography:       TypographyProfile.values[m['tp'] as int? ?? 0],
          animationMs:      m['anim'] as int? ?? 300,
          textScale:        (m['scale'] as num?)?.toDouble() ?? 1.0,
          enableGlowBorders: m['glow'] as bool? ?? true,
          useSystemWallpaper: m['wall'] as bool? ?? false,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'b':    state.brightness.name,
      'p':    state.primary.toARGB32(),
      's':    state.secondary?.toARGB32(),
      'sm':   state.surfaceMode.index,
      'tp':   state.typography.index,
      'anim': state.animationMs,
      'scale': state.textScale,
      'glow': state.enableGlowBorders,
      'wall': state.useSystemWallpaper,
    };
    await prefs.setString(_prefKey, jsonEncode(m));
  }

  void updatePrimary(Color c) {
    state = state.copyWith(primary: c);
    _saveToPrefs();
  }

  void updateSecondary(Color c) {
    state = state.copyWith(secondary: c);
    _saveToPrefs();
  }

  void setSurfaceMode(SurfaceMode mode) {
    state = state.copyWith(surfaceMode: mode);
    _saveToPrefs();
  }

  void setTypography(TypographyProfile tp) {
    state = state.copyWith(typography: tp);
    _saveToPrefs();
  }

  void toggleGlowBorders({required bool enabled}) {
    state = state.copyWith(enableGlowBorders: enabled);
    _saveToPrefs();
  }

  void toggleSystemWallpaper({required bool enabled}) {
    state = state.copyWith(useSystemWallpaper: enabled);
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
