import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryToggleBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryToggleBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryToggleBlock> createState() => _DiaryToggleBlockState();
}

class _DiaryToggleBlockState extends State<DiaryToggleBlock> {
  late bool _value;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _value = map['value'] as bool? ?? false;
  }

  @override
  void didUpdateWidget(covariant DiaryToggleBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      final map = widget.block.contentAsMap;
      _value = map['value'] as bool? ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = widget.block.contentAsMap;
    final label = (map['label'] ?? map['title'] ?? 'Toggle option').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: SwitchListTile(
        title: Text(label, style: theme.textTheme.bodyMedium),
        value: _value,
        onChanged: (val) {
          setState(() => _value = val);
          widget.onChanged?.call({'label': label, 'value': val});
        },
      ),
    );
  }
}
