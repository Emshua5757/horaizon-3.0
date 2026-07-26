// Basic Flutter widget test for horAIzon 3.0

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_flutter/app.dart';

void main() {
  testWidgets('HoraizonApp renders main title smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: HoraizonApp()));

    // Verify that 'horAIzon 3.0' text widget exists.
    expect(find.text('horAIzon 3.0'), findsOneWidget);
  });
}
