import 'package:equatable/equatable.dart';

import '../../journal/domain/journal_entry.dart';

/// A single day's mood, stored at `pregnancies/{pid}/moods/{yyyy-MM-dd}` — one
/// document per day (the id is the date key), so setting a mood upserts. Reuses
/// [JournalMood] so moods are consistent across the journal and the calendar.
class MoodEntry extends Equatable {
  const MoodEntry({
    required this.dateKey,
    required this.mood,
    this.note,
    this.loggedAt,
  });

  /// yyyy-MM-dd — also the Firestore document id.
  final String dateKey;
  final JournalMood mood;
  final String? note;
  final DateTime? loggedAt;

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() => {
        'id': dateKey,
        'dateKey': dateKey,
        'mood': mood.name,
        'note': note,
        'loggedAt': (loggedAt ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory MoodEntry.fromJson(Map<String, dynamic> json) => MoodEntry(
        dateKey: (json['dateKey'] ?? json['id']) as String,
        mood: JournalMood.fromName(json['mood'] as String?),
        note: json['note'] as String?,
        loggedAt: json['loggedAt'] == null
            ? null
            : DateTime.tryParse(json['loggedAt'] as String),
      );

  MoodEntry copyWith({JournalMood? mood, String? note}) => MoodEntry(
        dateKey: dateKey,
        mood: mood ?? this.mood,
        note: note ?? this.note,
        loggedAt: loggedAt,
      );

  @override
  List<Object?> get props => [dateKey, mood, note];
}
