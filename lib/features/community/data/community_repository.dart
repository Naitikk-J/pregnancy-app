import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/community_post.dart';

/// Reads/writes the shared community feed. The feed lives in a top-level
/// `community_posts` collection (shared across users), so it can't use the
/// pregnancy-scoped tracker helper.
class CommunityRepository {
  CommunityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('community_posts');

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _posts.doc(postId).collection('comments');

  /// The feed, newest first.
  Stream<List<CommunityPost>> watchFeed({int limit = 100}) {
    return _posts
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityPost.fromJson({...d.data(), 'id': d.id}))
            .toList(growable: false));
  }

  /// Live comments under a post, oldest first (reading order).
  Stream<List<CommunityComment>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CommunityComment.fromJson({...d.data(), 'id': d.id}))
            .toList(growable: false));
  }

  Future<void> createPost(CommunityPost post) =>
      _posts.doc(post.id).set(post.toJson());

  Future<void> deletePost(String id) => _posts.doc(id).delete();

  /// Toggles the current user's like using atomic array ops.
  Future<void> toggleLike({
    required String postId,
    required String uid,
    required bool liked,
  }) {
    return _posts.doc(postId).update({
      'likedBy':
          liked ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid]),
    });
  }

  Future<void> addComment(String postId, CommunityComment comment) async {
    await _comments(postId).doc(comment.id).set(comment.toJson());
    await _posts.doc(postId).update({'commentCount': FieldValue.increment(1)});
  }
}
