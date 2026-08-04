import 'package:flutter/material.dart';

/// Generic tab container used in the 7-tab resume editor.
///
/// Provides a scrollable [ListView] body with a [FloatingActionButton]
/// for adding new items. The [emptyState] is shown when [isEmpty] is true.
class ResumeSectionTab extends StatelessWidget {
  final String title;
  final bool isEmpty;
  final Widget emptyState;
  final Widget child;
  final VoidCallback onAdd;

  const ResumeSectionTab({
    super.key,
    required this.title,
    required this.isEmpty,
    required this.emptyState,
    required this.child,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isEmpty
              ? SizedBox.expand(key: const ValueKey('empty'), child: emptyState)
              : SingleChildScrollView(
                  key: const ValueKey('list'),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  child: child,
                ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'fab_$title',
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: Text('Add ${title.toLowerCase()}'),
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
          ),
        ),
      ],
    );
  }
}

/// Illustrated empty state widget shown when a section has no items.
class SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const SectionEmptyState({
    super.key,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: cs.outline),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
