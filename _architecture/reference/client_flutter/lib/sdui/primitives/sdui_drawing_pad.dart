import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiDrawingPad extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiDrawingPad({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiDrawingPad> createState() => _SduiDrawingPadState();
}

class _SduiDrawingPadState extends ConsumerState<SduiDrawingPad> {
  final List<List<Offset>> _strokes = [];
  String _lastSerialized = '';

  void _parseSvgPathToStrokes(String svg) {
    _strokes.clear();
    if (svg.isEmpty) return;
    // Regex matches coordinate blocks: command (M or L), and float coordinates
    final matches = RegExp(r'([ML])\s*([\d\.-]+)\s+([\d\.-]+)').allMatches(svg);
    for (final m in matches) {
      final command = m.group(1);
      final x = double.tryParse(m.group(2) ?? '') ?? 0.0;
      final y = double.tryParse(m.group(3) ?? '') ?? 0.0;
      if (command == 'M') {
        _strokes.add([Offset(x, y)]);
      } else if (command == 'L') {
        if (_strokes.isNotEmpty) {
          _strokes.last.add(Offset(x, y));
        }
      }
    }
    _lastSerialized = svg;
  }

  String _serializeStrokes() {
    final buffer = StringBuffer();
    for (final stroke in _strokes) {
      if (stroke.isEmpty) continue;
      buffer.write('M ${stroke.first.dx.toStringAsFixed(1)} ${stroke.first.dy.toStringAsFixed(1)}');
      for (int i = 1; i < stroke.length; i++) {
        buffer.write(' L ${stroke[i].dx.toStringAsFixed(1)} ${stroke[i].dy.toStringAsFixed(1)}');
      }
      buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  void _clearCanvas(String bindKey) {
    setState(() {
      _strokes.clear();
      _lastSerialized = '';
    });
    ref.read(sduiStateVaultProvider.notifier).set(bindKey, '');
    widget.dispatcher.onStateChange(bindKey, '');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final dispatcher = widget.dispatcher;

    // 1. Retrieve Behaviors
    final double height = node.behavior<double>(HbpBehavior.HEIGHT) ?? 
                          node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble() ?? 200.0;
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? 
                                   node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 12.0;
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0; // 0=readonly, 1=editable
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;

    final strokeColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // 2. Retrieve Content
    final String? label = node.contentVal<String>(HbpContent.LABEL);
    final vaultValue = ref.watch(sduiStateVaultProvider.select((state) => state[bindKey] as String?));
    final String currentSvg = vaultValue ?? node.contentVal<String>(HbpContent.VALUE) ?? '';

    // Synchronize currentSvg into local strokes if it changes externally
    if (currentSvg != _lastSerialized) {
      _parseSvgPathToStrokes(currentSvg);
    }

    Widget padCanvas = LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(borderRadiusVal),
            border: Border.all(color: colorScheme.outlineVariant, width: 1.0),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadiusVal),
                  child: interactiveMode == 1
                      ? GestureDetector(
                          onPanStart: (details) {
                            setState(() {
                              _strokes.add([details.localPosition]);
                            });
                          },
                          onPanUpdate: (details) {
                            setState(() {
                              if (_strokes.isNotEmpty) {
                                _strokes.last.add(details.localPosition);
                              }
                            });
                          },
                          onPanEnd: (_) {
                            final svgStr = _serializeStrokes();
                            _lastSerialized = svgStr;
                            ref.read(sduiStateVaultProvider.notifier).set(bindKey, svgStr);
                            dispatcher.onStateChange(bindKey, svgStr);
                          },
                          child: CustomPaint(
                            painter: _DrawingPainter(
                              strokes: _strokes,
                              strokeColor: strokeColor,
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: _DrawingPainter(
                            strokes: _strokes,
                            strokeColor: strokeColor,
                          ),
                        ),
                ),
              ),
              if (interactiveMode == 1 && _strokes.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withAlpha(200),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 20),
                      tooltip: 'Clear canvas',
                      onPressed: () => _clearCanvas(bindKey),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );

    if (label != null && label.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.gesture_rounded, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            padCanvas,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: padCanvas,
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color strokeColor;

  _DrawingPainter({
    required this.strokes,
    required this.strokeColor,
  });

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
  bool shouldRepaint(covariant _DrawingPainter oldDelegate) {
    return oldDelegate.strokes != oldDelegate.strokes || oldDelegate.strokeColor != strokeColor;
  }
}
