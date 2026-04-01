import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/file_encryption_service.dart';
import 'package:path/path.dart' as path;

void main() {
  group('FileEncryptionService Tests', () {
    late FileEncryptionService service;
    late Directory testDir;

    setUp(() async {
      service = FileEncryptionService();
      await service.initialize();

      // Create temporary test directory
      testDir = await Directory.systemTemp.createTemp('sipelor_test_');
    });

    tearDown(() async {
      // Clean up test directory
      if (await testDir.exists()) {
        await testDir.delete(recursive: true);
      }
    });

    test('should initialize service successfully', () async {
      // Arrange
      final newService = FileEncryptionService();

      // Act & Assert - should not throw
      await expectLater(newService.initialize(), completes);
    });

    test('should encrypt and decrypt file correctly', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'test.txt'));
      final originalContent = 'This is a test file for encryption';
      await testFile.writeAsString(originalContent);

      // Act - Encrypt
      final encryptedFile = await service.encryptFile(testFile);

      // Assert - Encrypted file should exist and be different from original
      expect(encryptedFile, isNotNull);
      expect(await encryptedFile!.exists(), true);
      
      final encryptedBytes = await encryptedFile.readAsBytes();
      final originalBytes = await testFile.readAsBytes();
      expect(encryptedBytes, isNot(equals(originalBytes)));

      // Act - Decrypt
      final decryptedFile = await service.decryptFile(encryptedFile);

      // Assert - Decrypted content should match original
      expect(decryptedFile, isNotNull);
      final decryptedContent = await decryptedFile!.readAsString();
      expect(decryptedContent, originalContent);
    });

    test('should handle binary files correctly', () async {
      // Arrange - Create a binary file (simulated image)
      final testFile = File(path.join(testDir.path, 'test.bin'));
      final binaryData = List<int>.generate(1024, (index) => index % 256);
      await testFile.writeAsBytes(binaryData);

      // Act - Encrypt
      final encryptedFile = await service.encryptFile(testFile);

      // Assert
      expect(encryptedFile, isNotNull);
      expect(await encryptedFile!.exists(), true);

      // Act - Decrypt
      final decryptedFile = await service.decryptFile(encryptedFile);

      // Assert - Binary data should match
      expect(decryptedFile, isNotNull);
      final decryptedData = await decryptedFile!.readAsBytes();
      expect(decryptedData, equals(binaryData));
    });

    test('should use custom output path when provided', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'test.txt'));
      await testFile.writeAsString('Test content');
      final customPath = path.join(testDir.path, 'custom_encrypted.txt');

      // Act
      final encryptedFile = await service.encryptFile(
        testFile,
        outputPath: customPath,
      );

      // Assert
      expect(encryptedFile?.path, customPath);
      expect(await File(customPath).exists(), true);
    });

    test('should verify encryption with checksum', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'test.txt'));
      await testFile.writeAsString('Test for checksum verification');

      // Act
      final encryptedFile = await service.encryptFile(testFile);
      
      // Assert
      expect(encryptedFile, isNotNull);
      
      // Verify that encryption is consistent (same input = same output)
      final encryptedFile2 = await service.encryptFile(testFile);
      
      final bytes1 = await encryptedFile!.readAsBytes();
      final bytes2 = await encryptedFile2!.readAsBytes();
      
      // Should produce same encrypted output for same input
      expect(bytes1, equals(bytes2));
    });

    test('should handle empty file', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'empty.txt'));
      await testFile.writeAsString('');

      // Act
      final encryptedFile = await service.encryptFile(testFile);

      // Assert
      expect(encryptedFile, isNotNull);
      expect(await encryptedFile!.exists(), true);

      // Decrypt and verify
      final decryptedFile = await service.decryptFile(encryptedFile);
      final content = await decryptedFile!.readAsString();
      expect(content, '');
    });

    test('should check if file is encrypted', () async {
      // Arrange
      final testFile = File(path.join(testDir.path, 'test.txt'));
      await testFile.writeAsString('Plain text file');

      // Act & Assert - Plain file should not be encrypted
      expect(service.isFileEncrypted(testFile), false);

      // Encrypt the file
      final encryptedFile = await service.encryptFile(testFile);

      // Act & Assert - Encrypted file should be detected
      expect(service.isFileEncrypted(encryptedFile!), true);
    });

    test('should handle large files efficiently', () async {
      // Arrange - Create a larger file (1MB)
      final testFile = File(path.join(testDir.path, 'large.bin'));
      final largeData = List<int>.generate(1024 * 1024, (index) => index % 256);
      await testFile.writeAsBytes(largeData);

      // Act - Measure encryption time
      final stopwatch = Stopwatch()..start();
      final encryptedFile = await service.encryptFile(testFile);
      stopwatch.stop();

      // Assert
      expect(encryptedFile, isNotNull);
      expect(await encryptedFile!.exists(), true);
      
      // Encryption should complete in reasonable time (< 5 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));

      // Verify decryption
      final decryptedFile = await service.decryptFile(encryptedFile);
      final decryptedData = await decryptedFile!.readAsBytes();
      expect(decryptedData.length, largeData.length);
    });
  });
}
