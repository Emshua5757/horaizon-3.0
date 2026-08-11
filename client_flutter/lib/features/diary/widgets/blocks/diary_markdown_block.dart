import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryMarkdownBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryMarkdownBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryMarkdownBlock> createState() => _DiaryMarkdownBlockState();
}

class _DiaryMarkdownBlockState extends State<DiaryMarkdownBlock> {
  late TextEditingController _controller;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _controller = TextEditingController(text: (map['text'] ?? map['value'] ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant DiaryMarkdownBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content && !_isEditing) {
      final map = widget.block.contentAsMap;
      _controller.text = (map['text'] ?? map['value'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (widget.onChanged != null) {
      widget.onChanged!({'text': _controller.text});
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Focus(
        onFocusChange: (focused) {
          setState(() => _isEditing = focused);
          if (!focused) _save();
        },
        child: TextField(
          controller: _controller,
          maxLines: null,
          keyboardType: TextInputType.multiline,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
          decoration: InputDecoration(
            hintText: 'Write in markdown...',
            hintStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          ),
          onChanged: (_) => _save(),
        ),
      ),
    );
  }
}
