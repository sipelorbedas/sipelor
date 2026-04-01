import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/owasp_security_checks.dart';

void main() {
  group('OWASPSecurityChecks Tests', () {
    test('runAllChecks executes all OWASP checks', () async {
      final results = await OWASPSecurityChecks.runAllChecks();
      
      expect(results, isNotNull);
      expect(results, isNotEmpty);
      expect(results.length, 10); // OWASP Mobile Top 10
    });

    test('generateReport creates comprehensive report', () async {
      final results = await OWASPSecurityChecks.runAllChecks();
      final report = OWASPSecurityChecks.generateReport(results);
      
      expect(report, isNotNull);
      expect(report, contains('OWASP Mobile Security'));
      expect(report, contains('Overall Score'));
    });

    test('checkM1_ImproperPlatformUsage validates platform security', () async {
      final result = await OWASPSecurityChecks.checkM1_ImproperPlatformUsage();
      
      expect(result, isNotNull);
      expect(result['category'], 'M1');
      expect(result['passed'], isNotNull);
    });

    test('checkM2_InsecureDataStorage validates data storage security', () async {
      final result = await OWASPSecurityChecks.checkM2_InsecureDataStorage();
      
      expect(result, isNotNull);
      expect(result['category'], 'M2');
      expect(result['passed'], isNotNull);
    });

    test('checkM3_InsecureCommunication validates network security', () async {
      final result = await OWASPSecurityChecks.checkM3_InsecureCommunication();
      
      expect(result, isNotNull);
      expect(result['category'], 'M3');
      expect(result['passed'], isNotNull);
    });

    test('checkM4_InsecureAuthentication validates auth security', () async {
      final result = await OWASPSecurityChecks.checkM4_InsecureAuthentication();
      
      expect(result, isNotNull);
      expect(result['category'], 'M4');
      expect(result['passed'], isNotNull);
    });

    test('checkM5_InsufficientCryptography validates encryption', () async {
      final result = await OWASPSecurityChecks.checkM5_InsufficientCryptography();
      
      expect(result, isNotNull);
      expect(result['category'], 'M5');
      expect(result['passed'], isNotNull);
    });

    test('checkM6_InsecureAuthorization validates authorization', () async {
      final result = await OWASPSecurityChecks.checkM6_InsecureAuthorization();
      
      expect(result, isNotNull);
      expect(result['category'], 'M6');
      expect(result['passed'], isNotNull);
    });

    test('checkM7_ClientCodeQuality validates code quality', () async {
      final result = await OWASPSecurityChecks.checkM7_ClientCodeQuality();
      
      expect(result, isNotNull);
      expect(result['category'], 'M7');
      expect(result['passed'], isNotNull);
    });

    test('checkM8_CodeTampering validates tamper protection', () async {
      final result = await OWASPSecurityChecks.checkM8_CodeTampering();
      
      expect(result, isNotNull);
      expect(result['category'], 'M8');
      expect(result['passed'], isNotNull);
    });

    test('checkM9_ReverseEngineering validates obfuscation', () async {
      final result = await OWASPSecurityChecks.checkM9_ReverseEngineering();
      
      expect(result, isNotNull);
      expect(result['category'], 'M9');
      expect(result['passed'], isNotNull);
    });

    test('checkM10_ExtraneousFunctionality validates production config', () async {
      final result = await OWASPSecurityChecks.checkM10_ExtraneousFunctionality();
      
      expect(result, isNotNull);
      expect(result['category'], 'M10');
      expect(result['passed'], isNotNull);
    });

    test('report includes recommendations for failed checks', () async {
      final results = await OWASPSecurityChecks.runAllChecks();
      final failedChecks = results.where((r) => r['passed'] == false).toList();
      
      for (var check in failedChecks) {
        expect(check['recommendations'], isNotNull);
        expect(check['recommendations'], isNotEmpty);
      }
    });

    // TODO: Add more tests:
    // - Test individual security validations
    // - Test score calculation
    // - Test recommendation generation
    // - Test report formatting
  });
}
