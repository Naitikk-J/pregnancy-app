import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/utils/duration_format.dart';
import 'package:pregnancy_companion/features/contractions/domain/contraction.dart';
import 'package:pregnancy_companion/features/contractions/domain/contraction_analysis.dart';
import 'package:pregnancy_companion/features/kick_counter/domain/kick_session.dart';
import 'package:pregnancy_companion/features/reports/domain/report_builder.dart';

void main() {
  group('DurationFormat', () {
    test('clock formats mm:ss and h:mm:ss', () {
      expect(DurationFormat.clock(const Duration(seconds: 5)), '00:05');
      expect(DurationFormat.clock(const Duration(minutes: 1, seconds: 23)),
          '01:23');
      expect(
          DurationFormat.clock(
              const Duration(hours: 1, minutes: 2, seconds: 3)),
          '1:02:03');
    });

    test('compact drops zero units', () {
      expect(DurationFormat.compact(const Duration(seconds: 45)), '45s');
      expect(DurationFormat.compact(const Duration(minutes: 4, seconds: 30)),
          '4m 30s');
      expect(DurationFormat.compact(const Duration(minutes: 30)), '30m');
      expect(DurationFormat.compact(const Duration(hours: 1, minutes: 5)),
          '1h 5m');
    });
  });

  group('KickSession', () {
    test('elapsed uses endedAt when complete', () {
      final s = KickSession(
        id: 'k1',
        startedAt: DateTime(2026, 1, 1, 10, 0),
        endedAt: DateTime(2026, 1, 1, 10, 30),
        kickCount: 10,
      );
      expect(s.elapsed(), const Duration(minutes: 30));
      expect(s.isComplete, isTrue);
      expect(s.reachedTarget, isTrue);
    });

    test('reachedTarget respects the target', () {
      final s = KickSession(
        id: 'k2',
        startedAt: DateTime(2026, 1, 1),
        kickCount: 7,
        targetKicks: 10,
      );
      expect(s.reachedTarget, isFalse);
      expect(s.copyWith(kickCount: 10).reachedTarget, isTrue);
    });

    test('round-trips through JSON', () {
      final s = KickSession(
        id: 'k3',
        startedAt: DateTime.utc(2026, 2, 2, 8),
        endedAt: DateTime.utc(2026, 2, 2, 9),
        kickCount: 10,
        targetKicks: 10,
        note: 'evening',
      );
      final restored = KickSession.fromJson(s.toJson());
      expect(restored, s);
    });
  });

  group('Contraction', () {
    test('duration uses endedAt when complete', () {
      final c = Contraction(
        id: 'c1',
        startedAt: DateTime(2026, 1, 1, 10, 0, 0),
        endedAt: DateTime(2026, 1, 1, 10, 1, 0),
      );
      expect(c.duration(), const Duration(minutes: 1));
      expect(c.isComplete, isTrue);
    });

    test('round-trips through JSON', () {
      final c = Contraction(
        id: 'c2',
        startedAt: DateTime.utc(2026, 3, 3, 3),
        endedAt: DateTime.utc(2026, 3, 3, 3, 1),
      );
      expect(Contraction.fromJson(c.toJson()), c);
    });
  });

  group('ContractionAnalyzer 5-1-1', () {
    // Builds an hour of contractions 5 min apart, each lasting [durationSec].
    List<Contraction> pattern(DateTime end, {int durationSec = 60}) {
      final list = <Contraction>[];
      // 13 contractions ending at [end], one every 5 minutes -> 60 min span.
      for (var i = 0; i < 13; i++) {
        final start = end.subtract(Duration(minutes: 5 * i));
        list.add(Contraction(
          id: 'c$i',
          startedAt: start,
          endedAt: start.add(Duration(seconds: durationSec)),
        ));
      }
      return list;
    }

    test('meets rule with 5-min intervals, 1-min length, over an hour', () {
      final now = DateTime(2026, 6, 1, 12, 0);
      final analysis =
          ContractionAnalyzer.analyze(pattern(now), asOf: now);
      expect(analysis.meets511, isTrue);
      expect(analysis.recentCount, 13);
      expect(analysis.averageInterval, const Duration(minutes: 5));
      expect(analysis.averageDuration, const Duration(seconds: 60));
    });

    test('does not meet rule when contractions are too short', () {
      final now = DateTime(2026, 6, 1, 12, 0);
      final analysis = ContractionAnalyzer.analyze(
        pattern(now, durationSec: 20),
        asOf: now,
      );
      expect(analysis.meets511, isFalse);
    });

    test('does not meet rule when spread over less than an hour', () {
      final now = DateTime(2026, 6, 1, 12, 0);
      // Only three contractions -> 10-minute span, fails sustained-span check.
      final short = [
        for (var i = 0; i < 3; i++)
          Contraction(
            id: 's$i',
            startedAt: now.subtract(Duration(minutes: 5 * i)),
            endedAt: now
                .subtract(Duration(minutes: 5 * i))
                .add(const Duration(seconds: 60)),
          ),
      ];
      final analysis = ContractionAnalyzer.analyze(short, asOf: now);
      expect(analysis.meets511, isFalse);
    });

    test('empty history returns a start prompt', () {
      final analysis = ContractionAnalyzer.analyze(const []);
      expect(analysis.recentCount, 0);
      expect(analysis.meets511, isFalse);
      expect(analysis.averageInterval, isNull);
    });

    test('ignores contractions outside the one-hour window', () {
      final now = DateTime(2026, 6, 1, 12, 0);
      final old = Contraction(
        id: 'old',
        startedAt: now.subtract(const Duration(hours: 3)),
        endedAt: now
            .subtract(const Duration(hours: 3))
            .add(const Duration(seconds: 60)),
      );
      final analysis = ContractionAnalyzer.analyze([old], asOf: now);
      expect(analysis.recentCount, 0);
    });
  });

  group('ReportBuilder', () {
    test('summarises kicks and contractions', () {
      final generated = DateTime(2026, 6, 1, 12, 0);
      final kicks = [
        KickSession(
          id: 'k1',
          startedAt: DateTime(2026, 6, 1, 9, 0),
          endedAt: DateTime(2026, 6, 1, 9, 40),
          kickCount: 10,
        ),
      ];
      final contractions = [
        Contraction(
          id: 'c1',
          startedAt: DateTime(2026, 6, 1, 11, 55),
          endedAt: DateTime(2026, 6, 1, 11, 56),
        ),
      ];
      final report = ReportBuilder.build(
        generatedAt: generated,
        kickSessions: kicks,
        contractions: contractions,
        motherName: 'Asha',
        currentWeek: 34,
        dueDate: DateTime(2026, 7, 20),
      );
      expect(report, contains('Asha'));
      expect(report, contains('Gestational week: 34'));
      expect(report, contains('10 kicks'));
      expect(report, contains('BABY KICK COUNTER'));
      expect(report, contains('CONTRACTION TIMER'));
    });

    test('handles no data gracefully', () {
      final report = ReportBuilder.build(
        generatedAt: DateTime(2026, 6, 1),
        kickSessions: const [],
        contractions: const [],
      );
      expect(report, contains('No completed kick sessions recorded.'));
      expect(report, contains('No contractions recorded.'));
    });
  });
}
