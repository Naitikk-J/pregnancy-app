import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../data/datasources/week_content_local_data_source.dart';
import '../../data/datasources/week_content_remote_data_source.dart';
import '../../data/repositories/week_content_repository_impl.dart';
import '../../domain/entities/week_content.dart';
import '../../domain/repositories/week_content_repository.dart';

final weekContentLocalDataSourceProvider =
    Provider<WeekContentLocalDataSource>((ref) => WeekContentLocalDataSource());

final weekContentRemoteDataSourceProvider =
    Provider<WeekContentRemoteDataSource>((ref) {
  return WeekContentRemoteDataSource(ref.watch(firestoreProvider));
});

final weekContentRepositoryProvider = Provider<WeekContentRepository>((ref) {
  return WeekContentRepositoryImpl(
    local: ref.watch(weekContentLocalDataSourceProvider),
    remote: ref.watch(weekContentRemoteDataSourceProvider),
    cache: ref.watch(localStorageProvider(LocalBox.cache)),
  );
});

/// Content for a specific week (family). Cached by Riverpod for the session.
final weekContentProvider =
    FutureProvider.family<WeekContent, int>((ref, week) {
  return ref.watch(weekContentRepositoryProvider).getWeek(week);
});
