/// Security configuration for the SIPELOR application
/// Contains security-related constants and settings
class SecurityConfig {
  // ==================== Password Policy ====================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Maximum password length (prevent DoS)
  static const int maxPasswordLength = 128;

  /// Recommended password length
  static const int recommendedPasswordLength = 12;

  /// Require uppercase in password
  static const bool requireUppercase = true;

  /// Require lowercase in password
  static const bool requireLowercase = true;

  /// Require number in password
  static const bool requireNumber = true;

  /// Require special character in password
  static const bool requireSpecialChar = true;

  // ==================== Rate Limiting ====================

  /// Maximum login attempts before blocking
  static const int maxLoginAttempts = 5;

  /// Login rate limit window (minutes)
  static const int loginRateLimitWindow = 15;

  /// Login block duration after max attempts (minutes)
  static const int loginBlockDuration = 30;

  /// Maximum password reset attempts
  static const int maxPasswordResetAttempts = 3;

  /// Password reset rate limit window (hours)
  static const int passwordResetWindow = 1;

  /// Password reset block duration (hours)
  static const int passwordResetBlockDuration = 2;

  /// Maximum booking creation attempts per hour
  static const int maxBookingAttempts = 10;

  /// Booking rate limit window (hours)
  static const int bookingRateLimitWindow = 1;

  // ==================== Session Management ====================

  /// Auto logout inactivity duration (minutes)
  static const int autoLogoutDuration = 10;

  /// Session token expiration (hours)
  static const int sessionTokenExpiration = 24;

  /// Refresh token expiration (days)
  static const int refreshTokenExpiration = 30;

  // ==================== Booking Security ====================

  /// Payment timeout for bookings (minutes)
  static const int paymentTimeout = 30;

  /// Booking expiration check interval (minutes)
  static const int expirationCheckInterval = 1;

  // ==================== Input Validation ====================

  /// Maximum username length
  static const int maxUsernameLength = 30;

  /// Minimum username length
  static const int minUsernameLength = 3;

  /// Maximum email length
  static const int maxEmailLength = 254;

  /// Maximum text field length
  static const int maxTextLength = 1000;

  /// Maximum phone number length
  static const int maxPhoneLength = 20;

  // ==================== File Upload Security ====================

  /// Maximum file size for uploads (MB)
  static const int maxFileSize = 10;

  /// Allowed image extensions
  static const List<String> allowedImageExtensions = [
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
  ];

  /// Allowed document extensions
  static const List<String> allowedDocExtensions = ['.pdf'];

  // ==================== Network Security ====================

  /// Require HTTPS for all API calls
  static const bool requireHttps = true;

  /// SSL pinning enabled (production only)
  /// IMPLEMENTATION: Configured in lib/config/ssl_config.dart
  /// Auto-enabled in production builds, disabled in development
  static const bool sslPinningEnabled = true; // ✅ Enabled (see ssl_config.dart)

  /// Request timeout (seconds)
  static const int requestTimeout = 30;

  // ==================== Biometric Authentication ====================

  /// Allow biometric authentication
  static const bool allowBiometric = true;

  /// Biometric timeout (seconds)
  static const int biometricTimeout = 30;

  // ==================== Audit Logging ====================

  /// Enable security audit logging
  static const bool auditLoggingEnabled = true;

  /// Log retention period (days)
  static const int logRetentionDays = 90;

  /// Events to log
  static const List<String> auditEvents = [
    'LOGIN_SUCCESS',
    'LOGIN_FAILURE',
    'LOGOUT',
    'PASSWORD_CHANGE',
    'PASSWORD_RESET',
    'ROLE_CHANGE',
    'BOOKING_CREATE',
    'BOOKING_APPROVE',
    'BOOKING_CANCEL',
    'ACCOUNT_DELETE',
    'PERMISSION_DENIED',
  ];

  // ==================== Developer Mode ====================

  /// Enable debug logging (automatically set by kDebugMode)
  static bool get debugLoggingEnabled {
    // In debug mode: true, in release mode: false
    bool isDebug = false;
    assert(() {
      isDebug = true;
      return true;
    }());
    return isDebug;
  }

  /// Allow insecure connections in debug (NEVER in production)
  static bool get allowInsecureDebug => false;

  // ==================== Helper Methods ====================

  /// Check if environment is production
  static bool get isProduction {
    // Automatically detect production mode
    // In production: kDebugMode = false, kReleaseMode = true
    return !debugLoggingEnabled;
  }

  /// Get security configuration summary
  static Map<String, dynamic> getSummary() {
    return {
      'password_policy': {
        'min_length': minPasswordLength,
        'max_length': maxPasswordLength,
        'require_uppercase': requireUppercase,
        'require_lowercase': requireLowercase,
        'require_number': requireNumber,
        'require_special_char': requireSpecialChar,
      },
      'rate_limiting': {
        'max_login_attempts': maxLoginAttempts,
        'login_block_duration_minutes': loginBlockDuration,
      },
      'session': {
        'auto_logout_minutes': autoLogoutDuration,
        'session_expiration_hours': sessionTokenExpiration,
      },
      'security': {
        'require_https': requireHttps,
        'ssl_pinning': sslPinningEnabled,
        'audit_logging': auditLoggingEnabled,
      },
    };
  }
}
