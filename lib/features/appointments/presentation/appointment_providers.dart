import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/id_utils.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/appointment.dart';

final appointmentCrudProvider = Provider<FirestoreCrud<Appointment>?>((ref) {
  final col = pregnancySubcollection(ref, 'appointments');
  if (col == null) return null;
  return FirestoreCrud<Appointment>(
    collection: col,
    fromJson: Appointment.fromJson,
    toJson: (a) => a.toJson(),
    idOf: (a) => a.id,
    orderByField: 'dateTime',
    descending: false,
  );
});

final appointmentsProvider = StreamProvider<List<Appointment>>((ref) {
  final crud = ref.watch(appointmentCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// Combines persistence with local-notification scheduling so saving an
/// appointment also schedules (and deleting cancels) its reminder.
class AppointmentActions {
  AppointmentActions(this._crud, this._notifications);

  final FirestoreCrud<Appointment> _crud;
  final NotificationService _notifications;

  int _notifId(String id) => IdUtils.stableNotificationId('appt_$id');

  Future<void> save(Appointment appt) async {
    await _crud.upsert(appt);
    final id = _notifId(appt.id);
    await _notifications.cancel(id);
    if (appt.isUpcoming) {
      await _notifications.scheduleAt(
        id: id,
        title: 'Appointment: ${appt.title}',
        body: appt.doctorName != null
            ? 'With ${appt.doctorName} — tap for details.'
            : 'Coming up soon — tap for details.',
        when: appt.reminderTime,
      );
    }
  }

  Future<void> delete(String id) async {
    await _crud.delete(id);
    await _notifications.cancel(_notifId(id));
  }

  Future<void> setStatus(Appointment appt, String status) =>
      save(appt.copyWith(status: status));
}

final appointmentActionsProvider = Provider<AppointmentActions?>((ref) {
  final crud = ref.watch(appointmentCrudProvider);
  if (crud == null) return null;
  return AppointmentActions(crud, ref.watch(notificationServiceProvider));
});
