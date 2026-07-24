import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/app/diagnostics/diagnostics_provider.dart';
import 'package:client_flutter/app/diagnostics/diagnostic_result.dart';
import 'package:client_flutter/app/diagnostics/system_diagnostics.dart';

/// ## SduiTerminal — Type ID 18
///
/// A live diagnostic console primitive backed by [DiagnosticsHistoryNotifier].
///
/// ### Behavior Keys
/// | Key | Name               | Values                                         |
/// |-----|--------------------|------------------------------------------------|
/// | 95  | interactive_mode   | 0=read-only (default), 1=stdin enabled         |
/// | 96  | accent_color_token | HbpColorToken int — cursor/highlight color     |
/// | 127 | terminal_mode      | 0=diagnostics (client logs), 1=raw stream (Ph10)|
///
/// ### Content Keys
/// | Key | Name  | Description                                        |
/// |-----|-------|----------------------------------------------------|
/// | 0   | value | stdin command buffer when interactive_mode=1       |
/// | 1   | label | Terminal header title text                         |
///
/// ### Data Source Strategy
/// Filter mode 0 (ALL): reads [DiagnosticsState.globalTimeline] — O(n), preserves
/// chronological interleaving across all severity levels.
/// Filter mode 1 (WARN+): linear scan of globalTimeline — O(n).
/// Filter mode 2 (CRITICAL): reads [DiagnosticsState.criticalQueue] directly — O(k), k≪n.
class SduiTerminal extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiTerminal({super.key, required this.node, required this.dispatcher});

  @override
  ConsumerState<SduiTerminal> createState() => _SduiTerminalState();
}

