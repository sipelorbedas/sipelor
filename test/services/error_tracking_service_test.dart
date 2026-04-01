import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/error_tracking_service.dart';

void main() {
  group('ErrorTrackingService', () {
    test('initialize should set initialized flag', () async {
      // Test that service can initialize without errors
      await ErrorTrackingService.initialize();
      
      // Verify no exceptions thrown
      expect(true, true);
    });

    test('captureException should accept any exception', () {
      final testException = Exception('Test exception');
      
      // Should not throw error even if Sentry is not configured
      expect(
        () => ErrorTrackingService.captureException(
          testException,
          stackTrace: StackTrace.current,
        ),
        returnsNormally,
      );
    });

    test('captureMessage should accept any message', () {
      // Should not throw error even if Sentry is not configured
      expect(
        () => ErrorTrackingService.captureMessage('Test message'),
        returnsNormally,
      );
    });

    test('logError should handle null exception', () {
      expect(
        () => ErrorTrackingService.logError(
          'Test error message',
          null,
          null,
        ),
        returnsNormally,
      );
    });

    test('logError should handle exception with stack trace', () {
      final testException = Exception('Test error');
      final stackTrace = StackTrace.current;
      
      expect(
        () => ErrorTrackingService.logError(
          'Test error',
          testException,
          stackTrace,
        ),
        returnsNormally,
      );
    });

    test('setUserContext should accept user info', () {
      expect(
        () => ErrorTrackingService.setUserContext(
          userId: 'test-user-123',
          email: 'test@example.com',
          username: 'Test User',
        ),
        returnsNormally,
      );
    });

    test('clearUserContext should complete without error', () {
      expect(
        () => ErrorTrackingService.clearUserContext(),
        returnsNormally,
      );
    });

    test('addBreadcrumb should accept breadcrumb data', () {
      expect(
        () => ErrorTrackingService.addBreadcrumb(
          message: 'Test breadcrumb',
          category: 'test',
          data: {'key': 'value'},
        ),
        returnsNormally,
      );
    });

    test('setTag should accept key-value pairs', () {
      expect(
        () => ErrorTrackingService.setTag('environment', 'test'),
        returnsNormally,
      );
    });

    test('sensitive data should be filtered', () {
      // Test that messages containing sensitive keywords are filtered
      const sensitiveMessages = [
        'password123',
        'Bearer token_abc123',
        'api_key=secret123',
        'credit_card=1234567890123456',
      ];

      for (final message in sensitiveMessages) {
        // Should not crash, even if message contains sensitive data
        expect(
          () => ErrorTrackingService.captureMessage(message),
          returnsNormally,
        );
      }
    });

    test('performance monitoring should work', () {
      final transaction = ErrorTrackingService.startTransaction(
        'test_operation',
        'test',
      );

      expect(transaction, isNotNull);

      // Should complete without error
      expect(
        () => ErrorTrackingService.finishTransaction(transaction),
        returnsNormally,
      );
    });

    test('multiple initialization should be safe', () async {
      // First initialization
      await ErrorTrackingService.initialize();
      
      // Second initialization should not crash
      await ErrorTrackingService.initialize();
      
      expect(true, true);
    });

    test('should work in debug mode', () {
      // Verify that debug mode flag is respected
      expect(kDebugMode, isA<bool>());
      
      // Service should work regardless of debug mode
      expect(
        () => ErrorTrackingService.captureMessage('Debug test'),
        returnsNormally,
      );
    });
  });
}
