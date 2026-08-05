import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline expand-to-edit card for a single work experience entry.
///
/// - Collapsed: shows company name, position, date range.
/// - Expanded: full edit form with auto-save (800ms debounce).
/// - Swipe-to-dismiss: optimistic delete via [ResumeMatrixNotifier].
class WorkItemCard extends ConsumerStatefulWidget {
  final WorkItemDto item;
  final bool initiallyExpanded;

  const WorkItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<WorkItemCard> createState() => _WorkItemCardState();
}

class _WorkItemCardState extends ConsumerState<WorkItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _posCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _highlightsCtrl;
  late TextEditingController _keywordsCtrl;

  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _initControllers(widget.item);
  }

  void _initControllers(WorkItemDto item) {
    _nameCtrl = TextEditingController(text: item.name);
    _posCtrl = TextEditingController(text: item.position);
    _startCtrl = TextEditingController(text: item.startDate);
    _endCtrl = TextEditingController(text: item.endDate);
    _summaryCtrl = TextEditingController(text: item.summary);
    _highlightsCtrl = TextEditingController(text: item.highlights.join('\n'));
    _keywordsCtrl = TextEditingController(text: item.keywords.join(', '));

    for (final ctrl in [
      _nameCtrl,
      _posCtrl,
      _startCtrl,
      _endCtrl,
      _summaryCtrl,
      _highlightsCtrl,
      _keywordsCtrl,
    ]) {
      ctrl.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ctrl in [
      _nameCtrl,
      _posCtrl,
      _startCtrl,
      _endCtrl,
      _summaryCtrl,
      _highlightsCtrl,
      _keywordsCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final highlights = _highlightsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    await ref.read(resumeMatrixProvider.notifier).upsertSection(
      'work',
      {
        'id': widget.item.id,
        'name': _nameCtrl.text,
        'position': _posCtrl.text,
        'start_date': _startCtrl.text,
        'end_date': _endCtrl.text,
        'summary': _summaryCtrl.text,
        'highlights': highlights,
        'keywords': keywords,
        'skills': widget.item.skills,
        'url': widget.item.url,
        'active': widget.item.active,
      },
    );

    if (!mounted) return;
    setState(() => _saved = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey('work_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) {
        ref
            .read(resumeMatrixProvider.notifier)
            .deleteItem('work', widget.item.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.isEmpty
                                  ? 'New Position'
                                  : widget.item.name,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.position.isNotEmpty)
                              Text(
                                widget.item.position,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: cs.outline),
                              ),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      if (widget.item.startDate.isNotEmpty)
                        Text(
                          '${widget.item.startDate} – '
                          '${widget.item.endDate.isEmpty ? 'Present' : widget.item.endDate}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: cs.outline),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),

                  // ── Expanded edit form ──────────────────────────────────
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Company / Organisation', _nameCtrl),
                    _field('Position / Title', _posCtrl),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Start Date', _startCtrl,
                                hint: 'e.g. Aug 2024 or Present')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _field('End Date', _endCtrl,
                                hint: 'e.g. May 2026 or Present')),
                      ],
                    ),
                    _field(
                      'Summary',
                      _summaryCtrl,
                      maxLines: 2,
                      hint: 'Describe what you did overall (1–3 sentences)',
                    ),
                    _field(
                      'Highlights (one per line — auto-bulleted)',
                      _highlightsCtrl,
                      maxLines: 5,
                      hint:
                          'e.g. Led migration of legacy monolith, reducing p99 latency by 40%',
                      helper:
                          'Each line becomes a bullet point (•) on the resume',
                    ),
                    _field(
                      'Keywords (comma-separated)',
                      _keywordsCtrl,
                      hint: 'e.g. Go, Docker, gRPC, Kubernetes',
                      helper: 'ATS skill tags — shown as a subtle tag line',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    String? hint,
    String? helper,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helper,
          helperMaxLines: 2,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete experience?'),
        content: Text(
          '"${widget.item.name}" will be permanently removed.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete')),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