class _SduiTerminalState extends ConsumerState<SduiTerminal> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _stdinController = TextEditingController();

  // Local ephemeral state — severity/subsystem filters are display logic.
  int _filterSeverity = 0; // 0=ALL, 1=DBG, 2=INFO, 3=WARN, 4=ERR
  String _filterSubsystem = 'ALL';

  @override
  void dispose() {
    _scrollController.dispose();
    _stdinController.dispose();
    super.dispose();
  }

  /// O(n) or O(k) filtered log source.
  /// globalTimeline is the only structure that preserves true insertion order
  /// across severity boundaries — concatenating the three partition queues
  /// would destroy chronological interleaving.
  List<DiagnosticResult> _getFilteredLogs(DiagnosticsState state) {
    final baseLogs = switch (_filterSeverity) {
      0 => state.globalTimeline,
      1 => state.globalTimeline.where((r) {
          final level = (r.telemetry?['log_level'] as num?)?.toInt() ?? 3;
          return level <= 2; // TRACE/DEBUG
        }).toList(),
      2 => state.globalTimeline.where((r) {
          final level = (r.telemetry?['log_level'] as num?)?.toInt() ?? 3;
          return level == 3; // INFO
        }).toList(),
      3 => state.globalTimeline.where((r) {
          final level = (r.telemetry?['log_level'] as num?)?.toInt() ?? 3;
          return level == 4; // WARN
        }).toList(),
      4 => state.globalTimeline.where((r) {
          final level = (r.telemetry?['log_level'] as num?)?.toInt() ?? 3;
          return level >= 5; // ERROR/CRITICAL
        }).toList(),
      _ => state.globalTimeline,
    };

    if (_filterSubsystem == 'ALL') {
      return baseLogs;
    }

    return baseLogs.where((r) {
      if (r.diagnostic == null) return false;
      final code = r.diagnostic!.code.toUpperCase();
      return code == _filterSubsystem || code.startsWith('$_filterSubsystem-');
    }).toList();
  }

  Color _severityColor(DiagnosticResult result, ColorScheme colors) {
    final int logLevel = (result.telemetry?['log_level'] as num?)?.toInt() ?? 3;
    return switch (logLevel) {
      1 || 2 => colors.onSurfaceVariant.withAlpha(140), // TRACE/DEBUG: Dimmed grey
      3 => const Color(0xFF66BB6A),                     // INFO: Nominal green
      4 => const Color(0xFFFFA726),                     // WARN: Warning orange
      5 || 6 => const Color(0xFFEF5350),                // ERROR/CRITICAL: Critical red
      _ => colors.onSurfaceVariant,
    };
  }

  String _formatTimestamp(DateTime ts) {
    final h = ts.hour.toString().padLeft(2, '0');
    final m = ts.minute.toString().padLeft(2, '0');
    final s = ts.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Formats the filtered log list as plaintext and writes to system clipboard.
  /// Format mirrors terminal line layout: [HH:mm:ss] ● CODE  message  ×N
  Future<void> _copyLogs(
    BuildContext context,
    List<DiagnosticResult> logs,
  ) async {
    if (logs.isEmpty) return;
    final buffer = StringBuffer();
    for (final r in logs) {
      final ts = _formatTimestamp(r.timestamp);
      final severity = switch (r.diagnostic?.severity) {
        DiagnosticSeverity.critical => 'CRITICAL',
        DiagnosticSeverity.warning => 'WARNING',
        DiagnosticSeverity.nominal => 'NOMINAL',
        null => 'UNKNOWN',
      };
      final code = r.diagnostic?.code ?? '---';
      final msg = r.message ?? r.diagnostic?.defaultMessage ?? '(no message)';
      final rle = r.occurrenceCount > 1 ? '  ×${r.occurrenceCount}' : '';
      buffer.writeln('[$ts] $severity  $code  $msg$rle');

      if (r.diagnostic?.defaultMessage != null &&
          r.diagnostic?.defaultMessage != msg) {
        buffer.writeln('  Details: ${r.diagnostic!.defaultMessage}');
      }

      if (r.telemetry != null && r.telemetry!.isNotEmpty && r.occurrenceCount <= 1) {
        final tele = const JsonEncoder.withIndent('  ').convert(r.telemetry);
        buffer.writeln('  Telemetry:\n${tele.split('\n').map((line) => '    $line').join('\n')}');
      }

      if (r.occurrences.length > 1) {
        buffer.writeln('  Occurrences (${r.occurrences.length}):');
        for (var idx = 0; idx < r.occurrences.length; idx++) {
          final occ = r.occurrences[idx];
          final occTs = _formatTimestamp(occ.timestamp);
          buffer.writeln('    #${idx + 1}: [$occTs]');
          if (occ.telemetry != null && occ.telemetry!.isNotEmpty) {
            final occTele = const JsonEncoder.withIndent('  ').convert(occ.telemetry);
            buffer.writeln(occTele.split('\n').map((line) => '      $line').join('\n'));
          }
        }
      }
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Copied ${logs.length} log ${logs.length == 1 ? "entry" : "entries"} to clipboard.',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          width: 340,
        ),
      );
    }
  }

  void _submitStdin(String command) {
    final trimmed = command.trim();
    if (trimmed.isEmpty) return;
    _stdinController.clear();
    widget.dispatcher.onStateChange(widget.node.id, trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // --- Behaviors ---
    final int interactiveMode =
        widget.node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final int? accentToken = widget.node.behavior<int>(
      HbpBehavior.ACCENT_COLOR_TOKEN,
    );
    // terminal_mode=1 (raw RPi5 stream) is a Phase 10 concern.
    // Currently only mode=0 (DiagnosticsHistoryNotifier) is implemented.
    // ignore: unused_local_variable
    final int terminalMode = widget.node.behavior<int>(127) ?? 0;

    final Color accentColor =
        SduiStyleResolver.resolveColor(context, accentToken) ?? colors.primary;

    // --- Content ---
    final String label =
        widget.node.contentVal<String>(HbpContent.LABEL) ?? 'System Console';

    // --- Live diagnostics state ---
    final DiagnosticsState diagState = ref.watch(diagnosticsHistoryProvider);
    final List<DiagnosticResult> logs = _getFilteredLogs(diagState);

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: colors.outlineVariant.withAlpha(80),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, label, accentColor, diagState, logs),
            Divider(
              height: 1,
              thickness: 1,
              color: colors.outlineVariant.withAlpha(60),
            ),
            _buildSubsystemFilterBar(context, diagState, colors),
            Divider(
              height: 1,
              thickness: 1,
              color: colors.outlineVariant.withAlpha(60),
            ),
            _buildLogList(context, logs, accentColor),
            if (interactiveMode == 1) ...[
              Divider(
                height: 1,
                thickness: 1,
                color: colors.outlineVariant.withAlpha(60),
              ),
              _buildStdinRow(context, accentColor),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Header: title + success rate + filter chips + clear
  // ──────────────────────────────────────────────────────────

  Widget _buildHeader(
    BuildContext context,
    String label,
    Color accentColor,
    DiagnosticsState state,
    List<DiagnosticResult> logs,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      color: colors.surfaceContainerHigh,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      child: Row(
        children: [
          Icon(Icons.terminal_rounded, size: 15, color: accentColor),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label.toUpperCase(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: theme.textTheme.labelSmall?.copyWith(
                fontFamily: 'monospace',
                color: accentColor,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _SuccessRateBadge(state: state, accentColor: accentColor),
          const Spacer(),
          // Severity filter chips
          _FilterChip(
            chipLabel: 'ALL',
            chipColor: colors.onSurfaceVariant,
            isSelected: _filterSeverity == 0,
            onTap: () => setState(() => _filterSeverity = 0),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            chipLabel: 'DBG',
            chipColor: colors.onSurfaceVariant.withAlpha(140),
            isSelected: _filterSeverity == 1,
            onTap: () => setState(() => _filterSeverity = 1),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            chipLabel: 'INFO',
            chipColor: const Color(0xFF66BB6A),
            isSelected: _filterSeverity == 2,
            onTap: () => setState(() => _filterSeverity = 2),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            chipLabel: 'WARN',
            chipColor: const Color(0xFFFFA726),
            isSelected: _filterSeverity == 3,
            onTap: () => setState(() => _filterSeverity = 3),
          ),
          const SizedBox(width: 4),
          _FilterChip(
            chipLabel: 'ERR',
            chipColor: const Color(0xFFEF5350),
            isSelected: _filterSeverity == 4,
            onTap: () => setState(() => _filterSeverity = 4),
          ),
          const SizedBox(width: 12),
          // Copy current filtered logs to clipboard
          GestureDetector(
            onTap: () => _copyLogs(context, logs),
            child: Tooltip(
              message: 'Copy logs',
              child: Icon(
                Icons.copy_all_outlined,
                size: 16,
                color: colors.onSurfaceVariant.withAlpha(160),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () =>
                ref.read(diagnosticsHistoryProvider.notifier).clearHistory(),
            child: Tooltip(
              message: 'Clear logs',
              child: Icon(
                Icons.delete_sweep_outlined,
                size: 16,
                color: colors.onSurfaceVariant.withAlpha(160),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Subsystem/Tag filter horizontal list
  // ──────────────────────────────────────────────────────────
  Widget _buildSubsystemFilterBar(
    BuildContext context,
    DiagnosticsState state,
    ColorScheme colors,
  ) {
    // Extract unique full codes and high-level prefixes dynamically
    final Set<String> subsystems = {'ALL'};
    for (final log in state.globalTimeline) {
      if (log.diagnostic != null) {
        final code = log.diagnostic!.code.toUpperCase();
        subsystems.add(code);

        final parts = code.split('-');
        if (parts.isNotEmpty) {
          subsystems.add(parts.first);
        }
      }
    }

    final list = subsystems.toList()..sort();
    // Keep 'ALL' at the very beginning
    list.remove('ALL');
    list.insert(0, 'ALL');

    return Container(
      color: colors.surfaceContainerLow.withAlpha(120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 6.0,
        runSpacing: 6.0,
        children: list.map((sub) {
          final isSelected = _filterSubsystem == sub;
          return _FilterChip(
            chipLabel: sub,
            chipColor: colors.primary,
            isSelected: isSelected,
            onTap: () => setState(() => _filterSubsystem = sub),
          );
        }).toList(),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Log list: reverse=true → newest entries at bottom, O(1) auto-scroll
  // ──────────────────────────────────────────────────────────

  Widget _buildLogList(
    BuildContext context,
    List<DiagnosticResult> logs,
    Color accentColor,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (logs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Text(
            '[ no log entries ]',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: colors.onSurfaceVariant.withAlpha(100),
            ),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 320),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true, // newest at bottom; no manual scroll needed
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        itemCount: logs.length,
        itemBuilder: (context, index) {
          // reverse:true → index 0 maps to the last element (newest)
          final entry = logs[logs.length - 1 - index];
          return _TerminalLine(
            result: entry,
            severityColor: _severityColor(entry, colors),
            formatTimestamp: _formatTimestamp,
          );
        },
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // stdin row — only rendered when interactive_mode=1
  // ──────────────────────────────────────────────────────────

  Widget _buildStdinRow(BuildContext context, Color accentColor) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Text(
            '\$',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: accentColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _stdinController,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: colors.onSurface,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: 'enter command...',
                hintStyle: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  color: colors.onSurfaceVariant.withAlpha(100),
                ),
              ),
              cursorColor: accentColor,
              onSubmitted: _submitStdin,
              inputFormatters: [
                FilteringTextInputFormatter.singleLineFormatter,
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _submitStdin(_stdinController.text),
            child: Icon(Icons.send_rounded, size: 15, color: accentColor),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Sub-widgets (private, file-scoped)
// ──────────────────────────────────────────────────────────────────────────────

/// A single terminal log line.
/// Layout: [HH:mm:ss] ● [CODE] message text                        ×N
class _TerminalLine extends StatefulWidget {
  final DiagnosticResult result;
  final Color severityColor;
  final String Function(DateTime) formatTimestamp;

  const _TerminalLine({
    required this.result,
    required this.severityColor,
    required this.formatTimestamp,
  });

  @override
  State<_TerminalLine> createState() => _TerminalLineState();
}

class _TerminalLineState extends State<_TerminalLine> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final TextStyle monoBase = const TextStyle(
      fontFamily: 'monospace',
      fontSize: 11,
      height: 1.6,
    );

    final int logLevel = (widget.result.telemetry?['log_level'] as num?)?.toInt() ?? 3;
    final Color messageColor = switch (logLevel) {
      1 || 2 => colors.onSurfaceVariant.withAlpha(140), // TRACE/DEBUG: Dimmed grey
      3 => colors.onSurface.withAlpha(210),             // INFO: Nominal white/grey
      4 => const Color(0xFFFFA726),                     // WARN: Warning orange
      5 || 6 => const Color(0xFFEF5350),                // ERROR/CRITICAL: Critical red
      _ => colors.onSurface.withAlpha(210),
    };

    final String messageText = widget.result.message ??
        widget.result.diagnostic?.defaultMessage ??
        '(no message)';

    final telemetry = widget.result.telemetry;
    final hasDetails =
        (telemetry != null && telemetry.isNotEmpty) ||
        (widget.result.diagnostic?.defaultMessage != null &&
            widget.result.diagnostic?.defaultMessage != messageText) ||
        widget.result.occurrences.length > 1;

    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      borderRadius: BorderRadius.circular(4),
      hoverColor: colors.onSurface.withAlpha(10),
      splashColor: colors.onSurface.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // [HH:mm:ss] timestamp
                Text(
                  '[${widget.formatTimestamp(widget.result.timestamp)}]',
                  style: monoBase.copyWith(
                    color: colors.onSurfaceVariant.withAlpha(110),
                  ),
                ),
                const SizedBox(width: 8),

                // Severity dot
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: widget.severityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Code badge
                if (widget.result.diagnostic != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: widget.severityColor.withAlpha(35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      widget.result.diagnostic!.code,
                      style: monoBase.copyWith(
                        color: widget.severityColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Message text
                Expanded(
                  child: Text(
                    messageText,
                    style: monoBase.copyWith(color: messageColor),
                    maxLines: _isExpanded ? null : 2,
                    overflow: _isExpanded ? null : TextOverflow.ellipsis,
                  ),
                ),

                // RLE occurrence badge
                if (widget.result.occurrenceCount > 1) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '×${widget.result.occurrenceCount}',
                      style: monoBase.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (_isExpanded && hasDetails) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10.0),
                margin: const EdgeInsets.only(left: 20.0),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest.withAlpha(160),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colors.outline.withAlpha(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.result.diagnostic?.defaultMessage != null &&
                        widget.result.diagnostic?.defaultMessage !=
                            messageText) ...[
                      Text(
                        'Details: ${widget.result.diagnostic!.defaultMessage}',
                        style: monoBase.copyWith(
                          color: colors.onSurfaceVariant.withAlpha(180),
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    if (telemetry != null && telemetry.isNotEmpty && widget.result.occurrenceCount <= 1) ...[
                      Text(
                        'Telemetry:',
                        style: monoBase.copyWith(
                          color: colors.onSurfaceVariant.withAlpha(120),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        const JsonEncoder.withIndent('  ').convert(telemetry),
                        style: monoBase.copyWith(
                          color: colors.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    if (widget.result.occurrences.length > 1) ...[
                      Text(
                        'Occurrences (${widget.result.occurrences.length}):',
                        style: monoBase.copyWith(
                          color: colors.onSurfaceVariant.withAlpha(120),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...widget.result.occurrences.asMap().entries.map((e) {
                        final idx = e.key + 1;
                        final occ = e.value;
                        final tsStr = widget.formatTimestamp(occ.timestamp);
                        final hasOccTelem = occ.telemetry != null && occ.telemetry!.isNotEmpty;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#$idx: [$tsStr]',
                                style: monoBase.copyWith(
                                  color: colors.onSurface,
                                  fontSize: 10,
                                ),
                              ),
                              if (hasOccTelem) ...[
                                Padding(
                                  padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                                  child: Text(
                                    const JsonEncoder.withIndent('  ').convert(occ.telemetry),
                                    style: monoBase.copyWith(
                                      color: colors.onSurfaceVariant.withAlpha(180),
                                      fontSize: 9,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Success rate badge shown in the header.
class _SuccessRateBadge extends StatelessWidget {
  final DiagnosticsState state;
  final Color accentColor;

  const _SuccessRateBadge({required this.state, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final rate = state.successRate;
    final Color rateColor = rate >= 90
        ? const Color(0xFF66BB6A)
        : rate >= 60
        ? const Color(0xFFFFA726)
        : const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: rateColor.withAlpha(30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '${rate.toStringAsFixed(1)}% OK',
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: rateColor,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
    );
  }
}

/// Animated severity filter chip for the terminal header.
class _FilterChip extends StatelessWidget {
  final String chipLabel;
  final Color chipColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.chipLabel,
    required this.chipColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(40) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected ? chipColor : colors.outlineVariant.withAlpha(80),
            width: 1.0,
          ),
        ),
        child: Text(
          chipLabel,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            color: isSelected ? chipColor : colors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}
