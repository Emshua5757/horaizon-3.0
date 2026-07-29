import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messagepack/messagepack.dart';
import '../hbp/hbp_client.dart';
import '../hbp/hbp_client_provider.dart';
import '../hbp/hbp_frame.dart';

enum LogLevel { info, warn, error }

/// Maximum number of log entries kept in the replay buffer.
/// Late subscribers (e.g. Telemetry tab opened after init) call [replayBuffer]
/// to drain entries they missed before they subscribed.
const _kMaxBufferSize = 200;

/// Central Telemetry & Logging Engine in client_flutter.
/// Respects Centralized Logging Policy (Rule #7): Emits structured telemetry logs over HBP v2 WebSocket
/// to shua_governor daemon for persistence in activity.db & important.log while maintaining local fallback.
class GovernorLogger {
  final HbpClient? _hbpClient;
  final _localLogController = StreamController<StructuredLogEntry>.broadcast();

  /// Rolling replay buffer — stores up to [_kMaxBufferSize] recent entries.
  /// Populated in sync with the broadcast stream so late subscribers never miss init-time logs.
  final List<StructuredLogEntry> _buffer = [];

  Stream<StructuredLogEntry> get logStream => _localLogController.stream;

  /// Snapshot of all buffered entries (oldest → newest). Use this to seed
  /// a UI state list on first subscription instead of replaying the stream.
  List<StructuredLogEntry> get bufferedEntries => List.unmodifiable(_buffer);

  GovernorLogger(this._hbpClient);

  /// Emit a structured telemetry log entry
  Future<void> log({
    required String subsystem,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    final timestamp = DateTime.now();
    final entry = StructuredLogEntry(
      subsystem: subsystem,
      level: level,
      message: message,
      timestamp: timestamp,
      metadata: metadata,
    );

    // 0. Append to replay buffer (capped at _kMaxBufferSize)
    _buffer.add(entry);
    if (_buffer.length > _kMaxBufferSize) {
      _buffer.removeAt(0);
    }

    // 1. Broadcast to local Flutter UI telemetry listeners
    if (!_localLogController.isClosed) {
      _localLogController.add(entry);
    }

    if (kDebugMode) {
      debugPrint('[${level.name.toUpperCase()}] [$subsystem] $message ${metadata ?? ''}');
    }

    // 2. If HBP v2 is connected, fire-and-forget log.emit frame to Rust shua_governor daemon.
    // IMPORTANT: Must NOT await — logging must never block or compete with ai.route pending tx.
    if (_hbpClient != null && _hbpClient.currentState == HbpConnectionState.connected) {
      final p = Packer();
      p.packMapLength(4);
      p.packString('subsystem'); p.packString(subsystem);
      p.packString('level');     p.packString(level.name);
      p.packString('message');   p.packString(message);
      p.packString('timestamp'); p.packInt(timestamp.millisecondsSinceEpoch);

      final frame = HbpFrame.request('shua.governor', 'log.emit', p.takeBytes());
      try {
        _hbpClient.sink(frame); // fire-and-forget: no await, no completer registered
      } catch (_) {
        // Resilient: log failures are non-fatal
      }
    }
  }

  void dispose() {
    _buffer.clear();
    _localLogController.close();
  }
}

class StructuredLogEntry {
  final String subsystem;
  final LogLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const StructuredLogEntry({
    required this.subsystem,
    required this.level,
    required this.message,
    required this.timestamp,
    this.metadata,
  });
}

/// Riverpod provider for GovernorLogger
final governorLoggerProvider = Provider<GovernorLogger>((ref) {
  final hbpAsync = ref.watch(hbpClientProvider);
  final hbpClient = hbpAsync.valueOrNull;
  final logger = GovernorLogger(hbpClient);
  ref.onDispose(() => logger.dispose());
  return logger;
});
