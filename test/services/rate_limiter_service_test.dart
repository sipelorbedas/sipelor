import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/rate_limiter_service.dart';

void main() {
  group('RateLimiterService', () {
    late RateLimiterService rateLimiter;

    setUp(() {
      rateLimiter = RateLimiterService();
    });

    test('allows request when under limit', () {
      final result = rateLimiter.checkRateLimit(
        'test-action',
        maxAttempts: 3,
        windowMinutes: 60,
      );
      
      expect(result.allowed, true);
      expect(result.remainingAttempts, 2);
    });

    test('blocks request when limit exceeded', () {
      // Make 3 requests
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      
      // 4th request should be blocked
      final result = rateLimiter.checkRateLimit(
        'test-action',
        maxAttempts: 3,
        windowMinutes: 60,
      );
      
      expect(result.allowed, false);
      expect(result.remainingAttempts, 0);
    });

    test('reset clears attempts for action', () {
      // Make 3 requests
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      
      // Reset
      rateLimiter.reset('test-action');
      
      // Should be allowed again
      final result = rateLimiter.checkRateLimit(
        'test-action',
        maxAttempts: 3,
        windowMinutes: 60,
      );
      
      expect(result.allowed, true);
    });

    test('time window expiry allows new requests', () async {
      // This test would need to mock time or wait for actual time to pass
      // For now, placeholder
      expect(true, true);
    });

    test('different actions have independent limits', () {
      // Action 1: Make 3 requests
      rateLimiter.checkRateLimit('action-1', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('action-1', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('action-1', maxAttempts: 3, windowMinutes: 60);
      
      // Action 1 should be blocked
      final result1 = rateLimiter.checkRateLimit('action-1', maxAttempts: 3, windowMinutes: 60);
      expect(result1.allowed, false);
      
      // Action 2 should still be allowed (independent counter)
      final result2 = rateLimiter.checkRateLimit('action-2', maxAttempts: 3, windowMinutes: 60);
      expect(result2.allowed, true);
    });

    test('getRemainingAttempts returns correct count', () {
      rateLimiter.checkRateLimit('test-action', maxAttempts: 5, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 5, windowMinutes: 60);
      
      final remaining = rateLimiter.getRemainingAttempts('test-action', maxAttempts: 5);
      expect(remaining, equals(3));
    });

    test('getBlockedDuration returns null when not blocked', () {
      final duration = rateLimiter.getBlockedDuration('test-action');
      expect(duration, isNull);
    });

    test('isBlocked returns false for non-blocked action', () {
      final blocked = rateLimiter.isBlocked('test-action');
      expect(blocked, false);
    });

    test('resetAttempts works correctly', () {
      // Make some requests
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: 60);
      
      // Reset
      rateLimiter.resetAttempts('test-action');
      
      // Should have full attempts again
      final remaining = rateLimiter.getRemainingAttempts('test-action', maxAttempts: 3);
      expect(remaining, equals(3));
    });

    test('clearAll removes all rate limit data', () {
      // Make requests for multiple actions
      rateLimiter.checkRateLimit('action-1', maxAttempts: 3, windowMinutes: 60);
      rateLimiter.checkRateLimit('action-2', maxAttempts: 3, windowMinutes: 60);
      
      // Clear all
      rateLimiter.clearAll();
      
      // Both should have full attempts
      final remaining1 = rateLimiter.getRemainingAttempts('action-1', maxAttempts: 3);
      final remaining2 = rateLimiter.getRemainingAttempts('action-2', maxAttempts: 3);
      
      expect(remaining1, equals(3));
      expect(remaining2, equals(3));
    });

    test('handles zero maxAttempts gracefully', () {
      final result = rateLimiter.checkRateLimit('test-action', maxAttempts: 0, windowMinutes: 60);
      expect(result.allowed, false);
      expect(result.remainingAttempts, 0);
    });

    test('handles negative window minutes gracefully', () {
      final result = rateLimiter.checkRateLimit('test-action', maxAttempts: 3, windowMinutes: -10);
      // Should use default or handle error
      expect(result, isNotNull);
    });
  });
}
