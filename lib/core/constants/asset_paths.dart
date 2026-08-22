/// Typed references to bundled assets. Prevents stringly-typed asset bugs.
class AssetPaths {
  AssetPaths._();

  static const String _images = 'assets/images';
  static const String _lottie = 'assets/lottie';
  static const String _icons = 'assets/icons';
  static const String _data = 'assets/data';

  // Images
  static const String logo = '$_images/logo.png';
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';

  // Lottie animations
  static const String splashAnimation = '$_lottie/pregnancy.json';
  static const String emptyState = '$_lottie/empty.json';
  static const String loading = '$_lottie/loading.json';

  // Icons
  static const String googleIcon = '$_icons/google.png';
  static const String appleIcon = '$_icons/apple.png';

  // Bundled offline content
  static const String weekContentJson = '$_data/week_content.json';
  static const String babyNamesJson = '$_data/baby_names.json';
}
