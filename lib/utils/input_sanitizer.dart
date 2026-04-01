import 'package:flutter/foundation.dart';

/// Comprehensive Input Sanitization Utility
/// Prevents XSS, SQL Injection, and other input-based attacks
class InputSanitizer {
  /// Sanitize HTML to prevent XSS attacks
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return input;
    
    final sanitized = input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
    
    return sanitized;
  }

  /// Sanitize SQL input to prevent SQL injection
  static String sanitizeSql(String input) {
    if (input.isEmpty) return input;

    final sanitized = input
        .replaceAll("'", '') // Remove single quotes (not escape — prevents injection)
        .replaceAll('"', '') // Remove double quotes
        .replaceAll(';', '') // Remove statement terminators
        .replaceAll('--', '') // Remove SQL line comments
        .replaceAll('/*', '') // Remove block comments
        .replaceAll('*/', '')
        .replaceAll('xp_', '') // Remove extended procedures
        .replaceAll('sp_', ''); // Remove stored procedures

    final dangerousKeywords = [
      'SELECT', 'FROM', 'WHERE', // Read queries
      'DROP', 'DELETE', 'TRUNCATE', 'ALTER', // Destructive
      'EXEC', 'EXECUTE', 'UNION', 'INSERT', 'UPDATE', 'CREATE', // Manipulation
      'SCRIPT', 'JAVASCRIPT', // Injection
    ];
    
    var result = sanitized;
    for (final keyword in dangerousKeywords) {
      result = result.replaceAll(RegExp(keyword, caseSensitive: false), '');
    }
    
    return result.trim();
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    if (email.isEmpty) return false;
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      caseSensitive: false,
    );
    
    return emailRegex.hasMatch(email) && email.length <= 254;
  }

  /// Validate Indonesian phone number
  static bool isValidPhone(String phone) {
    if (phone.isEmpty) return false;
    
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    final phoneRegex = RegExp(r'^(\+62|62|0)8[0-9]{8,11}$');
    
    return phoneRegex.hasMatch(cleaned);
  }

  /// Sanitize username - allow alphanumeric, underscore, hyphen, dot, and
  /// forward-slash.
  /// - Dot (.)   is allowed: OPD/Kecamatan usernames use it as separator
  ///             (e.g. kec.soreang, kec.baleendah).
  /// - Slash (/) is allowed: OPD and Pimpinan accounts may use it as part of
  ///             their username (e.g. opd/soreang, pimpinan/dprd).
  ///             Without this, the "/" would be stripped and the username
  ///             lookup would fail, preventing login.
  static String sanitizeUsername(String input) {
    try {
      return input
          .trim()
          .replaceAll(RegExp(r'[^a-zA-Z0-9_.\-/]'), '')
          .toLowerCase();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Error sanitizing username: $e');
      }
      return '';
    }
  }

  /// Sanitize text - remove potential XSS characters (alias for sanitizeHtml)
  static String sanitizeText(String input) {
    return sanitizeHtml(input);
  }

  /// Sanitize phone number - only allow digits, spaces, +, -, (, )
  static String sanitizePhoneNumber(String input) {
    try {
      return input.trim().replaceAll(RegExp(r'[^0-9+\-() ]'), '');
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Error sanitizing phone number: $e');
      }
      return '';
    }
  }

  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'Email wajib diisi';
    }

    final sanitized = email.trim().toLowerCase();

    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(sanitized)) {
      return 'Format email tidak valid';
    }

    // Check for maximum length
    if (sanitized.length > 254) {
      return 'Email terlalu panjang';
    }

    return null;
  }

  /// Validate Indonesian phone number format
  static String? validatePhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'Nomor telepon wajib diisi';
    }

    final sanitized = sanitizePhoneNumber(phone);

    // Indonesian phone number patterns
    // Starting with 08, +62, or 62
    final phoneRegex = RegExp(
      r'^(08|^\+?62|62)[0-9]{8,13}$',
    );

    if (!phoneRegex.hasMatch(sanitized.replaceAll(RegExp(r'[\s\-()]'), ''))) {
      return 'Format nomor telepon Indonesia tidak valid';
    }

    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? url) {
    if (url == null || url.isEmpty) {
      return 'URL wajib diisi';
    }

    try {
      final uri = Uri.parse(url.trim());
      
      if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
        return 'URL harus dimulai dengan http:// atau https://';
      }

      if (!uri.hasAuthority) {
        return 'Format URL tidak valid';
      }

      return null;
    } catch (e) {
      return 'Format URL tidak valid';
    }
  }

  /// Check if URL is secure (HTTPS)
  static bool isSecureUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.scheme == 'https';
    } catch (e) {
      return false;
    }
  }

  /// Sanitize filename - remove dangerous characters
  static String sanitizeFilename(String input) {
    try {
      // Remove path traversal attempts and dangerous characters
      return input
          .trim()
          .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
          .replaceAll('..', '_');
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Error sanitizing filename: $e');
      }
      return 'file';
    }
  }

  /// Validate maximum length
  static String? validateMaxLength(
    String? value,
    int maxLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Use with other validators for required check
    }

    if (value.length > maxLength) {
      return '${fieldName ?? "Field"} maksimal $maxLength karakter';
    }

    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(
    String? value,
    int minLength, {
    String? fieldName,
  }) {
    if (value == null || value.isEmpty) {
      return null; // Use with other validators for required check
    }

    if (value.length < minLength) {
      return '${fieldName ?? "Field"} minimal $minLength karakter';
    }

    return null;
  }

  /// Combine multiple validators
  static String? Function(String?) combineValidators(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) {
          return error;
        }
      }
      return null;
    };
  }

  /// Check for SQL injection patterns (additional layer of security)
  static bool containsSqlInjectionPattern(String input) {
    final sqlPatterns = [
      RegExp(r"('|(--)|;|\/\*|\*\/|xp_|sp_)", caseSensitive: false),
      RegExp(r"(union|select|insert|update|delete|drop|create|alter)",
          caseSensitive: false),
    ];

    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(input)) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Potential SQL injection pattern detected');
        }
        return true;
      }
    }

    return false;
  }

  /// Check for XSS patterns
  static bool containsXssPattern(String input) {
    final xssPatterns = [
      RegExp(r"<script", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
      RegExp(r"onerror=", caseSensitive: false),
      RegExp(r"onload=", caseSensitive: false),
    ];

    for (final pattern in xssPatterns) {
      if (pattern.hasMatch(input)) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Potential XSS pattern detected');
        }
        return true;
      }
    }

    return false;
  }

  // Additional security methods from lib/security/input_sanitizer.dart

  /// Normalize whitespace
  static String normalizeWhitespace(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(RegExp(r'\n+'), '\n');
  }

  /// Remove all whitespace
  static String removeWhitespace(String input) {
    return input.replaceAll(RegExp(r'\s+'), '');
  }

  /// Trim string to maximum length
  static String trim(String input, {int maxLength = 1000}) {
    if (input.length <= maxLength) return input;
    return input.substring(0, maxLength);
  }

  /// Sanitize numeric only
  static String sanitizeNumeric(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Sanitize alphanumeric only
  static String sanitizeAlphanumeric(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Validate and sanitize URL
  static String? sanitizeUrl(String input) {
    try {
      final uri = Uri.parse(input);
      
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return null;
      }
      
      if (uri.host.isEmpty) {
        return null;
      }
      
      return uri.toString();
    } catch (e) {
      return null;
    }
  }

  /// Remove script tags and javascript
  static String removeScripts(String input) {
    return input
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', dotAll: true, caseSensitive: false), '')
        .replaceAll(RegExp(r'javascript:', caseSensitive: false), '')
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), '');
  }

  /// Sanitize file name to prevent path traversal
  static String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll('..', '')
        .replaceAll('./', '')
        .replaceAll('../', '')
        .trim();
  }

  /// Validate file extension
  static bool isValidFileExtension(String fileName, List<String> allowedExtensions) {
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.any((ext) => ext.toLowerCase() == '.$extension' || ext.toLowerCase() == extension);
  }

  /// Sanitize price/amount input
  static String sanitizePrice(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.,]'), '');
    final parts = cleaned.split(RegExp(r'[.,]'));
    if (parts.length > 2) {
      return '${parts[0]}.${parts.sublist(1).join('')}';
    }
    return cleaned;
  }

  /// Validate booking code format
  static bool isValidBookingCode(String code) {
    final codeRegex = RegExp(r'^BK[A-Z0-9]{6,8}$');
    return codeRegex.hasMatch(code.toUpperCase());
  }

  /// Sanitize text for display (prevent XSS in user-generated content)
  static String sanitizeForDisplay(String input) {
    return sanitizeHtml(removeScripts(input));
  }

  /// Validate Indonesian ID number (NIK - 16 digits)
  static bool isValidNIK(String nik) {
    final cleaned = sanitizeNumeric(nik);
    return cleaned.length == 16;
  }

  /// Sanitize search query
  static String sanitizeSearchQuery(String query) {
    final sanitized = query
        .trim()
        .replaceAll(RegExp(r'[<>{}[\]\\|]'), '') // Strip special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    // Limit length using sanitized length to prevent RangeError
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }

  /// Check for common attack patterns
  static bool containsMaliciousPattern(String input) {
    final maliciousPatterns = [
      r'<script',
      r'javascript:',
      r'onerror=',
      r'onload=',
      r'eval\(',
      r'base64,',
      r'\.\./\.\./\.\./\.\./etc/passwd',
      r'union\s+select',
      r'drop\s+table',
      r'exec\s+',
      r'cmd\.exe',
      r'/bin/bash',
    ];
    
    final lowerInput = input.toLowerCase();
    return maliciousPatterns.any((pattern) => 
      RegExp(pattern, caseSensitive: false).hasMatch(lowerInput)
    );
  }

  /// Validate Indonesian phone number format (alias for backward compatibility)
  static bool isValidIndonesianPhone(String phone) {
    return isValidPhone(phone);
  }

  /// Validate URL format
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.tryParse(url);
      return uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Validate and sanitize booking code
  static String? validateBookingCode(String code) {
    try {
      final sanitized = code.trim().toUpperCase();
      if (RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(sanitized)) {
        return sanitized;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Sanitize and validate amount/price input
  static String? sanitizeAmount(String input) {
    try {
      final cleaned = input.trim().replaceAll(RegExp(r'[^0-9.]'), '');
      if (cleaned.isEmpty) return null;

      final num? value = num.tryParse(cleaned);
      if (value == null || value < 0) return null;

      return cleaned;
    } catch (e) {
      return null;
    }
  }

  /// Comprehensive input validation with max length
  static String? validateInput({
    required String input,
    required String fieldName,
    int? maxLength,
    int? minLength,
    bool allowEmpty = false,
  }) {
    try {
      final trimmed = input.trim();

      if (!allowEmpty && trimmed.isEmpty) {
        return '$fieldName tidak boleh kosong';
      }

      if (minLength != null && trimmed.length < minLength) {
        return '$fieldName minimal $minLength karakter';
      }

      if (maxLength != null && trimmed.length > maxLength) {
        return '$fieldName maksimal $maxLength karakter';
      }

      return null;
    } catch (e) {
      return 'Input tidak valid';
    }
  }

  /// Check for malicious patterns (alias for containsMaliciousPattern)
  static bool containsMaliciousPatterns(String input) {
    return containsMaliciousPattern(input);
  }
}
