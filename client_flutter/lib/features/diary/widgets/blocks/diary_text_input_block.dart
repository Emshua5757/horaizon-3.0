import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryTextInputBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryTextInputBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryTextInputBlock> createState() => _DiaryTextInputBlockState();
}

class _DiaryTextInputBlockState extends State<DiaryTextInputBlock> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _controller = TextEditingController(text: (map['value'] ?? map['text'] ?? '').toString());
  }

  @override
  void didUpdateWidget(covariant DiaryTextInputBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      final map = widget.block.contentAsMap;
      _controller.text = (map['value'] ?? map['text'] ?? '').toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged?.call({'value': _controller.text});
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.block.contentAsMap;
    final hint = (map['placeholder'] ?? map['hint'] ?? 'Type something...').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
        onChanged: (_) => _save(),
      ),
    );
  }
}
