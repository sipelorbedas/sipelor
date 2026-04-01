import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/secure_logger.dart';

void main() {
  group('SecureLogger', () {
    // SecureLogger only prints in debug mode (kDebugMode = true in test).
    // We test that calling these methods doesn't throw exceptions.

    test('log() does not throw', () {
      expect(() => SecureLogger.log('test message'), returnsNormally);
    });

    test('error() does not throw without error object', () {
      expect(() => SecureLogger.error('error message'), returnsNormally);
    });

    test('error() does not throw with error object', () {
      expect(
        () => SecureLogger.error('error message', Exception('test error')),
        returnsNormally,
      );
    });

    test('success() does not throw', () {
      expect(() => SecureLogger.success('success message'), returnsNormally);
    });

    test('warning() does not throw', () {
      expect(() => SecureLogger.warning('warning message'), returnsNormally);
    });

    test('info() does not throw', () {
      expect(() => SecureLogger.info('info message'), returnsNormally);
    });

    test('debug() does not throw', () {
      expect(() => SecureLogger.debug('debug message'), returnsNormally);
    });

    test('realtime() does not throw', () {
      expect(() => SecureLogger.realtime('realtime message'), returnsNormally);
    });
  });

  group('SecureLogger.isSecureUrl', () {
    test('https URL returns true', () {
      expect(SecureLogger.isSecureUrl('https://example.com'), isTrue);
      expect(SecureLogger.isSecureUrl('HTTPS://EXAMPLE.COM'), isTrue);
    });

    test('http URL returns false', () {
      expect(SecureLogger.isSecureUrl('http://example.com'), isFalse);
    });

    test('empty string returns false', () {
      expect(SecureLogger.isSecureUrl(''), isFalse);
    });

    test('ftp URL returns false', () {
      expect(SecureLogger.isSecureUrl('ftp://files.example.com'), isFalse);
    });
  });

  group('SecureLogger.validateUrl', () {
    test('https URL does not throw in any mode', () {
      expect(
        () => SecureLogger.validateUrl('https://example.com'),
        returnsNormally,
      );
    });

    test('http URL in debug mode does not throw', () {
      // kDebugMode is true in tests, so insecure URLs are allowed
      expect(
        () => SecureLogger.validateUrl('http://localhost:8080'),
        returnsNormally,
      );
    });
  });
}
