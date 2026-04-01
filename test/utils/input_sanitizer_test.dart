import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/input_sanitizer.dart';

void main() {
  group('InputSanitizer Tests', () {
    group('XSS Prevention', () {
      test('Should sanitize script tags', () {
        // Arrange
        final input = '<script>alert("XSS")</script>Hello';

        // Act
        final sanitized = InputSanitizer.sanitizeHtml(input);

        // Assert
        expect(sanitized, isNot(contains('<script')));
        expect(sanitized, contains('&lt;'));
        expect(sanitized, contains('&gt;'));
      });

      test('Should sanitize for display', () {
        // Arrange
        final input = '<script>alert(1)</script><div>Content</div>';

        // Act
        final sanitized = InputSanitizer.sanitizeForDisplay(input);

        // Assert
        expect(sanitized, isNot(contains('<script')));
      });

      test('Should detect malicious patterns', () {
        // Arrange
        final maliciousInputs = [
          '<script>alert(1)</script>',
          'javascript:alert(1)',
          '<img onerror="alert(1)">',
          'eval(malicious)',
        ];

        // Act & Assert
        for (final input in maliciousInputs) {
          expect(InputSanitizer.containsMaliciousPattern(input), isTrue,
              reason: '$input should be detected as malicious');
        }
      });
    });

    group('SQL Injection Prevention', () {
      test('Should escape single quotes', () {
        // Arrange
        final input = "'; DROP TABLE users; --";

        // Act
        final sanitized = InputSanitizer.sanitizeSql(input);

        // Assert
        expect(sanitized, isNot(contains("'")));
      });

      test('Should remove SQL keywords', () {
        // Arrange
        final input = "SELECT * FROM users WHERE 1=1";

        // Act
        final sanitized = InputSanitizer.sanitizeSql(input);

        // Assert
        expect(sanitized, isNot(contains('SELECT')));
        expect(sanitized, isNot(contains('FROM')));
      });
    });

    group('Email Validation', () {
      test('Valid email should pass', () {
        // Arrange
        final emails = [
          'user@example.com',
          'test.user@domain.co.id',
          'admin+tag@company.com',
        ];

        // Act & Assert
        for (final email in emails) {
          expect(InputSanitizer.isValidEmail(email), isTrue,
              reason: '$email should be valid');
        }
      });

      test('Invalid email should fail', () {
        // Arrange
        final emails = [
          'notanemail',
          '@example.com',
          'user@',
          'user space@example.com',
        ];

        // Act & Assert
        for (final email in emails) {
          expect(InputSanitizer.isValidEmail(email), isFalse,
              reason: '$email should be invalid');
        }
      });
    });

    group('Phone Number Validation', () {
      test('Valid Indonesian phone should pass', () {
        // Arrange
        final phones = [
          '081234567890',
          '0812-3456-7890',
          '+6281234567890',
          '6281234567890',
        ];

        // Act & Assert
        for (final phone in phones) {
          expect(InputSanitizer.isValidPhone(phone), isTrue,
              reason: '$phone should be valid');
        }
      });

      test('Invalid phone should fail', () {
        // Arrange
        final phones = [
          '123',
          'abcdefghijk',
          '++6281234',
          '07123456789', // Not starting with 08
        ];

        // Act & Assert
        for (final phone in phones) {
          expect(InputSanitizer.isValidPhone(phone), isFalse,
              reason: '$phone should be invalid');
        }
      });
    });

    group('String Trimming', () {
      test('Should trim whitespace', () {
        // Arrange
        final input = '  Hello World  ';

        // Act
        final trimmed = input.trim();

        // Assert
        expect(trimmed, equals('Hello World'));
      });

      test('Should remove multiple spaces', () {
        // Arrange
        final input = 'Hello    World';

        // Act
        final sanitized = InputSanitizer.normalizeWhitespace(input);

        // Assert
        expect(sanitized, equals('Hello World'));
      });

      test('Should trim to max length', () {
        // Arrange
        final input = 'A' * 2000;

        // Act
        final trimmed = InputSanitizer.trim(input, maxLength: 100);

        // Assert
        expect(trimmed.length, equals(100));
      });
    });

    group('File Name Sanitization', () {
      test('Should sanitize file name', () {
        // Arrange
        final input = '../../etc/passwd.txt';

        // Act
        final sanitized = InputSanitizer.sanitizeFileName(input);

        // Assert
        expect(sanitized, isNot(contains('..')));
        expect(sanitized, isNot(contains('/')));
      });

      test('Should validate file extensions', () {
        // Arrange
        final allowedExtensions = ['.jpg', '.png', '.pdf'];

        // Act & Assert
        expect(
          InputSanitizer.isValidFileExtension('document.pdf', allowedExtensions),
          isTrue,
        );
        expect(
          InputSanitizer.isValidFileExtension('image.png', allowedExtensions),
          isTrue,
        );
        expect(
          InputSanitizer.isValidFileExtension('script.exe', allowedExtensions),
          isFalse,
        );
      });
    });

    group('Search Query Sanitization', () {
      test('Should sanitize search query', () {
        // Arrange
        final input = '<script>alert(1)</script> search term';

        // Act
        final sanitized = InputSanitizer.sanitizeSearchQuery(input);

        // Assert
        expect(sanitized, isNot(contains('<')));
        expect(sanitized, isNot(contains('>')));
      });

      test('Should limit query length', () {
        // Arrange
        final input = 'A' * 200;

        // Act
        final sanitized = InputSanitizer.sanitizeSearchQuery(input);

        // Assert
        expect(sanitized.length, lessThanOrEqualTo(100));
      });
    });
  });
}
