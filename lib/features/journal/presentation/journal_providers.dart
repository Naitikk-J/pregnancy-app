import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../domain/journal_entry.dart';

final journalCrudProvider = Provider<FirestoreCrud<JournalEntry>?>((ref) {
  final col = pregnancySubcollection(ref, 'journal');
  if (col == null) return null;
  return FirestoreCrud<JournalEntry>(
    collection: col,
    fromJson: JournalEntry.fromJson,
    toJson: (e) => e.toJson(),
    idOf: (e) => e.id,
    orderByField: 'loggedAt',
    descending: true,
  );
});

/// All journal entries, newest first.
final journalEntriesProvider = StreamProvider<List<JournalEntry>>((ref) {
  final crud = ref.watch(journalCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch(limit: 200);
});
