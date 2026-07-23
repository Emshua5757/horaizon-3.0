# TASK-010 — `client_flutter` GoRouter + SplashScreen + Theme System

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/router/`, `lib/core/theme/`, `lib/app.dart` |
| **Blocks** | TASK-011, TASK-012 |
| **Prerequisites** | TASK-009 complete |

---

## Context

Wire up GoRouter with all Phase 1 routes, implement the SplashScreen that checks Pi5 connectivity before routing to the dashboard, and build the full theme system (HCT color system, 4 theme presets, Outfit/Lora/JetBrains Mono typography).

Read `_architecture/specs/client_flutter/client_flutter_spec.md` §§ "GoRouter — Route Map", "Theme System" before implementing.

---

## Part A — Theme System

### Step A1: `lib/core/theme/app_theme.dart`

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemePreset { midnightGlass, warmPaper, cyberNeon, emeraldForest }

class AppTheme {
  final AppThemePreset preset;
  final double fontScale;

  const AppTheme({
    this.preset = AppThemePreset.midnightGlass,
    this.fontScale = 1.0,
  });

  ThemeData get themeData {
    final scheme = _colorScheme();
    final base = ThemeData(
      useMaterial3:  true,
      colorScheme:   scheme,
      textTheme:     _textTheme(scheme),
      cardTheme:     _cardTheme(scheme),
      appBarTheme:   _appBarTheme(scheme),
      navigationRailTheme: _navRailTheme(scheme),
      navigationBarTheme:  _navBarTheme(scheme),
    );
    return base;
  }

  ColorScheme _colorScheme() {
    return switch (preset) {
      AppThemePreset.midnightGlass => ColorScheme.fromSeed(
          seedColor:   const Color(0xFF2A3A5C),
          brightness:  Brightness.dark,
        ),
      AppThemePreset.warmPaper => ColorScheme.fromSeed(
          seedColor:   const Color(0xFFC8954A),
          brightness:  Brightness.light,
        ),
      AppThemePreset.cyberNeon => ColorScheme.fromSeed(
          seedColor:   const Color(0xFF00E5A0),
          brightness:  Brightness.dark,
        ),
      AppThemePreset.emeraldForest => ColorScheme.fromSeed(
          seedColor:   const Color(0xFF2E7D52),
          brightness:  Brightness.dark,
        ),
    };
  }

  TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.outfitTextTheme(
      ThemeData(brightness: scheme.brightness).textTheme,
    ).apply(
      bodyColor:    scheme.onSurface,
      displayColor: scheme.onSurface,
      fontSizeFactor: fontScale,
    );
    return base;
  }

  CardThemeData _cardTheme(ColorScheme scheme) => CardThemeData(
        elevation:    0,
        shape:        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant.withOpacity(0.3)),
        ),
        color: scheme.surfaceContainerLow,
      );

  AppBarTheme _appBarTheme(ColorScheme scheme) => AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation:       0,
        scrolledUnderElevation: 1,
      );

  NavigationRailThemeData _navRailTheme(ColorScheme scheme) =>
      NavigationRailThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        selectedIconTheme: IconThemeData(color: scheme.primary),
        selectedLabelTextStyle: TextStyle(color: scheme.primary),
      );

  NavigationBarThemeData _navBarTheme(ColorScheme scheme) =>
      NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor:  scheme.primaryContainer,
      );
}
```

### Step A2: `lib/core/theme/theme_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_theme.dart';

class ThemeNotifier extends Notifier<AppTheme> {
  @override
  AppTheme build() => const AppTheme();

  void setPreset(AppThemePreset preset) =>
      state = AppTheme(preset: preset, fontScale: state.fontScale);

  void setFontScale(double scale) =>
      state = AppTheme(preset: state.preset, fontScale: scale);
}

