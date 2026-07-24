// client_flutter — Governor Logger (Phase 12)
// Structured binary HBP log emitter over HTTP POST to the Rust Governor.
//
// Architecture Decision:
//   The spec originally called for sending log frames over the Socket.io connection
//   via SduiSocketManager. However, SduiSocketManager uses the socket_io_client package
//   which wraps all data in Socket.io protocol framing — raw binary HBP frames cannot
//   be injected without corrupting the SDUI data channel. The SDUI socket is also
//   module-scoped (it connects to /ws/shua_diary), while logs go to the Governor.
//
//   Solution: Fire-and-forget HTTP POST to $governorBaseUrl/api/logs/ingest.
//   Body = 12-byte HBP header + MessagePack-encoded integer-keyed log map.
//   This keeps the log channel cleanly decoupled from the SDUI data path.
//
// Zero-overhead fast-path:
//   Gate check (O(1) int compare) before ANY allocation.
//   If level < _minLogLevel, returns immediately — no Map allocation, no HTTP call.
//
// Singleton pattern: GovernorLogger() always returns the same instance.

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:msgpack_dart/msgpack_dart.dart' as msgpack;
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/sdui/core/sdui_socket_provider.dart'
    show kGovernorBaseUrl;

// ─────────────────────────────────────────────────────────────────────────────
// HBP frame constants
// ─────────────────────────────────────────────────────────────────────────────

const int _kHbpMagicH = 0x48; // 'H'
const int _kHbpMagicB = 0x42; // 'B'
const int _kHbpTypeLog = 0x12; // Type: LOG

// ─────────────────────────────────────────────────────────────────────────────
// GovernorLogger — Singleton
// ─────────────────────────────────────────────────────────────────────────────

/// Structured HBP binary log emitter for the Flutter client.
///
/// Sends log frames to `POST $kGovernorBaseUrl/api/logs/ingest`.
/// Fire-and-forget: never awaits the HTTP response, never throws to the caller.
///
/// Usage:
/// ```dart
/// GovernorLogger().log(
///   HbpLogLevel.INFO,
///   'sdui_screen',
///   'Blueprint assembled in ${elapsed}ms',
///   tags: HbpLogTag.SDUI | HbpLogTag.PERF,
///   telemetry: {'elapsed_ms': elapsed},
/// );
/// ```
class GovernorLogger {
  // Dart's factory constructor + static field implements the singleton pattern
  // with zero overhead after first construction — subsequent calls return the
  // same memory address, no allocation.
  static final GovernorLogger _instance = GovernorLogger._internal();
  factory GovernorLogger() => _instance;
  GovernorLogger._internal();

  // Minimum level gate — configurable at runtime if needed.
  // Defaults to DEBUG (2) in debug mode for verbosity, otherwise INFO (3).
  int _minLogLevel = kDebugMode ? HbpLogLevel.DEBUG : HbpLogLevel.INFO;

  /// Update the client-side minimum log level threshold.
  void setMinLogLevel(int level) => _minLogLevel = level;

  // Pre-built ingest URI — computed once at first log call, not per-call.
  Uri? _ingestUri;
  Uri get _uri {
    _ingestUri ??= Uri.parse('$kGovernorBaseUrl/api/logs/ingest');
    return _ingestUri!;
  }

  /// Emits a structured binary log entry to the Governor.
  ///
  /// [level]      - HbpLogLevel integer (use HbpLogLevel.INFO, .WARN, etc.)
  /// [subsystem]  - Sub-component label (e.g. 'sdui_renderer', 'governor_client')
  /// [msg]        - Human-readable description of the event
  /// [tags]       - Optional 24-bit bitmask of HbpLogTag values
  /// [customTags] - Optional ad-hoc string tag array
  /// [telemetry]  - Optional key-value performance data map
  /// [traceId]    - Optional 8-char hex correlation ID
  void log(
    int level,
    String subsystem,
    String msg, {
    int tags = 0,
    List<String>? customTags,
    Map<String, dynamic>? telemetry,
    String? traceId,
  }) {
    // ── 1. Emitter Gate Check (O(1) — zero allocation fast path) ─────────────
    if (level < _minLogLevel) return;

    // ── 2. Build integer-keyed payload Map ────────────────────────────────────
    // Integer keys match BorrowedLogEntry serde(rename) mappings in Rust.
    final Map<int, dynamic> payload = {
      0: DateTime.now().millisecondsSinceEpoch, // ts
      1: level, // level
      2: HbpModule.CLIENT_FLUTTER, // module (11)
      3: subsystem, // subsystem
      4: msg, // msg
      5: tags, // tags
    };

    if (customTags != null) payload[6] = customTags;
    if (telemetry != null) payload[7] = telemetry;
    if (traceId != null) payload[8] = traceId;

    // ── 3. Encode + build HBP frame + POST (fire-and-forget) ─────────────────
    _sendAsync(payload);
  }

  /// Builds the 12-byte HBP header + MsgPack payload and POSTs it asynchronously.
  /// Any errors are silently dropped — the logger must never crash the app.
  void _sendAsync(Map<int, dynamic> payload) {
    // Dart's unawaited async — schedules on the event loop, never blocks the caller.
    () async {
      try {
        final Uint8List msgpackBytes = msgpack.serialize(payload);

        // Build 12-byte header:
        //   [0]    = 0x48 ('H') magic
        //   [1]    = 0x42 ('B') magic
        //   [2]    = 0x00       version (reserved)
        //   [3]    = 0x12       type: LOG
        //   [4-7]  = 0x00000000 flags / stream ID (reserved)
        //   [8-11] = payload length as u32 big-endian
        final header = ByteData(12);
        header.setUint8(0, _kHbpMagicH);
        header.setUint8(1, _kHbpMagicB);
        header.setUint8(3, _kHbpTypeLog);
        header.setUint32(8, msgpackBytes.length, Endian.big);

        final frame = Uint8List(12 + msgpackBytes.length);
        frame.setRange(0, 12, header.buffer.asUint8List());
        frame.setRange(12, 12 + msgpackBytes.length, msgpackBytes);

        await http
            .post(
              _uri,
              headers: const {'Content-Type': 'application/octet-stream'},
              body: frame,
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Silently drop — network errors, timeout, Governor offline:
        // none of these should ever surface to the application layer.
      }
    }();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience Extension (optional ergonomic API)
// ─────────────────────────────────────────────────────────────────────────────

/// Top-level singleton accessor for terseness in call sites.
/// `gLog.info('sdui_screen', 'Rendered in ${elapsed}ms', tags: HbpLogTag.PERF);`
final GovernorLogger gLog = GovernorLogger();
