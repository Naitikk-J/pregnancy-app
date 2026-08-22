import '../../../../core/local/local_storage.dart';
import '../../domain/entities/week_content.dart';
import '../../domain/repositories/week_content_repository.dart';
import '../datasources/week_content_local_data_source.dart';
import '../datasources/week_content_remote_data_source.dart';

/// Cache-first week content: Hive cache → best-effort remote (cached on
/// success) → bundled/synthesised local content. Always resolves, even offline
/// and even before any Firestore content is seeded.
class WeekContentRepositoryImpl implements WeekContentRepository {
  WeekContentRepositoryImpl({
    required WeekContentLocalDataSource local,
    required WeekContentRemoteDataSource remote,
    required LocalStorage cache,
  })  : _local = local,
        _remote = remote,
        _cache = cache;

  final WeekContentLocalDataSource _local;
  final WeekContentRemoteDataSource _remote;
  final LocalStorage _cache;

  String _key(int week) => 'week_content_$week';

  @override
  Future<WeekContent> getWeek(int week) async {
    final clamped = week.clamp(1, 40);

    // 1. Hive cache (fast, offline).
    final cached = _cache.get(_key(clamped));
    if (cached != null) {
      return WeekContent.fromJson(cached);
    }

    // 2. Remote (best-effort). Cache on success. Any failure → fall through.
    try {
      final remote = await _remote.getWeek(clamped);
      if (remote != null) {
        await _cache.put(_key(clamped), remote.toJson());
        return remote;
      }
    } catch (_) {
      // Offline or Firestore unavailable — use local content below.
    }

    // 3. Bundled / synthesised local content (guaranteed).
    return _local.getWeek(clamped);
  }
}
