import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ollama_ai_service.dart';
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
      ref.read(globalChatProvider.notifier).sendMessage(text);
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

          // Model & Target Host Selector Controls Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: cs.surfaceContainer,
            child: Row(
              children: [
                // Model Dropdown
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: chatState.availableModels.contains(chatState.selectedModel)
                            ? chatState.selectedModel
                            : (chatState.availableModels.isNotEmpty ? chatState.availableModels.first : 'qwen3.5:4b'),
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down_rounded, size: 18),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.onSurface),
                        items: chatState.availableModels.map((m) {
                          return DropdownMenuItem<String>(
                            value: m,
                            child: Text(m, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(globalChatProvider.notifier).setSelectedModel(val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Host Target Dropdown (RPi 5 vs Laptop)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AiOffloadTarget>(
                      value: chatState.offloadTarget,
                      icon: const Icon(Icons.dns_rounded, size: 14),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: cs.primary),
                      items: AiOffloadTarget.values.map((t) {
                        return DropdownMenuItem<AiOffloadTarget>(
                          value: t,
                          child: Text(t.displayName, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                      onChanged: (target) {
                        if (target != null) {
                          ref.read(globalChatProvider.notifier).setOffloadTarget(target);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Multi-Line Wrapping Quick Action Chips
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: cs.surfaceContainerLow,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: defaultChips.map((chipLabel) {
                return ActionChip(
                  label: Text(chipLabel, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
