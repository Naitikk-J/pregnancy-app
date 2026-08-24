import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/data/firestore_crud.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/id_utils.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/vaccine.dart';

final vaccineCrudProvider = Provider<FirestoreCrud<Vaccine>?>((ref) {
  final col = pregnancySubcollection(ref, 'vaccinations');
  if (col == null) return null;
  return FirestoreCrud<Vaccine>(
    collection: col,
    fromJson: Vaccine.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
  );
});

/// Stored vaccine records (catalog statuses the mother has changed, plus any
/// custom vaccines she added).
final storedVaccinesProvider = StreamProvider<List<Vaccine>>((ref) {
  final crud = ref.watch(vaccineCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// The default catalog with each mother's stored status merged in, followed by
/// any custom vaccines she added (those with an id not in the catalog).
final vaccineListProvider = Provider<List<Vaccine>>((ref) {
  final stored = ref.watch(storedVaccinesProvider).valueOrNull ?? const [];
  final byId = {for (final v in stored) v.id: v};
  final catalogIds = {for (final v in kDefaultVaccines) v.id};
  final merged = [for (final v in kDefaultVaccines) byId[v.id] ?? v];
  // Append custom vaccines (stored, but not part of the built-in catalog).
  final custom = stored.where((v) => !catalogIds.contains(v.id)).toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return [...merged, ...custom];
});

/// True when [id] is a user-added custom vaccine (not one of the built-ins).
bool isCustomVaccine(String id) =>
    !kDefaultVaccines.any((v) => v.id == id);

final vaccineActionsProvider = Provider<VaccineActions?>((ref) {
  final crud = ref.watch(vaccineCrudProvider);
  if (crud == null) return null;
  return VaccineActions(crud, ref.watch(notificationServiceProvider));
});

/// Persists vaccine changes and schedules an on-device reminder for the day a
/// vaccine is scheduled, so a booked shot actually alarms.
class VaccineActions {
  VaccineActions(this._crud, this._notifications);

  final FirestoreCrud<Vaccine> _crud;
  final NotificationService _notifications;

  int _notifId(String id) => IdUtils.stableNotificationId('vaccine_$id');

  Future<void> save(Vaccine v) async {
    await _crud.upsert(v);
    // Reminders are best-effort — never let a blocked permission fail the save.
    try {
      await _notifications.cancel(_notifId(v.id));
      if (v.status == VaccineStatus.scheduled && v.scheduledDate != null) {
        await _notifications.requestPermissions();
        final d = v.scheduledDate!;
        final when = DateTime(d.year, d.month, d.day, 9, 0);
        if (when.isAfter(DateTime.now())) {
          await _notifications.scheduleAt(
            id: _notifId(v.id),
            title: '💉 ${v.name}',
            body: 'Vaccination scheduled for today — confirm timing with your '
                'doctor.',
            when: when,
          );
        }
      }
    } catch (_) {
      // Ignore — the vaccine record is saved regardless.
    }
  }

  Future<void> delete(Vaccine v) async {
    await _notifications.cancel(_notifId(v.id));
    await _crud.delete(v.id);
  }
}
