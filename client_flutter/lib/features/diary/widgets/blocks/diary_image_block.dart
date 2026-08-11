import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryImageBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryImageBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final hash = (map['hash'] ?? map['sha256'] ?? '').toString();
    final url = (map['url'] ?? (hash.isNotEmpty ? 'http://127.0.0.1:7702/vault/$hash' : '')).toString();
    final caption = (map['caption'] ?? '').toString();

    if (url.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        color: theme.colorScheme.surfaceContainerLow,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.image_not_supported_outlined, color: theme.colorScheme.outline),
              const SizedBox(width: 12),
              Text('No image source', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: theme.colorScheme.errorContainer,
                child: Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: theme.colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ),
          ),
          if (caption.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(caption, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
