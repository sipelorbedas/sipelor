/// Comprehensive Input Sanitization Utility
/// Prevents XSS, SQL Injection, and other input-based attacks
library;

class InputSanitizer {
  /// Sanitize HTML to prevent XSS attacks
  static String sanitizeHtml(String input) {
    if (input.isEmpty) return input;
    
    final sanitized = input
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;')
        .replaceAll('&', '&amp;');
    
    return sanitized;
  }

  /// Sanitize SQL input to prevent SQL injection
  static String sanitizeSql(String input) {
    if (input.isEmpty) return input;
    
    // Remove or escape dangerous SQL characters and keywords
    final sanitized = input
        .replaceAll("'", '') // Remove single quotes (prevent SQL injection)
        .replaceAll('"', '') // Remove double quotes
        .replaceAll(';', '') // Remove semicolons
        .replaceAll('--', '') // Remove SQL line comments
        .replaceAll('/*', '') // Remove block comments
        .replaceAll('*/', '')
        .replaceAll('xp_', '') // Remove SQL Server extended procedures
        .replaceAll('sp_', ''); // Remove stored procedure calls
    
    // Remove dangerous SQL keywords (case insensitive)
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
    
    // Remove spaces and dashes
    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    // Check Indonesian phone number patterns
    // Formats: 08xxxxxxxxxx, +628xxxxxxxxxx, 628xxxxxxxxxx
    final phoneRegex = RegExp(r'^(\+62|62|0)8[0-9]{8,11}$');
    
    return phoneRegex.hasMatch(cleaned);
  }

  /// Sanitize and normalize whitespace
  static String normalizeWhitespace(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ') // Multiple spaces to single space
        .replaceAll(RegExp(r'\n+'), '\n'); // Multiple newlines to single
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

  /// Sanitize username (alphanumeric, underscore, dash only)
  static String sanitizeUsername(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }

  /// Sanitize alphanumeric only
  static String sanitizeAlphanumeric(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
  }

  /// Sanitize numeric only
  static String sanitizeNumeric(String input) {
    return input.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Validate and sanitize URL
  static String? sanitizeUrl(String input) {
    try {
      final uri = Uri.parse(input);
      
      // Only allow http and https schemes
      if (uri.scheme != 'http' && uri.scheme != 'https') {
        return null;
      }
      
      // Ensure host is present
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
        .replaceAll(RegExp(r'on\w+\s*=', caseSensitive: false), ''); // Remove event handlers
  }

  /// Sanitize file name to prevent path traversal
  static String sanitizeFileName(String fileName) {
    return fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '') // Remove invalid file name chars
        .replaceAll('..', '') // Prevent path traversal
        .replaceAll('./', '')
        .replaceAll('../', '')
        .trim();
  }

  /// Validate file extension
  static bool isValidFileExtension(String fileName, List<String> allowedExtensions) {
    final extension = fileName.toLowerCase().split('.').last;
    return allowedExtensions.any((ext) => ext.toLowerCase() == '.$extension');
  }

  /// Sanitize price/amount input
  static String sanitizePrice(String input) {
    // Keep only digits, comma, and period
    final cleaned = input.replaceAll(RegExp(r'[^0-9.,]'), '');
    
    // Remove multiple decimal separators
    final parts = cleaned.split(RegExp(r'[.,]'));
    if (parts.length > 2) {
      return '${parts[0]}.${parts.sublist(1).join('')}';
    }
    
    return cleaned;
  }

  /// Validate booking code format
  static bool isValidBookingCode(String code) {
    // Format: BK followed by 6-8 alphanumeric characters
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
        .replaceAll(RegExp(r'[<>{}[\]\\|]'), '') // Remove special chars
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize spaces
    // Limit length using sanitized string's own length to avoid RangeError
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }

  /// Check for common attack patterns
  static bool containsMaliciousPattern(String input) {
    final maliciousPatterns = [
      r'<script', // XSS
      r'javascript:', // XSS
      r'onerror=', // XSS
      r'onload=', // XSS
      r'eval\(', // Code injection
      r'base64,', // Base64 encoded attacks
      r'\.\./\.\./\.\./\.\./etc/passwd', // Path traversal
      r'union\s+select', // SQL injection
      r'drop\s+table', // SQL injection
      r'exec\s+', // Command injection
      r'cmd\.exe', // Command injection
      r'/bin/bash', // Command injection
    ];
    
    final lowerInput = input.toLowerCase();
    return maliciousPatterns.any((pattern) => 
      RegExp(pattern, caseSensitive: false).hasMatch(lowerInput)
    );
  }

  /// Comprehensive input validation
  static ValidationResult validate(String input, {
    required InputType type,
    int? maxLength,
    int? minLength,
    bool allowEmpty = false,
  }) {
    // Check empty
    if (!allowEmpty && input.trim().isEmpty) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Input tidak boleh kosong',
      );
    }

    // Check malicious patterns
    if (containsMaliciousPattern(input)) {
      return ValidationResult(
        isValid: false,
        sanitizedValue: '',
        error: 'Input mengandung karakter tidak valid',
      );
    }

    String sanitized;
    String? error;

    switch (type) {
      case InputType.email:
        sanitized = input.trim().toLowerCase();
        if (!isValidEmail(sanitized)) {
          error = 'Format email tidak valid';
        }
        break;

      case InputType.phone:
        sanitized = input.replaceAll(RegExp(r'[\s-]'), '');
        if (!isValidPhone(sanitized)) {
          error = 'Format nomor telepon tidak valid';
        }
        break;

      case InputType.username:
        sanitized = sanitizeUsername(input);
        if (minLength != null && sanitized.length < minLength) {
          error = 'Username minimal $minLength karakter';
        }
        break;

      case InputType.text:
        sanitized = sanitizeForDisplay(input);
        break;

      case InputType.numeric:
        sanitized = sanitizeNumeric(input);
        break;

      case InputType.price:
        sanitized = sanitizePrice(input);
        break;

      case InputType.url:
        final urlResult = sanitizeUrl(input);
        if (urlResult == null) {
          error = 'Format URL tidak valid';
          sanitized = '';
        } else {
          sanitized = urlResult;
        }
        break;

      default:
        sanitized = normalizeWhitespace(input);
    }

    // Check max length
    if (maxLength != null && sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }

    return ValidationResult(
      isValid: error == null,
      sanitizedValue: sanitized,
      error: error,
    );
  }
}

/// Input type enum
enum InputType {
  email,
  phone,
  username,
  text,
  numeric,
  price,
  url,
  general,
}

/// Validation result
class ValidationResult {
  final bool isValid;
  final String sanitizedValue;
  final String? error;

  ValidationResult({
    required this.isValid,
    required this.sanitizedValue,
    this.error,
  });
}
