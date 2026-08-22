import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Handles **local** notifications: medicine alarms, water reminders, appointment
/// alerts. These fire on-device and work fully offline (a core requirement).
///
/// Medicine reminders are alarm-style, full-screen heads-up notifications with
/// two action buttons — "Taken" and "Snooze 10m". Because the tap can arrive
/// while the app is backgrounded/killed, actions are handled in a top-level
/// handler that records "taken" doses to a small pending queue (SharedPreferences)
/// reconciled to Firestore on next app open, and reschedules snoozes directly.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Prefs key: pending "taken" doses as "medId|HH:mm|yyyy-MM-dd" strings.
  static const String pendingTakenKey = 'pending_taken_doses';
  static const String _tzNameKey = 'device_tz_name';
  static const String takenActionId = 'MED_TAKEN';
  static const String snoozeActionId = 'MED_SNOOZE';
  static const Duration snoozeFor = Duration(minutes: 10);

  static const AndroidNotificationChannel medicineChannel =
      AndroidNotificationChannel(
    'medicine_reminders',
    'Medicine reminders',
    description: 'Alarms for your scheduled medicines',
    importance: Importance.max,
  );

  static const AndroidNotificationChannel generalChannel =
      AndroidNotificationChannel(
    'general_reminders',
    'Water, appointments and other reminders',
    description: 'Water, appointments and other reminders',
    importance: Importance.high,
  );

  static const List<AndroidNotificationAction> _medicineActions = [
    AndroidNotificationAction(takenActionId, 'Taken',
        showsUserInterface: false, cancelNotification: true),
    AndroidNotificationAction(snoozeActionId, 'Snooze 10m',
        showsUserInterface: false, cancelNotification: true),
  ];

  Future<void> init() async {
    tz.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: notificationResponseHandler,
      onDidReceiveBackgroundNotificationResponse: notificationResponseHandler,
    );

    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(medicineChannel);
    await android?.createNotificationChannel(generalChannel);
  }

  /// Resolve and set the device's time zone so scheduled reminders fire at the
  /// correct local wall-clock time (the tz package otherwise defaults to UTC).
  /// Matches the device's current UTC offset against the tz database — no extra
  /// dependency needed, and the offset is what matters for scheduling.
  Future<void> _configureLocalTimeZone() async {
    try {
      final name = localTimeZoneName();
      if (name == null) return;
      tz.setLocalLocation(tz.getLocation(name));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tzNameKey, name);
    } catch (e) {
      if (kDebugMode) debugPrint('[notify] tz resolve failed: $e');
    }
  }

  /// Ask the user for notification permission (Android 13+, iOS), plus the
  /// exact-alarm and full-screen-intent special permissions that alarm-style
  /// medicine reminders need on Android 14+.
  Future<bool> requestPermissions() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    // Exact alarms so reminders fire at the precise time (Android 12+).
    try {
      await android?.requestExactAlarmsPermission();
    } catch (_) {}
    // Full-screen heads-up alarm reminders (Android 14+ gates this separately).
    try {
      await android?.requestFullScreenIntentPermission();
    } catch (_) {}

    final ios =
        _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    return androidGranted && iosGranted;
  }

  /// A snapshot of the notification/alarm readiness on this device, so the UI
  /// can tell the user exactly what (if anything) is blocking reminders.
  Future<NotificationStatus> status() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    bool enabled = true;
    bool exact = true;
    if (android != null) {
      enabled = await android.areNotificationsEnabled() ?? true;
      exact = await android.canScheduleExactNotifications() ?? true;
    }
    int pending = 0;
    try {
      pending = (await _plugin.pendingNotificationRequests()).length;
    } catch (_) {}
    return NotificationStatus(
      notificationsEnabled: enabled,
      exactAlarmsAllowed: exact,
      pendingCount: pending,
    );
  }

  /// Schedule a one-off notification at [when].
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    bool isMedicine = false,
    String? payload,
  }) async {
    if (when.isBefore(DateTime.now())) return;
    await _zonedScheduleSafe(
      id: id,
      title: title,
      body: body,
      when: tz.TZDateTime.from(when, tz.local),
      details: _details(isMedicine),
      payload: payload,
    );
  }

  /// Schedule a notification that repeats every day at the given time.
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    bool isMedicine = false,
    String? payload,
  }) async {
    await _zonedScheduleSafe(
      id: id,
      title: title,
      body: body,
      when: _nextInstanceOf(hour, minute),
      details: _details(isMedicine),
      matchComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Schedules via [zonedSchedule], preferring an exact alarm but **falling back
  /// to an inexact one** if the OS refuses exact alarms (Android 12+ can revoke
  /// the special permission). Without this fallback a denied exact-alarm
  /// permission makes `zonedSchedule` throw and the reminder is silently lost —
  /// the most common cause of "reminders never fire".
  Future<void> _zonedScheduleSafe({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required NotificationDetails details,
    DateTimeComponents? matchComponents,
    String? payload,
  }) async {
    Future<void> run(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: matchComponents,
          payload: payload,
        );
    try {
      await run(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        if (kDebugMode) {
          debugPrint('[notify] exact alarms denied — using inexact for $id');
        }
        await run(AndroidScheduleMode.inexactAllowWhileIdle);
      } else {
        rethrow;
      }
    }
  }

  /// Show a notification immediately (used to surface foreground FCM messages).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    bool isMedicine = false,
    String? payload,
  }) =>
      _plugin.show(id, title, body, _details(isMedicine), payload: payload);

  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationDetails _details(bool isMedicine) {
    final channel = isMedicine ? medicineChannel : generalChannel;
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: Priority.high,
        category: isMedicine
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        fullScreenIntent: isMedicine,
        actions: isMedicine ? _medicineActions : null,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    if (kDebugMode) debugPrint('[notify] daily -> $scheduled');
    return scheduled;
  }
}

