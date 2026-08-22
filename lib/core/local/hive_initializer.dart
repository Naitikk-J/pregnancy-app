import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Initializes Hive and opens the app's boxes.
///
/// Sensitive boxes are encrypted with an AES key that is generated once and
/// stored in the platform keystore/keychain via [FlutterSecureStorage]. Plain
/// caches (non-sensitive, easily re-fetched content) use unencrypted boxes.
///
/// [init] is **self-healing**: if a box is corrupt or the encryption key can no
/// longer decrypt it (which happens after an OS backup-restore or a
/// device-to-device transfer, where app files are restored but the keystore key
/// is not), it wipes local storage once and re-opens with a fresh key rather
/// than throwing — a thrown initializer would leave the app stuck forever on the
/// native launch (green) screen because `runApp` would never be reached. The
/// wiped data is only a local cache/sync-queue that re-syncs from Firestore, so
/// recovery loses nothing durable. Encrypted boxes are **always** re-opened
/// encrypted — recovery never downgrades sensitive data to plaintext.
class HiveInitializer {
  const HiveInitializer(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  /// Every box this app owns, in a single list so recovery can wipe them all.
  static const List<String> _allBoxes = [
    AppConstants.secureBox,
    AppConstants.syncQueueBox,
    AppConstants.settingsBox,
    AppConstants.cacheBox,
  ];

  /// Boxes that hold sensitive/personal data and must be encrypted.
  static const Set<String> _encryptedBoxes = {
    AppConstants.secureBox,
    AppConstants.syncQueueBox,
  };

  Future<void> init() async {
    await Hive.initFlutter();
    try {
      await _openBoxes();
    } catch (_) {
      // Corrupt box or unreadable/rotated key → recover once so the app can
      // still boot instead of hanging on the native splash forever.
      await _resetAndReopen();
    }
  }

  Future<void> _openBoxes() async {
    final cipher = HiveAesCipher(await _readOrCreateEncryptionKey());
    for (final name in _allBoxes) {
      await Hive.openBox<String>(
        name,
        encryptionCipher: _encryptedBoxes.contains(name) ? cipher : null,
      );
    }
  }

  /// Closes everything, deletes every box from disk **and** the stale
  /// encryption key (so the two can never drift out of sync), then re-opens
  /// from a clean slate with a freshly generated key.
  Future<void> _resetAndReopen() async {
    await Hive.close();
    for (final name in _allBoxes) {
      await Hive.deleteBoxFromDisk(name);
    }
    // Best-effort: drop the old key so a new one is generated on re-open. If the
    // keystore itself is unavailable, deletion may throw — swallow it so the
    // re-open (which regenerates) still runs.
    try {
      await _secureStorage.delete(key: AppConstants.hiveEncryptionKeyName);
    } catch (_) {/* fall through to regenerate */}
    await _openBoxes();
  }

  Future<List<int>> _readOrCreateEncryptionKey() async {
    final existing =
        await _secureStorage.read(key: AppConstants.hiveEncryptionKeyName);
    if (existing != null) {
      return base64Url.decode(existing);
    }
    final key = _generateKey();
    await _secureStorage.write(
      key: AppConstants.hiveEncryptionKeyName,
      value: base64Url.encode(key),
    );
    return key;
  }

  List<int> _generateKey() {
    final rng = Random.secure();
    return List<int>.generate(32, (_) => rng.nextInt(256));
  }
}
