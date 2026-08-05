class Validators {
  Validators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,4}$',
  );

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Name is required';
    if (name.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!_emailRegExp.hasMatch(email)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    final password = value ?? '';
    if (password.isEmpty) return 'Password is required';
    if (password.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    final confirm = value ?? '';
    if (confirm.isEmpty) return 'Please confirm your password';
    if (confirm != password) return 'Passwords do not match';
    return null;
  }
}
