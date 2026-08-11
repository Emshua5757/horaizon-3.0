import 'package:flutter/material.dart';
import '../../models/diary_block_dto.dart';

class DiaryDrawingBlock extends StatefulWidget {
  final DiaryBlockDto block;
  final ValueChanged<Map<String, dynamic>>? onChanged;
  final VoidCallback? onDelete;

  const DiaryDrawingBlock({
    super.key,
    required this.block,
    this.onChanged,
    this.onDelete,
  });

  @override
  State<DiaryDrawingBlock> createState() => _DiaryDrawingBlockState();
}

class _DiaryDrawingBlockState extends State<DiaryDrawingBlock> {
  final List<List<Offset>> _strokes = [];

  void _save() {
    final buffer = StringBuffer();
    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      buffer.write('M ${stroke.first.dx.toStringAsFixed(1)} ${stroke.first.dy.toStringAsFixed(1)}');
      for (int i = 1; i < stroke.length; i++) {
        buffer.write(' L ${stroke[i].dx.toStringAsFixed(1)} ${stroke[i].dy.toStringAsFixed(1)}');
      }
      buffer.write(' ');
    }
    widget.onChanged?.call({'svg': buffer.toString().trim()});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onPanStart: (details) {
                setState(() => _strokes.add([details.localPosition]));
              },
              onPanUpdate: (details) {
                setState(() {
                  if (_strokes.isNotEmpty) _strokes.last.add(details.localPosition);
                });
              },
              onPanEnd: (_) => _save(),
              child: CustomPaint(
                painter: _DrawingPainter(strokes: _strokes, strokeColor: colorScheme.primary),
              ),
            ),
          ),
          if (_strokes.isNotEmpty)
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error),
                onPressed: () {
                  setState(() => _strokes.clear());
                  _save();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  _DrawingPainter({required this.strokes, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (int i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) => true;
}
