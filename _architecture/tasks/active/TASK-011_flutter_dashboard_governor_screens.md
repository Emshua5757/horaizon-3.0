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

## Context

Implement the Dashboard screen (module status grid + Ollama badge) and all three Governor screens (Status, Ollama, Logs). These are the primary Phase 1 UI surfaces — they talk to `shua_governor` via HBP v2 and display real-time data.

---

## Part A — Governor Provider

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

## Part B — GovernorStatusScreen

### Step B1: `lib/features/governor/governor_status_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'governor_provider.dart';

class GovernorStatusScreen extends ConsumerWidget {
  const GovernorStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(governorStatusProvider);
    final notifier    = ref.read(governorStatusProvider.notifier);
    final theme       = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Governor Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: notifier.refresh,
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Ollama card
            _OllamaCard(status: status),
            const SizedBox(height: 16),
            // Module cards
            ...status.modules.map(
              (m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ModuleCard(
                  module: m,
                  onWake:  () => notifier.wakeModule(m.name),
                  onSleep: () => notifier.sleepModule(m.name),
                ),
              ),
            ),
            if (status.modules.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('No modules registered'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OllamaCard extends StatelessWidget {
  final GovernorStatus status;
  const _OllamaCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.psychology_outlined,
                color: theme.colorScheme.primary, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ollama', style: theme.textTheme.titleMedium),
                Text(
                  status.loadedModel ?? 'No model loaded',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: status.loadedModel != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
                if (status.ollamaRamMb != null)
                  Text(
                    '${status.ollamaRamMb!.toStringAsFixed(0)} MB',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final ModuleStatus module;
  final VoidCallback onWake;
  final VoidCallback onSleep;

  const _ModuleCard({
    required this.module,
    required this.onWake,
    required this.onSleep,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon, label) = switch (module.state) {
      ModuleState.running  => (Colors.green, Icons.play_circle_outline,   'Running'),
      ModuleState.sleeping => (Colors.amber, Icons.pause_circle_outline,  'Sleeping'),
      ModuleState.stopped  => (Colors.grey,  Icons.stop_circle_outlined,  'Stopped'),
      ModuleState.unknown  => (Colors.red,   Icons.help_outline,          'Unknown'),
    };
    return Card(
      child: ListTile(
        leading: Icon(icon, color: color),
        title:   Text(module.name),
        subtitle: Text(
          [
            label,
            if (module.pid != null) 'PID ${module.pid}',
            if (module.ramMb != null) '${module.ramMb!.toStringAsFixed(0)} MB',
          ].join(' · '),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (module.state == ModuleState.sleeping)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Wake',
                onPressed: onWake,
              ),
            if (module.state == ModuleState.running)
              IconButton(
                icon: const Icon(Icons.pause),
                tooltip: 'Sleep',
                onPressed: onSleep,
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Part C — GovernorOllamaScreen

### Step C1: `lib/features/governor/governor_ollama_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'governor_provider.dart';

const _availableModels = [
  ('qwen2.5:1.5b',     '~980 MB',  'Primary dialogue'),
  ('llama3.2:3b',      '~2.0 GB',  'Text generator'),
  ('nomic-embed-text', '~270 MB',  'Embeddings'),
];

class GovernorOllamaScreen extends ConsumerWidget {
  const GovernorOllamaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(governorStatusProvider);
    final notifier    = ref.read(governorStatusProvider.notifier);
    final theme       = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Ollama — Model Manager')),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (status) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Current status banner
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.memory,
                        color: theme.colorScheme.onPrimaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            status.loadedModel ?? 'No model loaded',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          if (status.ollamaRamMb != null)
                            Text(
                              '${status.ollamaRamMb!.toStringAsFixed(0)} MB in use',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (status.loadedModel != null)
                      FilledButton.tonal(
                        onPressed: notifier.evictModel,
                        child: const Text('Evict'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Available Models', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._availableModels.map(
              (m) => Card(
                child: ListTile(
                  title:    Text(m.$1),
                  subtitle: Text('${m.$2} · ${m.$3}'),
                  trailing: status.loadedModel == m.$1
                      ? Chip(
                          label: const Text('Loaded'),
                          backgroundColor: theme.colorScheme.primaryContainer,
                        )
                      : FilledButton(
                          onPressed: () => notifier.loadModel(m.$1),
                          child: const Text('Load'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Part D — GovernorLogsScreen (stub — real logs in Phase 2)

### Step D1: `lib/features/governor/governor_logs_screen.dart`

```dart
import 'package:flutter/material.dart';

class GovernorLogsScreen extends StatelessWidget {
  const GovernorLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Governor Logs')),
      body: const Center(
        child: Text('Live log stream — Phase 2\n'
            '(Requires shua_code_visualizer EVENT push integration)',
            textAlign: TextAlign.center),
      ),
    );
  }
}
```

---

## Part E — DashboardScreen

### Step E1: `lib/features/dashboard/dashboard_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../governor/governor_provider.dart';
import '../../core/hbp/hbp_client_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync    = ref.watch(governorStatusProvider);
    final connState      = ref.watch(connectionStateProvider);
    final theme          = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('horAIzon 3.0'),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: connState.when(
              data: (s) => Icon(
                s == HbpConnectionState.connected
                    ? Icons.wifi
                    : Icons.wifi_off,
                color: s == HbpConnectionState.connected
                    ? Colors.green
                    : theme.colorScheme.error,
              ),
              loading: () => const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => Icon(Icons.wifi_off,
                  color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
      body: statusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline,
                  color: theme.colorScheme.error, size: 48),
              const SizedBox(height: 16),
              Text('Cannot reach Governor\n$e',
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (status) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ollama status banner
              _OllamaStatusBanner(status: status),
              const SizedBox(height: 16),
              // Module grid
              Text('Modules', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (status.modules.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No modules registered yet')),
                  ),
                )
              else
                GridView.extent(
                  shrinkWrap:    true,
                  physics:       const NeverScrollableScrollPhysics(),
                  maxCrossAxisExtent: 200,
                  childAspectRatio:   1.2,
                  mainAxisSpacing:    12,
                  crossAxisSpacing:   12,
                  children: status.modules
                      .map((m) => _ModuleGridTile(module: m))
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/governor/status'),
        icon: const Icon(Icons.tune),
        label: const Text('Governor'),
      ),
    );
  }
}

class _OllamaStatusBanner extends StatelessWidget {
  final GovernorStatus status;
  const _OllamaStatusBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.psychology_outlined,
                color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ollama', style: theme.textTheme.labelLarge),
                Text(
                  status.loadedModel ?? 'Idle',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: status.loadedModel != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            const Spacer(),
            TextButton(
              onPressed: () => GoRouter.of(context).go('/governor/ollama'),
              child: const Text('Manage'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGridTile extends StatelessWidget {
  final ModuleStatus module;
  const _ModuleGridTile({required this.module});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (color, icon) = switch (module.state) {
      ModuleState.running  => (Colors.green,  Icons.check_circle_outline),
      ModuleState.sleeping => (Colors.amber,  Icons.pause_circle_outline),
      ModuleState.stopped  => (Colors.grey,   Icons.stop_circle_outlined),
      ModuleState.unknown  => (Colors.red,    Icons.help_outline),
    };
    final shortName = module.name.split('.').last;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => GoRouter.of(context).go('/governor/status'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(shortName,
                  style: theme.textTheme.labelMedium,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

## Acceptance Criteria

- [ ] `DashboardScreen` displays Ollama status banner and module grid from live `governor.status` data
- [ ] Connection icon in AppBar reflects `HbpConnectionState` (green wifi / red wifi_off)
- [ ] `GovernorStatusScreen` lists all registered modules with wake/sleep buttons
- [ ] Wake button sends `governor.module.wake` HBP request and refreshes state
- [ ] Sleep button sends `governor.module.sleep` HBP request and refreshes state
- [ ] `GovernorOllamaScreen` shows loaded model and Load/Evict buttons
- [ ] Load button sends `governor.ollama.load` HBP request
- [ ] Evict button sends `governor.ollama.evict` HBP request
- [ ] 30-second auto-refresh of `governorStatusProvider` works
- [ ] `flutter analyze` — no errors on all new files

---

## References

- `_architecture/specs/client_flutter/client_flutter_spec.md` — screen inventory, provider registry
- `_architecture/contracts/hbp/hbp_v2_spec.md` — `governor.status`, `module.wake`, `ollama.load` schemas
