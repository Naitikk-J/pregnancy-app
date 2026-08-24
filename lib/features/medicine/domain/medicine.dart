import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';

/// Sensible default clock times ("HH:mm") spreading [perDay] doses across the
/// waking day. Used when the user picks "how many times a day".
List<String> defaultDoseTimes(int perDay) {
  switch (perDay) {
    case <= 1:
      return const ['09:00'];
    case 2:
      return const ['09:00', '21:00'];
    case 3:
      return const ['08:00', '14:00', '20:00'];
    case 4:
      return const ['08:00', '12:00', '16:00', '20:00'];
    case 5:
      return const ['08:00', '11:30', '15:00', '18:30', '22:00'];
    default:
      return const ['07:00', '10:30', '13:30', '16:30', '19:30', '22:00'];
  }
}

/// A prescribed medicine, stored at `pregnancies/{pid}/medicines/{id}`.
class Medicine extends Equatable {
  const Medicine({
    required this.id,
    required this.name,
    required this.dosage,
    required this.times,
    required this.startDate,
    this.timing = MedicineTiming.anytime,
    this.endDate,
    this.refillDate,
    this.notes,
    this.active = true,
    this.asNeeded = false,
    this.durationDays,
    this.weekdays = const [],
  });

  final String id;
  final String name;
  final String dosage; // e.g. "1 tablet", "5 ml"
  final MedicineTiming timing;

  /// Times of day to take it, as "HH:mm" 24-hour strings. Empty for SOS meds.
  final List<String> times;

  /// Which weekdays the medicine is taken on, as `DateTime.weekday` values
  /// (1 = Monday … 7 = Sunday). Empty means **every day** (the default). A
  /// subset (e.g. `[1, 4]`) means a weekly schedule (e.g. Mon & Thu only).
  final List<int> weekdays;

  /// True when this med runs on a specific-days-of-week schedule rather than
  /// every day.
  bool get isWeekly => weekdays.isNotEmpty && weekdays.length < 7;

  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? refillDate;
  final String? notes;
  final bool active;

  /// SOS / "take only when needed" — no schedule, no reminders.
  final bool asNeeded;

  /// How many days the course runs (null = ongoing). [endDate] is derived from
  /// this at save time; kept for display ("for 5 days").
  final int? durationDays;

  /// Times taken per day (derived from [times]).
  int get timesPerDay => times.length;

  /// Units taken per single dose, read from the leading number in [dosage]
  /// (e.g. "2 tablets" → 2, "5 ml" → 5). Defaults to 1 when none is given.
  int get unitsPerDose {
    final match = RegExp(r'\d+').firstMatch(dosage);
    final n = match == null ? 1 : int.tryParse(match.group(0)!) ?? 1;
    return n < 1 ? 1 : n;
  }

  /// Total units needed to buy for the whole course (units/dose × doses/day ×
  /// days). Null for SOS meds, ongoing courses, or meds with no schedule.
  int? get courseUnits {
    if (asNeeded || durationDays == null || timesPerDay == 0) return null;
    return unitsPerDose * timesPerDay * durationDays!;
  }

  /// Whole days until the course ends (0 = ends today, negative = already over).
  /// Null for SOS / ongoing meds with no [endDate].
  int? get daysUntilEnd {
    if (asNeeded || endDate == null) return null;
    final today = DateTime.now();
    final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
    return end.difference(DateTime(today.year, today.month, today.day)).inDays;
  }

  /// True when an active course is within [withinDays] of running out — the
  /// signal for a "reorder soon" reminder. Defaults to 3 days.
  bool endingSoon({int withinDays = 3}) {
    final d = daysUntilEnd;
    return active && d != null && d >= 0 && d <= withinDays;
  }

  bool isActiveOn(DateTime day) {
    if (!active) return false;
    final d = DateTime(day.year, day.month, day.day);
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    if (d.isBefore(start)) return false;
    if (endDate != null) {
      final end = DateTime(endDate!.year, endDate!.month, endDate!.day);
      if (d.isAfter(end)) return false;
    }
    // Weekly schedule: only active on the selected weekdays.
    if (weekdays.isNotEmpty && !weekdays.contains(d.weekday)) return false;
    return true;
  }

  bool get needsRefillSoon {
    final r = refillDate;
    if (r == null) return false;
    final days = r.difference(DateTime.now()).inDays;
    return days >= 0 && days <= 3;
  }

  String get timingLabel => switch (timing) {
        MedicineTiming.beforeFood => 'Before food',
        MedicineTiming.afterFood => 'After food',
        MedicineTiming.anytime => 'Anytime',
      };

  Medicine copyWith({bool? active}) => Medicine(
        id: id,
        name: name,
        dosage: dosage,
        times: times,
        startDate: startDate,
        timing: timing,
        endDate: endDate,
        refillDate: refillDate,
        notes: notes,
        active: active ?? this.active,
        asNeeded: asNeeded,
        durationDays: durationDays,
        weekdays: weekdays,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'dosage': dosage,
        'timing': timing.name,
        'times': times,
        'startDate': startDate.toUtc().toIso8601String(),
        'endDate': endDate?.toUtc().toIso8601String(),
        'refillDate': refillDate?.toUtc().toIso8601String(),
        'notes': notes,
        'active': active,
        'asNeeded': asNeeded,
        'durationDays': durationDays,
        'weekdays': weekdays,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
      };

  factory Medicine.fromJson(Map<String, dynamic> json) => Medicine(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        dosage: json['dosage'] as String? ?? '',
        timing: MedicineTiming.values.firstWhere(
          (t) => t.name == json['timing'],
          orElse: () => MedicineTiming.anytime,
        ),
        times: (json['times'] as List<dynamic>?)?.cast<String>() ?? const [],
        startDate: DateTime.parse(
            json['startDate'] as String? ?? DateTime.now().toIso8601String()),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        refillDate: json['refillDate'] != null
            ? DateTime.parse(json['refillDate'] as String)
            : null,
        notes: json['notes'] as String?,
        active: json['active'] as bool? ?? true,
        asNeeded: json['asNeeded'] as bool? ?? false,
        durationDays: (json['durationDays'] as num?)?.toInt(),
        weekdays: (json['weekdays'] as List<dynamic>?)
                ?.map((e) => (e as num).toInt())
                .toList() ??
            const [],
      );

  @override
  List<Object?> get props =>
      [id, name, dosage, timing, times, active, asNeeded, durationDays, weekdays];
}

/// A record that a specific dose (medicine + date + time) was taken/skipped.
/// Doc id: `${medicineId}_${yyyyMMdd}_${hhmm}` so it's idempotent per dose.
class MedicineLog extends Equatable {
  const MedicineLog({
    required this.id,
    required this.medicineId,
    required this.dateKey,
    required this.time,
    required this.status,
    this.takenAt,
  });

  final String id;
  final String medicineId;
  final String dateKey; // yyyy-MM-dd
  final String time; // HH:mm
  final DoseStatus status;
  final DateTime? takenAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'medicineId': medicineId,
        'dateKey': dateKey,
        'time': time,
        'status': status.name,
        'takenAt': takenAt?.toUtc().toIso8601String(),
      };

  factory MedicineLog.fromJson(Map<String, dynamic> json) => MedicineLog(
        id: json['id'] as String,
        medicineId: json['medicineId'] as String? ?? '',
        dateKey: json['dateKey'] as String? ?? '',
        time: json['time'] as String? ?? '',
        status: DoseStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => DoseStatus.pending,
        ),
        takenAt: json['takenAt'] != null
            ? DateTime.parse(json['takenAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, status];
}
