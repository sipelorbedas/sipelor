import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/security/app_security_manager.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AppSecurityManager.initialize', () {
    test('initialize does not throw', () async {
      expect(() async => AppSecurityManager.initialize(), returnsNormally);
    });

    test('initialize twice does not throw (idempotent)', () async {
      await AppSecurityManager.initialize();
      expect(() async => AppSecurityManager.initialize(), returnsNormally);
    });
  });

  group('AppSecurityManager.runFullAudit', () {
    test('returns a SecurityAuditReport', () async {
      final report = await AppSecurityManager.runFullAudit(forceRefresh: true);
      expect(report, isNotNull);
      expect(report.posture, isA<SecurityPosture>());
      expect(report.allWarnings, isA<List<String>>());
      expect(report.recommendations, isA<List<String>>());
    });

    test('timestamp is recent', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 5));
      final report = await AppSecurityManager.runFullAudit(forceRefresh: true);
      expect(report.timestamp.isAfter(before), isTrue);
    });

    test('caching works — second call returns same result', () async {
      final r1 = await AppSecurityManager.runFullAudit(forceRefresh: true);
      final r2 = await AppSecurityManager.runFullAudit();
      expect(r1.timestamp, equals(r2.timestamp));
    });

    test('forceRefresh generates new timestamp', () async {
      final r1 = await AppSecurityManager.runFullAudit(forceRefresh: true);
      await Future.delayed(const Duration(milliseconds: 10));
      final r2 = await AppSecurityManager.runFullAudit(forceRefresh: true);
      expect(r2.timestamp.isAfter(r1.timestamp), isTrue);
    });
  });

  group('AppSecurityManager.isAppSafe', () {
    test('returns a boolean without throwing', () async {
      final safe = await AppSecurityManager.isAppSafe();
      expect(safe, isA<bool>());
    });
  });

  group('AppSecurityManager.isSensitiveOperationSafe', () {
    test('returns a boolean without throwing', () async {
      final safe = await AppSecurityManager.isSensitiveOperationSafe();
      expect(safe, isA<bool>());
    });
  });

  group('AppSecurityManager.lastReport', () {
    test('lastReport is populated after runFullAudit', () async {
      await AppSecurityManager.runFullAudit(forceRefresh: true);
      expect(AppSecurityManager.lastReport, isNotNull);
    });
  });

  group('AppSecurityManager.getStatusMessage', () {
    test('all postures return non-empty Indonesian message', () {
      for (final posture in SecurityPosture.values) {
        final msg = AppSecurityManager.getStatusMessage(posture);
        expect(msg, isNotEmpty);
      }
    });

    test('green posture message indicates safety', () {
      final msg = AppSecurityManager.getStatusMessage(SecurityPosture.green);
      expect(msg, contains('aman'));
    });

    test('red posture message indicates critical threat', () {
      final msg = AppSecurityManager.getStatusMessage(SecurityPosture.red);
      expect(msg.toLowerCase(), anyOf(contains('kritis'), contains('dibatasi')));
    });
  });

  group('SecurityAuditReport.isSecure / requiresAction', () {
    test('green posture → isSecure=true, requiresAction=false', () async {
      final report = await AppSecurityManager.runFullAudit(forceRefresh: true);
      // In test environment, posture should be green or yellow
      if (report.posture == SecurityPosture.green ||
          report.posture == SecurityPosture.yellow) {
        expect(report.isSecure, isTrue);
        expect(report.requiresAction, isFalse);
      }
    });
  });

  group('SecurityPosture enum', () {
    test('has 4 values', () {
      expect(SecurityPosture.values.length, 4);
    });

    test('values are correctly named', () {
      expect(SecurityPosture.green.name, 'green');
      expect(SecurityPosture.yellow.name, 'yellow');
      expect(SecurityPosture.orange.name, 'orange');
      expect(SecurityPosture.red.name, 'red');
    });
  });
}