final themeProvider = NotifierProvider<ThemeNotifier, AppTheme>(
  ThemeNotifier.new,
);
```

---

## Part B — GoRouter

### Step B1: `lib/router/app_router.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/governor/governor_status_screen.dart';
import '../features/governor/governor_ollama_screen.dart';
import '../features/governor/governor_logs_screen.dart';
import 'splash_screen.dart';
import 'shell_scaffold.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
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
          // Phase 2 stub routes
          GoRoute(
            path: '/code/topology',
            builder: (_, __) => const _StubScreen('Code Topology — Phase 2'),
          ),
          // Phase 3 stub routes
          GoRoute(
            path: '/resume',
            builder: (_, __) => const _StubScreen('Resume — Phase 3'),
          ),
          GoRoute(
            path: '/diary',
            builder: (_, __) => const _StubScreen('Diary — Phase 3'),
          ),
        ],
      ),
    ],
  );
});

class _StubScreen extends StatelessWidget {
  final String label;
  const _StubScreen(this.label);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(label)),
        body: Center(
          child: Text('$label\n(Coming soon)',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge),
        ),
      );
}
```

### Step B2: `lib/router/shell_scaffold.dart` — Platform-adaptive nav

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    return isWide ? _WideLayout(child: child) : _NarrowLayout(child: child);
  }
}

class _WideLayout extends StatelessWidget {
  final Widget child;
  const _WideLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _indexFor(location),
            onDestinationSelected: (i) => _navigate(context, i),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations
                .map((d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      label: Text(d.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  final Widget child;
  const _NarrowLayout({required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indexFor(location),
        onDestinationSelected: (i) => _navigate(context, i),
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}

class _Dest {
  final String route;
  final IconData icon;
  final String label;
  const _Dest(this.route, this.icon, this.label);
}

const _destinations = [
  _Dest('/dashboard',        Icons.dashboard_outlined,   'Dashboard'),
  _Dest('/governor/status',  Icons.memory_outlined,      'Governor'),
  _Dest('/diary',            Icons.book_outlined,        'Diary'),
  _Dest('/resume',           Icons.description_outlined, 'Resume'),
  _Dest('/settings',         Icons.settings_outlined,    'Settings'),
];

int _indexFor(String location) {
  final idx = _destinations.indexWhere((d) => location.startsWith(d.route));
  return idx < 0 ? 0 : idx;
}

void _navigate(BuildContext context, int index) {
  context.go(_destinations[index].route);
}
```

---

## Part C — SplashScreen

### Step C1: `lib/router/splash_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/hbp/hbp_client_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String _status = 'Connecting to horaizon-pi5…';
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // Trigger the client to connect; wait up to 5 seconds
      final client = await ref
          .read(hbpClientProvider.future)
          .timeout(const Duration(seconds: 5));

      if (client.currentState == HbpConnectionState.connected) {
        if (mounted) context.go('/dashboard');
      } else {
        setState(() {
          _status = 'Cannot reach Pi5 at ${client.hashCode}';
          _failed = true;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'horAIzon',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text('3.0', style: theme.textTheme.titleMedium),
            const SizedBox(height: 40),
            if (!_failed)
              const CircularProgressIndicator()
            else ...[
              Text(_status,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  setState(() { _failed = false; _status = 'Retrying…'; });
                  _checkConnection();
                },
                child: const Text('Retry'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go('/settings'),
                child: const Text('Open Settings'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

## Part D — Wire `lib/app.dart`

Replace the stub `app.dart` from TASK-008 with the real implementation:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/theme_provider.dart';
import 'router/app_router.dart';

class HoraizonApp extends ConsumerWidget {
  const HoraizonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme  = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title:            'horAIzon 3.0',
      debugShowCheckedModeBanner: false,
      theme:            theme.themeData,
      routerConfig:     router,
    );
  }
}
```

---

## Acceptance Criteria

- [ ] App launches on Windows → `SplashScreen` shows with "Connecting to horaizon-pi5…"
- [ ] If Pi5 is reachable → navigates to `/dashboard` automatically
- [ ] If Pi5 is unreachable → shows error + Retry + Settings buttons
- [ ] `ShellScaffold` renders `NavigationRail` on wide screens (≥720px) and `NavigationBar` on narrow
- [ ] All 5 nav destinations navigate to their routes
- [ ] Stub screens (`/diary`, `/resume`, `/code/topology`) render "Coming soon" text
- [ ] Theme switches correctly between all 4 presets (test by changing `themeProvider`)
- [ ] `flutter analyze` — no errors

---

## References

- `_architecture/specs/client_flutter/client_flutter_spec.md` — route map, theme system, connection lifecycle
