import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/session_manager.dart';

void main() {
  setUp(() {
    // Reset state before each test
    SessionManager.reset();
    SessionManager.setTimeout(const Duration(minutes: 30));
  });

  group('SessionManager.updateActivity', () {
    test('updates last activity timestamp', () {
      SessionManager.updateActivity();
      // After update, session should not be expired immediately
      expect(SessionManager.isSessionExpired(), isFalse);
    });
  });

  group('SessionManager.isSessionExpired', () {
    test('returns false when no activity recorded', () {
      // No activity set yet
      expect(SessionManager.isSessionExpired(), isFalse);
    });

    test('returns false immediately after activity update', () {
      SessionManager.updateActivity();
      expect(SessionManager.isSessionExpired(), isFalse);
    });

    test('returns true after timeout duration', () async {
      // Set very short timeout
      SessionManager.setTimeout(const Duration(milliseconds: 1));
      SessionManager.updateActivity();
      // Wait slightly longer than timeout
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(SessionManager.isSessionExpired(), isTrue);
    });
  });

  group('SessionManager.setTimeout', () {
    test('changes the timeout duration', () {
      SessionManager.setTimeout(const Duration(hours: 2));
      SessionManager.updateActivity();
      expect(SessionManager.isSessionExpired(), isFalse);
    });

    test('very short timeout causes immediate expiry', () async {
      SessionManager.setTimeout(const Duration(milliseconds: 5));
      SessionManager.updateActivity();
      await Future.delayed(const Duration(milliseconds: 20));
      expect(SessionManager.isSessionExpired(), isTrue);
    });
  });

  group('SessionManager.getTimeUntilExpiry', () {
    test('returns null when no activity recorded', () {
      expect(SessionManager.getTimeUntilExpiry(), isNull);
    });

    test('returns non-null duration after activity', () {
      SessionManager.updateActivity();
      final remaining = SessionManager.getTimeUntilExpiry();
      expect(remaining, isNotNull);
      expect(remaining!.inMinutes, greaterThan(0));
    });

    test('returns zero when session is expired', () async {
      SessionManager.setTimeout(const Duration(milliseconds: 5));
      SessionManager.updateActivity();
      await Future.delayed(const Duration(milliseconds: 20));
      final remaining = SessionManager.getTimeUntilExpiry();
      expect(remaining, equals(Duration.zero));
    });
  });

  group('SessionManager.reset', () {
    test('clears last activity', () {
      SessionManager.updateActivity();
      SessionManager.reset();
      // After reset, getTimeUntilExpiry returns null
      expect(SessionManager.getTimeUntilExpiry(), isNull);
    });

    test('session not expired after reset', () {
      SessionManager.updateActivity();
      SessionManager.reset();
      expect(SessionManager.isSessionExpired(), isFalse);
    });
  });

  group('SessionManager.initialize', () {
    test('sets initial activity timestamp', () {
      SessionManager.initialize();
      expect(SessionManager.isSessionExpired(), isFalse);
    });

    test('getTimeUntilExpiry returns positive after initialize', () {
      SessionManager.initialize();
      final remaining = SessionManager.getTimeUntilExpiry();
      expect(remaining, isNotNull);
    });
  });

  group('SessionManager.defaultTimeout', () {
    test('default timeout is 30 minutes', () {
      expect(SessionManager.defaultTimeout, equals(const Duration(minutes: 30)));
    });
  });
}
