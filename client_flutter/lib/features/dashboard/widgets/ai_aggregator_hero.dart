import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_effects_theme.dart';
import '../../../core/theme/app_semantic_palette.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Shua Governor AI Aggregator Hero Card with model selector modal and Laptop Offload toggle,
/// dynamically adapting to active Theme Preset and AppSemanticPalette.
class AiAggregatorHero extends ConsumerWidget {
  final GovernorStatus status;

  const AiAggregatorHero({super.key, required this.status});

  static const _availableModels = [
    _ModelOption(name: 'qwen2.5:1.5b', desc: 'Fast Edge Dialogue & Routing', ramMb: 1840),
    _ModelOption(name: 'llama3.2:1b', desc: 'Meta Lightweight Dialogue', ramMb: 1320),
    _ModelOption(name: 'deepseek-r1:1.5b', desc: 'Reasoning & Logic Synthesizer', ramMb: 1950),
    _ModelOption(name: 'phi3:mini', desc: 'Microsoft SLM Code Specialist', ramMb: 2300),
  ];

  void _showModelSelectorModal(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
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
              final isSelected = (status.loadedModel ?? '').contains(m.name);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? cs.primary.withValues(alpha: 0.15) : cs.surface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                  ),
                ),
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
                    ref.read(governorStatusProvider.notifier).refresh();
                    Navigator.of(ctx).pop();
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final semantic = Theme.of(context).extension<AppSemanticPalette>();
    final effects = Theme.of(context).extension<AppEffectsTheme>();

    final successColor = semantic?.success ?? cs.primary;
    final infoColor = semantic?.info ?? cs.secondary;

    final activeModel = status.loadedModel ?? 'qwen2.5:1.5b';
    final vramMb = status.ollamaRamMb ?? 1840.0;
    final isLaptop = status.isLaptopOffload;

    final badgeText = isLaptop ? 'MSI Laptop Offload' : 'RPi5 Local Engine';
    final badgeColor = isLaptop ? infoColor : successColor;

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

          // Active Model Box
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
          const SizedBox(height: 18),

          // Interactive Action Buttons
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
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.onSurface,
                  side: BorderSide(color: cs.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                ),
                onPressed: () {},
                child: const Text('Evict', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  isLaptop ? Icons.developer_board_rounded : Icons.laptop_mac_rounded,
                  size: 14,
                  color: cs.primary,
                ),
                label: Text(
                  isLaptop ? 'Switch to RPi5 Edge' : 'Switch to Laptop Offload',
                  style: TextStyle(color: cs.onSurface, fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(effects?.buttonRadius ?? 8)),
                ),
                onPressed: () => ref.read(governorStatusProvider.notifier).toggleOffloadTarget(!isLaptop),
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
