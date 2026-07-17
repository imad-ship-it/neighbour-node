/// Form validators — return an error string, or null when valid.
/// Used with `TextFormField.validator`.
class Validators {
  Validators._();

  static final RegExp _emailPattern =
      RegExp(r'^[\w\.\+\-]+@[\w\-]+(\.[\w\-]+)+$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Email is required';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? displayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Display name is required';
    if (v.length < 2) return 'Display name is too short';
    return null;
  }
}
