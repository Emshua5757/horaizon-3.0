import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:client_flutter/app/diagnostics/diagnostic_result.dart';
import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart'
    show kGovernorBaseUrl;
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

/// System profiles governing client-side diagnostics RAM and GC footprints.
enum TelemetryProfile {
  /// Strict memory savings for budget mobile hardware or low-battery alerts.
  lowFootprint,

  /// Default baseline configuration.
  defaultProfile,

  /// Heavy-duty logging for local testing, laptop viewport debugging, or deep trace captures.
  debugProfile,
}

/// The immutable state model representing the Dynamic Dual-Pointer Mirror Logs Engine.
class DiagnosticsState {
  /// Unified chronological log timeline of all system actions in O(1) access complexity.
  final List<DiagnosticResult> globalTimeline;

  /// Partitioned nominal operations (success actions, theme compiles, ping success).
  final List<DiagnosticResult> nominalQueue;

  /// Partitioned warning events (soft sync failures, duplicate actions, minor validation faults).
  final List<DiagnosticResult> warningQueue;

  /// Partitioned high-priority system failures (network loss, db locks, container exceptions).
  final List<DiagnosticResult> criticalQueue;

  /// Cumulative nominal successes recorded during the application's runtime.
  final int totalSuccessCount;

  /// Cumulative warnings and exceptions recorded during the application's runtime.
  final int totalFailureCount;

  /// rolling O(1) latency accumulator preventing frame-drawing traversal cycles.
  final double rollingAverageLatency;

  /// Dynamic limits for memory boundaries, adjustable at runtime.
  final int globalLimit;
  final int nominalLimit;
  final int warningLimit;
  final int criticalLimit;

  const DiagnosticsState({
    required this.globalTimeline,
    required this.nominalQueue,
    required this.warningQueue,
    required this.criticalQueue,
    required this.totalSuccessCount,
    required this.totalFailureCount,
    required this.rollingAverageLatency,
    required this.globalLimit,
    required this.nominalLimit,
    required this.warningLimit,
    required this.criticalLimit,
  });

  /// Standard clone pattern mapping to single-dispatch UI changes.
  DiagnosticsState copyWith({
    List<DiagnosticResult>? globalTimeline,
    List<DiagnosticResult>? nominalQueue,
    List<DiagnosticResult>? warningQueue,
    List<DiagnosticResult>? criticalQueue,
    int? totalSuccessCount,
    int? totalFailureCount,
    double? rollingAverageLatency,
    int? globalLimit,
    int? nominalLimit,
    int? warningLimit,
    int? criticalLimit,
  }) {
    return DiagnosticsState(
      globalTimeline: globalTimeline ?? this.globalTimeline,
      nominalQueue: nominalQueue ?? this.nominalQueue,
      warningQueue: warningQueue ?? this.warningQueue,
      criticalQueue: criticalQueue ?? this.criticalQueue,
      totalSuccessCount: totalSuccessCount ?? this.totalSuccessCount,
      totalFailureCount: totalFailureCount ?? this.totalFailureCount,
      rollingAverageLatency:
          rollingAverageLatency ?? this.rollingAverageLatency,
      globalLimit: globalLimit ?? this.globalLimit,
      nominalLimit: nominalLimit ?? this.nominalLimit,
      warningLimit: warningLimit ?? this.warningLimit,
      criticalLimit: criticalLimit ?? this.criticalLimit,
    );
  }

  /// Calculates success rate in O(1) execution space.
  double get successRate {
    final total = totalSuccessCount + totalFailureCount;
    if (total == 0) return 100.0;
    return (totalSuccessCount / total) * 100.0;
  }
}

/// The global diagnostics history provider holding the active telemetry state.
final diagnosticsHistoryProvider =
    NotifierProvider<DiagnosticsHistoryNotifier, DiagnosticsState>(() {
      return DiagnosticsHistoryNotifier();
    });

