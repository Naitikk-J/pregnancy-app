import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/enums.dart';
import '../../../core/data/firestore_crud.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/id_utils.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/medicine.dart';

// ---------------------------------------------------------------------------
// Data providers
// ---------------------------------------------------------------------------

final medicineCrudProvider = Provider<FirestoreCrud<Medicine>?>((ref) {
  final col = pregnancySubcollection(ref, 'medicines');
  if (col == null) return null;
  return FirestoreCrud<Medicine>(
    collection: col,
    fromJson: Medicine.fromJson,
    toJson: (m) => m.toJson(),
    idOf: (m) => m.id,
    orderByField: 'createdAt',
    descending: true,
  );
});

final medicinesProvider = StreamProvider<List<Medicine>>((ref) {
  final crud = ref.watch(medicineCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

final _logsCollectionProvider =
    Provider<CollectionReference<Map<String, dynamic>>?>((ref) {
  return pregnancySubcollection(ref, 'medicineLogs');
});

/// Today's dose logs, keyed by "${medicineId}_${time}".
final todayLogsProvider = StreamProvider<Map<String, MedicineLog>>((ref) {
  final col = ref.watch(_logsCollectionProvider);
  if (col == null) return Stream.value(const {});
  final key = IdUtils.dateKey(DateTime.now());
  return col.where('dateKey', isEqualTo: key).snapshots().map((snap) {
    final map = <String, MedicineLog>{};
    for (final doc in snap.docs) {
      final log = MedicineLog.fromJson({...doc.data(), 'id': doc.id});
      map['${log.medicineId}_${log.time}'] = log;
    }
    return map;
  });
});

/// A single scheduled dose for today, with its current status.
class DoseView {
  const DoseView({required this.medicine, required this.time, required this.status});
  final Medicine medicine;
  final String time;
  final DoseStatus status;
}

/// All of today's doses across active medicines, sorted by time.
final todayDosesProvider = Provider<List<DoseView>>((ref) {
  final meds = ref.watch(medicinesProvider).valueOrNull ?? const [];
  final logs = ref.watch(todayLogsProvider).valueOrNull ?? const {};
  final today = DateTime.now();

  final doses = <DoseView>[];
  for (final med in meds) {
    if (!med.isActiveOn(today)) continue;
    for (final time in med.times) {
      final status = logs['${med.id}_$time']?.status ?? DoseStatus.pending;
      doses.add(DoseView(medicine: med, time: time, status: status));
    }
  }
  doses.sort((a, b) => a.time.compareTo(b.time));
  return doses;
});

/// How many of today's doses are taken (for the dashboard summary).
final todayAdherenceProvider = Provider<({int taken, int total})>((ref) {
  final doses = ref.watch(todayDosesProvider);
  final taken = doses.where((d) => d.status == DoseStatus.taken).length;
  return (taken: taken, total: doses.length);
});

// ---------------------------------------------------------------------------
// Actions (persistence + notifications)
// ---------------------------------------------------------------------------

class MedicineActions {
  MedicineActions(this._crud, this._logsCol, this._notifications);

  final FirestoreCrud<Medicine> _crud;
  final CollectionReference<Map<String, dynamic>> _logsCol;
  final NotificationService _notifications;

  /// How many days before a course ends to remind the user to reorder.
  static const int endReminderDaysBefore = 2;

  int _notifId(String medId, String time) =>
      IdUtils.stableNotificationId('med_${medId}_$time');

  int _weeklyNotifId(String medId, int weekday, String time) =>
      IdUtils.stableNotificationId('med_${medId}_${weekday}_$time');

  int _endNotifId(String medId) =>
      IdUtils.stableNotificationId('medend_$medId');

  /// Cancels every possible alarm id for one medicine at [time] — both the daily
  /// id and all seven weekday ids — so switching between daily and weekly (or
  /// changing the chosen days) never leaves an orphan alarm firing.
  Future<void> _cancelForTime(String medId, String time) async {
    await _notifications.cancel(_notifId(medId, time));
    for (var wd = 1; wd <= 7; wd++) {
      await _notifications.cancel(_weeklyNotifId(medId, wd, time));
    }
  }

  Future<void> save(Medicine med, {List<String> previousTimes = const []}) async {
    // Saving the medicine is the primary action and must succeed on its own.
    await _crud.upsert(med);
    // Reminders are best-effort: a blocked notification/exact-alarm permission
    // must never make "save medicine" fail (this was a real bug — the med was
    // written but the reminder call threw, so the UI reported failure).
    try {
      // Clear alarms for every time we've ever used for this med (old + new),
      // across both the daily and weekly schemes, then reschedule fresh.
      for (final time in {...previousTimes, ...med.times}) {
        await _cancelForTime(med.id, time);
      }
      await _scheduleReminders(med);
    } catch (_) {
      // Ignore — the medicine is saved; reminders can be re-registered later
      // (rescheduleAll runs on the Medicines screen open).
    }
  }

  /// (Re)schedules the dose alarms and the "course ending soon" reminder for one
  /// medicine. Handles both every-day and specific-weekday schedules. Idempotent
  /// — cancels before scheduling.
  Future<void> _scheduleReminders(Medicine med) async {
    for (final time in med.times) {
      await _cancelForTime(med.id, time);
      if (!med.active) continue;
      final parts = time.split(':');
      final hour = int.tryParse(parts.first) ?? 9;
      final minute = int.tryParse(parts.last) ?? 0;

      if (med.weekdays.isEmpty) {
        // Every day.
        await _notifications.scheduleDaily(
          id: _notifId(med.id, time),
          title: 'Time for ${med.name}',
          body: '${med.dosage} · ${med.timingLabel}',
          hour: hour,
          minute: minute,
          isMedicine: true,
          payload: 'MED|${med.id}|$time',
        );
      } else {
        // Specific weekdays only.
        for (final wd in med.weekdays) {
          await _notifications.scheduleWeekly(
            id: _weeklyNotifId(med.id, wd, time),
            title: 'Time for ${med.name}',
            body: '${med.dosage} · ${med.timingLabel}',
            weekday: wd,
            hour: hour,
            minute: minute,
            isMedicine: true,
            payload: 'MED|${med.id}|$time',
          );
        }
      }
    }

    // "Course ending soon" reminder, a few days before the end date.
    final endId = _endNotifId(med.id);
    await _notifications.cancel(endId);
    final end = med.endDate;
    if (med.active && !med.asNeeded && end != null) {
      final remindOn = DateTime(end.year, end.month, end.day,
              9, 0)
          .subtract(const Duration(days: endReminderDaysBefore));
      if (remindOn.isAfter(DateTime.now())) {
        final left = med.courseUnits;
        await _notifications.scheduleAt(
          id: endId,
          title: '${med.name} is running low',
          body: left != null
              ? 'Your course ends in $endReminderDaysBefore days — buy about '
                  '$left more to continue.'
              : 'Your course ends in $endReminderDaysBefore days — reorder soon.',
          when: remindOn,
          isMedicine: false,
        );
      }
    }
  }

  /// Re-registers reminders for all active medicines. Call on app/screen open so
  /// alarms survive a reboot or reinstall (the OS drops scheduled alarms then).
  Future<void> rescheduleAll(List<Medicine> meds) async {
    for (final med in meds) {
      await _scheduleReminders(med);
    }
  }

  /// Shows a test alarm **immediately** (bypassing scheduling) *and* schedules
  /// one ~8 seconds out. The instant one proves notifications aren't blocked;
  /// the delayed one proves the OS delivers scheduled alarms. If only the first
  /// appears, the problem is exact-alarm/battery settings, not permissions.
  Future<void> sendTestReminder() async {
    await _notifications.show(
      id: IdUtils.stableNotificationId('med_test_now'),
      title: 'Test alarm (now) ⏰',
      body: 'Notifications work! Waiting for the scheduled one in ~8 seconds…',
      isMedicine: true,
      payload: 'TEST',
    );
    await _notifications.scheduleAt(
      id: IdUtils.stableNotificationId('med_test'),
      title: 'Test reminder (scheduled) ⏰',
      body: 'If you see this too, scheduled medicine alarms work on your phone.',
      when: DateTime.now().add(const Duration(seconds: 8)),
      isMedicine: true,
      payload: 'TEST',
    );
  }

  Future<void> setActive(Medicine med, bool active) =>
      save(med.copyWith(active: active), previousTimes: med.times);

  Future<void> delete(Medicine med) async {
    await _crud.delete(med.id);
    for (final time in med.times) {
      await _cancelForTime(med.id, time);
    }
    await _notifications.cancel(_endNotifId(med.id));
  }

  /// Log a taken dose for an SOS / as-needed medicine at the current time.
  Future<void> logAsNeededDose(Medicine med) {
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    return markDose(med, time, DoseStatus.taken);
  }

  Future<void> markDose(Medicine med, String time, DoseStatus status) =>
      markDoseRaw(med.id, time, IdUtils.dateKey(DateTime.now()), status);

  /// Write a dose log directly from ids (used by the notification action
  /// reconciler, which only has the medicine id + time + date).
  Future<void> markDoseRaw(
    String medicineId,
    String time,
    String dateKey,
    DoseStatus status,
  ) {
    final logId =
        '${medicineId}_${dateKey.replaceAll('-', '')}_${time.replaceAll(':', '')}';
    final log = MedicineLog(
      id: logId,
      medicineId: medicineId,
      dateKey: dateKey,
      time: time,
      status: status,
      takenAt: status == DoseStatus.taken ? DateTime.now() : null,
    );
    return _logsCol.doc(logId).set(log.toJson());
  }

  /// Flush "Taken" taps that were recorded (in a background isolate) while the
  /// app was closed, writing them as dose logs. Safe to call repeatedly.
  Future<void> reconcilePendingTaken() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(NotificationService.pendingTakenKey) ?? [];
    if (list.isEmpty) return;
    for (final e in list) {
      final p = e.split('|');
      if (p.length < 3) continue;
      try {
        await markDoseRaw(p[0], p[1], p[2], DoseStatus.taken);
      } catch (_) {
        // Leave for a later attempt if the write fails.
      }
    }
    await prefs.remove(NotificationService.pendingTakenKey);
  }
}

/// Fires once when watched to flush any pending "Taken" notification taps.
final pendingDoseReconcileProvider = FutureProvider<void>((ref) async {
  await ref.read(medicineActionsProvider)?.reconcilePendingTaken();
});

/// Re-registers OS reminders for all current medicines whenever the list is
/// available. Keeps alarms alive after a device reboot or app reinstall, which
/// clear scheduled alarms. Idempotent (cancel + reschedule).
final medicineRescheduleProvider = FutureProvider<void>((ref) async {
  final meds = ref.watch(medicinesProvider).valueOrNull;
  if (meds == null || meds.isEmpty) return;
  await ref.read(medicineActionsProvider)?.rescheduleAll(meds);
});

final medicineActionsProvider = Provider<MedicineActions?>((ref) {
  final crud = ref.watch(medicineCrudProvider);
  final logsCol = ref.watch(_logsCollectionProvider);
  if (crud == null || logsCol == null) return null;
  return MedicineActions(
      crud, logsCol, ref.watch(notificationServiceProvider));
});
