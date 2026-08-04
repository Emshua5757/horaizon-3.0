import 'package:flutter/material.dart';

/// Horizontal chip selector for Typst template choice.
///
/// Shows three [ChoiceChip]s: Default / Modern / Minimalist.
/// The selected chip uses solid fill; others are outlined.
class TemplatePicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelected;

  const TemplatePicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  static const _templates = [
    (id: 'default',    label: 'Default',    icon: Icons.article_outlined),
    (id: 'modern',     label: 'Modern',     icon: Icons.view_sidebar_outlined),
    (id: 'minimalist', label: 'Minimalist', icon: Icons.density_small_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _templates.map((t) {
          final isSelected = t.id == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(t.icon,
                  size: 16,
                  color: isSelected ? cs.onPrimary : cs.onSurfaceVariant),
              label: Text(t.label),
              selected: isSelected,
              onSelected: (_) => onSelected(t.id),
              selectedColor: cs.primary,
              labelStyle: TextStyle(
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
