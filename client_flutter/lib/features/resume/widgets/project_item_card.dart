import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline expand-to-edit card for a project entry.
class ProjectItemCard extends ConsumerStatefulWidget {
  final ProjectItemDto item;
  final bool initiallyExpanded;

  const ProjectItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<ProjectItemCard> createState() => _ProjectItemCardState();
}

class _ProjectItemCardState extends ConsumerState<ProjectItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _urlCtrl;
  late TextEditingController _highlightsCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _descCtrl = TextEditingController(text: widget.item.description);
    _urlCtrl = TextEditingController(text: widget.item.url);
    _highlightsCtrl =
        TextEditingController(text: widget.item.highlights.join('\n'));
    for (final c in [_nameCtrl, _descCtrl, _urlCtrl, _highlightsCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _descCtrl, _urlCtrl, _highlightsCtrl]) {
      c.dispose();
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
    await ref.read(resumeMatrixProvider.notifier).upsertSection('projects', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'description': _descCtrl.text,
      'url': _urlCtrl.text,
      'highlights': highlights,
      'exhibits': widget.item.exhibits,
      'active': widget.item.active,
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
      key: ValueKey('project_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('projects', widget.item.id),
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
                        child: Text(
                          widget.item.name.isEmpty ? 'New Project' : widget.item.name,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
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
                  if (widget.item.description.isNotEmpty && !_expanded)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.outline),
                      ),
                    ),
                  if (_expanded) ...[
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    _field('Project Name', _nameCtrl),
                    _field('Description', _descCtrl, maxLines: 3),
                    _field('URL', _urlCtrl),
                    _field('Highlights (one per line)', _highlightsCtrl,
                        maxLines: 4),
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
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_rounded, color: cs.onErrorContainer),
      );

  Future<bool> _confirmDelete(BuildContext context) async =>
      await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete project?'),
          content: Text('"${widget.item.name}" will be permanently removed.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete')),
          ],
        ),
      ) ??
      false;
}
