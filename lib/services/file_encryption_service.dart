import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as path;

/// Service for encrypting files before upload to Supabase Storage
/// Uses AES-256 encryption with RANDOM IV per file for secure storage.
///
/// SECURITY FIX: Each file is encrypted with a freshly generated random IV.
/// Stored format: iv_bytes [16] | ciphertext_bytes
///
/// Use cases:
/// - Payment proof images
/// - Profile photos
/// - Document uploads
class FileEncryptionService {
  static final FileEncryptionService _instance =
      FileEncryptionService._internal();
  factory FileEncryptionService() => _instance;
  FileEncryptionService._internal();

  late final encrypt_lib.Key _key;
  bool _initialized = false;

  static const String _appSalt = 'SIPELOR_FILE_ENCRYPTION_2026';
  static const int _ivLength = 16;

  /// Initialize encryption service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      final keyBytes = sha256.convert(utf8.encode(_appSalt)).bytes;
      _key = encrypt_lib.Key(Uint8List.fromList(keyBytes));
      _initialized = true;

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] Service initialized (random IV mode)');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Failed to initialize: $e');
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

  /// Encrypt file bytes with a fresh random IV.
  /// Returns: iv_bytes [16] | ciphertext_bytes
  Future<Uint8List?> encryptBytes(Uint8List fileBytes) async {
    try {
      if (!_initialized) await initialize();

      final iv = _generateRandomIV();
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_key));
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      // Prepend IV to ciphertext
      final combined = Uint8List(_ivLength + encrypted.bytes.length);
      combined.setRange(0, _ivLength, iv.bytes);
      combined.setRange(_ivLength, combined.length, encrypted.bytes);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] Bytes encrypted (random IV)');
        if (kDebugMode) {
          print(
          '📊 [FileEncryption] Original: ${fileBytes.length}, Encrypted: ${combined.length}',
        );
        }
      }

      return combined;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error encrypting bytes: $e');
      }
      return null;
    }
  }

  /// Decrypt file bytes. Reads IV from first 16 bytes.
  Future<Uint8List?> decryptBytes(Uint8List combined) async {
    try {
      if (!_initialized) await initialize();

      if (combined.length <= _ivLength) {
        throw Exception('Data too short to contain IV');
      }

      final ivBytes = combined.sublist(0, _ivLength);
      final ciphertextBytes = combined.sublist(_ivLength);

      final iv = encrypt_lib.IV(ivBytes);
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_key));
      final decrypted = encrypter.decryptBytes(
        encrypt_lib.Encrypted(ciphertextBytes),
        iv: iv,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] Bytes decrypted');
        if (kDebugMode) {
          print(
          '📊 [FileEncryption] Encrypted: ${combined.length}, Decrypted: ${decrypted.length}',
        );
        }
      }

      return Uint8List.fromList(decrypted);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error decrypting bytes: $e');
      }
      return null;
    }
  }

  /// Encrypt a file and write result to [outputPath]
  Future<File?> encryptFile(File sourceFile, {String? outputPath}) async {
    try {
      if (!_initialized) await initialize();

      final fileBytes = await sourceFile.readAsBytes();

      if (kDebugMode) {
        if (kDebugMode) print('📄 [FileEncryption] Encrypting file: ${sourceFile.path}');
        if (kDebugMode) print('📊 [FileEncryption] Original size: ${fileBytes.length} bytes');
      }

      final encryptedData = await encryptBytes(fileBytes);
      if (encryptedData == null) return null;

      final String finalOutputPath;
      if (outputPath != null) {
        finalOutputPath = outputPath;
      } else {
        final dir = path.dirname(sourceFile.path);
        final basename = path.basename(sourceFile.path);
        finalOutputPath = path.join(dir, '$basename.encrypted');
      }

      final encryptedFile = File(finalOutputPath);
      await encryptedFile.writeAsBytes(encryptedData);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] File encrypted successfully → $finalOutputPath');
        if (kDebugMode) print('📊 [FileEncryption] Encrypted size: ${encryptedData.length} bytes');
      }

      return encryptedFile;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error encrypting file: $e');
      }
      return null;
    }
  }

  /// Decrypt a file written by [encryptFile]
  Future<File?> decryptFile(File encryptedFile, {String? outputPath}) async {
    try {
      if (!_initialized) await initialize();

      final encryptedData = await encryptedFile.readAsBytes();

      if (kDebugMode) {
        if (kDebugMode) print('🔓 [FileEncryption] Decrypting file: ${encryptedFile.path}');
      }

      final decryptedData = await decryptBytes(encryptedData);
      if (decryptedData == null) return null;

      final String finalOutputPath;
      if (outputPath != null) {
        finalOutputPath = outputPath;
      } else {
        final originalPath = encryptedFile.path;
        finalOutputPath = originalPath.endsWith('.encrypted')
            ? originalPath.substring(0, originalPath.length - 10)
            : '$originalPath.decrypted';
      }

      final decryptedFile = File(finalOutputPath);
      await decryptedFile.writeAsBytes(decryptedData);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] File decrypted successfully → $finalOutputPath');
      }

      return decryptedFile;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error decrypting file: $e');
      }
      return null;
    }
  }

  /// Encrypt file bytes and return as base64 (for API upload)
  Future<String?> encryptFileToBase64(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final encryptedBytes = await encryptBytes(bytes);
      if (encryptedBytes == null) return null;
      return base64Encode(encryptedBytes);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error encrypting file to base64: $e');
      }
      return null;
    }
  }

  /// Decrypt base64 string and save as file
  Future<File?> decryptBase64ToFile(
    String base64String,
    String outputPath,
  ) async {
    try {
      final encryptedBytes = base64Decode(base64String);
      final decryptedBytes = await decryptBytes(Uint8List.fromList(encryptedBytes));
      if (decryptedBytes == null) return null;

      final file = File(outputPath);
      await file.writeAsBytes(decryptedBytes);
      return file;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error decrypting base64 to file: $e');
      }
      return null;
    }
  }

  /// Check if file is encrypted (basic check by extension)
  bool isFileEncrypted(String filePath) => filePath.endsWith('.encrypted');

  /// Delete file securely (overwrite before delete)
  Future<bool> secureDeleteFile(File file) async {
    try {
      final size = await file.length();
      final random = Random.secure();
      final randomBytes = Uint8List.fromList(
        List<int>.generate(size, (_) => random.nextInt(256)),
      );
      await file.writeAsBytes(randomBytes);
      await file.delete();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FileEncryption] File securely deleted: ${file.path}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryption] Error securely deleting file: $e');
      }
      return false;
    }
  }
}

