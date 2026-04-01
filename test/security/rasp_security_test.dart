import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/security/rasp_security.dart';

void main() {
  group('SecurityLevel enum', () {
    test('all values are distinct', () {
      final levels = SecurityLevel.values;
      expect(levels.toSet().length, levels.length);
    });

    test('safe is the first level', () {
      expect(SecurityLevel.values.first, SecurityLevel.safe);
    });

    test('critical is the most severe', () {
      expect(SecurityLevel.values.last, SecurityLevel.critical);
    });
  });

  group('RASPCheckResult', () {
    test('creates with isSafe=true correctly', () {
      final result = RASPCheckResult(
        isSafe: true,
        threats: [],
        securityLevel: SecurityLevel.safe,
      );
      expect(result.isSafe, true);
      expect(result.threats, isEmpty);
      expect(result.securityLevel, SecurityLevel.safe);
    });

    test('creates with threats correctly', () {
      final result = RASPCheckResult(
        isSafe: false,
        threats: ['Root access detected: /sbin/su'],
        securityLevel: SecurityLevel.danger,
      );
      expect(result.isSafe, false);
      expect(result.threats.length, 1);
      expect(result.securityLevel, SecurityLevel.danger);
    });
  });

  group('RASPSecurity.getSecurityMessage', () {
    test('returns safe message for SecurityLevel.safe', () {
      final result = RASPCheckResult(
        isSafe: true,
        threats: [],
        securityLevel: SecurityLevel.safe,
      );
      final msg = RASPSecurity.getSecurityMessage(result);
      expect(msg, contains('aman'));
    });

    test('returns warning message for SecurityLevel.warning', () {
      final result = RASPCheckResult(
        isSafe: true,
        threats: ['Running in debug mode'],
        securityLevel: SecurityLevel.warning,
      );
      final msg = RASPSecurity.getSecurityMessage(result);
      expect(msg.toLowerCase(), anyOf(contains('tidak normal'), contains('dibatasi')));
    });

    test('returns danger message for SecurityLevel.danger', () {
      final result = RASPCheckResult(
        isSafe: false,
        threats: ['Emulator detected'],
        securityLevel: SecurityLevel.danger,
      );
      final msg = RASPSecurity.getSecurityMessage(result);
      expect(msg.toUpperCase(), contains('PERINGATAN'));
    });

    test('returns critical message for SecurityLevel.critical', () {
      final result = RASPCheckResult(
        isSafe: false,
        threats: ['Root access detected', 'Frida server detected'],
        securityLevel: SecurityLevel.critical,
      );
      final msg = RASPSecurity.getSecurityMessage(result);
      expect(msg.toUpperCase(), contains('BAHAYA'));
    });
  });

  group('RASPSecurity.performSecurityCheck (non-native context)', () {
    test('returns valid RASPCheckResult', () async {
      // On test runner (non-native), security check should not throw
      expect(
        () async => await RASPSecurity.performSecurityCheck(),
        returnsNormally,
      );
    });

    test('result has consistent isSafe relative to securityLevel', () async {
      final result = await RASPSecurity.performSecurityCheck();
      if (result.securityLevel == SecurityLevel.critical) {
        expect(result.isSafe, false);
      }
      if (result.securityLevel == SecurityLevel.safe) {
        expect(result.isSafe, true);
      }
    });
  });

  group('RASPSecurity.shouldAllowExecution', () {
    test('returns a boolean value', () async {
      final allowed = await RASPSecurity.shouldAllowExecution();
      expect(allowed, isA<bool>());
    });
  });
}
