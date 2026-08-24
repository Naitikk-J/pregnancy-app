import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/core/utils/health_calculator.dart';
import 'package:pregnancy_companion/features/blood_pressure/domain/bp_reading.dart';
import 'package:pregnancy_companion/features/blood_sugar/domain/glucose_reading.dart';
import 'package:pregnancy_companion/features/hospital_bag/domain/hospital_bag_item.dart';
import 'package:pregnancy_companion/features/reports/domain/health_report_builder.dart';
import 'package:pregnancy_companion/features/sleep/domain/sleep_entry.dart';
import 'package:pregnancy_companion/features/vaccination/domain/vaccine.dart';
import 'package:pregnancy_companion/features/weight/domain/weight_entry.dart';

void main() {
  group('HealthCalculator.bpCategory', () {
    test('classifies across the ACC/AHA bands', () {
      expect(HealthCalculator.bpCategory(110, 70), BpCategory.normal);
      expect(HealthCalculator.bpCategory(122, 78), BpCategory.elevated);
      expect(HealthCalculator.bpCategory(132, 82), BpCategory.stage1);
      expect(HealthCalculator.bpCategory(145, 92), BpCategory.stage2);
      expect(HealthCalculator.bpCategory(185, 100), BpCategory.crisis);
      expect(HealthCalculator.bpCategory(85, 55), BpCategory.low);
    });

    test('takes the higher-severity of systolic/diastolic', () {
      // Normal systolic but stage-2 diastolic -> stage2.
      expect(HealthCalculator.bpCategory(118, 95), BpCategory.stage2);
    });

    test('isConcern flags stage2, crisis and low', () {
      expect(BpCategory.stage2.isConcern, isTrue);
      expect(BpCategory.crisis.isConcern, isTrue);
      expect(BpCategory.low.isConcern, isTrue);
      expect(BpCategory.normal.isConcern, isFalse);
      expect(BpCategory.elevated.isConcern, isFalse);
    });
  });

  group('HealthCalculator glucose', () {
    test('fasting target is 95, post-meal 140', () {
      expect(HealthCalculator.glucoseUpperTarget(GlucoseContext.fasting), 95);
      expect(HealthCalculator.glucoseUpperTarget(GlucoseContext.lunch), 140);
    });

    test('inRange respects context and hypo threshold', () {
      expect(HealthCalculator.glucoseInRange(90, GlucoseContext.fasting), isTrue);
      expect(HealthCalculator.glucoseInRange(110, GlucoseContext.fasting), isFalse);
      expect(HealthCalculator.glucoseInRange(110, GlucoseContext.lunch), isTrue);
      expect(HealthCalculator.glucoseInRange(60, GlucoseContext.fasting), isFalse);
    });

    test('status labels low/in range/high', () {
      expect(HealthCalculator.glucoseStatus(60, GlucoseContext.fasting), 'Low');
      expect(HealthCalculator.glucoseStatus(90, GlucoseContext.fasting), 'In range');
      expect(HealthCalculator.glucoseStatus(130, GlucoseContext.fasting), 'High');
    });
  });

  group('Entity serialization', () {
    test('BpReading round-trips and computes category', () {
      final r = BpReading(
        id: 'b1',
        systolic: 145,
        diastolic: 92,
        pulse: 80,
        loggedAt: DateTime.utc(2026, 6, 1, 9),
      );
      expect(r.category, BpCategory.stage2);
      expect(BpReading.fromJson(r.toJson()), r);
    });

    test('GlucoseReading round-trips with context', () {
      final r = GlucoseReading(
        id: 'g1',
        mgDl: 105,
        context: GlucoseContext.fasting,
        loggedAt: DateTime.utc(2026, 6, 1, 7),
      );
      expect(r.status, 'High');
      final restored = GlucoseReading.fromJson(r.toJson());
      expect(restored, r);
      expect(restored.context, GlucoseContext.fasting);
      expect(restored.hasInsulin, isFalse);
    });

    test('GlucoseReading round-trips with insulin dose', () {
      final r = GlucoseReading(
        id: 'g2',
        mgDl: 150,
        context: GlucoseContext.dinner,
        loggedAt: DateTime.utc(2026, 6, 1, 20),
        insulinUnits: 4.5,
        insulinAt: DateTime.utc(2026, 6, 1, 19, 45),
      );
      final restored = GlucoseReading.fromJson(r.toJson());
      expect(restored, r);
      expect(restored.hasInsulin, isTrue);
      expect(restored.insulinUnits, 4.5);
      expect(restored.insulinAt, DateTime.utc(2026, 6, 1, 19, 45));
    });

    test('legacy afterMeal context maps to a post-meal target', () {
      final restored = GlucoseReading.fromJson(const {
        'id': 'g3',
        'mgDl': 130,
        'context': 'afterMeal',
        'loggedAt': '2026-06-01T13:00:00.000Z',
      });
      expect(restored.context, GlucoseContext.other);
      expect(HealthCalculator.glucoseUpperTarget(restored.context), 140);
    });

    test('SleepEntry round-trips', () {
      final e = SleepEntry(
        id: 's1',
        hours: 7.5,
        quality: 4,
        loggedAt: DateTime.utc(2026, 6, 1),
      );
      expect(SleepEntry.fromJson(e.toJson()), e);
    });

    test('Vaccine round-trips and copyWith clears dates', () {
      const v = Vaccine(id: 'tdap', name: 'Tdap', timing: '27–36 weeks');
      final scheduled = v.copyWith(
        status: VaccineStatus.scheduled,
        scheduledDate: DateTime.utc(2026, 6, 1),
      );
      expect(scheduled.status, VaccineStatus.scheduled);
      expect(Vaccine.fromJson(scheduled.toJson()), scheduled);
      final reset = scheduled.copyWith(status: VaccineStatus.due, clearDates: true);
      expect(reset.scheduledDate, isNull);
    });

    test('HospitalBagItem round-trips and toggles packed', () {
      const i = HospitalBagItem(
        id: 'm_pads',
        label: 'Maternity pads',
        category: HospitalBagCategory.mother,
      );
      expect(i.packed, isFalse);
      final packed = i.copyWith(packed: true);
      expect(packed.packed, isTrue);
      expect(HospitalBagItem.fromJson(packed.toJson()), packed);
    });
  });

  group('Catalogs', () {
    test('vaccine ids are unique', () {
      final ids = kDefaultVaccines.map((v) => v.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('hospital bag ids are unique and cover all categories', () {
      final ids = kDefaultBagItems.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final c in HospitalBagCategory.values) {
        expect(kDefaultBagItems.any((i) => i.category == c), isTrue,
            reason: 'missing items for ${c.name}');
      }
    });
  });

  group('HealthReportBuilder', () {
    test('summarises all sections with data', () {
      final report = HealthReportBuilder.build(
        generatedAt: DateTime(2026, 6, 1, 12),
        motherName: 'Asha',
        currentWeek: 30,
        dueDate: DateTime(2026, 8, 1),
        bpReadings: [
          BpReading(id: 'b', systolic: 120, diastolic: 78, loggedAt: DateTime(2026, 6, 1, 9)),
        ],
        glucoseReadings: [
          GlucoseReading(id: 'g', mgDl: 90, context: GlucoseContext.fasting, loggedAt: DateTime(2026, 6, 1, 7)),
        ],
        sleepEntries: [
          SleepEntry(id: 's', hours: 8, quality: 4, loggedAt: DateTime(2026, 6, 1)),
        ],
        weightEntries: [
          WeightEntry(id: 'w', weightKg: 65, loggedAt: DateTime(2026, 6, 1)),
        ],
      );
      expect(report, contains('HEALTH REPORT'));
      expect(report, contains('Asha'));
      expect(report, contains('120/78 mmHg'));
      expect(report, contains('mg/dL'));
      expect(report, contains('7-night average'));
      expect(report, contains('65.0 kg'));
    });

    test('handles empty data gracefully', () {
      final report = HealthReportBuilder.build(
        generatedAt: DateTime(2026, 6, 1),
        bpReadings: const [],
        glucoseReadings: const [],
        sleepEntries: const [],
        weightEntries: const [],
      );
      expect(report, contains('No readings recorded.'));
      expect(report, contains('No entries recorded.'));
    });
  });
}
