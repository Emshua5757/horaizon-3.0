import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryTimePickerBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryTimePickerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryTimePickerBlock> createState() => _DiaryTimePickerBlockState();
}

class _DiaryTimePickerBlockState extends State<DiaryTimePickerBlock> {
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    final timeStr = (map['time'] ?? '12:00').toString();
    final parts = timeStr.split(':');
    _time = TimeOfDay(
      hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 12 : 12,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.access_time),
      title: Text(_time.format(context)),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: _time);
        if (picked != null) {
          setState(() => _time = picked);
          widget.onChanged?.call({'time': '${_time.hour}:${_time.minute.toString().padLeft(2, '0')}'});
        }
      },
    );
  }
}
