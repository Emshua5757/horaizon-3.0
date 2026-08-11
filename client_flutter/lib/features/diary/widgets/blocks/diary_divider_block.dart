import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryDividerBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryDividerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Divider(height: 1),
    );
  }
}

class DiarySpacerBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiarySpacerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final map = block.contentAsMap;
    final height = (map['height'] as num?)?.toDouble() ?? 24.0;
    return SizedBox(height: height);
  }
}
