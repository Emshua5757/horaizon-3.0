import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/app/theme/theme_provider.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';
import 'package:client_flutter/core/logging/governor_logger.dart';

class SduiHeatmap extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiHeatmap({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? currentValue = ref.watch(
      sduiStateVaultProvider.select((state) => state[node.id] as String?),
    ) ?? node.contentVal<String>(0);
    final String? label = node.contentVal<String>(1);

    // 2. Read layout configurations
    final int columns = _int(130) ?? 7;
    final int? rawRows = _int(131);
    final double cellAspectRatio = _num(133) ?? 1.0;
    final int showHeaders = _int(134) ?? 0; // 0=none, 1=col, 2=row, 3=both
    final int interactiveMode = _int(95) ?? 1; // 0=readonly, 1=editable

    final Color? accentColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(96));
    final Color? textColor = SduiStyleResolver.resolveColor(context, node.behavior<int>(97));

    // 3. Read data
    final rawData = node.contentVal<String>(6) ?? "[]";
    List<dynamic> cells = [];
    try {
      cells = jsonDecode(rawData) as List<dynamic>;
    } catch (e) {
      gLog.log(HbpLogLevel.ERROR, 'sdui_heatmap', 'Failed to parse cells data JSON: $e', tags: HbpLogTag.SDUI);
    }

    if (cells.isEmpty) {
      return const SizedBox.shrink();
    }

    final int computedRows = rawRows ?? (cells.length / columns).ceil();

    // Parse headers if present
    List<String> colLabels = [];
    List<String> rowLabels = [];
    final customEmojisRaw = node.contentVal<String>(7);
    if (customEmojisRaw != null) {
      try {
        final Map<String, dynamic> headersMap = jsonDecode(customEmojisRaw) as Map<String, dynamic>;
        if (headersMap['cols'] != null) {
          colLabels = List<String>.from(headersMap['cols'] as List);
        }
        if (headersMap['rows'] != null) {
          rowLabels = List<String>.from(headersMap['rows'] as List);
        }
      } catch (e) {
        gLog.log(HbpLogLevel.ERROR, 'sdui_heatmap', 'Failed to parse custom_emojis headers: $e', tags: HbpLogTag.SDUI);
      }
    }

    final themeState = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final Color primaryColor = accentColor ?? theme.colorScheme.primary;
    final Color negativeColor = themeState.secondary ?? theme.colorScheme.error;
    final Color emptyColor = theme.colorScheme.surfaceContainerHighest;

    // Check if double-sided (contains negative intensity values)
    bool isDoubleSided = false;
    for (var cell in cells) {
      if (cell is Map && cell['val'] != null) {
        final double val = (cell['val'] as num).toDouble();
        if (val < 0.0) {
          isDoubleSided = true;
          break;
        }
      }
    }

    // Builder for headers spacer column
    Widget buildRowHeaderSpacer() {
      return Container(
        width: 32,
        alignment: Alignment.center,
        child: const SizedBox.shrink(),
      );
    }

    // Grid cells layout list
    List<Widget> gridRows = [];

    // Title label if provided
    if (label != null && label.isNotEmpty) {
      gridRows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              color: textColor ?? theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Column Headers row
    final bool hasColHeaders = (showHeaders == 1 || showHeaders == 3) && colLabels.isNotEmpty;
    final bool hasRowHeaders = (showHeaders == 2 || showHeaders == 3) && rowLabels.isNotEmpty;

    if (hasColHeaders) {
      List<Widget> headerItems = [];
      if (hasRowHeaders) {
        headerItems.add(buildRowHeaderSpacer());
      }
      for (int c = 0; c < columns; c++) {
        final text = (c < colLabels.length) ? colLabels[c] : "";
        headerItems.add(
          Expanded(
            child: AspectRatio(
              aspectRatio: cellAspectRatio,
              child: Center(
                child: Text(
                  text,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textColor?.withValues(alpha: 0.6) ?? theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ),
        );
      }
      gridRows.add(Row(children: headerItems));
    }

    // Grid rows assembly
    for (int r = 0; r < computedRows; r++) {
      List<Widget> rowItems = [];

      // Row Header
      if (hasRowHeaders) {
        final text = (r < rowLabels.length) ? rowLabels[r] : "";
        rowItems.add(
          Container(
            width: 32,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 6.0),
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor?.withValues(alpha: 0.6) ?? theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      // Row cells
      for (int c = 0; c < columns; c++) {
        final index = r * columns + c;
        if (index >= cells.length) {
          rowItems.add(Expanded(child: const SizedBox.shrink()));
          continue;
        }

        final cell = cells[index];
        if (cell == null || cell is! Map) {
          rowItems.add(Expanded(child: const SizedBox.shrink()));
          continue;
        }

        final String? cellKey = cell['key'] as String?;
        final double? intensity = cell['val'] != null ? (cell['val'] as num).toDouble() : null;
        final String? cellLabel = cell['lbl']?.toString();

        // Determine cell background color
        Color color = Colors.transparent;
        final bool isRealDay = cellKey != null && cellLabel != null && cellLabel.isNotEmpty;
        
        if (isRealDay) {
          if (intensity != null) {
            if (isDoubleSided) {
              if (intensity > 0.0) {
                color = Color.lerp(emptyColor, primaryColor, intensity.clamp(0.0, 1.0))!;
              } else if (intensity < 0.0) {
                color = Color.lerp(emptyColor, negativeColor, intensity.abs().clamp(0.0, 1.0))!;
              } else {
                color = emptyColor;
              }
            } else {
              // Single-sided intensity (0.0 to 1.0)
              if (intensity > 0.0) {
                color = Color.lerp(emptyColor, primaryColor, intensity.clamp(0.0, 1.0))!;
              } else {
                color = emptyColor;
              }
            }
          } else {
            // Real day of month but no entry/intensity logged yet
            color = emptyColor.withValues(alpha: 0.2);
          }
        }

        final bool isSelected = cellKey != null && cellKey == currentValue;

        Widget cellBox = Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6.0),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2.0)
                : isRealDay
                    ? Border.all(color: theme.colorScheme.onSurface.withValues(alpha: 0.05), width: 1.0)
                    : Border.all(color: Colors.transparent, width: 1.0),
          ),
          child: cellLabel != null && cellLabel.isNotEmpty
              ? Center(
                  child: Text(
                    cellLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: intensity != null
                          ? (intensity.abs() > 0.6 ? Colors.white : (textColor ?? theme.colorScheme.onSurface))
                          : (textColor?.withValues(alpha: 0.7) ?? theme.colorScheme.onSurfaceVariant),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        );

        if (interactiveMode == 1 && cellKey != null) {
          cellBox = InkWell(
            onTap: () {
              dispatcher.onStateChange(node.id, cellKey);
              final actionPayload = node.behavior<Map<int, dynamic>>(70);
              if (actionPayload != null) {
                dispatcher.onAction(actionPayload);
              }
            },
            borderRadius: BorderRadius.circular(6.0),
            child: cellBox,
          );
        }

        rowItems.add(
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: AspectRatio(
                aspectRatio: cellAspectRatio,
                child: cellBox,
              ),
            ),
          ),
        );
      }

      gridRows.add(Row(children: rowItems));
    }

    Widget result = Padding(
      padding: SduiStyleResolver.resolveEdgeInsets(node.behavior(30)) ?? const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: gridRows,
      ),
    );

    final double? width = _resolveSize(node.behavior(32));
    final double? height = _resolveSize(node.behavior(33));
    final double? minWidth = _resolveSize(node.behavior(34));
    final double maxWidth = _resolveSize(node.behavior(35)) ?? 460.0;
    final double? minHeight = _resolveSize(node.behavior(36));
    final double? maxHeight = _resolveSize(node.behavior(37));

    if (width != null || height != null) {
      result = SizedBox(
        width: width,
        height: height,
        child: result,
      );
    }

    result = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: minWidth ?? 0.0,
          maxWidth: maxWidth,
          minHeight: minHeight ?? 0.0,
          maxHeight: maxHeight ?? double.infinity,
        ),
        child: result,
      ),
    );

    return result;
  }

  static double? _resolveSize(dynamic raw) {
    if (raw == null) return null;
    if (raw == 'infinity' || raw == double.infinity) return double.infinity;
    if (raw is num) return raw.toDouble();
    return null;
  }

  int? _int(int key) {
    final raw = node.behavior(key);
    if (raw is num) return raw.toInt();
    return null;
  }

  double? _num(int key) {
    final raw = node.behavior(key);
    if (raw is num) return raw.toDouble();
    return null;
  }
}
