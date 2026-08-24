import 'package:flutter/material.dart';

/// Shows a date picker followed by a time picker and returns the combined
/// [DateTime], or `null` if the user cancels either step.
///
/// Used by the health trackers (blood pressure, blood sugar, water) so a reading
/// can be logged for exactly when it was taken instead of always "now".
Future<DateTime?> pickDateTime(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = DateTime.now();
  final base = initial ?? now;
  final date = await showDatePicker(
    context: context,
    initialDate: base.isAfter(lastDate ?? now) ? (lastDate ?? now) : base,
    firstDate: firstDate ?? now.subtract(const Duration(days: 365)),
    lastDate: lastDate ?? now,
  );
  if (date == null || !context.mounted) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(base),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
