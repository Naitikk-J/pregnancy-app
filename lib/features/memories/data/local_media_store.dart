import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/photo_entry.dart';

/// Device-local storage for personal images kept **only on this phone** (never
/// uploaded — the free stack has no Firebase Storage):
///   * the profile **avatar** (a single image), and
///   * the **memories / bump photo timeline** (a growing collection).
///
/// Image files live under the app documents directory; a small JSON index
/// tracks the photo history. Uninstalling the app removes everything.
class LocalMediaStore {
  static const _dirName = 'memories';
  static const _indexName = 'index.json';
  static const _avatarPrefix = 'avatar';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_dirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _indexFile(Directory dir) => File('${dir.path}/$_indexName');

  String _safeExt(String extension) {
    final ext = extension.replaceAll('.', '').toLowerCase();
    return ext.isEmpty ? 'jpg' : ext;
  }

  // --- Avatar (single image) ---------------------------------------------

  /// Save (or replace) the avatar. Removes any prior avatar file first so we
  /// never leave orphans when the extension changes. Returns the saved path.
  Future<String> saveAvatar({
    required Uint8List bytes,
    required String extension,
  }) async {
    final dir = await _dir();
    await _clearAvatarFiles(dir);
    final file = File('${dir.path}/$_avatarPrefix.${_safeExt(extension)}');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// The current avatar file path, or null if none has been set.
  Future<String?> avatarPath() async {
    final dir = await _dir();
    final files = await _avatarFiles(dir);
    return files.isEmpty ? null : files.first.path;
  }

  Future<void> clearAvatar() async => _clearAvatarFiles(await _dir());

  Future<List<File>> _avatarFiles(Directory dir) async {
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) =>
            f.uri.pathSegments.last.startsWith('$_avatarPrefix.'))
        .toList();
  }

  Future<void> _clearAvatarFiles(Directory dir) async {
    for (final f in await _avatarFiles(dir)) {
      if (await f.exists()) await f.delete();
    }
  }

  // --- Memories timeline (collection) ------------------------------------

  /// Persist a memory's bytes (photo or video) and add it to the history index
  /// (newest first).
  Future<PhotoEntry> addPhoto({
    required String id,
    required Uint8List bytes,
    required String extension,
    required DateTime takenAt,
    String mediaType = 'image',
    int? week,
    String? note,
  }) async {
    final dir = await _dir();
    final file = File('${dir.path}/mem_$id.${_safeExt(extension)}');
    await file.writeAsBytes(bytes, flush: true);
    final entry = PhotoEntry(
      id: id,
      path: file.path,
      mediaType: mediaType,
      takenAt: takenAt,
      week: week,
      note: note,
    );
    final entries = await _read(dir);
    entries.add(entry);
    await _write(dir, entries);
    return entry;
  }

  /// All memory photos, newest moment first.
  Future<List<PhotoEntry>> photos() async {
    final entries = await _read(await _dir());
    entries.sort((a, b) => b.takenAt.compareTo(a.takenAt));
    return entries;
  }

  Future<void> updatePhoto(String id, {int? week, String? note}) async {
    final dir = await _dir();
    final entries = await _read(dir);
    final idx = entries.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    entries[idx] = entries[idx].copyWith(week: week, note: note);
    await _write(dir, entries);
  }

  Future<void> deletePhoto(String id) async {
    final dir = await _dir();
    final entries = await _read(dir);
    for (final e in entries.where((e) => e.id == id)) {
      final f = File(e.path);
      if (await f.exists()) await f.delete();
    }
    entries.removeWhere((e) => e.id == id);
    await _write(dir, entries);
  }

  Future<List<PhotoEntry>> _read(Directory dir) async {
    final f = _indexFile(dir);
    if (!await f.exists()) return [];
    try {
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(PhotoEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(Directory dir, List<PhotoEntry> entries) async {
    await _indexFile(dir)
        .writeAsString(jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
