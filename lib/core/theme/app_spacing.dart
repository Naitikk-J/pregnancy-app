/// Consistent spacing & radius scale. Use these instead of magic numbers so the
/// UI stays visually consistent and is trivial to re-tune globally.
class AppSpacing {
  AppSpacing._();

  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  // Corner radii — generous, soft rounding for a warm, friendly feel.
  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 18;
  static const double radiusCard = 22;
  static const double radiusXl = 26;
  static const double radiusXxl = 32;
  static const double radiusPill = 999;

  // Minimum accessible touch target.
  static const double minTouchTarget = 48;
}
