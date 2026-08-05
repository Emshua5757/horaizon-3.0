import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline edit card for a single education entry.
class EducationItemCard extends ConsumerStatefulWidget {
  final EducationDto item;
  final bool initiallyExpanded;

  const EducationItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<EducationItemCard> createState() => _EducationItemCardState();
}

class _EducationItemCardState extends ConsumerState<EducationItemCard> {
  late bool _expanded;
  late TextEditingController _instCtrl;
  late TextEditingController _areaCtrl;
  late TextEditingController _typeCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _scoreCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _instCtrl = TextEditingController(text: widget.item.institution);
    _areaCtrl = TextEditingController(text: widget.item.area);
    _typeCtrl = TextEditingController(text: widget.item.studyType);
    _startCtrl = TextEditingController(text: widget.item.startDate);
    _endCtrl = TextEditingController(text: widget.item.endDate);
    _scoreCtrl = TextEditingController(text: widget.item.score);
    for (final c in [
      _instCtrl,
      _areaCtrl,
      _typeCtrl,
      _startCtrl,
      _endCtrl,
      _scoreCtrl
    ]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [
      _instCtrl,
      _areaCtrl,
      _typeCtrl,
      _startCtrl,
      _endCtrl,
      _scoreCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    await ref.read(resumeMatrixProvider.notifier).upsertSection('education', {
      'id': widget.item.id,
      'institution': _instCtrl.text,
      'area': _areaCtrl.text,
      'study_type': _typeCtrl.text,
      'start_date': _startCtrl.text,
      'end_date': _endCtrl.text,
      'score': _scoreCtrl.text,
      'url': widget.item.url,
      'courses': widget.item.courses,
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
      key: ValueKey('edu_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('education', widget.item.id),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => _expanded = !_expanded),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 250),
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
                              widget.item.institution.isEmpty
                                  ? 'New Education'
                                  : widget.item.institution,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.studyType.isNotEmpty ||
                                widget.item.area.isNotEmpty)
                              Text(
                                '${widget.item.studyType} in ${widget.item.area}',
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
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: cs.outline,
                      ),
                    ],
                  ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Institution', _instCtrl),
                    _field('Area / Field of Study', _areaCtrl),
                    _field('Degree Type (e.g. BS, MS)', _typeCtrl),
                    Row(children: [
                      Expanded(child: _field('Start Date', _startCtrl)),
                      const SizedBox(width: 8),
                      Expanded(child: _field('End Date', _endCtrl)),
                    ]),
                    _field('GWA / Score', _scoreCtrl),
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
          title: const Text('Delete education entry?'),
          content:
              Text('"${widget.item.institution}" will be permanently removed.'),
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
