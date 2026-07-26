import 'package:flutter_test/flutter_test.dart';
import 'package:client_flutter/core/hbp/hbp_frame.dart';

void main() {
  group('HbpFrame Codec & Factories', () {
    test('Encodes and decodes request frame payload integrity', () {
      final payload = [0x01, 0x02, 0x03, 0x04];
      final original = HbpFrame.request('shua.resume', 'compile', payload);

      final bytes = original.encode();
      final decoded = HbpFrame.decode(bytes);

      expect(decoded.version, equals(2));
      expect(decoded.msgType, equals(HbpMsgType.request));
      expect(decoded.txId, equals(original.txId));
      expect(decoded.module, equals('shua.resume'));
      expect(decoded.op, equals('compile'));
      expect(decoded.payload, equals(payload));
      expect(decoded.error, isNull);
    });

    test('Encodes and decodes ping/pong frame', () {
      final ping = HbpFrame.ping();
      final bytes = ping.encode();
      final decoded = HbpFrame.decode(bytes);

      expect(decoded.msgType, equals(HbpMsgType.ping));
      expect(decoded.module, equals('shua.governor'));
      expect(decoded.op, equals('ping'));
    });

    test('Handles error frame with error string', () {
      final frame = HbpFrame(
        version: 2,
        msgType: HbpMsgType.error,
        txId: 'tx-12345',
        module: 'shua.governor',
        op: 'process.kill',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        payload: [],
        error: 'Permission denied: cgroups v2 restriction',
      );

      final bytes = frame.encode();
      final decoded = HbpFrame.decode(bytes);

      expect(decoded.isError, isTrue);
      expect(decoded.error, equals('Permission denied: cgroups v2 restriction'));
    });

    test('Parses all 6 msgTypes cleanly from integer value', () {
      expect(HbpMsgType.fromInt(1), equals(HbpMsgType.request));
      expect(HbpMsgType.fromInt(2), equals(HbpMsgType.response));
      expect(HbpMsgType.fromInt(3), equals(HbpMsgType.event));
      expect(HbpMsgType.fromInt(4), equals(HbpMsgType.ping));
      expect(HbpMsgType.fromInt(5), equals(HbpMsgType.pong));
      expect(HbpMsgType.fromInt(6), equals(HbpMsgType.error));
    });
  });
}
