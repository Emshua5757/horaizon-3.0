import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Inline expand-to-edit card for an organizational/leadership experience entry.
///
/// - Collapsed: shows organization name, role, and date range.
/// - Expanded: full edit form with auto-save (800 ms debounce).
/// - Swipe-to-dismiss: optimistic delete via [ResumeMatrixNotifier].
class OrgItemCard extends ConsumerStatefulWidget {
  final OrgItemDto item;
  final bool initiallyExpanded;

  const OrgItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<OrgItemCard> createState() => _OrgItemCardState();
}

class _OrgItemCardState extends ConsumerState<OrgItemCard> {
  late bool _expanded;
  late TextEditingController _orgCtrl;
  late TextEditingController _roleCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _summaryCtrl;
  late TextEditingController _highlightsCtrl;

  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _orgCtrl = TextEditingController(text: widget.item.organization);
    _roleCtrl = TextEditingController(text: widget.item.role);
    _startCtrl = TextEditingController(text: widget.item.startDate);
    _endCtrl = TextEditingController(text: widget.item.endDate);
    _summaryCtrl = TextEditingController(text: widget.item.summary);
    _highlightsCtrl =
        TextEditingController(text: widget.item.highlights.join('\n'));

    for (final ctrl in [
      _orgCtrl,
      _roleCtrl,
      _startCtrl,
      _endCtrl,
      _summaryCtrl,
      _highlightsCtrl,
    ]) {
      ctrl.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final ctrl in [
      _orgCtrl,
      _roleCtrl,
      _startCtrl,
      _endCtrl,
      _summaryCtrl,
      _highlightsCtrl,
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

    await ref.read(resumeMatrixProvider.notifier).upsertSection(
      'organizations',
      {
        'id': widget.item.id,
        'organization': _orgCtrl.text,
        'role': _roleCtrl.text,
        'start_date': _startCtrl.text,
        'end_date': _endCtrl.text,
        'summary': _summaryCtrl.text,
        'highlights': highlights,
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
      key: ValueKey('org_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) {
        ref
            .read(resumeMatrixProvider.notifier)
            .deleteItem('organizations', widget.item.id);
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
                              widget.item.organization.isEmpty
                                  ? 'New Org Experience'
                                  : widget.item.organization,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.role.isNotEmpty)
                              Text(
                                widget.item.role,
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
                    _field('Organization / Club / Committee', _orgCtrl,
                        hint: 'e.g. ICpEP.SE CTU-MC, Student Government'),
                    _field('Role / Title', _roleCtrl,
                        hint: 'e.g. Secretary, Vice President'),
                    Row(
                      children: [
                        Expanded(
                            child: _field('Start Date', _startCtrl,
                                hint: 'e.g. Aug 2023 or Present')),
                        const SizedBox(width: 8),
                        Expanded(
                            child: _field('End Date', _endCtrl,
                                hint: 'e.g. May 2025 or Present')),
                      ],
                    ),
                    _field(
                      'Summary',
                      _summaryCtrl,
                      maxLines: 2,
                      hint: 'Describe your overall role or involvement',
                    ),
                    _field(
                      'Highlights (one per line — auto-bulleted)',
                      _highlightsCtrl,
                      maxLines: 4,
                      hint:
                          'e.g. Organized Annual Tech Summit with 200+ attendees',
                      helper:
                          'Each line becomes a bullet point (•) on the resume',
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
        title: const Text('Delete org experience?'),
        content: Text(
          '"${widget.item.organization}" will be permanently removed.',
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

/// Factory helper — creates a new blank [OrgItemDto] for the FAB add action.
OrgItemDto newBlankOrgItem() => OrgItemDto(
      id: _uuid.v4(),
      organization: '',
      role: '',
      startDate: '',
      endDate: '',
      summary: '',
      highlights: [],
      active: true,
    );
