import 'package:flutter/foundation.dart';

/// Role enum for AI Chat Messages
enum ChatRole {
  user,
  assistant,
  system,
}

/// Node Offload Target Location
enum AiOffloadTarget {
  auto,
  rpi5,
  windowsHost,
}

extension AiOffloadTargetExtension on AiOffloadTarget {
  String get displayName {
    switch (this) {
      case AiOffloadTarget.auto:
        return 'Auto (Governor AI Router)';
      case AiOffloadTarget.rpi5:
        return 'RPi 5 Edge (100.67.11.0)';
      case AiOffloadTarget.windowsHost:
        return 'Windows Host (127.0.0.1)';
    }
  }

  String get shortLabel {
    switch (this) {
      case AiOffloadTarget.auto:
        return 'Governor Auto';
      case AiOffloadTarget.rpi5:
        return 'RPi 5';
      case AiOffloadTarget.windowsHost:
        return 'Windows';
    }
  }

  List<String> get candidateUrls {
    switch (this) {
      case AiOffloadTarget.auto:
      case AiOffloadTarget.rpi5:
        return const [
          'http://100.67.11.0:7700',     // Tailscale IP (primary active connection)
          'http://192.168.254.108:7700', // Local LAN IP
        ];
      case AiOffloadTarget.windowsHost:
        return const [
          'http://127.0.0.1:11434',      // Emergency local Windows Host Ollama
        ];
    }
  }

  String get baseUrl => candidateUrls.first;
}

/// Record of a single tool call executed during an agent loop turn.
class ToolCallStep {
  final String toolName;
  final String resultSummary;
  final bool success;

  const ToolCallStep({
    required this.toolName,
    this.resultSummary = '',
    this.success = true,
  });

  factory ToolCallStep.fromMap(Map<String, dynamic> map) {
    return ToolCallStep(
      toolName: (map['tool_name'] as String?) ?? '',
      resultSummary: (map['result_summary'] as String?) ?? '',
      success: (map['success'] as bool?) ?? true,
    );
  }
}

/// Record of a single turn within the N-turn agent loop.
class AgentLoopStep {
  final int turn;
  /// One of: "tool_execution", "inline_tool_execution", "nudge", "final_answer"
  final String stepType;
  final String modelContent;
  final List<ToolCallStep> toolCalls;

  const AgentLoopStep({
    required this.turn,
    required this.stepType,
    this.modelContent = '',
    this.toolCalls = const [],
  });

  factory AgentLoopStep.fromMap(Map<String, dynamic> map) {
    final tcList = (map['tool_calls'] as List<dynamic>?) ?? [];
    return AgentLoopStep(
      turn: (map['turn'] as int?) ?? 0,
      stepType: (map['step_type'] as String?) ?? 'unknown',
      modelContent: (map['model_content'] as String?) ?? '',
      toolCalls: tcList.map((e) => ToolCallStep.fromMap(e as Map<String, dynamic>)).toList(),
    );
  }

  String get stepTypeIcon {
    switch (stepType) {
      case 'tool_execution':
      case 'inline_tool_execution':
        return '🔧';
      case 'nudge':
        return '🔄';
      case 'reasoning':
        return '🧠';
      case 'final_answer':
        return '💬';
      default:
        return '⚙️';
    }
  }

  String get stepTypeLabel {
    switch (stepType) {
      case 'tool_execution':
        return 'Tool Execution';
      case 'inline_tool_execution':
        return 'Inline Tool Execution';
      case 'nudge':
        return 'Corrective Nudge';
      case 'reasoning':
        return 'Model Reasoning';
      case 'final_answer':
        return 'Final Answer';
      default:
        return stepType;
    }
  }
}

@immutable
class ChatMessage {
  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final String modelName;
  final AiOffloadTarget offloadTarget;
  final bool isStreaming;
  final double? evalTokensPerSec;
  final int? totalDurationMs;
  /// Detailed record of each agent loop turn for "thinking" UI.
  final List<AgentLoopStep> steps;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.modelName = 'qwen3.5:4b',
    this.offloadTarget = AiOffloadTarget.rpi5,
    this.isStreaming = false,
    this.evalTokensPerSec,
    this.totalDurationMs,
    this.steps = const [],
  });

  ChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    String? modelName,
    AiOffloadTarget? offloadTarget,
    bool? isStreaming,
    double? evalTokensPerSec,
    int? totalDurationMs,
    List<AgentLoopStep>? steps,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      modelName: modelName ?? this.modelName,
      offloadTarget: offloadTarget ?? this.offloadTarget,
      isStreaming: isStreaming ?? this.isStreaming,
      evalTokensPerSec: evalTokensPerSec ?? this.evalTokensPerSec,
      totalDurationMs: totalDurationMs ?? this.totalDurationMs,
      steps: steps ?? this.steps,
    );
  }
}
