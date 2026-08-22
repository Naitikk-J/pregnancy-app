import 'package:equatable/equatable.dart';

/// A personal emergency contact (partner, family, doctor) stored under
/// `pregnancies/{pid}/emergency_contacts`. Shared with members so a partner can
/// reach the same people, and used by the SOS button.
class EmergencyContact extends Equatable {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.relation = '',
    this.isPrimary = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String relation;
  final bool isPrimary;
  final DateTime? createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'relation': relation,
        'isPrimary': isPrimary,
        'createdAt':
            (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        relation: json['relation'] as String? ?? '',
        isPrimary: json['isPrimary'] as bool? ?? false,
        createdAt: json['createdAt'] is String
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );

  @override
  List<Object?> get props => [id, name, phone, relation, isPrimary];
}
