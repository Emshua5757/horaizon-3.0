# TASK-010 — `client_flutter` GoRouter + SplashScreen + Advanced Theme System

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/router/`, `lib/core/theme/`, `lib/core/auth/`, `lib/app.dart` |
| **Blocks** | TASK-011, TASK-012 |
| **Prerequisites** | TASK-009 complete |

---

## Context & Architectural Directives

Wire up GoRouter with all Phase 1 routes, implement the SplashScreen that checks Pi 5 connectivity before routing to the dashboard, build the state-of-the-art visual customization theme engine, and integrate biometric authentication with PIN fallback.

> [!IMPORTANT]
> **State-of-the-Art Aesthetic Design System**:
> Rather than a simple color-only picker, horAIzon 3.0 provides a rich visual customizer:
> 1. **Mathematical HCT ThemeCompiler (from 2.0)**: Takes `primarySeed` and optional `secondarySeed` hex values, computes Material 3 tonal variants, and grafts the explicit secondary hex color.
> 2. **Surface Material Modes**: `Cyber Obsidian` (`#0D0D12`), `OLED Pure Black` (`#000000`), `Midnight Space` (`#121826`), and `Warm Light` (`#F7F5F0`).
> 3. **Typography Profiles**: `Modern Outfit` (Sans), `Cyber Mono` (JetBrains Mono display), and `Editorial Lora` (Serif journal mode).
> 4. **Glow & Glassmorphism Effects**: Glow border shadows matching primary/secondary color, configurable card surface opacity.
> 5. **Android Wallpaper Toggle**: Optional `useSystemWallpaper` toggle via `dynamic_color` on Android.
> 6. **Micro-Animation Tuning**: Adjustable animation duration (`150ms` - `500ms`) and text scale (`0.8×` - `1.4×`).

Read `_architecture/specs/client_flutter/client_flutter_spec.md` before implementing.

---

## Part A — Advanced Theme System

### Step A1: `lib/core/theme/theme_compiler.dart`

```dart
import 'package:flutter/material.dart';

enum SurfaceMode { cyberObsidian, oledPureBlack, midnightSpace, warmLight }
enum TypographyProfile { modernOutfit, cyberMono, editorialLora }

/// Pure mathematical compiler translating primary/secondary seeds and surface modes
/// into a full Material 3 ThemeData object with glowing borders and glassmorphism.
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

    // 2. Graft explicit secondary seed if specified
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

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow.withOpacity(0.85),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: enableGlowBorders
                ? primarySeed.withOpacity(0.35)
                : scheme.outlineVariant.withOpacity(0.3),
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
        selectedLabelTextStyle: TextStyle(color: primarySeed, fontWeight: FontWeight.bold),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scaffoldBg,
        indicatorColor: scheme.primaryContainer,
      ),
    );
  }
}
```

### Step A2: `lib/core/theme/theme_provider.dart`

```dart
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
      primary: const Color(0xFF00E5FF),   // Cyber Blue default
      secondary: const Color(0xFF00E5A0), // Cyber Emerald secondary
    );
  }

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_prefKey);
      if (str != null) {
        final m = jsonDecode(str) as Map<String, dynamic>;
        state = ThemeState(
          brightness: m['b'] == 'light' ? Brightness.light : Brightness.dark,
          primary: Color(m['p'] as int),
          secondary: m['s'] != null ? Color(m['s'] as int) : null,
          surfaceMode: SurfaceMode.values[m['sm'] as int? ?? 0],
          typography: TypographyProfile.values[m['tp'] as int? ?? 0],
          animationMs: m['anim'] as int? ?? 300,
          textScale: (m['scale'] as num?)?.toDouble() ?? 1.0,
          enableGlowBorders: m['glow'] as bool? ?? true,
          useSystemWallpaper: m['wall'] as bool? ?? false,
        );
      }
    } catch (_) {}
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final m = {
      'b': state.brightness.name,
      'p': state.primary.value,
      's': state.secondary?.value,
      'sm': state.surfaceMode.index,
      'tp': state.typography.index,
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

  void toggleGlowBorders(bool enabled) {
    state = state.copyWith(enableGlowBorders: enabled);
    _saveToPrefs();
  }

  void toggleSystemWallpaper(bool enabled) {
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
```

---

## Part B — Biometric Auth & PIN Guard

### Step B1: `lib/core/auth/auth_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

enum AuthState { unauthenticated, authenticated }

class AuthNotifier extends Notifier<AuthState> {
  final _localAuth = LocalAuthentication();

  @override
  AuthState build() => AuthState.unauthenticated;

  Future<bool> authenticateBiometric() async {
    try {
      final canAuth = await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
      if (!canAuth) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock horAIzon 3.0',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );

      if (didAuth) state = AuthState.authenticated;
      return didAuth;
    } catch (_) {
      return false;
    }
  }

  void verifyPin(String pin) {
    // Default PIN: 5757
    if (pin == '5757') {
      state = AuthState.authenticated;
    }
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
```

---

## Part C — GoRouter Setup

### Step C1: `lib/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/governor/governor_status_screen.dart';
import '../features/governor/governor_ollama_screen.dart';
import '../features/governor/governor_logs_screen.dart';
import '../features/diary/diary_screen.dart';
import 'splash_screen.dart';
import 'shell_scaffold.dart';

final routeObserverProvider = Provider((_) => RouteObserver<ModalRoute<void>>());

final routerProvider = Provider<GoRouter>((ref) {
  final observer = ref.watch(routeObserverProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/governor/status',
            builder: (_, __) => const GovernorStatusScreen(),
          ),
          GoRoute(
            path: '/governor/ollama',
            builder: (_, __) => const GovernorOllamaScreen(),
          ),
          GoRoute(
            path: '/governor/logs',
            builder: (_, __) => const GovernorLogsScreen(),
          ),
          GoRoute(
            path: '/diary',
            builder: (_, __) => const DiaryScreen(),
          ),
        ],
      ),
    ],
  );
});
```

---

## Acceptance Criteria

- [ ] `ThemeCompiler` compiles primary & secondary seeds with 4 surface modes (`Cyber Obsidian`, `OLED Pure Black`, `Midnight Space`, `Warm Light`)
- [ ] Theme settings persist to `SharedPreferences` (JSON)
- [ ] Includes glowing borders toggle, typography profile selection, animation MS slider, and text scale
- [ ] GoRouter initialized with `RouteObserver`
- [ ] `AuthNotifier` supports biometric authentication + PIN fallback
- [ ] `flutter analyze` — 0 errors
