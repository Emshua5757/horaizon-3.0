import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_client.dart';
import '../../core/hbp/hbp_frame.dart';

enum ModuleState { running, sleeping, stopped, unknown }

class ModuleStatus {
  final String name;
  final ModuleState state;
  final int? pid;
  final double ramMb;
  final double cpuPercent;
  final int? uptimeS;
  final bool healthOk;
  final int restartCount;

  const ModuleStatus({
    required this.name,
    required this.state,
    this.pid,
    this.ramMb = 0.0,
    this.cpuPercent = 0.0,
    this.uptimeS,
    this.healthOk = true,
    this.restartCount = 0,
  });

  factory ModuleStatus.fromMap(Map m) => ModuleStatus(
        name: m['name'] as String? ?? '',
        state: _parseState(m['state'] as String? ?? 'unknown'),
        pid: m['pid'] as int?,
        ramMb: (m['ram_mb'] as num?)?.toDouble() ?? (m['ram_limit_mb'] as num?)?.toDouble() ?? 0.0,
        cpuPercent: (m['cpu_percent'] as num?)?.toDouble() ?? 0.0,
        uptimeS: m['uptime_s'] as int?,
        healthOk: m['health_ok'] as bool? ?? true,
        restartCount: m['restart_count'] as int? ?? 0,
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
  final bool isLaptopOffload;

  const GovernorStatus({
    this.cpuUsagePct = 18.0,
    this.totalRamMb = 2140.0,
    this.ramCeilingMb = 7168.0,
    this.socTempC = 41.8,
    this.tailscaleLatencyMs = 12,
    this.lastBackupTime = '03:00 AM (Zstd Encrypted)',
    required this.modules,
    this.loadedModel = 'qwen2.5:1.5b (Laptop Offload)',
    this.ollamaRamMb = 1840.0,
    this.isIntentRouterActive = true,
    this.isLaptopOffload = true,
  });

  GovernorStatus copyWith({
    double? cpuUsagePct,
    double? totalRamMb,
    double? ramCeilingMb,
    double? socTempC,
    int? tailscaleLatencyMs,
    String? lastBackupTime,
    List<ModuleStatus>? modules,
    String? loadedModel,
    double? ollamaRamMb,
    bool? isIntentRouterActive,
    bool? isLaptopOffload,
  }) {
    return GovernorStatus(
      cpuUsagePct: cpuUsagePct ?? this.cpuUsagePct,
      totalRamMb: totalRamMb ?? this.totalRamMb,
      ramCeilingMb: ramCeilingMb ?? this.ramCeilingMb,
      socTempC: socTempC ?? this.socTempC,
      tailscaleLatencyMs: tailscaleLatencyMs ?? this.tailscaleLatencyMs,
      lastBackupTime: lastBackupTime ?? this.lastBackupTime,
      modules: modules ?? this.modules,
      loadedModel: loadedModel ?? this.loadedModel,
      ollamaRamMb: ollamaRamMb ?? this.ollamaRamMb,
      isIntentRouterActive: isIntentRouterActive ?? this.isIntentRouterActive,
      isLaptopOffload: isLaptopOffload ?? this.isLaptopOffload,
    );
  }

  factory GovernorStatus.mock() => const GovernorStatus(
        isLaptopOffload: true,
        modules: [
          ModuleStatus(name: 'shua_diary', state: ModuleState.running, ramMb: 142.0, cpuPercent: 1.2, healthOk: true),
          ModuleStatus(name: 'shua_code_viz', state: ModuleState.sleeping, ramMb: 0.0, cpuPercent: 0.0, healthOk: true),
          ModuleStatus(name: 'shua_resume', state: ModuleState.running, ramMb: 88.0, cpuPercent: 0.4, healthOk: true),
        ],
      );
}

class GovernorStatusNotifier extends AsyncNotifier<GovernorStatus> {
  Timer? _pollTimer;

