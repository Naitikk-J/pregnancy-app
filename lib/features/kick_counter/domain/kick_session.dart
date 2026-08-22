import 'package:equatable/equatable.dart';

/// One "count the kicks" session, stored at
/// `pregnancies/{pid}/kick_sessions/{id}`.
///
/// The widely-taught method is to count until you feel [targetKicks] (10)
/// distinct movements and note how long it took — most healthy babies reach 10
/// within ~2 hours. A session records the running tally and, once finished, the
/// elapsed time.
class KickSession extends Equatable {
  const KickSession({
    required this.id,
    required this.startedAt,
    required this.kickCount,
    this.targetKicks = defaultTarget,
    this.endedAt,
    this.note,
  });

  /// Standard target for the "count to 10" method.
  static const int defaultTarget = 10;

  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int kickCount;
  final int targetKicks;
  final String? note;

  bool get isComplete => endedAt != null;
  bool get reachedTarget => kickCount >= targetKicks;

  /// Elapsed time. While the session is live (no [endedAt]) callers pass [now]
  /// so the value ticks; a finished session ignores [now].
  Duration elapsed([DateTime? now]) =>
      (endedAt ?? now ?? DateTime.now()).difference(startedAt);

  KickSession copyWith({
    DateTime? endedAt,
    int? kickCount,
    int? targetKicks,
    String? note,
  }) =>
      KickSession(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt ?? this.endedAt,
        kickCount: kickCount ?? this.kickCount,
        targetKicks: targetKicks ?? this.targetKicks,
        note: note ?? this.note,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'endedAt': endedAt?.toUtc().toIso8601String(),
        'kickCount': kickCount,
        'targetKicks': targetKicks,
        'note': note,
      };

  factory KickSession.fromJson(Map<String, dynamic> json) => KickSession(
        id: json['id'] as String,
        startedAt: DateTime.parse(json['startedAt'] as String),
        endedAt: json['endedAt'] == null
            ? null
            : DateTime.parse(json['endedAt'] as String),
        kickCount: (json['kickCount'] as num?)?.toInt() ?? 0,
        targetKicks:
            (json['targetKicks'] as num?)?.toInt() ?? defaultTarget,
        note: json['note'] as String?,
      );

  @override
  List<Object?> get props =>
      [id, startedAt, endedAt, kickCount, targetKicks, note];
}
