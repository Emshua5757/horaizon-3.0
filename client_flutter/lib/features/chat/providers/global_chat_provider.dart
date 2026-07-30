import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/ai/ollama_ai_service.dart';
import '../../../core/hbp/hbp_client_provider.dart';
import '../../../core/logging/governor_logger.dart';
import '../models/chat_message.dart';

class GlobalChatState {
  final List<ChatMessage> messages;
  final String selectedModel;
  final AiOffloadTarget offloadTarget;
  final double temperature;
  final bool isGenerating;
  final List<String> availableModels;
  final String systemPrompt;

  const GlobalChatState({
    required this.messages,
    this.selectedModel = 'qwen3.5:4b',
    this.offloadTarget = AiOffloadTarget.auto,
    this.temperature = 0.3,
    this.isGenerating = false,
    this.availableModels = const [
      'qwen3.5:4b',
      'qwen3.5:2b',
      'qwen2.5-coder:7b',
      'qwen2.5:3b',
      'qwen2.5:1.5b',
      'llama3.1:8b',
    ],
    this.systemPrompt =
        'You are JOSH, the horAIzon 3.0 Central AI Assistant running on Raspberry Pi 5 / Windows Host Offload.',
  });

  /// Helper returning the last user prompt and assistant response pair for mini-chat preview widgets
  (ChatMessage?, ChatMessage?) get lastExchange {
    if (messages.isEmpty) return (null, null);
    ChatMessage? lastUser;
    ChatMessage? lastAssistant;

    for (int i = messages.length - 1; i >= 0; i--) {
      if (lastAssistant == null && messages[i].role == ChatRole.assistant) {
        lastAssistant = messages[i];
      } else if (lastUser == null && messages[i].role == ChatRole.user) {
        lastUser = messages[i];
      }
      if (lastUser != null && lastAssistant != null) break;
    }
    return (lastUser, lastAssistant);
  }

  GlobalChatState copyWith({
    List<ChatMessage>? messages,
    String? selectedModel,
    AiOffloadTarget? offloadTarget,
    double? temperature,
    bool? isGenerating,
    List<String>? availableModels,
    String? systemPrompt,
  }) {
    return GlobalChatState(
      messages: messages ?? this.messages,
      selectedModel: selectedModel ?? this.selectedModel,
      offloadTarget: offloadTarget ?? this.offloadTarget,
      temperature: temperature ?? this.temperature,
      isGenerating: isGenerating ?? this.isGenerating,
      availableModels: availableModels ?? this.availableModels,
      systemPrompt: systemPrompt ?? this.systemPrompt,
    );
  }
}

class GlobalChatNotifier extends StateNotifier<GlobalChatState> {
  final OllamaAiService _aiService;
  final GovernorLogger? _logger;
  StreamSubscription<OllamaStreamChunk>? _streamSub;
  /// One global session ID per app lifetime. Generated once on first construction
  /// and passed with every ai.route request so shua_governor can persist and
  /// restore conversation context from the SQLite chat_history table.
  final String _sessionId = const Uuid().v4();

  GlobalChatNotifier(this._aiService, [this._logger])
      : super(GlobalChatState(
          messages: [
            ChatMessage(
              id: 'init_welcome',
              role: ChatRole.assistant,
              content:
                  'Hello Joshua! I am JOSH, your horAIzon 3.0 Central AI Assistant. How can I assist your workflow today?',
              timestamp: DateTime.now(),
              modelName: 'qwen3.5:4b',
              offloadTarget: AiOffloadTarget.auto,
            ),
          ],
        )) {
    refreshAvailableModels();
  }

  Future<void> refreshAvailableModels() async {
    final rawModels =
        await _aiService.fetchInstalledModels(state.offloadTarget);
    final models = rawModels.toSet().toList();
    if (!mounted) return;
    if (models.isNotEmpty) {
      state = state.copyWith(
        availableModels: models,
        selectedModel: models.contains(state.selectedModel)
            ? state.selectedModel
            : models.first,
      );
    }
  }

  void setOffloadTarget(AiOffloadTarget target) {
    state = state.copyWith(offloadTarget: target);
    _logger?.log(
      subsystem: 'AI_ROUTER',
      level: LogLevel.info,
      message: 'Offload target switched to ${target.displayName}',
    );
    refreshAvailableModels();
  }

  void setSelectedModel(String model) {
    state = state.copyWith(selectedModel: model);
    _logger?.log(
      subsystem: 'AI_ROUTER',
      level: LogLevel.info,
      message: 'Active AI model changed to $model',
    );
  }

  void setTemperature(double temp) {
    state = state.copyWith(temperature: temp);
  }

