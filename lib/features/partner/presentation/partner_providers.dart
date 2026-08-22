import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../auth/presentation/controllers/auth_providers.dart';
import '../data/partner_repository.dart';

final partnerRepositoryProvider = Provider<PartnerRepository>((ref) {
  return PartnerRepository(
    ref.watch(firestoreProvider),
    ref.watch(userRemoteDataSourceProvider),
  );
});
