import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryCodeBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryCodeBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryCodeBlock> createState() => _DiaryCodeBlockState();
}

class _DiaryCodeBlockState extends State<DiaryCodeBlock> {
  late TextEditingController _controller;
  late String _language;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _controller = TextEditingController(text: (map['code'] ?? map['text'] ?? '').toString());
    _language = (map['language'] ?? 'dart').toString();
  }

  @override
  void didUpdateWidget(covariant DiaryCodeBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      final map = widget.block.contentAsMap;
      _controller.text = (map['code'] ?? map['text'] ?? '').toString();
      _language = (map['language'] ?? 'dart').toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.onChanged?.call({'code': _controller.text, 'language': _language});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark code IDE background
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _language.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const Icon(Icons.code, size: 16, color: Colors.white54),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFFD4D4D4),
                height: 1.4,
              ),
              decoration: const InputDecoration(
                hintText: '// Paste code snippet here...',
                hintStyle: TextStyle(color: Colors.white30, fontFamily: 'monospace'),
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
