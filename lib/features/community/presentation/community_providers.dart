import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../data/community_repository.dart';
import '../domain/community_post.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(ref.watch(firestoreProvider));
});

/// The shared feed, newest first.
final communityFeedProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).watchFeed();
});

/// Comments for one post.
final postCommentsProvider = StreamProvider.family<List<CommunityComment>, String>(
  (ref, postId) => ref.watch(communityRepositoryProvider).watchComments(postId),
);

/// The signed-in user's uid, or null.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.uid;
});

/// A friendly display name for authoring posts/comments — profile name first,
/// then account display name, then a gentle fallback.
final authorNameProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  if (profile != null && profile.name.trim().isNotEmpty) return profile.name;
  final display = ref.watch(currentUserProvider)?.displayName;
  if (display != null && display.trim().isNotEmpty) return display;
  return 'A mom';
});
