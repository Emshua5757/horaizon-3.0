// ignore_for_file: avoid_print
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

// IMPORTANT: We use relative pathing here so the test runner doesn't get confused
// by the package name if it differs slightly during development.
import 'package:client_flutter/core/network/messagepack_codec.dart';

void main() {
  group('MessagePack Codec Integration Tests', () {
    test('Should serialize and deserialize an SDUI Map flawlessly', () {
      // 1. Setup a mock SDUI JSON payload (similar to what the Pi 5 sends)
      final Map<String, dynamic> mockPayload = {
        'type': 'Column',
        'children': [
          {'type': 'Text', 'value': 'horAIzon 2.0'},
          {'type': 'Gauge', 'value': 76.5},
        ],
      };

      // 2. Attempt Serialization
      final Uint8List binaryStream = MessagePackCodec.encode(mockPayload);

      // 3. Prove it compiled into bytes
      expect(
        binaryStream.isNotEmpty,
        true,
        reason: "The byte stream is empty. Serialization failed.",
      );
      print(
        'Mathematical Compression: Payload compressed to ${binaryStream.length} bytes.',
      );

      // 4. Attempt Deserialization
      final decodedPayload = MessagePackCodec.decode(binaryStream);

      // 5. Assert Data Integrity
      expect(
        decodedPayload['type'],
        'Column',
        reason: "The root type did not survive deserialization.",
      );
      expect(
        (decodedPayload['children'] as List).length,
        2,
        reason: "The children array length is incorrect.",
      );
      expect(
        (decodedPayload['children'][1])['value'],
        76.5,
        reason: "The gauge float value was corrupted.",
      );
    });
  });
}
