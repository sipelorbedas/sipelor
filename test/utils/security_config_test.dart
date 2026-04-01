import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/config/security_config.dart';

void main() {
  group('SecurityConfig - Password Policy', () {
    test('min password length is 8', () {
      expect(SecurityConfig.minPasswordLength, 8);
    });

    test('max password length is 128', () {
      expect(SecurityConfig.maxPasswordLength, 128);
    });

    test('recommended password length >= min', () {
      expect(SecurityConfig.recommendedPasswordLength,
          greaterThanOrEqualTo(SecurityConfig.minPasswordLength));
    });

    test('all complexity requirements are enabled', () {
      expect(SecurityConfig.requireUppercase, isTrue);
      expect(SecurityConfig.requireLowercase, isTrue);
      expect(SecurityConfig.requireNumber, isTrue);
      expect(SecurityConfig.requireSpecialChar, isTrue);
    });
  });

  group('SecurityConfig - Rate Limiting', () {
    test('maxLoginAttempts is between 3 and 10', () {
      expect(SecurityConfig.maxLoginAttempts, inInclusiveRange(3, 10));
    });

    test('loginBlockDuration is reasonable (> 0 minutes)', () {
      expect(SecurityConfig.loginBlockDuration, greaterThan(0));
    });

    test('maxPasswordResetAttempts is between 1 and 5', () {
      expect(SecurityConfig.maxPasswordResetAttempts, inInclusiveRange(1, 5));
    });

    test('maxBookingAttempts is reasonable', () {
      expect(SecurityConfig.maxBookingAttempts, greaterThan(0));
    });
  });

  group('SecurityConfig - Session Management', () {
    test('autoLogoutDuration is between 5 and 60 minutes', () {
      expect(SecurityConfig.autoLogoutDuration, inInclusiveRange(5, 60));
    });

    test('sessionTokenExpiration is between 1 and 24 hours', () {
      expect(SecurityConfig.sessionTokenExpiration, inInclusiveRange(1, 24));
    });

    test('refreshTokenExpiration is between 1 and 90 days', () {
      expect(SecurityConfig.refreshTokenExpiration, inInclusiveRange(1, 90));
    });
  });

  group('SecurityConfig - Network Security', () {
    test('HTTPS is required', () {
      expect(SecurityConfig.requireHttps, isTrue);
    });

    test('SSL pinning is enabled', () {
      expect(SecurityConfig.sslPinningEnabled, isTrue);
    });

    test('request timeout is between 10 and 60 seconds', () {
      expect(SecurityConfig.requestTimeout, inInclusiveRange(10, 60));
    });
  });

  group('SecurityConfig - Input Validation', () {
    test('max username length is reasonable', () {
      expect(SecurityConfig.maxUsernameLength, greaterThan(SecurityConfig.minUsernameLength));
    });

    test('max email length is 254 (RFC 5321 limit)', () {
      expect(SecurityConfig.maxEmailLength, 254);
    });

    test('max text length is positive', () {
      expect(SecurityConfig.maxTextLength, greaterThan(0));
    });
  });

  group('SecurityConfig - File Upload', () {
    test('maxFileSize is between 1 and 50 MB', () {
      expect(SecurityConfig.maxFileSize, inInclusiveRange(1, 50));
    });

    test('allowedImageExtensions includes common formats', () {
      expect(SecurityConfig.allowedImageExtensions, contains('.jpg'));
      expect(SecurityConfig.allowedImageExtensions, contains('.jpeg'));
      expect(SecurityConfig.allowedImageExtensions, contains('.png'));
    });

    test('allowedDocExtensions includes PDF', () {
      expect(SecurityConfig.allowedDocExtensions, contains('.pdf'));
    });
  });

  group('SecurityConfig - Audit Logging', () {
    test('audit logging is enabled', () {
      expect(SecurityConfig.auditLoggingEnabled, isTrue);
    });

    test('log retention is at least 30 days', () {
      expect(SecurityConfig.logRetentionDays, greaterThanOrEqualTo(30));
    });

    test('key security events are in audit list', () {
      expect(SecurityConfig.auditEvents, contains('LOGIN_SUCCESS'));
      expect(SecurityConfig.auditEvents, contains('LOGIN_FAILURE'));
      expect(SecurityConfig.auditEvents, contains('BOOKING_CREATE'));
      expect(SecurityConfig.auditEvents, contains('PERMISSION_DENIED'));
    });
  });

  group('SecurityConfig - getSummary', () {
    test('returns non-empty map', () {
      final summary = SecurityConfig.getSummary();
      expect(summary, isNotEmpty);
      expect(summary.containsKey('password_policy'), isTrue);
      expect(summary.containsKey('rate_limiting'), isTrue);
      expect(summary.containsKey('session'), isTrue);
      expect(summary.containsKey('security'), isTrue);
    });
  });
}
