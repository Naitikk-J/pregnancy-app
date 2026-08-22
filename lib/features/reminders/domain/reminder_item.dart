import 'package:equatable/equatable.dart';

/// A custom personal reminder ("drink water at 4pm", "call the doctor") with an
/// alarm-clock notification. Stored at `pregnancies/{pid}/reminders/{id}`.
class ReminderItem extends Equatable {
  const ReminderItem({
    required this.id,
    required this.title,
    required this.remindAt,
    this.note,
    this.done = false,
    this.repeatDaily = false,
  });

  final String id;
  final String title;
  final DateTime remindAt;
  final String? note;
  final bool done;

  /// When true, the alarm repeats every day at [remindAt]'s time.
  final bool repeatDaily;

  bool get isPast => remindAt.isBefore(DateTime.now());

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'remindAt': remindAt.toUtc().toIso8601String(),
        'note': note,
        'done': done,
        'repeatDaily': repeatDaily,
      };

  factory ReminderItem.fromJson(Map<String, dynamic> json) => ReminderItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? 'Reminder',
        remindAt: DateTime.parse(json['remindAt'] as String).toLocal(),
        note: json['note'] as String?,
        done: json['done'] as bool? ?? false,
        repeatDaily: json['repeatDaily'] as bool? ?? false,
      );

  ReminderItem copyWith({bool? done}) => ReminderItem(
        id: id,
        title: title,
        remindAt: remindAt,
        note: note,
        done: done ?? this.done,
        repeatDaily: repeatDaily,
      );

  @override
  List<Object?> get props => [id, title, remindAt, note, done, repeatDaily];
}