/// Readiness of on-device reminders, surfaced to the user so they can fix a
/// blocked setting instead of silently getting no alarms.
class NotificationStatus {
  const NotificationStatus({
    required this.notificationsEnabled,
    required this.exactAlarmsAllowed,
    required this.pendingCount,
  });

  final bool notificationsEnabled;
  final bool exactAlarmsAllowed;
  final int pendingCount;

  /// True when reminders should be able to fire (permission granted). Exact
  /// alarms are a nice-to-have — we fall back to inexact — so they don't gate
  /// this.
  bool get ready => notificationsEnabled;
}

/// Handles a tap on a medicine reminder's action buttons. Runs in the foreground
/// isolate when the app is alive and in a background isolate otherwise, so it
/// must be a top-level, entry-point function and self-contained.
///
/// Payload format for medicine reminders: `MED|medicineId|HH:mm`.
@pragma('vm:entry-point')
void notificationResponseHandler(NotificationResponse response) {
  final payload = response.payload ?? '';
  if (!payload.startsWith('MED|')) return;
  final parts = payload.split('|');
  if (parts.length < 3) return;
  final medId = parts[1];
  final time = parts[2];

  switch (response.actionId) {
    case NotificationService.takenActionId:
      _recordPendingTaken(medId, time);
      break;
    case NotificationService.snoozeActionId:
      _scheduleSnooze(medId, time);
      break;
  }
}

/// Finds an IANA timezone name whose current UTC offset matches this device's,
/// using the tz database already loaded via `initializeTimeZones()`. Returns
/// null if none matches (caller keeps the UTC default).
String? localTimeZoneName() {
  final ms = DateTime.now().timeZoneOffset.inMilliseconds;
  // Prefer India first (this is an India-first app), then any offset match.
  const preferred = ['Asia/Kolkata'];
  for (final name in preferred) {
    try {
      if (tz.getLocation(name).currentTimeZone.offset == ms) return name;
    } catch (_) {}
  }
  for (final entry in tz.timeZoneDatabase.locations.entries) {
    if (entry.value.currentTimeZone.offset == ms) return entry.key;
  }
  return null;
}

String _dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Future<void> _recordPendingTaken(String medId, String time) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(NotificationService.pendingTakenKey) ?? [];
    final entry = '$medId|$time|${_dateKey(DateTime.now())}';
    if (!list.contains(entry)) {
      list.add(entry);
      await prefs.setStringList(NotificationService.pendingTakenKey, list);
    }
  } catch (_) {
    // Best-effort; the user can also mark it in-app.
  }
}

Future<void> _scheduleSnooze(String medId, String time) async {
  try {
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );

    tz.initializeTimeZones();
    final tzName = localTimeZoneName();
    if (tzName != null) {
      try {
        tz.setLocalLocation(tz.getLocation(tzName));
      } catch (_) {}
    }

    final when = tz.TZDateTime.now(tz.local).add(NotificationService.snoozeFor);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        NotificationService.medicineChannel.id,
        NotificationService.medicineChannel.name,
        channelDescription: NotificationService.medicineChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        category: AndroidNotificationCategory.alarm,
        fullScreenIntent: true,
        actions: const [
          AndroidNotificationAction(NotificationService.takenActionId, 'Taken',
              showsUserInterface: false, cancelNotification: true),
          AndroidNotificationAction(
              NotificationService.snoozeActionId, 'Snooze 10m',
              showsUserInterface: false, cancelNotification: true),
        ],
      ),
    );
    Future<void> run(AndroidScheduleMode mode) => plugin.zonedSchedule(
          medId.hashCode & 0x7fffffff,
          'Medicine reminder (snoozed)',
          'Time for your medicine.',
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: 'MED|$medId|$time',
        );
    try {
      await run(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code == 'exact_alarms_not_permitted') {
        await run(AndroidScheduleMode.inexactAllowWhileIdle);
      } else {
        rethrow;
      }
    }
  } catch (_) {
    // Best-effort snooze.
  }
}
