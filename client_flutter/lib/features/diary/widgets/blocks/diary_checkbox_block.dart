import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryCheckboxBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryCheckboxBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryCheckboxBlock> createState() => _DiaryCheckboxBlockState();
}

class _DiaryCheckboxBlockState extends State<DiaryCheckboxBlock> {
  late TextEditingController _controller;
  late bool _checked;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _controller = TextEditingController(text: (map['label'] ?? map['text'] ?? '').toString());
    _checked = map['checked'] as bool? ?? false;
  }

  @override
  void didUpdateWidget(covariant DiaryCheckboxBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      final map = widget.block.contentAsMap;
      _controller.text = (map['label'] ?? map['text'] ?? '').toString();
      _checked = map['checked'] as bool? ?? false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged?.call({
      'label': _controller.text,
      'checked': _checked,
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: Row(
        children: [
          Checkbox(
            value: _checked,
            onChanged: (val) {
              setState(() => _checked = val ?? false);
              _save();
            },
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: _checked ? TextDecoration.lineThrough : null,
                color: _checked
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                    : theme.colorScheme.onSurface,
              ),
              decoration: const InputDecoration(
                hintText: 'To-do item...',
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (_) => _save(),
            ),
          ),
        ],
      ),
    );
  }
}
