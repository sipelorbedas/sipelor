import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/security/anti_tamper_guard.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('AntiTamperGuard.sha256Hash', () {
    test('produces consistent hash for same input', () {
      final h1 = AntiTamperGuard.sha256Hash('sipelor');
      final h2 = AntiTamperGuard.sha256Hash('sipelor');
      expect(h1, equals(h2));
    });

    test('different inputs produce different hashes', () {
      final h1 = AntiTamperGuard.sha256Hash('input1');
      final h2 = AntiTamperGuard.sha256Hash('input2');
      expect(h1, isNot(equals(h2)));
    });

    test('hash is 64 hex characters (SHA-256)', () {
      final hash = AntiTamperGuard.sha256Hash('test');
      expect(hash.length, 64);
      expect(hash, matches(RegExp(r'^[0-9a-f]+$')));
    });
  });

  group('AntiTamperGuard.generateHmac', () {
    test('returns non-empty hex string', () {
      final hmac = AntiTamperGuard.generateHmac(
        payload: 'data',
        secret: 'secret',
      );
      expect(hmac, isNotEmpty);
      expect(hmac.length, 64);
    });

    test('same payload + secret → same hmac', () {
      final h1 = AntiTamperGuard.generateHmac(payload: 'p', secret: 's');
      final h2 = AntiTamperGuard.generateHmac(payload: 'p', secret: 's');
      expect(h1, equals(h2));
    });

    test('different secret → different hmac', () {
      final h1 = AntiTamperGuard.generateHmac(payload: 'p', secret: 's1');
      final h2 = AntiTamperGuard.generateHmac(payload: 'p', secret: 's2');
      expect(h1, isNot(equals(h2)));
    });
  });

  group('AntiTamperGuard.verifyDataIntegrity', () {
    const payload = 'booking-123-user-456';
    const secret = 'test-secret-key';

    test('correct hmac returns true', () {
      final hmac = AntiTamperGuard.generateHmac(payload: payload, secret: secret);
      expect(
        AntiTamperGuard.verifyDataIntegrity(
          payload: payload,
          expectedHmac: hmac,
          secret: secret,
        ),
        isTrue,
      );
    });

    test('tampered payload returns false', () {
      final hmac = AntiTamperGuard.generateHmac(payload: payload, secret: secret);
      expect(
        AntiTamperGuard.verifyDataIntegrity(
          payload: 'tampered-data',
          expectedHmac: hmac,
          secret: secret,
        ),
        isFalse,
      );
    });

    test('wrong secret returns false', () {
      final hmac = AntiTamperGuard.generateHmac(payload: payload, secret: secret);
      expect(
        AntiTamperGuard.verifyDataIntegrity(
          payload: payload,
          expectedHmac: hmac,
          secret: 'wrong-secret',
        ),
        isFalse,
      );
    });

    test('empty hmac returns false', () {
      expect(
        AntiTamperGuard.verifyDataIntegrity(
          payload: payload,
          expectedHmac: '',
          secret: secret,
        ),
        isFalse,
      );
    });
  });

  group('AntiTamperGuard.verifyConfigIntegrity', () {
    test('correct token returns true', () {
      expect(
        AntiTamperGuard.verifyConfigIntegrity('sipelor-bedas-config-integrity-2026'),
        isTrue,
      );
    });

    test('wrong token returns false', () {
      expect(
        AntiTamperGuard.verifyConfigIntegrity('wrong-token'),
        isFalse,
      );
    });

    test('empty token returns false', () {
      expect(AntiTamperGuard.verifyConfigIntegrity(''), isFalse);
    });
  });

  group('AntiTamperGuard.getSeverityMessage', () {
    test('all severities return non-empty Indonesian message', () {
      for (final severity in TamperSeverity.values) {
        final msg = AntiTamperGuard.getSeverityMessage(severity);
        expect(msg, isNotEmpty);
      }
    });

    test('none severity message says safe', () {
      expect(AntiTamperGuard.getSeverityMessage(TamperSeverity.none), contains('aman'));
    });

    test('critical severity message mentions stop', () {
      final msg = AntiTamperGuard.getSeverityMessage(TamperSeverity.critical);
      expect(msg.toLowerCase(), contains('kritis'));
    });
  });

  group('TamperCheckResult', () {
    test('clean factory creates safe result', () {
      final result = TamperCheckResult.clean();
      expect(result.isTampered, isFalse);
      expect(result.violations, isEmpty);
      expect(result.severity, TamperSeverity.none);
    });
  });

  group('AntiTamperGuard.runAllChecks (web/desktop - no real threats)', () {
    test('runs without throwing', () async {
      // On test environment (not Android/iOS), checks should complete cleanly
      final result = await AntiTamperGuard.runAllChecks();
      expect(result, isNotNull);
      // In test/desktop environment, result should be clean or have only debug warning
      expect(result.violations, isA<List<String>>());
    });
  });
}
