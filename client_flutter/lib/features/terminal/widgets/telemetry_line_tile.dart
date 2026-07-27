import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/telemetry_log_item.dart';

/// Single telemetry log entry widget with expandable JSON payload inspector.
/// Consumes Theme.of(context).colorScheme for complete theme reactivity.
class TelemetryLineTile extends StatefulWidget {
  final TelemetryLogItem item;
  final Color severityColor;

  const TelemetryLineTile({
    super.key,
    required this.item,
    required this.severityColor,
  });

  @override
  State<TelemetryLineTile> createState() => _TelemetryLineTileState();
}

class _TelemetryLineTileState extends State<TelemetryLineTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final item = widget.item;

    final tsStr =
        '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')}:${item.timestamp.second.toString().padLeft(2, '0')}';

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '[$tsStr]',
                  style: TextStyle(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.severityColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.subsystem,
                    style: TextStyle(
                      color: widget.severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.message,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                    maxLines: _isExpanded ? null : 1,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),
                if (item.occurrenceCount > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '×${item.occurrenceCount}',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_isExpanded && item.metadata != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(left: 24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Text(
                  const JsonEncoder.withIndent('  ').convert(item.metadata),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
