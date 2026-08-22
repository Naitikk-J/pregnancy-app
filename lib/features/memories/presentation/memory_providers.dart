import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local_media_store.dart';
import '../domain/photo_entry.dart';

final localMediaStoreProvider =
    Provider<LocalMediaStore>((ref) => LocalMediaStore());

/// The device-local avatar image path, or null if the user hasn't set one.
/// Invalidate after saving/clearing to refresh the UI.
final avatarPathProvider = FutureProvider<String?>((ref) {
  return ref.watch(localMediaStoreProvider).avatarPath();
});

/// The memories / bump photo timeline, newest moment first. Invalidate after
/// add/edit/delete to refresh.
final memoryPhotosProvider = FutureProvider<List<PhotoEntry>>((ref) {
  return ref.watch(localMediaStoreProvider).photos();
});
