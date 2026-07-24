import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme/theme_provider.dart';

/// Entry point of the horAIzon 2.0 client shell.
void main() {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    try {
      final file = File('sdui_crash.log');
      file.writeAsStringSync(
        '=== CRASH REPORT ===\n${details.exception}\n${details.stack}\n\n',
        mode: FileMode.append,
      );
    } catch (_) {}
  };

  runApp(const ProviderScope(child: HorAIzonClientShell()));
}

/// The root application shell.
///
/// Operates as a Server-Driven UI (SDUI) receiver. Uses [MaterialApp.router]
/// to delegate navigation state to [GoRouter], and listens to [ProviderScope]
/// for top-level dependency injection.
class HorAIzonClientShell extends ConsumerWidget {
  const HorAIzonClientShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the routerProvider to obtain the dynamically injected router instance
    final goRouter = ref.watch(routerProvider);
    final themeState = ref.watch(themeProvider);
    return MaterialApp.router(
      title: 'horAIzon 2.0',
      debugShowCheckedModeBanner: false,
      theme: themeState.compiledData,
      themeAnimationDuration: Duration(milliseconds: themeState.animationMs),
      themeAnimationCurve: Curves.easeInOutCubic,
      routerConfig: goRouter,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQueryData.copyWith(
            textScaler: TextScaler.linear(themeState.textScale),
          ),
          child: child!,
        );
      },
    );
  }
}
