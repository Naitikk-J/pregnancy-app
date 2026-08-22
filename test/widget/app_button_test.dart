import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/widgets/app_button.dart';

void main() {
  Widget wrap(Widget child) =>
      MaterialApp(home: Scaffold(body: child));

  testWidgets('AppButton shows label and fires onPressed', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(AppButton(label: 'Save', onPressed: () => tapped = true)),
    );

    expect(find.text('Save'), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(tapped, isTrue);
  });

  testWidgets('AppButton hides label and disables tap while loading',
      (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      wrap(AppButton(
        label: 'Save',
        isLoading: true,
        onPressed: () => tapped = true,
      )),
    );

    expect(find.text('Save'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(AppButton));
    expect(tapped, isFalse);
  });
}
