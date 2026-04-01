import 'package:flutter/foundation.dart';

/// Utility class for validating password strength
/// Implements OWASP password security guidelines
class PasswordValidator {
  // Password requirements
  static const int minLength = 8;
  static const int maxLength = 128;
  static const int recommendedLength = 12;

  /// Validate password with comprehensive security checks
  static String? validate(String? value, {bool isSignUp = false}) {
    if (value == null || value.isEmpty) {
      return 'Password wajib diisi';
    }

    // Check minimum length
    if (value.length < minLength) {
      return 'Password minimal $minLength karakter';
    }

    // Check maximum length (prevent DoS)
    if (value.length > maxLength) {
      return 'Password maksimal $maxLength karakter';
    }

    // Only enforce complexity rules for sign up
    if (isSignUp) {
      // Check for at least one uppercase letter
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Password harus mengandung minimal 1 huruf besar';
      }

      // Check for at least one lowercase letter
      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return 'Password harus mengandung minimal 1 huruf kecil';
      }

      // Check for at least one number
      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password harus mengandung minimal 1 angka';
      }

      // Check for at least one special character
      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(value)) {
        return 'Password harus mengandung minimal 1 karakter spesial';
      }

      // Check for common weak passwords
      if (isCommonPassword(value)) {
        return 'Password terlalu umum, gunakan password yang lebih unik';
      }

      // Check for sequential characters
      if (hasSequentialCharacters(value)) {
        return 'Password tidak boleh mengandung urutan karakter (123, abc)';
      }

      // Check for repeated characters
      if (hasRepeatedCharacters(value)) {
        return 'Password tidak boleh mengandung karakter berulang (aaa, 111)';
      }
    }

    return null; // Password is valid
  }

  /// Get password strength (0-4)
  /// 0 = Very Weak, 1 = Weak, 2 = Fair, 3 = Good, 4 = Strong
  static int getStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= minLength) strength++;
    if (password.length >= recommendedLength) strength++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[A-Z]').hasMatch(password)) {
      strength++;
    }

    if (RegExp(r'[0-9]').hasMatch(password)) {
      strength++;
    }

    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\\/`~;]').hasMatch(password)) {
      strength++;
    }

    // Reduce strength for common patterns
    if (isCommonPassword(password)) {
      strength = 1; // Force to weak
    }

    if (hasSequentialCharacters(password) || hasRepeatedCharacters(password)) {
      strength = strength > 0 ? strength - 1 : 0;
    }

    // Normalize to 0-4 scale
    return strength > 4 ? 4 : strength;
  }

  /// Get password strength label
  static String getStrengthLabel(String password) {
    final strength = getStrength(password);

    switch (strength) {
      case 0:
        return 'Sangat Lemah';
      case 1:
        return 'Lemah';
      case 2:
        return 'Cukup';
      case 3:
        return 'Baik';
      case 4:
        return 'Kuat';
      default:
        return '';
    }
  }

  /// Check if password is in common password list
  static bool isCommonPassword(String password) {
    final commonPasswords = [
      'password',
      '12345678',
      'qwerty123',
      'abc123456',
      'password1',
      'admin123',
      'letmein',
      'welcome',
      'monkey',
      'dragon',
      'master',
      'sunshine',
      'princess',
      'qwertyuiop',
      'superman',
      'asdfghjkl',
      '123456789',
      'iloveyou',
      'batman',
      'trustno1',
      '1234567890',
      'welcome123',
      'password123',
      'admin1234',
    ];

    final lowerPassword = password.toLowerCase();

    // Check exact match
    if (commonPasswords.contains(lowerPassword)) {
      return true;
    }

    // Check if common password is substring
    for (final common in commonPasswords) {
      if (lowerPassword.contains(common)) {
        return true;
      }
    }

    return false;
  }

  /// Check for sequential characters (123, abc, etc.)
  static bool hasSequentialCharacters(String password) {
    final lower = password.toLowerCase();

    for (int i = 0; i < lower.length - 2; i++) {
      final char1 = lower.codeUnitAt(i);
      final char2 = lower.codeUnitAt(i + 1);
      final char3 = lower.codeUnitAt(i + 2);

      // Check for sequential ascending (abc, 123)
      if (char2 == char1 + 1 && char3 == char2 + 1) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Sequential ascending characters detected');
        }
        return true;
      }

      // Check for sequential descending (cba, 321)
      if (char2 == char1 - 1 && char3 == char2 - 1) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Sequential descending characters detected');
        }
        return true;
      }
    }

    return false;
  }

  /// Check for repeated characters (aaa, 111, etc.)
  static bool hasRepeatedCharacters(String password) {
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] && password[i + 1] == password[i + 2]) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Repeated characters detected');
        }
        return true;
      }
    }

    return false;
  }

  /// Generate password strength requirements message
  static String getRequirementsMessage() {
    return '''
Password harus memenuhi kriteria berikut:
• Minimal $minLength karakter (direkomendasikan $recommendedLength)
• Minimal 1 huruf besar (A-Z)
• Minimal 1 huruf kecil (a-z)
• Minimal 1 angka (0-9)
• Minimal 1 karakter spesial (!@#\$%^&*)
• Tidak mengandung urutan karakter (123, abc)
• Tidak mengandung karakter berulang (aaa, 111)
• Tidak menggunakan password umum
''';
  }
}
