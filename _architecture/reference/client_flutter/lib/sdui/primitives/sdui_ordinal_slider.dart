import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/sdui/core/sdui_node.dart';
import 'package:client_flutter/sdui/core/sdui_state_vault.dart';
import 'package:client_flutter/sdui/events/sdui_event_dispatcher.dart';
import 'package:client_flutter/sdui/utils/sdui_style_resolver.dart';

class SduiOrdinalSlider extends ConsumerStatefulWidget {
  final SduiNode node;
  final SduiEventDispatcher dispatcher;

  const SduiOrdinalSlider({
    super.key,
    required this.node,
    required this.dispatcher,
  });

  @override
  ConsumerState<SduiOrdinalSlider> createState() => _SduiOrdinalSliderState();
}

class _SduiOrdinalSliderState extends ConsumerState<SduiOrdinalSlider> {
  int _hoveredIndex = -1;
  double _hoveredRating = -1.0;

  void _handleTap(int index, double tapX, double iconSize, bool halfStep, bool isReadOnly) {
    if (isReadOnly) return;

    double newRating;
    if (halfStep && tapX < iconSize / 2) {
      newRating = index + 0.5;
    } else {
      newRating = index + 1.0;
    }

    widget.dispatcher.onStateChange(widget.node.id, newRating);

    final actionPayload = widget.node.behavior<Map<int, dynamic>>(70);
    if (actionPayload != null) {
      widget.dispatcher.onAction(actionPayload);
    }
  }

  IconData _iconFor(String iconName, int index, double activeRating) {
    final double stepValue = index + 1.0;
    final bool isFull = activeRating >= stepValue;
    final bool isHalf = !isFull && activeRating >= index + 0.5;

    const Map<String, List<IconData>> iconVariants = {
      'star':  [Icons.star_rounded,       Icons.star_half_rounded,    Icons.star_border_rounded],
      'heart': [Icons.favorite_rounded,   Icons.favorite_rounded,     Icons.favorite_border_rounded],
      'thumb': [Icons.thumb_up_rounded,   Icons.thumb_up_rounded,     Icons.thumb_up_off_alt_rounded],
      'flame': [Icons.local_fire_department_rounded, Icons.local_fire_department_rounded, Icons.local_fire_department_outlined],
      'bolt':  [Icons.bolt_rounded,       Icons.bolt_rounded,         Icons.bolt_outlined],
      'mood':  [Icons.sentiment_very_satisfied_rounded, Icons.sentiment_satisfied_rounded, Icons.sentiment_neutral_rounded],
    };
    final List<IconData> variants = iconVariants[iconName] ?? iconVariants['star']!;
    
    if (isFull) return variants[0];
    if (isHalf) return variants[1];
    return variants[2];
  }

  String _labelFor(double rating, List<String>? customLabels) {
    final int r = rating.round();
    final int idx = r - 1;
    if (customLabels != null && idx >= 0 && idx < customLabels.length) {
      return customLabels[idx];
    }
    return switch (r) {
      1 => 'Terrible',
      2 => 'Bad',
      3 => 'Okay',
      4 => 'Good',
      5 => 'Excellent',
      _ => 'Rate',
    };
  }

