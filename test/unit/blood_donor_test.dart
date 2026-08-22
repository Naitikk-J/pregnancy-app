import 'package:flutter_test/flutter_test.dart';
import 'package:pregnancy_companion/features/blood_donors/domain/blood_donor.dart';

void main() {
  group('blood compatibility', () {
    test('O- is the universal donor (can give to everyone)', () {
      for (final recipient in kBloodGroups) {
        expect(canDonateTo(recipient, 'O-'), isTrue,
            reason: 'O- should donate to $recipient');
      }
    });

    test('AB+ is the universal recipient (can receive from everyone)', () {
      final compatible = compatibleDonorGroups('AB+');
      expect(compatible, containsAll(kBloodGroups));
    });

    test('O- can only receive from O-', () {
      expect(compatibleDonorGroups('O-'), {'O-'});
    });

    test('A+ receives A+, A-, O+, O- only', () {
      expect(compatibleDonorGroups('A+'), {'A+', 'A-', 'O+', 'O-'});
      expect(canDonateTo('A+', 'B+'), isFalse);
      expect(canDonateTo('A+', 'O-'), isTrue);
    });

    test('unknown or blank group has no compatible donors', () {
      expect(compatibleDonorGroups(null), isEmpty);
      expect(compatibleDonorGroups(''), isEmpty);
      expect(canDonateTo('A+', ''), isFalse);
    });

    test('is case/whitespace tolerant', () {
      expect(canDonateTo(' a+ ', 'o-'), isTrue);
    });

    test('serializes and restores a donor', () {
      final d = BloodDonor(
        id: '1',
        name: 'Asha',
        phone: '9990001111',
        bloodGroup: 'O-',
        relation: 'Sister',
        createdAt: DateTime.utc(2026, 1, 1),
      );
      final back = BloodDonor.fromJson(d.toJson());
      expect(back.name, 'Asha');
      expect(back.bloodGroup, 'O-');
      expect(back.relation, 'Sister');
    });
  });
}
