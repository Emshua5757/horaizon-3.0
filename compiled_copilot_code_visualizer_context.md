# horAIzon 3.0 — Compiled Master Context Document

> Total Files Included: 16

================================================================================

<!-- START_FILE: client_flutter\lib\shared\widgets\copilot_chat_drawer.dart -->
# FILE: copilot_chat_drawer.dart
**Relative Path**: `client_flutter\lib\shared\widgets\copilot_chat_drawer.dart`

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/chat/models/chat_message.dart';
import '../../features/chat/providers/global_chat_provider.dart';
import '../../features/chat/widgets/formatted_markdown_content.dart';

/// Reusable AI Copilot Drawer Widget (JOSH) supporting dynamic context scoping (e.g. scope: code, scope: governor).
class CopilotChatDrawer extends ConsumerStatefulWidget {
  final String contextHint;
  final VoidCallback? onClose;
  final List<String>? quickActionChips;
  final ValueChanged<String>? onChipSelected;

  const CopilotChatDrawer({
    super.key,
    required this.contextHint,
    this.onClose,
    this.quickActionChips,
    this.onChipSelected,
  });

  @override
  ConsumerState<CopilotChatDrawer> createState() => _CopilotChatDrawerState();
}

class _CopilotChatDrawerState extends ConsumerState<CopilotChatDrawer> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _submit([String? overrideText]) {
    final text = (overrideText ?? _promptController.text).trim();
    if (text.isNotEmpty) {
      _promptController.clear();
      ref.read(globalChatProvider.notifier).sendMessage(text, contextHint: widget.contextHint);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chatState = ref.watch(globalChatProvider);

    ref.listen(globalChatProvider, (_, __) => _scrollToBottom());

    final defaultChips = widget.quickActionChips ??
        (widget.contextHint == 'code'
            ? [
                '👑 God Functions',
                '🔥 Callers',
                '💥 Blast Radius',
                '💀 Dead Code',
              ]
            : ['📊 CPU Stats', '💾 RAM Usage', '🔍 Logs']);

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: cs.outlineVariant),
        ),
      ),
      child: Column(
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(bottom: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Icon(Icons.smart_toy_rounded, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  'JOSH Copilot',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'scope: ${widget.contextHint}',
                    style: TextStyle(
                      color: cs.onPrimaryContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: widget.onClose,
                    tooltip: 'Close Copilot Drawer',
                  ),
              ],
            ),
          ),

          // Model & Target Selector Control Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
            ),
            child: Row(
              children: [
                // Model Dropdown Selector
                Icon(Icons.psychology_rounded, size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: chatState.availableModels.contains(chatState.selectedModel)
                          ? chatState.selectedModel
                          : chatState.availableModels.firstOrNull ?? 'qwen3.5:4b',
                      isDense: true,
                      isExpanded: true,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface),
                      onChanged: (newModel) {
                        if (newModel != null) {
                          ref.read(globalChatProvider.notifier).setSelectedModel(newModel);
                        }
                      },
                      items: chatState.availableModels.map((m) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(m, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Target Selector (Auto, RPi 5, Windows Host)
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AiOffloadTarget>(
                      value: chatState.offloadTarget,
                      isDense: true,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: cs.primary),
                      onChanged: (target) {
                        if (target != null) {
                          ref.read(globalChatProvider.notifier).setOffloadTarget(target);
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: AiOffloadTarget.auto,
                          child: Text('Target: Auto'),
                        ),
                        DropdownMenuItem(
                          value: AiOffloadTarget.rpi5,
                          child: Text('Target: RPi 5'),
                        ),
                        DropdownMenuItem(
                          value: AiOffloadTarget.windowsHost,
                          child: Text('Target: Windows Host'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Multi-line Wrap Quick Action Chips Container (no clipping or single-line hiding)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: defaultChips.map((chipLabel) {
                return ActionChip(
                  label: Text(
                    chipLabel,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onPressed: () {
                    if (widget.onChipSelected != null) {
                      widget.onChipSelected!(chipLabel);
                    }
                    _submit(chipLabel);
                  },
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Message List
          Expanded(
            child: chatState.messages.isEmpty
                ? Center(
                    child: Text(
                      'Ask JOSH anything about ${widget.contextHint}...',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: chatState.messages.length,
                    itemBuilder: (context, index) {
                      final msg = chatState.messages[index];
                      return _CopilotMessageBubble(message: msg);
                    },
                  ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cs.surface,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promptController,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Ask JOSH about ${widget.contextHint}...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 12),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: cs.outlineVariant),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: chatState.isGenerating
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  onPressed: chatState.isGenerating ? null : () => _submit(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CopilotMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _CopilotMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.smart_toy_rounded, size: 14, color: cs.primary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isUser ? cs.primary.withValues(alpha: 0.18) : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUser ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isUser ? 'Joshua' : 'JOSH',
                        style: TextStyle(
                          color: isUser ? cs.primary : cs.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 8),
                      ),
                      if (message.evalTokensPerSec != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '⚡ ${message.evalTokensPerSec!.toStringAsFixed(1)} t/s',
                          style: TextStyle(color: cs.primary, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Steps / Tool execution details
                  if (message.steps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: message.steps.map((step) {
                          final toolSummaries = step.toolCalls.map((tc) => '  • ${tc.toolName}').join('\n');
                          return Text(
                            '[Turn ${step.turn}] ${step.stepTypeLabel}\n$toolSummaries',
                            style: TextStyle(
                              fontSize: 9,
                              fontFamily: 'monospace',
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Formatted Markdown Content
                  FormattedMarkdownContent(
                    content: message.content.isEmpty && message.isStreaming
                        ? '...'
                        : message.content,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\shared\widgets\copilot_chat_drawer.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\chat\global_chat_screen.dart -->
# FILE: global_chat_screen.dart
**Relative Path**: `client_flutter\lib\features\chat\global_chat_screen.dart`

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/app_card.dart';
import 'models/chat_message.dart';
import 'providers/global_chat_provider.dart';
import 'widgets/formatted_markdown_content.dart';

/// Interactive Global AI Chat Screen (JOSH) connected to RPi5 & Windows Host Offload Ollama.
class GlobalChatScreen extends ConsumerStatefulWidget {
  const GlobalChatScreen({super.key});

  @override
  ConsumerState<GlobalChatScreen> createState() => _GlobalChatScreenState();
}

class _GlobalChatScreenState extends ConsumerState<GlobalChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showSettingsPanel = false;

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  void _submit() {
    final text = _promptController.text.trim();
    if (text.isNotEmpty) {
      _promptController.clear();
      ref.read(globalChatProvider.notifier).sendMessage(text);
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final chatState = ref.watch(globalChatProvider);
    final chatNotifier = ref.read(globalChatProvider.notifier);

    // Scroll to bottom when messages list updates
    ref.listen(globalChatProvider, (_, __) => _scrollToBottom());

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Top Header Bar
            Row(
              children: [
                Icon(Icons.psychology_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'JOSH — Global AI Assistant',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      'Context-Aware AI Engine • ${chatState.offloadTarget.displayName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Offload Node Badge Button
                InkWell(
                  onTap: () {
                    final nextTarget = switch (chatState.offloadTarget) {
                      AiOffloadTarget.auto => AiOffloadTarget.rpi5,
                      AiOffloadTarget.rpi5 => AiOffloadTarget.windowsHost,
                      AiOffloadTarget.windowsHost => AiOffloadTarget.auto,
                    };
                    chatNotifier.setOffloadTarget(nextTarget);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: switch (chatState.offloadTarget) {
                            AiOffloadTarget.auto => cs.primary,
                            AiOffloadTarget.rpi5 => const Color(0xFF10B981),
                            AiOffloadTarget.windowsHost => const Color(0xFF00E5FF),
                          },
                        ),
                        const SizedBox(width: 8),
                        Text(
                          chatState.offloadTarget.shortLabel,
                          style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Settings Panel Toggle
                IconButton(
                  icon: Icon(
                    _showSettingsPanel ? Icons.tune_rounded : Icons.tune_outlined,
                    color: _showSettingsPanel ? cs.primary : cs.onSurfaceVariant,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showSettingsPanel = !_showSettingsPanel),
                  tooltip: 'AI Parameters Panel',
                ),

                // Copy Entire Conversation Transcript Button
                IconButton(
                  icon: Icon(Icons.copy_all_rounded, color: cs.primary, size: 20),
                  tooltip: 'Copy Entire Conversation Transcript',
                  onPressed: () {
                    if (chatState.messages.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat history is empty.')),
                      );
                      return;
                    }

                    final sb = StringBuffer();
                    sb.writeln('========================================');
                    sb.writeln('  horAIzon 3.0 FULL AI CHAT TRANSCRIPT  ');
                    sb.writeln('  Exported at: ${DateTime.now().toIso8601String()}');
                    sb.writeln('========================================\n');

                    for (final msg in chatState.messages) {
                      final sender = msg.role == ChatRole.user ? 'JOSHUA (User)' : 'JOSH AI (${msg.modelName})';
                      final tokInfo = msg.evalTokensPerSec != null ? ' [${msg.evalTokensPerSec!.toStringAsFixed(1)} tok/s]' : '';
                      final cleanContent = FormattedMarkdownContent.stripThinkTags(msg.content);
                      sb.writeln('[$sender - ${msg.timestamp}$tokInfo]');
                      sb.writeln('Target: ${msg.offloadTarget.shortLabel}');
                      sb.writeln('Content:\n$cleanContent');
                      sb.writeln('\n----------------------------------------\n');
                    }

                    Clipboard.setData(ClipboardData(text: sb.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copied full conversation transcript & metadata!')),
                    );
                  },
                ),

                // Clear History Button
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, color: cs.onSurfaceVariant, size: 20),
                  onPressed: () => chatNotifier.clearHistory(),
                  tooltip: 'Clear Chat History',
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Collapsible AI Aggregator Tuning Panel
            if (_showSettingsPanel) ...[
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'AI AGGREGATOR TUNING & OFFLOAD CONFIG',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        InkWell(
                          onTap: () => setState(() => _showSettingsPanel = false),
                          child: Icon(Icons.close_rounded, size: 16, color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Model Selector Dropdown
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Active Model:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: cs.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: cs.outlineVariant),
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final modelList = chatState.availableModels.toSet().toList();
                                    if (!modelList.contains(chatState.selectedModel)) {
                                      modelList.insert(0, chatState.selectedModel);
                                    }
                                    final selectedValue = modelList.contains(chatState.selectedModel)
                                        ? chatState.selectedModel
                                        : (modelList.isNotEmpty ? modelList.first : null);

                                    return DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedValue,
                                        isExpanded: true,
                                        dropdownColor: cs.surfaceContainerHigh,
                                        style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.bold),
                                        items: modelList.map((m) {
                                          return DropdownMenuItem(
                                            value: m,
                                            child: Text(m),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) chatNotifier.setSelectedModel(val);
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Temperature Slider
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Temperature:', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11)),
                                  Text(
                                    chatState.temperature.toStringAsFixed(2),
                                    style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Slider(
                                value: chatState.temperature,
                                min: 0.0,
                                max: 1.0,
                                divisions: 20,
                                activeColor: cs.primary,
                                onChanged: (val) => chatNotifier.setTemperature(val),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            // Main Message Feed Container
            Expanded(
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: chatState.messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome_rounded, size: 48, color: cs.primary.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              'Start Conversation with JOSH',
                              style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Select a quick prompt below or type your query.',
                              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: chatState.messages.length,
                        itemBuilder: (context, index) {
                          final msg = chatState.messages[index];
                          return _ChatMessageBubble(message: msg);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 14),

            // Quick Prompt Action Chips Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _QuickPromptChip(
                    label: '⚡ RPi 5 System Health',
                    onTap: () => chatNotifier.sendMessage('Check RPi 5 system health, NVMe status, and governor uptime.'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPromptChip(
                    label: '💻 Summarize Architecture',
                    onTap: () => chatNotifier.sendMessage('Summarize horAIzon 3.0 monorepo architecture and HBP v2 contract rules.'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPromptChip(
                    label: '📝 Draft Task Proposal',
                    onTap: () => chatNotifier.sendMessage('Draft a new task spec proposal formatted in horAIzon TASK-XXX style.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Interactive Stdin Prompt Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      style: TextStyle(color: cs.onSurface, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: chatState.isGenerating
                            ? 'JOSH is typing response…'
                            : 'Ask JOSH anything (e.g. system control, code analysis)…',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 13),
                      ),
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (chatState.isGenerating)
                    IconButton(
                      icon: const Icon(Icons.stop_circle_rounded, color: Color(0xFFEF4444)),
                      onPressed: () => chatNotifier.stopGeneration(),
                      tooltip: 'Stop Stream',
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.send_rounded, color: cs.primary),
                      onPressed: _submit,
                      tooltip: 'Send Prompt',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _ChatMessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isUser = message.role == ChatRole.user;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.smart_toy_rounded, size: 18, color: cs.primary),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isUser ? cs.primary.withValues(alpha: 0.18) : cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12).copyWith(
                  topLeft: isUser ? const Radius.circular(12) : const Radius.circular(2),
                  topRight: isUser ? const Radius.circular(2) : const Radius.circular(12),
                ),
                border: Border.all(
                  color: isUser ? cs.primary.withValues(alpha: 0.4) : cs.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isUser ? 'Joshua' : 'JOSH AI (${message.modelName})',
                        style: TextStyle(
                          color: isUser ? cs.primary : cs.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 9),
                      ),
                      if (message.evalTokensPerSec != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '⚡ ${message.evalTokensPerSec!.toStringAsFixed(1)} tok/s',
                          style: TextStyle(color: cs.primary, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ],
                      const Spacer(),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.copy_rounded, size: 14, color: cs.onSurfaceVariant),
                        tooltip: 'Copy Message (Live streaming content so far)',
                        onPressed: () {
                          final stepsText = message.steps.map((s) {
                            final tools = s.toolCalls.map((tc) => '  • ${tc.toolName}: ${tc.resultSummary}').join('\n');
                            final body = s.modelContent.trim();
                            return '[Turn ${s.turn} · ${s.stepTypeLabel}]\n${body.isNotEmpty ? body : ""}${tools.isNotEmpty ? "\n$tools" : ""}';
                          }).where((t) => t.trim().isNotEmpty).join('\n\n');

                          final textToCopy = [
                            if (stepsText.isNotEmpty) stepsText,
                            if (message.content.isNotEmpty) message.content,
                          ].join('\n\n----------------------------------------\n\n');

                          Clipboard.setData(ClipboardData(text: textToCopy.isNotEmpty ? textToCopy : '...'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message.isStreaming
                                  ? 'Copied live streaming steps & content so far (${textToCopy.length} chars)!'
                                  : 'Message text copied to clipboard.'),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: Icon(Icons.copy_all_rounded, size: 14, color: cs.primary),
                        tooltip: 'Copy All (Model, Speed, Steps & Response so far)',
                        onPressed: () {
                          final tokInfo = message.evalTokensPerSec != null
                              ? '${message.evalTokensPerSec!.toStringAsFixed(1)} tok/s'
                              : 'N/A';
                          final stepsText = message.steps.map((s) {
                            final tools = s.toolCalls.map((tc) => '  • ${tc.toolName}: ${tc.resultSummary}').join('\n');
                            final body = s.modelContent.trim();
                            return '[Turn ${s.turn} · ${s.stepTypeLabel}]\n${body.isNotEmpty ? body : ""}${tools.isNotEmpty ? "\n$tools" : ""}';
                          }).where((t) => t.trim().isNotEmpty).join('\n\n');

                          final mainText = [
                            if (stepsText.isNotEmpty) stepsText,
                            if (message.content.isNotEmpty) message.content,
                          ].join('\n\n----------------------------------------\n\n');

                          final exportText = '[JOSH AI Message Export]\n'
                              '• Model: ${message.modelName}\n'
                              '• Target: ${message.offloadTarget.shortLabel}\n'
                              '• Performance: $tokInfo\n'
                              '• Status: ${message.isStreaming ? "Streaming live..." : "Complete"}\n'
                              '• Timestamp: ${message.timestamp}\n'
                              '----------------------------------------\n\n'
                              '${mainText.isNotEmpty ? mainText : "(Reasoning in progress...)"}';

                          Clipboard.setData(ClipboardData(text: exportText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(message.isStreaming
                                  ? 'Copied live stream metadata, N-turn steps & content so far!'
                                  : 'Copied full AI message, model & performance metadata!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  if (!isUser && message.steps.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AgentLoopCard(steps: message.steps),
                    ),
                  if (message.content.isEmpty && message.isStreaming)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Executing N-Turn Agent Loop (Reasoning & MCP Tools)…',
                            style: TextStyle(
                              color: cs.primary,
                              fontSize: 11.5,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'JetBrainsMono',
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (message.content.isNotEmpty) ...[
                    FormattedMarkdownContent(content: message.content),
                    if (message.isStreaming)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: cs.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Streaming tokens…',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 10,
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: cs.secondary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: cs.secondary.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.person_rounded, size: 18, color: cs.secondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickPromptChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickPromptChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(color: cs.primary, fontSize: 11, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\chat\global_chat_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\chat\models\chat_message.dart -->
# FILE: chat_message.dart
**Relative Path**: `client_flutter\lib\features\chat\models\chat_message.dart`

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


<!-- END_FILE: client_flutter\lib\features\chat\models\chat_message.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\chat\providers\global_chat_provider.dart -->
# FILE: global_chat_provider.dart
**Relative Path**: `client_flutter\lib\features\chat\providers\global_chat_provider.dart`

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

  Future<void> sendMessage(String text, {String contextHint = 'governor'}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isGenerating) return;

    _logger?.log(
      subsystem: 'AI_CHAT',
      level: LogLevel.info,
      message: 'User prompt sent to JOSH ($trimmed)',
      metadata: {
        'model': state.selectedModel,
        'target': state.offloadTarget.shortLabel,
        'contextHint': contextHint,
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
      contextHint: contextHint,
    );

    var finalContent = '';
    var chunkCount = 0;

    _streamSub = stream.listen(
      (chunk) {
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
            final updatedSteps = List<AgentLoopStep>.from(m.steps);

            // 1. Handle incoming completed turn steps from shua_governor
            if (chunk.steps.isNotEmpty) {
              for (final incomingStep in chunk.steps) {
                final idx = updatedSteps.indexWhere((s) => s.turn == incomingStep.turn);
                if (idx >= 0) {
                  updatedSteps[idx] = incomingStep;
                } else {
                  updatedSteps.add(incomingStep);
                }
              }
            }

            // 2. Token delta chunk or final completion payload from Ollama / shua_governor
            if (chunk.content.isNotEmpty) {
              if (chunk.done) {
                finalContent = chunk.content;
              } else {
                finalContent += chunk.content;
              }
            }

            return m.copyWith(
              content: finalContent,
              offloadTarget: targetNode,
              isStreaming: !chunk.done,
              evalTokensPerSec: chunk.evalTokensPerSec ?? m.evalTokensPerSec,
              totalDurationMs: chunk.totalDurationMs ?? m.totalDurationMs,
              steps: updatedSteps,
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
          final replyPreview = finalContent.length > 120
              ? '${finalContent.substring(0, 120)}…'
              : finalContent;
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
              'reply_chars': finalContent.length,
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
            'partial_chars': finalContent.length,
            'chunks_received': chunkCount,
          },
        );

        final newMessages = state.messages.map((m) {
          if (m.id == assistantMsgId) {
            return m.copyWith(
              content: '$finalContent\n[Error: $e]',
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
        if (finalContent.isEmpty && chunkCount == 0) {
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


<!-- END_FILE: client_flutter\lib\features\chat\providers\global_chat_provider.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\chat\widgets\formatted_markdown_content.dart -->
# FILE: formatted_markdown_content.dart
**Relative Path**: `client_flutter\lib\features\chat\widgets\formatted_markdown_content.dart`

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/chat_message.dart';

/// Collapsible N-Turn Agent Loop card — shows each iteration of the MCP tool-calling
/// loop (like ChatGPT/Claude "thinking" blocks) with turn dividers, step type icons,
/// and tool call result summaries.
/// Independent N-Turn Agent Loop card container — renders a dedicated card
/// for each turn step (Turn 1: Tool Call, Turn 2: Nudge, etc.) so no turn step is ever lost or overwritten.
class AgentLoopCard extends StatelessWidget {
  final List<AgentLoopStep> steps;

  const AgentLoopCard({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (steps.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2, right: 2),
            child: Row(
              children: [
                Icon(Icons.loop_rounded, size: 14, color: cs.tertiary),
                const SizedBox(width: 6),
                Text(
                  'AGENT LOOP (${steps.length} ${steps.length == 1 ? "TURN" : "TURNS"})',
                  style: TextStyle(
                    color: cs.tertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    final allTurnsText = steps.map((s) {
                      final toolsStr = s.toolCalls
                          .map((tc) => '  • Tool ${tc.toolName} (${tc.success ? "Success" : "Failed"}):\n    ${tc.resultSummary}')
                          .join('\n\n');
                      final body = s.modelContent.trim();
                      return '[Turn ${s.turn} · ${s.stepTypeIcon} ${s.stepTypeLabel.toUpperCase()}]\n'
                          '${body.isNotEmpty ? body : "(No text)"}'
                          '${toolsStr.isNotEmpty ? "\n$toolsStr" : ""}';
                    }).join('\n\n----------------------------------------\n\n');

                    final fullExport = '========================================\n'
                        '  JOSH AGENT LOOP EXECUTION (${steps.length} TURNS)\n'
                        '========================================\n\n'
                        '$allTurnsText';

                    Clipboard.setData(ClipboardData(text: fullExport));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied all ${steps.length} agent loop turns & tool outputs to clipboard!'),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy_all_rounded, size: 13, color: cs.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'Copy All Turns',
                          style: TextStyle(
                            color: cs.tertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ...steps.map((step) => _TurnStepCard(step: step)),
      ],
    );
  }
}

class _TurnStepCard extends StatefulWidget {
  final AgentLoopStep step;
  const _TurnStepCard({required this.step});

  @override
  State<_TurnStepCard> createState() => _TurnStepCardState();
}

class _TurnStepCardState extends State<_TurnStepCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final step = widget.step;
    final isError = step.toolCalls.any((tc) => !tc.success);

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? Colors.red.shade400.withValues(alpha: 0.5) : cs.tertiary.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  if (step.stepType == 'reasoning')
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  else
                    Icon(
                      step.stepType == 'nudge'
                          ? Icons.warning_amber_rounded
                          : Icons.precision_manufacturing_rounded,
                      size: 15,
                      color: isError ? Colors.red.shade300 : cs.tertiary,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    'TURN ${step.turn} · ${step.stepType == "reasoning" ? "⚡ REASONING (LIVE)" : "${step.stepTypeIcon} ${step.stepTypeLabel.toUpperCase()}"}',
                    style: TextStyle(
                      color: step.stepType == 'reasoning'
                          ? cs.primary
                          : (isError ? Colors.red.shade300 : cs.tertiary),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontFamily: 'JetBrainsMono',
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.copy_rounded, size: 14, color: cs.primary),
                    tooltip: 'Copy Turn ${step.turn} details',
                    onPressed: () {
                      final toolsStr = step.toolCalls
                          .map((tc) => '• Tool ${tc.toolName} (${tc.success ? "Success" : "Failed"}):\n  ${tc.resultSummary}')
                          .join('\n\n');
                      final turnExport = '[Turn ${step.turn} · ${step.stepTypeIcon} ${step.stepTypeLabel.toUpperCase()}]\n'
                          '${step.modelContent.trim()}\n'
                          '${toolsStr.isNotEmpty ? "\n$toolsStr" : ""}';
                      Clipboard.setData(ClipboardData(text: turnExport.trim()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Copied Turn ${step.turn} (${step.stepTypeLabel}) details to clipboard!'),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, thickness: 1),
            _AgentLoopStepTile(step: step),
          ],
        ],
      ),
    );
  }
}

class _AgentLoopStepTile extends StatefulWidget {
  final AgentLoopStep step;

  const _AgentLoopStepTile({required this.step});

  @override
  State<_AgentLoopStepTile> createState() => _AgentLoopStepTileState();
}

class _AgentLoopStepTileState extends State<_AgentLoopStepTile> {
  bool _showFullContent = false;
  final Set<String> _expandedToolResults = {};

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final step = widget.step;
    final isError = step.toolCalls.any((tc) => !tc.success);

    final isLongContent = step.modelContent.length > 200;
    final displayedContent = isLongContent && !_showFullContent
        ? '${step.modelContent.substring(0, 200)}…'
        : step.modelContent;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header: Turn N · 🔧 step_type
          Row(
            children: [
              Text(
                'Turn ${step.turn}',
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
              const SizedBox(width: 6),
              Text('·', style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10)),
              const SizedBox(width: 6),
              Text(
                '${step.stepTypeIcon} ${step.stepTypeLabel}',
                style: TextStyle(
                  color: isError ? Colors.red.shade300 : cs.tertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Model content (with Show Full / Show Less toggle)
          if (step.modelContent.isNotEmpty) ...[
            SelectableText(
              displayedContent,
              style: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.8),
                fontSize: 11,
                height: 1.4,
                fontFamily: 'JetBrainsMono',
              ),
            ),
            if (isLongContent)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: InkWell(
                  onTap: () => setState(() => _showFullContent = !_showFullContent),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _showFullContent ? 'Show Less ▴' : 'Show Full reasoning ▾',
                          style: TextStyle(
                            color: cs.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],

          // Tool call results (with per-tool Show Full toggle)
          ...step.toolCalls.map((tc) {
            final isLongToolRes = tc.resultSummary.length > 200;
            final isExpanded = _expandedToolResults.contains(tc.toolName);
            final displayedToolRes = isLongToolRes && !isExpanded
                ? '${tc.resultSummary.substring(0, 200)}…'
                : tc.resultSummary;

            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tc.success ? '✅' : '❌',
                    style: const TextStyle(fontSize: 11),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tc.toolName,
                          style: TextStyle(
                            color: tc.success ? cs.primary : Colors.red.shade300,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'JetBrainsMono',
                          ),
                        ),
                        if (tc.resultSummary.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: SelectableText(
                              displayedToolRes,
                              style: TextStyle(
                                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontFamily: 'JetBrainsMono',
                              ),
                            ),
                          ),
                          if (isLongToolRes)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedToolResults.remove(tc.toolName);
                                    } else {
                                      _expandedToolResults.add(tc.toolName);
                                    }
                                  });
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    isExpanded ? 'Show Less ▴' : 'Show Full tool output ▾',
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'JetBrainsMono',
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Rich Theme-Aware Markdown & Fenced Code Block Renderer for JOSH AI Chat.
/// Renders headers, lists, inline code, and syntax-styled code cards (bash, rust, json, mermaid, batch)
/// with a 1-click "Copy Code" button and responsive theme integration.
class FormattedMarkdownContent extends StatelessWidget {
  final String content;

  const FormattedMarkdownContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final blocks = _parseBlocks(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks.map((block) {
        if (block.isThinkingBlock) {
          return _ThinkingCard(text: block.text);
        } else if (block.isCodeBlock) {
          return _CodeBlockCard(
            language: block.language,
            code: block.text,
          );
        } else if (block.isTableBlock) {
          return _MarkdownTableWidget(tableText: block.text);
        } else {
          return _TextBlockRenderer(text: block.text);
        }
      }).toList(),
    );
  }

  static String stripThinkTags(String input) {
    return input.replaceAll(RegExp(r'<think>.*?</think>', dotAll: true), '').trim();
  }

  List<_ParsedBlock> _parseBlocks(String input) {
    final List<_ParsedBlock> blocks = [];
    final lines = input.split('\n');

    bool inCode = false;
    bool inThinking = false;
    bool inTable = false;
    String currentLang = '';
    final List<String> currentBuffer = [];
    final List<String> tableBuffer = [];

    void flushBuffer() {
      if (currentBuffer.isEmpty) return;
      final text = currentBuffer.join('\n').trim();
      if (text.isNotEmpty) {
        blocks.add(_ParsedBlock(
          isCodeBlock: inCode,
          isThinkingBlock: inThinking,
          language: inCode ? currentLang : '',
          text: text,
        ));
      }
      currentBuffer.clear();
    }

    void flushTable() {
      if (tableBuffer.isEmpty) return;
      final text = tableBuffer.join('\n').trim();
      if (text.isNotEmpty) {
        blocks.add(_ParsedBlock(
          isTableBlock: true,
          text: text,
        ));
      }
      tableBuffer.clear();
      inTable = false;
    }

    for (final line in lines) {
      if (line.contains('<think>')) {
        if (inTable) flushTable();
        final parts = line.split('<think>');
        if (parts[0].trim().isNotEmpty) {
          currentBuffer.add(parts[0]);
        }
        flushBuffer();
        inThinking = true;
        final remainder = parts.sublist(1).join('<think>');
        if (remainder.contains('</think>')) {
          final endParts = remainder.split('</think>');
          currentBuffer.add(endParts[0]);
          flushBuffer();
          inThinking = false;
          if (endParts.length > 1 && endParts[1].trim().isNotEmpty) {
            currentBuffer.add(endParts.sublist(1).join('</think>'));
          }
        } else {
          currentBuffer.add(remainder);
        }
        continue;
      } else if (line.contains('</think>')) {
        if (inTable) flushTable();
        final parts = line.split('</think>');
        currentBuffer.add(parts[0]);
        flushBuffer();
        inThinking = false;
        if (parts.length > 1 && parts[1].trim().isNotEmpty) {
          currentBuffer.add(parts.sublist(1).join('</think>'));
        }
        continue;
      }

      final trimmed = line.trim();
      if (trimmed.startsWith('🛠️ **[MCP Tool') || trimmed.startsWith('⚙️ **[Governor Telemetry')) {
        if (inTable) flushTable();
        flushBuffer();
        blocks.add(_ParsedBlock(
          isThinkingBlock: true,
          text: line,
        ));
        continue;
      }

      if (trimmed.startsWith('```')) {
        if (inTable) flushTable();
        if (inCode) {
          flushBuffer();
          inCode = false;
          currentLang = '';
        } else {
          flushBuffer();
          inCode = true;
          currentLang = trimmed.substring(3).trim();
        }
        continue;
      }

      // Check for Markdown table row (| Header | Header |)
      if (!inCode && !inThinking) {
        if (trimmed.startsWith('|') && trimmed.endsWith('|') && trimmed.length > 2) {
          if (!inTable) {
            flushBuffer();
            inTable = true;
          }
          tableBuffer.add(line);
          continue;
        } else if (inTable) {
          flushTable();
        }
      }

      currentBuffer.add(line);
    }

    if (inTable) flushTable();
    flushBuffer();
    return blocks;
  }
}

class _ParsedBlock {
  final bool isCodeBlock;
  final bool isThinkingBlock;
  final bool isTableBlock;
  final String language;
  final String text;

  _ParsedBlock({
    this.isCodeBlock = false,
    this.isThinkingBlock = false,
    this.isTableBlock = false,
    this.language = '',
    required this.text,
  });
}

class _ThinkingCard extends StatefulWidget {
  final String text;

  const _ThinkingCard({required this.text});

  @override
  State<_ThinkingCard> createState() => _ThinkingCardState();
}

class _ThinkingCardState extends State<_ThinkingCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cleanedText = widget.text
        .replaceAll('<think>', '')
        .replaceAll('</think>', '')
        .trim();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.psychology_rounded, size: 16, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'THINKING PHASE & AGENT CHAIN-OF-THOUGHT',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, thickness: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SelectableText(
                cleanedText,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 11.5,
                  height: 1.45,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CodeBlockCard extends StatefulWidget {
  final String language;
  final String code;

  const _CodeBlockCard({
    required this.language,
    required this.code,
  });

  @override
  State<_CodeBlockCard> createState() => _CodeBlockCardState();
}

class _CodeBlockCardState extends State<_CodeBlockCard> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final displayLang = widget.language.isEmpty ? 'CODE' : widget.language.toUpperCase();
    final isMermaid = displayLang == 'MERMAID' || displayLang == 'MMD';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMermaid ? cs.secondary.withValues(alpha: 0.5) : cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isMermaid
                  ? cs.secondaryContainer.withValues(alpha: 0.3)
                  : cs.surfaceContainerHigh.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: Row(
              children: [
                Icon(
                  isMermaid ? Icons.schema_rounded : Icons.code_rounded,
                  size: 14,
                  color: isMermaid ? cs.secondary : cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  isMermaid ? 'MERMAID DIAGRAM' : displayLang,
                  style: TextStyle(
                    color: isMermaid ? cs.secondary : cs.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _copyCode,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 12,
                          color: _copied ? Colors.green : cs.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied!' : 'Copy',
                          style: TextStyle(
                            color: _copied ? Colors.green : cs.onSurfaceVariant,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Code Text Area
          Padding(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              widget.code.trimRight(),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 12,
                height: 1.45,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlockRenderer extends StatelessWidget {
  final String text;

  const _TextBlockRenderer({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = text.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final trimmed = line.trim();

        // Header 1 (# Header)
        if (trimmed.startsWith('# ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Text(
              trimmed.substring(2),
              style: TextStyle(color: cs.primary, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 2 (## Header)
        if (trimmed.startsWith('## ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: TextStyle(color: cs.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Header 3 (### Header)
        if (trimmed.startsWith('### ')) {
          return Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              trimmed.substring(4),
              style: TextStyle(color: cs.secondary, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          );
        }

        // Bullet Point (- item or * item)
        if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                Expanded(
                  child: _RichInlineText(text: trimmed.substring(2)),
                ),
              ],
            ),
          );
        }

        // Numbered List (1. item)
        final numMatch = RegExp(r'^\d+\.\s').firstMatch(trimmed);
        if (numMatch != null) {
          final prefix = numMatch.group(0)!;
          return Padding(
            padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(prefix, style: TextStyle(color: cs.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                Expanded(
                  child: _RichInlineText(text: trimmed.substring(prefix.length)),
                ),
              ],
            ),
          );
        }

        if (trimmed.isEmpty) {
          return const SizedBox(height: 6);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _RichInlineText(text: line),
        );
      }).toList(),
    );
  }
}

class _RichInlineText extends StatelessWidget {
  final String text;

  const _RichInlineText({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final spans = <InlineSpan>[];

    // Regex for bold (**text**), italics (*text*), and inline code (`code`)
    final regex = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)');
    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final matchedStr = match.group(0)!;
      if (matchedStr.startsWith('**') && matchedStr.endsWith('**')) {
        spans.add(TextSpan(
          text: matchedStr.substring(2, matchedStr.length - 2),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (matchedStr.startsWith('*') && matchedStr.endsWith('*')) {
        spans.add(TextSpan(
          text: matchedStr.substring(1, matchedStr.length - 1),
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (matchedStr.startsWith('`') && matchedStr.endsWith('`')) {
        spans.add(WidgetSpan(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Text(
              matchedStr.substring(1, matchedStr.length - 1),
              style: TextStyle(
                color: cs.primary,
                fontSize: 11.5,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
        ));
      }

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return SelectableText.rich(
      TextSpan(
        style: TextStyle(color: cs.onSurface, fontSize: 13, height: 1.45),
        children: spans,
      ),
    );
  }
}

class _MarkdownTableWidget extends StatelessWidget {
  final String tableText;

  const _MarkdownTableWidget({required this.tableText});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lines = tableText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return const SizedBox.shrink();

    List<String> parseRow(String row) {
      final trimmed = row.trim();
      final content = trimmed.startsWith('|') ? trimmed.substring(1) : trimmed;
      final cleaned = content.endsWith('|') ? content.substring(0, content.length - 1) : content;
      return cleaned.split('|').map((cell) => cell.trim()).toList();
    }

    final rawHeaderRow = parseRow(lines[0]);
    final rawDataRows = <List<String>>[];

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.replaceAll(RegExp(r'[\|\:\-\s]'), '').isEmpty) {
        continue;
      }
      rawDataRows.add(parseRow(line));
    }

    int maxCols = rawHeaderRow.length;
    for (final row in rawDataRows) {
      if (row.length > maxCols) {
        maxCols = row.length;
      }
    }
    if (maxCols == 0) return const SizedBox.shrink();

    List<String> padRow(List<String> row) {
      if (row.length == maxCols) return row;
      final padded = List<String>.from(row);
      while (padded.length < maxCols) {
        padded.add('');
      }
      return padded.sublist(0, maxCols);
    }

    final headerRow = padRow(rawHeaderRow);
    final dataRows = rawDataRows.map((r) => padRow(r)).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh.withValues(alpha: 0.8),
                ),
                children: headerRow.map((cell) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text(
                      cell,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  );
                }).toList(),
              ),
              ...dataRows.asMap().entries.map((entry) {
                final rowIndex = entry.key;
                final rowCells = entry.value;
                final isEven = rowIndex % 2 == 0;

                return TableRow(
                  decoration: BoxDecoration(
                    color: isEven
                        ? Colors.transparent
                        : cs.surfaceContainerHighest.withValues(alpha: 0.15),
                  ),
                  children: rowCells.map((cell) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: _RichInlineText(text: cell),
                    );
                  }).toList(),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\chat\widgets\formatted_markdown_content.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\code_topology_screen.dart -->
# FILE: code_topology_screen.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\code_topology_screen.dart`

// File: client_flutter/lib/features/code_visualizer/code_topology_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/copilot_chat_drawer.dart';
import 'models/topology_insights.dart';
import 'models/topology_models.dart';
import 'presentation/widgets/code_topology_canvas.dart';
import 'presentation/widgets/layout_engine.dart';
import 'presentation/widgets/path_tracer_panel.dart';
import 'presentation/widgets/symbol_inspector_drawer.dart';
import 'providers/code_topology_provider.dart';

final isAiCopilotOpenProvider = StateProvider<bool>((ref) => false);

class CodeTopologyScreen extends ConsumerWidget {
  const CodeTopologyScreen({super.key});

  Future<void> _pickRepositoryFolder(WidgetRef ref) async {
    final selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select Repository Folder to Visualize',
    );

    if (selectedPath != null && selectedPath.isNotEmpty) {
      ref.read(activeWorkspacePathProvider.notifier).state = selectedPath;
      ref.read(selectedNodeProvider.notifier).state = null;
      ref.read(pathStartNodeProvider.notifier).state = null;
      ref.read(pathEndNodeProvider.notifier).state = null;
      ref.invalidate(codeTopologyProvider);
    }
  }

  int _countForFilter(TopologyGraphDataModel? data, InsightFilter? filter) {
    if (data == null || data.nodes.isEmpty) return 0;
    if (filter == null) return data.nodes.length;
    switch (filter) {
      case InsightFilter.godFunctions:
        return data.nodes.where((n) => n.isGodFunction).length;
      case InsightFilter.hubs:
        return data.nodes.where((n) => n.isHub).length;
      case InsightFilter.highRisk:
        return data.nodes.where((n) => n.isHighRisk).length;
      case InsightFilter.deadCode:
        return data.nodes.where((n) => n.isDeadCode).length;
      case InsightFilter.publicApis:
        return data.nodes.where((n) => n.isPublicApi).length;
    }
  }

  void _showPhysicsTuningDialog(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final repulsion = ref.watch(physicsRepulsionProvider);
            final spring = ref.watch(physicsSpringProvider);
            final modulePull = ref.watch(physicsModuleAttractorProvider);
            final gravity = ref.watch(physicsGravityProvider);
            final maxVel = ref.watch(physicsMaxVelocityProvider);
            final damping = ref.watch(physicsDampingProvider);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tune_rounded, size: 20, color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Physics Simulation Tuning',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.close_rounded, size: 18, color: cs.onSurfaceVariant),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    Divider(height: 16, color: cs.outlineVariant),

                    // Max Velocity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Max Particle Speed Limit:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text('${maxVel.toInt()} px/frame', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: maxVel,
                        min: 10.0,
                        max: 100.0,
                        divisions: 45,
                        onChanged: (val) {
                          ref.read(physicsMaxVelocityProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Friction Damping Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Friction Damping:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(damping.toStringAsFixed(2), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: damping,
                        min: 0.50,
                        max: 0.95,
                        divisions: 45,
                        onChanged: (val) {
                          ref.read(physicsDampingProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Repulsion Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Repulsion Force:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text('${repulsion.toInt()}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: repulsion,
                        min: 3000,
                        max: 50000,
                        divisions: 47,
                        onChanged: (val) {
                          ref.read(physicsRepulsionProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Spring Attraction Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Spring Attraction:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(spring.toStringAsFixed(3), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: spring,
                        min: 0.005,
                        max: 0.20,
                        divisions: 39,
                        onChanged: (val) {
                          ref.read(physicsSpringProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Module Galaxy Pull Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Module Constellation Pull:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(modulePull.toStringAsFixed(3), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: modulePull,
                        min: 0.005,
                        max: 0.10,
                        divisions: 38,
                        onChanged: (val) {
                          ref.read(physicsModuleAttractorProvider.notifier).state = val;
                        },
                      ),
                    ),

                    // Center Gravity Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Center Gravity:', style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        Text(gravity.toStringAsFixed(4), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface)),
                      ],
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(trackHeight: 3),
                      child: Slider(
                        value: gravity,
                        min: 0.0005,
                        max: 0.01,
                        divisions: 38,
                        onChanged: (val) {
                          ref.read(physicsGravityProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final topologyAsync = ref.watch(codeTopologyProvider);
    final selectedNode = ref.watch(selectedNodeProvider);
    final activePath = ref.watch(activeWorkspacePathProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final currentLayout = ref.watch(selectedLayoutModeProvider);
    final isolationDepth = ref.watch(isolationDepthProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);
    final isCopilotOpen = ref.watch(isAiCopilotOpenProvider);

    final graphData = topologyAsync.valueOrNull;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          children: [
            // Clean 2-Tier Header Toolbar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surface,
                border: Border(bottom: BorderSide(color: cs.outlineVariant)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tier 1: Title, Full Workspace Path Breadcrumb, Change Folder Button, and Metric Badge
                  Row(
                    children: [
                      Icon(Icons.hub_rounded, color: cs.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'Code Topology',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Full Path Breadcrumb Pill
                      Expanded(
                        child: Tooltip(
                          message: activePath.isEmpty ? 'No path selected' : activePath,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cs.outlineVariant),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.folder_rounded, size: 14, color: cs.primary),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    activePath.isEmpty ? 'Select Workspace Folder...' : activePath,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Folder Picker Button
                      FilledButton.tonalIcon(
                        icon: const Icon(Icons.folder_open_rounded, size: 14),
                        label: const Text('Change Folder', style: TextStyle(fontSize: 11)),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _pickRepositoryFolder(ref),
                      ),
                      const SizedBox(width: 8),

                      // Graph Nodes & Edges Metric Badge
                      if (graphData != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${graphData.nodes.length} Nodes · ${graphData.edges.length} Edges',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Tier 2: Viewport Controls & Filter Chips (Wrap Layout)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.start,
                    children: [
                      // Layout Mode Segmented Control
                      SegmentedButton<LayoutMode>(
                        style: SegmentedButton.styleFrom(
                          textStyle: const TextStyle(fontSize: 11),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: LayoutMode.physics,
                            label: Text('⚡ Physics Cluster'),
                          ),
                          ButtonSegment(
                            value: LayoutMode.fileGrouped,
                            label: Text('📁 File Grouped'),
                          ),
                          ButtonSegment(
                            value: LayoutMode.callFlow,
                            label: Text('🌲 Call Flow'),
                          ),
                        ],
                        selected: {currentLayout},
                        onSelectionChanged: (set) {
                          ref.read(selectedLayoutModeProvider.notifier).state = set.first;
                        },
                      ),

                      // Search Bar
                      SizedBox(
                        width: 160,
                        height: 32,
                        child: TextField(
                          onChanged: (val) {
                            ref.read(searchQueryProvider.notifier).state = val;
                          },
                          style: TextStyle(fontSize: 12, color: cs.onSurface),
                          decoration: InputDecoration(
                            hintText: 'Search symbol...',
                            hintStyle: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                            prefixIcon: Icon(Icons.search_rounded, size: 14, color: cs.onSurfaceVariant),
                            contentPadding: EdgeInsets.zero,
                            filled: true,
                            fillColor: cs.surfaceContainerHighest,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: BorderSide(color: cs.outlineVariant),
                            ),
                          ),
                        ),
                      ),

                      // N-Hop Subgraph Isolation Depth Dropdown
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            value: isolationDepth,
                            style: TextStyle(fontSize: 11, color: cs.onSurface),
                            dropdownColor: cs.surface,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('🌐 Global Graph')),
                              DropdownMenuItem(value: 1, child: Text('🎯 1-Hop Isolation')),
                              DropdownMenuItem(value: 2, child: Text('🕸️ 2-Hop Isolation')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(isolationDepthProvider.notifier).state = val;
                              }
                            },
                          ),
                        ),
                      ),

                      // Physics Tuning Slider Button
                      IconButton.filledTonal(
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        tooltip: 'Adjust Physics Sliders',
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () => _showPhysicsTuningDialog(context, ref),
                      ),

                      // Multi-Select Insight Filter Chips with Dynamic Count Badges
                      _FilterChip(
                        label: 'All',
                        count: _countForFilter(graphData, null),
                        isSelected: activeFilters.isEmpty,
                        onSelected: (_) {
                          ref.read(activeFiltersProvider.notifier).state = {};
                        },
                      ),
                      _FilterChip(
                        label: '👑 God Functions',
                        count: _countForFilter(graphData, InsightFilter.godFunctions),
                        isSelected: activeFilters.contains(InsightFilter.godFunctions),
                        onSelected: (val) {
                          final updated = Set<InsightFilter>.from(activeFilters);
                          val ? updated.add(InsightFilter.godFunctions) : updated.remove(InsightFilter.godFunctions);
                          ref.read(activeFiltersProvider.notifier).state = updated;
                        },
                      ),
                      _FilterChip(
                        label: '🔥 Hubs',
                        count: _countForFilter(graphData, InsightFilter.hubs),
                        isSelected: activeFilters.contains(InsightFilter.hubs),
                        onSelected: (val) {
                          final updated = Set<InsightFilter>.from(activeFilters);
                          val ? updated.add(InsightFilter.hubs) : updated.remove(InsightFilter.hubs);
                          ref.read(activeFiltersProvider.notifier).state = updated;
                        },
                      ),
                      _FilterChip(
                        label: '⚠️ High Risk',
                        count: _countForFilter(graphData, InsightFilter.highRisk),
                        isSelected: activeFilters.contains(InsightFilter.highRisk),
                        onSelected: (val) {
                          final updated = Set<InsightFilter>.from(activeFilters);
                          val ? updated.add(InsightFilter.highRisk) : updated.remove(InsightFilter.highRisk);
                          ref.read(activeFiltersProvider.notifier).state = updated;
                        },
                      ),
                      _FilterChip(
                        label: '💀 Dead Code',
                        count: _countForFilter(graphData, InsightFilter.deadCode),
                        isSelected: activeFilters.contains(InsightFilter.deadCode),
                        onSelected: (val) {
                          final updated = Set<InsightFilter>.from(activeFilters);
                          val ? updated.add(InsightFilter.deadCode) : updated.remove(InsightFilter.deadCode);
                          ref.read(activeFiltersProvider.notifier).state = updated;
                        },
                      ),

                      // AND / OR Toggle Button
                      if (activeFilters.length > 1)
                        InputChip(
                          avatar: Icon(matchAll ? Icons.rule_rounded : Icons.alt_route_rounded, size: 12),
                          label: Text(
                            matchAll ? 'MATCH ALL' : 'MATCH ANY',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          selected: matchAll,
                          onPressed: () {
                            ref.read(filterMatchAllProvider.notifier).state = !matchAll;
                          },
                        ),

                      // Path Tracer Reset Button
                      if (pathStart != null || pathEnd != null)
                        ActionChip(
                          avatar: const Icon(Icons.route_rounded, size: 12),
                          label: Text(
                            'Path: ${pathStart?.qualifiedName ?? '?'} ➔ ${pathEnd?.qualifiedName ?? '?'}',
                            style: const TextStyle(fontSize: 10),
                          ),
                          onPressed: () {
                            ref.read(pathStartNodeProvider.notifier).state = null;
                            ref.read(pathEndNodeProvider.notifier).state = null;
                          },
                        ),

                      IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        tooltip: 'Rescan Repository',
                        onPressed: () => ref.invalidate(codeTopologyProvider),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCopilotOpen ? cs.primary : cs.primaryContainer,
                          foregroundColor: isCopilotOpen ? cs.onPrimary : cs.onPrimaryContainer,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        onPressed: () {
                          ref.read(isAiCopilotOpenProvider.notifier).state = !isCopilotOpen;
                        },
                        icon: const Icon(Icons.smart_toy_rounded, size: 16),
                        label: const Text('🤖 JOSH Copilot', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Main View (Canvas + Inspector Drawer + Path Tracer Panel + Copilot Drawer)
            Expanded(
              child: topologyAsync.when(
                loading: () => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        'Parsing repository symbols and building topology graph...',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                error: (err, stack) => Center(child: Text('Error loading topology: $err')),
                data: (data) => Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CodeTopologyCanvas(graphData: data),
                        ),
                        if (selectedNode != null && !isCopilotOpen)
                          SymbolInspectorDrawer(node: selectedNode),
                        if (isCopilotOpen)
                          CopilotChatDrawer(
                            contextHint: 'code',
                            onClose: () => ref.read(isAiCopilotOpenProvider.notifier).state = false,
                          ),
                      ],
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: PathTracerPanel(graphData: data),
                    ),
                    if (!isCopilotOpen)
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton.extended(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          onPressed: () => ref.read(isAiCopilotOpenProvider.notifier).state = true,
                          icon: const Icon(Icons.smart_toy_rounded, size: 18),
                          label: const Text('JOSH AI Copilot', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text('$label ($count)', style: const TextStyle(fontSize: 10)),
      selected: isSelected,
      onSelected: onSelected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\code_topology_screen.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\models\topology_insights.dart -->
# FILE: topology_insights.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\models\topology_insights.dart`

// File: client_flutter/lib/features/code_visualizer/models/topology_insights.dart

import 'topology_models.dart';

enum InsightFilter { godFunctions, hubs, highRisk, deadCode, publicApis }

extension TopologyNodeInsights on TopologyNodeModel {
  /// A "God Function": high complexity & high LOC, or huge fan-out with too many params.
  bool get isGodFunction =>
      (exceedsComplexityThreshold && exceedsLocThreshold) ||
      (complexity >= 15 && loc >= 80) ||
      (fanOut >= 8 && params.length >= 5);

  /// Structural hub: high call traffic (fanIn + fanOut >= 6).
  bool get isHub => (fanIn + fanOut) >= 6;

  /// Dead Code: unreferenced, not public, not a test.
  bool get isDeadCode => isOrphan && !isPublic && !isTest;

  /// High Risk score >= 7.0.
  bool get isHighRisk => riskScore >= 7.0;

  /// Public API symbol.
  bool get isPublicApi => isPublic && !isTest;

  /// Primary badge label.
  String get primaryBadgeLabel {
    if (isGodFunction) return 'God Function';
    if (isDeadCode) return 'Dead Code';
    if (isHighRisk) return 'High Risk';
    if (isHub) return 'Hub';
    if (isPublicApi) return 'Public API';
    return '';
  }

  String get primaryBadgeEmoji {
    if (isGodFunction) return '👑';
    if (isDeadCode) return '💀';
    if (isHighRisk) return '⚠️';
    if (isHub) return '🔥';
    if (isPublicApi) return '📦';
    return '';
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\models\topology_insights.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\models\topology_models.dart -->
# FILE: topology_models.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\models\topology_models.dart`

class ParamModel {
  final String name;
  final String type;
  final bool isOptional;

  const ParamModel({
    required this.name,
    required this.type,
    this.isOptional = false,
  });

  factory ParamModel.fromJson(Map<String, dynamic> json) {
    return ParamModel(
      name: json['name'] as String? ?? '',
      type: json['type_name'] as String? ?? json['type'] as String? ?? '',
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'is_optional': isOptional,
      };
}

class ThresholdConfigModel {
  final int maxParams;
  final int maxComplexity;
  final int maxLoc;
  final double maxRiskScore;

  const ThresholdConfigModel({
    this.maxParams = 5,
    this.maxComplexity = 10,
    this.maxLoc = 75,
    this.maxRiskScore = 7.0,
  });

  factory ThresholdConfigModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ThresholdConfigModel();
    return ThresholdConfigModel(
      maxParams: (json['max_params'] as num?)?.toInt() ?? 5,
      maxComplexity: (json['max_complexity'] as num?)?.toInt() ?? 10,
      maxLoc: (json['max_loc'] as num?)?.toInt() ?? 75,
      maxRiskScore: (json['max_risk_score'] as num?)?.toDouble() ?? 7.0,
    );
  }
}

class TopologyNodeModel {
  final String id;
  final String kind;
  final String qualifiedName;
  final String file;
  final int line;
  final List<ParamModel> params;
  final String? returnType;
  final int complexity;
  final List<String> sideEffects;
  final String? intent;
  final int loc;
  final bool isPublic;
  final bool isTest;
  final int fanIn;
  final int fanOut;
  final double riskScore;
  final bool isOrphan;
  final bool exceedsParamThreshold;
  final bool exceedsComplexityThreshold;
  final bool exceedsLocThreshold;

  // TASK-016B Data Expansions (0.7a - 0.7l)
  final bool isEntrypoint;
  final int? sccId;
  final String modulePath;
  final bool isAsync;
  final bool isBlocking;
  final int dagLevel;

  const TopologyNodeModel({
    required this.id,
    required this.kind,
    required this.qualifiedName,
    required this.file,
    required this.line,
    required this.params,
    this.returnType,
    required this.complexity,
    required this.sideEffects,
    this.intent,
    required this.loc,
    required this.isPublic,
    required this.isTest,
    required this.fanIn,
    required this.fanOut,
    required this.riskScore,
    required this.isOrphan,
    this.exceedsParamThreshold = false,
    this.exceedsComplexityThreshold = false,
    this.exceedsLocThreshold = false,
    this.isEntrypoint = false,
    this.sccId,
    this.modulePath = '',
    this.isAsync = false,
    this.isBlocking = false,
    this.dagLevel = 0,
  });

  factory TopologyNodeModel.fromJson(Map<String, dynamic> json) {
    final rawParams = json['params'] as List<dynamic>? ?? [];
    final rawSideEffects = json['side_effects'] as List<dynamic>? ?? [];

    return TopologyNodeModel(
      id: json['id'] as String? ?? '',
      kind: json['kind'] as String? ?? 'function',
      qualifiedName: json['qualified_name'] as String? ?? '',
      file: json['file'] as String? ?? '',
      line: (json['line'] as num?)?.toInt() ?? 1,
      params: rawParams
          .map((p) => ParamModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      returnType: json['return_type'] as String?,
      complexity: (json['complexity'] as num?)?.toInt() ?? 1,
      sideEffects: rawSideEffects.map((e) => e.toString()).toList(),
      intent: json['intent'] as String?,
      loc: (json['loc'] as num?)?.toInt() ?? 1,
      isPublic: json['is_public'] as bool? ?? true,
      isTest: json['is_test'] as bool? ?? false,
      fanIn: (json['fan_in'] as num?)?.toInt() ?? 0,
      fanOut: (json['fan_out'] as num?)?.toInt() ?? 0,
      riskScore: (json['risk_score'] as num?)?.toDouble() ?? 0.0,
      isOrphan: json['is_orphan'] as bool? ?? false,
      exceedsParamThreshold: json['exceeds_param_threshold'] as bool? ?? false,
      exceedsComplexityThreshold:
          json['exceeds_complexity_threshold'] as bool? ?? false,
      exceedsLocThreshold: json['exceeds_loc_threshold'] as bool? ?? false,
      isEntrypoint: json['is_entrypoint'] as bool? ?? false,
      sccId: (json['scc_id'] as num?)?.toInt(),
      modulePath: json['module_path'] as String? ?? '',
      isAsync: json['is_async'] as bool? ?? false,
      isBlocking: json['is_blocking'] as bool? ?? false,
      dagLevel: (json['dag_level'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'qualified_name': qualifiedName,
        'file': file,
        'line': line,
        'params': params.map((p) => p.toJson()).toList(),
        'return_type': returnType,
        'complexity': complexity,
        'side_effects': sideEffects,
        'intent': intent,
        'loc': loc,
        'is_public': isPublic,
        'is_test': isTest,
        'fan_in': fanIn,
        'fan_out': fanOut,
        'risk_score': riskScore,
        'is_orphan': isOrphan,
        'exceeds_param_threshold': exceedsParamThreshold,
        'exceeds_complexity_threshold': exceedsComplexityThreshold,
        'exceeds_loc_threshold': exceedsLocThreshold,
        'is_entrypoint': isEntrypoint,
        'scc_id': sccId,
        'module_path': modulePath,
        'is_async': isAsync,
        'is_blocking': isBlocking,
        'dag_level': dagLevel,
      };
}

class TopologyEdgeModel {
  final String from;
  final String to;
  final String relation;
  final int callCount;

  const TopologyEdgeModel({
    required this.from,
    required this.to,
    required this.relation,
    this.callCount = 1,
  });

  factory TopologyEdgeModel.fromJson(Map<String, dynamic> json) {
    return TopologyEdgeModel(
      from: json['from'] as String? ?? '',
      to: json['to'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Calls',
      callCount: (json['call_count'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'relation': relation,
        'call_count': callCount,
      };
}

class TopologyGraphDataModel {
  final List<TopologyNodeModel> nodes;
  final List<TopologyEdgeModel> edges;
  final ThresholdConfigModel thresholdConfig;

  const TopologyGraphDataModel({
    required this.nodes,
    required this.edges,
    this.thresholdConfig = const ThresholdConfigModel(),
  });

  factory TopologyGraphDataModel.fromJson(Map<String, dynamic> json) {
    final rawNodes = json['nodes'] as List<dynamic>? ?? [];
    final rawEdges = json['edges'] as List<dynamic>? ?? [];

    final parsedNodes = rawNodes
        .map((n) => TopologyNodeModel.fromJson(n as Map<String, dynamic>))
        .toList();
    final parsedEdgeList = rawEdges
        .map((e) => TopologyEdgeModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Normalize edge from/to to node.id ONCE upon loading graph snapshot
    final idByQName = {for (final n in parsedNodes) n.qualifiedName: n.id};
    final idByRawId = {for (final n in parsedNodes) n.id: n.id};
    final idByShort = <String, String>{};
    for (final n in parsedNodes) {
      final short = n.qualifiedName.split('.').last;
      idByShort.putIfAbsent(short, () => n.id);
    }

    final normalizedEdges = <TopologyEdgeModel>[];
    for (final e in parsedEdgeList) {
      final resolvedFrom = idByRawId[e.from] ?? idByQName[e.from] ?? idByShort[e.from] ?? e.from;
      final resolvedTo = idByRawId[e.to] ?? idByQName[e.to] ?? idByShort[e.to] ?? e.to;
      normalizedEdges.add(TopologyEdgeModel(
        from: resolvedFrom,
        to: resolvedTo,
        relation: e.relation,
        callCount: e.callCount,
      ));
    }

    return TopologyGraphDataModel(
      nodes: parsedNodes,
      edges: normalizedEdges,
      thresholdConfig: ThresholdConfigModel.fromJson(
          json['threshold_config'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {
        'nodes': nodes.map((n) => n.toJson()).toList(),
        'edges': edges.map((e) => e.toJson()).toList(),
      };
}

class TopologyDeltaEvent {
  final String filePath;
  final String changeType;
  final List<String> affectedNodeIds;

  const TopologyDeltaEvent({
    required this.filePath,
    required this.changeType,
    required this.affectedNodeIds,
  });

  factory TopologyDeltaEvent.fromJson(Map<String, dynamic> json) {
    final rawAffected = json['affected_node_ids'] as List<dynamic>? ?? [];
    return TopologyDeltaEvent(
      filePath: json['file_path'] as String? ?? '',
      changeType: json['change_type'] as String? ?? 'modified',
      affectedNodeIds: rawAffected.map((e) => e.toString()).toList(),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\models\topology_models.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart -->
# FILE: code_topology_canvas.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/code_topology_canvas.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_insights.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';
import '../../providers/topology_data_source.dart';
import 'layout_engine.dart';

class CodeTopologyCanvas extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;

  const CodeTopologyCanvas({
    super.key,
    required this.graphData,
  });

  @override
  ConsumerState<CodeTopologyCanvas> createState() => _CodeTopologyCanvasState();
}

class _CodeTopologyCanvasState extends ConsumerState<CodeTopologyCanvas>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  PhysicsSimulation? _physicsSim;
  String? _draggedNodeId;
  Offset? _dragGrabOffset;

  final TransformationController _transformController = TransformationController();

  GraphLayout? _cachedStaticLayout;
  LayoutMode? _cachedMode;
  TopologyGraphDataModel? _cachedData;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((dt) {
      if (_physicsSim != null && !_physicsSim!.isSettled) {
        final changed = _physicsSim!.step(0.016);
        if (changed) {
          setState(() {});
        } else {
          _ticker.stop();
        }
      } else {
        _ticker.stop();
      }
    });

    _initSimulation();
  }

  @override
  void didUpdateWidget(CodeTopologyCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.graphData, widget.graphData)) {
      _initSimulation();
      _cachedStaticLayout = null;
    }
  }

  void _initSimulation() {
    final repulsion = ref.read(physicsRepulsionProvider);
    final spring = ref.read(physicsSpringProvider);
    final modulePull = ref.read(physicsModuleAttractorProvider);
    final gravity = ref.read(physicsGravityProvider);
    final maxVel = ref.read(physicsMaxVelocityProvider);
    final damping = ref.read(physicsDampingProvider);

    _physicsSim = PhysicsSimulation(
      nodes: widget.graphData.nodes,
      edges: widget.graphData.edges,
      repulsion: repulsion,
      springStrength: spring,
      moduleAttractorStrength: modulePull,
      centerGravity: gravity,
      maxVelocity: maxVel,
      damping: damping,
    );
    _startTickerIfNeeded();
  }

  void _startTickerIfNeeded() {
    if (_physicsSim != null && !_physicsSim!.isSettled && !_ticker.isActive) {
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _transformController.dispose();
    super.dispose();
  }

  GraphLayout _currentLayout(LayoutMode mode) {
    if (mode == LayoutMode.physics) {
      return _physicsSim?.toLayout() ??
          GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    }

    if (_cachedStaticLayout != null &&
        _cachedMode == mode &&
        identical(_cachedData, widget.graphData)) {
      return _cachedStaticLayout!;
    }

    final layout =
        GraphLayoutEngine.compute(data: widget.graphData, mode: mode);
    _cachedStaticLayout = layout;
    _cachedMode = mode;
    _cachedData = widget.graphData;
    return layout;
  }

  Set<String> _neighborhoodOf(String nodeId) {
    final ids = <String>{nodeId};
    final node = widget.graphData.nodes.firstWhere((n) => n.id == nodeId, orElse: () => widget.graphData.nodes.first);
    final qname = node.qualifiedName;

    for (final e in widget.graphData.edges) {
      if (e.from == nodeId || e.from == qname) {
        ids.add(e.to);
      }
      if (e.to == nodeId || e.to == qname) {
        ids.add(e.from);
      }
    }
    return ids;
  }

  List<String>? _findShortestPath(String fromId, String toId) {
    final index = ref.read(graphIndexProvider);
    if (index != null) {
      return index.tracePathLocal(fromId, toId);
    }
    return [fromId];
  }

  bool _passesFilter(
    TopologyNodeModel n,
    Set<InsightFilter> activeFilters,
    bool matchAll,
    String query,
  ) {
    if (query.isNotEmpty &&
        !n.qualifiedName.toLowerCase().contains(query.toLowerCase())) {
      return false;
    }
    if (activeFilters.isEmpty) return true;

    final matches = [
      if (activeFilters.contains(InsightFilter.godFunctions) && n.isGodFunction) true,
      if (activeFilters.contains(InsightFilter.hubs) && n.isHub) true,
      if (activeFilters.contains(InsightFilter.highRisk) && n.isHighRisk) true,
      if (activeFilters.contains(InsightFilter.deadCode) && n.isDeadCode) true,
      if (activeFilters.contains(InsightFilter.publicApis) && n.isPublicApi) true,
    ];

    if (matchAll) {
      return matches.length == activeFilters.length;
    }
    return matches.contains(true);
  }

  TopologyNodeModel? _hitTest(Offset localPoint, GraphLayout layout) {
    for (final n in widget.graphData.nodes.reversed) {
      final pos = layout.positions[n.id];
      if (pos == null) continue;
      if ((pos - localPoint).distance <= _nodeRadius(n) + 12.0) return n;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(selectedLayoutModeProvider);
    final activeFilters = ref.watch(activeFiltersProvider);
    final matchAll = ref.watch(filterMatchAllProvider);
    final query = ref.watch(searchQueryProvider);
    final isolationDepth = ref.watch(isolationDepthProvider);
    final graphIndex = ref.watch(graphIndexProvider);
    final selected = ref.watch(selectedNodeProvider);
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final repulsion = ref.watch(physicsRepulsionProvider);
    final spring = ref.watch(physicsSpringProvider);
    final modulePull = ref.watch(physicsModuleAttractorProvider);
    final gravity = ref.watch(physicsGravityProvider);
    final maxVel = ref.watch(physicsMaxVelocityProvider);
    final damping = ref.watch(physicsDampingProvider);

    if (_physicsSim != null) {
      if (_physicsSim!.repulsion != repulsion ||
          _physicsSim!.springStrength != spring ||
          _physicsSim!.moduleAttractorStrength != modulePull ||
          _physicsSim!.centerGravity != gravity ||
          _physicsSim!.maxVelocity != maxVel ||
          _physicsSim!.damping != damping) {
        _physicsSim!.repulsion = repulsion;
        _physicsSim!.springStrength = spring;
        _physicsSim!.moduleAttractorStrength = modulePull;
        _physicsSim!.centerGravity = gravity;
        _physicsSim!.maxVelocity = maxVel;
        _physicsSim!.damping = damping;
        _physicsSim!.wakeUp();
        _startTickerIfNeeded();
      }
    }

    _startTickerIfNeeded();
    final layout = _currentLayout(mode);

    // Calculate highlighted neighborhood or shortest path
    Set<String>? highlighted;
    List<String>? pathNodes;

    if (pathStart != null && pathEnd != null) {
      pathNodes = _findShortestPath(pathStart.id, pathEnd.id);
      if (pathNodes != null) highlighted = pathNodes.toSet();
    } else if (selected != null) {
      highlighted = _neighborhoodOf(selected.id);
    }

    final width = max(layout.contentSize.width, 1400.0);
    final height = max(layout.contentSize.height, 1000.0);
    final isSimulating = mode == LayoutMode.physics && _physicsSim != null && !_physicsSim!.isSettled;

    return RepaintBoundary(
      child: Container(
        color: const Color(0xFF0E1116),
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.12,
          maxScale: 3.0,
          constrained: false,
          boundaryMargin: const EdgeInsets.all(500),
          child: SizedBox(
            width: width,
            height: height,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final tapped = _hitTest(details.localPosition, layout);
                ref.read(selectedNodeProvider.notifier).state = tapped;
              },
              onPanStart: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null) return;
                final hit = _hitTest(details.localPosition, layout);
                if (hit != null) {
                  _draggedNodeId = hit.id;
                  final p = _physicsSim!.particles[hit.id];
                  if (p != null) {
                    _dragGrabOffset = details.localPosition - p.position;
                  }
                  _physicsSim!.pinnedIds.add(hit.id);
                  _startTickerIfNeeded();
                }
              },
              onPanUpdate: (details) {
                if (mode != LayoutMode.physics || _physicsSim == null || _draggedNodeId == null) return;
                final p = _physicsSim!.particles[_draggedNodeId];
                if (p != null) {
                  p.position = details.localPosition - (_dragGrabOffset ?? Offset.zero);
                  _physicsSim!.wakeUp();
                  _startTickerIfNeeded();
                }
              },
              onPanEnd: (_) {
                if (_draggedNodeId != null) {
                  _physicsSim?.pinnedIds.remove(_draggedNodeId);
                  _draggedNodeId = null;
                  _dragGrabOffset = null;
                }
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: _TopologyPainter(
                  graphData: widget.graphData,
                  layout: layout,
                  activeFilters: activeFilters,
                  matchAll: matchAll,
                  query: query,
                  isolationDepth: isolationDepth,
                  graphIndex: graphIndex,
                  selectedId: selected?.id,
                  highlighted: highlighted,
                  pathNodes: pathNodes,
                  passesFilter: _passesFilter,
                  isSimulating: isSimulating,
                  transformController: _transformController,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _nodeRadius(TopologyNodeModel n) {
  const base = 13.0;
  final boost = min((n.fanIn + n.fanOut).toDouble(), 22.0) * 0.85;
  return base + boost;
}

class _TopologyPainter extends CustomPainter {
  final TopologyGraphDataModel graphData;
  final GraphLayout layout;
  final Set<InsightFilter> activeFilters;
  final bool matchAll;
  final String query;
  final int isolationDepth;
  final GraphIndex? graphIndex;
  final String? selectedId;
  final Set<String>? highlighted;
  final List<String>? pathNodes;
  final bool Function(TopologyNodeModel, Set<InsightFilter>, bool, String) passesFilter;
  final bool isSimulating;
  final TransformationController transformController;

  static final Map<String, TextPainter> _labelCache = {};

  _TopologyPainter({
    required this.graphData,
    required this.layout,
    required this.activeFilters,
    required this.matchAll,
    required this.query,
    required this.isolationDepth,
    required this.graphIndex,
    required this.selectedId,
    required this.highlighted,
    required this.pathNodes,
    required this.passesFilter,
    required this.isSimulating,
    required this.transformController,
  });

  Set<String> _computeVisibleIds() {
    if (isolationDepth > 0 && graphIndex != null) {
      final isolatedIds = <String>{};

      if (query.isNotEmpty) {
        final searchMatches = graphData.nodes
            .where((n) => n.qualifiedName.toLowerCase().contains(query.toLowerCase()));
        for (final matchNode in searchMatches) {
          final nbrs = graphIndex!.blastRadiusLocal(matchNode.id, maxDepth: isolationDepth);
          isolatedIds.addAll(nbrs);
        }
      } else if (selectedId != null) {
        final nbrs = graphIndex!.blastRadiusLocal(selectedId!, maxDepth: isolationDepth);
        isolatedIds.addAll(nbrs);
      }

      if (isolatedIds.isNotEmpty) {
        return isolatedIds;
      }
    }

    return {
      for (final n in graphData.nodes)
        if (passesFilter(n, activeFilters, matchAll, query)) n.id,
    };
  }

  Rect _computeVisibleViewportRect(Size canvasSize) {
    final matrix = transformController.value;
    final inverted = Matrix4.inverted(matrix);
    // Transform viewport screen coordinates back to content canvas space
    final transformed = MatrixUtils.transformRect(inverted, Offset.zero & canvasSize);
    return transformed.inflate(180.0);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final visibleIds = _computeVisibleIds();
    final visibleViewportRect = _computeVisibleViewportRect(size);

    _paintFileGroups(canvas);
    _paintEdges(canvas, visibleIds, visibleViewportRect);
    _paintNodes(canvas, visibleIds, visibleViewportRect);
  }

  void _paintFileGroups(Canvas canvas) {
    for (final entry in layout.fileGroups.entries) {
      final fill = Paint()
        ..color = const Color(0x14FFFFFF)
        ..style = PaintingStyle.fill;
      final border = Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      final rrect =
          RRect.fromRectAndRadius(entry.value, const Radius.circular(14));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, border);

      final label = entry.key.split(RegExp(r'[/\\]')).last;
      final tp = _labelCache.putIfAbsent(
        'group_$label',
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: const TextStyle(
              color: Color(0xAAE0E0E0),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      tp.paint(canvas, entry.value.topLeft + const Offset(12, 8));
    }
  }

  void _paintEdges(Canvas canvas, Set<String> visibleIds, Rect viewportRect) {
    final pathEdgeSet = <String>{};
    if (pathNodes != null && pathNodes!.length >= 2) {
      for (int i = 0; i < pathNodes!.length - 1; i++) {
        pathEdgeSet.add('${pathNodes![i]}->${pathNodes![i + 1]}');
        pathEdgeSet.add('${pathNodes![i + 1]}->${pathNodes![i]}');
      }
    }

    for (final e in graphData.edges) {
      final fromPos = layout.positions[e.from];
      final toPos = layout.positions[e.to];
      if (fromPos == null || toPos == null) continue;

      // Real Viewport Inverse Edge Culling: Skip edges outside visible viewport
      if (!viewportRect.contains(fromPos) && !viewportRect.contains(toPos)) {
        continue;
      }

      final isPathEdge = pathEdgeSet.contains('${e.from}->${e.to}') ||
          pathEdgeSet.contains('${e.to}->${e.from}');
      final isHighlighted = highlighted != null &&
          (highlighted!.contains(e.from) || highlighted!.contains(e.to));
      final dimmed = highlighted != null && !isHighlighted;

      final relLower = e.relation.toLowerCase();
      final baseColor = isPathEdge
          ? const Color(0xFF00E676)
          : (relLower == 'imports' ? const Color(0xFF40C4FF) : const Color(0xFFFFB74D));

      final opacity = dimmed ? 0.08 : (isPathEdge ? 1.0 : (isHighlighted ? 0.95 : 0.45));
      final strokeWidth = isPathEdge ? 3.2 : (isHighlighted ? 2.4 : 1.4);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = baseColor.withValues(alpha: opacity);

      // Fast Direct Line Segments during active 60fps live physics simulation for 0 jank
      if (isSimulating) {
        canvas.drawLine(fromPos, toPos, paint);
      } else {
        final mid = Offset((fromPos.dx + toPos.dx) / 2, (fromPos.dy + toPos.dy) / 2);
        final control =
            mid + Offset((toPos.dy - fromPos.dy) * 0.15, (fromPos.dx - toPos.dx) * 0.15);
        final path = Path()
          ..moveTo(fromPos.dx, fromPos.dy)
          ..quadraticBezierTo(control.dx, control.dy, toPos.dx, toPos.dy);
        canvas.drawPath(path, paint);
      }
    }
  }

  void _paintNodes(Canvas canvas, Set<String> visibleIds, Rect viewportRect) {
    for (final n in graphData.nodes) {
      if (!visibleIds.contains(n.id)) continue;
      final pos = layout.positions[n.id];
      if (pos == null) continue;

      // Real Viewport Node Culling
      if (!viewportRect.contains(pos)) continue;

      final isSelected = n.id == selectedId;
      final isDimmed = highlighted != null && !highlighted!.contains(n.id);
      final radius = _nodeRadius(n);

      final baseColor = _nodeColor(n);
      final color = isDimmed ? baseColor.withValues(alpha: 0.15) : baseColor;

      // Selection Halo
      if (isSelected) {
        final haloPaint = Paint()
          ..color = const Color(0xFF00E676).withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 10, haloPaint);

        final ringPaint = Paint()
          ..color = const Color(0xFF00E676)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5;
        canvas.drawCircle(pos, radius + 5, ringPaint);
      }

      // Outer glow for high risk or god functions
      if (n.isGodFunction || n.isHighRisk) {
        final glowColor = n.isGodFunction ? const Color(0xFFFF5252) : const Color(0xFFFFAB00);
        final glowPaint = Paint()
          ..color = glowColor.withValues(alpha: 0.25)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(pos, radius + 6, glowPaint);
      }

      // Main Node Fill
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, radius, fillPaint);

      // Node Border Stroke
      final borderPaint = Paint()
        ..color = isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.2 : 1.0;
      canvas.drawCircle(pos, radius, borderPaint);

      // Node Title Label (Cached TextPainter)
      final label = n.qualifiedName.split('.').last;
      final cacheKey = '${n.id}_${isDimmed}_$isSelected';
      final tp = _labelCache.putIfAbsent(
        cacheKey,
        () => TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isDimmed
                  ? Colors.white.withValues(alpha: 0.2)
                  : (isSelected ? const Color(0xFF00E676) : Colors.white.withValues(alpha: 0.9)),
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );
      tp.paint(canvas, pos + Offset(-tp.width / 2, radius + 3));
    }
  }

  Color _nodeColor(TopologyNodeModel n) {
    switch (n.kind.toLowerCase()) {
      case 'class':
        return const Color(0xFF42A5F5); // Blue
      case 'enum':
        return const Color(0xFFAB47BC); // Purple
      case 'module':
        return const Color(0xFF26A69A); // Teal
      case 'trait':
        return const Color(0xFFFF7043); // Orange
      case 'function':
      default:
        if (n.isGodFunction) return const Color(0xFFEF5350); // Red
        if (n.isHub) return const Color(0xFFFFA726); // Amber
        if (n.isDeadCode) return const Color(0xFF78909C); // Grey
        return const Color(0xFF29B6F6); // Cyan
    }
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.selectedId != selectedId ||
        oldDelegate.highlighted != highlighted ||
        oldDelegate.query != query ||
        oldDelegate.activeFilters != activeFilters ||
        oldDelegate.isolationDepth != isolationDepth ||
        oldDelegate.isSimulating != isSimulating ||
        oldDelegate.pathNodes != pathNodes ||
        oldDelegate.matchAll != matchAll ||
        oldDelegate.graphIndex != graphIndex;
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\code_topology_canvas.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart -->
# FILE: layout_engine.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/layout_engine.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/topology_models.dart';

enum LayoutMode { physics, fileGrouped, callFlow }

class GraphLayout {
  final Map<String, Offset> positions;
  final Map<String, Rect> fileGroups;
  final Size contentSize;

  const GraphLayout({
    required this.positions,
    this.fileGroups = const {},
    required this.contentSize,
  });
}

class PhysicsParticle {
  final TopologyNodeModel node;
  Offset position;
  Offset velocity;
  bool isPinned;

  PhysicsParticle({
    required this.node,
    required this.position,
    this.isPinned = false,
  }) : velocity = Offset.zero;
}

class PhysicsSimulation {
  final Map<String, PhysicsParticle> particles;
  final List<TopologyEdgeModel> edges;
  final Size canvasSize;

  double repulsion;
  double springStrength;
  double moduleAttractorStrength;
  double centerGravity;
  double maxVelocity;
  double damping;

  double temperature = 1.0;
  bool isSettled = false;
  final Set<String> pinnedIds = {};
  final Map<String, Offset> moduleAttractors = {};

  PhysicsSimulation({
    required List<TopologyNodeModel> nodes,
    required this.edges,
    this.canvasSize = const Size(2400, 1800),
    this.repulsion = 12000.0,
    this.springStrength = 0.05,
    this.moduleAttractorStrength = 0.035,
    this.centerGravity = 0.003,
    this.maxVelocity = 32.0,
    this.damping = 0.80,
  }) : particles = {} {
    final rnd = Random(42);
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);

    // Group modules into distinct galaxy constellation sectors around center
    final modules = <String, List<TopologyNodeModel>>{};
    for (final n in nodes) {
      modules.putIfAbsent(n.modulePath, () => []).add(n);
    }

    final modKeys = modules.keys.toList()..sort();
    for (int i = 0; i < modKeys.length; i++) {
      final modAngle = (i / max(1, modKeys.length)) * 2 * pi;
      final modRadius = 520.0 + (i % 3) * 180.0;
      moduleAttractors[modKeys[i]] = center + Offset(cos(modAngle) * modRadius, sin(modAngle) * modRadius);
    }

    // Seed particles around their module attractor centers
    for (int i = 0; i < nodes.length; i++) {
      final n = nodes[i];
      final modCenter = moduleAttractors[n.modulePath] ?? center;
      final offsetAngle = rnd.nextDouble() * 2 * pi;
      final offsetRadius = rnd.nextDouble() * 90.0;

      particles[n.id] = PhysicsParticle(
        node: n,
        position: modCenter + Offset(cos(offsetAngle) * offsetRadius, sin(offsetAngle) * offsetRadius),
      );
    }
  }

  void togglePin(String id) {
    if (pinnedIds.contains(id)) {
      pinnedIds.remove(id);
      if (particles.containsKey(id)) {
        particles[id]!.isPinned = false;
      }
    } else {
      pinnedIds.add(id);
      if (particles.containsKey(id)) {
        particles[id]!.isPinned = true;
      }
    }
  }

  /// Single 60fps physics step with configurable Max Velocity & Friction Damping
  bool step(double dt) {
    if (particles.isEmpty || isSettled) {
      return false;
    }

    const springLength = 65.0;
    const minEnergyEpsilon = 0.03;
    const cellSize = 220.0;

    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    double totalKineticEnergy = 0.0;

    // 1. Build Spatial Hash Grid Buckets for O(N) Repulsion
    final grid = <int, List<PhysicsParticle>>{};
    int cellKey(int cx, int cy) => (cx * 73856093) ^ (cy * 19349663);

    for (final p in particles.values) {
      final cx = (p.position.dx / cellSize).floor();
      final cy = (p.position.dy / cellSize).floor();
      grid.putIfAbsent(cellKey(cx, cy), () => []).add(p);
    }

    // 2. Compute Repulsion against adjacent 3x3 grid cells + Module Attractor Pull
    for (final a in particles.values) {
      if (a.isPinned || pinnedIds.contains(a.node.id)) continue;

      var force = Offset.zero;
      final acx = (a.position.dx / cellSize).floor();
      final acy = (a.position.dy / cellSize).floor();

      for (int dx = -1; dx <= 1; dx++) {
        for (int dy = -1; dy <= 1; dy++) {
          final neighbors = grid[cellKey(acx + dx, acy + dy)];
          if (neighbors == null) continue;

          for (final b in neighbors) {
            if (identical(a, b)) continue;
            final delta = a.position - b.position;
            var distSq = delta.distanceSquared;
            if (distSq < 16) distSq = 16;
            if (distSq > cellSize * cellSize) continue;
            final dist = sqrt(distSq);

            // Bounded force clamp prevents infinity explosions
            final repMag = min(repulsion / distSq, 600.0);
            force += delta / dist * repMag;
          }
        }
      }

      // Strong pull toward module galaxy constellation center
      final modCenter = moduleAttractors[a.node.modulePath] ?? center;
      force += (modCenter - a.position) * moduleAttractorStrength;
      force += (center - a.position) * centerGravity;

      a.velocity = (a.velocity + force * dt * 30.0) * damping;

      // Dynamic Velocity Clamping
      final speed = a.velocity.distance;
      if (speed > maxVelocity) {
        a.velocity = (a.velocity / speed) * maxVelocity;
      }
    }

    // 3. Pure O(1) Hooke spring attraction pulling connected call/import nodes into tight clusters
    for (final e in edges) {
      final a = particles[e.from];
      final b = particles[e.to];
      if (a == null || b == null || identical(a, b)) continue;

      final delta = b.position - a.position;
      final dist = max(delta.distance, 1.0);
      final displacement = dist - springLength;
      final mult = max(1.0, e.callCount * 1.0);
      final f = delta / dist * min(displacement * springStrength * mult, 250.0);

      if (!a.isPinned && !pinnedIds.contains(a.node.id)) {
        a.velocity += f;
        final speedA = a.velocity.distance;
        if (speedA > maxVelocity) {
          a.velocity = (a.velocity / speedA) * maxVelocity;
        }
      }
      if (!b.isPinned && !pinnedIds.contains(b.node.id)) {
        b.velocity -= f;
        final speedB = b.velocity.distance;
        if (speedB > maxVelocity) {
          b.velocity = (b.velocity / speedB) * maxVelocity;
        }
      }
    }

    // 4. Integrate position & compute total energy
    for (final p in particles.values) {
      if (!p.isPinned && !pinnedIds.contains(p.node.id)) {
        p.position += p.velocity * (dt * 30.0);
        totalKineticEnergy += p.velocity.distanceSquared;
      }
    }

    // 5. Thermal decay
    temperature = max(0.0, temperature - 0.008);
    isSettled = totalKineticEnergy < minEnergyEpsilon && temperature <= 0.05;
    return !isSettled;
  }

  void wakeUp() {
    temperature = 1.0;
    isSettled = false;
  }

  GraphLayout toLayout() {
    var minX = double.infinity, minY = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity;
    for (final p in particles.values) {
      minX = min(minX, p.position.dx);
      minY = min(minY, p.position.dy);
      maxX = max(maxX, p.position.dx);
      maxY = max(maxY, p.position.dy);
    }
    const margin = 160.0;
    final positions = {
      for (final e in particles.entries)
        e.key: e.value.position - Offset(minX - margin, minY - margin),
    };

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1800.0, (maxX - minX) + margin * 2),
        max(1400.0, (maxY - minY) + margin * 2),
      ),
    );
  }
}

class GraphLayoutEngine {
  const GraphLayoutEngine._();

  static GraphLayout compute({
    required TopologyGraphDataModel data,
    required LayoutMode mode,
    Size canvasSize = const Size(2400, 1800),
  }) {
    if (data.nodes.isEmpty) {
      return GraphLayout(positions: const {}, contentSize: canvasSize);
    }
    switch (mode) {
      case LayoutMode.physics:
        final sim = PhysicsSimulation(nodes: data.nodes, edges: data.edges, canvasSize: canvasSize);
        return sim.toLayout();
      case LayoutMode.fileGrouped:
        return _fileGroupedLayout(data);
      case LayoutMode.callFlow:
        return _callFlowLayout(data);
    }
  }

  static GraphLayout _fileGroupedLayout(TopologyGraphDataModel data) {
    final byFile = <String, List<TopologyNodeModel>>{};
    for (final n in data.nodes) {
      byFile.putIfAbsent(n.file, () => []).add(n);
    }
    final files = byFile.keys.toList()..sort();

    const cols = 2;
    const padding = 50.0;
    const nodeSpacingX = 140.0;
    const nodeSpacingY = 90.0;

    final positions = <String, Offset>{};
    final fileGroups = <String, Rect>{};

    var currentY = padding;
    var maxColumnX = 0.0;

    for (var i = 0; i < files.length; i += cols) {
      var maxHeightInRow = 0.0;
      var currentX = padding;

      for (var c = 0; c < cols && (i + c) < files.length; c++) {
        final file = files[i + c];
        final members = byFile[file]!;

        final colsInBox = sqrt(members.length).ceil().clamp(2, 5);
        final rowsInBox = (members.length / colsInBox).ceil().clamp(1, 999);
        final boxWidth = max(420.0, colsInBox * nodeSpacingX + 60.0);
        final boxHeight = max(240.0, rowsInBox * nodeSpacingY + 80.0);

        fileGroups[file] = Rect.fromLTWH(currentX, currentY, boxWidth, boxHeight);

        for (var k = 0; k < members.length; k++) {
          final r = k ~/ colsInBox;
          final colIdx = k % colsInBox;
          positions[members[k].id] = Offset(
            currentX + 60 + colIdx * nodeSpacingX,
            currentY + 60 + r * nodeSpacingY,
          );
        }

        currentX += boxWidth + padding;
        maxHeightInRow = max(maxHeightInRow, boxHeight);
      }

      maxColumnX = max(maxColumnX, currentX);
      currentY += maxHeightInRow + padding;
    }

    return GraphLayout(
      positions: positions,
      fileGroups: fileGroups,
      contentSize: Size(
        max(1600.0, maxColumnX),
        max(1200.0, currentY + 100),
      ),
    );
  }

  static GraphLayout _callFlowLayout(TopologyGraphDataModel data) {
    final byLevel = <int, List<TopologyNodeModel>>{};
    for (final n in data.nodes) {
      byLevel.putIfAbsent(n.dagLevel, () => []).add(n);
    }

    const levelHeight = 190.0;
    const nodeGap = 140.0;
    const paddingX = 100.0;
    const paddingY = 80.0;

    final positions = <String, Offset>{};
    final maxLevel = byLevel.keys.isEmpty ? 0 : byLevel.keys.reduce(max);
    var maxWidth = 0.0;

    for (var lvl = 0; lvl <= maxLevel; lvl++) {
      final nodesAtLevel = byLevel[lvl] ?? const <TopologyNodeModel>[];
      nodesAtLevel.sort((a, b) => a.qualifiedName.compareTo(b.qualifiedName));

      for (var i = 0; i < nodesAtLevel.length; i++) {
        positions[nodesAtLevel[i].id] = Offset(
          paddingX + i * nodeGap,
          paddingY + lvl * levelHeight,
        );
      }
      maxWidth = max(maxWidth, nodesAtLevel.length * nodeGap);
    }

    return GraphLayout(
      positions: positions,
      contentSize: Size(
        max(1600.0, maxWidth + paddingX * 2),
        max(1200.0, (maxLevel + 1) * levelHeight + paddingY * 2),
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\layout_engine.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\path_tracer_panel.dart -->
# FILE: path_tracer_panel.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\path_tracer_panel.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/path_tracer_panel.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../providers/code_topology_provider.dart';

class PathTracerPanel extends ConsumerStatefulWidget {
  final TopologyGraphDataModel graphData;
  const PathTracerPanel({super.key, required this.graphData});

  @override
  ConsumerState<PathTracerPanel> createState() => _PathTracerPanelState();
}

class _PathTracerPanelState extends ConsumerState<PathTracerPanel> {
  bool _directed = false;

  @override
  Widget build(BuildContext context) {
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);
    final index = ref.watch(graphIndexProvider);

    if (pathStart == null && pathEnd == null) {
      return const SizedBox.shrink();
    }

    final path = (pathStart != null && pathEnd != null && index != null)
        ? index.tracePathLocal(pathStart.id, pathEnd.id, directed: _directed)
        : null;

    return Container(
      width: 320,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF30363D)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.route_rounded, color: Color(0xFF00E676), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Shortest Path Tracer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white70),
                onPressed: () {
                  ref.read(pathStartNodeProvider.notifier).state = null;
                  ref.read(pathEndNodeProvider.notifier).state = null;
                },
              ),
            ],
          ),
          const Divider(color: Color(0xFF30363D)),

          // Start & End Pickers
          _NodePickerTile(
            label: 'Start (A)',
            node: pathStart,
            color: const Color(0xFF42A5F5),
            onClear: () => ref.read(pathStartNodeProvider.notifier).state = null,
          ),
          const SizedBox(height: 6),
          _NodePickerTile(
            label: 'Target (B)',
            node: pathEnd,
            color: const Color(0xFFAB47BC),
            onClear: () => ref.read(pathEndNodeProvider.notifier).state = null,
          ),
          const SizedBox(height: 10),

          // Directed Toggle
          Row(
            children: [
              const Text(
                'Directed Call Edges',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Switch(
                value: _directed,
                onChanged: (val) => setState(() => _directed = val),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Hop-by-Hop Call Chain Sequence List
          if (path != null && path.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0x2200E676),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Path Found: ${path.length - 1} Call Hop(s)',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: path.length,
                separatorBuilder: (_, __) => const Icon(
                  Icons.south_rounded,
                  size: 14,
                  color: Color(0xFF00E676),
                ),
                itemBuilder: (context, i) {
                  final nodeId = path[i];
                  final node = index?.nodeMap[nodeId];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${i + 1}. ${node?.qualifiedName ?? nodeId}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ] else if (pathStart != null && pathEnd != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No call path connects Start and Target.',
                style: TextStyle(color: Color(0xFFEF5350), fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NodePickerTile extends StatelessWidget {
  final String label;
  final TopologyNodeModel? node;
  final Color color;
  final VoidCallback onClear;

  const _NodePickerTile({
    required this.label,
    required this.node,
    required this.color,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 4, backgroundColor: color),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              node?.qualifiedName ?? 'Select from canvas...',
              style: TextStyle(
                color: node != null ? Colors.white : Colors.white38,
                fontSize: 11,
                fontWeight: node != null ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (node != null)
            GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white54),
            ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\path_tracer_panel.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart -->
# FILE: symbol_inspector_drawer.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart`

// File: client_flutter/lib/features/code_visualizer/presentation/widgets/symbol_inspector_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/topology_models.dart';
import '../../models/topology_insights.dart';
import '../../providers/code_topology_provider.dart';

class SymbolInspectorDrawer extends ConsumerWidget {
  final TopologyNodeModel node;
  const SymbolInspectorDrawer({super.key, required this.node});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final pathStart = ref.watch(pathStartNodeProvider);
    final pathEnd = ref.watch(pathEndNodeProvider);

    final isStart = pathStart?.id == node.id;
    final isEnd = pathEnd?.id == node.id;

    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(left: BorderSide(color: cs.outlineVariant)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title & Close Button
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.qualifiedName,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    ref.read(selectedNodeProvider.notifier).state = null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              '${node.file}:${node.line}',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),

            // Shortest Path Tracer Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isStart ? Icons.check_circle_rounded : Icons.play_arrow_rounded, size: 14),
                    label: Text(isStart ? 'Path Start' : 'Set Start', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isStart ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathStartNodeProvider.notifier).state = isStart ? null : node;
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(isEnd ? Icons.check_circle_rounded : Icons.flag_rounded, size: 14),
                    label: Text(isEnd ? 'Path End' : 'Set End', style: const TextStyle(fontSize: 10)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      side: BorderSide(color: isEnd ? Colors.green : cs.outlineVariant),
                    ),
                    onPressed: () {
                      ref.read(pathEndNodeProvider.notifier).state = isEnd ? null : node;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Insight Badges
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (node.isGodFunction)
                  _badge('👑 God Function', const Color(0xFFAB47BC)),
                if (node.isDeadCode)
                  _badge('💀 Dead Code', const Color(0xFF757575)),
                if (node.isHighRisk)
                  _badge('⚠️ High Risk', const Color(0xFFEF5350)),
                if (node.isHub) _badge('🔥 Hub', const Color(0xFFFFA726)),
                if (node.isPublic) _badge('Public', const Color(0xFF42A5F5)),
                if (node.isTest) _badge('Test', const Color(0xFF26A69A)),
              ],
            ),
            const SizedBox(height: 18),

            _metricRow('Complexity', node.complexity.toString(),
                warn: node.exceedsComplexityThreshold),
            _metricRow('Lines of Code', node.loc.toString(),
                warn: node.exceedsLocThreshold),
            _metricRow('Params', node.params.length.toString(),
                warn: node.exceedsParamThreshold),
            _metricRow('Fan In', node.fanIn.toString()),
            _metricRow('Fan Out', node.fanOut.toString()),
            _metricRow('Risk Score', node.riskScore.toStringAsFixed(1),
                warn: node.riskScore >= 7.0),
            if (node.returnType != null)
              _metricRow('Returns', node.returnType!),
            const SizedBox(height: 16),
            if (node.intent != null) ...[
              Text(
                'Intent',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 4),
              Text(node.intent!, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 16),
            ],
            if (node.params.isNotEmpty) ...[
              Text(
                'Parameters',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              ...node.params.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${p.name}: ${p.type}${p.isOptional ? '?' : ''}',
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (node.sideEffects.isNotEmpty) ...[
              Text(
                'Side Effects',
                style: TextStyle(
                    fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: node.sideEffects
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 10)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _metricRow(String label, String value, {bool warn = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: warn ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\presentation\widgets\symbol_inspector_drawer.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart -->
# FILE: code_topology_provider.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart`

// File: client_flutter/lib/features/code_visualizer/providers/code_topology_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/topology_models.dart';
import '../models/topology_insights.dart';
import '../presentation/widgets/layout_engine.dart';
import 'topology_data_source.dart';

final selectedNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final searchQueryProvider = StateProvider<String>((ref) => '');
final activeWorkspacePathProvider =
    StateProvider<String>((ref) => 'c:/horaizon-3.0/shua_code_visualizer/src');

final selectedLayoutModeProvider =
    StateProvider<LayoutMode>((ref) => LayoutMode.physics);

// Graphify Filters & Shortest Path Providers
final activeFiltersProvider =
    StateProvider<Set<InsightFilter>>((ref) => <InsightFilter>{});
final filterMatchAllProvider = StateProvider<bool>((ref) => false); // false = OR, true = AND
final isolationDepthProvider = StateProvider<int>((ref) => 0); // 0 = off, 1 = 1-hop, 2 = 2-hop

final pathStartNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);
final pathEndNodeProvider = StateProvider<TopologyNodeModel?>((ref) => null);

// Dynamic Physics Tuning Providers (Calm, stable defaults)
final physicsRepulsionProvider = StateProvider<double>((ref) => 12000.0);
final physicsSpringProvider = StateProvider<double>((ref) => 0.05);
final physicsModuleAttractorProvider = StateProvider<double>((ref) => 0.035);
final physicsGravityProvider = StateProvider<double>((ref) => 0.003);
final physicsMaxVelocityProvider = StateProvider<double>((ref) => 32.0);
final physicsDampingProvider = StateProvider<double>((ref) => 0.80);

/// Provider constructing the active TopologyDataSource (Standalone vs Managed)
final topologyDataSourceProvider = Provider<TopologyDataSource>((ref) {
  final targetPath = ref.watch(activeWorkspacePathProvider);
  return StandaloneDataSource(workspacePath: targetPath);
});

/// StreamProvider broadcasting live TopologyDeltaEvents over Managed WebSocket IPC
final topologyDeltaStreamProvider = StreamProvider<TopologyDeltaEvent>((ref) {
  final dataSource = ref.watch(topologyDataSourceProvider);
  return dataSource.deltaStream ?? const Stream<TopologyDeltaEvent>.empty();
});

/// FutureProvider loading the current TopologyGraphDataModel snapshot
final codeTopologyProvider = FutureProvider<TopologyGraphDataModel>((ref) async {
  final dataSource = ref.watch(topologyDataSourceProvider);
  return dataSource.loadSnapshot();
});

/// Provider computing and caching the GraphIndex structure once per graph snapshot
final graphIndexProvider = Provider<GraphIndex?>((ref) {
  final topologyAsync = ref.watch(codeTopologyProvider);
  return topologyAsync.when(
    data: (graphData) => GraphIndex.build(graphData),
    loading: () => null,
    error: (_, __) => null,
  );
});


<!-- END_FILE: client_flutter\lib\features\code_visualizer\providers\code_topology_provider.dart -->
================================================================================

<!-- START_FILE: client_flutter\lib\features\code_visualizer\providers\topology_data_source.dart -->
# FILE: topology_data_source.dart
**Relative Path**: `client_flutter\lib\features\code_visualizer\providers\topology_data_source.dart`

// File: client_flutter/lib/features/code_visualizer/providers/topology_data_source.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/topology_models.dart';

/// Pre-indexed graph lookup structure built once per TopologyGraphDataModel snapshot
class GraphIndex {
  final TopologyGraphDataModel graphData;
  final Map<String, TopologyNodeModel> nodeMap;
  final Map<String, List<String>> forwardAdjacency;
  final Map<String, List<String>> reverseAdjacency;
  final Map<String, List<String>> undirectedAdjacency;

  GraphIndex._({
    required this.graphData,
    required this.nodeMap,
    required this.forwardAdjacency,
    required this.reverseAdjacency,
    required this.undirectedAdjacency,
  });

  factory GraphIndex.build(TopologyGraphDataModel data) {
    final nodeMap = {for (final n in data.nodes) n.id: n};
    final fwd = <String, List<String>>{};
    final rev = <String, List<String>>{};
    final undir = <String, List<String>>{};

    for (final e in data.edges) {
      fwd.putIfAbsent(e.from, () => []).add(e.to);
      rev.putIfAbsent(e.to, () => []).add(e.from);

      undir.putIfAbsent(e.from, () => []).add(e.to);
      undir.putIfAbsent(e.to, () => []).add(e.from);
    }

    return GraphIndex._(
      graphData: data,
      nodeMap: nodeMap,
      forwardAdjacency: fwd,
      reverseAdjacency: rev,
      undirectedAdjacency: undir,
    );
  }

  /// Fast client-side BFS shortest path tracer fallback
  List<String>? tracePathLocal(String fromId, String toId, {bool directed = false}) {
    if (fromId == toId) return [fromId];
    final adj = directed ? forwardAdjacency : undirectedAdjacency;

    final parent = <String, String>{};
    final visited = <String>{fromId};
    final queue = <String>[fromId];

    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      if (curr == toId) {
        final path = <String>[];
        String? step = toId;
        while (step != null) {
          path.insert(0, step);
          step = parent[step];
        }
        return path;
      }

      for (final next in adj[curr] ?? const <String>[]) {
        if (!visited.contains(next)) {
          visited.add(next);
          parent[next] = curr;
          queue.add(next);
        }
      }
    }
    return null; // Disconnected
  }

  /// Fast client-side BFS blast radius N-hop caller calculation fallback
  Set<String> blastRadiusLocal(String nodeId, {int maxDepth = 3}) {
    final affected = <String>{nodeId};
    var queue = <String>[nodeId];

    for (int depth = 0; depth < maxDepth; depth++) {
      final nextQueue = <String>[];
      for (final curr in queue) {
        for (final caller in reverseAdjacency[curr] ?? const <String>[]) {
          if (affected.add(caller)) {
            nextQueue.add(caller);
          }
        }
      }
      queue = nextQueue;
      if (queue.isEmpty) break;
    }
    return affected;
  }
}

/// Abstract data source interface decoupling Standalone vs Managed Subprocess modes
abstract class TopologyDataSource {
  Future<TopologyGraphDataModel> loadSnapshot();
  Stream<TopologyDeltaEvent>? get deltaStream;
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false});
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3});
}

/// Standalone Mode Data Source (reads CLI stdout / local disk export)
class StandaloneDataSource implements TopologyDataSource {
  final String workspacePath;
  StandaloneDataSource({required this.workspacePath});

  @override
  Stream<TopologyDeltaEvent>? get deltaStream => null;

  @override
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false}) async => null;

  @override
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3}) async => {nodeId};

  @override
  Future<TopologyGraphDataModel> loadSnapshot() async {
    const binaryPath = 'c:/horaizon-3.0/shua_code_visualizer/target/debug/shua_code_visualizer.exe';

    // 1. Try running shua_code_visualizer CLI and reading output
    try {
      final tempOut = '${Directory.systemTemp.path}/code_viz_dynamic_graph.json';
      if (await File(binaryPath).exists()) {
        final res = await Process.run(binaryPath, [
          '--workspace-root',
          workspacePath,
          '--export-graph',
          tempOut,
        ]);

        if (res.exitCode == 0) {
          final file = File(tempOut);
          if (await file.exists()) {
            final text = await file.readAsString();
            final jsonMap = jsonDecode(text) as Map<String, dynamic>;
            return TopologyGraphDataModel.fromJson(jsonMap);
          }
        } else {
          debugPrint('StandaloneDataSource process error: ${res.stderr}');
        }
      }
    } catch (e) {
      debugPrint('StandaloneDataSource subprocess exception: $e');
    }

    // 2. Fallback: Read pre-exported file from root disk
    try {
      const diskPath = 'c:/horaizon-3.0/code_viz_graph_output.json';
      final file = File(diskPath);
      if (await file.exists()) {
        final text = await file.readAsString();
        final jsonMap = jsonDecode(text) as Map<String, dynamic>;
        return TopologyGraphDataModel.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('StandaloneDataSource disk fallback exception: $e');
    }

    // 3. Asset fallback
    try {
      final assetStr = await rootBundle.loadString('assets/code_viz_graph_output.json');
      final jsonMap = jsonDecode(assetStr) as Map<String, dynamic>;
      return TopologyGraphDataModel.fromJson(jsonMap);
    } catch (_) {}

    return const TopologyGraphDataModel(nodes: [], edges: []);
  }
}

/// Managed Subprocess Mode Data Source (Connects over HBP v2 WebSocket IPC)
class ManagedDataSource implements TopologyDataSource {
  final String wsUrl;
  WebSocket? _socket;
  final _deltaController = StreamController<TopologyDeltaEvent>.broadcast();

  ManagedDataSource({this.wsUrl = 'ws://127.0.0.1:7700/hbp'});

  @override
  Stream<TopologyDeltaEvent> get deltaStream => _deltaController.stream;

  @override
  Future<List<String>?> tracePath(String fromId, String toId, {bool directed = false}) async {
    return null;
  }

  @override
  Future<Set<String>> blastRadius(String nodeId, {int maxDepth = 3}) async {
    return {nodeId};
  }

  @override
  Future<TopologyGraphDataModel> loadSnapshot() async {
    try {
      _socket = await WebSocket.connect(wsUrl);
      _socket!.listen((data) {
        if (data is String) {
          final jsonMap = jsonDecode(data) as Map<String, dynamic>;
          if (jsonMap.containsKey('affected_node_ids')) {
            _deltaController.add(TopologyDeltaEvent.fromJson(jsonMap));
          }
        }
      });
    } catch (e) {
      debugPrint('ManagedDataSource WebSocket connect error: $e');
    }
    return StandaloneDataSource(workspacePath: 'c:/horaizon-3.0/shua_code_visualizer/src').loadSnapshot();
  }

  void dispose() {
    _socket?.close();
    _deltaController.close();
  }
}


<!-- END_FILE: client_flutter\lib\features\code_visualizer\providers\topology_data_source.dart -->
================================================================================

<!-- START_FILE: _architecture\tasks\active\TASK-015B_shua_code_visualizer_advanced_analysis.md -->
# FILE: TASK-015B_shua_code_visualizer_advanced_analysis.md
**Relative Path**: `_architecture\tasks\active\TASK-015B_shua_code_visualizer_advanced_analysis.md`

# TASK-015B — `shua_code_visualizer` Advanced Analysis & History (Deferred)

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Deferred — not started |
| **Phase** | Phase 2 (or later — not required for TASK-016 to ship) |
| **Type** | AI-executable |
| **Language** | Rust |
| **Target** | `shua_modules/shua_code_visualizer/` (extends TASK-015A) |
| **Blocks** | None |
| **Prerequisites** | TASK-015A complete, registered with `shua_governor`, and in real use for at least one refactor cycle (recommended, not mandatory) |
| **References** | `_architecture/reference/shua_code_visualizer/src/debug/ghost_imports.rs`, `src/export/git_diff.rs` (horAIzon 2.0 — revived here) |

---

## Purpose

TASK-015A gives you the live signature/risk map. TASK-015B adds *history and cross-cutting analysis* on top of it — the features that need either git history, snapshots over time, or cross-file/cross-language pattern matching, none of which are required for TASK-016's initial UI to function. Explicitly deferred, not dropped.

---

## Key Modules & Subtasks

### 1. Git Churn Integration (`src/history/git_diff.rs`)

- [ ] 1.1 Port git-diff-chunk → symbol mapping from horAIzon 2.0's `git_diff.rs` (logic is directly reusable, only the output shape needs to change to match TASK-015A's `GraphNode`/qualified-path model).
- [ ] 1.2 Track per-symbol churn count (number of commits touching that symbol's line range) over a configurable window (default: last 90 days).
- [ ] 1.3 `priority_score = risk_score * churn_count` — combines "risky and messy" (TASK-015A §6) with "changes constantly," which is the actual top-of-list refactor target.
- [ ] 1.4 New MCP tool: `code_top_priority_refactors` — input `{module_path: Option<string>, limit: u32 = 20}`, returns nodes sorted by `priority_score` descending.

### 2. Ghost Import / Unused Import Detector (`src/debug/ghost_imports.rs`)

- [ ] 2.1 Port detection logic from horAIzon 2.0's `debug/ghost_imports.rs` directly — this module needs minimal changes since it operates independently of the graph/risk work in 015A.
- [ ] 2.2 New MCP tool: `code_find_unused_imports` — input `{module_path: Option<string>}`, returns per-file list of unused imports.

### 3. Duplicate / Near-Duplicate Signature Clustering (`src/graph/duplicates.rs`)

- [ ] 3.1 Normalized signature similarity metric: name similarity (edit distance or token overlap) + param-shape similarity (count, type sequence).
- [ ] 3.2 Configurable clustering threshold (default: flag pairs above 0.85 similarity).
- [ ] 3.3 Cross-language mode (optional flag): compare normalized signatures across a Rust/Dart pair, useful for catching intentional-boundary-mirror vs accidental-copy-paste-drift, distinct from TASK-015A's `code_check_contract_drift` (which checks *tagged* boundary pairs; this checks *untagged*, opportunistically discovered similarity).
- [ ] 3.4 New MCP tool: `code_find_duplicate_signatures` — input `{module_path: Option<string>, cross_language: bool = false}`, returns clusters of similar signatures.

### 4. Public API Diff / Breaking-Change Detector (`src/history/api_diff.rs`)

- [ ] 4.1 Snapshot all `pub`/exported signatures on each full scan, keyed by git ref (or timestamp if no git context available), persisted alongside the §4 hash index from TASK-015A.
- [ ] 4.2 Diff logic: compare two snapshots, classify each symbol as `Added`, `Removed`, or `Changed` (with the specific field/type that changed for `Changed`).
- [ ] 4.3 New MCP tool: `code_diff_public_api` — input `{from_ref: string, to_ref: string}` (git refs) or `{from_snapshot_id, to_snapshot_id}`, returns the classified diff list.

### 5. Automatic Contract-Drift Discovery (extends TASK-015A §9)

- [ ] 5.1 Replace TASK-015A's manual `@hbp_boundary` tagging requirement with heuristic discovery: cross-reference struct names appearing in `hbp_*.toml` schema files and `mcp_master_spec.md` against parsed Rust/Dart/TS struct definitions, and auto-pair by name match.
- [ ] 5.2 Fall back to manual tagging (TASK-015A §9.1) for anything the heuristic can't confidently pair.
- [ ] 5.3 `code_check_contract_drift` (TASK-015A §9.3) gains an optional `{auto_discover: bool}` input flag — when true, skips the `boundary_tag` requirement and runs the full auto-discovered pair set.

---

## Acceptance Criteria

- [ ] `code_top_priority_refactors`, `code_find_unused_imports`, `code_find_duplicate_signatures`, `code_diff_public_api` are registered with `shua_governor` as MCP tools under scope `"code"`.
- [ ] Churn tracking correctly attributes commits to symbol qualified-paths across a file rename (i.e. doesn't silently lose churn history when a file moves).
- [ ] Duplicate-signature clustering produces zero false positives on TASK-015A's own codebase above the default 0.85 threshold (sanity check before shipping the default).
- [ ] `code_diff_public_api` correctly flags a deliberately introduced breaking change (manual test: rename a `pub fn` param) between two git refs.
- [ ] Auto-discovered contract-drift pairing correctly identifies the `GraphNode` Rust↔Dart↔toml relationship from TASK-015A without manual tagging.
- [ ] All new tools' schemas are exported via TASK-015A §3.2's schema-sync mechanism — no hand-written schema docs.


<!-- END_FILE: _architecture\tasks\active\TASK-015B_shua_code_visualizer_advanced_analysis.md -->
================================================================================

<!-- START_FILE: _architecture\tasks\active\TASK-015T_shua_code_visualizer_test_fixture.md -->
# FILE: TASK-015T_shua_code_visualizer_test_fixture.md
**Relative Path**: `_architecture\tasks\active\TASK-015T_shua_code_visualizer_test_fixture.md`

# TASK-015T — Golden-Answer Test Fixture for `shua_code_visualizer`

| Field | Value |
| :--- | :--- |
| **Status** | [ ] Not Started |
| **Phase** | Phase 2 (build alongside or immediately after TASK-015A) |
| **Type** | AI-executable (fixture code can be AI-generated per §1 constraints below) |
| **Language** | Rust (test harness), Rust/Dart/Go/Python/TS (fixture code) |
| **Target** | `shua_modules/shua_code_visualizer/test_fixtures/golden_repo/` |
| **Blocks** | None — but should exist before TASK-015A is marked "done," not after |
| **Prerequisites** | TASK-015A modules implemented enough to run against fixture files (can develop in parallel — write fixtures + expected answers first, then use them as the acceptance test while building 015A) |

---

## Purpose

A small, hand-designed multi-language codebase where every "interesting" answer is known in advance: which function is called the most, which one is dead, which one is a god-function, which pair of structs has drifted across the HBP boundary. Every 015A tool that has real logic (not just AST reshaping) gets checked against this fixture instead of eyeballed against your real repo.

---

## 1. Fixture Design Constraints (read this before generating fixture code, AI or otherwise)

- [ ] 1.1 Every planted "answer" must be countable by a human in under a minute just by reading the file — no clever indirection, no macro-generated calls, no dynamic dispatch that obscures the call graph. The fixture's job is to be unambiguous, not realistic.
- [ ] 1.2 Name things so the intent is obvious in the code itself (e.g. `fn deliberately_unused_helper()`, `fn god_function_six_params(...)`) — makes it easy to verify by inspection that the fixture matches `expected_answers.toml`, and easy to re-verify after any fixture edit.
- [ ] 1.3 Keep total fixture size small (aim for <300 lines across all languages combined) — this is a correctness corpus, not a performance corpus. Performance gets tested against your real repo separately (already covered by TASK-015A §4.7).
- [ ] 1.4 Every language subfolder needs at minimum: one high-fan-in function, one dead/orphan function, one god-function (exceeds at least 2 of the 3 thresholds), one clean/unremarkable function (negative control — must NOT be flagged by anything).

---

## 2. Fixture Contents

### 2.1 Per-language basic corpus (`test_fixtures/golden_repo/{rust,dart,go,python,typescript}/`)

- [ ] `rust/orders.rs`:
  - `calculate_total(...)` — called from 5 other functions in this file → **fan_in = 5**, the deliberate "most-called" answer.
  - `apply_discount(a,b,c,d,e,f)` — 6 params, complexity ≥ 12 (nested `if`/`match`) → deliberate god-function, should trip `exceeds_param_threshold` **and** `exceeds_complexity_threshold`.
  - `deliberately_unused_helper()` — not `pub`, zero callers, not `main`, not test-annotated → deliberate `is_orphan = true`.
  - `main()` — zero callers but must **not** be flagged orphan (entrypoint allowlist test).
  - `clean_add(a: i32, b: i32) -> i32` — negative control, must trip zero flags.
- [ ] `dart/order_service.dart` — mirrors `orders.rs` structurally: one high-fan-in method, one near-duplicate of `calculate_total` (for TASK-015B's duplicate-signature clustering, if/when that's tested), one orphan, one clean control.
- [ ] `go/`, `python/`, `typescript/` — same four-symbol pattern (high-fan-in / orphan / god-function / clean control) minimally, one file each. Doesn't need the duplicate/mirror complexity Dart has — just proves each language's tree-sitter grammar extracts complexity, params, and calls correctly.

### 2.2 Cross-boundary contract pair (`test_fixtures/golden_repo/cross_boundary/`)

- [ ] `rust/graph_node.rs` — a `GraphNode` struct tagged `/// @hbp_boundary: GraphNode`, matching TASK-015A §3.3's real shape (subset is fine: id, kind, complexity, fan_in).
- [ ] `dart/graph_node_model.dart` — the paired Dart model, tagged the same way, with **one deliberately mismatched field** (e.g. `complexity: int` in Rust vs `complexity: double` in Dart, or a renamed field like `fanIn` vs the expected `fan_in`). This is the planted answer for `code_check_contract_drift`.

### 2.3 Watcher / incremental-diff scenario (`test_fixtures/golden_repo/watch_scenario/`)

- [ ] `v1/counter.rs` — baseline: two functions, `increment` and `reset`.
- [ ] `v2/counter.rs` — modified: `increment`'s signature changes (param added), a new function `decrement` is added, `reset` is deleted.
- [ ] Test harness copies `v1` into a scratch dir, runs a full scan, then overwrites with `v2`'s content and triggers the watcher, asserting the resulting `TopologyDeltaEvent` reports exactly: 1 modified (`increment`), 1 added (`decrement`), 1 removed (`reset`) — validates TASK-015A §4.4 patch logic, not just full-scan correctness.

- [ ] Reuse `orders.rs` — asserted blast radius of `calculate_total` at depth 1 must be exactly its 5 known callers, no more, no less, and must resolve by qualified path (add a second, unrelated `calculate_total` in a different module/file in the fixture specifically to catch any accidental bare-name-match regression — this directly tests the fix for the horAIzon 2.0 substring-fallback bug).

### 2.5 Unresolved callee scenario

- [ ] Method call on a variable instance (e.g. `worker.run()`) in fixture code. Test harness asserts that building the graph with dangling edges completes cleanly without panicking and drops/tags unresolved target edges without corrupting `fan_in` metrics.


---

## 3. Expected Answers File

- [ ] `test_fixtures/golden_repo/expected_answers.toml` — hand-written, not generated, and reviewed by you line-by-line since this is the ground truth everything else is graded against. One entry per planted symbol:
  ```toml
  [["rust::orders::calculate_total"]]
  fan_in = 5
  is_orphan = false
  exceeds_complexity_threshold = false

  [["rust::orders::apply_discount"]]
  exceeds_param_threshold = true
  exceeds_complexity_threshold = true

  [["rust::orders::deliberately_unused_helper"]]
  is_orphan = true

  [["rust::orders::main"]]
  is_orphan = false   # entrypoint allowlist

  [["cross_boundary::GraphNode"]]
  drift_expected = true
  drift_field = "complexity"  # or whichever field you plant as mismatched
  ```

---

## 4. Test Harness (`shua_modules/shua_code_visualizer/tests/golden_repo_test.rs`)

- [ ] 4.1 Runs a full scan against `test_fixtures/golden_repo/` and loads `expected_answers.toml`.
- [ ] 4.2 One `#[test]` per tool being validated:
  - `test_fan_in_matches_expected` — checks `calculate_total.fan_in == 5`.
  - `test_god_function_flags` — checks `apply_discount` trips both flags, `clean_add` trips none.
  - `test_dead_code_detection` — checks `deliberately_unused_helper` is flagged, `main` is not.
  - `test_blast_radius_qualified_resolution` — checks the duplicate-name trap in §2.4 resolves correctly.
  - `test_contract_drift_detected` — checks `code_check_contract_drift` flags the planted mismatch in §2.2, and does **not** false-positive on any correctly-matched fields.
  - `test_watcher_incremental_diff` — runs the §2.3 v1→v2 scenario, asserts the exact added/modified/removed set.
- [ ] 4.3 This test suite becomes a required CI gate for TASK-015A — no PR to `shua_code_visualizer` merges if `golden_repo_test.rs` fails.

---

## Acceptance Criteria

- [ ] `test_fixtures/golden_repo/` exists with all files from §2, each planted answer traceable by reading the file (per §1.1/1.2).
- [ ] `expected_answers.toml` exists and has been manually reviewed against the fixture code (not generated by the same process being tested).
- [ ] All six tests in §4.2 pass against a working TASK-015A build.
- [ ] Deliberately breaking one piece of logic (e.g. reverting qualified-path resolution to bare-name matching) causes `test_blast_radius_qualified_resolution` to fail — i.e. the test suite is verified to actually catch the regression it's designed for, not just pass trivially.


<!-- END_FILE: _architecture\tasks\active\TASK-015T_shua_code_visualizer_test_fixture.md -->
================================================================================

