import 'dart:typed_data';

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

  /// Decode frame from MessagePack bytes (supports both rmp_serde array tuples and map frames)
  factory HbpFrame.decode(List<int> bytes) {
    try {
      final u = Unpacker(Uint8List.fromList(bytes));
      final firstByte = bytes.isNotEmpty ? bytes[0] : 0;

      // rmp_serde serializes Rust structs as MessagePack FixArray (0x90 - 0x9f)
      if ((firstByte & 0xf0) == 0x90) {
        final len = u.unpackListLength();
        final v = u.unpackInt() ?? 2;
        final t = u.unpackInt() ?? 1;
        final id = u.unpackString() ?? '';
        final mod = u.unpackString() ?? '';
        final op = u.unpackString() ?? '';
        final ts = u.unpackInt() ?? 0;
        final p = _unpackBinary(u);
        String? err;
        if (len > 7) {
          err = _unpackErrorString(u);
        }
        return HbpFrame(
          version:   v,
          msgType:   HbpMsgType.fromInt(t),
          txId:      id,
          module:    mod,
          op:        op,
          timestamp: ts,
          payload:   p,
          error:     err,
        );
      }

      // Fallback for Map encoding (0x80 - 0x8f)
      final len = u.unpackMapLength();
      final map = <String, dynamic>{};
      for (var i = 0; i < len; i++) {
        final key = u.unpackString();
        if (key == null) continue;
        map[key] = switch (key) {
          'v' || 't' || 'ts' => u.unpackInt(),
          'p'                => _unpackBinary(u),
          'err'              => _unpackErrorString(u),
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
    } catch (e) {
      // ignore: avoid_print
      print('[HBP Frame Decode Error] $e');
      rethrow;
    }
  }

  static List<int> _unpackBinary(Unpacker u) {
    try {
      return u.unpackBinary();
    } catch (_) {
      try {
        final len = u.unpackListLength();
        final list = <int>[];
        for (var i = 0; i < len; i++) {
          final val = u.unpackInt();
          if (val != null) list.add(val);
        }
        return list;
      } catch (_) {
        return [];
      }
    }
  }

  static String? _unpackErrorString(Unpacker u) {
    try {
      return u.unpackString();
    } catch (_) {
      return null;
    }
  }

  bool get isError => error != null;
  bool get isPong  => msgType == HbpMsgType.pong;
}

int _nowMs() =>
    DateTime.now().millisecondsSinceEpoch;
