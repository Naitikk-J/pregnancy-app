import '../entities/week_content.dart';

/// Provides educational content for a gestational week. Implementations
/// guarantee a result for any week 1–40 (falling back to offline content).
abstract interface class WeekContentRepository {
  Future<WeekContent> getWeek(int week);
}
