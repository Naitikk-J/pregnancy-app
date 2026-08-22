import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../../journal/domain/journal_entry.dart';
import '../domain/mood_entry.dart';

final moodCrudProvider = Provider<FirestoreCrud<MoodEntry>?>((ref) {
  final col = pregnancySubcollection(ref, 'moods');
  if (col == null) return null;
  return FirestoreCrud<MoodEntry>(
    collection: col,
    fromJson: MoodEntry.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.dateKey,
    orderByField: 'dateKey',
    descending: true,
  );
});

/// All logged moods (up to a year), newest first.
final moodEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final crud = ref.watch(moodCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 400);
});

/// Moods keyed by yyyy-MM-dd for quick calendar lookup.
final moodByDateProvider = Provider<Map<String, MoodEntry>>((ref) {
  final list = ref.watch(moodEntriesProvider).valueOrNull ?? const [];
  return {for (final m in list) m.dateKey: m};
});

/// Saves (upserts) a day's mood.
final moodActionsProvider = Provider<MoodActions?>((ref) {
  final crud = ref.watch(moodCrudProvider);
  if (crud == null) return null;
  return MoodActions(crud);
});

class MoodActions {
  MoodActions(this._crud);
  final FirestoreCrud<MoodEntry> _crud;

  Future<void> setMood(DateTime day, JournalMood mood, {String? note}) {
    return _crud.upsert(MoodEntry(
      dateKey: MoodEntry.keyFor(day),
      mood: mood,
      note: note,
      loggedAt: DateTime.now(),
    ));
  }

  Future<void> remove(String dateKey) => _crud.delete(dateKey);
}

/// The colour used to tint a mood cell — warm for positive, cool/soft for low.
Color moodColor(JournalMood mood) => switch (mood) {
      JournalMood.great => const Color(0xFF7FC8A0),
      JournalMood.good => const Color(0xFF6FD0C0),
      JournalMood.okay => const Color(0xFFF4B36B),
      JournalMood.low => const Color(0xFFF1857B),
      JournalMood.rough => const Color(0xFFB86B8E),
    };
