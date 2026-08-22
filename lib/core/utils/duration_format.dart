/// Pure duration formatting helpers, shared by the kick counter, contraction
/// timer and exported reports. No Flutter imports so they're unit-testable.
class DurationFormat {
  const DurationFormat._();

  /// Stopwatch style: `MM:SS`, or `H:MM:SS` once an hour has passed.
  /// e.g. `Duration(seconds: 83)` -> `01:23`.
  static String clock(Duration d) {
    final negative = d.isNegative;
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    final s = abs.inSeconds.remainder(60);
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    final base = h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
    return negative ? '-$base' : base;
  }

  /// Human, compact form used for intervals & summaries.
  /// e.g. `1h 5m`, `4m 30s`, `45s`.
  static String compact(Duration d) {
    final abs = d.abs();
    final h = abs.inHours;
    final m = abs.inMinutes.remainder(60);
    final s = abs.inSeconds.remainder(60);
    if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
    if (m > 0) return (s > 0 && m < 10) ? '${m}m ${s}s' : '${m}m';
    return '${s}s';
  }
}
