import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:messagepack/messagepack.dart';

void main() {
  test('Decode exact Rust LogEntry MsgPack Map Payload in Flutter', () {
    // Exact byte payload exported by Rust unit test `test_log_entry_msgpack_map_encoding`
    final rustPayloadBytes = Uint8List.fromList([
      137, 162, 116, 115, 207, 0, 0, 1, 139, 207, 229, 104, 0, 165, 108, 101,
      118, 101, 108, 3, 166, 109, 111, 100, 117, 108, 101, 10, 169, 115, 117, 98,
      115, 121, 115, 116, 101, 109, 171, 104, 98, 112, 95, 104, 97, 110, 100, 108,
      101, 114, 163, 109, 115, 103, 185, 114, 101, 115, 117, 109, 101, 46, 99,
      111, 109, 112, 105, 108, 101, 32, 100, 105, 115, 112, 97, 116, 99, 104, 101,
      100, 164, 116, 97, 103, 115, 1, 171, 99, 117, 115, 116, 111, 109, 95, 116,
      97, 103, 115, 192, 169, 116, 101, 108, 101, 109, 101, 116, 114, 121, 192,
      168, 116, 114, 97, 99, 101, 95, 105, 100, 192
    ]);

    final u = Unpacker(rustPayloadBytes);
    final map = u.unpackMap();

    expect(map, isNotNull);
    expect(map['subsystem'], equals('hbp_handler'));
    expect(map['msg'], equals('resume.compile dispatched'));
    expect(map['level'], equals(3));
    expect(map['module'], equals(10));
  });
}
