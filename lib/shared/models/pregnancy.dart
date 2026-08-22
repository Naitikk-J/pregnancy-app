import 'package:equatable/equatable.dart';

import '../../core/constants/enums.dart';
import '../../core/utils/pregnancy_calculator.dart';

/// A pregnancy record, mirroring `pregnancies/{id}`. This is the central shared
/// entity: partner, family and doctor all link to it via the [members] map.
class Pregnancy extends Equatable {
  const Pregnancy({
    required this.id,
    required this.ownerUserId,
    required this.lmpDate,
    required this.dueDate,
    required this.riskCategory,
    this.doctorName,
    this.hospital,
    this.doctorUserId,
    this.status = 'active',
    this.members = const {},
    this.sharing = const {},
    this.createdAt,
    this.updatedAt,
  });

  /// Categories a mother can choose to share with partners/family. The owner
  /// always sees everything; these gate what *members* can read. Defaults
  /// (when unset) are privacy-first: only the "overview" categories are shared.
  static const List<String> shareCategories = [
    'appointments',
    'planning',
    'medicines',
    'vitals',
    'symptoms',
    'movements',
  ];
  static const Set<String> shareDefaultsOn = {'appointments', 'planning'};

  static String labelForCategory(String c) => switch (c) {
        'appointments' => 'Appointments',
        'planning' => 'Plans & lists (bag, shopping, names, birth plan)',
        'medicines' => 'Medicines & reminders',
        'vitals' => 'Vitals (weight, BP, sugar, sleep)',
        'symptoms' => 'Symptoms',
        'movements' => 'Kicks & contractions',
        _ => c,
      };

  final String id;
  final String ownerUserId;
  final DateTime lmpDate;
  final DateTime dueDate;
  final RiskCategory riskCategory;
  final String? doctorName;
  final String? hospital;
  final String? doctorUserId;
  final String status;

  /// { uid: { role, permissions, invitedAt, acceptedAt } }
  final Map<String, dynamic> members;

  /// { category: bool } — what members may view. See [shareCategories].
  final Map<String, dynamic> sharing;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Whether [category] is shared with members (owner-set, privacy-first default).
  bool isShared(String category) =>
      sharing[category] as bool? ?? shareDefaultsOn.contains(category);

  // --- Derived (never stored raw; computed live to stay correct daily) ---
  int get currentWeek => PregnancyCalculator.currentWeek(lmpDate);
  int get dayOfCurrentWeek => PregnancyCalculator.dayOfWeek(lmpDate);
  Trimester get trimester =>
      PregnancyCalculator.trimesterForWeek(currentWeek);
  double get progress => PregnancyCalculator.progress(lmpDate);
  int get daysRemaining => PregnancyCalculator.daysRemaining(dueDate);

  bool isMember(String uid) => members.containsKey(uid);

  Pregnancy copyWith({
    String? ownerUserId,
    DateTime? lmpDate,
    DateTime? dueDate,
    RiskCategory? riskCategory,
    String? doctorName,
    String? hospital,
    String? doctorUserId,
    String? status,
    Map<String, dynamic>? members,
    Map<String, dynamic>? sharing,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Pregnancy(
        id: id,
        ownerUserId: ownerUserId ?? this.ownerUserId,
        lmpDate: lmpDate ?? this.lmpDate,
        dueDate: dueDate ?? this.dueDate,
        riskCategory: riskCategory ?? this.riskCategory,
        doctorName: doctorName ?? this.doctorName,
        hospital: hospital ?? this.hospital,
        doctorUserId: doctorUserId ?? this.doctorUserId,
        status: status ?? this.status,
        members: members ?? this.members,
        sharing: sharing ?? this.sharing,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'ownerUserId': ownerUserId,
        'lmpDate': lmpDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        // Denormalized for cheap dashboard/doctor reads; refreshed on write.
        'currentWeek': currentWeek,
        'trimester': trimester.name,
        'riskCategory': riskCategory.name,
        'doctorName': doctorName,
        'hospital': hospital,
        'doctorUserId': doctorUserId,
        'status': status,
        'members': members,
        'sharing': sharing,
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Pregnancy.fromJson(Map<String, dynamic> json) => Pregnancy(
        id: json['id'] as String,
        ownerUserId: json['ownerUserId'] as String,
        lmpDate: DateTime.parse(json['lmpDate'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        riskCategory: RiskCategory.fromName(json['riskCategory'] as String?),
        doctorName: json['doctorName'] as String?,
        hospital: json['hospital'] as String?,
        doctorUserId: json['doctorUserId'] as String?,
        status: json['status'] as String? ?? 'active',
        members: (json['members'] as Map<String, dynamic>?) ?? const {},
        sharing: (json['sharing'] as Map<String, dynamic>?) ?? const {},
        createdAt: _parse(json['createdAt']),
        updatedAt: _parse(json['updatedAt']),
      );

  static DateTime? _parse(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;

  @override
  List<Object?> get props => [
        id,
        ownerUserId,
        lmpDate,
        dueDate,
        riskCategory,
        doctorName,
        hospital,
        doctorUserId,
        status,
        members,
        sharing,
      ];
}
