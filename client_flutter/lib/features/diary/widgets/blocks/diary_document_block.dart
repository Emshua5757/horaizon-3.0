import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryDocumentBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryDocumentBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final title = (map['title'] ?? map['filename'] ?? 'Attachment.pdf').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: Icon(Icons.picture_as_pdf, color: theme.colorScheme.error),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('PDF Document'),
        trailing: const Icon(Icons.download),
      ),
    );
  }
}

class DiaryCarouselBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryCarouselBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final items = (map['items'] as List?)?.map((e) => e.toString()).toList() ?? ['Slide 1', 'Slide 2', 'Slide 3'];

    return SizedBox(
      height: 120,
      child: PageView.builder(
        itemCount: items.length,
        itemBuilder: (context, idx) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(items[idx], style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
            ),
          );
        },
      ),
    );
  }
}

class DiaryHtmlBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryHtmlBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final html = (map['html'] ?? map['text'] ?? '<p>Sanitized HTML</p>').toString();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(html, style: theme.textTheme.bodyMedium?.copyWith(fontFamily: 'monospace')),
    );
  }
}

class DiaryExpansionBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryExpansionBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final title = (map['title'] ?? 'Accordion Section').toString();
    final body = (map['content'] ?? map['text'] ?? 'Hidden details...').toString();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ExpansionTile(
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(body, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class DiaryWrapBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryWrapBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final items = (map['items'] as List?)?.map((e) => e.toString()).toList() ?? ['Tag A', 'Tag B', 'Tag C'];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: items.map((tag) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(tag, style: theme.textTheme.labelMedium),
        )).toList(),
      ),
    );
  }
}
