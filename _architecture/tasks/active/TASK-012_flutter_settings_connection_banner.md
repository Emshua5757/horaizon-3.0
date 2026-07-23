# TASK-012 — `client_flutter` SettingsScreen + Connection Banner

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/features/settings/`, `lib/shared/widgets/` |
| **Blocks** | Nothing — this completes Phase 1 Flutter |
| **Prerequisites** | TASK-011 complete |

---

## Context

Implement the Settings screen (Pi5 host configuration, theme picker, font scale) and the connection banner widget that appears at the top of every screen when the Pi5 is unreachable. This completes the Phase 1 Flutter client.

---

## Part A — SettingsScreen

### Step A1: `lib/features/settings/settings_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/app_config_provider.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _hostCtrl;
  late TextEditingController _portCtrl;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(appConfigProvider).valueOrNull;
    _hostCtrl = TextEditingController(text: config?.piHost ?? '100.67.11.0');
    _portCtrl = TextEditingController(text: '${config?.port ?? 7700}');
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final notifier = ref.read(appConfigProvider.notifier);
    await notifier.update(
      piHost: _hostCtrl.text.trim(),
      port:   int.tryParse(_portCtrl.text.trim()) ?? 7700,
    );
    // Reconnect with new config
    await ref.read(hbpClientProvider.notifier).reconnect();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved — reconnecting…')),
      );
    }
    setState(() => _changed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme        = Theme.of(context);
    final appTheme     = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final config       = ref.watch(appConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (_changed)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Network section ----
          _SectionHeader('Network'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pi5 Host (Tailscale IP or LAN IP)',
                      style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _hostCtrl,
                    decoration: const InputDecoration(
                      hintText: '100.67.11.0',
                      prefixIcon: Icon(Icons.dns_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _changed = true),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  Text('Port', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _portCtrl,
                    decoration: const InputDecoration(
                      hintText: '7700',
                      prefixIcon: Icon(Icons.lan_outlined),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() => _changed = true),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  config.when(
                    data: (c) => Chip(
                      avatar: const Icon(Icons.link, size: 16),
                      label: Text('ws://${c.piHost}:${c.port}',
                          style: theme.textTheme.bodySmall),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error:   (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ---- Theme section ----
          _SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: theme.textTheme.labelMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: AppThemePreset.values.map((preset) {
                      final isSelected = appTheme.preset == preset;
                      return ChoiceChip(
                        label: Text(_presetLabel(preset)),
                        selected: isSelected,
                        onSelected: (_) => themeNotifier.setPreset(preset),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Text('Font Scale', style: theme.textTheme.labelMedium),
                  Slider(
                    value:    appTheme.fontScale,
                    min:      0.8,
                    max:      1.4,
                    divisions: 6,
                    label:    '${appTheme.fontScale.toStringAsFixed(1)}×',
                    onChanged: themeNotifier.setFontScale,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ---- About section ----
          _SectionHeader('About'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('horAIzon 3.0'),
              subtitle: const Text(
                'Native Flutter · Multi-language backend · Offline-first AI\n'
                'Running on horaizon-pi5 (100.67.11.0)',
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ---- Sync contracts ----
          _SectionHeader('Developer Tools'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync_outlined),
              title: const Text('HBP v2 Contracts'),
              subtitle: const Text(
                'Run: python -m tools.sync_contracts\n'
                'to regenerate contracts across all languages',
              ),
              trailing: const Icon(Icons.terminal),
            ),
          ),
        ],
      ),
    );
  }

  String _presetLabel(AppThemePreset preset) => switch (preset) {
        AppThemePreset.midnightGlass  => 'Midnight',
        AppThemePreset.warmPaper      => 'Warm Paper',
        AppThemePreset.cyberNeon      => 'Cyber Neon',
        AppThemePreset.emeraldForest  => 'Emerald',
      };
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
      );
}
```

---

## Part B — Connection Banner (shared widget)

This widget sits above every screen's body when the Pi5 is unreachable. Wire it into `ShellScaffold` from TASK-010.

### Step B1: `lib/shared/widgets/connection_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/hbp/hbp_client_provider.dart';

class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connAsync = ref.watch(connectionStateProvider);

    return connAsync.when(
      data: (state) {
        if (state == HbpConnectionState.connected) {
          return const SizedBox.shrink();
        }
        final (label, color) = switch (state) {
          HbpConnectionState.reconnecting =>
            ('Reconnecting to Pi5…', Colors.amber.shade700),
          HbpConnectionState.connecting =>
            ('Connecting…', Colors.blue.shade700),
          _ =>
            ('Pi5 unreachable — check Tailscale', Colors.red.shade700),
        };
        return MaterialBanner(
          backgroundColor: color,
          content: Text(label,
              style: const TextStyle(color: Colors.white)),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(hbpClientProvider.notifier).reconnect(),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error:   (_, __) => const SizedBox.shrink(),
    );
  }
}
```

### Step B2: Add `ConnectionBanner` to `ShellScaffold`

In `lib/router/shell_scaffold.dart`, update both layout classes to include the banner at the top of their `body`:

```dart
// In _WideLayout.build(), replace body's Row child Expanded:
Expanded(
  child: Column(
    children: [
      const ConnectionBanner(),
      Expanded(child: child),
    ],
  ),
),

// In _NarrowLayout.build(), replace body: child with:
body: Column(
  children: [
    const ConnectionBanner(),
    Expanded(child: child),
  ],
),
```

---

## Part C — Loading Shimmer (shared widget)

### Step C1: `lib/shared/widgets/loading_shimmer.dart`

```dart
import 'package:flutter/material.dart';

/// A pulsing shimmer placeholder for async loading states.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 60,
    this.borderRadius = 12,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHigh;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width:  widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color:        color.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}
```

---

## Part D — Final Phase 1 Integration Smoke Test

Run the following to confirm Phase 1 is complete:

```powershell
# 1. Ensure all dependencies are resolved
flutter pub get

# 2. Static analysis — must be 0 errors
flutter analyze

# 3. Unit tests
flutter test

# 4. Run on Windows
flutter run -d windows

# 5. Run on Android (Moto G84 connected via USB or wireless debug)
flutter run -d android
```

Manual verification checklist:
- Open app on MSI → SplashScreen appears → connects to Pi5 → navigates to Dashboard
- Dashboard shows module grid with real data from `governor.status`
- Navigate to Governor → Status screen → see module states
- Navigate to Governor → Ollama screen → load `qwen2.5:1.5b` → see it appear as loaded
- Navigate to Settings → change theme → theme applies immediately
- Kill Pi5 connection → connection banner appears at top of screen

---

## Acceptance Criteria

- [ ] `SettingsScreen` saves Pi5 host + port to `SharedPreferences`
- [ ] Changing Pi5 host in Settings and saving triggers a reconnect
- [ ] Theme picker changes the app theme in real time
- [ ] Font scale slider changes text size in real time
- [ ] `ConnectionBanner` shows amber banner on reconnecting, red on disconnected
- [ ] `ConnectionBanner` disappears immediately when connection is restored
- [ ] `LoadingShimmer` pulses correctly
- [ ] `flutter analyze` — 0 errors across ALL files
- [ ] `flutter test` — all tests pass
- [ ] App works on both Windows (NavigationRail) and Android (BottomNavigationBar)

---

## References

- `_architecture/specs/client_flutter/client_flutter_spec.md` — Phase 1 acceptance criteria, screen inventory
- TASK-010 — `ShellScaffold` (must add `ConnectionBanner` there)
