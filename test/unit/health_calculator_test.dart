import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/utils/health_calculator.dart';

void main() {
  group('HealthCalculator', () {
    test('bmi computes correctly', () {
      // 60kg, 165cm -> ~22.04
      expect(
        HealthCalculator.bmi(weightKg: 60, heightCm: 165),
        closeTo(22.04, 0.05),
      );
    });

    test('bmi guards against bad input', () {
      expect(HealthCalculator.bmi(weightKg: 0, heightCm: 165), 0);
      expect(HealthCalculator.bmi(weightKg: 60, heightCm: 0), 0);
    });

    test('bmiCategory classification', () {
      expect(HealthCalculator.bmiCategory(17), 'Underweight');
      expect(HealthCalculator.bmiCategory(22), 'Normal');
      expect(HealthCalculator.bmiCategory(27), 'Overweight');
      expect(HealthCalculator.bmiCategory(32), 'Obese');
    });

    test('recommendedTotalGainKg matches IOM bands', () {
      expect(HealthCalculator.recommendedTotalGainKg(20).min, 11.5);
      expect(HealthCalculator.recommendedTotalGainKg(20).max, 16.0);
      expect(HealthCalculator.recommendedTotalGainKg(17).max, 18.0);
      expect(HealthCalculator.recommendedTotalGainKg(35).max, 9.0);
    });

    test('sleepAssessment reflects the 7-9 h recommendation', () {
      expect(HealthCalculator.sleepAssessment(8), contains('Within'));
      expect(HealthCalculator.sleepAssessment(6.5), contains('Slightly below'));
      expect(HealthCalculator.sleepAssessment(5), contains('Well below'));
      expect(HealthCalculator.sleepAssessment(0), 'No data');
    });
  });
}
