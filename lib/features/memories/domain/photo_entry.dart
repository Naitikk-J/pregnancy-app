/// A single saved memory (a bump/belly photo or a short video), stored **on
/// this device only** — never uploaded (the free stack has no Firebase Storage).
/// Dates are ISO-8601 strings so the index sorts cleanly.
class PhotoEntry {
  const PhotoEntry({
    required this.id,
    required this.path,
    required this.takenAt,
    this.mediaType = 'image',
    this.week,
    this.note,
  });

  final String id;

  /// Absolute path to the media file in the app documents directory.
  final String path;

  /// 'image' or 'video'.
  final String mediaType;

  /// When the moment happened (chosen by the user; defaults to "now").
  final DateTime takenAt;

  /// Optional pregnancy week this memory belongs to.
  final int? week;

  /// Optional short caption.
  final String? note;

  bool get isVideo => mediaType == 'video';

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'mediaType': mediaType,
        'takenAt': takenAt.toIso8601String(),
        if (week != null) 'week': week,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  factory PhotoEntry.fromJson(Map<String, dynamic> json) => PhotoEntry(
        id: json['id'] as String,
        path: json['path'] as String,
        mediaType: json['mediaType'] as String? ?? 'image',
        takenAt: DateTime.tryParse(json['takenAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        week: (json['week'] as num?)?.toInt(),
        note: json['note'] as String?,
      );

  PhotoEntry copyWith({int? week, String? note}) => PhotoEntry(
        id: id,
        path: path,
        mediaType: mediaType,
        takenAt: takenAt,
        week: week ?? this.week,
        note: note ?? this.note,
      );
}
