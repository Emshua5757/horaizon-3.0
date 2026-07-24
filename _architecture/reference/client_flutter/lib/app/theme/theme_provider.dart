import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';
import 'theme_compiler.dart';
import 'package:client_flutter/app/diagnostics/diagnostic_result.dart';
import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';
import 'package:client_flutter/app/diagnostics/diagnostics_provider.dart';

class ThemeState {
  final Brightness brightness;
  final Color primary;
  final Color? secondary;
  final int animationMs;
  final double textScale;

  ThemeState({
    required this.brightness,
    required this.primary,
    this.secondary,
    this.animationMs = 300,
    this.textScale = 1.0,
  });

  /// Instantly compiles the math into a Flutter ThemeData object.
  ThemeData get compiledData => ThemeCompiler.compile(
        brightness: brightness,
        primarySeed: primary,
        secondarySeed: secondary,
        textScale: textScale,
      );

  ThemeState copyWith({
    Brightness? brightness,
    Color? primary,
    Color? secondary,
    int? animationMs,
    double? textScale,
  }) {
    return ThemeState(
      brightness: brightness ?? this.brightness,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      animationMs: animationMs ?? this.animationMs,
      textScale: textScale ?? this.textScale,
    );
  }
}

class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    _loadSettings();
    return ThemeState(
      brightness: Brightness.dark,
      primary: const Color(0xFF00E5FF), // Cyber-blue default
    );
  }

  Future<void> _loadSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'theme_settings.json'));
      if (await file.exists()) {
        final data = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final brightness = data['brightness'] == 'light' ? Brightness.light : Brightness.dark;
        final primary = Color(data['primary'] as int);
        final secondary = data['secondary'] != null ? Color(data['secondary'] as int) : null;
        final animationMs = data['animationMs'] as int? ?? 300;
        final textScale = (data['textScale'] as num?)?.toDouble() ?? 1.0;

        state = ThemeState(
          brightness: brightness,
          primary: primary,
          secondary: secondary,
          animationMs: animationMs,
          textScale: textScale,
        );
      }
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'theme_provider', 'Failed to load settings: $e', tags: HbpLogTag.SYSTEM);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'theme_settings.json'));
      final data = {
        'brightness': state.brightness == Brightness.light ? 'light' : 'dark',
        'primary': state.primary.toARGB32(),
        'secondary': state.secondary?.toARGB32(),
        'animationMs': state.animationMs,
        'textScale': state.textScale,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'theme_provider', 'Failed to save settings: $e', tags: HbpLogTag.SYSTEM);
    }
  }

  void toggleBrightness() {
    state = state.copyWith(
      brightness: state.brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
    _saveSettings();
    _logThemeChange('Brightness toggled to ${state.brightness.name}');
  }

  void updatePrimary(Color newColor) {
    state = state.copyWith(primary: newColor);
    _saveSettings();
    _logThemeChange('Primary color updated');
  }

  void updateSecondary(Color newColor) {
    state = state.copyWith(secondary: newColor);
    _saveSettings();
    _logThemeChange('Secondary color updated');
  }

  void updateAnimationMs(int ms) {
    state = state.copyWith(animationMs: ms);
    _saveSettings();
    _logThemeChange('Animation speed updated to ${ms}ms');
  }

  void updateTextScale(double scale) {
    state = state.copyWith(textScale: scale);
    _saveSettings();
    _logThemeChange('Text scale updated to $scale');
  }

  void _logThemeChange(String detail) {
    ref.read(diagnosticsHistoryProvider.notifier).logResult(
      DiagnosticResult.success(
        detail,
        diagnostic: SystemEvents.themeUpdated,
      ),
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeState>(() {
  return ThemeNotifier();
});
