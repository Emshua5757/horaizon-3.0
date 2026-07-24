import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiWrap extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiWrap({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiWrap> createState() => _SduiWrapState();
}

class _SduiWrapState extends ConsumerState<SduiWrap> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Retrieve Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    
    final double spacingVal = node.behavior<double>(HbpBehavior.MAIN_AXIS_SPACING) ?? 
                              node.behavior<int>(HbpBehavior.MAIN_AXIS_SPACING)?.toDouble() ?? 8.0;
    
    final double runSpacingVal = node.behavior<double>(HbpBehavior.CROSS_AXIS_SPACING) ?? 
                                 node.behavior<int>(HbpBehavior.CROSS_AXIS_SPACING)?.toDouble() ?? 8.0;

    // Children recursive rendering
    final childrenNodes = node.children ?? [];
    final childWidgets = childrenNodes.map((childNode) {
      return SduiRenderer(node: childNode, dispatcher: widget.dispatcher);
    }).toList();

    Widget buildWrapWidget() {
      return Wrap(
        spacing: spacingVal,
        runSpacing: runSpacingVal,
        alignment: WrapAlignment.start,
        crossAxisAlignment: WrapCrossAlignment.start,
        children: childWidgets,
      );
    }

    if (interactiveMode == 1) {
      if (_isEditing) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: BorderSide(color: colorScheme.outline.withAlpha(60), width: 1.0),
          ),
          color: colorScheme.surfaceContainer,
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
                        Icon(Icons.wrap_text_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Wrap Layout Sandbox (Editing)',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                      onPressed: () => setState(() => _isEditing = false),
                      tooltip: 'Done Editing',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Main-Axis Spacing: ${spacingVal.toStringAsFixed(0)}dp',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          Slider(
                            value: spacingVal,
                            min: 0.0,
                            max: 40.0,
                            onChanged: (val) {
                              setState(() {
                                widget.node.behaviors[HbpBehavior.MAIN_AXIS_SPACING] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cross-Axis Spacing: ${runSpacingVal.toStringAsFixed(0)}dp',
                            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          Slider(
                            value: runSpacingVal,
                            min: 0.0,
                            max: 40.0,
                            onChanged: (val) {
                              setState(() {
                                widget.node.behaviors[HbpBehavior.CROSS_AXIS_SPACING] = val;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Render content inline inside sandbox card so user can preview spacing adjustments live
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: buildWrapWidget(),
                ),
              ],
            ),
          ),
        );
      } else {
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 28.0),
              child: buildWrapWidget(),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Wrap Spacing',
                ),
              ),
            ),
          ],
        );
      }
    }

    return buildWrapWidget();
  }
}
