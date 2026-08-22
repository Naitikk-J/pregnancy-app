import 'package:equatable/equatable.dart';

import '../../../core/constants/enums.dart';

/// A pregnancy vaccine and the mother's status for it, stored at
/// `pregnancies/{pid}/vaccinations/{id}` (id is a stable slug from the catalog).
class Vaccine extends Equatable {
  const Vaccine({
    required this.id,
    required this.name,
    required this.timing,
    this.status = VaccineStatus.due,
    this.scheduledDate,
    this.completedDate,
  });

  final String id;
  final String name;

  /// When it's typically given, e.g. "27–36 weeks".
  final String timing;
  final VaccineStatus status;
  final DateTime? scheduledDate;
  final DateTime? completedDate;

  Vaccine copyWith({
    VaccineStatus? status,
    DateTime? scheduledDate,
    DateTime? completedDate,
    bool clearDates = false,
  }) =>
      Vaccine(
        id: id,
        name: name,
        timing: timing,
        status: status ?? this.status,
        scheduledDate: clearDates ? null : (scheduledDate ?? this.scheduledDate),
        completedDate: clearDates ? null : (completedDate ?? this.completedDate),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'timing': timing,
        'status': status.name,
        'scheduledDate': scheduledDate?.toUtc().toIso8601String(),
        'completedDate': completedDate?.toUtc().toIso8601String(),
      };

  factory Vaccine.fromJson(Map<String, dynamic> json) => Vaccine(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        timing: json['timing'] as String? ?? '',
        status: VaccineStatus.fromName(json['status'] as String?),
        scheduledDate: json['scheduledDate'] == null
            ? null
            : DateTime.parse(json['scheduledDate'] as String),
        completedDate: json['completedDate'] == null
            ? null
            : DateTime.parse(json['completedDate'] as String),
      );

  @override
  List<Object?> get props =>
      [id, name, timing, status, scheduledDate, completedDate];
}

/// Default pregnancy vaccine catalog (India-first). The catalog provides the
/// name/timing; the mother's per-vaccine status is merged in from Firestore by
/// matching [Vaccine.id], so no seeding write is needed.
const List<Vaccine> kDefaultVaccines = [
  Vaccine(id: 'tt1', name: 'Tetanus (TT/Td) — 1st dose', timing: 'Early / first visit'),
  Vaccine(id: 'tt2', name: 'Tetanus (TT/Td) — 2nd dose', timing: '4 weeks after 1st dose'),
  Vaccine(id: 'tdap', name: 'Tdap (whooping cough)', timing: '27–36 weeks'),
  Vaccine(id: 'flu', name: 'Influenza (flu shot)', timing: 'Any trimester (seasonal)'),
  Vaccine(id: 'covid', name: 'COVID-19', timing: 'As advised by your doctor'),
];
