import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:messagepack/messagepack.dart';
import '../../features/chat/models/chat_message.dart';
import '../hbp/hbp_client.dart';
import '../hbp/hbp_frame.dart';
import '../logging/governor_logger.dart';

/// Ollama Stream Response Chunk
class OllamaStreamChunk {
  final String content;
  final bool done;
  final double? evalTokensPerSec;
  final int? totalDurationMs;
  final AiOffloadTarget? routedNode;

  OllamaStreamChunk({
    required this.content,
    required this.done,
    this.evalTokensPerSec,
    this.totalDurationMs,
    this.routedNode,
  });
}

/// Core AI Service communicating with local Ollama endpoints with automatic Governor Fallback.
class OllamaAiService {
  final http.Client _defaultClient;
  final GovernorLogger? _logger;
  final HbpClient? _hbpClient;

  OllamaAiService({http.Client? client, GovernorLogger? logger, HbpClient? hbpClient})
      : _defaultClient = client ?? http.Client(),
        _logger = logger,
        _hbpClient = hbpClient;

  void _log(String message, [LogLevel level = LogLevel.info]) {
    _logger?.log(subsystem: 'AI_ROUTER', level: level, message: message);
  }

  /// Stream AI chat completions: Primary route through shua_governor (Port 7700),
  /// fallback to direct Ollama HTTP when RPi 5 is powered off.
  Stream<OllamaStreamChunk> streamChatCompletion({
    required AiOffloadTarget targetNode,
    required String modelName,
    required List<ChatMessage> messages,
    double temperature = 0.3,
    String? systemPrompt,
  }) async* {
    final effectiveNode = targetNode == AiOffloadTarget.auto
        ? await probeBestAvailableNode(AiOffloadTarget.rpi5)
        : targetNode;

    // 1. Primary Route: shua_governor HBP v2 WebSocket (Port 7700)
    if (_hbpClient != null) {
      if (_hbpClient.currentState != HbpConnectionState.connected) {
        try {
          await _hbpClient.connect().timeout(const Duration(seconds: 2));
        } catch (_) {}
      }

      if (_hbpClient.currentState == HbpConnectionState.connected) {
        final userPrompt = messages.lastWhere((m) => m.role == ChatRole.user, orElse: () => messages.last).content;
        final offloadUrl = effectiveNode == AiOffloadTarget.windowsHost ? 'http://127.0.0.1:11434' : '';

        _log('[HBP v2] Dispatching governor.ai.route over WebSocket (Port 7700) to shua_governor (offload: "$offloadUrl")...');

        final p = Packer();
        p.packMapLength(3);
        p.packString('prompt');              p.packString(userPrompt);
        p.packString('context_hint');        p.packString('governor');
        p.packString('offload_device_url'); p.packString(offloadUrl);

        final reqFrame = HbpFrame.request('shua.governor', 'ai.route', p.takeBytes());

        try {
          final resFrame = await _hbpClient.send(reqFrame, timeout: const Duration(seconds: 180));
          final payloadMap = _decodeHbpPayload(resFrame.payload);
          final reply = payloadMap['reply'] as String? ?? '';
          final iterations = payloadMap['iterations'] as int? ?? 1;
          final toolsCalled = (payloadMap['tools_called'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          _log('[HBP v2] shua_governor agent loop finished: $iterations turns, tools: $toolsCalled');
          yield OllamaStreamChunk(content: reply, done: true, routedNode: effectiveNode);
          return;
        } catch (e) {
          _log('[HBP v2] governor.ai.route RPC failed ($e)', LogLevel.warn);
        }
      }
    }

    // 2. Offline Fallback: Direct Ollama HTTP completion when RPi 5 is offline
    _log('Falling back to direct HTTP stream on ${effectiveNode.shortLabel} (model: $modelName)');
    final baseUrl = await resolveWorkingBaseUrl(effectiveNode) ?? effectiveNode.baseUrl;
    final httpBaseUrl = baseUrl.contains(':7700') ? baseUrl.replaceAll(':7700', ':11434') : baseUrl;
    final uri = Uri.parse('$httpBaseUrl/api/chat');

    final formattedMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      formattedMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final msg in messages) {
      if (msg.role != ChatRole.system) {
        formattedMessages.add({'role': msg.role == ChatRole.user ? 'user' : 'assistant', 'content': msg.content});
      }
    }

    final payload = jsonEncode({
      'model': modelName,
      'messages': formattedMessages,
      'options': {'temperature': temperature, 'num_ctx': 8192},
      'stream': true,
    });

    final requestClient = http.Client();
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    try {
      final response = await requestClient.send(request).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        await for (final line in response.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          if (line.trim().isEmpty) continue;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final done = json['done'] as bool? ?? false;
            final messageObj = json['message'] as Map<String, dynamic>?;
            final content = messageObj?['content'] as String? ?? '';
            if (content.isNotEmpty || done) {
              yield OllamaStreamChunk(content: content, done: done, routedNode: effectiveNode);
            }
          } catch (_) {}
        }
        requestClient.close();
        return;
      }
    } catch (e) {
      _log('Direct HTTP stream failed: $e', LogLevel.warn);
    }
    requestClient.close();

    yield OllamaStreamChunk(content: '[Governor Alert: Neither RPi 5 nor Windows Host is reachable.]\n', done: true);
  }

  Future<String?> resolveWorkingBaseUrl(AiOffloadTarget node) async {
    final futures = node.candidateUrls.map((candidate) async {
      try {
        final pingUrl = candidate.contains(':7700') ? candidate.replaceAll(':7700', ':11434') : candidate;
        final res = await _defaultClient.get(Uri.parse('$pingUrl/api/tags')).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) return candidate;
      } catch (_) {}
      return null;
    });
    final results = await Future.wait(futures);
    return results.whereType<String>().firstOrNull;
  }

  Future<AiOffloadTarget> probeBestAvailableNode(AiOffloadTarget preferred) async {
    if (await resolveWorkingBaseUrl(preferred) != null) return preferred;
    final other = preferred == AiOffloadTarget.rpi5 ? AiOffloadTarget.windowsHost : AiOffloadTarget.rpi5;
    if (await resolveWorkingBaseUrl(other) != null) return other;
    return preferred;
  }

  Future<List<String>> fetchInstalledModels(AiOffloadTarget targetNode) async {
    final activeNode = await probeBestAvailableNode(targetNode);
    final baseUrl = (await resolveWorkingBaseUrl(activeNode)) ?? activeNode.baseUrl;
    try {
      final res = await _defaultClient.get(Uri.parse('$baseUrl/api/tags')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        final names = models.map((m) => m['name'].toString()).toList();
        if (names.isNotEmpty) return names;
      }
    } catch (_) {}
    return ['qwen2.5-coder:7b', 'qwen2.5:3b', 'qwen2.5:1.5b', 'llama3.1:8b'];
  }

  static Map<String, dynamic> _decodeHbpPayload(List<int> bytes) {
    if (bytes.isEmpty) return {};

    try {
      final str = utf8.decode(bytes);
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {}

    try {
      final u = Unpacker(Uint8List.fromList(bytes));
      final len = u.unpackMapLength();
      final map = <String, dynamic>{};
      for (var i = 0; i < len; i++) {
        final key = u.unpackString();
        if (key == null) continue;
        try {
          map[key] = u.unpackString();
        } catch (_) {
          try {
            map[key] = u.unpackInt();
          } catch (_) {
            try {
              map[key] = u.unpackMap();
            } catch (_) {}
          }
        }
      }
      return map;
    } catch (_) {}

    return {};
  }
}
