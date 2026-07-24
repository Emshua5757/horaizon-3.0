// client_flutter/lib/core/governor/metrics_snapshot.dart
// Phase 11.10.A — Data model for SSE /api/metrics/stream JSON frames.
//
// Mirrors the Rust MetricsSnapshot struct in shua_governor/src/routes/sse_metrics.rs.
// Fields are intentionally nullable so partial payloads don't crash the parser.

/// Per-module telemetry included in each MetricsSnapshot.
class ModuleMetrics {
  /// State label: "ACTIVE", "STOPPED", "STARTING", "FROZEN", etc.
  final String state;

  /// Current RSS RAM in megabytes.
  final double ramMb;

  /// CPU utilisation 0.0–100.0 (per-module, 4-core normalised).
  final double cpuPct;

  const ModuleMetrics({
    required this.state,
    required this.ramMb,
    required this.cpuPct,
  });

  factory ModuleMetrics.fromJson(Map<String, dynamic> json) {
    return ModuleMetrics(
      state:  (json['state']   as String?)  ?? 'UNKNOWN',
      ramMb:  (json['ram_mb']  as num?)?.toDouble() ?? 0.0,
      cpuPct: (json['cpu_pct'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// System-wide snapshot broadcast by the Governor supervisor every 2 seconds.
/// Received over GET /api/metrics/stream as SSE "data:" JSON frames.
class MetricsSnapshot {
  /// Unix timestamp (seconds) when this snapshot was taken on the Pi.
  final int ts;

  /// System-wide CPU utilisation (0.0–100.0), all 4 Cortex-A76 cores.
  final double cpuPct;

  /// RPi 5 CPU die temperature in °C from thermal_zone0.
  final double tempC;

  /// Total RSS RAM across Governor + all running modules in MB.
  final double ramMb;

  /// RAM as a fraction of the 8 GB Pi 5 ceiling (0.0–1.0).
  final double ramPct;

  /// NVMe disk utilization percentage (0.0–100.0).
  final double diskUsedPct;

  /// Per-module telemetry keyed by module_id (e.g. "shua_diary").
  final Map<String, ModuleMetrics> modules;

  const MetricsSnapshot({
    required this.ts,
    required this.cpuPct,
    required this.tempC,
    required this.ramMb,
    required this.ramPct,
    required this.diskUsedPct,
    required this.modules,
  });

  factory MetricsSnapshot.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'] as Map<String, dynamic>? ?? {};
    final modules = rawModules.map(
      (key, value) => MapEntry(
        key,
        ModuleMetrics.fromJson(value as Map<String, dynamic>),
      ),
    );

    return MetricsSnapshot(
      ts:          (json['ts']            as int?)    ?? 0,
      cpuPct:      (json['cpu_pct']       as num?)?.toDouble() ?? 0.0,
      tempC:       (json['temp_c']        as num?)?.toDouble() ?? 0.0,
      ramMb:       (json['ram_mb']        as num?)?.toDouble() ?? 0.0,
      ramPct:      (json['ram_pct']       as num?)?.toDouble() ?? 0.0,
      diskUsedPct: (json['disk_used_pct'] as num?)?.toDouble() ?? 0.0,
      modules:     modules,
    );
  }

  @override
  String toString() =>
      'MetricsSnapshot(cpu: ${cpuPct.toStringAsFixed(1)}%, '
      'temp: ${tempC.toStringAsFixed(1)}°C, '
      'ram: ${ramMb.toStringAsFixed(1)} MB, '
      'modules: ${modules.keys.toList()})';
}
