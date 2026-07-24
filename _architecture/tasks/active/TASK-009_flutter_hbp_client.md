# TASK-009 — `client_flutter` HBP v2 Client & Native Logging Engine

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/core/hbp/`, `lib/core/logging/` |
| **Blocks** | TASK-010, TASK-011 |
| **Prerequisites** | TASK-008 complete |

---

## Architectural Directives & Native Improvements

> [!IMPORTANT]
> **NO Monolithic Socket Managers (`SduiSocketManager`). NO Drift Side Channels.**
> - In 2.0, `SduiSocketManager` was a 688 LOC monolith mapping screen IDs to raw sockets, and `GovernorLogger` wrote to a Drift DB sync table as a side channel.
> - **In 3.0**:
>   1. **`HorizonWebSocketProvider`**: A clean, reusable Riverpod `AsyncNotifier<WebSocketChannel>` that handles connection lifecycle, heartbeat ping/pong, and reconnect with exponential backoff. Each feature module instantiates its own typed WS stream (e.g. `governorWsProvider`, `diaryWsProvider`).
>   2. **`GovernorLogger`**: Emits structured telemetry logs directly over the HBP v2 WebSocket connection to `shua_governor` port 7700. Zero local database coupling.

Read `_architecture/contracts/hbp/hbp_v2_spec.md` in full before implementing.

---

## Step 1: `lib/core/hbp/hbp_frame.dart` — Envelope model + MessagePack codec

```dart
import 'package:messagepack/messagepack.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// HBP v2 message type codes
enum HbpMsgType {
  request(0x01),
  response(0x02),
  event(0x03),
  ping(0x04),
  pong(0x05),
  error(0x06);

  const HbpMsgType(this.value);
  final int value;

  static HbpMsgType fromInt(int v) =>
      HbpMsgType.values.firstWhere((e) => e.value == v,
          orElse: () => throw ArgumentError('Unknown HbpMsgType: $v'));
}

/// Universal HBP v2 message envelope
class HbpFrame {
  final int version;          // Always 2
  final HbpMsgType msgType;
  final String txId;          // UUID v4
  final String module;        // e.g. "shua.resume"
  final String op;            // e.g. "compile"
  final int timestamp;        // Unix ms
  final List<int> payload;    // msgpack-encoded body
  final String? error;

  const HbpFrame({
    required this.version,
    required this.msgType,
    required this.txId,
    required this.module,
    required this.op,
    required this.timestamp,
    required this.payload,
    this.error,
  });

  // ---- factories ----

  factory HbpFrame.request(String module, String op, List<int> payload) =>
      HbpFrame(
        version:   2,
        msgType:   HbpMsgType.request,
        txId:      _uuid.v4(),
        module:    module,
        op:        op,
        timestamp: _nowMs(),
        payload:   payload,
      );

  factory HbpFrame.ping() => HbpFrame(
        version:   2,
        msgType:   HbpMsgType.ping,
        txId:      _uuid.v4(),
        module:    'shua.governor',
        op:        'ping',
        timestamp: _nowMs(),
        payload:   [],
      );

  // ---- codec ----

  /// Encode frame to MessagePack bytes
  List<int> encode() {
    final p = Packer();
    p.packMapLength(error != null ? 8 : 7);
    p.packString('v');   p.packInt(version);
    p.packString('t');   p.packInt(msgType.value);
    p.packString('id');  p.packString(txId);
    p.packString('mod'); p.packString(module);
    p.packString('op');  p.packString(op);
    p.packString('ts');  p.packInt(timestamp);
    p.packString('p');   p.packBinary(payload);
    if (error != null) {
      p.packString('err'); p.packString(error!);
    }
    return p.takeBytes();
  }

  /// Decode frame from MessagePack bytes
  factory HbpFrame.decode(List<int> bytes) {
    final u = Unpacker(bytes);
    final len = u.unpackMapLength();
    final map = <String, dynamic>{};
    for (var i = 0; i < len; i++) {
      final key = u.unpackString()!;
      map[key] = switch (key) {
        'v' || 't' || 'ts' => u.unpackInt(),
        'p'                => u.unpackBinary(),
        _                  => u.unpackString(),
      };
    }
    return HbpFrame(
      version:   (map['v'] as int?) ?? 2,
      msgType:   HbpMsgType.fromInt((map['t'] as int?) ?? 1),
      txId:      (map['id'] as String?) ?? '',
      module:    (map['mod'] as String?) ?? '',
      op:        (map['op'] as String?) ?? '',
      timestamp: (map['ts'] as int?) ?? 0,
      payload:   (map['p'] as List<int>?) ?? [],
      error:     map['err'] as String?,
    );
  }

  bool get isError => error != null;
  bool get isPong  => msgType == HbpMsgType.pong;
}

