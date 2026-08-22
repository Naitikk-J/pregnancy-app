import '../constants/app_constants.dart';
import '../constants/enums.dart';

/// Pure functions for pregnancy date math. No I/O, fully unit-testable.
///
/// Convention: a pregnancy is dated from the Last Menstrual Period (LMP).
/// Due date (EDD) = LMP + 280 days (Naegele's rule).
class PregnancyCalculator {
  const PregnancyCalculator._();

  /// Estimated due date from the last menstrual period.
  static DateTime dueDateFromLmp(DateTime lmp) =>
      _dateOnly(lmp).add(const Duration(days: AppConstants.fullTermDays));

  /// LMP inferred from a known due date.
  static DateTime lmpFromDueDate(DateTime dueDate) =>
      _dateOnly(dueDate).subtract(const Duration(days: AppConstants.fullTermDays));

  /// Completed gestational days on [asOf] (defaults to today). Never negative.
  static int gestationalDays(DateTime lmp, {DateTime? asOf}) {
    final now = _dateOnly(asOf ?? _today());
    final start = _dateOnly(lmp);
    final days = now.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  /// Current gestational week (1-based, clamped to 1..40).
  static int currentWeek(DateTime lmp, {DateTime? asOf}) {
    final week = (gestationalDays(lmp, asOf: asOf) ~/ 7) + 1;
    return week.clamp(1, AppConstants.fullTermWeeks);
  }

  /// Day within the current week, 1..7.
  static int dayOfWeek(DateTime lmp, {DateTime? asOf}) =>
      (gestationalDays(lmp, asOf: asOf) % 7) + 1;

  /// Trimester for a given week. 1–13 first, 14–27 second, 28+ third.
  static Trimester trimesterForWeek(int week) {
    if (week <= 13) return Trimester.first;
    if (week <= 27) return Trimester.second;
    return Trimester.third;
  }

  /// Days remaining until the due date (0 if past due).
  static int daysRemaining(DateTime dueDate, {DateTime? asOf}) {
    final diff = _dateOnly(dueDate).difference(_dateOnly(asOf ?? _today())).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Overall progress 0.0–1.0 through the pregnancy.
  static double progress(DateTime lmp, {DateTime? asOf}) {
    final days = gestationalDays(lmp, asOf: asOf);
    return (days / AppConstants.fullTermDays).clamp(0.0, 1.0);
  }

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