/// Helper class for file encryption operations
class FileEncryptionHelper {
  static final _service = FileEncryptionService();

  /// Encrypt file bytes before upload to Supabase Storage
  static Future<Uint8List?> encryptForUpload(Uint8List fileBytes) async {
    try {
      await _service.initialize();
      return await _service.encryptBytes(fileBytes);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryptionHelper] Error encrypting for upload: $e');
      }
      return null;
    }
  }

  /// Decrypt file bytes after download from Supabase Storage
  static Future<Uint8List?> decryptAfterDownload(Uint8List encryptedBytes) async {
    try {
      await _service.initialize();
      return await _service.decryptBytes(encryptedBytes);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryptionHelper] Error decrypting after download: $e');
      }
      return null;
    }
  }

  /// Encrypt file for upload to Supabase Storage (file-based)
  static Future<File?> prepareFileForUpload({
    required File file,
    required Directory tempDir,
  }) async {
    try {
      await _service.initialize();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = path.join(tempDir.path, 'encrypted_$timestamp.dat');
      return await _service.encryptFile(file, outputPath: outputPath);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryptionHelper] Error preparing file for upload: $e');
      }
      return null;
    }
  }

  /// Decrypt file after download from Supabase Storage
  static Future<File?> prepareFileAfterDownload({
    required File encryptedFile,
    required String outputPath,
  }) async {
    try {
      await _service.initialize();
      return await _service.decryptFile(encryptedFile, outputPath: outputPath);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [FileEncryptionHelper] Error preparing file after download: $e');
      }
      return null;
    }
  }
}
