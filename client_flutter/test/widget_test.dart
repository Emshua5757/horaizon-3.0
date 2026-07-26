import 'package:client_flutter/core/hbp/hbp_client_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client_flutter/app.dart';

void main() {
  testWidgets('HoraizonApp renders main title smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          hbpClientProvider.overrideWith((ref) async {
            throw Exception('Offline test override');
          }),
        ],
        child: const HoraizonApp(),
      ),
    );

    await tester.pump();

    expect(find.text('horAIzon 3.0'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