  void clearHistory() {
    _streamSub?.cancel();
    state = state.copyWith(
      messages: [],
      isGenerating: false,
    );
    _logger?.log(
      subsystem: 'AI_CHAT',
      level: LogLevel.info,
      message: 'Chat history cleared by user',
    );
  }

  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isGenerating) return;

    _logger?.log(
      subsystem: 'AI_CHAT',
      level: LogLevel.info,
      message: 'User prompt sent to JOSH ($trimmed)',
      metadata: {
        'model': state.selectedModel,
        'target': state.offloadTarget.shortLabel,
      },
    );

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: ChatRole.user,
      content: trimmed,
      timestamp: DateTime.now(),
      modelName: state.selectedModel,
      offloadTarget: state.offloadTarget,
    );

    final assistantMsgId = '${DateTime.now().millisecondsSinceEpoch}_assistant';
    final initialAssistantMsg = ChatMessage(
      id: assistantMsgId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      modelName: state.selectedModel,
      offloadTarget: state.offloadTarget,
      isStreaming: true,
    );

    final updatedMessages = [
      ...state.messages,
      userMessage,
      initialAssistantMsg
    ];
    state = state.copyWith(
      messages: updatedMessages,
      isGenerating: true,
    );

    final stream = _aiService.streamChatCompletion(
      targetNode: state.offloadTarget,
      modelName: state.selectedModel,
      messages: updatedMessages.where((m) => m.id != assistantMsgId).toList(),
      temperature: state.temperature,
      systemPrompt: state.systemPrompt,
      sessionId: _sessionId,
    );

    var currentContent = '';
    var chunkCount = 0;
    _streamSub = stream.listen(
      (chunk) {
        currentContent += chunk.content;
        chunkCount++;
        final targetNode = chunk.routedNode ?? state.offloadTarget;

        if (chunk.routedNode != null &&
            chunk.routedNode != state.offloadTarget) {
          _logger?.log(
            subsystem: 'AI_ROUTER',
            level: LogLevel.warn,
            message:
                'Primary node offline, auto-routed to ${chunk.routedNode!.shortLabel}',
          );
        }

        final newMessages = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(
              content: currentContent,
              offloadTarget: targetNode,
              isStreaming: !chunk.done,
              evalTokensPerSec: chunk.evalTokensPerSec ?? m.evalTokensPerSec,
              totalDurationMs: chunk.totalDurationMs ?? m.totalDurationMs,
              steps: chunk.steps.isNotEmpty ? chunk.steps : m.steps,
            );
          }
          return m;
        }).toList();

        state = state.copyWith(
          messages: newMessages,
          offloadTarget: targetNode,
          isGenerating: !chunk.done,
        );

        if (chunk.done) {
          // ── Telemetry: log full reply preview + stats ──────────────
          final replyPreview = currentContent.length > 120
              ? '${currentContent.substring(0, 120)}…'
              : currentContent;
          final tokStr = chunk.evalTokensPerSec?.toStringAsFixed(1) ?? 'N/A';
          final durationStr = chunk.totalDurationMs != null
              ? '${chunk.totalDurationMs}ms'
              : 'N/A';
          _logger?.log(
            subsystem: 'AI_CHAT',
            level: LogLevel.info,
            message: 'JOSH reply ($tokStr tok/s, $durationStr, $chunkCount chunks): $replyPreview',
            metadata: {
              'model': state.selectedModel,
              'target': targetNode.shortLabel,
              'chunks': chunkCount,
              'reply_chars': currentContent.length,
              'eval_toks_per_s': tokStr,
              'duration_ms': chunk.totalDurationMs ?? 0,
            },
          );
        }
      },
      onError: (e) {
        _logger?.log(
          subsystem: 'AI_CHAT',
          level: LogLevel.error,
          message: 'AI stream error after $chunkCount chunks — $e',
          metadata: {
            'model': state.selectedModel,
            'target': state.offloadTarget.shortLabel,
            'partial_chars': currentContent.length,
            'chunks_received': chunkCount,
          },
        );

        final newMessages = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(
              content: '$currentContent\n[Error: $e]',
              isStreaming: false,
            );
          }
          return m;
        }).toList();

        state = state.copyWith(
          messages: newMessages,
          isGenerating: false,
        );
      },
      onDone: () {
        // Guard: if stream ended but no done chunk was received (0-reply edge case)
        if (currentContent.isEmpty && chunkCount == 0) {
          _logger?.log(
            subsystem: 'AI_CHAT',
            level: LogLevel.warn,
            message: 'Stream closed with 0 chunks — reply may be empty. Check HBP payload decode or governor ai.route handler.',
            metadata: {'model': state.selectedModel, 'target': state.offloadTarget.shortLabel},
          );
        }
        state = state.copyWith(isGenerating: false);
      },
    );
  }

  void stopGeneration() {
    _streamSub?.cancel();
    _streamSub = null;

    _logger?.log(
      subsystem: 'AI_CHAT',
      level: LogLevel.info,
      message: 'AI generation stopped by user',
    );

    final newMessages = state.messages.map((m) {
      if (m.isStreaming) {
        return m.copyWith(
          isStreaming: false,
          content: m.content.isEmpty
              ? '[Generation stopped by user]'
              : '${m.content}\n[Generation stopped by user]',
        );
      }
      return m;
    }).toList();

    state = state.copyWith(
      messages: newMessages,
      isGenerating: false,
    );
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final ollamaAiServiceProvider = Provider<OllamaAiService>((ref) {
  final logger = ref.watch(governorLoggerProvider);
  final hbpAsync = ref.watch(hbpClientProvider);
  final hbpClient = hbpAsync.valueOrNull;
  return OllamaAiService(logger: logger, hbpClient: hbpClient);
});

final globalChatProvider =
    StateNotifierProvider<GlobalChatNotifier, GlobalChatState>((ref) {
  final aiService = ref.watch(ollamaAiServiceProvider);
  final logger = ref.watch(governorLoggerProvider);
  return GlobalChatNotifier(aiService, logger);
});
