import 'package:intl/intl.dart';

import '../../../core/constants/enums.dart';
import '../../../core/utils/health_calculator.dart';
import '../../blood_pressure/domain/bp_reading.dart';
import '../../blood_sugar/domain/glucose_reading.dart';
import '../../sleep/domain/sleep_entry.dart';
import '../../symptoms/domain/symptom_entry.dart';
import '../../weight/domain/weight_entry.dart';

/// How urgently an indicator suggests follow-up.
enum IndicatorLevel { ok, watch, alert }

/// A single interpreted health indicator (value + research-based reading).
class HealthIndicator {
  const HealthIndicator({
    required this.label,
    required this.value,
    required this.note,
    required this.level,
  });

  final String label;
  final String value;
  final String note;
  final IndicatorLevel level;

  /// ASCII marker so it renders in both the text report and the PDF font.
  String get marker => switch (level) {
        IndicatorLevel.ok => '[OK]',
        IndicatorLevel.watch => '[! ]',
        IndicatorLevel.alert => '[!!]',
      };
}

/// Builds a plain-text health summary (blood pressure, blood sugar, sleep,
/// weight, height/BMI and symptoms) plus research-based **indicators** a mother
/// can copy or send to her doctor. Pure and offline-friendly.
///
/// Reference ranges follow widely used clinical guidance: WHO (BMI), IOM 2009
/// (pregnancy weight gain), ACC/AHA (blood pressure), ADA/ACOG (gestational
/// glucose targets) and the National Sleep Foundation (sleep). Informational
/// only — not a diagnosis.
class HealthReportBuilder {
  const HealthReportBuilder._();

  static const int _maxRows = 12;

