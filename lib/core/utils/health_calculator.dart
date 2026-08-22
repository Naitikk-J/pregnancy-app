import '../constants/enums.dart';

/// Pure health computations (BMI, weight gain, BP & glucose ranges).
/// Unit-testable — no Flutter/Firebase imports.
class HealthCalculator {
  const HealthCalculator._();

  /// Body Mass Index from weight (kg) and height (cm). Returns 0 for bad input.
  static double bmi({required double weightKg, required double heightCm}) {
    if (heightCm <= 0 || weightKg <= 0) return 0;
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  /// WHO BMI classification.
  static String bmiCategory(double bmi) {
    if (bmi <= 0) return 'Unknown';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  /// Recommended total pregnancy weight gain range (kg) based on pre-pregnancy
  /// BMI, per IOM guidelines. Returns (min, max).
  static ({double min, double max}) recommendedTotalGainKg(double prePregBmi) {
    if (prePregBmi < 18.5) return (min: 12.5, max: 18.0);
    if (prePregBmi < 25) return (min: 11.5, max: 16.0);
    if (prePregBmi < 30) return (min: 7.0, max: 11.5);
    return (min: 5.0, max: 9.0);
  }

  /// Blood-pressure category from a systolic/diastolic reading (mmHg), per
  /// ACC/AHA thresholds. Highest-severity match wins.
  static BpCategory bpCategory(int systolic, int diastolic) {
    if (systolic >= 180 || diastolic >= 120) return BpCategory.crisis;
    if (systolic >= 140 || diastolic >= 90) return BpCategory.stage2;
    if (systolic >= 130 || diastolic >= 80) return BpCategory.stage1;
    if (systolic >= 120) return BpCategory.elevated; // diastolic < 80 here
    if (systolic < 90 || diastolic < 60) return BpCategory.low;
    return BpCategory.normal;
  }

  /// Upper healthy target (mg/dL) for a glucose reading, using common
  /// gestational-diabetes goals (fasting ≤95, 1-hr post-meal ≤140).
  static double glucoseUpperTarget(GlucoseContext context) => switch (context) {
        GlucoseContext.fasting => 95,
        GlucoseContext.beforeMeal => 95,
        GlucoseContext.afterMeal => 140,
        GlucoseContext.random => 140,
      };

  /// Lower bound (mg/dL) below which a reading is hypoglycaemic.
  static const double glucoseLowThreshold = 70;

  /// Whether a glucose reading (mg/dL) sits within the healthy range for its
  /// [context] — i.e. not hypo and at/below the upper target.
  static bool glucoseInRange(double mgDl, GlucoseContext context) =>
      mgDl >= glucoseLowThreshold && mgDl <= glucoseUpperTarget(context);

  /// 'Low' / 'In range' / 'High' label for a glucose reading.
  static String glucoseStatus(double mgDl, GlucoseContext context) {
    if (mgDl < glucoseLowThreshold) return 'Low';
    if (mgDl > glucoseUpperTarget(context)) return 'High';
    return 'In range';
  }

  /// Recommended nightly sleep for adults, per the National Sleep Foundation.
  static const double sleepRecommendedMin = 7;
  static const double sleepRecommendedMax = 9;

  /// Plain-language assessment of an average nightly sleep duration (hours),
  /// against the 7-9 h recommendation. ASCII only (safe for PDF fonts).
  static String sleepAssessment(double avgHours) {
    if (avgHours <= 0) return 'No data';
    if (avgHours < 6) {
      return 'Well below the recommended 7-9 h - mention this to your doctor';
    }
    if (avgHours < sleepRecommendedMin) {
      return 'Slightly below the recommended 7-9 h';
    }
    if (avgHours > 10) return 'Above typical - fine if you feel rested';
    return 'Within the recommended 7-9 h';
  }

  /// Symptoms that, especially when severe or combined, are recognised warning
  /// signs in pregnancy (e.g. pre-eclampsia) and warrant prompt review.
  static const Set<String> redFlagSymptomTypes = {
    'Headache',
    'Swelling',
    'Dizziness',
    'Vomiting',
  };
}
