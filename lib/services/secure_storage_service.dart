import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for securely storing sensitive data using encrypted storage
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for stored values
  static const String _biometricUsernameKey = 'biometric_username';
  static const String _biometricPasswordKey = 'biometric_password';
  static const String _sessionTokenKey = 'session_token';
  static const String _refreshTokenKey = 'refresh_token';

  /// Write a value to secure storage
  static Future<void> write({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      if (kDebugMode) {
        if (kDebugMode) print('✅ Secure storage write: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error writing to secure storage: $e');
      }
      rethrow;
    }
  }

  /// Read a value from secure storage
  static Future<String?> read({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      if (kDebugMode && value != null) {
        if (kDebugMode) print('✅ Secure storage read: $key');
      }
      return value;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error reading from secure storage: $e');
      }
      return null;
    }
  }

  /// Delete a value from secure storage
  static Future<void> delete({required String key}) async {
    try {
      await _storage.delete(key: key);
      if (kDebugMode) {
        if (kDebugMode) print('✅ Secure storage delete: $key');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error deleting from secure storage: $e');
      }
      rethrow;
    }
  }

  /// Clear all values from secure storage
  static Future<void> deleteAll() async {
    try {
      await _storage.deleteAll();
      if (kDebugMode) {
        if (kDebugMode) print('✅ Secure storage cleared all');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error clearing secure storage: $e');
      }
      rethrow;
    }
  }

  /// Check if a key exists in secure storage
  static Future<bool> containsKey({required String key}) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error checking key in secure storage: $e');
      }
      return false;
    }
  }

  // ==================== Biometric Credentials ====================

  /// Save biometric credentials securely
  static Future<void> saveBiometricCredentials({
    required String username,
    required String password,
  }) async {
    await write(key: _biometricUsernameKey, value: username);
    await write(key: _biometricPasswordKey, value: password);
    if (kDebugMode) {
      if (kDebugMode) print('✅ Biometric credentials saved securely');
    }
  }

  /// Get biometric credentials
  static Future<Map<String, String>?> getBiometricCredentials() async {
    try {
      final username = await read(key: _biometricUsernameKey);
      final password = await read(key: _biometricPasswordKey);

      if (username != null && password != null) {
        return {
          'username': username,
          'password': password,
        };
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error getting biometric credentials: $e');
      }
      return null;
    }
  }

  /// Delete biometric credentials
  static Future<void> deleteBiometricCredentials() async {
    await delete(key: _biometricUsernameKey);
    await delete(key: _biometricPasswordKey);
    if (kDebugMode) {
      if (kDebugMode) print('✅ Biometric credentials deleted');
    }
  }

  // ==================== Session Management ====================

  /// Save session token
  static Future<void> saveSessionToken(String token) async {
    await write(key: _sessionTokenKey, value: token);
  }

  /// Get session token
  static Future<String?> getSessionToken() async {
    return await read(key: _sessionTokenKey);
  }

  /// Delete session token
  static Future<void> deleteSessionToken() async {
    await delete(key: _sessionTokenKey);
  }

  /// Save refresh token
  static Future<void> saveRefreshToken(String token) async {
    await write(key: _refreshTokenKey, value: token);
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    return await read(key: _refreshTokenKey);
  }

  /// Delete refresh token
  static Future<void> deleteRefreshToken() async {
    await delete(key: _refreshTokenKey);
  }

  /// Clear all session data
  static Future<void> clearSession() async {
    await deleteSessionToken();
    await deleteRefreshToken();
    if (kDebugMode) {
      if (kDebugMode) print('✅ Session data cleared');
    }
  }
}
