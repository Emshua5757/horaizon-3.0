import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryProgressBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryProgressBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final progress = (map['value'] as num?)?.toDouble() ?? 0.0;
    final label = (map['label'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text('${(progress * 100).toInt()}%', style: theme.textTheme.labelMedium),
              ],
            ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }
}