class DiagnosticsHistoryNotifier extends Notifier<DiagnosticsState> {
  @override
  DiagnosticsState build() {
    // Phase 12 — Listen to centralized logs stream from Governor
    ref.listen(governorLogsStreamProvider, (previous, next) {
      if (next.hasValue && next.value != null) {
        logResult(next.value!, fromRemote: true);
      }
    });

    return const DiagnosticsState(
      globalTimeline: [],
      nominalQueue: [],
      warningQueue: [],
      criticalQueue: [],
      totalSuccessCount: 0,
      totalFailureCount: 0,
      rollingAverageLatency: 0.0,
      globalLimit: 100,
      nominalLimit: 50,
      warningLimit: 30,
      criticalLimit: 20,
    );
  }

  /// Helper method executing O(1) sublist pointer truncations for dynamic limit drops.
  List<DiagnosticResult> _truncate(List<DiagnosticResult> list, int limit) {
    if (list.length > limit) {
      return list.sublist(list.length - limit);
    }
    return list;
  }

  /// Dynamically alters queue sizing constraints and sweeps memory instantly.
  void updateLimits({
    int? globalLimit,
    int? nominalLimit,
    int? warningLimit,
    int? criticalLimit,
  }) {
    final nextGlobalLimit = globalLimit ?? state.globalLimit;
    final nextNominalLimit = nominalLimit ?? state.nominalLimit;
    final nextWarningLimit = warningLimit ?? state.warningLimit;
    final nextCriticalLimit = criticalLimit ?? state.criticalLimit;

    state = state.copyWith(
      globalLimit: nextGlobalLimit,
      nominalLimit: nextNominalLimit,
      warningLimit: nextWarningLimit,
      criticalLimit: nextCriticalLimit,
      globalTimeline: _truncate(state.globalTimeline, nextGlobalLimit),
      nominalQueue: _truncate(state.nominalQueue, nextNominalLimit),
      warningQueue: _truncate(state.warningQueue, nextWarningLimit),
      criticalQueue: _truncate(state.criticalQueue, nextCriticalLimit),
    );
  }

  /// Shifter to dynamically re-scale active telemetry memory preset limits.
  void setTelemetryProfile(TelemetryProfile profile) {
    switch (profile) {
      case TelemetryProfile.lowFootprint:
        updateLimits(
          globalLimit: 50,
          nominalLimit: 25,
          warningLimit: 15,
          criticalLimit: 10,
        );
        break;
      case TelemetryProfile.defaultProfile:
        updateLimits(
          globalLimit: 100,
          nominalLimit: 50,
          warningLimit: 30,
          criticalLimit: 20,
        );
        break;
      case TelemetryProfile.debugProfile:
        updateLimits(
          globalLimit: 500,
          nominalLimit: 250,
          warningLimit: 150,
          criticalLimit: 100,
        );
        break;
    }
  }

  /// Conveniece syntactic sugar resetting all buffer parameters back to default profile.
  void resetLimitsToDefault() {
    setTelemetryProfile(TelemetryProfile.defaultProfile);
  }