  @override
  Widget build(BuildContext context) {
    // 1. Behaviors
    final int ordinalMode = widget.node.behavior<int>(119) ?? 0; // 0=star_rating, 1=segmented_picker
    final double maxVal = widget.node.behavior<double>(45) ?? 5.0;
    final int count = maxVal.round();
    final bool halfStep = widget.node.behavior<int>(120) == 1;
    final bool showLabel = widget.node.behavior<int>(121) == 1;
    final bool isReadOnly = widget.node.behavior<int>(95) == 0;
    
    final Color? accentColor = SduiStyleResolver.resolveColor(context, widget.node.behavior<int>(96));

    // 2. Content
    final String iconName = widget.node.contentVal<String>(3) ?? 'star';
    
    // Parse custom emojis (7) and custom labels (6)
    final rawEmojis = widget.node.contentVal<List<dynamic>>(7);
    final List<String>? customEmojis = rawEmojis?.map((e) => e.toString()).toList();
    
    final rawLabels = widget.node.contentVal<List<dynamic>>(6);
    final List<String>? customLabels = rawLabels?.map((e) => e.toString()).toList();

    // 3. State
    final rawVaultVal = ref.watch(
      sduiStateVaultProvider.select((state) => state[widget.node.id]),
    );
    double rating = widget.node.contentVal<double>(0) ?? 0.0;
    if (rawVaultVal is num) rating = rawVaultVal.toDouble();

    final theme = Theme.of(context);
    final activeRating = _hoveredRating >= 0.0 ? _hoveredRating : rating;
    const double iconSize = 32.0;

    final List<Widget> items = List.generate(count, (index) {
      final double stepValue = index + 1.0;
      
      bool isFilledOrHalf;
      if (ordinalMode == 1) {
        // Segmented Picker mode: mutually exclusive exact match
        isFilledOrHalf = activeRating.round() == stepValue.round();
      } else {
        // Star Rating mode: accumulative fill
        isFilledOrHalf = activeRating >= stepValue - 0.5;
      }

      Color baseActiveColor;
      if (accentColor != null) {
        baseActiveColor = accentColor;
      } else if (iconName == 'star') {
        baseActiveColor = Colors.amber.shade500;
      } else if (iconName == 'heart') {
        baseActiveColor = Colors.red.shade400;
      } else {
        baseActiveColor = theme.colorScheme.primary;
      }

      final Color iconColor = isFilledOrHalf 
          ? baseActiveColor 
          : theme.colorScheme.onSurfaceVariant.withAlpha(64); // ~0.25 opacity

      final bool useEmoji = customEmojis != null && index < customEmojis.length;

      Widget iconWidget;
      if (useEmoji) {
        iconWidget = AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFilledOrHalf 
                ? theme.colorScheme.primary.withAlpha(64)
                : Colors.transparent,
            shape: BoxShape.circle,
            boxShadow: isFilledOrHalf
                ? [
                    BoxShadow(
                      color: theme.colorScheme.primary.withAlpha(76),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ]
                : [],
          ),
          child: Text(
            customEmojis[index],
            style: const TextStyle(fontSize: 28),
          ),
        );
      } else {
        iconWidget = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Icon(
            _iconFor(iconName, index, activeRating),
            size: iconSize,
            color: iconColor,
          ),
        );
      }

      final Widget tapTarget = MouseRegion(
        onHover: isReadOnly
            ? null
            : (details) {
                final double tapX = details.localPosition.dx;
                final double hoverValue = (halfStep && tapX < iconSize / 2)
                    ? index + 0.5
                    : index + 1.0;
                if (_hoveredIndex != index || _hoveredRating != hoverValue) {
                  if (mounted) {
                    setState(() {
                      _hoveredIndex = index;
                      _hoveredRating = hoverValue;
                    });
                  }
                }
              },
        onExit: isReadOnly
            ? null
            : (_) {
                if (mounted) {
                  setState(() {
                    _hoveredIndex = -1;
                    _hoveredRating = -1.0;
                  });
                }
              },
        child: GestureDetector(
          onTapDown: isReadOnly ? null : (details) {
            _handleTap(index, details.localPosition.dx, iconSize, halfStep, isReadOnly);
          },
          child: iconWidget,
        ),
      );

      if (ordinalMode == 1 && showLabel) {
        // Mode 1: Segmented Picker Labeled Row
        final String labelStr = (customLabels != null && index < customLabels.length)
            ? customLabels[index]
            : _labelFor(index + 1.0, null);

        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tapTarget,
              const SizedBox(height: 8),
              Text(
                labelStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isFilledOrHalf ? FontWeight.bold : FontWeight.normal,
                  color: isFilledOrHalf 
                      ? theme.colorScheme.primary 
                      : theme.colorScheme.onSurfaceVariant.withAlpha(153), // 0.6 opacity
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }

      return tapTarget;
    });

    if (ordinalMode == 1) {
      // Segmented picker always spans
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items,
      );
    }

    if (!showLabel) {
      return Row(mainAxisSize: MainAxisSize.min, children: items);
    }

    // Label badge for star rating mode
    final bool hasRating = rating > 0.0;
    final String label = _labelFor(activeRating, customLabels);

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(mainAxisSize: MainAxisSize.min, children: items),
        const SizedBox(width: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: hasRating
                ? theme.colorScheme.primaryContainer.withAlpha(76)
                : theme.colorScheme.onSurfaceVariant.withAlpha(13),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontFamily: 'JetBrainsMono',
              color: hasRating
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant.withAlpha(128),
            ),
          ),
        ),
      ],
    );
  }
}
