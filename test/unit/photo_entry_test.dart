import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/memories/domain/photo_entry.dart';

void main() {
  group('PhotoEntry', () {
    test('round-trips through JSON with all fields', () {
      final entry = PhotoEntry(
        id: 'abc',
        path: '/data/mem_abc.jpg',
        takenAt: DateTime(2026, 3, 14, 9, 30),
        week: 22,
        note: 'First real bump!',
      );

      final restored = PhotoEntry.fromJson(entry.toJson());

      expect(restored.id, entry.id);
      expect(restored.path, entry.path);
      expect(restored.takenAt, entry.takenAt);
      expect(restored.week, 22);
      expect(restored.note, 'First real bump!');
    });

    test('omits null optional fields in JSON', () {
      final entry = PhotoEntry(
        id: 'x',
        path: '/p.jpg',
        takenAt: DateTime(2026, 1, 1),
      );
      final json = entry.toJson();
      expect(json.containsKey('week'), isFalse);
      expect(json.containsKey('note'), isFalse);

      final restored = PhotoEntry.fromJson(json);
      expect(restored.week, isNull);
      expect(restored.note, isNull);
    });

    test('copyWith overrides week and note', () {
      final entry = PhotoEntry(
        id: 'x',
        path: '/p.jpg',
        takenAt: DateTime(2026, 1, 1),
      );
      final updated = entry.copyWith(week: 30, note: 'later');
      expect(updated.week, 30);
      expect(updated.note, 'later');
      expect(updated.id, 'x');
      expect(updated.takenAt, entry.takenAt);
    });

    test('tolerates a malformed takenAt string', () {
      final restored = PhotoEntry.fromJson({
        'id': 'x',
        'path': '/p.jpg',
        'takenAt': 'not-a-date',
      });
      expect(restored.takenAt, DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
