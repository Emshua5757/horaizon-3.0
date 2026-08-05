import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Skill group card with inline keyword chip editing.
///
/// Displays the skill group name and level, with keyword [FilterChip]s.
/// Tapping the edit icon expands to a form for editing name, level, and keywords.
class SkillChipRow extends ConsumerStatefulWidget {
  final SkillDto item;
  final bool initiallyExpanded;

  const SkillChipRow({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<SkillChipRow> createState() => _SkillChipRowState();
}

class _SkillChipRowState extends ConsumerState<SkillChipRow> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _levelCtrl;
  late TextEditingController _keywordsCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _levelCtrl = TextEditingController(text: widget.item.level);
    _keywordsCtrl =
        TextEditingController(text: widget.item.keywords.join(', '));
    for (final c in [_nameCtrl, _levelCtrl, _keywordsCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _levelCtrl, _keywordsCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    final keywords = _keywordsCtrl.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    await ref.read(resumeMatrixProvider.notifier).upsertSection('skills', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'level': _levelCtrl.text,
      'keywords': keywords,
    });
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
      key: ValueKey('skill_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('skills', widget.item.id),
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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.item.name.isEmpty
                                  ? 'New Skill Group'
                                  : widget.item.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.level.isNotEmpty)
                              Text(widget.item.level,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.outline)),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      const SizedBox(width: 8),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (!_expanded && widget.item.keywords.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: widget.item.keywords
                          .take(8)
                          .map((k) => Chip(
                                label: Text(k),
                                labelStyle: theme.textTheme.labelSmall,
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ))
                          .toList(),
                    ),
                    if (widget.item.keywords.length > 8)
                      Text(
                        '+${widget.item.keywords.length - 8} more',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: cs.outline),
                      ),
                  ],
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Skill Group Name', _nameCtrl),
                    _field('Level (e.g. Expert)', _levelCtrl),
                    _field('Keywords (comma-separated)', _keywordsCtrl,
                        maxLines: 3),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              isDense: true),
        ),
      );

  Widget _deleteBg(ColorScheme cs) => Container(
        decoration: BoxDecoration(
            color: cs.errorContainer, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Delete skill group?'),
          content:
              Text('"${widget.item.name}" and all keywords will be removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}
