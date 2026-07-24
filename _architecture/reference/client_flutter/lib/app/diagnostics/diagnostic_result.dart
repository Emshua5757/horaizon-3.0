import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';

/// Represents a single logged occurrence of a repeated event.
class OccurrenceEntry {
  final DateTime timestamp;
  final Map<String, dynamic>? telemetry;

  const OccurrenceEntry({
    required this.timestamp,
    this.telemetry,
  });
}

/// A strongly-typed Diagnostic Result wrapper for horAIzon 2.0.
/// Replaces the C# 'out' parameter pattern using Dart's generic type models,
/// providing structured diagnostics, telemetry logging capabilities, and failure context.
class DiagnosticResult<T> {
  /// Indicates if the operation completed successfully without violations.
  final bool isSuccess;

  /// The resulting payload of the operation. Null on failure.
  final T? data;

  /// System-level diagnostic defining severity and standard error code.
  final SystemDiagnostic? diagnostic;

  /// Human-readable diagnostic description of the execution trace or failure.
  final String? message;

  /// Timestamp of operation resolution for Lamport ordering or timeline logs.
  final DateTime timestamp;

  /// Optional contextual telemetry (e.g. CPU temperature, network round-trip time).
  final Map<String, dynamic>? telemetry;

  /// Number of repeated identical entries represented by this snapshot (Run-Length Encoding).
  final int occurrenceCount;

  /// List of individual occurrences that were merged into this result.
  final List<OccurrenceEntry> occurrences;

  const DiagnosticResult._({
    required this.isSuccess,
    this.data,
    this.diagnostic,
    this.message,
    required this.timestamp,
    this.telemetry,
    required this.occurrenceCount,
    required this.occurrences,
  });

  /// Factory constructor representing a successful operation execution.
  factory DiagnosticResult.success(T data, {
    SystemDiagnostic? diagnostic,
    Map<String, dynamic>? telemetry,
  }) {
    final now = DateTime.now();
    return DiagnosticResult._(
      isSuccess: true,
      data: data,
      diagnostic: diagnostic,
      timestamp: now,
      telemetry: telemetry,
      occurrenceCount: 1,
      occurrences: [OccurrenceEntry(timestamp: now, telemetry: telemetry)],
    );
  }

  /// Factory constructor representing a failed operation execution.
  factory DiagnosticResult.failure(SystemDiagnostic diagnostic, {
    String? customMessage,
    Map<String, dynamic>? telemetry,
  }) {
    final now = DateTime.now();
    return DiagnosticResult._(
      isSuccess: false,
      diagnostic: diagnostic,
      message: customMessage ?? diagnostic.defaultMessage,
      timestamp: now,
      telemetry: telemetry,
      occurrenceCount: 1,
      occurrences: [OccurrenceEntry(timestamp: now, telemetry: telemetry)],
    );
  }

  /// Syntactic sugar for check status.
  bool get isFailure => !isSuccess;

  /// Helper to safely retrieve round-trip latency from telemetry mapping in O(1) time.
  int get latencyMs => (telemetry?['latency_ms'] as num?)?.toInt() ?? 0;

  /// Helper to verify if this represents a high-priority diagnostic event.
  bool get isCritical => diagnostic?.severity == DiagnosticSeverity.critical || (telemetry?['critical'] as bool? ?? false);

  /// Standard clone pattern allowing mutable increments to deduplication indices.
  DiagnosticResult<T> copyWith({
    DateTime? timestamp,
    int? occurrenceCount,
    List<OccurrenceEntry>? occurrences,
  }) {
    return DiagnosticResult._(
      isSuccess: isSuccess,
      data: data,
      diagnostic: diagnostic,
      message: message,
      timestamp: timestamp ?? this.timestamp,
      telemetry: telemetry,
      occurrenceCount: occurrenceCount ?? this.occurrenceCount,
      occurrences: occurrences ?? this.occurrences,
    );
  }

  @override
  String toString() {
    final countLabel = occurrenceCount > 1 ? ' (x$occurrenceCount)' : '';
    if (isSuccess) {
      return '[SUCCESS]$countLabel DiagnosticResult resolved at $timestamp. Data: $data';
    } else {
      return '[ERROR]$countLabel Code: ${diagnostic?.code ?? "UNKNOWN"} | Msg: $message | Resolved at $timestamp';
    }
  }
}
