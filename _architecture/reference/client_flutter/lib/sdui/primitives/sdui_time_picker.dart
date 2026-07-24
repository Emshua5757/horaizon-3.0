import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiTimePicker extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiTimePicker({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // 1. Decode Behaviors & Content
    final int interactiveMode = node.behavior<int>(HbpBehavior.INTERACTIVE_MODE) ?? 1;
    final int pickerMode = node.behavior<int>(HbpBehavior.PICKER_MODE) ?? 0; // 0 = single, 1 = range
    final double borderRadiusVal = node.behavior<double>(HbpBehavior.BORDER_RADIUS) ??
        node.behavior<int>(HbpBehavior.BORDER_RADIUS)?.toDouble() ??
        16.0;

    final String label = node.contentVal<String>(HbpContent.LABEL) ?? 'Select Time';
    final String placeholder = node.contentVal<String>(HbpContent.PLACEHOLDER) ?? 'Not set';

    // Accent Color token resolution
    final int? accentColorToken = node.behavior<int>(HbpBehavior.ACCENT_COLOR_TOKEN);
    final Color accentColor = SduiStyleResolver.resolveColor(context, accentColorToken) ?? colorScheme.primary;

    // 2. Resolve State from Vault safely to avoid _TypeError in selector evaluations
    final dynamic vaultStartVal = ref.watch(
      sduiStateVaultProvider.select((s) => s['${node.id}_start']),
    );
    final String? vaultStart = vaultStartVal is String ? vaultStartVal : null;

    final dynamic vaultEndVal = ref.watch(
      sduiStateVaultProvider.select((s) => s['${node.id}_end']),
    );
    final String? vaultEnd = vaultEndVal is String ? vaultEndVal : null;

    final dynamic vaultLegacyVal = ref.watch(
      sduiStateVaultProvider.select((s) => s[node.id]),
    );
    final String? vaultLegacy = vaultLegacyVal is String ? vaultLegacyVal : null;

    final String startTimeStr = vaultStart ?? vaultLegacy ?? node.contentVal<String>(HbpContent.VALUE) ?? '';
    final String endTimeStr = vaultEnd ?? node.contentVal<String>(HbpContent.DATA) ?? '';
    final bool hasValue = startTimeStr.isNotEmpty;
    final bool isInteractive = interactiveMode == 1;

    // 3. Theme-Based Design
    final Color bgColor = isInteractive
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;

    final Color borderColor = isInteractive
        ? (hasValue 
            ? accentColor.withValues(alpha: 0.3) 
            : colorScheme.outlineVariant.withValues(alpha: 0.5))
        : colorScheme.outlineVariant.withValues(alpha: 0.2);

    TimeOfDay parseTime(String t) {
      if (!t.contains(':')) return TimeOfDay.now();
      try {
        final parts = t.split(':');
        return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {
        return TimeOfDay.now();
      }
    }

    Widget buildHeader(String text) {
      return Text(
        text.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
    }

    Widget buildTimeDisplay(String timeStr, String emptyPlaceholder) {
      final bool active = timeStr.isNotEmpty;
      final String text = active ? parseTime(timeStr).format(context) : emptyPlaceholder;
      return Text(
        text,
        style: theme.textTheme.headlineSmall?.copyWith(
          color: active ? colorScheme.onSurface : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          fontWeight: active ? FontWeight.w800 : FontWeight.w500,
          letterSpacing: -0.5,
        ),
      );
    }

    Widget contentWidget;

    if (pickerMode == 1) {
      // PREMIUM RANGE TIME MODE: Vertical Stack layout (Prevents horizontal compression)
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Start Time area
          InkWell(
            onTap: isInteractive
                ? () => _pickTime(context, ref, startTimeStr, true, label, accentColor)
                : null,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadiusVal),
              topRight: Radius.circular(borderRadiusVal),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildHeader('$label (Start)'),
                        const SizedBox(height: 6.0),
                        buildTimeDisplay(startTimeStr, placeholder),
                      ],
                    ),
                  ),
                  if (isInteractive)
                    Icon(
                      Icons.edit_outlined,
                      color: accentColor,
                      size: 20.0,
                    ),
                ],
              ),
            ),
          ),

          // Divider separating Start and End times
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            indent: 20.0,
            endIndent: 20.0,
          ),

          // End Time area
          InkWell(
            onTap: isInteractive
                ? () => _pickTime(context, ref, endTimeStr, false, label, accentColor)
                : null,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(borderRadiusVal),
              bottomRight: Radius.circular(borderRadiusVal),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        buildHeader('$label (End)'),
                        const SizedBox(height: 6.0),
                        buildTimeDisplay(endTimeStr, placeholder),
                      ],
                    ),
                  ),
                  if (isInteractive)
                    Icon(
                      Icons.edit_outlined,
                      color: accentColor,
                      size: 20.0,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      // SINGLE TIME MODE (Stacked header/value vertically)
      contentWidget = InkWell(
        onTap: isInteractive
            ? () => _pickTime(context, ref, startTimeStr, true, label, accentColor)
            : null,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    buildHeader(label),
                    const SizedBox(height: 6.0),
                    buildTimeDisplay(startTimeStr, placeholder),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              if (isInteractive)
                Icon(
                  Icons.edit_outlined,
                  color: accentColor,
                  size: 20.0,
                ),
            ],
          ),
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadiusVal),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          if (isInteractive && hasValue)
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12.0,
              offset: const Offset(0, 3),
            )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: contentWidget,
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    String currentTimeStr,
    bool isStart,
    String label,
    Color accentColor,
  ) async {
    // Parse initial time
    TimeOfDay initialTime = TimeOfDay.now();
    if (currentTimeStr.contains(':')) {
      try {
        final parts = currentTimeStr.split(':');
        initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      } catch (_) {}
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      initialEntryMode: TimePickerEntryMode.dial,
      helpText: '${label.toUpperCase()} (${isStart ? "START" : "END"})\n(Auto-syncs if overlapping)',
      builder: (context, child) => _buildThemeData(context, child, accentColor),
    );

    if (picked != null) {
      final formatted = "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
      
      final vault = ref.read(sduiStateVaultProvider.notifier);
      final int pickerMode = node.behavior<int>(HbpBehavior.PICKER_MODE) ?? 0;
      
      if (pickerMode == 0) {
        vault.set('${node.id}_start', formatted);
        vault.set(node.id, formatted);
        dispatcher.onStateChange(node.id, formatted);
      } else {
        if (isStart) {
          final dynamic existingEndVal = ref.read(sduiStateVaultProvider)['${node.id}_end'];
          final String existingEnd = existingEndVal is String ? existingEndVal : '';
          
          // Auto-adjust constraint check
          String finalStart = formatted;
          String finalEnd = existingEnd;
          
          if (existingEnd.isNotEmpty) {
            final endParts = existingEnd.split(':');
            final endHour = int.parse(endParts[0]);
            final endMin = int.parse(endParts[1]);
            if (picked.hour > endHour || (picked.hour == endHour && picked.minute > endMin)) {
              finalEnd = formatted; // Adjust end time to match start time if start is later
              vault.set('${node.id}_end', finalEnd);
            }
          }
          
          vault.set('${node.id}_start', finalStart);
          dispatcher.onStateChange(node.id, {'start': finalStart, 'end': finalEnd});
        } else {
          final dynamic existingStartVal = ref.read(sduiStateVaultProvider)['${node.id}_start'];
          final String existingStart = existingStartVal is String ? existingStartVal : '';
          
          // Auto-adjust constraint check
          String finalStart = existingStart;
          String finalEnd = formatted;
          
          if (existingStart.isNotEmpty) {
            final startParts = existingStart.split(':');
            final startHour = int.parse(startParts[0]);
            final startMin = int.parse(startParts[1]);
            if (picked.hour < startHour || (picked.hour == startHour && picked.minute < startMin)) {
              finalStart = formatted; // Adjust start time to match end time if end is earlier
              vault.set('${node.id}_start', finalStart);
            }
          }
          
          vault.set('${node.id}_end', finalEnd);
          dispatcher.onStateChange(node.id, {'start': finalStart, 'end': finalEnd});
        }
      }
    }
  }

  Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);

    return MediaQuery(
      data: mediaQuery.copyWith(
        alwaysUse24HourFormat: false,
        size: Size(
          mediaQuery.size.width < mediaQuery.size.height 
              ? mediaQuery.size.width 
              : mediaQuery.size.height,
          mediaQuery.size.height > mediaQuery.size.width 
              ? mediaQuery.size.height 
              : mediaQuery.size.width,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: colorScheme.copyWith(
            primary: accentColor,
            onPrimary: colorScheme.onPrimary,
          ),
          timePickerTheme: TimePickerThemeData(
            backgroundColor: colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
            hourMinuteShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            dayPeriodShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            dialBackgroundColor: colorScheme.surfaceContainerLow,
            dialHandColor: accentColor,
            dialTextColor: colorScheme.onSurface,
            entryModeIconColor: accentColor,
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: colorScheme.surface,
              // REDUCED VERTICAL PADDING to prevent number vertical truncation in typing mode
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: accentColor, width: 2.0),
              ),
            ),
          ),
          dialogTheme: DialogThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
          ),
        ),
        child: child!,
      ),
    );
  }
}