  /// Dispatches execution trace, registers duplicate runs, and routes pointers dynamically.
  void logResult(DiagnosticResult result, {bool fromRemote = false}) {
    if (!fromRemote) {
      // Phase 12 Phase D — Route local logs to the central aggregator
      final severity =
          result.diagnostic?.severity ?? DiagnosticSeverity.nominal;
      final level = switch (severity) {
        DiagnosticSeverity.nominal => HbpLogLevel.INFO,
        DiagnosticSeverity.warning => HbpLogLevel.WARN,
        DiagnosticSeverity.critical => HbpLogLevel.ERROR,
      };

      final subsystem = result.diagnostic?.code ?? 'CLIENT';
      gLog.log(
        level,
        subsystem,
        result.message ?? result.diagnostic?.defaultMessage ?? '',
        tags: subsystem.startsWith('AUTH')
            ? HbpLogTag.SECURITY
            : subsystem.startsWith('NAV')
            ? HbpLogTag.LIFECYCLE
            : HbpLogTag.SYSTEM,
        telemetry: result.telemetry,
      );
      return;
    }

    // 1. (Legacy console UI removed - logs are now processed in memory and SDUI will fetch them)

    final timeline = state.globalTimeline;

    // 2. Perform Run-Length Encoding (RLE) Deduplication to save slot storage
    if (timeline.isNotEmpty) {
      final lastResult = timeline.last;
      if (lastResult.diagnostic?.code == result.diagnostic?.code &&
          lastResult.message == result.message &&
          lastResult.isSuccess == result.isSuccess) {
        final updatedResult = lastResult.copyWith(
          timestamp: result.timestamp,
          occurrenceCount: lastResult.occurrenceCount + 1,
          occurrences: [
            ...lastResult.occurrences,
            OccurrenceEntry(
              timestamp: result.timestamp,
              telemetry: result.telemetry,
            ),
          ],
        );

        // Replace identical element on the global timeline
        final newTimeline = List<DiagnosticResult>.from(timeline);
        newTimeline[newTimeline.length - 1] = updatedResult;

        // Replace identical element on its corresponding target partition queue
        List<DiagnosticResult> newNominal = List.from(state.nominalQueue);
        List<DiagnosticResult> newWarning = List.from(state.warningQueue);
        List<DiagnosticResult> newCritical = List.from(state.criticalQueue);

        if (result.isCritical) {
          if (newCritical.isNotEmpty) {
            newCritical[newCritical.length - 1] = updatedResult;
          }
        } else if (result.isFailure) {
          if (newWarning.isNotEmpty) {
            newWarning[newWarning.length - 1] = updatedResult;
          }
        } else {
          if (newNominal.isNotEmpty) {
            newNominal[newNominal.length - 1] = updatedResult;
          }
        }

        state = state.copyWith(
          globalTimeline: newTimeline,
          nominalQueue: newNominal,
          warningQueue: newWarning,
          criticalQueue: newCritical,
        );
        return;
      }
    }

    // 3. Process Standard Queue Appends with Dynamic Circular Bounding Limits
    final newTimeline = List<DiagnosticResult>.from(timeline)..add(result);
    if (newTimeline.length > state.globalLimit) {
      newTimeline.removeAt(0);
    }

    List<DiagnosticResult> newNominal = List.from(state.nominalQueue);
    List<DiagnosticResult> newWarning = List.from(state.warningQueue);
    List<DiagnosticResult> newCritical = List.from(state.criticalQueue);

    if (result.isCritical) {
      newCritical.add(result);
      if (newCritical.length > state.criticalLimit) {
        newCritical.removeAt(0);
      }
    } else if (result.isFailure) {
      newWarning.add(result);
      if (newWarning.length > state.warningLimit) {
        newWarning.removeAt(0);
      }
    } else {
      newNominal.add(result);
      if (newNominal.length > state.nominalLimit) {
        newNominal.removeAt(0);
      }
    }

    // 4. Update O(1) Running Telemetry Metrics
    final isSuccess = result.isSuccess;
    final int nextSuccessCount = state.totalSuccessCount + (isSuccess ? 1 : 0);
    final int nextFailureCount = state.totalFailureCount + (isSuccess ? 0 : 1);

    // Calculate rolling average execution latency synchronously in O(1) time
    final int totalRuns = nextSuccessCount + nextFailureCount;
    final double nextLatencyAvg = totalRuns == 1
        ? result.latencyMs.toDouble()
        : ((state.rollingAverageLatency * (totalRuns - 1)) + result.latencyMs) /
              totalRuns;

    state = state.copyWith(
      globalTimeline: newTimeline,
      nominalQueue: newNominal,
      warningQueue: newWarning,
      criticalQueue: newCritical,
      totalSuccessCount: nextSuccessCount,
      totalFailureCount: nextFailureCount,
      rollingAverageLatency: nextLatencyAvg,
    );
  }

