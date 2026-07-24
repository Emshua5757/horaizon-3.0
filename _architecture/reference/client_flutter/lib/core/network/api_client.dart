import 'package:client_flutter/core/network/messagepack_codec.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  Future<Map<String, dynamic>> postBinary(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final response = await http.post(
      Uri.parse(endpoint),
      body: MessagePackCodec.encode(payload),
      headers: {'Content-Type': 'application/msgPack'},
    );
    return MessagePackCodec.decode(response.bodyBytes);
  }
}
