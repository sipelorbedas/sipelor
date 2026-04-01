import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:crypto/crypto.dart';

/// Service for encrypting sensitive data in SharedPreferences
/// Uses AES-256 encryption with RANDOM IV per entry for secure local data storage.
///
/// SECURITY FIX: Each value is encrypted with a freshly generated random IV.
/// The IV is stored alongside the ciphertext as: base64(iv_bytes | encrypted_bytes).
///
/// Use this for:
/// - User preferences containing sensitive info
/// - Cached API responses with personal data
/// - Temporary sensitive data that doesn't need SecureStorage
///
/// DO NOT use for:
/// - Credentials (use SecureStorageService instead)
/// - Tokens (use SecureStorageService instead)
class EncryptedPreferencesService {
  static final EncryptedPreferencesService _instance =
      EncryptedPreferencesService._internal();
  factory EncryptedPreferencesService() => _instance;
  EncryptedPreferencesService._internal();

  late final encrypt_lib.Key _key;
  bool _initialized = false;

  // Encryption key derivation
  // Key is derived from app salt. IV is random per encryption.
  static const String _appSalt = 'SIPELOR_BEDAS_2026';
  static const int _ivLength = 16; // AES block size in bytes

  /// Initialize encryption service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final keyBytes = sha256.convert(utf8.encode(_appSalt)).bytes;
      _key = encrypt_lib.Key(Uint8List.fromList(keyBytes));
      _initialized = true;

      if (kDebugMode) {
        if (kDebugMode) print('✅ [EncryptedPreferences] Encryption service initialized (random IV mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Failed to initialize: $e');
      }
      rethrow;
    }
  }

  /// Generate a cryptographically secure random IV
  encrypt_lib.IV _generateRandomIV() {
    final random = Random.secure();
    final ivBytes = List<int>.generate(_ivLength, (_) => random.nextInt(256));
    return encrypt_lib.IV(Uint8List.fromList(ivBytes));
  }

  /// Encrypt a string value with a fresh random IV
  /// Stored format: base64( iv_bytes [16] | ciphertext_bytes )
  Future<bool> setString(String key, String value) async {
    try {
      if (!_initialized) await initialize();

      final iv = _generateRandomIV();
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_key));
      final encrypted = encrypter.encrypt(value, iv: iv);

      // Combine IV + ciphertext and base64-encode
      final combined = Uint8List(_ivLength + encrypted.bytes.length);
      combined.setRange(0, _ivLength, iv.bytes);
      combined.setRange(_ivLength, combined.length, encrypted.bytes);
      final storedValue = base64.encode(combined);

      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(key, storedValue);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [EncryptedPreferences] Encrypted (random IV) and saved: $key');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error saving encrypted string: $e');
      }
      return false;
    }
  }

  /// Retrieve and decrypt a string value
  /// Reads IV from the first 16 bytes of stored data
  Future<String?> getString(String key) async {
    try {
      if (!_initialized) await initialize();

      final prefs = await SharedPreferences.getInstance();
      final storedValue = prefs.getString(key);

      if (storedValue == null) return null;

      final combined = base64.decode(storedValue);
      if (combined.length <= _ivLength) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ [EncryptedPreferences] Stored data too short for key: $key');
        }
        return null;
      }

      // Extract IV and ciphertext
      final ivBytes = combined.sublist(0, _ivLength);
      final ciphertextBytes = combined.sublist(_ivLength);

      final iv = encrypt_lib.IV(ivBytes);
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_key));
      final decrypted = encrypter.decrypt(
        encrypt_lib.Encrypted(ciphertextBytes),
        iv: iv,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [EncryptedPreferences] Decrypted: $key');
      }
      return decrypted;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error reading encrypted string: $e');
      }
      return null;
    }
  }

  /// Encrypt and save an integer value
  Future<bool> setInt(String key, int value) async {
    return await setString(key, value.toString());
  }

  /// Retrieve and decrypt an integer value
  Future<int?> getInt(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return int.tryParse(stringValue);
  }

  /// Encrypt and save a boolean value
  Future<bool> setBool(String key, bool value) async {
    return await setString(key, value.toString());
  }

  /// Retrieve and decrypt a boolean value
  Future<bool?> getBool(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return stringValue.toLowerCase() == 'true';
  }

  /// Encrypt and save a double value
  Future<bool> setDouble(String key, double value) async {
    return await setString(key, value.toString());
  }

  /// Retrieve and decrypt a double value
  Future<double?> getDouble(String key) async {
    final stringValue = await getString(key);
    if (stringValue == null) return null;
    return double.tryParse(stringValue);
  }

  /// Encrypt and save a list of strings
  Future<bool> setStringList(String key, List<String> values) async {
    final jsonString = jsonEncode(values);
    return await setString(key, jsonString);
  }

  /// Retrieve and decrypt a list of strings
  Future<List<String>?> getStringList(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      final decoded = jsonDecode(jsonString) as List<dynamic>;
      return decoded.map((e) => e.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error parsing string list: $e');
      }
      return null;
    }
  }

  /// Encrypt and save a JSON object
  Future<bool> setJson(String key, Map<String, dynamic> jsonData) async {
    final jsonString = jsonEncode(jsonData);
    return await setString(key, jsonString);
  }

  /// Retrieve and decrypt a JSON object
  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await getString(key);
    if (jsonString == null) return null;

    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error parsing JSON: $e');
      }
      return null;
    }
  }

  /// Remove a key from encrypted storage
  Future<bool> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(key);
      if (kDebugMode) {
        if (kDebugMode) print('✅ [EncryptedPreferences] Removed: $key');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error removing key: $e');
      }
      return false;
    }
  }

  /// Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(key);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error checking key: $e');
      }
      return false;
    }
  }

  /// Clear all encrypted preferences — use with caution!
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.clear();
      if (kDebugMode) {
        if (kDebugMode) print('✅ [EncryptedPreferences] Cleared all preferences');
      }
      return result;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error clearing preferences: $e');
      }
      return false;
    }
  }

  /// Get all keys (for debugging/migration)
  Future<Set<String>> getAllKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [EncryptedPreferences] Error getting keys: $e');
      }
      return {};
    }
  }
}

// Convenience keys for common encrypted data
class EncryptedPrefKeys {
  static const String userPhoneNumber = 'encrypted_user_phone';
  static const String userAddress = 'encrypted_user_address';
  static const String userBirthDate = 'encrypted_user_birthdate';
  static const String lastPaymentMethod = 'encrypted_last_payment_method';
  static const String cachedProfileData = 'encrypted_cached_profile';
  static const String cachedBookingData = 'encrypted_cached_bookings';
  static const String securityQuestionAnswer = 'encrypted_security_answer';
  static const String analyticsPreferences = 'encrypted_analytics_prefs';
}