  /// Computes the interpreted indicators from the latest data. Shared by the
  /// text report and the PDF so both stay in sync. Notes are ASCII-only.
  static List<HealthIndicator> indicators({
    required List<BpReading> bpReadings,
    required List<GlucoseReading> glucoseReadings,
    required List<SleepEntry> sleepEntries,
    required List<WeightEntry> weightEntries,
    required List<SymptomEntry> symptoms,
    double? heightCm,
    double? baselineWeightKg,
  }) {
    final out = <HealthIndicator>[];

    // Sorted-newest helpers.
    List<T> desc<T>(List<T> src, DateTime Function(T) at) =>
        [...src]..sort((a, b) => at(b).compareTo(at(a)));

    final weights = desc<WeightEntry>(weightEntries, (e) => e.loggedAt);
    final latestWeight = weights.isEmpty ? null : weights.first.weightKg;
    final baseWeight = baselineWeightKg ??
        (weights.isEmpty ? null : weights.last.weightKg);

    // --- BMI (height + weight) ---
    if (latestWeight != null && heightCm != null && heightCm > 0) {
      final bmi = HealthCalculator.bmi(weightKg: latestWeight, heightCm: heightCm);
      final cat = HealthCalculator.bmiCategory(bmi);
      out.add(HealthIndicator(
        label: 'Body mass index',
        value: '${bmi.toStringAsFixed(1)} kg/m2',
        note: '$cat (WHO). Pre-pregnancy BMI guides recommended weight gain.',
        level: cat == 'Normal' ? IndicatorLevel.ok : IndicatorLevel.watch,
      ));
    }

    // --- Weight gain vs IOM range ---
    if (latestWeight != null && baseWeight != null) {
      final gained = latestWeight - baseWeight;
      final bmiForRange = (heightCm != null && heightCm > 0)
          ? HealthCalculator.bmi(weightKg: baseWeight, heightCm: heightCm)
          : 0.0;
      final range = HealthCalculator.recommendedTotalGainKg(bmiForRange);
      final note = bmiForRange > 0
          ? 'Recommended total gain for your BMI: '
              '${range.min.toStringAsFixed(0)}-${range.max.toStringAsFixed(0)} kg (IOM).'
          : 'Add your height for a personalised target range (IOM).';
      out.add(HealthIndicator(
        label: 'Weight change',
        value: '${gained >= 0 ? '+' : ''}${gained.toStringAsFixed(1)} kg',
        note: note,
        level: bmiForRange > 0 && gained > range.max
            ? IndicatorLevel.watch
            : IndicatorLevel.ok,
      ));
    }

    // --- Blood pressure (ACC/AHA) ---
    final bps = desc<BpReading>(bpReadings, (e) => e.loggedAt);
    if (bps.isNotEmpty) {
      final r = bps.first;
      final cat = HealthCalculator.bpCategory(r.systolic, r.diastolic);
      final (note, level) = switch (cat) {
        BpCategory.normal => ('Normal (<120/80 mmHg).', IndicatorLevel.ok),
        BpCategory.low => (
            'On the low side - fine unless you feel faint or dizzy.',
            IndicatorLevel.ok
          ),
        BpCategory.elevated => (
            'Elevated (120-129 systolic). Keep monitoring.',
            IndicatorLevel.watch
          ),
        BpCategory.stage1 => (
            'Stage 1 high (>=130/80, ACC/AHA). Discuss with your doctor.',
            IndicatorLevel.watch
          ),
        BpCategory.stage2 => (
            '>=140/90 - in pregnancy this can signal gestational hypertension '
                'or pre-eclampsia. Contact your doctor.',
            IndicatorLevel.alert
          ),
        BpCategory.crisis => (
            '>=180/120 - seek urgent medical care now.',
            IndicatorLevel.alert
          ),
      };
      out.add(HealthIndicator(
        label: 'Blood pressure',
        value: '${r.systolic}/${r.diastolic} mmHg',
        note: note,
        level: level,
      ));
    }

    // --- Blood sugar (ADA/ACOG GDM targets) ---
    if (glucoseReadings.isNotEmpty) {
      final gl = desc<GlucoseReading>(glucoseReadings, (e) => e.loggedAt);
      final latest = gl.first;
      final highs = gl
          .where((r) =>
              r.mgDl > HealthCalculator.glucoseUpperTarget(r.context))
          .length;
      final lows = gl
          .where((r) => r.mgDl < HealthCalculator.glucoseLowThreshold)
          .length;
      final level = highs > 0 || lows > 0
          ? (highs >= 3 || lows > 0 ? IndicatorLevel.alert : IndicatorLevel.watch)
          : IndicatorLevel.ok;
      final extras = [
        if (highs > 0) '$highs above target',
        if (lows > 0) '$lows low',
      ].join(', ');
      out.add(HealthIndicator(
        label: 'Blood sugar',
        value: '${latest.mgDl.toStringAsFixed(0)} mg/dL (${latest.status})'
            '${extras.isEmpty ? '' : ' - $extras'}',
        note: 'GDM targets: fasting <=95, 1-h post-meal <=140 mg/dL (ADA/ACOG).',
        level: level,
      ));
    }

    // --- Sleep (National Sleep Foundation) ---
    if (sleepEntries.isNotEmpty) {
      final sl = desc<SleepEntry>(sleepEntries, (e) => e.loggedAt);
      final recent = sl.take(7).toList();
      final avg = recent.fold<double>(0, (s, e) => s + e.hours) / recent.length;
      out.add(HealthIndicator(
        label: 'Sleep (7-night avg)',
        value: '${avg.toStringAsFixed(1)} h',
        note: '${HealthCalculator.sleepAssessment(avg)} (7-9 h, NSF).',
        level: avg >= HealthCalculator.sleepRecommendedMin
            ? IndicatorLevel.ok
            : (avg < 6 ? IndicatorLevel.alert : IndicatorLevel.watch),
      ));
    }

    // --- Symptoms (red-flag screen) ---
    if (symptoms.isNotEmpty) {
      final cutoff = DateTime.now().subtract(const Duration(days: 14));
      final recent =
          symptoms.where((s) => s.loggedAt.isAfter(cutoff)).toList();
      final severeFlags = recent.where((s) =>
          HealthCalculator.redFlagSymptomTypes.contains(s.type) &&
          s.severity >= 7);
      final headache =
          recent.any((s) => s.type == 'Headache' && s.severity >= 5);
      final swelling =
          recent.any((s) => s.type == 'Swelling' && s.severity >= 5);
      final flagged = severeFlags.isNotEmpty || (headache && swelling);
      out.add(HealthIndicator(
        label: 'Symptoms',
        value: '${recent.length} logged in last 2 weeks',
        note: flagged
            ? 'Severe headache and/or swelling can be warning signs of '
                'pre-eclampsia - please get checked soon.'
            : 'No red-flag symptoms in the last 2 weeks.',
        level: flagged ? IndicatorLevel.alert : IndicatorLevel.ok,
      ));
    }

    return out;
  }

  static String build({
    required DateTime generatedAt,
    required List<BpReading> bpReadings,
    required List<GlucoseReading> glucoseReadings,
    required List<SleepEntry> sleepEntries,
    required List<WeightEntry> weightEntries,
    List<SymptomEntry> symptoms = const [],
    String? motherName,
    int? currentWeek,
    DateTime? dueDate,
    double? heightCm,
    double? baselineWeightKg,
  }) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final dtFmt = DateFormat('d MMM, HH:mm');
    final b = StringBuffer();

