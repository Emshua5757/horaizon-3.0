import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:client_flutter/core/auth/auth_provider.dart';

void main() {
  group('AuthNotifier', () {
    test('Initializes with unauthenticated state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(authProvider);
      expect(state, equals(AuthState.unauthenticated));
    });

    test('Verifies fallback PIN 5757 and transitions to authenticated', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      notifier.verifyPin('5757');

      expect(container.read(authProvider), equals(AuthState.authenticated));
    });

    test('Rejects invalid PIN without changing state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(authProvider.notifier);
      notifier.verifyPin('0000');

      expect(container.read(authProvider), equals(AuthState.unauthenticated));
    });
  });
}
