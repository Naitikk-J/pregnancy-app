import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/blood_pressure/domain/bp_reading.dart';
import 'package:pregnancy_companion/features/blood_sugar/domain/glucose_reading.dart';
import 'package:pregnancy_companion/features/reports/domain/health_report_builder.dart';
import 'package:pregnancy_companion/features/sleep/domain/sleep_entry.dart';
import 'package:pregnancy_companion/features/symptoms/domain/symptom_entry.dart';
import 'package:pregnancy_companion/features/weight/domain/weight_entry.dart';

void main() {
  final now = DateTime(2026, 6, 1, 9);

  HealthIndicator byLabel(List<HealthIndicator> list, String label) =>
      list.firstWhere((i) => i.label == label);

  group('HealthReportBuilder.indicators', () {
    test('BMI is computed from latest weight + height (WHO)', () {
      final flags = HealthReportBuilder.indicators(
        bpReadings: const [],
        glucoseReadings: const [],
        sleepEntries: const [],
        weightEntries: [WeightEntry(id: 'w', weightKg: 60, loggedAt: now)],
        symptoms: const [],
        heightCm: 165,
      );
      final bmi = byLabel(flags, 'Body mass index');
      expect(bmi.value, contains('22.0'));
      expect(bmi.note, contains('Normal'));
      expect(bmi.level, IndicatorLevel.ok);
    });

    test('high blood pressure flags pre-eclampsia as an alert', () {
      final flags = HealthReportBuilder.indicators(
        bpReadings: [
          BpReading(id: 'b', systolic: 145, diastolic: 95, loggedAt: now),
        ],
        glucoseReadings: const [],
        sleepEntries: const [],
        weightEntries: const [],
        symptoms: const [],
      );
      final bp = byLabel(flags, 'Blood pressure');
      expect(bp.level, IndicatorLevel.alert);
      expect(bp.note.toLowerCase(), contains('pre-eclampsia'));
    });

    test('glucose above the GDM target is flagged', () {
      final flags = HealthReportBuilder.indicators(
        bpReadings: const [],
        glucoseReadings: [
          GlucoseReading(
              id: 'g', mgDl: 120, context: GlucoseContext.fasting, loggedAt: now),
        ],
        sleepEntries: const [],
        weightEntries: const [],
        symptoms: const [],
      );
      final gl = byLabel(flags, 'Blood sugar');
      expect(gl.level, isNot(IndicatorLevel.ok));
      expect(gl.note, contains('95'));
    });

    test('short sleep is flagged against the 7-9 h band', () {
      final flags = HealthReportBuilder.indicators(
        bpReadings: const [],
        glucoseReadings: const [],
        sleepEntries: [SleepEntry(id: 's', hours: 5, quality: 3, loggedAt: now)],
        weightEntries: const [],
        symptoms: const [],
      );
      final sleep = byLabel(flags, 'Sleep (7-night avg)');
      expect(sleep.level, IndicatorLevel.alert);
    });

    test('severe headache + swelling raises a red-flag symptom alert', () {
      final recent = DateTime.now().subtract(const Duration(days: 1));
      final flags = HealthReportBuilder.indicators(
        bpReadings: const [],
        glucoseReadings: const [],
        sleepEntries: const [],
        weightEntries: const [],
        symptoms: [
          SymptomEntry(id: 's1', type: 'Headache', severity: 8, loggedAt: recent),
          SymptomEntry(id: 's2', type: 'Swelling', severity: 6, loggedAt: recent),
        ],
      );
      final sy = byLabel(flags, 'Symptoms');
      expect(sy.level, IndicatorLevel.alert);
    });

    test('weight gain beyond the IOM range is a watch', () {
      final flags = HealthReportBuilder.indicators(
        bpReadings: const [],
        glucoseReadings: const [],
        sleepEntries: const [],
        weightEntries: [WeightEntry(id: 'w', weightKg: 85, loggedAt: now)],
        symptoms: const [],
        heightCm: 165,
        baselineWeightKg: 60, // BMI ~22 -> IOM max 16kg; gained 25kg
      );
      final wt = byLabel(flags, 'Weight change');
      expect(wt.value, contains('+25.0'));
      expect(wt.level, IndicatorLevel.watch);
    });
  });
}
