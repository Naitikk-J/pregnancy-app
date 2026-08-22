import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/widgets/empty_state.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders title and message', (tester) async {
    await tester.pumpWidget(wrap(const EmptyState(
      title: 'Nothing here',
      message: 'Add something to get started.',
    )));

    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something to get started.'), findsOneWidget);
  });

  testWidgets('shows an action button only when both label and callback given',
      (tester) async {
    await tester.pumpWidget(wrap(const EmptyState(title: 'Empty')));
    expect(find.byType(TextButton), findsNothing);

    var tapped = false;
    await tester.pumpWidget(wrap(EmptyState(
      title: 'Empty',
      actionLabel: 'Add',
      onAction: () => tapped = true,
    )));
    expect(find.text('Add'), findsOneWidget);

    await tester.tap(find.text('Add'));
    expect(tapped, isTrue);
  });
}