    b.writeln('PREGNANCY COMPANION - HEALTH REPORT');
    b.writeln('=' * 52);
    if (motherName != null && motherName.isNotEmpty) b.writeln('Name: $motherName');
    if (currentWeek != null) b.writeln('Gestational week: $currentWeek');
    if (dueDate != null) b.writeln('Estimated due date: ${dateFmt.format(dueDate)}');
    if (heightCm != null && heightCm > 0) {
      b.writeln('Height: ${heightCm.toStringAsFixed(0)} cm');
    }
    b.writeln('Generated: ${dtFmt.format(generatedAt)}');
    b.writeln('');

    // Indicators / assessment.
    final flags = indicators(
      bpReadings: bpReadings,
      glucoseReadings: glucoseReadings,
      sleepEntries: sleepEntries,
      weightEntries: weightEntries,
      symptoms: symptoms,
      heightCm: heightCm,
      baselineWeightKg: baselineWeightKg,
    );
    b.writeln('ASSESSMENT & INDICATORS');
    b.writeln('-' * 52);
    if (flags.isEmpty) {
      b.writeln('Log some vitals to see interpreted indicators.');
    } else {
      for (final f in flags) {
        b.writeln('${f.marker} ${f.label}: ${f.value}');
        b.writeln('      ${f.note}');
      }
      b.writeln('');
      b.writeln('Guidance: WHO (BMI), IOM (weight gain), ACC/AHA (BP), '
          'ADA/ACOG (glucose), NSF (sleep).');
    }
    b.writeln('');

    // Blood pressure
    b.writeln('BLOOD PRESSURE');
    b.writeln('-' * 52);
    if (bpReadings.isEmpty) {
      b.writeln('No readings recorded.');
    } else {
      final sorted = [...bpReadings]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final r in sorted.take(_maxRows)) {
        b.writeln('- ${dtFmt.format(r.loggedAt)} - ${r.systolic}/${r.diastolic} mmHg'
            '${r.pulse != null ? ', ${r.pulse} bpm' : ''} (${r.category.label})');
      }
      if (sorted.length > _maxRows) {
        b.writeln('... and ${sorted.length - _maxRows} earlier reading(s).');
      }
    }
    b.writeln('');

    // Blood sugar
    b.writeln('BLOOD SUGAR');
    b.writeln('-' * 52);
    if (glucoseReadings.isEmpty) {
      b.writeln('No readings recorded.');
    } else {
      final sorted = [...glucoseReadings]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final r in sorted.take(_maxRows)) {
        b.writeln('- ${dtFmt.format(r.loggedAt)} - ${r.mgDl.toStringAsFixed(0)} mg/dL '
            '(${r.context.label}, ${r.status})');
      }
      if (sorted.length > _maxRows) {
        b.writeln('... and ${sorted.length - _maxRows} earlier reading(s).');
      }
    }
    b.writeln('');

    // Sleep
    b.writeln('SLEEP');
    b.writeln('-' * 52);
    if (sleepEntries.isEmpty) {
      b.writeln('No entries recorded.');
    } else {
      final sorted = [...sleepEntries]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      final recent = sorted.take(7).toList();
      final avg = recent.fold<double>(0, (s, e) => s + e.hours) / recent.length;
      b.writeln('7-night average: ${avg.toStringAsFixed(1)} h');
      for (final e in sorted.take(_maxRows)) {
        b.writeln('- ${DateFormat('d MMM').format(e.loggedAt)} - '
            '${e.hours.toStringAsFixed(1)} h (quality ${e.quality}/5)');
      }
    }
    b.writeln('');

    // Weight
    b.writeln('WEIGHT');
    b.writeln('-' * 52);
    if (weightEntries.isEmpty) {
      b.writeln('No entries recorded.');
    } else {
      final sorted = [...weightEntries]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      b.writeln('Latest: ${sorted.first.weightKg.toStringAsFixed(1)} kg');
      for (final e in sorted.take(_maxRows)) {
        b.writeln('- ${DateFormat('d MMM').format(e.loggedAt)} - '
            '${e.weightKg.toStringAsFixed(1)} kg');
      }
    }
    b.writeln('');

    // Symptoms
    b.writeln('SYMPTOMS');
    b.writeln('-' * 52);
    if (symptoms.isEmpty) {
      b.writeln('No symptoms recorded.');
    } else {
      final sorted = [...symptoms]
        ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));
      for (final s in sorted.take(_maxRows)) {
        b.writeln('- ${DateFormat('d MMM').format(s.loggedAt)} - '
            '${s.type} (severity ${s.severity}/10)'
            '${s.note != null && s.note!.isNotEmpty ? ' - ${s.note}' : ''}');
      }
      if (sorted.length > _maxRows) {
        b.writeln('... and ${sorted.length - _maxRows} earlier entry(ies).');
      }
    }
    b.writeln('');

    b.writeln('-' * 52);
    b.writeln('Informational only - not a substitute for medical advice.');

    return b.toString();
  }
}
