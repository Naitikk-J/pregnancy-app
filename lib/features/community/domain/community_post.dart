import 'package:equatable/equatable.dart';

/// A post in the shared community feed, stored at `community_posts/{id}`.
/// Unlike trackers, the feed is a top-level collection shared across all users.
class CommunityPost extends Equatable {
  const CommunityPost({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
    this.week,
    this.likedBy = const [],
    this.commentCount = 0,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  /// The author's pregnancy week when posting, for a little context. Optional.
  final int? week;

  /// UIDs that liked the post; count is derived from its length.
  final List<String> likedBy;
  final int commentCount;

  int get likeCount => likedBy.length;
  bool likedBy_(String uid) => likedBy.contains(uid);

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'week': week,
        'likedBy': likedBy,
        'commentCount': commentCount,
      };

  factory CommunityPost.fromJson(Map<String, dynamic> json) => CommunityPost(
        id: json['id'] as String,
        authorUid: json['authorUid'] as String? ?? '',
        authorName: json['authorName'] as String? ?? 'A mom',
        text: json['text'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
        week: (json['week'] as num?)?.toInt(),
        likedBy: (json['likedBy'] as List<dynamic>?)?.cast<String>() ?? const [],
        commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      );

  @override
  List<Object?> get props =>
      [id, authorUid, authorName, text, createdAt, week, likedBy, commentCount];
}

/// A comment under a post, stored at `community_posts/{postId}/comments/{id}`.
class CommunityComment extends Equatable {
  const CommunityComment({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory CommunityComment.fromJson(Map<String, dynamic> json) =>
      CommunityComment(
        id: json['id'] as String,
        authorUid: json['authorUid'] as String? ?? '',
        authorName: json['authorName'] as String? ?? 'A mom',
        text: json['text'] as String? ?? '',
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '') ??
                DateTime.now(),
      );

  @override
  List<Object?> get props => [id, authorUid, authorName, text, createdAt];
}
