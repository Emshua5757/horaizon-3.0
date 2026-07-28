import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../../core/hbp/hbp_client_provider.dart';
import '../../core/hbp/hbp_client.dart';
import '../../core/hbp/hbp_frame.dart';
import '../../core/logging/governor_logger.dart';
import '../../core/theme/theme_provider.dart';

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
    required this.ramMb,
    required this.cpuPercent,
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
      };
}

class GovernorStatus {
  final int? uptimeS;
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

  final List<double> cpuHistory;
  final List<double> ramHistory;
  final List<double> tempHistory;
  final List<double> latencyHistory;

  const GovernorStatus({
    this.uptimeS,
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
    this.cpuHistory = const [12.0, 15.0, 18.0, 14.0, 16.0, 18.0],
    this.ramHistory = const [2100.0, 2120.0, 2140.0, 2130.0, 2140.0],
    this.tempHistory = const [40.5, 41.0, 41.5, 41.8, 41.6],
    this.latencyHistory = const [14.0, 12.0, 13.0, 12.0, 12.0],
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
    List<double>? cpuHistory,
    List<double>? ramHistory,
    List<double>? tempHistory,
    List<double>? latencyHistory,
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
      cpuHistory: cpuHistory ?? this.cpuHistory,
      ramHistory: ramHistory ?? this.ramHistory,
      tempHistory: tempHistory ?? this.tempHistory,
      latencyHistory: latencyHistory ?? this.latencyHistory,
    );
  }

  factory GovernorStatus.mock() => const GovernorStatus(
        isLaptopOffload: true,
        modules: [
          ModuleStatus(name: 'shua_diary', state: ModuleState.running, ramMb: 142.0, cpuPercent: 1.2, healthOk: true),
          ModuleStatus(name: 'shua_code_visualizer', state: ModuleState.sleeping, ramMb: 380.0, cpuPercent: 0.0, healthOk: true),
          ModuleStatus(name: 'shua_resume', state: ModuleState.running, ramMb: 96.0, cpuPercent: 0.4, healthOk: true),
        ],
      );
}

class GovernorStatusNotifier extends AsyncNotifier<GovernorStatus> {
  Timer? _pollTimer;

  @override
  Future<GovernorStatus> build() async {
    final pollSeconds = ref.watch(themeProvider.select((s) => s.telemetryPollingSeconds));
    _startPolling(pollSeconds);
    ref.onDispose(() => _pollTimer?.cancel());
    return _fetch();
  }

  void _startPolling(double seconds) {
    _pollTimer?.cancel();
    final ms = (seconds * 1000).round().clamp(100, 10000);
    _pollTimer = Timer.periodic(Duration(milliseconds: ms), (_) async {
      final current = state.valueOrNull ?? GovernorStatus.mock();
      final updated = await _fetch();
      state = AsyncData(updated.copyWith(isLaptopOffload: current.isLaptopOffload));
    });
  }

  List<double> _appendHistory(List<double> existing, double newVal) {
    final list = List<double>.from(existing);
    list.add(newVal);
    if (list.length > 20) {
      list.removeAt(0);
    }
    return list;
  }

  Future<GovernorStatus> _fetch() async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final logger = ref.read(governorLoggerProvider);

