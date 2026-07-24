import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/core/sdui_renderer.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/sdui/registry/sdui_icon_registry.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiExpansionTile extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiExpansionTile({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiExpansionTile> createState() => _SduiExpansionTileState();
}

class _SduiExpansionTileState extends ConsumerState<SduiExpansionTile> {
  bool _isEditing = false;
  late TextEditingController _titleController;
  late TextEditingController _bodyController;
  late TextEditingController _iconController;

  @override
  void initState() {
    super.initState();
    final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
    final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];

    String title = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Accordion Section';
    String body = widget.node.contentVal<String>(HbpContent.VALUE) ?? '';
    String iconName = widget.node.contentVal<String>(HbpContent.ICON_NAME) ?? '';

    if (vaultValue is String && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        title = parsed['title']?.toString() ?? title;
        body = parsed['body']?.toString() ?? body;
        iconName = parsed['icon']?.toString() ?? iconName;
      } catch (e) {
        // Ignore fallback
      }
    }

    _titleController = TextEditingController(text: title);
    _bodyController = TextEditingController(text: body);
    _iconController = TextEditingController(text: iconName);
  }

  @override
  void didUpdateWidget(covariant SduiExpansionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.node.id != oldWidget.node.id) {
      final String bindKey = widget.node.behavior<String>(HbpBehavior.BIND_KEY) ?? widget.node.id;
      final vaultValue = ref.read(sduiStateVaultProvider)[bindKey];

      String title = widget.node.contentVal<String>(HbpContent.LABEL) ?? 'Accordion Section';
      String body = widget.node.contentVal<String>(HbpContent.VALUE) ?? '';
      String iconName = widget.node.contentVal<String>(HbpContent.ICON_NAME) ?? '';

      if (vaultValue is String && vaultValue.isNotEmpty) {
        try {
          final Map<String, dynamic> parsed = jsonDecode(vaultValue);
          title = parsed['title']?.toString() ?? title;
          body = parsed['body']?.toString() ?? body;
          iconName = parsed['icon']?.toString() ?? iconName;
        } catch (e) {
          // Ignore
        }
      }

      _titleController.text = title;
      _bodyController.text = body;
      _iconController.text = iconName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final node = widget.node;

    // 1. Retrieve Behaviors
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 0;
    final String bindKey = node.behavior<String>(HbpBehavior.BIND_KEY) ?? node.id;
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final double baseBorderRadius = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ?? 
                                   node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ?? 8.0;

    final accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // 2. Retrieve Content / Vault
    final String? nodeLabel = node.contentVal<String>(HbpContent.LABEL);
    final String? nodeBody = node.contentVal<String>(HbpContent.VALUE);
    final String? nodeIcon = node.contentVal<String>(HbpContent.ICON_NAME);

    final String? vaultValue = ref.watch(
      sduiStateVaultProvider.select((state) => state[bindKey] as String?),
    );

    String title = nodeLabel ?? 'Accordion Section';
    String body = nodeBody ?? '';
    String activeIconName = nodeIcon ?? '';
    double borderRadiusVal = baseBorderRadius;
    bool isExpanded = false;

    if (vaultValue != null && vaultValue.isNotEmpty) {
      try {
        final Map<String, dynamic> parsed = jsonDecode(vaultValue);
        title = parsed['title']?.toString() ?? title;
        body = parsed['body']?.toString() ?? body;
        activeIconName = parsed['icon']?.toString() ?? activeIconName;
        borderRadiusVal = (parsed['radius'] as num?)?.toDouble() ?? borderRadiusVal;
        isExpanded = parsed['expanded'] == true;
      } catch (e) {
        if (vaultValue == 'true' || vaultValue == 'false') {
          isExpanded = vaultValue == 'true';
        } else {
          body = vaultValue;
        }
      }
    }

    // Leading icon resolution
    Widget? leadingIcon;
    if (activeIconName.isNotEmpty) {
      final iconData = SduiIconRegistry.resolve(activeIconName);
      leadingIcon = Icon(iconData, color: accentColor);
    }

    // Children node recursive building
    final childrenNodes = node.children ?? [];
    List<Widget> childWidgets = childrenNodes.map((childNode) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: SduiRenderer(node: childNode, dispatcher: widget.dispatcher),
      );
    }).toList();

    // Fallback: render body Markdown if children nodes are empty
    if (childWidgets.isEmpty) {
      childWidgets = [
        Align(
          alignment: Alignment.topLeft,
          child: body.isNotEmpty
              ? MarkdownBody(
                  data: body,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Text(
                  'Empty section content',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant.withAlpha(128),
                  ),
                ),
        ),
      ];
    }

    void updateState({
      String? t,
      String? b,
      String? i,
      double? r,
      bool? exp,
    }) {
      final String finalTitle = t ?? title;
      final String finalBody = b ?? body;
      final String finalIcon = i ?? activeIconName;
      final double finalRadius = r ?? borderRadiusVal;
      final bool finalExp = exp ?? isExpanded;

      final payload = jsonEncode({
        'title': finalTitle,
        'body': finalBody,
        'icon': finalIcon,
        'radius': finalRadius,
        'expanded': finalExp,
      });

      ref.read(sduiStateVaultProvider.notifier).set(bindKey, payload);
      widget.dispatcher.onStateChange(bindKey, payload);
    }

    Widget buildTile() {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 0.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusVal),
          side: BorderSide(color: colorScheme.outline.withAlpha(40), width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        color: colorScheme.surfaceContainerLow,
        child: ExpansionTile(
          key: PageStorageKey('${node.id}_expansion'),
          initiallyExpanded: isExpanded,
          leading: leadingIcon,
          title: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          iconColor: accentColor,
          collapsedIconColor: colorScheme.onSurfaceVariant,
          textColor: accentColor,
          collapsedTextColor: colorScheme.onSurface,
          childrenPadding: const EdgeInsets.all(12.0),
          backgroundColor: colorScheme.surfaceContainerLowest,
          collapsedBackgroundColor: Colors.transparent,
          shape: const Border(),
          collapsedShape: const Border(),
          onExpansionChanged: (expanded) {
            updateState(exp: expanded);
          },
          children: childWidgets,
        ),
      );
    }

    if (interactiveMode == 1) {
      if (_isEditing) {
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusVal),
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
                        Icon(Icons.unfold_more_rounded, color: colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Accordion Sandbox (Editing)',
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
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Header Title / Label',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    updateState(t: val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    labelText: 'Section Body Content (Markdown supported)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (val) {
                    updateState(b: val);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _iconController,
                        decoration: const InputDecoration(
                          labelText: 'Icon Name (e.g. settings)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (val) {
                          updateState(i: val);
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Border Radius: ${borderRadiusVal.toStringAsFixed(0)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          Slider(
                            value: borderRadiusVal,
                            min: 0.0,
                            max: 24.0,
                            onChanged: (val) {
                              updateState(r: val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      } else {
        return Stack(
          children: [
            buildTile(),
            Positioned(
              top: 6,
              right: 42,
              child: CircleAvatar(
                radius: 12,
                backgroundColor: colorScheme.primary,
                child: IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                  padding: EdgeInsets.zero,
                  onPressed: () => setState(() => _isEditing = true),
                  tooltip: 'Edit Accordion Params',
                ),
              ),
            ),
          ],
        );
      }
    }

    return buildTile();
  }
}
