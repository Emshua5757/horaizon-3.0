import 'package:flutter/material.dart';

/// The global application theme enforcing the horAIzon 2.0 aesthetics.
/// 
/// Uses a deep premium dark background and HSL-based palettes to support
/// Server-Driven UI color overrides.
final ThemeData horAIzonTheme = ThemeData.dark().copyWith(
  scaffoldBackgroundColor: const Color(0xFF0D0D12),
  // Additional theme tokens will be added here as the SDUI engine expands
);
