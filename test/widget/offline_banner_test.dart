import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/di/providers.dart';
import 'package:pregnancy_companion/core/widgets/offline_banner.dart';

void main() {
  Widget wrap(Stream<bool> status) => ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => status),
        ],
        child: const MaterialApp(
          home: Scaffold(body: OfflineBanner()),
        ),
      );

  testWidgets('shows the offline message when offline', (tester) async {
    await tester.pumpWidget(wrap(Stream.value(false)));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.byIcon(Icons.cloud_off), findsOneWidget);
  });

  testWidgets('shows nothing when online', (tester) async {
    await tester.pumpWidget(wrap(Stream.value(true)));
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsNothing);
    expect(find.byIcon(Icons.cloud_off), findsNothing);
  });

  testWidgets('assumes online before the first event', (tester) async {
    await tester.pumpWidget(wrap(const Stream.empty()));
    await tester.pump();
    expect(find.textContaining("You're offline"), findsNothing);
  });
}
