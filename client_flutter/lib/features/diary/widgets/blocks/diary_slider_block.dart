import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiarySliderBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiarySliderBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiarySliderBlock> createState() => _DiarySliderBlockState();
}

class _DiarySliderBlockState extends State<DiarySliderBlock> {
  late double _val;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _val = (map['value'] as num?)?.toDouble() ?? 0.5;
  }

  @override
  void didUpdateWidget(covariant DiarySliderBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.block.content != widget.block.content) {
      final map = widget.block.contentAsMap;
      _val = (map['value'] as num?)?.toDouble() ?? 0.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = widget.block.contentAsMap;
    final label = (map['label'] ?? '').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Text(_val.toStringAsFixed(1), style: theme.textTheme.labelMedium),
              ],
            ),
          Slider(
            value: _val.clamp(0.0, 1.0),
            onChanged: (v) {
              setState(() => _val = v);
              widget.onChanged?.call({'label': label, 'value': v});
            },
          ),
        ],
      ),
    );
  }
}
