import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/chat/global_chat_screen.dart';
import '../features/terminal/terminal_screen.dart';
import '../features/governor/governor_status_screen.dart';
import '../features/governor/governor_ollama_screen.dart';
import '../features/diary/diary_screen.dart';
import 'splash_screen.dart';
import 'shell_scaffold.dart';

final routeObserverProvider = Provider((_) => RouteObserver<ModalRoute<void>>());

/// GoRouter configuration with splash route and ShellRoute for the main app.
final routerProvider = Provider<GoRouter>((ref) {
  final observer = ref.watch(routeObserverProvider);

  return GoRouter(
    initialLocation: '/',
    observers: [observer],
    routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/chat',
            builder: (_, __) => const GlobalChatScreen(),
          ),
          GoRoute(
            path: '/terminal',
            builder: (_, __) => const TerminalScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/governor/status',
            builder: (_, __) => const GovernorStatusScreen(),
          ),
          GoRoute(
            path: '/governor/ollama',
            builder: (_, __) => const GovernorOllamaScreen(),
          ),
          GoRoute(
            path: '/diary',
            builder: (_, __) => const DiaryScreen(),
          ),
        ],
      ),
    ],
  );
});
