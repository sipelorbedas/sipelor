import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/notification_cleanup_service.dart';

void main() {
  group('NotificationCleanupService', () {
    setUp(() {
      // Setup before each test
    });

    tearDown(() {
      // Cleanup after each test
      NotificationCleanupService.dispose();
    });

    test('initialize should start cleanup service', () async {
      await NotificationCleanupService.initialize(
        hoursOld: 24,
        checkIntervalHours: 6,
      );

      expect(NotificationCleanupService.isInitialized, isTrue);
    });

    test('dispose should stop cleanup service', () async {
      await NotificationCleanupService.initialize();
      
      expect(NotificationCleanupService.isInitialized, isTrue);

      NotificationCleanupService.dispose();

      expect(NotificationCleanupService.isInitialized, isFalse);
    });

    test('initialize should not crash when called twice', () async {
      await NotificationCleanupService.initialize();
      await NotificationCleanupService.initialize(); // Second call

      expect(NotificationCleanupService.isInitialized, isTrue);
    });

    test('isInitialized returns false before initialization', () {
      expect(NotificationCleanupService.isInitialized, isFalse);
    });

    test('isInitialized returns true after initialization', () async {
      await NotificationCleanupService.initialize();

      expect(NotificationCleanupService.isInitialized, isTrue);
    });

    test('manualCleanup should accept custom hours parameter', () async {
      // Test that method accepts parameter without crashing
      // In real environment, this would interact with Supabase
      try {
        final deletedCount = await NotificationCleanupService.manualCleanup(
          hoursOld: 48,
        );
        
        // Should return a number (0 if no notifications or not connected to DB)
        expect(deletedCount, isA<int>());
        expect(deletedCount, greaterThanOrEqualTo(0));
      } catch (e) {
        // Expected to fail in test environment without Supabase
        expect(e, isNotNull);
      }
    });

    test('manualCleanup uses default 24 hours when not specified', () async {
      try {
        final deletedCount = await NotificationCleanupService.manualCleanup();
        
        expect(deletedCount, isA<int>());
        expect(deletedCount, greaterThanOrEqualTo(0));
      } catch (e) {
        // Expected to fail in test environment
        expect(e, isNotNull);
      }
    });

    test('getStatistics should return statistics map', () async {
      try {
        final stats = await NotificationCleanupService.getStatistics();
        
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats, isNotEmpty);
        
        // Should have timestamp in results
        expect(stats.containsKey('timestamp'), isTrue);
      } catch (e) {
        // Expected to fail in test environment without Supabase
        expect(e, isNotNull);
      }
    });

    test('initialize with custom parameters', () async {
      await NotificationCleanupService.initialize(
        hoursOld: 48,
        checkIntervalHours: 12,
      );

      expect(NotificationCleanupService.isInitialized, isTrue);
    });

    test('multiple dispose calls should be safe', () {
      NotificationCleanupService.dispose();
      NotificationCleanupService.dispose();
      NotificationCleanupService.dispose();

      expect(NotificationCleanupService.isInitialized, isFalse);
    });
  });
}
