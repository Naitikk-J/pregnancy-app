import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../shared/providers/app_settings_provider.dart';
import '../../settings/ai_key_providers.dart';
import '../data/document_ai_repository.dart';
import '../data/local_scan_store.dart';
import '../domain/scan_models.dart';

final documentAiRepositoryProvider = Provider<DocumentAiRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return DocumentAiRepository(
    ref.watch(firebaseAuthProvider),
    endpoint: config.aiEndpoint,
    lang: ref.watch(appSettingsProvider).localeCode,
    userKey: ref.watch(userGeminiKeyProvider).valueOrNull ?? '',
  );
});

final localScanStoreProvider =
    Provider<LocalScanStore>((ref) => LocalScanStore());

/// Device-local scan history (prescriptions + lab reports), newest first.
final scanHistoryProvider = FutureProvider<List<ScanRecord>>((ref) {
  return ref.watch(localScanStoreProvider).records();
});
