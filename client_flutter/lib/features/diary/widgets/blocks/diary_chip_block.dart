import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryChipBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryChipBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final label = (map['label'] ?? map['text'] ?? 'Tag').toString();
    final iconName = map['icon']?.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Wrap(
        children: [
          Chip(
            avatar: iconName != null ? const Icon(Icons.label, size: 16) : null,
            label: Text(label, style: theme.textTheme.labelMedium),
            backgroundColor: theme.colorScheme.primaryContainer,
          ),
        ],
      ),
    );
  }
}

class DiaryContainerBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryContainerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final text = (map['text'] ?? map['content'] ?? '').toString();
    final title = (map['title'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
            ],
            Text(text, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class DiaryGridBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryGridBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final items = (map['items'] as List?)?.map((e) => e.toString()).toList() ?? ['Item 1', 'Item 2', 'Item 3', 'Item 4'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 3,
        ),
        itemCount: items.length,
        itemBuilder: (context, idx) {
          return Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(items[idx], style: theme.textTheme.bodyMedium),
          );
        },
      ),
    );
  }
}
