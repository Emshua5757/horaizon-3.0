import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

/// SduiTimeline - Type ID 28
/// 
/// High-performance data primitive rendering vertical or horizontal progress
/// steppers, milestone channels, or system execution histories.
class SduiTimeline extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiTimeline({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiTimeline> createState() => _SduiTimelineState();
}

class _SduiTimelineState extends ConsumerState<SduiTimeline> {
  List<SduiTimelineEvent> _events = [];
  dynamic _rawLastData;
  bool _isEditing = false;
  late TextEditingController _dataController;

  @override
  void initState() {
    super.initState();
    _parseData();
    _dataController = TextEditingController(text: _getRawDataString());
  }

  @override
  void didUpdateWidget(covariant SduiTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    _parseData();
    if (widget.node.id != oldWidget.node.id) {
      _dataController.text = _getRawDataString();
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  String _getRawDataString() {
    final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];
    final rawData = (vaultValue is String && vaultValue.isNotEmpty) ? vaultValue : widget.node.contentVal<dynamic>(HbpContent.DATA);

    if (rawData == null) return '';

    if (rawData is String) {
      final trimmed = rawData.trim();
      if ((trimmed.startsWith('[') && trimmed.endsWith(']')) || (trimmed.startsWith('{') && trimmed.endsWith('}'))) {
        try {
          final decoded = jsonDecode(trimmed);
          if (decoded is List) {
            final events = decoded.map((item) {
              if (item is Map) return SduiTimelineEvent.fromMap(item);
              return SduiTimelineEvent(title: '', desc: '', date: '');
            }).toList();
            return _formatEventsToText(events);
          }
        } catch (_) {
          // Fallback to raw string if parsing fails
        }
      }
      return rawData;
    }

    if (rawData is List) {
      final events = rawData.map((item) {
        if (item is Map) return SduiTimelineEvent.fromMap(item);
        return SduiTimelineEvent(title: '', desc: '', date: '');
      }).toList();
      return _formatEventsToText(events);
    }

    return '';
  }

  String _formatEventsToText(List<SduiTimelineEvent> events) {
    return events.map((event) {
      final buffer = StringBuffer();
      if (event.date.isNotEmpty) {
        buffer.write('${event.date} - ');
      }
      buffer.write(event.title);
      if (event.desc.isNotEmpty) {
        buffer.write(': ${event.desc}');
      }
      return buffer.toString();
    }).join('\n');
  }

  void _parseData() {
    final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];
    final rawData = (vaultValue is String && vaultValue.isNotEmpty) ? vaultValue : widget.node.contentVal<dynamic>(HbpContent.DATA);

    if (rawData == _rawLastData) return;
    _rawLastData = rawData;

    if (rawData == null) {
      _events = [];
      return;
    }

    try {
      List<dynamic> list;
      if (rawData is String) {
        try {
          list = jsonDecode(rawData) as List<dynamic>;
          _events = list.map((item) {
            if (item is Map) {
              return SduiTimelineEvent.fromMap(item);
            }
            return SduiTimelineEvent(title: '', desc: '', date: '');
          }).toList();
          return;
        } catch (_) {
          _parseFromTextLines(rawData);
          return;
        }
      } else if (rawData is List) {
        list = rawData;
        _events = list.map((item) {
          if (item is Map) {
            return SduiTimelineEvent.fromMap(item);
          }
          return SduiTimelineEvent(title: '', desc: '', date: '');
        }).toList();
      } else {
        _events = [];
      }
    } catch (e) {
      _events = [];
    }
  }

  void _parseFromTextLines(String text) {
    final lines = text.split('\n');
    final List<SduiTimelineEvent> parsedEvents = [];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      String date = '';
      String title = line;
      String desc = '';

      // Match: "09:00 - Title: Description" or "09:00 — Title" or "09:00 | Title | Description"
      final RegExp separatorRegex = RegExp(r'\s*([—\-\|])\s*');
      final match = separatorRegex.firstMatch(line);
      if (match != null) {
        date = line.substring(0, match.start).trim();
        final rest = line.substring(match.end).trim();
        
        final descIndex = rest.indexOf(RegExp(r'[:|]'));
        if (descIndex != -1) {
          title = rest.substring(0, descIndex).trim();
          desc = rest.substring(descIndex + 1).trim();
        } else {
          title = rest;
        }
      } else {
        final descIndex = line.indexOf(RegExp(r'[:|]'));
        if (descIndex != -1) {
          title = line.substring(0, descIndex).trim();
          desc = line.substring(descIndex + 1).trim();
        }
      }

      parsedEvents.add(SduiTimelineEvent(
        title: title,
        desc: desc,
        date: date,
      ));
    }

    _events = parsedEvents;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;

    // Retrieve behaviors
    final double? width = node.behavior<double>(HbpBehavior.WIDTH) ?? node.behavior<int>(HbpBehavior.WIDTH)?.toDouble();
    final double? height = node.behavior<double>(HbpBehavior.HEIGHT) ?? node.behavior<int>(HbpBehavior.HEIGHT)?.toDouble();
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 12.0;

    // scroll_direction: 0=vertical (default), 1=horizontal
    final int scrollDirection = node.behavior<int>(HbpBehavior.SCROLL_DIRECTION) ?? 0;
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final Color accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    final String? title = node.contentVal<String>(HbpContent.LABEL);

    // Watch vault state to trigger rebuilds on typing pauses
    ref.watch(sduiStateVaultProvider.select((s) => s[bindKey]));
    _parseData();

    Widget timelineWidget;
    if (_events.isEmpty) {
      timelineWidget = _buildEmptyState(colorScheme, theme);
    } else if (scrollDirection == 1) {
      timelineWidget = _buildHorizontalTimeline(accentColor, colorScheme, theme, borderRadiusVal);
    } else {
      timelineWidget = _buildVerticalTimeline(accentColor, colorScheme, theme, borderRadiusVal);
    }

    if (interactiveMode == 1 && _isEditing) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusVal),
          side: BorderSide(color: colorScheme.outline.withAlpha(60), width: 1.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.route_outlined, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Timeline Events Editor',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        _parseData();
                      });
                    },
                    tooltip: 'Done Editing',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _dataController,
                maxLines: 6,
                keyboardType: TextInputType.multiline,
                style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Timeline Events (JSON or Plain Text)',
                  border: OutlineInputBorder(),
                  helperText: 'JSON or Text: "12:30 - Task Title: Detail desc"',
                ),
                onChanged: (val) {
                  widget.dispatcher.onStateChange(bindKey, val);
                },
              ),
            ],
          ),
        ),
      );
    }

    Widget contentCard = Container(
      width: width ?? double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        border: Border.all(
          color: colorScheme.outline.withAlpha(50),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title.isNotEmpty) ...[
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
          ],
          timelineWidget,
        ],
      ),
    );

    if (interactiveMode == 1) {
      return Stack(
        children: [
          contentCard,
          Positioned(
            top: 10,
            right: 10,
            child: CircleAvatar(
              radius: 14,
              backgroundColor: colorScheme.primary.withAlpha(30),
              child: IconButton(
                icon: Icon(Icons.edit_outlined, size: 14, color: colorScheme.primary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _isEditing = true),
                tooltip: 'Edit Timeline Events',
              ),
            ),
          ),
        ],
      );
    }

    return RepaintBoundary(child: contentCard);
  }

  Widget _buildVerticalTimeline(
    Color accentColor,
    ColorScheme colorScheme,
    ThemeData theme,
    double borderRadiusVal,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_events.length, (index) {
        final event = _events[index];
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 75,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(top: 14.0),
                child: Text(
                  event.date,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(
                width: 40,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    CustomPaint(
                      size: Size.infinite,
                      painter: TimelineTrackPainter(
                        color: colorScheme.outlineVariant,
                        isFirst: index == 0,
                        isLast: index == _events.length - 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: _buildNodeIcon(event, accentColor, colorScheme),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(borderRadiusVal),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (event.desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.desc,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildHorizontalTimeline(
    Color accentColor,
    ColorScheme colorScheme,
    ThemeData theme,
    double borderRadiusVal,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(_events.length, (index) {
          final event = _events[index];
          return SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: const Size(180, 40),
                        painter: TimelineHorizontalTrackPainter(
                          color: colorScheme.outlineVariant,
                          isFirst: index == 0,
                          isLast: index == _events.length - 1,
                        ),
                      ),
                      _buildNodeIcon(event, accentColor, colorScheme),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(borderRadiusVal),
                      border: Border.all(
                        color: colorScheme.outline.withAlpha(40),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          event.date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (event.desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            event.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNodeIcon(SduiTimelineEvent event, Color accentColor, ColorScheme colorScheme) {
    if (event.icon != null && event.icon!.isNotEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(color: accentColor, width: 2),
        ),
        child: Center(
          child: Icon(
            SduiIconRegistry.resolve(event.icon),
            size: 16,
            color: accentColor,
          ),
        ),
      );
    } else {
      return Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
        ),
      );
    }
  }

  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.route_outlined,
            color: colorScheme.onSurfaceVariant.withAlpha(128),
            size: 36,
          ),
          const SizedBox(height: 6),
          Text(
            'No Events Registered',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ],
      ),
    );
  }
}

class SduiTimelineEvent {
  final String title;
  final String desc;
  final String date;
  final String? icon;

  SduiTimelineEvent({
    required this.title,
    required this.desc,
    required this.date,
    this.icon,
  });

  factory SduiTimelineEvent.fromMap(Map<dynamic, dynamic> map) {
    return SduiTimelineEvent(
      title: map['title']?.toString() ?? '',
      desc: map['desc']?.toString() ?? map['description']?.toString() ?? '',
      date: map['date']?.toString() ?? map['time']?.toString() ?? '',
      icon: map['icon']?.toString(),
    );
  }
}

class TimelineTrackPainter extends CustomPainter {
  final Color color;
  final bool isFirst;
  final bool isLast;

  TimelineTrackPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double startY = isFirst ? 24.0 : 0.0;
    final double endY = isLast ? 24.0 : size.height;

    canvas.drawLine(
      Offset(size.width / 2, startY),
      Offset(size.width / 2, endY),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TimelineTrackPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast;
  }
}

class TimelineHorizontalTrackPainter extends CustomPainter {
  final Color color;
  final bool isFirst;
  final bool isLast;

  TimelineHorizontalTrackPainter({
    required this.color,
    required this.isFirst,
    required this.isLast,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final double startX = isFirst ? size.width / 2 : 0.0;
    final double endX = isLast ? size.width / 2 : size.width;

    canvas.drawLine(
      Offset(startX, size.height / 2),
      Offset(endX, size.height / 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant TimelineHorizontalTrackPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.isFirst != isFirst ||
        oldDelegate.isLast != isLast;
  }
}
