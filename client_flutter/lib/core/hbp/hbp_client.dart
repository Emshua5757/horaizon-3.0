import 'dart:async';
import 'dart:typed_data';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../config/app_config.dart';
import 'hbp_frame.dart';

enum HbpConnectionState { disconnected, connecting, connected, reconnecting }

typedef WebSocketChannelFactory = WebSocketChannel Function(Uri uri);

/// High-Performance Binary Protocol (HBP) v2 WebSocket Client
class HbpClient {
  final AppConfig _config;
  final WebSocketChannelFactory _channelFactory;

  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _heartbeat;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  HbpConnectionState _state = HbpConnectionState.disconnected;
  final Map<String, Completer<HbpFrame>> _pending = {};
  final _eventController = StreamController<HbpFrame>.broadcast();
  int _lastLatencyMs = 12;

  int get lastLatencyMs => _lastLatencyMs;

  HbpClient(
    this._config, {
    WebSocketChannelFactory? channelFactory,
  }) : _channelFactory =
            channelFactory ?? ((uri) => WebSocketChannel.connect(uri));

  Stream<HbpFrame> get events => _eventController.stream;
  final _stateController = StreamController<HbpConnectionState>.broadcast();
  Stream<HbpConnectionState> get connectionState => _stateController.stream;
  HbpConnectionState get currentState => _state;

  // ---- connection lifecycle ----

  Future<void> connect() async {
    if (_state == HbpConnectionState.connected ||
        _state == HbpConnectionState.connecting) {
      return;
    }

    _setState(HbpConnectionState.connecting);
    final uri = Uri.parse(_config.governorWsUrl);
    // ignore: avoid_print
    print('[HBP Client] Attempting connection to $uri ...');

    try {
      _channel = _channelFactory(uri);
      await _channel!.ready.timeout(const Duration(seconds: 4));
      _setState(HbpConnectionState.connected);
      _reconnectAttempts = 0;
      // ignore: avoid_print
      print('[HBP Client] SUCCESS: Connected to $uri ✓');

      _sub = _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );

      _startHeartbeat();
    } catch (e) {
      // ignore: avoid_print
      print('[HBP Client ERROR] Failed to connect to $uri -> $e');
      _setState(HbpConnectionState.disconnected);
      _scheduleReconnect();
    }
  }

  void disconnect() {
    _heartbeat?.cancel();
    _reconnectTimer?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _channel = null;
    _setState(HbpConnectionState.disconnected);
  }

  // ---- request / response ----

  /// Send an HBP v2 request frame and await the matching response
  Future<HbpFrame> send(HbpFrame frame) async {
    if (_state != HbpConnectionState.connected || _channel == null) {
      throw StateError('HbpClient is not connected (state: $_state)');
    }

    final startMs = DateTime.now().millisecondsSinceEpoch;
    final completer = Completer<HbpFrame>();
    _pending[frame.txId] = completer;

    _channel!.sink.add(Uint8List.fromList(frame.encode()));

    // Timeout after 10s if no response
    final resp = await completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        _pending.remove(frame.txId);
        throw TimeoutException(
            'HBP v2 request timed out: ${frame.module}.${frame.op}');
      },
    );

    _lastLatencyMs = DateTime.now().millisecondsSinceEpoch - startMs;
    return resp;
  }

  // ---- internal handlers ----

  void _onMessage(dynamic message) {
    List<int>? bytes;
    if (message is List<int>) {
      bytes = message;
    } else if (message is Uint8List) {
      bytes = message.toList();
    }
    if (bytes == null || bytes.isEmpty) return;

    try {
      final frame = HbpFrame.decode(bytes);
      // ignore: avoid_print
      print('[HBP Client Incoming] Decoded frame op: ${frame.op}, txId: ${frame.txId}');

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
      if (_state == HbpConnectionState.connected && _channel != null) {
        _channel?.sink.add(Uint8List.fromList(HbpFrame.ping().encode()));
      }
    });
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    if (_reconnectAttempts > 10) return; // Cap attempts

    _reconnectAttempts++;
    final delaySeconds = (1 << _reconnectAttempts).clamp(1, 30);
    final delay = Duration(seconds: delaySeconds);
    _setState(HbpConnectionState.reconnecting);

    _reconnectTimer = Timer(delay, () => connect());
  }

  void _setState(HbpConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }
}
