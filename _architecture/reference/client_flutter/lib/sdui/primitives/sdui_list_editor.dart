import 'dart:async';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

// ─── List Style constants ──────────────────────────────────────────────
abstract final class ListStyle {
  static const int tags = 0;
  static const int checklist = 1;
  static const int bullets = 2;
  static const int numbers = 3;
  static const int custom = 4;
  static const int radio = 5;
}

// ─── Bullet Style constants ──────────────────────────────────────────────
abstract final class BulletStyle {
  static const int dot = 0;
  static const int dash = 1;
  static const int asterisk = 2;
  static const int arrow = 3;
}

class SduiListEditor extends StatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiListEditor({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  State<SduiListEditor> createState() => _SduiListEditorState();
}

class _ListItem {
  String text;
  bool isChecked;
  final FocusNode focusNode;
  final FocusNode keyboardFocusNode;
  final TextEditingController controller;

  _ListItem({required this.text, this.isChecked = false})
      : focusNode = FocusNode(),
        keyboardFocusNode = FocusNode(skipTraversal: true),
        controller = TextEditingController(text: text);

  void dispose() {
    focusNode.dispose();
    keyboardFocusNode.dispose();
    controller.dispose();
  }
}

class _SduiListEditorState extends State<SduiListEditor> {
  final List<_ListItem> _items = [];
  Timer? _debounce;
  bool _isTagEditMode = false;

  int get _listStyle => _int(60) ?? ListStyle.bullets;
  int get _bulletStyle => _int(61) ?? BulletStyle.dot;
  IconData? get _accentIcon {
    final name = widget.node.behavior<String>(62);
    if (name == null || name.isEmpty) return null;
    return SduiIconRegistry.resolve(name);
  }
  int get _maxItems => _int(63) ?? 0;
  int get _minItems => _int(64) ?? 1;
  bool get _isReadOnly => _int(95) == 0;
  String get _bindKey => widget.node.behavior<String>(40) ?? widget.node.id;
  
  String get _initialContent => widget.node.contentVal<String>(0) ?? "";
  String? get _headerLabel => widget.node.contentVal<String>(1);
  String? get _itemHintText => widget.node.contentVal<String>(2);

  int? _int(int key) {
    final raw = widget.node.behavior(key);
    if (raw is num) return raw.toInt();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadFromContent(_initialContent);
    if (_items.isEmpty && !_isReadOnly) _appendNewItem();
  }

  @override
  void didUpdateWidget(SduiListEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContent = oldWidget.node.contentVal<String>(0) ?? "";
    if (oldContent != _initialContent && _serialize() != _initialContent) {
      for (final item in _items) {
        item.dispose();
      }
      _items.clear();
      _loadFromContent(_initialContent);
      if (_items.isEmpty && !_isReadOnly) _appendNewItem();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  void _loadFromContent(String content) {
    if (content.trim().isEmpty) return;
    for (final raw in content.split('\n').where((l) => l.trim().isNotEmpty)) {
      final line = raw.trim();
      switch (_listStyle) {
        case ListStyle.checklist:
          final isChecked = line.startsWith('- [x]') || line.startsWith('* [x]');
          final text = line.replaceFirst(RegExp(r'^[-*]\s*\[[ x]\]\s*'), '').trim();
          _items.add(_ListItem(text: text, isChecked: isChecked));
        case ListStyle.tags:
          _items.add(_ListItem(text: line.replaceFirst(RegExp(r'^([-*#])\s*'), '').trim()));
        case ListStyle.numbers:
          _items.add(_ListItem(text: line.replaceFirst(RegExp(r'^\d+\.\s*'), '').trim()));
        case ListStyle.radio:
          final isSelected = line.startsWith('>');
          final text = line.replaceFirst(RegExp(r'^[>-]\s*'), '').trim();
          _items.add(_ListItem(text: text, isChecked: isSelected));
        default:
          _items.add(_ListItem(text: line.replaceFirst(RegExp(r'^[-*•🏋️›–]\s*'), '').trim()));
      }
    }
  }

  String _serialize() {
    final Iterable<_ListItem> src = _listStyle == ListStyle.tags
        ? _items.where((i) => i.controller.text.trim().isNotEmpty)
        : _items;

    int seq = 1;
    return src.map((item) {
      final text = item.controller.text.trim();
      return switch (_listStyle) {
        ListStyle.checklist => '- [${item.isChecked ? 'x' : ' '}] $text',
        ListStyle.tags      => '# $text',
        ListStyle.numbers   => '${seq++}. $text',
        ListStyle.radio     => '${item.isChecked ? '>' : '-'} $text',
        _                   => '- $text',
      };
    }).join('\n');
  }

  void _appendNewItem({int? afterIndex}) {
    if (_maxItems > 0 && _items.length >= _maxItems) return;
    final item = _ListItem(text: '');
    final insertAt = afterIndex != null ? afterIndex + 1 : _items.length;
    _items.insert(insertAt, item);
    item.controller.addListener(() => item.text = item.controller.text);
  }

  void _persistChange() {
    if (_isReadOnly) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (_listStyle != ListStyle.tags) {
        _items.removeWhere((i) =>
            i.controller.text.trim().isEmpty &&
            _items.length > 1 &&
            !i.focusNode.hasFocus);
        if (_items.isEmpty) _appendNewItem();
      }
      
      final bindKey = _bindKey;
      if (bindKey.isNotEmpty) {
        widget.dispatcher.onStateChange(bindKey, _serialize());
      }
    });
  }

  void _toggleChecked(int index) {
    if (_isReadOnly) return;
    setState(() => _items[index].isChecked = !_items[index].isChecked);
    
    final bindKey = _bindKey;
    if (bindKey.isNotEmpty) {
      widget.dispatcher.onStateChange(bindKey, _serialize());
    }
  }

  void _onEnterPressed(int index) {
    if (_isReadOnly) return;
    setState(() => _appendNewItem(afterIndex: index));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (index + 1 < _items.length) _items[index + 1].focusNode.requestFocus();
    });
  }

  void _onBackspaceOnEmpty(int index) {
    final floor = _minItems.clamp(1, 999);
    if (_isReadOnly || _items.length <= floor) return;
    setState(() {
      _items[index].dispose();
      _items.removeAt(index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = (index - 1).clamp(0, _items.length - 1);
      _items[target].focusNode.requestFocus();
      final ctrl = _items[target].controller;
      ctrl.selection = TextSelection.fromPosition(TextPosition(offset: ctrl.text.length));
    });
    _persistChange();
  }

  void _selectRadio(int index) {
    if (_isReadOnly) return;
    setState(() {
      for (int i = 0; i < _items.length; i++) {
        _items[i].isChecked = (i == index);
      }
    });
    final bindKey = _bindKey;
    if (bindKey.isNotEmpty) {
      widget.dispatcher.onStateChange(bindKey, _serialize());
    }
  }

  Color _resolveAccentColor(ThemeData theme) {
    final tokenColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(96));
    return tokenColor ?? theme.colorScheme.secondary;
  }

  Color _resolveContainerColor(ThemeData theme) {
    final tokenColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(96));
    if (tokenColor != null) {
       return tokenColor.withValues(alpha: 0.15); // Derive a container hue since we don't have secondaryContainer explicitly here
    }
    return theme.colorScheme.secondaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _resolveAccentColor(theme);

    if (_listStyle == ListStyle.tags && !_isTagEditMode) {
      return _buildTagReadMode(theme, accentColor);
    }

    final bool hasContainer = _listStyle == ListStyle.tags || _listStyle == ListStyle.custom;

    return Container(
      padding: hasContainer ? const EdgeInsets.all(12.0) : EdgeInsets.zero,
      decoration: hasContainer
          ? BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_headerLabel != null) _buildHeaderRow(theme, accentColor),
          if (_listStyle == ListStyle.checklist) _buildProgressHeader(theme, accentColor),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(_items.length, (index) => _buildItemRow(theme, accentColor, index)),
          ),
          if (!_isReadOnly) _buildFooterActions(theme, accentColor),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme, Color accentColor) {
    String label = _headerLabel!;
    if (label.contains('{num}')) {
      label = label.replaceAll('{num}', _items.length.toString());
      final reg = RegExp(r'\{([^}]+)\|([^}]+)\}');
      label = label.replaceAllMapped(reg, (match) {
        final singular = match.group(1) ?? '';
        final plural = match.group(2) ?? '';
        return _items.length == 1 ? singular : plural;
      });
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          if (_accentIcon != null) Icon(_accentIcon, size: 16, color: accentColor),
          if (_accentIcon != null) const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressHeader(ThemeData theme, Color accentColor) {
    final total = _items.length;
    final completed = _items.where((i) => i.isChecked).length;
    if (total == 0) return const SizedBox.shrink();

    final double progress = total > 0 ? completed / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.checklist_rtl, size: 14, color: accentColor.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Text(
                    '$completed of $total completed',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (completed == total && total > 0) ...[
                    const SizedBox(width: 6),
                    Icon(Icons.celebration, size: 13, color: Colors.amber.shade400),
                  ],
                ],
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6.0,
              backgroundColor: accentColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagReadMode(ThemeData theme, Color accentColor) {
    final tags = _items
        .map((i) => i.controller.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    return MouseRegion(
      cursor: _isReadOnly ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isReadOnly
            ? null
            : () => setState(() {
                  _isTagEditMode = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_items.isNotEmpty) _items.last.focusNode.requestFocus();
                  });
                }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(color: accentColor.withValues(alpha: 0.08)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.local_offer_outlined, size: 13, color: accentColor.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Expanded(
                child: tags.isEmpty
                    ? Text(
                        'Tap to add tags...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        ),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: tags.map((tag) => _buildTagChip(theme, accentColor, tag)).toList(),
                      ),
              ),
              if (!_isReadOnly) ...[
                const SizedBox(width: 8),
                Icon(Icons.edit_note, size: 16, color: accentColor.withValues(alpha: 0.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTagChip(ThemeData theme, Color accentColor, String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Text(
        '#$tag',
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
    );
  }

  Widget _buildItemRow(ThemeData theme, Color accentColor, int index) {
    final item = _items[index];
    final containerColor = _resolveContainerColor(theme);

    Widget prefix = switch (_listStyle) {
      ListStyle.checklist => SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: item.isChecked,
            onChanged: _isReadOnly ? null : (_) => _toggleChecked(index),
            activeColor: accentColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ListStyle.tags => Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: containerColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Icon(Icons.local_offer_outlined, size: 11, color: accentColor),
        ),
      ListStyle.numbers => Padding(
          padding: const EdgeInsets.only(right: 8.0, left: 4.0),
          child: Text(
            '${index + 1}.',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: accentColor.withValues(alpha: 0.8),
            ),
          ),
        ),
      ListStyle.radio => GestureDetector(
          onTap: () => _selectRadio(index),
          child: Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: item.isChecked ? accentColor : theme.colorScheme.outline,
                width: 2.0,
              ),
            ),
            child: item.isChecked
                ? Center(
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ListStyle.custom => Container(
          width: 24,
          height: 24,
          margin: const EdgeInsets.only(right: 8.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: containerColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(_accentIcon ?? Icons.circle, size: 11, color: accentColor),
        ),
      _ => Padding(
          padding: const EdgeInsets.only(right: 10.0, left: 8.0),
          child: switch (_bulletStyle) {
            BulletStyle.dash     => Text('–', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            BulletStyle.asterisk => Text('*', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            BulletStyle.arrow    => Text('›', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            _                    => Icon(Icons.circle, size: 6, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          },
        ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          prefix,
          Expanded(
            child: _isReadOnly
                ? Text(
                    item.text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: item.isChecked ? TextDecoration.lineThrough : null,
                      color: item.isChecked ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
                    ),
                  )
                : KeyboardListener(
                    focusNode: item.keyboardFocusNode,
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace &&
                          item.controller.text.isEmpty) {
                        _onBackspaceOnEmpty(index);
                      }
                    },
                    child: TextField(
                      controller: item.controller,
                      focusNode: item.focusNode,
                      maxLines: null,
                      textInputAction: TextInputAction.next,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: item.isChecked ? TextDecoration.lineThrough : null,
                        color: item.isChecked ? theme.colorScheme.onSurface.withValues(alpha: 0.4) : null,
                        fontWeight: _listStyle == ListStyle.tags ? FontWeight.w600 : FontWeight.normal,
                      ),
                      decoration: InputDecoration(
                        prefixText: _listStyle == ListStyle.tags ? '#' : null,
                        hintText: _itemHintText ?? (_listStyle == ListStyle.tags ? 'tag' : index == 0 ? 'Add an item...' : 'Item...'),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 4.0),
                      ),
                      onChanged: (_) => _persistChange(),
                      onSubmitted: (_) => _onEnterPressed(index),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(ThemeData theme, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              setState(() => _appendNewItem());
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_items.isNotEmpty) _items.last.focusNode.requestFocus();
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: accentColor.withValues(alpha: 0.6)),
                  const SizedBox(width: 6),
                  Text(
                    _listStyle == ListStyle.tags ? 'Add tag' : 'Add item',
                    style: theme.textTheme.bodySmall?.copyWith(color: accentColor.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
          ),
          if (_listStyle == ListStyle.tags)
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _items.removeWhere((i) => i.controller.text.trim().isEmpty && _items.length > 1);
                  _isTagEditMode = false;
                });
                
                final bindKey = _bindKey;
                if (bindKey.isNotEmpty) {
                  widget.dispatcher.onStateChange(bindKey, _serialize());
                }
              },
              icon: const Icon(Icons.done, size: 14),
              label: const Text('Done', style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: accentColor,
                side: BorderSide(color: accentColor.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}
