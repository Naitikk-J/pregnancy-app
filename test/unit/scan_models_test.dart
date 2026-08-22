import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/document_scan/domain/scan_models.dart';

void main() {
  group('ExtractedMedicine', () {
    test('parses a full medicine and maps to a Medicine', () {
      final e = ExtractedMedicine.fromJson({
        'name': 'Folic Acid',
        'dosage': '5 mg',
        'timesPerDay': 2,
        'suggestedTimes': ['09:00', '21:00'],
        'timing': 'afterFood',
        'durationDays': 30,
        'instructions': 'with water',
      });
      expect(e.name, 'Folic Acid');
      expect(e.timing, MedicineTiming.afterFood);
      expect(e.suggestedTimes, ['09:00', '21:00']);

      final med = e.toMedicine(id: 'm1', startDate: DateTime(2026, 1, 1));
      expect(med.id, 'm1');
      expect(med.times, ['09:00', '21:00']);
      expect(med.endDate, DateTime(2026, 1, 31));
      expect(med.notes, 'with water');
    });

    test('fills default times when none provided', () {
      final e = ExtractedMedicine.fromJson({
        'name': 'Iron',
        'dosage': '1 tablet',
        'timesPerDay': 3,
      });
      expect(e.suggestedTimes, ['08:00', '14:00', '20:00']);
    });

    test('drops malformed times', () {
      final e = ExtractedMedicine.fromJson({
        'name': 'X',
        'suggestedTimes': ['09:00', 'noon', '25:99', '21:30'],
      });
      expect(e.suggestedTimes, ['09:00', '21:30']);
    });
  });

  group('PrescriptionResult', () {
    test('parses medicines and warnings', () {
      final r = PrescriptionResult.fromJson({
        'isPrescription': true,
        'medicines': [
          {'name': 'A', 'timesPerDay': 1},
          {'name': 'B', 'timesPerDay': 2},
        ],
        'warnings': ['check dose', ''],
      });
      expect(r.isPrescription, isTrue);
      expect(r.medicines.length, 2);
      expect(r.warnings, ['check dose']);
    });

    test('handles a non-prescription gracefully', () {
      final r = PrescriptionResult.fromJson({
        'isPrescription': false,
        'medicines': [],
      });
      expect(r.isPrescription, isFalse);
      expect(r.medicines, isEmpty);
    });
  });

  group('LabAnalysis', () {
    test('parses findings and flags status', () {
      final a = LabAnalysis.fromJson({
        'reportType': 'CBC',
        'summary': 'Mostly normal.',
        'findings': [
          {
            'name': 'Hemoglobin',
            'value': '9.5',
            'unit': 'g/dL',
            'referenceRange': '11-15',
            'status': 'Low',
            'note': 'mild anemia',
          },
        ],
        'recommendations': ['Iron-rich foods'],
        'urgent': false,
      });
      expect(a.reportType, 'CBC');
      expect(a.findings.single.status, 'low');
      expect(a.findings.single.isAbnormal, isTrue);
      expect(a.disclaimer, isNotEmpty); // defaulted
    });
  });

  group('ScanRecord', () {
    test('round-trips through JSON', () {
      final r = ScanRecord(
        id: 'x',
        type: 'lab',
        createdAt: DateTime(2026, 2, 3, 4, 5),
        imagePath: '/tmp/x.jpg',
        title: 'CBC',
        summary: 'ok',
      );
      final back = ScanRecord.fromJson(r.toJson());
      expect(back.id, 'x');
      expect(back.type, 'lab');
      expect(back.imagePath, '/tmp/x.jpg');
      expect(back.createdAt, DateTime(2026, 2, 3, 4, 5));
    });
  });
}
