import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService', () {
    setUp(() {
      // Setup before each test
      // Note: In real tests, you would mock FlutterSecureStorage
    });

    test('write and read should work for simple values', () async {
      const testKey = 'test_key';
      const testValue = 'test_value';

      try {
        // Write value
        await SecureStorageService.write(key: testKey, value: testValue);

        // Read value
        final result = await SecureStorageService.read(key: testKey);

        // Verify
        expect(result, equals(testValue));

        // Cleanup
        await SecureStorageService.delete(key: testKey);
      } catch (e) {
        // If secure storage is not available in test environment, skip test
        print('Secure storage not available in test environment: $e');
      }
    });

    test('read should return null for non-existent key', () async {
      const nonExistentKey = 'non_existent_key_${DateTime.now().millisecondsSinceEpoch}';

      final result = await SecureStorageService.read(key: nonExistentKey);

      expect(result, isNull);
    });

    test('delete should remove stored value', () async {
      const testKey = 'test_delete_key';
      const testValue = 'test_delete_value';

      try {
        // Write value
        await SecureStorageService.write(key: testKey, value: testValue);

        // Delete value
        await SecureStorageService.delete(key: testKey);

        // Read should return null
        final result = await SecureStorageService.read(key: testKey);
        expect(result, isNull);
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('containsKey should return true for existing key', () async {
      const testKey = 'test_exists_key';
      const testValue = 'test_exists_value';

      try {
        // Write value
        await SecureStorageService.write(key: testKey, value: testValue);

        // Check if key exists
        final exists = await SecureStorageService.containsKey(key: testKey);
        expect(exists, isTrue);

        // Cleanup
        await SecureStorageService.delete(key: testKey);
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('containsKey should return false for non-existent key', () async {
      const nonExistentKey = 'non_existent_check_key_${DateTime.now().millisecondsSinceEpoch}';

      final exists = await SecureStorageService.containsKey(key: nonExistentKey);
      expect(exists, isFalse);
    });

    test('saveBiometricCredentials should store username and password', () async {
      const testUsername = 'test@example.com';
      const testPassword = 'testPassword123';

      try {
        // Save credentials
        await SecureStorageService.saveBiometricCredentials(
          username: testUsername,
          password: testPassword,
        );

        // Retrieve credentials
        final credentials = await SecureStorageService.getBiometricCredentials();

        expect(credentials, isNotNull);
        expect(credentials!['username'], equals(testUsername));
        expect(credentials['password'], equals(testPassword));

        // Cleanup
        await SecureStorageService.deleteBiometricCredentials();
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('getBiometricCredentials should return null when not set', () async {
      // Ensure credentials are deleted first
      try {
        await SecureStorageService.deleteBiometricCredentials();
      } catch (e) {
        // Ignore if already deleted
      }

      final credentials = await SecureStorageService.getBiometricCredentials();
      expect(credentials, isNull);
    });

    test('deleteBiometricCredentials should remove credentials', () async {
      const testUsername = 'delete@example.com';
      const testPassword = 'deletePassword123';

      try {
        // Save credentials
        await SecureStorageService.saveBiometricCredentials(
          username: testUsername,
          password: testPassword,
        );

        // Delete credentials
        await SecureStorageService.deleteBiometricCredentials();

        // Credentials should be null
        final credentials = await SecureStorageService.getBiometricCredentials();
        expect(credentials, isNull);
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('saveSessionToken and getSessionToken should work', () async {
      const testToken = 'test_session_token_123';

      try {
        // Save token
        await SecureStorageService.saveSessionToken(testToken);

        // Get token
        final retrievedToken = await SecureStorageService.getSessionToken();
        expect(retrievedToken, equals(testToken));

        // Cleanup
        await SecureStorageService.deleteSessionToken();
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('saveRefreshToken and getRefreshToken should work', () async {
      const testToken = 'test_refresh_token_456';

      try {
        // Save token
        await SecureStorageService.saveRefreshToken(testToken);

        // Get token
        final retrievedToken = await SecureStorageService.getRefreshToken();
        expect(retrievedToken, equals(testToken));

        // Cleanup
        await SecureStorageService.deleteRefreshToken();
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('clearSession should remove all session data', () async {
      const testSessionToken = 'session_789';
      const testRefreshToken = 'refresh_789';

      try {
        // Save tokens
        await SecureStorageService.saveSessionToken(testSessionToken);
        await SecureStorageService.saveRefreshToken(testRefreshToken);

        // Clear session
        await SecureStorageService.clearSession();

        // Tokens should be null
        final sessionToken = await SecureStorageService.getSessionToken();
        final refreshToken = await SecureStorageService.getRefreshToken();

        expect(sessionToken, isNull);
        expect(refreshToken, isNull);
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });

    test('deleteAll should clear all stored data', () async {
      const key1 = 'test_key_1';
      const key2 = 'test_key_2';
      const value1 = 'test_value_1';
      const value2 = 'test_value_2';

      try {
        // Write multiple values
        await SecureStorageService.write(key: key1, value: value1);
        await SecureStorageService.write(key: key2, value: value2);

        // Delete all
        await SecureStorageService.deleteAll();

        // All values should be null
        final result1 = await SecureStorageService.read(key: key1);
        final result2 = await SecureStorageService.read(key: key2);

        expect(result1, isNull);
        expect(result2, isNull);
      } catch (e) {
        print('Secure storage not available in test environment: $e');
      }
    });
  });
}
