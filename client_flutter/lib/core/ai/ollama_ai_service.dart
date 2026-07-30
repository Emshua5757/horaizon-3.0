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
  /// Agent loop steps for N-turn visibility in the UI.
  final List<AgentLoopStep> steps;

  OllamaStreamChunk({
    required this.content,
    required this.done,
    this.evalTokensPerSec,
    this.totalDurationMs,
    this.routedNode,
    this.steps = const [],
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
    String? sessionId,
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

        _log('[HBP v2] Dispatching governor.ai.route to shua_governor (target: ${effectiveNode.shortLabel}, offload: "$offloadUrl", prompt: "$userPrompt")...');

        final p = Packer();
        p.packMapLength(5);
        p.packString('prompt');              p.packString(userPrompt);
        p.packString('context_hint');        p.packString('governor');
        p.packString('offload_device_url'); p.packString(offloadUrl);
        p.packString('model');              p.packString(modelName);
        p.packString('session_id');         p.packString(sessionId ?? '');

        final reqFrame = HbpFrame.request('shua.governor', 'ai.route', p.takeBytes());

        try {
          final resFrame = await _hbpClient.send(reqFrame, timeout: const Duration(seconds: 180));
          final payloadMap = _decodeHbpPayload(resFrame.payload);
          final reply = payloadMap['reply'] as String? ?? '';
          final iterations = payloadMap['iterations'] as int? ?? 1;
          final toolsCalled = (payloadMap['tools_called'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          // ── Parse agent loop steps for N-turn UI ──────────────
          final stepsRaw = payloadMap['steps'] as List<dynamic>? ?? [];
          final steps = stepsRaw
              .whereType<Map<String, dynamic>>()
              .map((s) => AgentLoopStep.fromMap(s))
              .toList();

          // ── Telemetry: log decode result for debugging ──────────────
          if (reply.isEmpty) {
            _log('[HBP v2] WARNING: decoded reply is EMPTY — payloadMap keys=${payloadMap.keys.toList()}, payload bytes=${resFrame.payload.length}', LogLevel.warn);
          } else {
            final replyPreview = reply.length > 80 ? '${reply.substring(0, 80)}...' : reply;
            _log('[HBP v2] shua_governor agent loop finished ($iterations turns, tools: $toolsCalled, steps: ${steps.length}): $replyPreview');
          }

          yield OllamaStreamChunk(content: reply, done: true, routedNode: effectiveNode, steps: steps);
          return;
        } catch (e) {
          _log('[HBP v2] governor.ai.route RPC failed ($e)', LogLevel.warn);
        }
      }
    }

    // 2. Offline Fallback: Direct Ollama HTTP completion when RPi 5 is offline
    _log('HBP unavailable — falling back to direct HTTP stream on ${effectiveNode.shortLabel} (model: $modelName)', LogLevel.warn);
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
    return ['qwen3.5:4b', 'qwen3.5:2b', 'qwen2.5-coder:7b', 'qwen2.5:3b', 'qwen2.5:1.5b', 'llama3.1:8b'];
  }

  static Map<String, dynamic> _decodeHbpPayload(List<int> bytes) {
    if (bytes.isEmpty) return {};

    // 1. Try plain UTF-8 JSON first (defensive fallback)
    try {
      final str = utf8.decode(bytes);
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (_) {}

    // 2. MessagePack — recursive typed decode matching rmp_serde named-field output
    try {
      final raw = Uint8List.fromList(bytes);
      final cursor = _Cursor(0);
      final result = _unpackValue(raw, cursor);
      if (result is Map<String, dynamic>) return result;
    } catch (_) {}

    return {};
  }

  /// Recursive MessagePack value decoder that reads the type discriminator byte
  /// directly from [raw] at [cursor.pos] before dispatching to Unpacker.
  static dynamic _unpackValue(Uint8List raw, _Cursor cursor) {
    if (cursor.pos >= raw.length) return null;
    final tag = raw[cursor.pos];

    // nil (0xc0 is always exactly 1 byte)
    if (tag == 0xc0) {
      cursor.pos += 1;
      return null;
    }

    // bool false / true
    if (tag == 0xc2 || tag == 0xc3) {
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackBool();
      cursor.pos += 1;
      return val;
    }

    // fixstr (0xa0–0xbf)
    if (tag >= 0xa0 && tag <= 0xbf) {
      final strLen = tag & 0x1f;
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackString();
      cursor.pos += 1 + strLen;
      return val;
    }

    // str8 (0xd9) / str16 (0xda) / str32 (0xdb)
    if (tag == 0xd9) {
      final strLen = raw[cursor.pos + 1];
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackString();
      cursor.pos += 2 + strLen;
      return val;
    }
    if (tag == 0xda) {
      final strLen = (raw[cursor.pos + 1] << 8) | raw[cursor.pos + 2];
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackString();
      cursor.pos += 3 + strLen;
      return val;
    }
    if (tag == 0xdb) {
      final strLen = (raw[cursor.pos + 1] << 24) | (raw[cursor.pos + 2] << 16) |
                     (raw[cursor.pos + 3] << 8)  |  raw[cursor.pos + 4];
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackString();
      cursor.pos += 5 + strLen;
      return val;
    }

    // bin8 (0xc4) / bin16 (0xc5) / bin32 (0xc6)
    if (tag == 0xc4) {
      final binLen = raw[cursor.pos + 1];
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackBinary();
      cursor.pos += 2 + binLen;
      return val;
    }
    if (tag == 0xc5) {
      final binLen = (raw[cursor.pos + 1] << 8) | raw[cursor.pos + 2];
      final u = Unpacker(raw.sublist(cursor.pos));
      final val = u.unpackBinary();
      cursor.pos += 3 + binLen;
      return val;
    }

    // fixarray (0x90–0x9f) — rmp_serde uses this for structs in array mode
    if (tag >= 0x90 && tag <= 0x9f) {
      final count = tag & 0x0f;
      cursor.pos += 1;
      // Try to decode as a top-level map (rmp_serde struct-as-array)
      // For the ai.route reply this is always a map, not an array
      return List.generate(count, (_) => _unpackValue(raw, cursor));
    }

    // fixmap (0x80–0x8f)
    if (tag >= 0x80 && tag <= 0x8f) {
      final count = tag & 0x0f;
      cursor.pos += 1;
      final map = <String, dynamic>{};
      for (var i = 0; i < count; i++) {
        final key = _unpackValue(raw, cursor)?.toString() ?? '';
        map[key] = _unpackValue(raw, cursor);
      }
      return map;
    }

    // map16 (0xde)
    if (tag == 0xde) {
      final count = (raw[cursor.pos + 1] << 8) | raw[cursor.pos + 2];
      cursor.pos += 3;
      final map = <String, dynamic>{};
      for (var i = 0; i < count; i++) {
        final key = _unpackValue(raw, cursor)?.toString() ?? '';
        map[key] = _unpackValue(raw, cursor);
      }
      return map;
    }

    // array16 (0xdc)
    if (tag == 0xdc) {
      final count = (raw[cursor.pos + 1] << 8) | raw[cursor.pos + 2];
      cursor.pos += 3;
      return List.generate(count, (_) => _unpackValue(raw, cursor));
    }

    // positive fixint (0x00–0x7f)
    if (tag <= 0x7f) {
      cursor.pos += 1;
      return tag;
    }

    // negative fixint (0xe0–0xff)
    if (tag >= 0xe0) {
      cursor.pos += 1;
      return tag - 256;
    }

    // uint8 (0xcc)
    if (tag == 0xcc) { cursor.pos += 2; return raw[cursor.pos - 1]; }
    // uint16 (0xcd)
    if (tag == 0xcd) { cursor.pos += 3; return (raw[cursor.pos - 2] << 8) | raw[cursor.pos - 1]; }
    // uint32 (0xce)
    if (tag == 0xce) { cursor.pos += 5; return (raw[cursor.pos - 4] << 24) | (raw[cursor.pos - 3] << 16) | (raw[cursor.pos - 2] << 8) | raw[cursor.pos - 1]; }
    // int8 (0xd0)
    if (tag == 0xd0) { final v = raw[cursor.pos + 1]; cursor.pos += 2; return v >= 128 ? v - 256 : v; }
    // int16 (0xd1)
    if (tag == 0xd1) { final v = (raw[cursor.pos + 1] << 8) | raw[cursor.pos + 2]; cursor.pos += 3; return v >= 32768 ? v - 65536 : v; }
    // int32 (0xd2)
    if (tag == 0xd2) {
      final v = (raw[cursor.pos + 1] << 24) | (raw[cursor.pos + 2] << 16) | (raw[cursor.pos + 3] << 8) | raw[cursor.pos + 4];
      cursor.pos += 5;
      return v;
    }

    // float32 (0xca) / float64 (0xcb) — treat as int for our use case
    if (tag == 0xca) { cursor.pos += 5; return null; }
    if (tag == 0xcb) { cursor.pos += 9; return null; }

    // Unknown: skip one byte
    cursor.pos += 1;
    return null;
  }
}

/// Simple mutable position cursor for [_unpackValue]
class _Cursor {
  int pos;
  _Cursor(this.pos);
}
