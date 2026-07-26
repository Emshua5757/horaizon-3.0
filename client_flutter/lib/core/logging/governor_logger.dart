import '../hbp/hbp_client.dart';
import '../hbp/hbp_frame.dart';
import 'package:messagepack/messagepack.dart';

enum LogLevel { info, warn, error }

/// Emits structured telemetry logs directly over HBP v2 WebSocket to shua_governor
class GovernorLogger {
  final HbpClient _hbpClient;

  GovernorLogger(this._hbpClient);

  /// Emit a structured log entry over HBP v2 directly to shua_governor
  Future<void> log({
    required String subsystem,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? metadata,
  }) async {
    if (_hbpClient.currentState != HbpConnectionState.connected) return;

    final p = Packer();
    p.packMapLength(4);
    p.packString('subsystem'); p.packString(subsystem);
    p.packString('level');     p.packString(level.name);
    p.packString('message');   p.packString(message);
    p.packString('timestamp'); p.packInt(DateTime.now().millisecondsSinceEpoch);

    final frame = HbpFrame.request('shua.governor', 'log.emit', p.takeBytes());
    try {
      await _hbpClient.send(frame);
    } catch (_) {
      // Fire-and-forget: do not crash if telemetry send fails
    }
  }
}
