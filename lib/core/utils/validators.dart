class Validators {
  Validators._();

  static const int maxNameLength = 50;
  static const int maxTitleLength = 60;
  static const int maxDescriptionLength = 500;
  static const int minPasswordLength = 8;

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (v.length > 254) return 'That email is too long';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  /// Login only checks that something was typed — strength rules apply when
  /// a password is being *created* (see [signupPassword]). Re-validating
  /// strength here would lock out accounts made before the rules changed.
  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter your password';
    return null;
  }

  static final RegExp _hasLetter = RegExp(r'[A-Za-z]');
  static final RegExp _hasDigit = RegExp(r'\d');

  static String? signupPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.trim().isEmpty) return "Password can't be only spaces";
    if (v.length < minPasswordLength) {
      return 'Use at least $minPasswordLength characters';
    }
    if (v.length > 72) return 'Password is too long (72 characters max)';
    if (!_hasLetter.hasMatch(v)) return 'Include at least one letter';
    if (!_hasDigit.hasMatch(v)) return 'Include at least one number';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name is too short';
    if (v.length > maxNameLength) {
      return 'Name is too long ($maxNameLength characters max)';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final v = value ?? '';
    if (v.isEmpty) return 'Re-enter your password';
    if (v != password) return 'Passwords do not match';
    return null;
  }

  static String? requiredTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return "Task title can't be empty";
    if (v.length > maxTitleLength) {
      return 'Title is too long ($maxTitleLength characters max)';
    }
    return null;
  }

  static String? description(String? value) {
    final v = value?.trim() ?? '';
    if (v.length > maxDescriptionLength) {
      return 'Description is too long ($maxDescriptionLength characters max)';
    }
    return null;
  }
}
