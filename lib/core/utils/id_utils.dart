/// Utilities for generating stable identifiers.
class IdUtils {
  const IdUtils._();

  /// A stable, non-negative 31-bit int derived from [input] — used for
  /// notification ids so the same medicine/appointment maps to the same
  /// notification (and can be cancelled/rescheduled deterministically).
  static int stableNotificationId(String input) {
    var hash = 0;
    for (final code in input.codeUnits) {
      hash = 0x1fffffff & (hash + code);
      hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
      hash ^= hash >> 6;
    }
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    hash ^= hash >> 11;
    hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
    return hash & 0x7fffffff;
  }

  /// yyyy-MM-dd key for a date (used for per-day docs like water intake).
  static String dateKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
