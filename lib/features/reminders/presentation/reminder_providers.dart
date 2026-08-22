import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../core/di/providers.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/id_utils.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/reminder_item.dart';

final reminderCrudProvider = Provider<FirestoreCrud<ReminderItem>?>((ref) {
  final col = pregnancySubcollection(ref, 'reminders');
  if (col == null) return null;
  return FirestoreCrud<ReminderItem>(
    collection: col,
    fromJson: ReminderItem.fromJson,
    toJson: (r) => r.toJson(),
    idOf: (r) => r.id,
    orderByField: 'remindAt',
  );
});

/// All reminders, soonest first.
final remindersProvider = StreamProvider<List<ReminderItem>>((ref) {
  final crud = ref.watch(reminderCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 100);
});

/// Upcoming (not done, not past) reminders for the home card — soonest first.
final upcomingRemindersProvider = Provider<List<ReminderItem>>((ref) {
  final all = ref.watch(remindersProvider).valueOrNull ?? const [];
  final list = all
      .where((r) => !r.done && (!r.isPast || r.repeatDaily))
      .toList()
    ..sort((a, b) => a.remindAt.compareTo(b.remindAt));
  return list;
});

final reminderActionsProvider = Provider<ReminderActions?>((ref) {
  final crud = ref.watch(reminderCrudProvider);
  if (crud == null) return null;
  return ReminderActions(crud, ref.watch(notificationServiceProvider));
});

class ReminderActions {
  ReminderActions(this._crud, this._notifications);
  final FirestoreCrud<ReminderItem> _crud;
  final NotificationService _notifications;

  int _notifId(String id) => IdUtils.stableNotificationId('reminder_$id');

  /// Saves the reminder and (re)schedules its alarm notification.
  Future<void> save(ReminderItem r) async {
    await _crud.upsert(r);
    await _notifications.requestPermissions();
    await _notifications.cancel(_notifId(r.id));
    if (r.done) return;
    final body = (r.note != null && r.note!.trim().isNotEmpty)
        ? r.note!.trim()
        : 'Tap to open Pregnancy Companion.';
    if (r.repeatDaily) {
      await _notifications.scheduleDaily(
        id: _notifId(r.id),
        title: '⏰ ${r.title}',
        body: body,
        hour: r.remindAt.hour,
        minute: r.remindAt.minute,
      );
    } else if (r.remindAt.isAfter(DateTime.now())) {
      await _notifications.scheduleAt(
        id: _notifId(r.id),
        title: '⏰ ${r.title}',
        body: body,
        when: r.remindAt,
      );
    }
  }

  Future<void> toggleDone(ReminderItem r) async {
    final updated = r.copyWith(done: !r.done);
    await _crud.upsert(updated);
    if (updated.done) {
      await _notifications.cancel(_notifId(r.id));
    } else {
      await save(updated);
    }
  }

  Future<void> delete(ReminderItem r) async {
    await _notifications.cancel(_notifId(r.id));
    await _crud.delete(r.id);
  }
}
