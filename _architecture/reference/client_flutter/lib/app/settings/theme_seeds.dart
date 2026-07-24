import 'package:flutter/material.dart';

/// Represents a selectable color accent option within the system configuration.
class ThemeSeedOption {
  final Color color;
  final String label;

  const ThemeSeedOption({required this.color, required this.label});
}

/// Central repository for approved system seed color palettes.
class AppThemeSeeds {
  static const List<ThemeSeedOption> options = [
    ThemeSeedOption(color: Color(0xFF00E5FF), label: 'Cyber Blue'),
    ThemeSeedOption(color: Color(0xFFFF0055), label: 'Neon Pink'),
    ThemeSeedOption(color: Color(0xFF00FF88), label: 'Matrix Green'),
    ThemeSeedOption(color: Color(0xFFFFAA00), label: 'Amber Warning'),
    ThemeSeedOption(color: Color(0xFF8C00FF), label: 'Void Purple'),
    ThemeSeedOption(color: Color(0xFFFF3300), label: 'Core Red'),
    ThemeSeedOption(color: Color(0xFFCCFF00), label: 'Acid Yellow'),
    ThemeSeedOption(color: Color(0xFF00FFAA), label: 'Quantum Teal'),
    ThemeSeedOption(color: Color(0xFFFF00AA), label: 'Plasma Magenta'),
    ThemeSeedOption(color: Color(0xFF4D00FF), label: 'Hyper Indigo'),
  ];
}
