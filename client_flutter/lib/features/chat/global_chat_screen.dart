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
                            return '[Turn ${s.turn} · ${s.stepTypeLabel}]\n${body.isNotEmpty ? body : ""}${tools.isNotEmpty ? "\n" + tools : ""}';
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
                            return '[Turn ${s.turn} · ${s.stepTypeLabel}]\n${body.isNotEmpty ? body : ""}${tools.isNotEmpty ? "\n" + tools : ""}';
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
                  else if (message.content.isNotEmpty)
                    FormattedMarkdownContent(content: message.content),
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
