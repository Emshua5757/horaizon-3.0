import 'package:flutter/material.dart';

/// Horizontal card-based template selector showing a preview thumbnail + name.
///
/// Shows three cards: Default / Modern / Minimalist.
/// Selected card has a primary-colored border; others are outlined.
/// Tapping a card calls [onSelected].
class TemplatePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TemplatePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _templates = [
    (id: 'default',    label: 'Default',    preview: 'assets/resume_templates/default.png'),
    (id: 'modern',     label: 'Modern',     preview: 'assets/resume_templates/modern.png'),
    (id: 'minimalist', label: 'Minimalist', preview: 'assets/resume_templates/minimalist.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _templates.map((t) {
          final isSelected = t.id == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => onSelected(t.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                width: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? cs.primary : cs.outlineVariant,
                    width: isSelected ? 2.5 : 1,
                  ),
                  color: isSelected
                      ? cs.primaryContainer.withValues(alpha: 0.3)
                      : cs.surfaceContainerLow,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview thumbnail
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(10)),
                      child: Image.asset(
                        t.preview,
                        height: 80,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 80,
                          color: cs.surfaceContainerHighest,
                          child: Icon(Icons.article_outlined,
                              color: cs.outline, size: 28),
                        ),
                      ),
                    ),
                    // Label row
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(Icons.check_circle_rounded,
                                  size: 14, color: cs.primary),
                            ),
                          Flexible(
                            child: Text(
                              t.label,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: isSelected
                                    ? cs.primary
                                    : cs.onSurface,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
