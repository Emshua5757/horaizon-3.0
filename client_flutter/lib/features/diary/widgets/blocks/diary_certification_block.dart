import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryCertificationBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryCertificationBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = block.contentAsMap;
    final certName = (map['cert_name'] ?? map['name'] ?? 'AWS Solutions Architect').toString();
    final issuer = (map['issuer'] ?? 'Amazon Web Services').toString();
    final status = (map['status'] ?? 'studying').toString();

    Color statusColor;
    switch (status) {
      case 'passed':
        statusColor = Colors.green;
        break;
      case 'exam_scheduled':
        statusColor = Colors.orange;
        break;
      case 'studying':
        statusColor = Colors.blue;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.workspace_premium, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(certName, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  Text(issuer, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Chip(
              label: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              backgroundColor: statusColor.withValues(alpha: 0.1),
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
