// Central enums used across the app. Kept free of Flutter/Firebase imports so
// they can be used from the domain layer and in pure Dart tests.

/// The role a user plays in the pregnancy ecosystem.
enum UserRole {
  mother,
  husband,
  family,
  doctor,
  admin;

  String get label => switch (this) {
        UserRole.mother => 'Mother',
        UserRole.husband => 'Husband / Partner',
        UserRole.family => 'Family Member',
        UserRole.doctor => 'Doctor',
        UserRole.admin => 'Admin',
      };

  static UserRole fromName(String? name) => UserRole.values.firstWhere(
        (r) => r.name == name,
        orElse: () => UserRole.mother,
      );
}

/// Clinical risk classification for the pregnancy.
enum RiskCategory {
  low,
  medium,
  high;

  String get label => switch (this) {
        RiskCategory.low => 'Low risk',
        RiskCategory.medium => 'Medium risk',
        RiskCategory.high => 'High risk',
      };

  static RiskCategory fromName(String? name) => RiskCategory.values.firstWhere(
        (r) => r.name == name,
        orElse: () => RiskCategory.low,
      );
}

/// Pregnancy trimesters.
enum Trimester {
  first,
  second,
  third;

  String get label => switch (this) {
        Trimester.first => 'First trimester',
        Trimester.second => 'Second trimester',
        Trimester.third => 'Third trimester',
      };
}

/// Medicine intake timing relative to food.
enum MedicineTiming { beforeFood, afterFood, anytime }

/// Status of a scheduled medicine dose.
enum DoseStatus { pending, taken, missed, skipped }

/// Kinds of vitals we track in a single collection.
enum VitalKind { weight, bloodPressure, bloodSugar, water, sleep }

/// App-wide theme preference.
enum AppThemeMode { system, light, dark }

/// Blood-pressure classification (ACC/AHA thresholds). Gestational hypertension
/// is generally flagged from stage2 (≥140/90) upward.
enum BpCategory {
  low,
  normal,
  elevated,
  stage1,
  stage2,
  crisis;

  String get label => switch (this) {
        BpCategory.low => 'Low',
        BpCategory.normal => 'Normal',
        BpCategory.elevated => 'Elevated',
        BpCategory.stage1 => 'High (stage 1)',
        BpCategory.stage2 => 'High (stage 2)',
        BpCategory.crisis => 'Crisis',
      };

  /// True when the reading warrants raising it with a doctor during pregnancy.
  bool get isConcern =>
      this == BpCategory.stage2 ||
      this == BpCategory.crisis ||
      this == BpCategory.low;
}

/// When a blood-sugar reading was taken — determines the healthy target range.
enum GlucoseContext {
  fasting,
  breakfast,
  lunch,
  dinner,
  other;

  String get label => switch (this) {
        GlucoseContext.fasting => 'Fasting',
        GlucoseContext.breakfast => 'Breakfast',
        GlucoseContext.lunch => 'Lunch',
        GlucoseContext.dinner => 'Dinner',
        GlucoseContext.other => 'Other',
      };

  static GlucoseContext fromName(String? name) =>
      GlucoseContext.values.firstWhere(
        (c) => c.name == name,
        // Legacy readings stored as beforeMeal/afterMeal/random land here.
        orElse: () => GlucoseContext.other,
      );
}

/// Status of a vaccine in the user's pregnancy schedule.
enum VaccineStatus {
  due,
  scheduled,
  done;

  String get label => switch (this) {
        VaccineStatus.due => 'Due',
        VaccineStatus.scheduled => 'Scheduled',
        VaccineStatus.done => 'Done',
      };

  static VaccineStatus fromName(String? name) =>
      VaccineStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => VaccineStatus.due,
      );
}

/// Grouping for the shopping / essentials checklist.
enum ShoppingCategory {
  mother,
  baby,
  nursery,
  feeding,
  health;

  String get label => switch (this) {
        ShoppingCategory.mother => 'For mom',
        ShoppingCategory.baby => 'Baby clothing',
        ShoppingCategory.nursery => 'Nursery & gear',
        ShoppingCategory.feeding => 'Feeding',
        ShoppingCategory.health => 'Health & care',
      };

  static ShoppingCategory fromName(String? name) =>
      ShoppingCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => ShoppingCategory.baby,
      );
}

/// Grouping for hospital-bag checklist items.
enum HospitalBagCategory {
  mother,
  baby,
  documents,
  partner;

  String get label => switch (this) {
        HospitalBagCategory.mother => 'For mom',
        HospitalBagCategory.baby => 'For baby',
        HospitalBagCategory.documents => 'Documents',
        HospitalBagCategory.partner => 'For partner',
      };

  static HospitalBagCategory fromName(String? name) =>
      HospitalBagCategory.values.firstWhere(
        (c) => c.name == name,
        orElse: () => HospitalBagCategory.mother,
      );
}
