import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_effects_theme.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../chat/models/chat_message.dart';
import '../../chat/providers/global_chat_provider.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Shua Governor AI Aggregator Hero Card with model selector modal, Laptop Offload toggle,
/// and live Mini Chat Preview connected to GlobalChatProvider.
class AiAggregatorHero extends ConsumerStatefulWidget {
  final GovernorStatus status;

  const AiAggregatorHero({super.key, required this.status});

  @override
  ConsumerState<AiAggregatorHero> createState() => _AiAggregatorHeroState();
}

class _AiAggregatorHeroState extends ConsumerState<AiAggregatorHero> {
  final TextEditingController _miniPromptController = TextEditingController();

  @override
  void dispose() {
    _miniPromptController.dispose();
    super.dispose();
  }

  static const _availableModels = [
    _ModelOption(name: 'qwen2.5-coder:7b', desc: 'Code & Technical Architecture Specialist', ramMb: 4420),
    _ModelOption(name: 'qwen2.5:3b', desc: 'Balanced Local Reasoning & Chat', ramMb: 2450),
    _ModelOption(name: 'qwen2.5:1.5b', desc: 'Fast Edge Dialogue & Routing', ramMb: 1840),
    _ModelOption(name: 'llama3.1:8b', desc: 'Meta High-Capacity Reasoning', ramMb: 4800),
  ];

  void _showModelSelectorModal(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final activeModel = ref.read(globalChatProvider).selectedModel;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
        ),
        title: Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Select Ollama AI Model',
              style: TextStyle(color: cs.onSurface, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _availableModels.map((m) {
              final isSelected = activeModel == m.name;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary.withValues(alpha: 0.15) : cs.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: ListTile(
                    dense: true,
                    title: Text(
                      m.name,
                      style: TextStyle(
                        color: isSelected ? cs.primary : cs.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      '${m.desc} • ~${m.ramMb} MB',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                    ),
                    trailing: isSelected ? Icon(Icons.check_circle_rounded, color: cs.primary, size: 18) : null,
                    onTap: () {
                      ref.read(globalChatProvider.notifier).setSelectedModel(m.name);
                      Navigator.of(ctx).pop();
                    },
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _submitMiniPrompt() {
    final text = _miniPromptController.text.trim();
    if (text.isNotEmpty) {
      _miniPromptController.clear();
      ref.read(globalChatProvider.notifier).sendMessage(text);
      context.go('/chat');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final successColor = semantic?.success ?? cs.primary;
    final infoColor = semantic?.info ?? cs.secondary;

    final chatState = ref.watch(globalChatProvider);
    final (lastUser, lastAssistant) = chatState.lastExchange;

    final target = chatState.offloadTarget;
    final activeModel = chatState.selectedModel;
    final vramMb = widget.status.ollamaRamMb ?? 1840.0;

    final (badgeText, badgeColor) = switch (target) {
      AiOffloadTarget.auto => ('Auto (Governor Router)', cs.primary),
      AiOffloadTarget.rpi5 => ('RPi5 Local Engine', successColor),
      AiOffloadTarget.windowsHost => ('Windows Host Offload', infoColor),
    };

    return StitchCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, color: cs.primary, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'SHUA GOVERNOR',
                        style: TextStyle(
                          color: cs.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'AI Aggregator',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: badgeColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Active Model & Parameter Controls Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        'Active Model',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showModelSelectorModal(context, ref),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeModel,
                                  style: TextStyle(color: cs.onSurface, fontSize: 12, fontWeight: FontWeight.w600),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down_rounded, color: cs.primary, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ollama VRAM Allocation',
                      style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${vramMb.toStringAsFixed(0)} MB',
                      style: TextStyle(color: cs.primary, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (vramMb / 4096.0).clamp(0.0, 1.0),
                    backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Mini Chat Preview Connected to Global Chat State
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 14, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'MINI AI CHAT PREVIEW',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.go('/chat'),
                      child: Text(
                        'Full Chat Page ↗',
                        style: TextStyle(color: cs.primary, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (lastUser != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👤 ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                          lastUser.content,
                          style: TextStyle(color: cs.onSurface, fontSize: 11, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (lastAssistant != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🤖 ', style: TextStyle(fontSize: 11)),
                      Expanded(
                        child: Text(
                          lastAssistant.content.isEmpty ? 'Typing...' : lastAssistant.content,
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ] else if (lastUser == null) ...[
                  Text(
                    'No chat messages yet. Enter prompt below to start.',
                    style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.6), fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _miniPromptController,
                        style: TextStyle(color: cs.onSurface, fontSize: 11),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Type prompt to JOSH...',
                          hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 11),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: cs.outlineVariant),
                          ),
                        ),
                        onSubmitted: (_) => _submitMiniPrompt(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      icon: Icon(Icons.send_rounded, size: 16, color: cs.primary),
                      onPressed: _submitMiniPrompt,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                ),
                onPressed: () => _showModelSelectorModal(context, ref),
                child: const Text(
                  'Select Model',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  target == AiOffloadTarget.auto
                      ? Icons.auto_awesome_rounded
                      : (target == AiOffloadTarget.windowsHost ? Icons.laptop_mac_rounded : Icons.developer_board_rounded),
                  size: 14,
                  color: cs.primary,
                ),
                label: Text(
                  'Route: ${target.shortLabel}',
                  style: TextStyle(color: cs.onSurface, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                ),
                onPressed: () {
                  final nextTarget = switch (target) {
                    AiOffloadTarget.auto => AiOffloadTarget.rpi5,
                    AiOffloadTarget.rpi5 => AiOffloadTarget.windowsHost,
                    AiOffloadTarget.windowsHost => AiOffloadTarget.auto,
                  };
                  ref.read(globalChatProvider.notifier).setOffloadTarget(nextTarget);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModelOption {
  final String name;
  final String desc;
  final int ramMb;

  const _ModelOption({
    required this.name,
    required this.desc,
    required this.ramMb,
  });
}
