import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/firestore_crud.dart';
import '../../../shared/providers/pregnancy_scope.dart';
import '../../profile/presentation/controllers/profile_providers.dart';
import '../domain/blood_donor.dart';

final bloodDonorsCrudProvider = Provider<FirestoreCrud<BloodDonor>?>((ref) {
  final col = pregnancySubcollection(ref, 'blood_donors');
  if (col == null) return null;
  return FirestoreCrud<BloodDonor>(
    collection: col,
    fromJson: BloodDonor.fromJson,
    toJson: (d) => d.toJson(),
    idOf: (d) => d.id,
    orderByField: 'createdAt',
    descending: false,
  );
});

/// All saved potential donors.
final bloodDonorsProvider = StreamProvider<List<BloodDonor>>((ref) {
  final crud = ref.watch(bloodDonorsCrudProvider);
  if (crud == null) return Stream.value(const []);
  return crud.watch();
});

/// The mother's own blood group (from her profile), used to flag which saved
/// donors are compatible.
final motherBloodGroupProvider = Provider<String?>((ref) {
  return ref.watch(userProfileProvider).valueOrNull?.bloodGroup;
});
