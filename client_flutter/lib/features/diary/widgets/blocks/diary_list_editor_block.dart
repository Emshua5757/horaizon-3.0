import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryListEditorBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryListEditorBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryListEditorBlock> createState() => _DiaryListEditorBlockState();
}

class _DiaryListEditorBlockState extends State<DiaryListEditorBlock> {
  late List<String> _items;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _items = (map['items'] as List?)?.map((e) => e.toString()).toList() ?? ['List item 1'];
  }

  void _save() {
    widget.onChanged?.call({'items': _items});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        children: [
          ..._items.asMap().entries.map((entry) {
            final idx = entry.key;
            return Row(
              children: [
                const Text('• ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: entry.value)..selection = TextSelection.collapsed(offset: entry.value.length),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true),
                    onChanged: (val) {
                      _items[idx] = val;
                      _save();
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, size: 16),
                  onPressed: () {
                    setState(() => _items.removeAt(idx));
                    _save();
                  },
                ),
              ],
            );
          }),
          TextButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add item'),
            onPressed: () {
              setState(() => _items.add(''));
              _save();
            },
          ),
        ],
      ),
    );
  }
}

class DiaryListViewBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryListViewBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final map = block.contentAsMap;
    final items = (map['items'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, idx) => ListTile(
        dense: true,
        leading: const Icon(Icons.arrow_right),
        title: Text(items[idx]),
      ),
    );
  }
}

class DiaryOrdinalSliderBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryOrdinalSliderBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryOrdinalSliderBlock> createState() => _DiaryOrdinalSliderBlockState();
}

class _DiaryOrdinalSliderBlockState extends State<DiaryOrdinalSliderBlock> {
  late int _rating;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _rating = (map['value'] as num?)?.toInt() ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final map = widget.block.contentAsMap;
    final label = (map['label'] ?? 'Rating').toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Row(
            children: List.generate(5, (idx) {
              final star = idx + 1;
              return IconButton(
                icon: Icon(
                  star <= _rating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                ),
                onPressed: () {
                  setState(() => _rating = star);
                  widget.onChanged?.call({'label': label, 'value': _rating});
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class DiaryRadioBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryRadioBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryRadioBlock> createState() => _DiaryRadioBlockState();
}

class _DiaryRadioBlockState extends State<DiaryRadioBlock> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final map = widget.block.contentAsMap;
    _selected = (map['value'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
    final map = widget.block.contentAsMap;
    final options = (map['options'] as List?)?.map((e) => e.toString()).toList() ?? ['Option A', 'Option B'];

    return Column(
      children: options.map((opt) {
        return RadioListTile<String>(
          title: Text(opt),
          value: opt,
          // ignore: deprecated_member_use
          groupValue: _selected,
          // ignore: deprecated_member_use
          onChanged: (val) {
            if (val != null) {
              setState(() => _selected = val);
              widget.onChanged?.call({'value': val});
            }
          },
        );
      }).toList(),
    );
  }
}

class DiaryShimmerBlock extends StatelessWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryShimmerBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
