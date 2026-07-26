import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../governor/governor_provider.dart';
import 'stitch_card.dart';

/// Shua Governor AI Aggregator Hero Card with model selector modal and Laptop Offload toggle.
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF070A10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
        ),
        title: const Row(
          children: [
            Icon(Icons.smart_toy_rounded, color: Color(0xFF00E5FF), size: 20),
            SizedBox(width: 8),
            Text(
              'Select Ollama AI Model',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                  color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF00E5FF).withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: ListTile(
                  dense: true,
                  title: Text(
                    m.name,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF00E5FF) : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      fontFamily: 'Geist',
                    ),
                  ),
                  subtitle: Text(
                    '${m.desc} • ~${m.ramMb} MB VRAM',
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF00E5FF), size: 18)
                      : const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 12),
                  onTap: () {
                    ref.read(governorStatusProvider.notifier).selectModel(m.name);
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
    final activeModel = status.loadedModel ?? 'qwen2.5:1.5b (Laptop Offload)';
    final vramMb = status.ollamaRamMb ?? 1840;
    final isLaptop = status.isLaptopOffload;
    final badgeColor = isLaptop ? const Color(0xFF00E5FF) : const Color(0xFF3CE36A);
    final badgeText = isLaptop ? 'Laptop Offload Active' : 'RPi5 Edge Active';

    return StitchCard(
      isGlowing: true,
      borderColor: const Color(0xFF00E5FF).withValues(alpha: 0.35),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy_rounded, color: Color(0xFF00E5FF), size: 14),
                      SizedBox(width: 6),
                      Text(
                        'SHUA GOVERNOR',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontFamily: 'Geist',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3),
                  Text(
                    'AI Aggregator',
                    style: TextStyle(
                      color: Color(0xFFD4E4FA),
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
                  color: badgeColor.withValues(alpha: 0.1),
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
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 100,
                      child: Text(
                        'Active Model',
                        style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => _showModelSelectorModal(context, ref),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  activeModel,
                                  style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Geist'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF00E5FF), size: 18),
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
                    const Text(
                      'Ollama VRAM Allocation',
                      style: TextStyle(color: Color(0xFFC8C5CB), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${vramMb.toStringAsFixed(0)} MB',
                      style: const TextStyle(color: Color(0xFF00E5FF), fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Geist'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (vramMb / 4096.0).clamp(0.0, 1.0),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00E5FF)),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          const SizedBox(height: 18),

          // Interactive Action Buttons
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: const Color(0xFF050508),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () => _showModelSelectorModal(context, ref),
                child: const Text(
                  'Select Model',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFD4E4FA),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {},
                child: const Text('Evict', style: TextStyle(fontSize: 12)),
              ),
              OutlinedButton.icon(
                icon: Icon(
                  isLaptop ? Icons.developer_board_rounded : Icons.laptop_mac_rounded,
                  size: 14,
                  color: const Color(0xFF00E5FF),
                ),
                label: Text(
                  isLaptop ? 'Switch to RPi5 Edge' : 'Switch to Laptop Offload',
                  style: const TextStyle(color: Color(0xFFD4E4FA), fontSize: 12),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
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
