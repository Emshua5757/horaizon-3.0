import 'dart:async';
import 'dart:typed_data';

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
  HbpClient(this._config, {WebSocketChannel Function(Uri uri)? channelFactory})
      : _channelFactory = channelFactory ?? WebSocketChannel.connect;

  final AppConfig _config;
  final WebSocketChannel Function(Uri uri) _channelFactory;

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
        _state == HbpConnectionState.connecting) {
      return;
    }

    _setState(HbpConnectionState.connecting);
    final uri = Uri.parse(_config.governorWsUrl);

    try {
      _channel = _channelFactory(uri);
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
