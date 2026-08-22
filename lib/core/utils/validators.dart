/// Reusable form validators. Return `null` when valid, else an error message.
class Validators {
  const Validators._();

  static final RegExp _emailRegex =
      RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required.';
    if (v.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Za-z]').hasMatch(v) || !RegExp(r'\d').hasMatch(v)) {
      return 'Include letters and numbers.';
    }
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required.';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.replaceAll(RegExp(r'[\s-]'), '') ?? '';
    if (v.isEmpty) return 'Phone number is required.';
    if (!RegExp(r'^\+?\d{7,15}$').hasMatch(v)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Value']) {
    final v = double.tryParse(value?.trim() ?? '');
    if (v == null) return 'Enter a valid number.';
    if (v <= 0) return '$field must be greater than zero.';
    return null;
  }
}
