import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../domain/scan_models.dart';

/// Device-local storage for scanned prescriptions/lab reports. Per the user's
/// choice, original scans are kept **only on this phone** (never uploaded): the
/// image files live under the app documents directory and a small JSON index
/// tracks the history. Uninstalling the app removes them.
class LocalScanStore {
  static const _dirName = 'scans';
  static const _indexName = 'index.json';

  Future<Directory> _dir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_dirName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  File _indexFile(Directory dir) => File('${dir.path}/$_indexName');

  /// Persist the original scan bytes; returns the saved file path.
  Future<String> saveImage({
    required String id,
    required Uint8List bytes,
    required String extension,
  }) async {
    final dir = await _dir();
    final safeExt = extension.replaceAll('.', '').toLowerCase();
    final file = File('${dir.path}/$id.$safeExt');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Add a record to the front of the history index.
  Future<void> addRecord(ScanRecord record) async {
    final dir = await _dir();
    final records = await _read(dir);
    records.insert(0, record);
    await _indexFile(dir)
        .writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<List<ScanRecord>> records() async => _read(await _dir());

  Future<void> deleteRecord(String id) async {
    final dir = await _dir();
    final records = await _read(dir);
    final removed = records.where((r) => r.id == id).toList();
    records.removeWhere((r) => r.id == id);
    for (final r in removed) {
      final f = File(r.imagePath);
      if (await f.exists()) await f.delete();
    }
    await _indexFile(dir)
        .writeAsString(jsonEncode(records.map((r) => r.toJson()).toList()));
  }

  Future<List<ScanRecord>> _read(Directory dir) async {
    final f = _indexFile(dir);
    if (!await f.exists()) return [];
    try {
      final raw = jsonDecode(await f.readAsString());
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(ScanRecord.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}
