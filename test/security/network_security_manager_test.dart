import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/security/network_security_manager.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('NetworkSecurityManager.isUrlSecure', () {
    test('https URL is secure', () {
      expect(NetworkSecurityManager.isUrlSecure('https://api.supabase.co'), isTrue);
    });

    test('HTTPS (uppercase) is secure', () {
      expect(NetworkSecurityManager.isUrlSecure('HTTPS://EXAMPLE.COM'), isTrue);
    });

    test('http URL is not secure (in release mode check)', () {
      expect(NetworkSecurityManager.isUrlSecure('http://example.com'), isFalse);
    });

    test('empty URL is not secure', () {
      expect(NetworkSecurityManager.isUrlSecure(''), isFalse);
    });

    test('invalid URL is not secure', () {
      expect(NetworkSecurityManager.isUrlSecure('not-a-url'), isFalse);
    });

    test('ftp URL is not secure', () {
      expect(NetworkSecurityManager.isUrlSecure('ftp://files.com'), isFalse);
    });
  });

  group('NetworkSecurityManager.enforceHttps', () {
    test('https URL does not throw', () {
      expect(
        () => NetworkSecurityManager.enforceHttps('https://api.supabase.co'),
        returnsNormally,
      );
    });

    test('http URL in debug mode (tests) does not throw', () {
      // kDebugMode = true in tests, so http is allowed
      expect(
        () => NetworkSecurityManager.enforceHttps('http://localhost:8080'),
        returnsNormally,
      );
    });
  });

  group('NetworkSecurityManager.getRiskLevelName', () {
    test('all risk levels return Indonesian names', () {
      expect(NetworkSecurityManager.getRiskLevelName(NetworkRiskLevel.low), 'Rendah');
      expect(NetworkSecurityManager.getRiskLevelName(NetworkRiskLevel.medium), 'Sedang');
      expect(NetworkSecurityManager.getRiskLevelName(NetworkRiskLevel.high), 'Tinggi');
      expect(NetworkSecurityManager.getRiskLevelName(NetworkRiskLevel.critical), 'Kritis');
    });
  });

  group('NetworkSecurityManager.assess', () {
    test('runs without throwing in test environment', () async {
      final result = await NetworkSecurityManager.assess();
      expect(result, isNotNull);
      expect(result.warnings, isA<List<String>>());
      // Let any lingering async tasks settle before next test
      await Future<void>.delayed(Duration.zero);
    });

    test('returns valid riskLevel', () async {
      final result = await NetworkSecurityManager.assess();
      expect(result.riskLevel, isA<NetworkRiskLevel>());
      await Future<void>.delayed(Duration.zero);
    });
  });

  group('SecurityException', () {
    test('contains message in toString', () {
      const ex = SecurityException('test security error');
      expect(ex.toString(), contains('test security error'));
    });

    test('can be caught as Exception', () {
      expect(
        () => throw const SecurityException('blocked'),
        throwsA(isA<SecurityException>()),
      );
    });
  });

  group('NetworkSecurityResult', () {
    test('secure factory creates safe result', () {
      final r = NetworkSecurityResult.secure();
      expect(r.isSecure, isTrue);
      expect(r.warnings, isEmpty);
      expect(r.riskLevel, NetworkRiskLevel.low);
    });
  });
}
