import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/config/ssl_config.dart';

void main() {
  group('SSLConfig - Certificate Pins', () {
    test('primaryCertificatePin starts with sha256/', () {
      expect(SSLConfig.primaryCertificatePin.startsWith('sha256/'), true);
    });

    test('backupCertificatePin starts with sha256/', () {
      expect(SSLConfig.backupCertificatePin.startsWith('sha256/'), true);
    });

    test('certificatePins contains at least 2 pins for redundancy', () {
      expect(SSLConfig.certificatePins.length, greaterThanOrEqualTo(2));
    });

    test('pins are not empty strings', () {
      for (final pin in SSLConfig.certificatePins) {
        expect(pin.length, greaterThan(7)); // "sha256/" = 7 chars
      }
    });

    test('primary and backup pins are different', () {
      expect(
        SSLConfig.primaryCertificatePin,
        isNot(SSLConfig.backupCertificatePin),
      );
    });
  });

  group('SSLConfig - Domain Configuration', () {
    test('supabaseDomain is not empty', () {
      expect(SSLConfig.supabaseDomain, isNotEmpty);
    });

    test('supabaseDomain points to supabase.co', () {
      expect(SSLConfig.supabaseDomain, contains('supabase.co'));
    });

    test('pinnedDomains includes main domain and wildcard', () {
      expect(SSLConfig.pinnedDomains, contains(SSLConfig.supabaseDomain));
      expect(SSLConfig.pinnedDomains.any((d) => d.contains('*.supabase')), true);
    });
  });

  group('SSLConfig - Environment Detection', () {
    test('isProduction and isDevelopment are mutually exclusive', () {
      // In test environment, one must be true
      expect(SSLConfig.isProduction != SSLConfig.isDevelopment, true);
    });

    test('allowBypassOnFailure is true only in development', () {
      if (SSLConfig.isDevelopment) {
        expect(SSLConfig.allowBypassOnFailure, true);
      } else {
        expect(SSLConfig.allowBypassOnFailure, false);
      }
    });
  });

  group('SSLConfig - Validation', () {
    test('validate() returns true with correct configuration', () {
      expect(SSLConfig.validate(), true);
    });

    test('getCertificateInfo() returns correct keys', () {
      final info = SSLConfig.getCertificateInfo();
      expect(info.containsKey('ssl_pinning_enabled'), true);
      expect(info.containsKey('pinned_domain'), true);
      expect(info.containsKey('primary_pin'), true);
      expect(info.containsKey('backup_pin'), true);
      expect(info.containsKey('last_updated'), true);
      expect(info.containsKey('next_review'), true);
    });

    test('getCertificateInfo() primary_pin is truncated', () {
      final info = SSLConfig.getCertificateInfo();
      final pin = info['primary_pin'] as String;
      expect(pin.endsWith('...'), true);
    });
  });

  group('SSLConfig - Expiry Warning', () {
    test('getCertificateExpiryWarning returns String or null', () {
      final warning = SSLConfig.getCertificateExpiryWarning();
      // Either null (not yet due for review) or a non-empty warning string
      if (warning != null) {
        expect(warning, isNotEmpty);
      }
    });

    test('sslHandshakeTimeout is a positive number', () {
      expect(SSLConfig.sslHandshakeTimeout, greaterThan(0));
    });
  });
}
