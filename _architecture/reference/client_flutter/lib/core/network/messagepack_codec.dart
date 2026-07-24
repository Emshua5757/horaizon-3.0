import 'dart:typed_data';
import 'package:msgpack_dart/msgpack_dart.dart';

/// A utility class for handling HorAIzon Binary Protocol (HBP) serialization.
class MessagePackCodec {
  /// Encodes a dynamic payload into a compressed MessagePack binary stream.
  static Uint8List encode(dynamic payload) {
    return serialize(payload);
  }

  /// Decodes a MessagePack binary stream back into a dynamic payload.
  static dynamic decode(Uint8List bytes) {
    return deserialize(bytes);
  }
}
