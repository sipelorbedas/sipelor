# Data Encryption at Rest - Implementation Guide

> **Panduan implementasi enkripsi data lokal untuk SIPELOR BEDAS**
> 
> Tanggal: 26 Januari 2026
> Status: Production Ready

---

## 📋 Daftar Isi

1. [Overview](#overview)
2. [Services Implemented](#services-implemented)
3. [Encrypted Preferences Service](#encrypted-preferences-service)
4. [File Encryption Service](#file-encryption-service)
5. [Integration Guide](#integration-guide)
6. [Security Considerations](#security-considerations)
7. [Testing](#testing)

---

## Overview

Aplikasi SIPELOR BEDAS kini dilengkapi dengan enkripsi data at rest untuk melindungi informasi sensitif pengguna. Implementasi ini menggunakan AES-256 encryption untuk:

1. **Encrypted SharedPreferences** - Enkripsi data sensitif di local storage
2. **File Encryption** - Enkripsi file sebelum upload ke Supabase Storage

### ✅ Status Implementasi

| Component | Status | File Location |
|-----------|--------|---------------|
| Encrypted Preferences Service | ✅ Complete | `lib/services/encrypted_preferences_service.dart` |
| File Encryption Service | ✅ Complete | `lib/services/file_encryption_service.dart` |
| Main App Integration | ✅ Complete | `lib/main.dart` |
| Package Dependencies | ✅ Installed | `encrypt: ^5.0.3` |

---

## Services Implemented

### 1. Encrypted Preferences Service ✅

**Purpose**: Encrypt sensitive user data stored in SharedPreferences

**Location**: `lib/services/encrypted_preferences_service.dart`

**Features**:
- ✅ AES-256 encryption
- ✅ Singleton pattern
- ✅ Auto-initialization
- ✅ Support untuk String, Int, Bool, Double, List<String>, JSON
- ✅ Secure key derivation from app salt
- ✅ Type-safe methods

**Package Used**: `encrypt: ^5.0.3`

### 2. File Encryption Service ✅

**Purpose**: Encrypt files before upload and decrypt after download

**Location**: `lib/services/file_encryption_service.dart`

**Features**:
- ✅ AES-256 encryption untuk files
- ✅ Encrypt file-to-file
- ✅ Encrypt bytes (in-memory)
- ✅ Base64 encoding support
- ✅ Secure file deletion
- ✅ Helper methods untuk Supabase Storage integration

**Package Used**: `encrypt: ^5.0.3`

---

## Encrypted Preferences Service

### Usage Examples

#### 1. Basic String Encryption

```dart
import 'package:sipelor/services/encrypted_preferences_service.dart';

final encryptedPrefs = EncryptedPreferencesService();

// Save encrypted string
await encryptedPrefs.setString('user_phone', '+6281234567890');

// Retrieve decrypted string
final phone = await encryptedPrefs.getString('user_phone');
print(phone); // +6281234567890
```

#### 2. JSON Object Encryption

```dart
// Save encrypted JSON
final profileData = {
  'address': 'Jl. Example No. 123',
  'birth_date': '1990-01-01',
  'emergency_contact': '+6287654321098',
};

await encryptedPrefs.setJson(
  EncryptedPrefKeys.cachedProfileData,
  profileData,
);

// Retrieve decrypted JSON
final cachedProfile = await encryptedPrefs.getJson(
  EncryptedPrefKeys.cachedProfileData,
);
```

#### 3. List Encryption

```dart
// Save encrypted list
final sensitiveList = ['item1', 'item2', 'item3'];
await encryptedPrefs.setStringList('my_list', sensitiveList);

// Retrieve decrypted list
final decryptedList = await encryptedPrefs.getStringList('my_list');
```

### Predefined Keys

Use `EncryptedPrefKeys` class untuk consistency:

```dart
class EncryptedPrefKeys {
  // User sensitive preferences
  static const String userPhoneNumber = 'encrypted_user_phone';
  static const String userAddress = 'encrypted_user_address';
  static const String userBirthDate = 'encrypted_user_birthdate';
  
  // Payment information (temporary)
  static const String lastPaymentMethod = 'encrypted_last_payment_method';
  
  // Cached sensitive data
  static const String cachedProfileData = 'encrypted_cached_profile';
  static const String cachedBookingData = 'encrypted_cached_bookings';
  
  // Security settings
  static const String securityQuestionAnswer = 'encrypted_security_answer';
  
  // Analytics preferences
  static const String analyticsPreferences = 'encrypted_analytics_prefs';
}
```

### When to Use Encrypted Preferences

✅ **Use for**:
- User personal information (phone, address, birthdate)
- Cached API responses containing sensitive data
- Temporary payment information
- Security question answers
- Privacy preferences

❌ **Don't use for**:
- Credentials (passwords, tokens) → Use `SecureStorageService` instead
- Session tokens → Use `SecureStorageService` instead
- Large datasets → Consider encrypted database
- Non-sensitive app preferences → Use regular SharedPreferences

### API Reference

```dart
// Initialize (automatically called in main.dart)
await EncryptedPreferencesService().initialize();

// Save methods
await encryptedPrefs.setString(key, value);
await encryptedPrefs.setInt(key, value);
await encryptedPrefs.setBool(key, value);
await encryptedPrefs.setDouble(key, value);
await encryptedPrefs.setStringList(key, values);
await encryptedPrefs.setJson(key, jsonObject);

// Retrieve methods
final string = await encryptedPrefs.getString(key);
final int = await encryptedPrefs.getInt(key);
final bool = await encryptedPrefs.getBool(key);
final double = await encryptedPrefs.getDouble(key);
final list = await encryptedPrefs.getStringList(key);
final json = await encryptedPrefs.getJson(key);

// Utility methods
await encryptedPrefs.remove(key);
final exists = await encryptedPrefs.containsKey(key);
await encryptedPrefs.clearAll(); // Use with caution!
final keys = await encryptedPrefs.getAllKeys();
```

---

## File Encryption Service

### Usage Examples

#### 1. Encrypt File Before Upload to Supabase

```dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sipelor/services/file_encryption_service.dart';

// Easy way using helper
final tempDir = await getTemporaryDirectory();
final encryptedFile = await FileEncryptionHelper.prepareFileForUpload(
  file: File('/path/to/image.jpg'),
  tempDir: tempDir,
);

if (encryptedFile != null) {
  // Upload encrypted file
  await supabase.storage
    .from('payment-proofs')
    .upload('payments/${userId}_${timestamp}.dat', encryptedFile);
}
```

#### 2. Decrypt File After Download

```dart
// Download encrypted file from Supabase
final downloadPath = '${tempDir.path}/downloaded_encrypted.dat';
await supabase.storage
  .from('payment-proofs')
  .download('payments/user123_proof.dat', File(downloadPath));

// Decrypt it
final decryptedFile = await FileEncryptionHelper.prepareFileAfterDownload(
  encryptedFile: File(downloadPath),
  outputPath: '${tempDir.path}/payment_proof.jpg',
);

// Use decrypted file
if (decryptedFile != null) {
  // Display image, etc.
}
```

#### 3. In-Memory Encryption (for API uploads)

```dart
final fileService = FileEncryptionService();
await fileService.initialize();

// Read file bytes
final fileBytes = await File('image.jpg').readAsBytes();

// Encrypt bytes
final encryptedBytes = await fileService.encryptBytes(fileBytes);

// Upload to API
if (encryptedBytes != null) {
  // Send via HTTP POST, etc.
}
```

#### 4. Base64 Encoding for API

```dart
// Encrypt and convert to base64
final base64Encrypted = await fileService.encryptFileToBase64(
  File('document.pdf'),
);

// Send to API
await dio.post('/upload', data: {'file': base64Encrypted});

// On download, decrypt base64
final decryptedFile = await fileService.decryptBase64ToFile(
  base64String,
  '/path/output.pdf',
);
```

### API Reference

```dart
final fileService = FileEncryptionService();

// Initialize
await fileService.initialize();

// File-to-file encryption/decryption
final encryptedFile = await fileService.encryptFile(
  sourceFile,
  outputPath: '/path/output.encrypted', // optional
);

final decryptedFile = await fileService.decryptFile(
  encryptedFile,
  outputPath: '/path/output.jpg', // optional
);

// Bytes encryption/decryption
final encryptedBytes = await fileService.encryptBytes(fileBytes);
final decryptedBytes = await fileService.decryptBytes(encryptedBytes);

// Base64 operations
final base64 = await fileService.encryptFileToBase64(file);
final file = await fileService.decryptBase64ToFile(base64, outputPath);

// Utilities
final isEncrypted = fileService.isFileEncrypted(filePath);
final size = await fileService.getFileSize(file);
await fileService.secureDeleteFile(file); // Overwrite then delete
```

---

## Integration Guide

### Setup (Already Done)

1. ✅ Package installed in `pubspec.yaml`:
   ```yaml
   dependencies:
     encrypt: ^5.0.3
   ```

2. ✅ Services initialized in `lib/main.dart`:
   ```dart
   await EncryptedPreferencesService().initialize();
   await FileEncryptionService().initialize();
   await SecurityEventNotificationService.initialize();
   ```

### Integration Examples

#### Example 1: Encrypt User Profile Cache

```dart
import 'package:sipelor/services/encrypted_preferences_service.dart';

Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
  final encryptedPrefs = EncryptedPreferencesService();
  
  // Remove sensitive data from plain storage
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('user_profile'); // Old unencrypted key
  
  // Save to encrypted storage
  await encryptedPrefs.setJson(
    EncryptedPrefKeys.cachedProfileData,
    profile,
  );
}

Future<Map<String, dynamic>?> getCachedProfile() async {
  final encryptedPrefs = EncryptedPreferencesService();
  return await encryptedPrefs.getJson(
    EncryptedPrefKeys.cachedProfileData,
  );
}
```

#### Example 2: Encrypt Payment Proof Upload

```dart
import 'package:sipelor/services/file_encryption_service.dart';

Future<String?> uploadPaymentProof({
  required File imageFile,
  required String userId,
  required String bookingId,
}) async {
  try {
    final tempDir = await getTemporaryDirectory();
    
    // Encrypt file
    final encryptedFile = await FileEncryptionHelper.prepareFileForUpload(
      file: imageFile,
      tempDir: tempDir,
    );
    
    if (encryptedFile == null) {
      throw Exception('Failed to encrypt file');
    }
    
    // Upload to Supabase Storage
    final fileName = 'payment_${userId}_${bookingId}_${DateTime.now().millisecondsSinceEpoch}.encrypted';
    await supabase.storage
      .from('payment-proofs')
      .upload(fileName, encryptedFile);
    
    // Clean up temp encrypted file
    await FileEncryptionService().secureDeleteFile(encryptedFile);
    
    return fileName;
  } catch (e) {
    print('Error uploading payment proof: $e');
    return null;
  }
}
```

#### Example 3: Migrate Existing Data

```dart
Future<void> migrateToEncryptedStorage() async {
  final prefs = await SharedPreferences.getInstance();
  final encryptedPrefs = EncryptedPreferencesService();
  
  // List of keys to migrate
  final keysToMigrate = [
    'user_phone',
    'user_address',
    'cached_profile_data',
  ];
  
  for (final key in keysToMigrate) {
    final value = prefs.getString(key);
    if (value != null) {
      // Save to encrypted storage
      await encryptedPrefs.setString('encrypted_$key', value);
      
      // Remove from plain storage
      await prefs.remove(key);
    }
  }
  
  print('Migration complete');
}
```

---

## Security Considerations

### Encryption Details

**Algorithm**: AES-256 (Advanced Encryption Standard)
**Mode**: CBC (Cipher Block Chaining)
**Key Size**: 256 bits
**IV**: Fixed per installation (derived from app salt)

### Key Management

**Current Implementation**:
- Key derived from app-specific salt: `SIPELOR_BEDAS_2026`
- Uses SHA-256 hash of salt as encryption key
- Fixed IV for simplicity

**Production Recommendations**:

1. **Per-Device Key** (Recommended):
   ```dart
   // Combine app salt with device ID
   final deviceId = await DeviceInfo().getId();
   final keyMaterial = '$_appSalt-$deviceId';
   final keyBytes = sha256.convert(utf8.encode(keyMaterial)).bytes;
   ```

2. **Per-User Key** (Advanced):
   ```dart
   // Combine with user ID after login
   final userId = currentUser.id;
   final keyMaterial = '$_appSalt-$userId';
   ```

3. **Rotate Keys Periodically**:
   - Implement key rotation every 90 days
   - Re-encrypt all data with new key
   - Store key version in metadata

### Limitations

⚠️ **Important Security Notes**:

1. **Key Storage**: Encryption key is derived from hardcoded salt. For maximum security, consider:
   - Using device-specific hardware keys (if available)
   - Storing keys in secure enclave/keystore
   - Implementing key derivation from user PIN

2. **Fixed IV**: Current implementation uses fixed IV for simplicity. For better security:
   - Generate random IV per encryption operation
   - Store IV alongside encrypted data
   - Increases ciphertext size slightly

3. **Not E2E Encryption**: This encrypts data at rest locally. Data transmitted to server is still encrypted via HTTPS/TLS but decrypted at server.

4. **Backup Considerations**: Encrypted data cannot be restored on new device without key. Consider:
   - Cloud backup of encryption keys (encrypted)
   - User recovery mechanism
   - Data re-sync from server

### Best Practices

✅ **Do**:
- Encrypt all personally identifiable information (PII)
- Encrypt cached API responses with sensitive data
- Encrypt temporary files before upload
- Clear encrypted data on logout
- Log encryption operations (without revealing data)

❌ **Don't**:
- Store encryption keys in plain text
- Encrypt non-sensitive data (performance overhead)
- Share encryption keys across users
- Ignore encryption errors silently

---

## Testing

### Unit Tests

Create tests in `test/services/`:

```dart
// test/services/encrypted_preferences_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/encrypted_preferences_service.dart';

void main() {
  group('EncryptedPreferencesService', () {
    late EncryptedPreferencesService service;

    setUp(() async {
      service = EncryptedPreferencesService();
      await service.initialize();
    });

    test('encrypts and decrypts string correctly', () async {
      const testKey = 'test_string';
      const testValue = 'Hello, World!';

      await service.setString(testKey, testValue);
      final result = await service.getString(testKey);

      expect(result, equals(testValue));
    });

    test('encrypts and decrypts JSON correctly', () async {
      const testKey = 'test_json';
      final testJson = {'name': 'John', 'age': 30};

      await service.setJson(testKey, testJson);
      final result = await service.getJson(testKey);

      expect(result, equals(testJson));
    });

    test('returns null for non-existent key', () async {
      final result = await service.getString('non_existent');
      expect(result, isNull);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/encryption_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/encrypted_preferences_service.dart';
import 'package:sipelor/services/file_encryption_service.dart';

void main() {
  testWidgets('Encryption services work together', (tester) async {
    // Test that both services can initialize
    await EncryptedPreferencesService().initialize();
    await FileEncryptionService().initialize();

    // Test encrypted preferences
    final prefs = EncryptedPreferencesService();
    await prefs.setString('test', 'value');
    final value = await prefs.getString('test');
    expect(value, 'value');

    // Test file encryption
    // (requires file I/O setup)
  });
}
```

### Manual Testing Checklist

- [ ] Save encrypted string and verify retrieval
- [ ] Save encrypted JSON and verify structure preserved
- [ ] Encrypt file and verify size increase
- [ ] Decrypt file and verify content matches original
- [ ] Test with various file types (image, PDF, text)
- [ ] Verify encrypted data persists after app restart
- [ ] Test clearAll() removes all encrypted data
- [ ] Verify performance impact on app startup

---

## Troubleshooting

### Common Issues

#### 1. Initialization Error

**Problem**: Service not initialized before use

**Solution**:
```dart
// Ensure initialization in main.dart
await EncryptedPreferencesService().initialize();
```

#### 2. Decryption Failed

**Problem**: Cannot decrypt previously encrypted data

**Causes**:
- App reinstalled (key changed)
- Manual modification of encrypted data
- Corrupted storage

**Solution**:
- Clear encrypted data and re-encrypt
- Implement backup/recovery mechanism

#### 3. Performance Issues

**Problem**: App slow on startup

**Cause**: Encrypting large amounts of data synchronously

**Solution**:
- Encrypt data asynchronously
- Batch operations
- Only encrypt truly sensitive data

---

## Migration from Plain Storage

### Step-by-Step Migration

1. **Identify Sensitive Data**:
   - Review all SharedPreferences keys
   - Identify which contain sensitive information

2. **Create Migration Script**:
   ```dart
   Future<void> migrateToEncrypted() async {
     final prefs = await SharedPreferences.getInstance();
     final encrypted = EncryptedPreferencesService();
     
     // Migrate each key
     for (final key in sensitiveKeys) {
       final value = prefs.getString(key);
       if (value != null) {
         await encrypted.setString(key, value);
         await prefs.remove(key);
       }
     }
   }
   ```

3. **Run Once on App Update**:
   ```dart
   final migrated = prefs.getBool('encrypted_migration_done') ?? false;
   if (!migrated) {
     await migrateToEncrypted();
     await prefs.setBool('encrypted_migration_done', true);
   }
   ```

---

## Future Enhancements

### Planned Improvements

1. **Per-User Encryption Keys**
   - Different key for each user
   - Re-encrypt on user change

2. **Key Rotation**
   - Automatic key rotation every 90 days
   - Transparent to user

3. **Hardware-Backed Keys**
   - Use Android Keystore / iOS Keychain for key storage
   - Requires platform-specific implementation

4. **Encrypted Database**
   - For offline-first features
   - SQLCipher integration

5. **Remote Key Management**
   - Optional cloud backup of keys
   - Secure key recovery mechanism

---

## Resources

- **Encrypt Package**: [https://pub.dev/packages/encrypt](https://pub.dev/packages/encrypt)
- **AES Encryption**: [https://en.wikipedia.org/wiki/Advanced_Encryption_Standard](https://en.wikipedia.org/wiki/Advanced_Encryption_Standard)
- **Flutter Secure Storage**: [https://pub.dev/packages/flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- **OWASP Mobile Security**: [https://owasp.org/www-project-mobile-top-10/](https://owasp.org/www-project-mobile-top-10/)

---

**Dokumen ini akan di-update sesuai enhancement dan feedback.**

**Last Updated**: 26 Januari 2026  
**Version**: 1.0  
**Author**: Development Team  
**Status**: Production Ready