    try {
      var client = ref.read(hbpClientProvider).valueOrNull;

      if (client == null || client.currentState != HbpConnectionState.connected) {
        ref.invalidate(hbpClientProvider);
        try {
          client = await ref.read(hbpClientProvider.future).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      if (client == null || client.currentState != HbpConnectionState.connected) {
        return current;
      }

      final frame = HbpFrame.request('shua.governor', 'status', const []);
      final resp = await client.send(frame);

      if (resp.isError || resp.payload.isEmpty) {
        return current;
      }

      final map = Unpacker(Uint8List.fromList(resp.payload)).unpackMap();

      final modulesList = (map['modules'] as List? ?? [])
          .map((m) => ModuleStatus.fromMap(m as Map))
          .toList();
      final ollama = map['ollama'] as Map?;
      final isLaptop = map['is_laptop_offload'] as bool? ?? true;
      final modelName = ollama?['loaded_model'] as String? ?? 'qwen2.5:1.5b';

      final cpu = (map['cpu_pct'] as num?)?.toDouble() ?? current.cpuUsagePct;
      final ram = (map['total_ram_mb'] as num?)?.toDouble() ?? current.totalRamMb;
      final temp = (map['temp_c'] as num?)?.toDouble() ?? current.socTempC;
      final ping = client.lastLatencyMs.toDouble();

      if (temp > 65.0) {
        logger.log(
          subsystem: 'GOVERNOR',
          level: LogLevel.warn,
          message: 'RPi 5 SoC Temperature elevated: ${temp.toStringAsFixed(1)}°C',
        );
      }

      return GovernorStatus(
        uptimeS: (map['uptime_s'] as num?)?.toInt(),
        cpuUsagePct: cpu,
        totalRamMb: ram,
        ramCeilingMb: (map['ram_ceiling_mb'] as num?)?.toDouble() ?? 7168.0,
        socTempC: temp,
        tailscaleLatencyMs: ping.toInt(),
        lastBackupTime: map['last_backup'] as String? ?? '03:00 AM (Zstd Encrypted)',
        modules: modulesList.isEmpty ? current.modules : modulesList,
        loadedModel: isLaptop ? '$modelName (Laptop Offload)' : '$modelName (RPi5 Edge)',
        ollamaRamMb: (ollama?['ram_mb'] as num?)?.toDouble() ?? 1840.0,
        isIntentRouterActive: map['router_active'] as bool? ?? true,
        isLaptopOffload: isLaptop,
        cpuHistory: _appendHistory(current.cpuHistory, cpu),
        ramHistory: _appendHistory(current.ramHistory, ram),
        tempHistory: _appendHistory(current.tempHistory, temp),
        latencyHistory: _appendHistory(current.latencyHistory, ping),
      );
    } catch (e) {
      logger.log(
        subsystem: 'GOVERNOR',
        level: LogLevel.error,
        message: 'Failed fetching Governor status over HBP v2: $e',
      );
      return current;
    }
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> selectModel(String modelName) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final logger = ref.read(governorLoggerProvider);
    final suffix = current.isLaptopOffload ? '(Laptop Offload)' : '(RPi5 Edge)';
    state = AsyncData(current.copyWith(loadedModel: '$modelName $suffix'));

    logger.log(
      subsystem: 'GOVERNOR',
      level: LogLevel.info,
      message: 'Governor requesting model load: $modelName',
    );

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final p = Packer();
        p.packMapLength(1);
        p.packString('model');
        p.packString(modelName);
        await client.send(HbpFrame.request('shua.governor', 'ollama.load', p.takeBytes()));
      }
    } catch (e) {
      logger.log(subsystem: 'GOVERNOR', level: LogLevel.error, message: 'Model load RPC error: $e');
    }
  }

  Future<void> toggleOffloadTarget(bool isLaptop) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final logger = ref.read(governorLoggerProvider);
    final rawModel = (current.loadedModel ?? 'qwen2.5:1.5b').split(' ').first;
    final newModelStr = isLaptop ? '$rawModel (Laptop Offload)' : '$rawModel (RPi5 Edge)';

    state = AsyncData(current.copyWith(
      isLaptopOffload: isLaptop,
      loadedModel: newModelStr,
    ));

    logger.log(
      subsystem: 'GOVERNOR',
      level: LogLevel.info,
      message: 'Toggled Governor offload target: ${isLaptop ? "Laptop Offload" : "RPi5 Edge"}',
    );

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final p = Packer();
        p.packMapLength(1);
        p.packString('is_laptop_offload');
        p.packBool(isLaptop);
        await client.send(HbpFrame.request('shua.governor', 'ollama.offload_target', p.takeBytes()));
      }
    } catch (_) {}
  }

  Future<void> wakeModule(String name) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final logger = ref.read(governorLoggerProvider);
    final updated = current.modules.map((m) {
      if (m.name == name) {
        return ModuleStatus(
          name: m.name,
          state: ModuleState.running,
          ramMb: m.ramMb > 0 ? m.ramMb : 128.0,
          cpuPercent: 1.5,
          healthOk: true,
        );
      }
      return m;
    }).toList();

    state = AsyncData(current.copyWith(modules: updated));

    logger.log(
      subsystem: 'GOVERNOR',
      level: LogLevel.info,
      message: 'Governor waking up microservice: $name',
    );

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final p = Packer();
        p.packMapLength(1);
        p.packString('name');
        p.packString(name);
        await client.send(HbpFrame.request('shua.governor', 'process.wake', p.takeBytes()));
      }
    } catch (e) {
      logger.log(subsystem: 'GOVERNOR', level: LogLevel.error, message: 'Wake process RPC error: $e');
    }
  }

  Future<void> sleepModule(String name) async {
    final current = state.valueOrNull ?? GovernorStatus.mock();
    final logger = ref.read(governorLoggerProvider);
    final updated = current.modules.map((m) {
      if (m.name == name) {
        return ModuleStatus(
          name: m.name,
          state: ModuleState.sleeping,
          ramMb: m.ramMb,
          cpuPercent: 0.0,
          healthOk: true,
        );
      }
      return m;
    }).toList();

    state = AsyncData(current.copyWith(modules: updated));

    logger.log(
      subsystem: 'GOVERNOR',
      level: LogLevel.info,
      message: 'Governor putting microservice to sleep: $name',
    );

    try {
      final client = ref.read(hbpClientProvider).valueOrNull;
      if (client != null && client.currentState == HbpConnectionState.connected) {
        final p = Packer();
        p.packMapLength(1);
        p.packString('name');
        p.packString(name);
        await client.send(HbpFrame.request('shua.governor', 'process.sleep', p.takeBytes()));
      }
    } catch (e) {
      logger.log(subsystem: 'GOVERNOR', level: LogLevel.error, message: 'Sleep process RPC error: $e');
    }
  }
}

final governorStatusProvider = AsyncNotifierProvider<GovernorStatusNotifier, GovernorStatus>(GovernorStatusNotifier.new);
