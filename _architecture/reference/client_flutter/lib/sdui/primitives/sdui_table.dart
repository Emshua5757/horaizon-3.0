import 'dart:convert';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:flutter/material.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';

class SduiTable extends StatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiTable({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  State<SduiTable> createState() => _SduiTableState();
}

class _SduiTableState extends State<SduiTable> {
  late List<String> _flatMatrix;
  int _rowCount = 0;
  int _colCount = 0;

  bool _isEditing = false;
  int? _editingRow;
  int? _editingCol;
  late TextEditingController _cellController;
  late FocusNode _cellFocusNode;

  // Behavior Keys
  int get _minRows => _int(125) ?? 1;
  int get _minCols => _int(126) ?? 1;
  double get _colWidth {
    final raw = widget.node.behavior(127);
    if (raw is num) return raw.toDouble();
    return 120.0;
  }
  bool get _isReadOnly => _int(95) == 0;
  String get _bindKey => widget.node.behavior<String>(40) ?? widget.node.id;

  // Content Keys
  String get _initialContent => widget.node.contentVal<String>(0) ?? "";
  String? get _headerLabel => widget.node.contentVal<String>(1);

  int? _int(int key) {
    final raw = widget.node.behavior(key);
    if (raw is num) return raw.toInt();
    return null;
  }

  @override
  void initState() {
    super.initState();
    _parseContent(_initialContent);
    _cellController = TextEditingController();
    _cellFocusNode = FocusNode();
    _cellFocusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted && !_cellFocusNode.hasFocus && _isEditing) {
      _saveCellEdit();
    }
  }

  @override
  void didUpdateWidget(SduiTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldContent = oldWidget.node.contentVal<String>(0) ?? "";
    if (oldContent != _initialContent && !_isEditing) {
      _parseContent(_initialContent);
    }
  }

  @override
  void dispose() {
    _cellFocusNode.removeListener(_onFocusChange);
    _cellController.dispose();
    _cellFocusNode.dispose();
    super.dispose();
  }

  void _parseContent(String payload) {
    try {
      if (payload.trim().isEmpty) {
        _colCount = 2;
        _rowCount = 2;
        _flatMatrix = ['Header 1', 'Header 2', 'Row 1', 'Row 1'];
      } else {
        final decoded = jsonDecode(payload);
        if (decoded is List && decoded.isNotEmpty) {
          _rowCount = decoded.length;
          _colCount = (decoded[0] as List).length;
          _flatMatrix = [];
          for (var row in decoded) {
            for (var cell in row as List) {
              _flatMatrix.add(cell.toString());
            }
          }
        } else {
          throw Exception('Invalid matrix format');
        }
      }
    } catch (e) {
      _colCount = 2;
      _rowCount = 2;
      _flatMatrix = ['Header 1', 'Header 2', 'Error', 'Error'];
    }
  }

  void _saveMatrix() {
    final bindKey = _bindKey;
    if (bindKey.isNotEmpty) {
      List<List<String>> output = [];
      for (int r = 0; r < _rowCount; r++) {
        output.add(_flatMatrix.sublist(r * _colCount, (r + 1) * _colCount));
      }
      final serialized = jsonEncode(output);
      widget.dispatcher.onStateChange(bindKey, serialized);
    }
  }

  void _startCellEdit(int row, int col) {
    if (_isReadOnly) return;
    
    // Save any existing edit first
    if (_isEditing && (_editingRow != row || _editingCol != col)) {
      _flatMatrix[_editingRow! * _colCount + _editingCol!] = _cellController.text;
    }

    setState(() {
      _isEditing = true;
      _editingRow = row;
      _editingCol = col;
      _cellController.text = _flatMatrix[row * _colCount + col];
      // Select all text
      _cellController.selection = TextSelection(
        baseOffset: 0, 
        extentOffset: _cellController.text.length
      );
    });
    Future.microtask(() => _cellFocusNode.requestFocus());
  }

  void _saveCellEdit() {
    if (_editingRow != null && _editingCol != null) {
      setState(() {
        _flatMatrix[_editingRow! * _colCount + _editingCol!] = _cellController.text;
        _isEditing = false;
        _editingRow = null;
        _editingCol = null;
      });
      _saveMatrix();
    }
  }

  void _addRow() {
    if (_isReadOnly) return;
    if (_rowCount == 0) {
      _colCount = 1;
      _rowCount = 1;
      _flatMatrix.add('New Cell');
    } else {
      _rowCount++;
      _flatMatrix.addAll(List.generate(_colCount, (_) => 'New Cell'));
    }
    setState(() {});
    _saveMatrix();
  }

  void _addColumn() {
    if (_isReadOnly || _rowCount == 0) return;
    for (int r = _rowCount - 1; r >= 0; r--) {
      _flatMatrix.insert(r * _colCount + _colCount, 'New Col');
    }
    _colCount++;
    setState(() {});
    _saveMatrix();
  }

  void _removeRow() {
    if (_isReadOnly) return;
    if (_rowCount > _minRows) {
      _flatMatrix.removeRange((_rowCount - 1) * _colCount, _rowCount * _colCount);
      _rowCount--;
      setState(() {});
      _saveMatrix();
    }
  }

  void _removeColumn() {
    if (_isReadOnly) return;
    if (_rowCount > 0 && _colCount > _minCols) {
      for (int r = _rowCount - 1; r >= 0; r--) {
        _flatMatrix.removeAt(r * _colCount + (_colCount - 1));
      }
      _colCount--;
      setState(() {});
      _saveMatrix();
    }
  }

  Color _resolveAccentColor(ThemeData theme) {
    final tokenColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(96));
    return tokenColor ?? theme.colorScheme.primaryContainer;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accentColor = _resolveAccentColor(theme);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_headerLabel != null || !_isReadOnly)
          Row(
            children: [
              if (_headerLabel != null)
                Expanded(
                  child: Text(
                    _headerLabel!,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                const Spacer(),
              if (!_isReadOnly) ...[
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  tooltip: 'Remove Row',
                  onPressed: _rowCount > _minRows ? _removeRow : null,
                  visualDensity: VisualDensity.compact,
                ),
                Text('Row', style: theme.textTheme.bodySmall),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'Add Row',
                  onPressed: _addRow,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Container(width: 1, height: 16, color: theme.dividerColor),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.remove, size: 16),
                  tooltip: 'Remove Column',
                  onPressed: _rowCount > 0 && _colCount > _minCols ? _removeColumn : null,
                  visualDensity: VisualDensity.compact,
                ),
                Text('Col', style: theme.textTheme.bodySmall),
                IconButton(
                  icon: const Icon(Icons.add, size: 16),
                  tooltip: 'Add Column',
                  onPressed: _addColumn,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ],
          ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: FixedColumnWidth(_colWidth),
            border: TableBorder.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
              borderRadius: BorderRadius.circular(4),
            ),
            children: List.generate(_rowCount, (rowIndex) {
              final isHeader = rowIndex == 0;
              return TableRow(
                decoration: BoxDecoration(
                  color: isHeader 
                      ? accentColor.withValues(alpha: 0.3)
                      : (rowIndex % 2 == 0 
                          ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1)
                          : Colors.transparent),
                ),
                children: List.generate(_colCount, (colIndex) {
                  final cellContent = _flatMatrix[rowIndex * _colCount + colIndex];
                  final isCellEditing = _isEditing && _editingRow == rowIndex && _editingCol == colIndex;

                  return TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: GestureDetector(
                      onDoubleTap: () => _startCellEdit(rowIndex, colIndex),
                      onTap: () => _startCellEdit(rowIndex, colIndex),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        alignment: Alignment.center,
                        child: isCellEditing
                            ? Material(
                                type: MaterialType.transparency,
                                child: TextField(
                                  controller: _cellController,
                                  focusNode: _cellFocusNode,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onSubmitted: (_) => _saveCellEdit(),
                                ),
                              )
                            : Text(
                                cellContent,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
                                  color: isHeader ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ),
      ],
    );
  }
}
