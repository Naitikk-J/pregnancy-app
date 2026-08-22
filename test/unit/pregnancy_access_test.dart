import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/core/constants/enums.dart';
import 'package:pregnancy_companion/features/recovery/domain/pregnancy_access.dart';
import 'package:pregnancy_companion/shared/models/pregnancy.dart';

Pregnancy _pregnancy({
  required String owner,
  Map<String, dynamic> members = const {},
}) {
  final lmp = DateTime.now().subtract(const Duration(days: 100));
  return Pregnancy(
    id: 'preg1',
    ownerUserId: owner,
    lmpDate: lmp,
    dueDate: lmp.add(const Duration(days: 280)),
    riskCategory: RiskCategory.low,
    members: members,
  );
}

void main() {
  group('resolvePregnancyAccess', () {
    test('none when there is no active pregnancy id', () {
      expect(
        resolvePregnancyAccess(
          uid: 'u1',
          activePregnancyId: null,
          pregnancyLoaded: true,
          pregnancy: null,
        ),
        PregnancyAccess.none,
      );
      expect(
        resolvePregnancyAccess(
          uid: 'u1',
          activePregnancyId: '',
          pregnancyLoaded: true,
          pregnancy: null,
        ),
        PregnancyAccess.none,
      );
    });

    test('loading while the pregnancy is still resolving', () {
      expect(
        resolvePregnancyAccess(
          uid: 'u1',
          activePregnancyId: 'preg1',
          pregnancyLoaded: false,
          pregnancy: null,
        ),
        PregnancyAccess.loading,
      );
    });

    test('missing when the referenced document does not exist', () {
      expect(
        resolvePregnancyAccess(
          uid: 'u1',
          activePregnancyId: 'preg1',
          pregnancyLoaded: true,
          pregnancy: null,
        ),
        PregnancyAccess.missing,
      );
    });

    test('ok when the user owns the pregnancy', () {
      expect(
        resolvePregnancyAccess(
          uid: 'u1',
          activePregnancyId: 'preg1',
          pregnancyLoaded: true,
          pregnancy: _pregnancy(owner: 'u1'),
        ),
        PregnancyAccess.ok,
      );
    });

    test('ok when the user is a member but not the owner', () {
      expect(
        resolvePregnancyAccess(
          uid: 'partner',
          activePregnancyId: 'preg1',
          pregnancyLoaded: true,
          pregnancy: _pregnancy(
            owner: 'u1',
            members: const {'partner': {'role': 'husband'}},
          ),
        ),
        PregnancyAccess.ok,
      );
    });

    test('foreign when the account is neither owner nor member', () {
      expect(
        resolvePregnancyAccess(
          uid: 'stranger',
          activePregnancyId: 'preg1',
          pregnancyLoaded: true,
          pregnancy: _pregnancy(
            owner: 'u1',
            members: const {'u1': {'role': 'mother'}},
          ),
        ),
        PregnancyAccess.foreign,
      );
    });

    test('needsRecovery covers foreign, missing and none only', () {
      expect(PregnancyAccess.foreign.needsRecovery, isTrue);
      expect(PregnancyAccess.missing.needsRecovery, isTrue);
      expect(PregnancyAccess.none.needsRecovery, isTrue);
      expect(PregnancyAccess.ok.needsRecovery, isFalse);
      expect(PregnancyAccess.loading.needsRecovery, isFalse);
    });
  });
}
