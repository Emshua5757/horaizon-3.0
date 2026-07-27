import 'package:flutter/material.dart';
import '../../shared/widgets/app_card.dart';

/// Developer preview gallery route (/dev/blocks) showcasing native diary block widgets.
class BlockGalleryScreen extends StatelessWidget {
  const BlockGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Developer Block Gallery (/dev/blocks)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diary Markdown Block',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '# horAIzon 3.0 Telemetry Log\n- Real-time MessagePack streaming active.\n- Hardware temperature nominal at 41.8 °C.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diary Code Block',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'let frame = HbpFrame::decode(&bytes)?;\ndispatch_op(frame.op, frame.payload);',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'JetBrains Mono',
                          color: cs.onSurface,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
