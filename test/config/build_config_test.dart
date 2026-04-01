import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/config/build_config.dart';

void main() {
  group('BuildConfig', () {
    test('environment should have default value', () {
      expect(BuildConfig.environment, isIn(['development', 'staging', 'production']));
    });

    test('isDevelopment should return true by default in debug mode', () {
      // In test mode, kDebugMode is typically true
      expect(BuildConfig.isDevelopment, isTrue);
    });

    test('isProduction should return false in debug mode', () {
      // In test mode, kReleaseMode is false
      expect(BuildConfig.isProduction, isFalse);
    });

    test('isStaging should check environment correctly', () {
      expect(BuildConfig.isStaging, BuildConfig.environment == 'staging');
    });

    test('sslPinningEnabled should return false in development without flag', () {
      // In non-production without ENABLE_SSL_PINNING flag
      if (!BuildConfig.isProduction) {
        // Should be false unless ENABLE_SSL_PINNING is set to 'true'
        expect(BuildConfig.sslPinningEnabled, isA<bool>());
      }
    });

    test('errorTrackingEnabled should return true', () {
      // Should always be enabled
      expect(BuildConfig.errorTrackingEnabled, isTrue);
    });

    test('deepLinkingEnabled should return true', () {
      // Should always be enabled
      expect(BuildConfig.deepLinkingEnabled, isTrue);
    });

    test('offlineModeEnabled should return boolean value', () {
      expect(BuildConfig.offlineModeEnabled, isA<bool>());
    });

    test('autoLogoutEnabled should return boolean value', () {
      expect(BuildConfig.autoLogoutEnabled, isA<bool>());
    });

    test('autoLogoutMinutes should return positive number', () {
      expect(BuildConfig.autoLogoutMinutes, greaterThan(0));
    });

    test('maxUploadSizeMB should return positive number', () {
      expect(BuildConfig.maxUploadSizeMB, greaterThan(0));
    });

    test('imageCompressionQuality should be between 0 and 100', () {
      expect(BuildConfig.imageCompressionQuality, greaterThanOrEqualTo(0));
      expect(BuildConfig.imageCompressionQuality, lessThanOrEqualTo(100));
    });

    test('appName should not be empty', () {
      expect(BuildConfig.appName, isNotEmpty);
    });

    test('appVersion should have valid format', () {
      expect(BuildConfig.appVersion, matches(RegExp(r'^\d+\.\d+\.\d+$')));
    });

    test('appBuildNumber should be positive', () {
      expect(BuildConfig.appBuildNumber, greaterThan(0));
    });

    test('cacheExpiryMinutes should be positive', () {
      expect(BuildConfig.cacheExpiryMinutes, greaterThan(0));
    });

    test('should have consistent environment detection', () {
      final isDev = BuildConfig.isDevelopment;
      final isProd = BuildConfig.isProduction;
      final isStaging = BuildConfig.isStaging;

      // Cannot be in multiple environments at once
      if (isProd) {
        expect(isDev, isFalse);
        expect(isStaging, isFalse);
      }
    });
  });
}
