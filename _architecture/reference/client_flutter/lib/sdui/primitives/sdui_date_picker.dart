import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiDatePicker extends ConsumerWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiDatePicker({
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

    final String label = node.contentVal<String>(HbpContent.LABEL) ?? 'Select Date';
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

    final String startDateStr = vaultStart ?? vaultLegacy ?? node.contentVal<String>(HbpContent.VALUE) ?? '';
    final String endDateStr = vaultEnd ?? node.contentVal<String>(HbpContent.DATA) ?? '';
    final bool hasValue = startDateStr.isNotEmpty;
    final bool isInteractive = interactiveMode == 1;

    // 3. Premium styling definitions
    final Color bgColor = isInteractive
        ? colorScheme.surfaceContainerLow
        : colorScheme.surface;

    final Color borderColor = isInteractive
        ? (hasValue 
            ? accentColor.withValues(alpha: 0.3) 
            : colorScheme.outlineVariant.withValues(alpha: 0.5))
        : colorScheme.outlineVariant.withValues(alpha: 0.2);

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

    Widget buildDateDisplay(String dateStr, String emptyPlaceholder) {
      final bool active = dateStr.isNotEmpty;
      final DateTime? date = DateTime.tryParse(dateStr);
      final String text = active && date != null ? _formatDate(date) : emptyPlaceholder;
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
      contentWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: isInteractive
                ? () => _triggerPicker(context, ref, startDateStr, endDateStr, pickerMode, true, label, accentColor)
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
                        buildDateDisplay(startDateStr, placeholder),
                      ],
                    ),
                  ),
                  if (isInteractive)
                    Icon(Icons.edit_outlined, color: accentColor, size: 20.0),
                ],
              ),
            ),
          ),
          Divider(
            height: 1.0,
            thickness: 1.0,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            indent: 20.0,
            endIndent: 20.0,
          ),
          InkWell(
            onTap: isInteractive
                ? () => _triggerPicker(context, ref, startDateStr, endDateStr, pickerMode, false, label, accentColor)
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
                        buildDateDisplay(endDateStr, placeholder),
                      ],
                    ),
                  ),
                  if (isInteractive)
                    Icon(Icons.edit_outlined, color: accentColor, size: 20.0),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      contentWidget = InkWell(
        onTap: isInteractive
            ? () => _triggerPicker(context, ref, startDateStr, endDateStr, pickerMode, true, label, accentColor)
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
                    buildDateDisplay(startDateStr, placeholder),
                  ],
                ),
              ),
              const SizedBox(width: 12.0),
              if (isInteractive)
                Icon(Icons.edit_outlined, color: accentColor, size: 20.0),
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

  Future<void> _triggerPicker(
    BuildContext context,
    WidgetRef ref,
    String startStr,
    String endStr,
    int mode,
    bool isStart,
    String label,
    Color accentColor,
  ) async {
    DateTime initialStart = DateTime.tryParse(startStr) ?? DateTime.now();
    DateTime initialEnd = DateTime.tryParse(endStr) ?? DateTime.now().add(const Duration(days: 7));

    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime(2100);

    DateTime initialDate = isStart ? initialStart : initialEnd;

    if (mode == 1) {
      if (isStart) {
        lastDate = DateTime.tryParse(endStr) ?? DateTime(2100);
        if (initialDate.isAfter(lastDate)) initialDate = lastDate;
      } else {
        firstDate = DateTime.tryParse(startStr) ?? DateTime(1900);
        if (initialDate.isBefore(firstDate)) initialDate = firstDate;
      }
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      initialEntryMode: DatePickerEntryMode.calendar,
      helpText: mode == 1 ? '${label.toUpperCase()} (${isStart ? "START" : "END"})' : label.toUpperCase(),
      fieldLabelText: label,
      fieldHintText: 'YYYY-MM-DD',
      builder: (context, child) => _buildThemeData(context, child, accentColor),
    );

    if (picked != null) {
      final formatted = "${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      
      final vault = ref.read(sduiStateVaultProvider.notifier);
      
      if (mode == 0) {
        vault.set('${node.id}_start', formatted);
        vault.set(node.id, formatted);
        dispatcher.onStateChange(node.id, formatted);
      } else {
        if (isStart) {
          vault.set('${node.id}_start', formatted);
          dispatcher.onStateChange(node.id, {'start': formatted, 'end': endStr});
        } else {
          vault.set('${node.id}_end', formatted);
          dispatcher.onStateChange(node.id, {'start': startStr, 'end': formatted});
        }
      }
    }
  }

  Widget _buildThemeData(BuildContext context, Widget? child, Color accentColor) {
    final colorScheme = Theme.of(context).colorScheme;
    final mediaQuery = MediaQuery.of(context);
    
    return MediaQuery(
      data: mediaQuery.copyWith(
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
          datePickerTheme: DatePickerThemeData(
            backgroundColor: colorScheme.surfaceContainerHigh,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0),
            ),
            headerBackgroundColor: accentColor,
            headerForegroundColor: colorScheme.onPrimary,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return colorScheme.onSurface.withValues(alpha: 0.2);
              }
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onPrimary;
              }
              return colorScheme.onSurface;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return accentColor;
              }
              return null;
            }),
            todayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return colorScheme.onPrimary;
              }
              return accentColor;
            }),
          ),
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


  String _formatDate(DateTime date) {
    const List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return "${months[date.month - 1]} ${date.day}, ${date.year}";
  }
}
