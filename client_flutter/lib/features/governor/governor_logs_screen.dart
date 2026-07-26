import 'package:flutter/material.dart';
import '../terminal/terminal_screen.dart';

/// GovernorLogsScreen — redirects to the primary TerminalScreen where all system telemetry logs stream.
class GovernorLogsScreen extends StatelessWidget {
  const GovernorLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const TerminalScreen();
  }
}
