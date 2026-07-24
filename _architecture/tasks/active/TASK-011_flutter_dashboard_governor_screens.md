# TASK-011 — `client_flutter` DashboardScreen + GovernorScreens

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/features/dashboard/`, `lib/features/governor/` |
| **Blocks** | TASK-012 |
| **Prerequisites** | TASK-010 complete (routing works) |

---

## Context & Native Improvements

Implement the native Dashboard screen (module launch card grid + live Ollama badge), responsive `AdaptiveShell`, and all three Governor screens (Status, Ollama, Logs).

> [!NOTE]
> **Native Upgrades in 3.0**:
> 1. **Native `ModuleLaunchScreen`**: Replaces the 2.0 SDUI dashboard renderer. Renders a native `GridView` of module cards (`Diary`, `Code Visualizer`, `Terminal`, `Settings`) with animated card press effects and status badges.
> 2. **Responsive `AdaptiveShell`**: Uses `NavigationRail` on tablet/desktop (width ≥ 640px) and `NavigationBar` on mobile phones.
> 3. **Reverse Telemetry Feed in `GovernorLogsScreen`**: Pi 5 `warn!` and `error!` logs emitted from Rust `shua_governor` stream over WebSocket and populate the terminal log list in real-time.

---

## Part A — Governor Status Provider

### Step A1: `lib/features/governor/governor_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_frame.dart';

// ---- Data models ----

enum ModuleState { running, sleeping, stopped, unknown }

class ModuleStatus {
  final String name;
  final ModuleState state;
  final int? pid;
  final double? ramMb;
  final int? uptimeS;

  const ModuleStatus({
    required this.name,
    required this.state,
    this.pid,
    this.ramMb,
    this.uptimeS,
  });

  factory ModuleStatus.fromMap(Map m) => ModuleStatus(
        name:    m['name'] as String? ?? '',
        state:   _parseState(m['state'] as String? ?? 'unknown'),
        pid:     m['pid'] as int?,
        ramMb:   (m['ram_mb'] as num?)?.toDouble(),
        uptimeS: m['uptime_s'] as int?,
      );

  static ModuleState _parseState(String s) => switch (s) {
        'running'  => ModuleState.running,
        'sleeping' => ModuleState.sleeping,
        'stopped'  => ModuleState.stopped,
        _          => ModuleState.unknown,
      };
}

class GovernorStatus {
  final List<ModuleStatus> modules;
  final String? loadedModel;
  final double? ollamaRamMb;

  const GovernorStatus({
    required this.modules,
    this.loadedModel,
    this.ollamaRamMb,
  });

  factory GovernorStatus.empty() =>
      const GovernorStatus(modules: []);
}

// ---- Provider ----

class GovernorStatusNotifier extends AsyncNotifier<GovernorStatus> {
  @override
  Future<GovernorStatus> build() async {
    // Auto-refresh every 30s
    final timer = Stream.periodic(const Duration(seconds: 30));
    ref.listen(timer.asBroadcastStream().provider, (_, __) {
      refresh();
    });
    return _fetch();
  }

  Future<GovernorStatus> _fetch() async {
    final client = await ref.read(hbpClientProvider.future);
    final frame  = HbpFrame.request('shua.governor', 'status', []);
    final resp   = await client.send(frame);

    if (resp.isError || resp.payload.isEmpty) return GovernorStatus.empty();

    final map     = Unpacker(resp.payload).unpackMap();
    final modules = (map['modules'] as List? ?? [])
        .map((m) => ModuleStatus.fromMap(m as Map))
        .toList();
    final ollama  = map['ollama'] as Map?;

    return GovernorStatus(
      modules:      modules,
      loadedModel:  ollama?['loaded_model'] as String?,
      ollamaRamMb: (ollama?['ram_mb'] as num?)?.toDouble(),
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> wakeModule(String name) async {
    final client = await ref.read(hbpClientProvider.future);
    final payload = _encodeMap({'module': name});
    await client.send(HbpFrame.request('shua.governor', 'module.wake', payload));
    await refresh();
  }

  Future<void> sleepModule(String name) async {
    final client = await ref.read(hbpClientProvider.future);
    final payload = _encodeMap({'module': name});
    await client.send(HbpFrame.request('shua.governor', 'module.sleep', payload));
    await refresh();
  }

  Future<void> loadModel(String model) async {
    final client = await ref.read(hbpClientProvider.future);
    final payload = _encodeMap({'model': model});
    await client.send(HbpFrame.request('shua.governor', 'ollama.load', payload));
    await refresh();
  }

  Future<void> evictModel() async {
    final client = await ref.read(hbpClientProvider.future);
    await client.send(HbpFrame.request('shua.governor', 'ollama.evict', []));
    await refresh();
  }
}

final governorStatusProvider =
    AsyncNotifierProvider<GovernorStatusNotifier, GovernorStatus>(
  GovernorStatusNotifier.new,
);

List<int> _encodeMap(Map<String, dynamic> m) {
  final p = Packer();
  p.packMapLength(m.length);
  m.forEach((k, v) {
    p.packString(k);
    if (v is String) p.packString(v);
    else if (v is int) p.packInt(v);
    else p.packNull();
  });
  return p.takeBytes();
}

extension on Stream {
  StreamProvider get provider => StreamProvider((_) => this);
}
```

---

## Part B — Native DashboardScreen (`lib/features/dashboard/dashboard_screen.dart`)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../governor/governor_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(governorStatusProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('horAIzon 3.0'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Ollama status header card
          statusAsync.when(
            data: (status) => Card(
              child: ListTile(
                leading: const Icon(Icons.memory, color: Colors.emerald),
                title: Text(status.loadedModel ?? 'No AI Model Loaded'),
                subtitle: Text(status.ollamaRamMb != null
                    ? '${status.ollamaRamMb!.toStringAsFixed(0)} MB RAM allocated'
                    : 'Ollama Idle'),
                trailing: TextButton(
                  onPressed: () => context.go('/governor/ollama'),
                  child: const Text('Manage'),
                ),
              ),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text('Governor Error: $err'),
          ),
          const SizedBox(height: 24),
          Text('Modules', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          // Native grid of module cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _ModuleTile(
                title: 'Shua Diary',
                icon: Icons.book_outlined,
                color: Colors.amber,
                onTap: () => context.go('/diary'),
              ),
              _ModuleTile(
                title: 'Code Topology',
                icon: Icons.account_tree_outlined,
                color: Colors.cyan,
                onTap: () => context.go('/code/topology'),
              ),
              _ModuleTile(
                title: 'Governor Status',
                icon: Icons.monitor_heart_outlined,
                color: Colors.emerald,
                onTap: () => context.go('/governor/status'),
              ),
              _ModuleTile(
                title: 'System Logs',
                icon: Icons.terminal_outlined,
                color: Colors.purple,
                onTap: () => context.go('/governor/logs'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModuleTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModuleTile({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleSmall),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Part C — Governor Logs Screen (`lib/features/governor/governor_logs_screen.dart`)

Subscribes to live server-pushed EVENT telemetry logs over WebSocket.

---

## Acceptance Criteria

- [ ] Native `DashboardScreen` renders module tiles and Ollama status header
- [ ] Responsive `AdaptiveShell` switches between `NavigationRail` (≥ 640px) and `NavigationBar`
- [ ] `GovernorLogsScreen` streams live reverse-telemetry logs over HBP v2 WebSocket
- [ ] `flutter analyze` — 0 errors
