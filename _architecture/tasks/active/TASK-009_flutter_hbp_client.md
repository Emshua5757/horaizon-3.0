# TASK-009 — `client_flutter` HBP v2 Client

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not started |
| **Phase** | Phase 1 |
| **Type** | AI-executable |
| **Language** | Dart |
| **Target** | `client_flutter/lib/core/hbp/` |
| **Blocks** | TASK-010, TASK-011 |
| **Prerequisites** | TASK-008 complete |

---

## Context

Implement the HBP v2 WebSocket client for Flutter. This is the foundation that every screen and provider uses to talk to `shua_governor`. It handles connection lifecycle, heartbeat, reconnect with backoff, MessagePack encoding, and pending request resolution via Completers.

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

      _sub = _channel!.stream.listen(
        _onMessage,
        onDone: _onDisconnect,
        onError: (_) => _onDisconnect(),
      );

      _setState(HbpConnectionState.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();
    } catch (_) {
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

  // ---- sending ----

  /// Send a request and wait for the matching response.
  /// Throws [TimeoutException] after 30 seconds.
  Future<HbpFrame> send(HbpFrame frame) async {
    if (_state != HbpConnectionState.connected) {
      throw StateError('HbpClient: not connected');
    }
    final completer = Completer<HbpFrame>();
    _pending[frame.txId] = completer;
    _channel!.sink.add(Uint8List.fromList(frame.encode()));
    return completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _pending.remove(frame.txId);
        throw TimeoutException('HBP request timed out: ${frame.op}');
      },
    );
  }

  /// Convenience: send a request and decode the response payload as JSON.
  Future<Map<String, dynamic>> request(
    String module,
    String op, {
    List<int> payload = const [],
  }) async {
    final frame = HbpFrame.request(module, op, payload);
    final response = await send(frame);
    if (response.isError) {
      throw Exception('HBP error: ${response.error}');
    }
    // Empty payload is valid for operations with no response body
    if (response.payload.isEmpty) return {};
    // Decode msgpack payload as a map
    // (requires messagepack unpacker on the response payload bytes)
    // For now return the raw bytes wrapped — proper decode in providers
    return {'_raw': response.payload};
  }

  // ---- incoming ----

  void _onMessage(dynamic raw) {
    List<int> bytes;
    if (raw is List<int>) {
      bytes = raw;
    } else if (raw is Uint8List) {
      bytes = raw;
    } else {
      return; // ignore text frames
    }

    final frame = HbpFrame.decode(bytes);

    if (frame.isPong) {
      // Heartbeat acknowledged — nothing to do
      return;
    }

    if (frame.msgType == HbpMsgType.response) {
      final completer = _pending.remove(frame.txId);
      if (completer != null) {
        completer.complete(frame);
      }
      return;
    }

    if (frame.msgType == HbpMsgType.event) {
      _eventController.add(frame);
    }
  }

  // ---- heartbeat ----

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_state == HbpConnectionState.connected) {
        _channel?.sink.add(
          Uint8List.fromList(HbpFrame.ping().encode()),
        );
      }
    });
  }

  // ---- reconnect ----

  void _onDisconnect() {
    _heartbeat?.cancel();
    _setState(HbpConnectionState.disconnected);
    // Fail all pending requests
    for (final c in _pending.values) {
      c.completeError(StateError('Connection lost'));
    }
    _pending.clear();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _setState(HbpConnectionState.reconnecting);
    _reconnectAttempts++;
    // Exponential backoff: 2s, 4s, 8s, max 30s
    final delay = Duration(
      seconds: (_reconnectAttempts * 2).clamp(2, 30),
    );
    _reconnectTimer = Timer(delay, connect);
  }

  void _setState(HbpConnectionState s) {
    _state = s;
    _stateController.add(s);
  }

  void dispose() {
    disconnect();
    _eventController.close();
    _stateController.close();
  }
}
```

---

## Step 3: `lib/core/config/app_config.dart`

```dart
/// App configuration — loaded from SharedPreferences
class AppConfig {
  final String piHost;        // e.g. "100.67.11.0" or "192.168.1.x"
  final int port;             // default 7700
  final bool useTailscale;    // if false, use LAN IP

  const AppConfig({
    required this.piHost,
    required this.port,
    required this.useTailscale,
  });

  factory AppConfig.defaults() => const AppConfig(
        piHost:       '100.67.11.0',
        port:         7700,
        useTailscale: true,
      );

  String get governorWsUrl => 'ws://$piHost:$port';

