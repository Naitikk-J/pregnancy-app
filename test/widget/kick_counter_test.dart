import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/kick_counter/presentation/kick_counter_providers.dart';
import 'package:pregnancy_companion/features/kick_counter/presentation/kick_counter_screen.dart';

void main() {
  // Overriding the CRUD provider to null keeps the whole screen off Firebase:
  // history streams empty and the in-memory session controller no-ops its
  // persistence, so we can drive the start -> tap flow purely in widget land.
  Widget wrap() => ProviderScope(
        overrides: [kickCrudProvider.overrideWithValue(null)],
        child: const MaterialApp(home: KickCounterScreen()),
      );

  testWidgets('starts a session and counts kicks', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    // History view first.
    expect(find.text('Start counting'), findsOneWidget);
    expect(find.text('0'), findsNothing);

    await tester.tap(find.text('Start counting'));
    await tester.pump();

    // Active session view: counter starts at 0 of 10.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('of 10 kicks'), findsOneWidget);

    // Tap the big "I felt a kick" target three times.
    final kickButton = find.text('I felt a kick');
    for (var i = 0; i < 3; i++) {
      await tester.tap(kickButton);
      await tester.pump();
    }
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('reaching the target completes the session', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pump();

    await tester.tap(find.text('Start counting'));
    await tester.pump();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('I felt a kick'));
      await tester.pump();
    }

    expect(find.textContaining('Great'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });
}