int _nowMs() =>
    DateTime.now().millisecondsSinceEpoch;
```

---

## Step 2: `lib/core/hbp/hbp_client.dart` — WebSocket connection + heartbeat + reconnect

```dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'hbp_frame.dart';
import '../config/app_config.dart';

/// Connection state enum
enum HbpConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class HbpClient {
  HbpClient(this._config);

  final AppConfig _config;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;

  var _state = HbpConnectionState.disconnected;
  int _reconnectAttempts = 0;

  /// Pending requests: txId → Completer<HbpFrame>
  final _pending = <String, Completer<HbpFrame>>{};

  /// Event stream for server-pushed EVENTs (fire-and-forget from server)
  final _eventController = StreamController<HbpFrame>.broadcast();
  Stream<HbpFrame> get events => _eventController.stream;

  /// Connection state stream
  final _stateController =
      StreamController<HbpConnectionState>.broadcast();
  Stream<HbpConnectionState> get connectionState => _stateController.stream;
  HbpConnectionState get currentState => _state;

  // ---- connection lifecycle ----

  Future<void> connect() async {
    if (_state == HbpConnectionState.connected ||
        _state == HbpConnectionState.connecting) return;

    _setState(HbpConnectionState.connecting);
    final uri = Uri.parse(_config.governorWsUrl);

    try {
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;
      _setState(HbpConnectionState.connected);
      _reconnectAttempts = 0;

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _startHeartbeat();
    } catch (e) {
      _setState(HbpConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _setState(HbpConnectionState.disconnected);
  }

  // ---- request / response ----

  /// Send an HBP v2 request frame and await the matching response
  Future<HbpFrame> send(HbpFrame frame) async {
    if (_state != HbpConnectionState.connected) {
      throw StateError('HbpClient is not connected (state: $_state)');
    }

    final completer = Completer<HbpFrame>();
    _pending[frame.txId] = completer;

    _channel!.sink.add(Uint8List.fromList(frame.encode()));

    // Timeout after 10s if no response
    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(frame.txId);
        throw TimeoutException('HBP v2 request timed out: ${frame.module}.${frame.op}');
      },
    );
  }

  // ---- internal handlers ----

  void _onMessage(dynamic message) {
    if (message is! List<int>) return;
    try {
      final frame = HbpFrame.decode(message);

      if (frame.isPong) return; // Heartbeat response

      if (frame.msgType == HbpMsgType.event) {
        _eventController.add(frame);
        return;
      }

      // Response to a pending request
      final completer = _pending.remove(frame.txId);
      if (completer != null && !completer.isCompleted) {
        completer.complete(frame);
      }
    } catch (e) {
      // Decode error — ignore malformed frame
    }
  }

  void _onError(Object error) {
    _setState(HbpConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _onDone() {
    _setState(HbpConnectionState.disconnected);
    _scheduleReconnect();
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_state == HbpConnectionState.connected) {
        _channel?.sink.add(Uint8List.fromList(HbpFrame.ping().encode()));
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts > 10) return; // Cap attempts

    _reconnectAttempts++;
    final delay = Duration(seconds: (1 << _reconnectAttempts).clamp(1, 30));
    _setState(HbpConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () => connect());
  }

  void _setState(HbpConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }
}
```

---

## Step 3: `lib/core/logging/governor_logger.dart` — Direct HBP v2 telemetry emitter

```dart
import '../hbp/hbp_client.dart';
import '../hbp/hbp_frame.dart';
import 'package:messagepack/messagepack.dart';

enum LogLevel { info, warn, error }

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
```

---

## Step 4: `lib/core/hbp/hbp_client_provider.dart` — Riverpod provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config_provider.dart';
import 'hbp_client.dart';

final hbpClientProvider = FutureProvider<HbpClient>((ref) async {
  final config = await ref.watch(appConfigProvider.future);
  final client = HbpClient(config);
  await client.connect();

  ref.onDispose(() => client.disconnect());
  return client;
});

final hbpConnectionStateProvider = StreamProvider<HbpConnectionState>((ref) async* {
  final client = await ref.watch(hbpClientProvider.future);
  yield client.currentState;
  yield* client.connectionState;
});
```

---

## Acceptance Criteria

- [ ] `HbpFrame` correctly encodes and decodes all 6 frame types
- [ ] `HbpClient` connects to `ws://host:port/hbp` and sends ping every 15s
- [ ] Reconnect uses exponential backoff (1s, 2s, 4s… up to 30s)
- [ ] `GovernorLogger` emits structured telemetry logs over WebSocket to `shua_governor` with zero Drift DB coupling
- [ ] `hbpConnectionStateProvider` emits live state updates
- [ ] `flutter analyze` — 0 errors
