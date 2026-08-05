import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/resume_matrix_provider.dart';
import '../resume_matrix_dto.dart';

/// Inline edit card for a certificate entry.
class CertificateItemCard extends ConsumerStatefulWidget {
  final CertificateDto item;
  final bool initiallyExpanded;

  const CertificateItemCard({
    super.key,
    required this.item,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<CertificateItemCard> createState() =>
      _CertificateItemCardState();
}

class _CertificateItemCardState extends ConsumerState<CertificateItemCard> {
  late bool _expanded;
  late TextEditingController _nameCtrl;
  late TextEditingController _issuerCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _urlCtrl;
  Timer? _debounce;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _nameCtrl = TextEditingController(text: widget.item.name);
    _issuerCtrl = TextEditingController(text: widget.item.issuer);
    _dateCtrl = TextEditingController(text: widget.item.date);
    _urlCtrl = TextEditingController(text: widget.item.url);
    for (final c in [_nameCtrl, _issuerCtrl, _dateCtrl, _urlCtrl]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final c in [_nameCtrl, _issuerCtrl, _dateCtrl, _urlCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), _save);
  }

  Future<void> _save() async {
    await ref
        .read(resumeMatrixProvider.notifier)
        .upsertSection('certificates', {
      'id': widget.item.id,
      'name': _nameCtrl.text,
      'issuer': _issuerCtrl.text,
      'date': _dateCtrl.text,
      'url': _urlCtrl.text,
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
      key: ValueKey('cert_${widget.item.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(cs),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => ref
          .read(resumeMatrixProvider.notifier)
          .deleteItem('certificates', widget.item.id),
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
                              widget.item.name.isEmpty
                                  ? 'New Certificate'
                                  : widget.item.name,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (widget.item.issuer.isNotEmpty)
                              Text(widget.item.issuer,
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: cs.outline)),
                          ],
                        ),
                      ),
                      if (_saved)
                        Icon(Icons.check_circle_rounded,
                            color: cs.primary, size: 18),
                      if (widget.item.date.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(widget.item.date,
                              style: theme.textTheme.labelSmall
                                  ?.copyWith(color: cs.outline)),
                        ),
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
                    _field('Certificate Name', _nameCtrl),
                    _field('Issuer', _issuerCtrl),
                    _field('Date (YYYY-MM)', _dateCtrl),
                    _field('URL', _urlCtrl),
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
          title: const Text('Delete certificate?'),
          content: Text('"${widget.item.name}" will be permanently removed.'),
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
