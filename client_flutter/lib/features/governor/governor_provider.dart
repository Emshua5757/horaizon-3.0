import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_frame.dart';

enum ModuleState { running, sleeping, stopped, unknown }

class ModuleStatus {
  final String name;
  final ModuleState state;
  final int? pid;
  final double ramMb;
  final int? uptimeS;

  const ModuleStatus({
    required this.name,
    required this.state,
    this.pid,
    this.ramMb = 0.0,
    this.uptimeS,
  });

  factory ModuleStatus.fromMap(Map m) => ModuleStatus(
        name: m['name'] as String? ?? '',
        state: _parseState(m['state'] as String? ?? 'unknown'),
        pid: m['pid'] as int?,
        ramMb: (m['ram_mb'] as num?)?.toDouble() ?? 0.0,
        uptimeS: m['uptime_s'] as int?,
      );

  static ModuleState _parseState(String s) => switch (s) {
        'running' => ModuleState.running,
        'sleeping' => ModuleState.sleeping,
        'stopped' => ModuleState.stopped,
        _ => ModuleState.unknown,
      };
}

class GovernorStatus {
  final double cpuUsagePct;
  final double totalRamMb;
  final double ramCeilingMb;
  final double socTempC;
  final int tailscaleLatencyMs;
  final String lastBackupTime;
  final List<ModuleStatus> modules;
  final String? loadedModel;
  final double? ollamaRamMb;
  final bool isIntentRouterActive;

  const GovernorStatus({
    this.cpuUsagePct = 18.0,
    this.totalRamMb = 2140.0,
    this.ramCeilingMb = 7168.0,
    this.socTempC = 41.8,
    this.tailscaleLatencyMs = 12,
    this.lastBackupTime = '03:00 AM (Zstd Encrypted)',
    required this.modules,
    this.loadedModel = 'qwen2.5:1.5b (RPi5 Edge)',
    this.ollamaRamMb = 1840.0,
    this.isIntentRouterActive = true,
  });

  factory GovernorStatus.mock() => const GovernorStatus(
        modules: [
          ModuleStatus(name: 'shua_diary', state: ModuleState.running, ramMb: 142.0),
          ModuleStatus(name: 'shua_code_viz', state: ModuleState.sleeping, ramMb: 0.0),
          ModuleStatus(name: 'shua_resume', state: ModuleState.running, ramMb: 88.0),
        ],
      );
}

class GovernorStatusNotifier extends AsyncNotifier<GovernorStatus> {
  @override
  Future<GovernorStatus> build() async {
    return _fetch();
  }

  Future<GovernorStatus> _fetch() async {
    try {
      final client = await ref.read(hbpClientProvider.future);
      final frame = HbpFrame.request('shua.governor', 'status', const []);
      final resp = await client.send(frame);

      if (resp.isError || resp.payload.isEmpty) {
        return GovernorStatus.mock();
      }

      final map = Unpacker(Uint8List.fromList(resp.payload)).unpackMap();
      final modulesList = (map['modules'] as List? ?? [])
          .map((m) => ModuleStatus.fromMap(m as Map))
          .toList();
      final ollama = map['ollama'] as Map?;

      return GovernorStatus(
        cpuUsagePct: (map['cpu_pct'] as num?)?.toDouble() ?? 18.0,
        totalRamMb: (map['total_ram_mb'] as num?)?.toDouble() ?? 2140.0,
        ramCeilingMb: 7168.0,
        socTempC: (map['temp_c'] as num?)?.toDouble() ?? 41.8,
        tailscaleLatencyMs: map['latency_ms'] as int? ?? 12,
        lastBackupTime: map['last_backup'] as String? ?? '03:00 AM (Zstd Encrypted)',
        modules: modulesList.isEmpty ? GovernorStatus.mock().modules : modulesList,
        loadedModel: ollama?['loaded_model'] as String? ?? 'qwen2.5:1.5b (RPi5 Edge)',
        ollamaRamMb: (ollama?['ram_mb'] as num?)?.toDouble() ?? 1840.0,
        isIntentRouterActive: map['router_active'] as bool? ?? true,
      );
    } catch (_) {
      return GovernorStatus.mock();
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> wakeModule(String name) async {
    try {
      final client = await ref.read(hbpClientProvider.future);
      final payload = _encodeMap({'module': name});
      await client.send(HbpFrame.request('shua.governor', 'module.wake', payload));
    } catch (_) {}
    await refresh();
  }

  Future<void> sleepModule(String name) async {
    try {
      final client = await ref.read(hbpClientProvider.future);
      final payload = _encodeMap({'module': name});
      await client.send(HbpFrame.request('shua.governor', 'module.sleep', payload));
    } catch (_) {}
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
    if (v is String) {
      p.packString(v);
    } else if (v is int) {
      p.packInt(v);
    } else {
      p.packNull();
    }
  });
  return p.takeBytes();
}
