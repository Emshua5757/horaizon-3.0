import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../features/chat/models/chat_message.dart';

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

  OllamaAiService({http.Client? client}) : _defaultClient = client ?? http.Client();

  /// Stream AI chat responses with automatic Governor fallback routing between RPi 5 and Windows Host
  Stream<OllamaStreamChunk> streamChatCompletion({
    required AiOffloadTarget targetNode,
    required String modelName,
    required List<ChatMessage> messages,
    double temperature = 0.3,
    String? systemPrompt,
  }) async* {
    final effectiveNode = targetNode == AiOffloadTarget.auto
        ? await probeBestAvailableNode(AiOffloadTarget.windowsHost)
        : targetNode;

    // Attempt Primary Target Node
    final primaryResult = await _tryStreamNode(
      node: effectiveNode,
      modelName: modelName,
      messages: messages,
      temperature: temperature,
      systemPrompt: systemPrompt,
    );

    if (primaryResult != null) {
      yield* primaryResult;
      return;
    }

    // Governor Automatic Failover to Alternative Node
    final fallbackNode = effectiveNode == AiOffloadTarget.rpi5
        ? AiOffloadTarget.windowsHost
        : AiOffloadTarget.rpi5;

    final fallbackResult = await _tryStreamNode(
      node: fallbackNode,
      modelName: modelName,
      messages: messages,
      temperature: temperature,
      systemPrompt: systemPrompt,
    );

    if (fallbackResult != null) {
      yield OllamaStreamChunk(
        content: '[Governor Auto-Route: Target ${targetNode.shortLabel} offline → Switched to ${fallbackNode.shortLabel}]\n\n',
        done: false,
        routedNode: fallbackNode,
      );
      yield* fallbackResult;
      return;
    }

    // Both Nodes Offline Guidance
    yield OllamaStreamChunk(
      content: '[Governor Alert: Neither RPi 5 (100.67.11.0:11434) nor Windows Host (127.0.0.1:11434) is currently running Ollama.\n'
          'To start Ollama:\n'
          '• On Windows: Run "ollama serve" in PowerShell or start the Ollama desktop app.\n'
          '• On RPi 5: Run "sudo systemctl start ollama" via SSH.]\n',
      done: true,
    );
  }

  Future<Stream<OllamaStreamChunk>?> _tryStreamNode({
    required AiOffloadTarget node,
    required String modelName,
    required List<ChatMessage> messages,
    required double temperature,
    String? systemPrompt,
  }) async {
    final baseUrl = await resolveWorkingBaseUrl(node);
    if (baseUrl == null) return null;

    final uri = Uri.parse('$baseUrl/api/chat');

    final formattedMessages = <Map<String, dynamic>>[];
    if (systemPrompt != null && systemPrompt.isNotEmpty) {
      formattedMessages.add({'role': 'system', 'content': systemPrompt});
    }

    for (final msg in messages) {
      if (msg.role != ChatRole.system) {
        formattedMessages.add({
          'role': msg.role == ChatRole.user ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    final payload = jsonEncode({
      'model': modelName,
      'messages': formattedMessages,
      'options': {
        'temperature': temperature,
        'num_ctx': 8192,
      },
      'stream': true,
    });

    final requestClient = http.Client();
    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..body = payload;

    http.StreamedResponse response;
    try {
      // Allow up to 30s for cold-start GGUF model layer allocation in VRAM
      response = await requestClient.send(request).timeout(const Duration(seconds: 30));
    } catch (_) {
      requestClient.close();
      return null;
    }

    if (response.statusCode != 200) {
      requestClient.close();
      return null;
    }

    late StreamSubscription lineSub;
    late StreamController<OllamaStreamChunk> controller;

    controller = StreamController<OllamaStreamChunk>(
      onCancel: () {
        lineSub.cancel();
        requestClient.close();
      },
    );

    lineSub = response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        if (controller.isClosed) return;
        if (line.trim().isEmpty) return;
        try {
          final json = jsonDecode(line) as Map<String, dynamic>;
          final done = json['done'] as bool? ?? false;
          final messageObj = json['message'] as Map<String, dynamic>?;
          final mainContent = messageObj?['content'] as String? ?? '';
          final thinkingContent = messageObj?['reasoning_content'] as String? ??
              messageObj?['thinking'] as String? ??
              json['thinking'] as String? ??
              '';
          final content = mainContent.isNotEmpty
              ? mainContent
              : (thinkingContent.isNotEmpty ? thinkingContent : '');

          double? tokPerSec;
          int? durationMs;

          if (done) {
            final totalDurationNs = json['total_duration'] as int? ?? 0;
            final evalCount = json['eval_count'] as int? ?? 0;
            final evalDurationNs = json['eval_duration'] as int? ?? 0;

            if (totalDurationNs > 0) {
              durationMs = totalDurationNs ~/ 1000000;
            }
            if (evalCount > 0 && evalDurationNs > 0) {
              tokPerSec = (evalCount / (evalDurationNs / 1e9));
            }
          }

          if (!controller.isClosed) {
            controller.add(OllamaStreamChunk(
              content: content,
              done: done,
              evalTokensPerSec: tokPerSec,
              totalDurationMs: durationMs,
              routedNode: node,
            ));
          }

          if (done && !controller.isClosed) {
            controller.close();
            requestClient.close();
          }
        } catch (_) {}
      },
      onError: (e) {
        if (!controller.isClosed) controller.close();
        requestClient.close();
      },
      onDone: () {
        if (!controller.isClosed) controller.close();
        requestClient.close();
      },
    );

    return controller.stream;
  }

  /// Probe candidate URLs for target node (LAN IP primary, Tailscale IP secondary)
  Future<String?> resolveWorkingBaseUrl(AiOffloadTarget node) async {
    for (final candidate in node.candidateUrls) {
      try {
        final res = await _defaultClient.get(Uri.parse('$candidate/api/tags')).timeout(const Duration(milliseconds: 800));
        if (res.statusCode == 200) return candidate;
      } catch (_) {}
    }
    return null;
  }

  /// Probe active Ollama endpoint and return available node or fallback
  Future<AiOffloadTarget> probeBestAvailableNode(AiOffloadTarget preferred) async {
    if (await _pingNode(preferred)) return preferred;
    final other = preferred == AiOffloadTarget.rpi5 ? AiOffloadTarget.windowsHost : AiOffloadTarget.rpi5;
    if (await _pingNode(other)) return other;
    return preferred;
  }

  Future<bool> _pingNode(AiOffloadTarget node) async {
    final url = await resolveWorkingBaseUrl(node);
    return url != null;
  }

  /// Query installed models on target node (`GET /api/tags`)
  Future<List<String>> fetchInstalledModels(AiOffloadTarget targetNode) async {
    final activeNode = await probeBestAvailableNode(targetNode);
    final baseUrl = await resolveWorkingBaseUrl(activeNode) ?? activeNode.baseUrl;
    try {
      final res = await _defaultClient.get(Uri.parse('$baseUrl/api/tags')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final models = data['models'] as List<dynamic>? ?? [];
        final names = models.map((m) => m['name'].toString()).toList();
        if (names.isNotEmpty) return names;
      }
    } catch (_) {}

    return const [
      'qwen2.5-coder:7b',
      'qwen2.5:3b',
      'qwen2.5:1.5b',
      'llama3.1:8b',
    ];
  }
}
