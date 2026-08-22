import 'contraction.dart';

/// Summary of recent contraction activity, plus whether the classic **5-1-1
/// rule** is met: contractions about **5** minutes apart, each lasting about
/// **1** minute, sustained for **1** hour — a common cue that active labour may
/// be starting and it's time to contact the doctor / go to the hospital.
///
/// This is guidance only, never a diagnosis; thresholds intentionally leave a
/// little tolerance so real-world timing still triggers.
class ContractionAnalysis {
  const ContractionAnalysis({
    required this.recentCount,
    required this.meets511,
    required this.guidance,
    this.averageInterval,
    this.averageDuration,
  });

  /// Number of completed contractions inside the rolling 1-hour window.
  final int recentCount;
  final Duration? averageInterval;
  final Duration? averageDuration;
  final bool meets511;
  final String guidance;
}

class ContractionAnalyzer {
  const ContractionAnalyzer._();

  /// Rolling window the rule is evaluated over.
  static const Duration window = Duration(hours: 1);

  // 5-1-1 thresholds (with small tolerances).
  static const Duration maxAverageInterval = Duration(minutes: 5);
  static const Duration minAverageDuration = Duration(seconds: 55);
  static const Duration minSustainedSpan = Duration(minutes: 55);

  static ContractionAnalysis analyze(
    List<Contraction> contractions, {
    DateTime? asOf,
  }) {
    final now = asOf ?? DateTime.now();

    // Completed contractions inside the last hour, oldest first.
    final recent = contractions
        .where((c) => c.isComplete && now.difference(c.startedAt) <= window)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

    if (recent.isEmpty) {
      return const ContractionAnalysis(
        recentCount: 0,
        meets511: false,
        guidance: 'Tap start when a contraction begins and stop when it ends. '
            "I'll track how long each one lasts and how far apart they are.",
      );
    }

    // Average duration across the window.
    final totalDuration = recent.fold<Duration>(
      Duration.zero,
      (sum, c) => sum + c.duration(),
    );
    final avgDuration = Duration(
      microseconds: totalDuration.inMicroseconds ~/ recent.length,
    );

    // Average start-to-start interval (needs at least two contractions).
    Duration? avgInterval;
    Duration span = Duration.zero;
    if (recent.length >= 2) {
      span = recent.last.startedAt.difference(recent.first.startedAt);
      avgInterval = Duration(
        microseconds: span.inMicroseconds ~/ (recent.length - 1),
      );
    }

    final meets511 = avgInterval != null &&
        span >= minSustainedSpan &&
        avgInterval <= maxAverageInterval &&
        avgDuration >= minAverageDuration;

    final String guidance;
    if (meets511) {
      guidance = 'Your contractions match the 5-1-1 pattern — about 5 minutes '
          'apart, roughly a minute long, for an hour. Call your doctor or head '
          'to the hospital now.';
    } else {
      guidance = 'Keep timing. Watch for contractions about 5 minutes apart, '
          'each lasting about a minute, for a full hour (the 5-1-1 rule).';
    }

    return ContractionAnalysis(
      recentCount: recent.length,
      averageInterval: avgInterval,
      averageDuration: avgDuration,
      meets511: meets511,
      guidance: guidance,
    );
  }
}
