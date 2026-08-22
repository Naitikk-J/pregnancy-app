import 'package:equatable/equatable.dart';

/// How the mother felt for a journal entry.
enum JournalMood {
  great,
  good,
  okay,
  low,
  rough;

  String get emoji => switch (this) {
        JournalMood.great => '😄',
        JournalMood.good => '🙂',
        JournalMood.okay => '😐',
        JournalMood.low => '😕',
        JournalMood.rough => '😣',
      };

  String get label => switch (this) {
        JournalMood.great => 'Great',
        JournalMood.good => 'Good',
        JournalMood.okay => 'Okay',
        JournalMood.low => 'Low',
        JournalMood.rough => 'Rough',
      };

  static JournalMood fromName(String? name) => JournalMood.values.firstWhere(
        (m) => m.name == name,
        orElse: () => JournalMood.okay,
      );
}

/// A pregnancy journal entry, stored at `pregnancies/{pid}/journal/{id}`.
class JournalEntry extends Equatable {
  const JournalEntry({
    required this.id,
    required this.loggedAt,
    required this.text,
    this.mood = JournalMood.okay,
    this.title,
  });

  final String id;
  final DateTime loggedAt;
  final String text;
  final JournalMood mood;
  final String? title;

  Map<String, dynamic> toJson() => {
        'id': id,
        'loggedAt': loggedAt.toUtc().toIso8601String(),
        'text': text,
        'mood': mood.name,
        'title': title,
      };

  factory JournalEntry.fromJson(Map<String, dynamic> json) => JournalEntry(
        id: json['id'] as String,
        loggedAt: DateTime.parse(json['loggedAt'] as String),
        text: json['text'] as String? ?? '',
        mood: JournalMood.fromName(json['mood'] as String?),
        title: json['title'] as String?,
      );

  @override
  List<Object?> get props => [id, loggedAt, text, mood, title];
}
