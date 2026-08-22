import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/core/utils/pregnancy_calculator.dart';

void main() {
  group('PregnancyCalculator', () {
    final lmp = DateTime(2025, 1, 1);

    test('dueDateFromLmp adds 280 days', () {
      expect(
        PregnancyCalculator.dueDateFromLmp(lmp),
        DateTime(2025, 1, 1).add(const Duration(days: 280)),
      );
    });

    test('lmpFromDueDate is the inverse of dueDateFromLmp', () {
      final due = PregnancyCalculator.dueDateFromLmp(lmp);
      expect(PregnancyCalculator.lmpFromDueDate(due), lmp);
    });

    test('currentWeek is 1 on the LMP day', () {
      expect(PregnancyCalculator.currentWeek(lmp, asOf: lmp), 1);
    });

    test('currentWeek is 2 after 7 days', () {
      expect(
        PregnancyCalculator.currentWeek(lmp,
            asOf: lmp.add(const Duration(days: 7))),
        2,
      );
    });

    test('currentWeek clamps to 40 well past term', () {
      expect(
        PregnancyCalculator.currentWeek(lmp,
            asOf: lmp.add(const Duration(days: 400))),
        40,
      );
    });

    test('gestationalDays never negative for future LMP', () {
      final future = DateTime(2999, 1, 1);
      expect(PregnancyCalculator.gestationalDays(future), 0);
    });

    test('trimesterForWeek boundaries', () {
      expect(PregnancyCalculator.trimesterForWeek(13), Trimester.first);
      expect(PregnancyCalculator.trimesterForWeek(14), Trimester.second);
      expect(PregnancyCalculator.trimesterForWeek(27), Trimester.second);
      expect(PregnancyCalculator.trimesterForWeek(28), Trimester.third);
    });

    test('progress is within 0..1 and ~0.5 at 20 weeks', () {
      final asOf = lmp.add(const Duration(days: 140));
      final p = PregnancyCalculator.progress(lmp, asOf: asOf);
      expect(p, closeTo(0.5, 0.01));
    });

    test('daysRemaining is zero when past due', () {
      final due = PregnancyCalculator.dueDateFromLmp(lmp);
      expect(
        PregnancyCalculator.daysRemaining(due,
            asOf: due.add(const Duration(days: 5))),
        0,
      );
    });
  });
}
