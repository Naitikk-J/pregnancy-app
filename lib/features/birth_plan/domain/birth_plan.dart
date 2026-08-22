import 'package:equatable/equatable.dart';

/// Preferred mode of delivery.
enum BirthType {
  vaginal,
  cesarean,
  undecided;

  String get label => switch (this) {
        BirthType.vaginal => 'Vaginal birth',
        BirthType.cesarean => 'Cesarean (C-section)',
        BirthType.undecided => 'Guided by my doctor',
      };

  static BirthType fromName(String? n) => BirthType.values
      .firstWhere((e) => e.name == n, orElse: () => BirthType.undecided);
}

/// Pain-management preference.
enum PainPreference {
  natural,
  epidural,
  openToOptions,
  undecided;

  String get label => switch (this) {
        PainPreference.natural => 'Natural / no medication',
        PainPreference.epidural => 'Epidural',
        PainPreference.openToOptions => 'Open to options',
        PainPreference.undecided => 'Decide on the day',
      };

  static PainPreference fromName(String? n) => PainPreference.values
      .firstWhere((e) => e.name == n, orElse: () => PainPreference.undecided);
}

/// Feeding preference for the newborn.
enum FeedingPreference {
  breast,
  formula,
  mixed,
  undecided;

  String get label => switch (this) {
        FeedingPreference.breast => 'Breastfeeding',
        FeedingPreference.formula => 'Formula feeding',
        FeedingPreference.mixed => 'Both (mixed)',
        FeedingPreference.undecided => 'Not decided yet',
      };

  static FeedingPreference fromName(String? n) => FeedingPreference.values
      .firstWhere((e) => e.name == n, orElse: () => FeedingPreference.undecided);
}

/// A structured birth plan, stored at `pregnancies/{pid}/birthPlan/plan`
/// (a single document per pregnancy).
class BirthPlan extends Equatable {
  const BirthPlan({
    this.id = 'plan',
    this.birthType = BirthType.undecided,
    this.painPreference = PainPreference.undecided,
    this.feeding = FeedingPreference.undecided,
    this.companion = '',
    this.skinToSkin = true,
    this.delayedCordClamping = false,
    this.environmentNotes = '',
    this.specialRequests = '',
    this.updatedAt,
  });

  final String id;
  final BirthType birthType;
  final PainPreference painPreference;
  final FeedingPreference feeding;

  /// Who the mother wants with her during labour.
  final String companion;
  final bool skinToSkin;
  final bool delayedCordClamping;

  /// Atmosphere preferences (lighting, music, freedom to move…).
  final String environmentNotes;
  final String specialRequests;
  final DateTime? updatedAt;

  BirthPlan copyWith({
    BirthType? birthType,
    PainPreference? painPreference,
    FeedingPreference? feeding,
    String? companion,
    bool? skinToSkin,
    bool? delayedCordClamping,
    String? environmentNotes,
    String? specialRequests,
    DateTime? updatedAt,
  }) =>
      BirthPlan(
        id: id,
        birthType: birthType ?? this.birthType,
        painPreference: painPreference ?? this.painPreference,
        feeding: feeding ?? this.feeding,
        companion: companion ?? this.companion,
        skinToSkin: skinToSkin ?? this.skinToSkin,
        delayedCordClamping: delayedCordClamping ?? this.delayedCordClamping,
        environmentNotes: environmentNotes ?? this.environmentNotes,
        specialRequests: specialRequests ?? this.specialRequests,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'birthType': birthType.name,
        'painPreference': painPreference.name,
        'feeding': feeding.name,
        'companion': companion,
        'skinToSkin': skinToSkin,
        'delayedCordClamping': delayedCordClamping,
        'environmentNotes': environmentNotes,
        'specialRequests': specialRequests,
        'updatedAt': (updatedAt ?? DateTime.now()).toUtc().toIso8601String(),
      };

  factory BirthPlan.fromJson(Map<String, dynamic> json) => BirthPlan(
        id: json['id'] as String? ?? 'plan',
        birthType: BirthType.fromName(json['birthType'] as String?),
        painPreference:
            PainPreference.fromName(json['painPreference'] as String?),
        feeding: FeedingPreference.fromName(json['feeding'] as String?),
        companion: json['companion'] as String? ?? '',
        skinToSkin: json['skinToSkin'] as bool? ?? true,
        delayedCordClamping: json['delayedCordClamping'] as bool? ?? false,
        environmentNotes: json['environmentNotes'] as String? ?? '',
        specialRequests: json['specialRequests'] as String? ?? '',
        updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [
        id,
        birthType,
        painPreference,
        feeding,
        companion,
        skinToSkin,
        delayedCordClamping,
        environmentNotes,
        specialRequests,
      ];
}
