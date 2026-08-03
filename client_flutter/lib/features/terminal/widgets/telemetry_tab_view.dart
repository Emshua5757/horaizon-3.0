import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../shared/widgets/app_card.dart';
import '../models/telemetry_log_item.dart';
import 'telemetry_line_tile.dart';

/// Tab 1: Evolved SDUI Telemetry Log Console & Governor Stdin Prompt
class TelemetryTabView extends StatefulWidget {
  final List<TelemetryLogItem> logs;
  final Function(String) onCommandSubmitted;
  final VoidCallback onClearLogs;

  const TelemetryTabView({
    super.key,
    required this.logs,
    required this.onCommandSubmitted,
    required this.onClearLogs,
  });

  @override
  State<TelemetryTabView> createState() => _TelemetryTabViewState();
}

class _TelemetryTabViewState extends State<TelemetryTabView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _stdinController = TextEditingController();

  int _filterSeverity = 0; // 0=ALL, 1=DBG, 2=INFO, 3=WARN, 4=ERR
  // ignore: prefer_final_fields
  String _filterSubsystem = 'ALL';
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    _scrollToBottom();
  }

  @override
  void didUpdateWidget(covariant TelemetryTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isPaused) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  Color _getSeverityColor(String level, ColorScheme cs) {
    switch (level.toUpperCase()) {
      case 'DEBUG':
      case 'DBG':
        return cs.onSurfaceVariant.withValues(alpha: 0.6);
      case 'INFO':
        return const Color(0xFF10B981);
      case 'WARN':
      case 'WARNING':
        return const Color(0xFFF59E0B);
      case 'ERR':
      case 'ERROR':
      case 'CRITICAL':
        return const Color(0xFFEF4444);
      default:
        return cs.primary;
    }
  }

  List<String> get _subsystemsList {
    final set = {'ALL'};
    for (final l in widget.logs) {
      set.add(l.subsystem);
    }
    final list = set.toList()..sort();
    list.remove('ALL');
    list.insert(0, 'ALL');
    return list;
  }

  List<TelemetryLogItem> get _filteredLogs {
    return widget.logs.where((item) {
      if (_filterSeverity == 1 && item.level != 'DEBUG') return false;
      if (_filterSeverity == 2 && item.level != 'INFO') return false;
      if (_filterSeverity == 3 && item.level != 'WARN') return false;
      if (_filterSeverity == 4 && item.level != 'ERROR') return false;

      if (_filterSubsystem != 'ALL' && item.subsystem != _filterSubsystem) return false;
      return true;
    }).toList();
  }

  void _submitCommand() {
    final text = _stdinController.text.trim();
    if (text.isNotEmpty) {
      _stdinController.clear();
      widget.onCommandSubmitted(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final filtered = _filteredLogs;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Severity Filter Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: cs.surfaceContainerHigh.withValues(alpha: 0.5),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'SEVERITY:',
                          style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'ALL', isSelected: _filterSeverity == 0, onTap: () => setState(() => _filterSeverity = 0)),
                        const SizedBox(width: 4),
                        _FilterChip(label: 'INFO', isSelected: _filterSeverity == 2, color: const Color(0xFF10B981), onTap: () => setState(() => _filterSeverity = 2)),
                        const SizedBox(width: 4),
                        _FilterChip(label: 'WARN', isSelected: _filterSeverity == 3, color: const Color(0xFFF59E0B), onTap: () => setState(() => _filterSeverity = 3)),
                        const SizedBox(width: 4),
                        _FilterChip(label: 'ERR', isSelected: _filterSeverity == 4, color: const Color(0xFFEF4444), onTap: () => setState(() => _filterSeverity = 4)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                IconButton(
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, size: 18, color: cs.primary),
                  tooltip: _isPaused ? 'Resume stream' : 'Pause stream',
                  onPressed: () => setState(() => _isPaused = !_isPaused),
                ),
                IconButton(
                  icon: Icon(Icons.copy_all_rounded, size: 18, color: cs.onSurfaceVariant),
                  tooltip: 'Copy logs to clipboard',
                  onPressed: () {
                    final buf = filtered.map((l) => '[${l.timestamp.toIso8601String()}] [${l.subsystem}] ${l.level}: ${l.message}').join('\n');
                    Clipboard.setData(ClipboardData(text: buf));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Copied ${filtered.length} log entries to clipboard.')),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(Icons.delete_sweep_rounded, size: 18, color: cs.onSurfaceVariant),
                  tooltip: 'Clear log buffer',
                  onPressed: widget.onClearLogs,
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Subsystem / Module Tag Filter Chip Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: cs.surfaceContainerLow.withValues(alpha: 0.4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'MODULE TAGS:',
                    style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                  const SizedBox(width: 8),
                  ..._subsystemsList.map((sub) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: _FilterChip(
                        label: sub,
                        isSelected: _filterSubsystem == sub,
                        color: cs.secondary,
                        onTap: () => setState(() => _filterSubsystem = sub),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Log Lines Window
          Expanded(
            child: Container(
              color: cs.surfaceContainerLowest,
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        '[ No log entries matching filter ]',
                        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12, fontFamily: 'monospace'),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        final color = _getSeverityColor(item.level, cs);

                        return TelemetryLineTile(
                          item: item,
                          severityColor: color,
                        );
                      },
                    ),
            ),
          ),
          const Divider(height: 1, thickness: 1),

          // Stdin Prompt Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: cs.surfaceContainerLow,
            child: Row(
              children: [
                Text(
                  r'$',
                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'monospace'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _stdinController,
                    style: TextStyle(color: cs.onSurface, fontSize: 12, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Execute Governor Command (e.g. metrics.get, process.list, ping)...',
                      hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.5), fontSize: 12, fontFamily: 'monospace'),
                    ),
                    onSubmitted: (_) => _submitCommand(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send_rounded, size: 16, color: cs.primary),
                  onPressed: _submitCommand,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
