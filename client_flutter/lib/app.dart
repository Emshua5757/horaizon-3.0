import 'package:flutter/material.dart';

/// Root application widget.
/// GoRouter and theme are wired up in TASK-010.
class HoraizonApp extends StatelessWidget {
  const HoraizonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'horAIzon 3.0',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text(
            'horAIzon 3.0',
            style: TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
