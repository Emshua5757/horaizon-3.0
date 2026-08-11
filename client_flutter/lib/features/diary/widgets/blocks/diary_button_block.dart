import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryButtonBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryButtonBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final map = block.contentAsMap;
    final label = (map['label'] ?? map['text'] ?? 'Action').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: FilledButton(
        onPressed: () {},
        child: Text(label),
      ),
    );
  }
}
