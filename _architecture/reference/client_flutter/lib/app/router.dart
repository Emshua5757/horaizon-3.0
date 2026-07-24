import 'package:client_flutter/app/adaptive_shell.dart';
import 'package:client_flutter/app/route_history.dart';
import 'package:client_flutter/app/settings/settings_page.dart';
import 'package:client_flutter/sdui/core/sdui_screen.dart';
import 'package:client_flutter/sdui/sdui_sandbox_screen.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Exposes the GoRouter instance as a Riverpod provider.
///
/// Pure SDUI-4 Architecture: Flutter is a dumb renderer shell.
/// Every screen is just a screenId string resolved into an AST payload by the server.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final location = state.uri.toString();
      Future.microtask(() {
        ref.read(routeHistoryProvider).addRoute(location);
      });
      return null;
    },
    routes: [
      // ── Dev / Debug ───────────────────────────────────────────────────────
      GoRoute(
        path: '/sdui_sandbox',
        builder: (context, state) => const SduiSandboxScreen(),
      ),

      // ── App Shell (nav bar + adaptive layout) ────────────────────────────
      ShellRoute(
        builder: (context, state, child) => AdaptiveShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const SduiScreen(screenId: 'dashboard'),
          ),
          GoRoute(
            path: '/comms',
            builder: (context, state) => const SduiScreen(screenId: 'chat_playground'),
          ),
          GoRoute(
            path: '/diary',
            builder: (context, state) => const SduiScreen(screenId: 'diary_list'),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return SduiScreen(
                    screenId: 'diary_editor_$id',
                    suppressAppBar: true,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/console',
            builder: (context, state) => const SduiScreen(screenId: 'console'),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/resume',
            builder: (context, state) => const SduiScreen(screenId: 'resume_dashboard'),
            routes: [
              GoRoute(
                path: ':subscreen',
                builder: (context, state) {
                  final sub = state.pathParameters['subscreen']!;
                  return SduiScreen(
                    screenId: 'resume_$sub',
                    suppressAppBar: sub == 'forge',
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Presents any SDUI screen as a draggable bottom sheet modal.
void showSduiModalSheet(BuildContext context, String screenId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SduiScreen(
              screenId: screenId,
              suppressAppBar: true,
              scrollController: scrollController,
            ),
          );
        },
      );
    },
  );
}
