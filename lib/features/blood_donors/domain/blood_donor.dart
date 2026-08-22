import 'package:equatable/equatable.dart';

/// The eight ABO/Rh blood groups, in the order used across the app's pickers.
const List<String> kBloodGroups = [
  'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-',
];

/// Red-cell donor compatibility: for a given recipient [group], the set of donor
/// blood groups that can safely donate to them. Pure and testable.
///
/// (Standard transfusion rules — O- is the universal donor, AB+ the universal
/// recipient.) Returns an empty set for an unknown/blank group.
Set<String> compatibleDonorGroups(String? group) {
  switch (group?.trim().toUpperCase()) {
    case 'O-':
      return {'O-'};
    case 'O+':
      return {'O-', 'O+'};
    case 'A-':
      return {'A-', 'O-'};
    case 'A+':
      return {'A+', 'A-', 'O+', 'O-'};
    case 'B-':
      return {'B-', 'O-'};
    case 'B+':
      return {'B+', 'B-', 'O+', 'O-'};
    case 'AB-':
      return {'AB-', 'A-', 'B-', 'O-'};
    case 'AB+':
      return {'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'};
    default:
      return const {};
  }
}

/// Whether someone with [donorGroup] can donate blood to a [recipientGroup].
bool canDonateTo(String? recipientGroup, String? donorGroup) {
  final d = donorGroup?.trim().toUpperCase();
  if (d == null || d.isEmpty) return false;
  return compatibleDonorGroups(recipientGroup).contains(d);
}

/// A saved potential blood donor, stored at
/// `pregnancies/{pid}/blood_donors/{id}`. Separate from emergency contacts —
/// this is a small directory of people whose blood group is known, so a
/// compatible donor can be reached quickly if a transfusion is ever needed.
class BloodDonor extends Equatable {
  const BloodDonor({
    required this.id,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    this.relation = '',
    this.note = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String bloodGroup;
  final String relation;
  final String note;
  final DateTime? createdAt;

  BloodDonor copyWith({
    String? name,
    String? phone,
    String? bloodGroup,
    String? relation,
    String? note,
  }) =>
      BloodDonor(
        id: id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        relation: relation ?? this.relation,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'bloodGroup': bloodGroup,
        'relation': relation,
        'note': note,
        'createdAt': (createdAt ?? DateTime.now().toUtc()).toIso8601String(),
      };

  factory BloodDonor.fromJson(Map<String, dynamic> json) => BloodDonor(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        bloodGroup: json['bloodGroup'] as String? ?? '',
        relation: json['relation'] as String? ?? '',
        note: json['note'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props =>
      [id, name, phone, bloodGroup, relation, note, createdAt];
}
