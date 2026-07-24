import 'package:flutter/material.dart';
import 'package:client_flutter/core/network/hbp_constants.g.dart';

class SduiStyleResolver {
  /// Resolves an integer color token to a ColorScheme value, or an ARGB hex value.
  static Color? resolveColor(BuildContext context, int? token) {
    if (token == null) return null;
    
    if (token >= 0xFF000000) return Color(token); // Direct ARGB override
    
    return resolveHbpColorToken(context, token);
  }

  /// Parses edge insets from a single number, [h,v], or [top, right, bottom, left] lists.
  static EdgeInsetsGeometry? resolveEdgeInsets(dynamic val) {
    if (val == null) return null;
    if (val is num) return EdgeInsets.all(val.toDouble());
    if (val is List) {
      if (val.length == 2) {
        return EdgeInsets.symmetric(horizontal: val[0].toDouble(), vertical: val[1].toDouble());
      }
      if (val.length == 4) {
        return EdgeInsets.fromLTRB(val[3].toDouble(), val[0].toDouble(), val[1].toDouble(), val[2].toDouble());
      }
    }
    return null;
  }

  /// Resolves an integer text style slot to the corresponding Theme slot.
  static TextStyle? resolveTextStyle(BuildContext context, int? slot) {
    if (slot == null) return null;
    final tt = Theme.of(context).textTheme;
    return switch (slot) {
      0 => tt.displayLarge,
      1 => tt.displayMedium,
      2 => tt.displaySmall,
      3 => tt.headlineLarge,
      4 => tt.headlineMedium,
      5 => tt.headlineSmall,
      6 => tt.titleLarge,
      7 => tt.titleMedium,
      8 => tt.titleSmall,
      9 => tt.bodyLarge,
      10 => tt.bodyMedium,
      11 => tt.bodySmall,
      12 => tt.labelLarge,
      13 => tt.labelMedium,
      14 => tt.labelSmall,
      _ => tt.bodyMedium,
    };
  }
}
