import 'package:flutter/material.dart';

class DiaryBlockPickerBottomSheet extends StatelessWidget {
  final ValueChanged<String> onBlockSelected;

  const DiaryBlockPickerBottomSheet({
    super.key,
    required this.onBlockSelected,
  });

  static const List<Map<String, dynamic>> _categories = [
    {
      'name': 'Text & Content',
      'items': [
        {'type': 'markdown', 'label': 'Markdown', 'icon': Icons.notes},
        {'type': 'text_input', 'label': 'Text Field', 'icon': Icons.edit_note},
        {'type': 'code', 'label': 'Code Snippet', 'icon': Icons.code},
        {'type': 'table', 'label': 'Table', 'icon': Icons.table_chart},
      ],
    },
    {
      'name': 'Tasks & Form',
      'items': [
        {'type': 'checkbox', 'label': 'Checklist', 'icon': Icons.check_box_outlined},
        {'type': 'toggle', 'label': 'Toggle Switch', 'icon': Icons.toggle_on_outlined},
        {'type': 'slider', 'label': 'Slider', 'icon': Icons.tune},
        {'type': 'progress', 'label': 'Progress Bar', 'icon': Icons.linear_scale},
        {'type': 'button', 'label': 'Button', 'icon': Icons.smart_button},
      ],
    },
    {
      'name': 'Data & Media',
      'items': [
        {'type': 'image', 'label': 'Image', 'icon': Icons.image_outlined},
        {'type': 'chart', 'label': 'Chart', 'icon': Icons.bar_chart},
        {'type': 'date_picker', 'label': 'Date Picker', 'icon': Icons.calendar_today},
        {'type': 'time_picker', 'label': 'Time Picker', 'icon': Icons.access_time},
        {'type': 'certification', 'label': 'Certification', 'icon': Icons.workspace_premium},
      ],
    },
    {
      'name': 'Structure',
      'items': [
        {'type': 'divider', 'label': 'Divider', 'icon': Icons.horizontal_rule},
        {'type': 'spacer', 'label': 'Spacer', 'icon': Icons.height},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Block', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _categories.length,
              itemBuilder: (context, catIdx) {
                final cat = _categories[catIdx];
                final items = cat['items'] as List<Map<String, dynamic>>;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        cat['name'] as String,
                        style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, itemIdx) {
                        final item = items[itemIdx];
                        return InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            onBlockSelected(item['type'] as String);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: theme.colorScheme.outlineVariant),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              children: [
                                Icon(item['icon'] as IconData, size: 20, color: theme.colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    item['label'] as String,
                                    style: theme.textTheme.bodyMedium,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
