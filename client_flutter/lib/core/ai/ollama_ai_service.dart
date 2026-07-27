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
        ? await probeBestAvailableNode(AiOffloadTarget.rpi5)
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

  /// Probe candidate URLs concurrently (Tailscale 100.67.11.0 & LAN IP) for instant node resolution
  Future<String?> resolveWorkingBaseUrl(AiOffloadTarget node) async {
    final futures = node.candidateUrls.map((candidate) async {
      try {
        final pingUrl = candidate.contains(':7700')
            ? candidate.replaceAll(':7700', ':11434')
            : candidate;
        final res = await _defaultClient.get(Uri.parse('$pingUrl/api/tags')).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) return candidate;
      } catch (_) {}
      return null;
    });

    final results = await Future.wait(futures);
    for (final res in results) {
      if (res != null) return res;
    }
    return null;
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
      'tools': _governorTools,
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
          final toolCallsObj = messageObj?['tool_calls'] as List<dynamic>?;

          String toolCallText = '';
          if (toolCallsObj != null && toolCallsObj.isNotEmpty) {
            for (final tc in toolCallsObj) {
              final fn = tc['function'] as Map<String, dynamic>?;
              final name = fn?['name'] as String? ?? 'tool';
              final args = fn?['arguments'] as Map<String, dynamic>? ?? {};
              toolCallText += '\n\n🛠️ **[MCP Tool Invoked]**: `$name(${jsonEncode(args)})`\n\n';
            }
          }

          final content = toolCallText.isNotEmpty
              ? toolCallText
              : (mainContent.isNotEmpty
                  ? mainContent
                  : (thinkingContent.isNotEmpty ? thinkingContent : ''));

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

  static final List<Map<String, dynamic>> _governorTools = [
    {
      'type': 'function',
      'function': {
        'name': 'governor_get_metrics',
        'description': 'Fetches real-time Raspberry Pi 5 CPU usage %, RAM allocation, system temperature, disk usage, and active microservice module process statuses.',
        'parameters': {
          'type': 'object',
          'properties': {},
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'governor_query_logs',
        'description': 'Queries recent system logs, errors, telemetry metrics, and subsystem trace events from governor database (activity.db).',
        'parameters': {
          'type': 'object',
          'properties': {
            'subsystem': {'type': 'string'},
            'limit': {'type': 'integer'},
          },
          'required': [],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'governor_wake_module',
        'description': 'Resumes a sleeping microservice module on Raspberry Pi 5.',
        'parameters': {
          'type': 'object',
          'properties': {
            'module_name': {
              'type': 'string',
              'enum': ['shua.diary', 'shua.code_visualizer', 'shua.resume', 'shua.gym', 'shua.crypto'],
            },
          },
          'required': ['module_name'],
        },
      },
    },
    {
      'type': 'function',
      'function': {
        'name': 'governor_sleep_module',
        'description': 'Pauses a running microservice module on Raspberry Pi 5 to free RAM and CPU.',
        'parameters': {
          'type': 'object',
          'properties': {
            'module_name': {
              'type': 'string',
              'enum': ['shua.diary', 'shua.code_visualizer', 'shua.resume', 'shua.gym', 'shua.crypto'],
            },
          },
          'required': ['module_name'],
        },
      },
    },
  ];
}