  AppConfig copyWith({String? piHost, int? port, bool? useTailscale}) =>
      AppConfig(
        piHost:       piHost ?? this.piHost,
        port:         port ?? this.port,
        useTailscale: useTailscale ?? this.useTailscale,
      );
}
```

---

## Step 4: `lib/core/config/app_config_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class AppConfigNotifier extends AsyncNotifier<AppConfig> {
  static const _keyHost = 'pi_host';
  static const _keyPort = 'pi_port';
  static const _keyTailscale = 'use_tailscale';

  @override
  Future<AppConfig> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppConfig(
      piHost:       prefs.getString(_keyHost)      ?? '100.67.11.0',
      port:         prefs.getInt(_keyPort)          ?? 7700,
      useTailscale: prefs.getBool(_keyTailscale)    ?? true,
    );
  }

  Future<void> update({String? piHost, int? port, bool? useTailscale}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await future;
    final next = current.copyWith(
      piHost: piHost, port: port, useTailscale: useTailscale,
    );
    if (piHost != null)       await prefs.setString(_keyHost, piHost);
    if (port != null)         await prefs.setInt(_keyPort, port);
    if (useTailscale != null) await prefs.setBool(_keyTailscale, useTailscale);
    state = AsyncData(next);
  }
}

final appConfigProvider =
    AsyncNotifierProvider<AppConfigNotifier, AppConfig>(
  AppConfigNotifier.new,
);
```

---

## Step 5: `lib/core/hbp/hbp_client_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config_provider.dart';
import 'hbp_client.dart';

/// Global HBP client instance — created once on first use.
final hbpClientProvider = AsyncNotifierProvider<HbpClientNotifier, HbpClient>(
  HbpClientNotifier.new,
);

class HbpClientNotifier extends AsyncNotifier<HbpClient> {
  @override
  Future<HbpClient> build() async {
    final config = await ref.watch(appConfigProvider.future);
    final client = HbpClient(config);
    await client.connect();

    // Dispose on provider teardown
    ref.onDispose(client.dispose);

    return client;
  }

  /// Reconnect with a new config (e.g. after settings change)
  Future<void> reconnect() async {
    final current = state.valueOrNull;
    current?.disconnect();
    state = const AsyncLoading();
    final config = await ref.read(appConfigProvider.future);
    final client = HbpClient(config);
    await client.connect();
    state = AsyncData(client);
  }
}

/// Stream provider for connection state — drives the connection banner UI
final connectionStateProvider = StreamProvider<HbpConnectionState>((ref) {
  final clientAsync = ref.watch(hbpClientProvider);
  return clientAsync.when(
    data:    (client) => client.connectionState,
    loading: () => Stream.value(HbpConnectionState.connecting),
    error:   (_, __) => Stream.value(HbpConnectionState.disconnected),
  );
});
```

---

## Step 6: Write unit tests

Create `test/core/hbp/hbp_frame_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/core/hbp/hbp_frame.dart';

void main() {
  group('HbpFrame', () {
    test('request round-trips through encode/decode', () {
      final frame = HbpFrame.request('shua.resume', 'compile', [1, 2, 3]);
      final encoded = frame.encode();
      final decoded = HbpFrame.decode(encoded);

      expect(decoded.module, 'shua.resume');
      expect(decoded.op, 'compile');
      expect(decoded.version, 2);
      expect(decoded.payload, [1, 2, 3]);
      expect(decoded.msgType, HbpMsgType.request);
    });

    test('ping frame has correct type', () {
      final ping = HbpFrame.ping();
      final decoded = HbpFrame.decode(ping.encode());
      expect(decoded.msgType, HbpMsgType.ping);
    });
  });
}
```

```powershell
flutter test test/core/hbp/hbp_frame_test.dart
```

---

## Acceptance Criteria

- [ ] `HbpFrame.request()` creates a frame with correct fields
- [ ] `HbpFrame.encode()` + `HbpFrame.decode()` round-trip is lossless (unit test passes)
- [ ] `HbpClient.connect()` establishes a WebSocket connection to Pi5
- [ ] `HbpClient.send()` sends a request and resolves the `Completer` on response
- [ ] Heartbeat PING is sent every 15 seconds
- [ ] On connection drop, reconnect fires after backoff
- [ ] `connectionStateProvider` emits correct state changes
- [ ] `flutter test` — all tests pass
- [ ] `flutter analyze` — no errors

---

## References

- `_architecture/contracts/hbp/hbp_v2_spec.md` — full frame spec, client implementation notes
- `_architecture/specs/client_flutter/client_flutter_spec.md` — Riverpod provider registry
