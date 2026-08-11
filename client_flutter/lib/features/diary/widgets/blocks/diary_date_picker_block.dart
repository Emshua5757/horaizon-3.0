import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryDatePickerBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryDatePickerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryDatePickerBlock> createState() => _DiaryDatePickerBlockState();
}

class _DiaryDatePickerBlockState extends State<DiaryDatePickerBlock> {
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _date = map['date'] != null ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now() : DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(_date.toIso8601String().split('T').first),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          setState(() => _date = picked);
          widget.onChanged?.call({'date': _date.toIso8601String()});
        }
      },
    );
  }
}
