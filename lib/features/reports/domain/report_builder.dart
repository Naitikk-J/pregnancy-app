import 'package:intl/intl.dart';

import '../../../core/utils/duration_format.dart';
import '../../contractions/domain/contraction.dart';
import '../../contractions/domain/contraction_analysis.dart';
import '../../kick_counter/domain/kick_session.dart';

/// Builds a plain-text summary of kick-counter and contraction activity that a
/// mother can copy or email to her doctor. Pure (no I/O), so it's easy to test
/// and can run offline.
class ReportBuilder {
  const ReportBuilder._();

  static const int _maxRows = 20;

  static String build({
    required DateTime generatedAt,
    required List<KickSession> kickSessions,
    required List<Contraction> contractions,
    String? motherName,
    int? currentWeek,
    DateTime? dueDate,
  }) {
    final dateFmt = DateFormat('EEE, d MMM yyyy');
    final dateTimeFmt = DateFormat('d MMM, HH:mm');
    final b = StringBuffer();

    b.writeln('PREGNANCY COMPANION — MOVEMENT & CONTRACTION REPORT');
    b.writeln('=' * 52);
    if (motherName != null && motherName.isNotEmpty) {
      b.writeln('Name: $motherName');
    }
    if (currentWeek != null) {
      b.writeln('Gestational week: $currentWeek');
    }
    if (dueDate != null) {
      b.writeln('Estimated due date: ${dateFmt.format(dueDate)}');
    }
    b.writeln('Generated: ${dateTimeFmt.format(generatedAt)}');
    b.writeln('');

    // --- Baby kicks ---
    b.writeln('BABY KICK COUNTER');
    b.writeln('-' * 52);
    final completedKicks =
        kickSessions.where((s) => s.isComplete).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (completedKicks.isEmpty) {
      b.writeln('No completed kick sessions recorded.');
    } else {
      b.writeln('Sessions recorded: ${completedKicks.length}');
      b.writeln('');
      for (final s in completedKicks.take(_maxRows)) {
        final target = s.reachedTarget
            ? 'reached ${s.targetKicks}'
            : '${s.kickCount}/${s.targetKicks}';
        b.writeln('• ${dateTimeFmt.format(s.startedAt)} — '
            '${s.kickCount} kicks in ${DurationFormat.compact(s.elapsed())} '
            '($target)');
      }
      if (completedKicks.length > _maxRows) {
        b.writeln('… and ${completedKicks.length - _maxRows} earlier '
            'session(s).');
      }
    }
    b.writeln('');

    // --- Contractions ---
    b.writeln('CONTRACTION TIMER');
    b.writeln('-' * 52);
    final completedContractions =
        contractions.where((c) => c.isComplete).toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    if (completedContractions.isEmpty) {
      b.writeln('No contractions recorded.');
    } else {
      final analysis = ContractionAnalyzer.analyze(
        completedContractions,
        asOf: generatedAt,
      );
      b.writeln('Contractions recorded: ${completedContractions.length}');
      b.writeln('In the last hour: ${analysis.recentCount}');
      if (analysis.averageInterval != null) {
        b.writeln('Average interval (last hour): '
            '${DurationFormat.compact(analysis.averageInterval!)}');
      }
      if (analysis.averageDuration != null) {
        b.writeln('Average duration (last hour): '
            '${DurationFormat.compact(analysis.averageDuration!)}');
      }
      b.writeln('5-1-1 pattern met: ${analysis.meets511 ? 'YES' : 'no'}');
      b.writeln('');
      // Ascending order so start-to-start intervals read naturally.
      final ascending = [...completedContractions]
        ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
      final rows = ascending.length > _maxRows
          ? ascending.sublist(ascending.length - _maxRows)
          : ascending;
      for (var i = 0; i < rows.length; i++) {
        final c = rows[i];
        final interval = i == 0
            ? '—'
            : DurationFormat.compact(
                c.startedAt.difference(rows[i - 1].startedAt));
        b.writeln('• ${dateTimeFmt.format(c.startedAt)} — '
            'lasted ${DurationFormat.compact(c.duration())}, '
            'interval $interval');
      }
    }
    b.writeln('');
    b.writeln('-' * 52);
    b.writeln('This report is informational and does not replace medical '
        'advice. Share any concerns with your doctor.');

    return b.toString();
  }
}