  /// Wipes all cached logs to perform garbage collection
  void clearHistory() {
    state = state.copyWith(
      globalTimeline: [],
      nominalQueue: [],
      warningQueue: [],
      criticalQueue: [],
      totalSuccessCount: 0,
      totalFailureCount: 0,
      rollingAverageLatency: 0.0,
    );
  }
}

/// SSE StreamProvider for centralized logs from /api/logs/stream.
final governorLogsStreamProvider = StreamProvider<DiagnosticResult>((ref) {
  return _sseLogsStream();
});

Stream<DiagnosticResult> _sseLogsStream() async* {
  final uri = Uri.parse('$kGovernorBaseUrl/api/logs/stream');

  while (true) {
    try {
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';

      final client = http.Client();
      final response = await client.send(request);

      if (response.statusCode != 200) {
        client.close();
        await Future.delayed(const Duration(seconds: 5));
        continue;
      }

      final lineStream = response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter());

      await for (final line in lineStream) {
        if (!line.startsWith('data: ')) continue;

        final jsonStr = line.substring(6).trim();
        if (jsonStr.isEmpty) continue;

        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;

          final int level = json['level'] as int? ?? 3;
          final int moduleVal = json['module'] as int? ?? 10;
          final String subsystem = json['subsystem'] as String? ?? 'general';
          final String msg = json['msg'] as String? ?? '';
          final Map<String, dynamic>? telemetry =
              json['telemetry'] as Map<String, dynamic>?;

          DiagnosticSeverity severity = DiagnosticSeverity.nominal;
          if (level == HbpLogLevel.WARN) {
            severity = DiagnosticSeverity.warning;
          } else if (level >= HbpLogLevel.ERROR) {
            severity = DiagnosticSeverity.critical;
          }

          String moduleName = 'UNKNOWN';
          switch (moduleVal) {
            case HbpModule.CORE_CHAT:
              moduleName = 'CHAT';
              break;
            case HbpModule.SHUA_DIARY:
              moduleName = 'DIARY';
              break;
            case HbpModule.SHUA_CRYPTO:
              moduleName = 'CRYPTO';
              break;
            case HbpModule.SHUA_GYM_VISION:
              moduleName = 'GYM';
              break;
            case HbpModule.SHUA_TRADING_BOT:
              moduleName = 'TRADING';
              break;
            case HbpModule.SHUA_RESUME:
              moduleName = 'RESUME';
              break;
            case HbpModule.SHUA_MEMORY_LANE:
              moduleName = 'MEMORY';
              break;
            case HbpModule.SHUA_CODE_REVIEW:
              moduleName = 'REVIEW';
              break;
            case HbpModule.SHUA_EDGE_ML:
              moduleName = 'ML';
              break;
            case HbpModule.SHUA_BILL_TRACKER:
              moduleName = 'BILL';
              break;
            case HbpModule.SHUA_GOVERNOR:
              moduleName = 'GOVERNOR';
              break;
            case HbpModule.CLIENT_FLUTTER:
              moduleName = 'FLUTTER';
              break;
          }

          final code = '$moduleName-$subsystem'.toUpperCase();
          final diag = SystemDiagnostic(code, msg, severity);

          // Inject raw log level into telemetry so the terminal UI can differentiate TRACE/DEBUG/INFO/WARN/ERR
          final Map<String, dynamic> enrichedTelemetry = {
            ...?telemetry,
            'log_level': level,
          };

          final result = level >= 4 // WARN (4), ERROR (5) or CRITICAL (6)
              ? DiagnosticResult.failure(
                  diag,
                  customMessage: msg,
                  telemetry: enrichedTelemetry,
                )
              : DiagnosticResult.success(
                  msg,
                  diagnostic: diag,
                  telemetry: enrichedTelemetry,
                );

          yield result;
        } catch (e) {
          gLog.log(
            HbpLogLevel.ERROR,
            'logs_sse',
            'Map error: $e',
            tags: HbpLogTag.NETWORK,
          );
        }
      }

      client.close();
      await Future.delayed(const Duration(seconds: 3));
    } catch (e) {
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}
