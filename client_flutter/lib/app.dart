import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/theme_provider.dart';
import 'router/app_router.dart';

/// Root application widget.
/// Wires GoRouter, live theme hot-swapping, and text scale from ThemeNotifier.
class HoraizonApp extends ConsumerWidget {
  const HoraizonApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(themeState.textScale),
      ),
      child: MaterialApp.router(
        title: 'horAIzon 3.0',
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        theme: themeState.compiledData,
      ),
    );
  }
}
