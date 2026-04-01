import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'secure_storage_service.dart';

/// Service to handle biometric authentication
/// Now uses SecureStorageService for encrypted credential storage
class BiometricAuthService {
  static final LocalAuthentication _localAuth = LocalAuthentication();

  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if device supports biometric authentication
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics =
          await _localAuth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _localAuth.isDeviceSupported();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Biometric canCheckBiometrics: $canAuthenticateWithBiometrics');
        if (kDebugMode) {
          print(
          '✅ Biometric isDeviceSupported: ${await _localAuth.isDeviceSupported()}',
        );
        }
        if (kDebugMode) print('✅ Biometric available: $canAuthenticate');
      }
      return canAuthenticate;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '❌ Error checking biometric availability: ${e.code} - ${e.message}',
        );
        }
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Unexpected error checking biometric availability: $e');
      }
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on PlatformException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error getting available biometrics: $e');
      }
      return [];
    }
  }

  /// Authenticate using biometric
  static Future<bool> authenticate({
    String reason = 'Gunakan biometrik untuk login',
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ Biometric not available on this device');
        }
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
      );

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          didAuthenticate
              ? '✅ Biometric authentication successful'
              : '❌ Biometric authentication failed',
        );
        }
      }

      return didAuthenticate;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error during biometric authentication: ${e.message}');
      }
      return false;
    }
  }

  /// Check if biometric is enabled in settings
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error checking biometric enabled status: $e');
      }
      return false;
    }
  }

  /// Enable biometric authentication
  /// Now stores credentials in encrypted secure storage
  static Future<void> enableBiometric({
    required String username,
    required String password,
  }) async {
    try {
      // Save biometric enabled flag in shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, true);

      // Save credentials in encrypted secure storage
      await SecureStorageService.saveBiometricCredentials(
        username: username,
        password: password,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ Biometric enabled and credentials saved securely');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error enabling biometric: $e');
      }
      rethrow;
    }
  }

  /// Disable biometric authentication
  /// Now removes credentials from secure storage
  static Future<void> disableBiometric() async {
    try {
      // Remove biometric enabled flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, false);

      // Delete credentials from secure storage
      await SecureStorageService.deleteBiometricCredentials();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Biometric disabled and credentials removed securely');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error disabling biometric: $e');
      }
      rethrow;
    }
  }

  /// Get saved credentials — ONLY after successful biometric verification.
  /// SECURITY FIX: Credentials are never returned without live biometric proof.
  static Future<Map<String, String>?> getSavedCredentials() async {
    try {
      // Step 1: Ensure biometric is enabled
      final enabled = await isBiometricEnabled();
      if (!enabled) {
        if (kDebugMode) print('⚠️ [Biometric] getSavedCredentials: biometric not enabled');
        return null;
      }

      // Step 2: Require live biometric verification before releasing credentials
      final verified = await authenticate(
        reason: 'Verifikasi identitas Anda untuk masuk',
      );
      if (!verified) {
        if (kDebugMode) print('❌ [Biometric] getSavedCredentials: verification failed');
        return null;
      }

      // Step 3: Only now retrieve credentials from secure storage
      final credentials = await SecureStorageService.getBiometricCredentials();
      if (kDebugMode) {
        if (kDebugMode) {
          print(credentials != null
            ? '✅ [Biometric] Credentials returned after verification'
            : '⚠️ [Biometric] No credentials stored');
        }
      }
      return credentials;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error getting saved credentials: $e');
      }
      return null;
    }
  }

  /// Get biometric type name for display
  static Future<String> getBiometricTypeName() async {
    try {
      final types = await getAvailableBiometrics();
      if (types.isEmpty) {
        return 'Biometrik';
      }

      if (types.contains(BiometricType.face)) {
        return 'Face ID';
      } else if (types.contains(BiometricType.fingerprint)) {
        return 'Sidik Jari';
      } else if (types.contains(BiometricType.iris)) {
        return 'Iris';
      } else {
        return 'Biometrik';
      }
    } catch (e) {
      return 'Biometrik';
    }
  }
}
