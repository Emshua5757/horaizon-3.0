import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:client_flutter/core/config/app_config.dart';
import 'package:client_flutter/core/hbp/hbp_client.dart';
import 'package:client_flutter/core/hbp/hbp_frame.dart';

class MockWebSocketChannel implements WebSocketChannel {
  final StreamController<dynamic> _streamController;
  final StreamController<dynamic> _sinkController;

  MockWebSocketChannel(this._streamController, this._sinkController);

  @override
  Stream<dynamic> get stream => _streamController.stream;

  @override
  WebSocketSink get sink => _MockSink(_sinkController);

  @override
  Future<void> get ready => Future.value();

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockSink implements WebSocketSink {
  final StreamController<dynamic> _sinkController;
  _MockSink(this._sinkController);

  @override
  void add(dynamic data) {
    _sinkController.add(data);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future addStream(Stream<dynamic> stream) async {}

  @override
  Future close([int? closeCode, String? closeReason]) async {}

  @override
  Future get done => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('HbpClient WebSocket Engine', () {
    late AppConfig config;
    late StreamController<dynamic> serverToClient;
    late StreamController<dynamic> clientToServer;
    late MockWebSocketChannel channel;

    setUp(() {
      config = const AppConfig(governorHost: '127.0.0.1', governorPort: 7700);
      serverToClient = StreamController<dynamic>();
      clientToServer = StreamController<dynamic>();
      channel = MockWebSocketChannel(serverToClient, clientToServer);
    });

    tearDown(() {
      serverToClient.close();
      clientToServer.close();
    });

    test('Transitions connection states on connect and onDone socket drop', () async {
      final client = HbpClient(config, channelFactory: (_) => channel);
      final states = <HbpConnectionState>[];
      client.connectionState.listen(states.add);

      expect(client.currentState, equals(HbpConnectionState.disconnected));

      await client.connect();
      expect(client.currentState, equals(HbpConnectionState.connected));

      // Simulate socket disconnection
      await serverToClient.close();

      // Wait brief microtask for async onDone handler to process state update
      await Future.delayed(const Duration(milliseconds: 50));
      expect(client.currentState, equals(HbpConnectionState.reconnecting));

      client.disconnect();
    });

    test('Dispatches response frame to matching transaction txId', () async {
      final client = HbpClient(config, channelFactory: (_) => channel);
      await client.connect();

      final requestFrame = HbpFrame.request('shua.governor', 'metrics.get', [1, 2, 3]);

      final responseFuture = client.send(requestFrame);

      final responseFrame = HbpFrame(
        version: 2,
        msgType: HbpMsgType.response,
        txId: requestFrame.txId,
        module: 'shua.governor',
        op: 'metrics.get',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: [10, 20, 30],
      );

      serverToClient.add(responseFrame.encode());

      final result = await responseFuture;
      expect(result.txId, equals(requestFrame.txId));
      expect(result.payload, equals([10, 20, 30]));

      client.disconnect();
    });
  });
}
