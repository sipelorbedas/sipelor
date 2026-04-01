import 'package:flutter/foundation.dart';

/// Secure logger that only prints in debug mode
/// Use this instead of direct print() statements to prevent
/// sensitive information leakage in production builds
class SecureLogger {
  /// Log general information (only in debug mode)
  static void log(String message) {
    if (kDebugMode) {
      if (kDebugMode) print(message);
    }
  }

  /// Log error messages (only in debug mode)
  static void error(String message, [dynamic error]) {
    if (kDebugMode) {
      if (kDebugMode) print('❌ $message');
      if (error != null) {
        if (kDebugMode) print('Error details: $error');
      }
    }
  }

  /// Log success messages (only in debug mode)
  static void success(String message) {
    if (kDebugMode) {
      if (kDebugMode) print('✅ $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String message) {
    if (kDebugMode) {
      if (kDebugMode) print('⚠️  $message');
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String message) {
    if (kDebugMode) {
      if (kDebugMode) print('📝 $message');
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message) {
    if (kDebugMode) {
      if (kDebugMode) print('🔍 $message');
    }
  }

  /// Log realtime/subscription messages (only in debug mode)
  static void realtime(String message) {
    if (kDebugMode) {
      if (kDebugMode) print('📡 $message');
    }
  }

  /// Check if secure URL (HTTPS)
  static bool isSecureUrl(String url) {
    return url.toLowerCase().startsWith('https://');
  }

  /// Validate URL security
  static void validateUrl(String url) {
    if (!isSecureUrl(url) && !kDebugMode) {
      throw Exception('Insecure URL detected in production: Only HTTPS URLs are allowed');
    }
  }
}
