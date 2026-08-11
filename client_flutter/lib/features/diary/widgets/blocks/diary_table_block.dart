import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryTableBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryTableBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final map = block.contentAsMap;
    final headers = (map['headers'] as List?)?.map((e) => e.toString()).toList() ?? ['Column 1', 'Column 2'];
    final rows = (map['rows'] as List?)?.map((r) => (r as List).map((c) => c.toString()).toList()).toList() ?? [
      ['Data 1', 'Data 2']
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        child: DataTable(
          columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
          rows: rows.map((r) => DataRow(cells: r.map((cell) => DataCell(Text(cell))).toList())).toList(),
        ),
      ),
    );
  }
}
