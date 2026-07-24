import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_flutter/app/auth/auth_provider.dart';
import 'package:client_flutter/app/auth/pin_entry_screen.dart';

void main() {
  group('🏆 horAIzon 2.0 Auth Flow - HackerRank System Challenge 🏆', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // LEVEL 1: STATE ENGINE CHALLENGES
    // =========================================================================

    test('🔥 Challenge 1.1: Initial State Integrity (O(1) Memory Initialization)', () {
      // GIVEN: The system has just booted.
      // WHEN: We read the authentication state.
      final authState = container.read(authProvider);

      // THEN: The user must be strictly unauthenticated with an empty PIN buffer.
      expect(
        authState.status,
        AuthStatus.unauthenticated,
        reason: 'Security breach! Initial boot status must be strictly unauthenticated.',
      );
      expect(
        authState.enteredPin,
        '',
        reason: 'Initial PIN buffer must be empty.',
      );
    });

    test('🔥 Challenge 1.2: Dynamic Keystroke Buffering & Boundary Limits', () {
      final notifier = container.read(authProvider.notifier);

      // WHEN: User presses '4', '0', '0'
      notifier.enterDigit('4');
      notifier.enterDigit('0');
      notifier.enterDigit('0');

      // THEN: State must buffer the values in FIFO sequence but remain unauthenticated.
      var state = container.read(authProvider);
      expect(state.enteredPin, '400');
      expect(state.status, AuthStatus.unauthenticated);

      // WHEN: User attempts to exceed the 4-digit limit by adding extra digits
      notifier.enterDigit('2'); // Hits 4th digit (Correct PIN: 4002)
      
      state = container.read(authProvider);
      expect(state.status, AuthStatus.authenticated, reason: 'PIN 4002 is valid. User must be authenticated.');
      expect(state.enteredPin, '4002');
    });

    test('🔥 Challenge 1.3: Underflow Immunity (Backspace Edge Case)', () {
      final notifier = container.read(authProvider.notifier);

      // WHEN: User types and deletes
      notifier.enterDigit('4');
      notifier.deleteDigit();

      var state = container.read(authProvider);
      expect(state.enteredPin, '', reason: 'Buffer should be empty after deleting the only digit.');

      // WHEN: User clicks delete on an empty buffer (Potential index underflow crash vector!)
      notifier.deleteDigit();
      
      state = container.read(authProvider);
      expect(state.enteredPin, '', reason: 'System must handle empty delete gracefully without index out of bounds exceptions.');
      expect(state.status, AuthStatus.unauthenticated);
    });

    test('🔥 Challenge 1.4: Cryptographic PIN Rejection & Reset Shakes', () async {
      final notifier = container.read(authProvider.notifier);

      // WHEN: User inputs an invalid PIN (e.g., 9999)
      notifier.enterDigit('9');
      notifier.enterDigit('9');
      notifier.enterDigit('9');
      notifier.enterDigit('9'); // Hits 4th digit

      var state = container.read(authProvider);
      
      // THEN: State must immediately register an Error state to trigger shake animations
      expect(
        state.status,
        AuthStatus.error,
        reason: 'Invalid PIN entry must transition to AuthStatus.error to trigger UI shake feedback.',
      );

      // AND: The entered buffer must clear itself so the user can re-input securely
      expect(
        state.enteredPin,
        '',
        reason: 'PIN buffer must clear instantly on failure to ensure zero-residual state visibility.',
      );
    });

    // =========================================================================
    // LEVEL 2: WIDGET RENDERING & USER INTERACTION CHALLENGES
    // =========================================================================

    testWidgets('🎮 Challenge 2.1: Glassmorphic Dialpad Structural Paint', (WidgetTester tester) async {
      // GIVEN: The application renders the secure PinEntryScreen.
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const PinEntryScreen(),
          ),
        ),
      );

      // THEN: Proves the dialpad contains the 10 numeric buttons (0-9).
      for (int i = 0; i <= 9; i++) {
        expect(
          find.text('$i'),
          findsOneWidget,
          reason: 'Keypad is missing key: $i. The dialpad must exhibit full decimal completeness.',
        );
      }

      // AND: The dialpad contains a backspace/delete key
      expect(
        find.byIcon(Icons.backspace_outlined),
        findsOneWidget,
        reason: 'Keypad is missing the backspace delete button for underflow edits.',
      );
    });
  });
}
