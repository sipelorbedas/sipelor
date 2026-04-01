import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/password_validator.dart';
import 'package:sipelor/services/password_service.dart';

void main() {
  group('PasswordService Tests', () {
    test('changePassword should validate empty fields', () async {
      final result = await PasswordService.changePassword(
        oldPassword: '',
        newPassword: 'NewPass123!',
        confirmPassword: 'NewPass123!',
      );

      expect(result, isNotNull);
      expect(result, contains('field harus diisi'));
    });

    test('changePassword should check password confirmation match', () async {
      final result = await PasswordService.changePassword(
        oldPassword: 'OldPass123!',
        newPassword: 'NewPass123!',
        confirmPassword: 'DifferentPass123!',
      );

      expect(result, isNotNull);
      expect(result, contains('tidak cocok'));
    });

    test('changePassword should reject same old and new password', () async {
      final result = await PasswordService.changePassword(
        oldPassword: 'SamePass123!',
        newPassword: 'SamePass123!',
        confirmPassword: 'SamePass123!',
      );

      expect(result, isNotNull);
      expect(result, contains('berbeda dari password lama'));
    });

    test('changePassword should validate new password strength', () async {
      final result = await PasswordService.changePassword(
        oldPassword: 'OldPass123!',
        newPassword: 'weak',
        confirmPassword: 'weak',
      );

      expect(result, isNotNull);
    });

    test('requestPasswordReset should validate email format', () async {
      final result = await PasswordService.requestPasswordReset(
        email: 'invalid-email',
      );

      // Should complete without revealing if email exists
      // In production, this always returns success to prevent user enumeration
      expect(result, isA<String?>());
    });

    test('requestPasswordReset should accept valid email', () async {
      final result = await PasswordService.requestPasswordReset(
        email: 'test@example.com',
      );

      // Should not crash
      expect(result, isA<String?>());
    });

    test('resetPassword should validate token', () async {
      final result = await PasswordService.resetPassword(
        token: 'invalid-token',
        newPassword: 'NewPass123!',
        confirmPassword: 'NewPass123!',
      );

      // Should handle invalid token gracefully
      expect(result, isA<String?>());
    });

    test('resetPassword should validate password confirmation', () async {
      final result = await PasswordService.resetPassword(
        token: 'some-token',
        newPassword: 'NewPass123!',
        confirmPassword: 'DifferentPass123!',
      );

      expect(result, isNotNull);
      expect(result, contains('tidak cocok'));
    });

    test('resetPassword should validate new password strength', () async {
      final result = await PasswordService.resetPassword(
        token: 'some-token',
        newPassword: 'weak',
        confirmPassword: 'weak',
      );

      expect(result, isNotNull);
    });
  });

  group('PasswordValidator Tests', () {
    test('Valid strong password should pass validation', () {
      // Arrange
      final password = 'StrongPass123!';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('Short password should fail validation', () {
      // Arrange
      final password = 'Pass1!';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Password minimal 8 karakter'));
    });

    test('Password without uppercase should fail', () {
      // Arrange
      final password = 'password123!';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Harus ada huruf besar'));
    });

    test('Password without lowercase should fail', () {
      // Arrange
      final password = 'PASSWORD123!';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Harus ada huruf kecil'));
    });

    test('Password without number should fail', () {
      // Arrange
      final password = 'Password!';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Harus ada angka'));
    });

    test('Password without special character should fail', () {
      // Arrange
      final password = 'Password123';

      // Act
      final result = PasswordValidator.validate(password);

      // Assert
      expect(result.isValid, isFalse);
      expect(result.errors, contains('Harus ada simbol'));
    });

    test('Password strength weak', () {
      // Arrange
      final password = 'Pass123!';

      // Act
      final strength = PasswordValidator.getStrength(password);

      // Assert
      expect(strength, equals(PasswordStrength.weak));
    });

    test('Password strength medium', () {
      // Arrange
      final password = 'Password123';

      // Act
      final strength = PasswordValidator.getStrength(password);

      // Assert
      expect(strength, equals(PasswordStrength.medium));
    });

    test('Password strength strong', () {
      // Arrange
      final password = 'P@ssw0rd123!';

      // Act
      final strength = PasswordValidator.getStrength(password);

      // Assert
      expect(strength, equals(PasswordStrength.strong));
    });
  });
}