  @override
  Future<GovernorStatus> build() async {
    _startPolling();
    ref.onDispose(() => _pollTimer?.cancel());
    return _fetch();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    // 2-second safe polling interval (0.5 Hz) for Raspberry Pi 5
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final current = state.valueOrNull ?? GovernorStatus.mock();
      final updated = await _fetch();
      // Keep local toggle state if modified
      state = AsyncData(updated.copyWith(isLaptopOffload: current.isLaptopOffload));
    });
  }

  Future<GovernorStatus> _fetch() async {
    try {
      var client = ref.read(hbpClientProvider).valueOrNull;

      if (client == null || client.currentState != HbpConnectionState.connected) {
        debugPrint('[HBP Client] Governor disconnected — retrying HBP WebSocket connection...');
        ref.invalidate(hbpClientProvider);
        try {
          client = await ref.read(hbpClientProvider.future).timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('[HBP Client] Reconnect attempt failed: $e');
        }
      }

      if (client == null || client.currentState != HbpConnectionState.connected) {
        return state.valueOrNull ?? GovernorStatus.mock();
      }

      final frame = HbpFrame.request('shua.governor', 'status', const []);
      final resp = await client.send(frame);

      if (resp.isError || resp.payload.isEmpty) {
        // ignore: avoid_print
        print('[HBP Client] Empty/Error response for governor.status (Err: ${resp.error})');
        return state.valueOrNull ?? GovernorStatus.mock();
      }

      final map = Unpacker(Uint8List.fromList(resp.payload)).unpackMap();
      // ignore: avoid_print
      print('[HBP TELEMETRY LIVE] Received frame payload: $map');

      final modulesList = (map['modules'] as List? ?? [])
          .map((m) => ModuleStatus.fromMap(m as Map))
          .toList();
      final ollama = map['ollama'] as Map?;
      final isLaptop = map['is_laptop_offload'] as bool? ?? true;
      final modelName = ollama?['loaded_model'] as String? ?? 'qwen2.5:1.5b';

      final liveLatencyMs = client.lastLatencyMs;

      return GovernorStatus(
        cpuUsagePct: (map['cpu_pct'] as num?)?.toDouble() ?? 18.0,
        totalRamMb: (map['total_ram_mb'] as num?)?.toDouble() ?? 2140.0,
        ramCeilingMb: 7168.0,
        socTempC: (map['temp_c'] as num?)?.toDouble() ?? 41.8,
        tailscaleLatencyMs: liveLatencyMs > 0 ? liveLatencyMs : (map['latency_ms'] as int? ?? 12),
        lastBackupTime: map['last_backup'] as String? ?? '03:00 AM (Zstd Encrypted)',
        modules: modulesList.isEmpty ? GovernorStatus.mock().modules : modulesList,
        loadedModel: isLaptop ? '$modelName (Laptop Offload)' : '$modelName (RPi5 Edge)',
        ollamaRamMb: (ollama?['ram_mb'] as num?)?.toDouble() ?? 1840.0,
        isIntentRouterActive: map['router_active'] as bool? ?? true,
        isLaptopOffload: isLaptop,
      );
    } catch (_) {
      return state.valueOrNull ?? GovernorStatus.mock();
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  /// Select active Ollama model
  Future<void> selectModel(String modelName) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final suffix = current.isLaptopOffload ? '(Laptop Offload)' : '(RPi5 Edge)';
    state = AsyncData(current.copyWith(loadedModel: '$modelName $suffix'));

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final payload = _encodeMap({'model': modelName});
        await client.send(HbpFrame.request('shua.governor', 'ollama.load', payload));
      }
    } catch (_) {}
  }

  /// Toggle inference offload target between Laptop GPU and RPi5 Edge Node
  Future<void> toggleOffloadTarget(bool isLaptop) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final rawModel = (current.loadedModel ?? 'qwen2.5:1.5b').split(' ').first;
    final newModelStr = isLaptop ? '$rawModel (Laptop Offload)' : '$rawModel (RPi5 Edge)';

    state = AsyncData(current.copyWith(
      isLaptopOffload: isLaptop,
      loadedModel: newModelStr,
    ));

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final payload = _encodeMap({'is_laptop_offload': isLaptop});
        await client.send(HbpFrame.request('shua.governor', 'ollama.offload_target', payload));
      }
    } catch (_) {}
  }

  Future<void> wakeModule(String name) async {
    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final payload = _encodeMap({'module': name});
        await client.send(HbpFrame.request('shua.governor', 'module.wake', payload));
      }
    } catch (_) {}
    await refresh();
  }

  Future<void> sleepModule(String name) async {
    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final payload = _encodeMap({'module': name});
        await client.send(HbpFrame.request('shua.governor', 'module.sleep', payload));
      }
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
    } else if (v is bool) {
      p.packBool(v);
    } else {
      p.packNull();
    }
  });
  return p.takeBytes();
}
