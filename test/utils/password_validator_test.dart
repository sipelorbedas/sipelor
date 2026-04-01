import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/utils/password_validator.dart';

void main() {
  group('PasswordValidator.validate', () {
    test('null/empty returns required message', () {
      expect(PasswordValidator.validate(null), isNotNull);
      expect(PasswordValidator.validate(''), isNotNull);
    });

    test('too short returns min-length message', () {
      final msg = PasswordValidator.validate('Ab1!');
      expect(msg, contains('8'));
    });

    test('too long returns max-length message', () {
      final long = 'A' * 129;
      expect(PasswordValidator.validate(long), contains('128'));
    });

    test('valid login password (no complexity) returns null', () {
      // Default isSignUp = false — only length checked
      expect(PasswordValidator.validate('simple12'), isNull);
    });

    test('sign-up: missing uppercase returns message', () {
      final msg = PasswordValidator.validate('abcdef1!', isSignUp: true);
      expect(msg, contains('besar'));
    });

    test('sign-up: missing lowercase returns message', () {
      final msg = PasswordValidator.validate('ABCDEF1!', isSignUp: true);
      expect(msg, contains('kecil'));
    });

    test('sign-up: missing number returns message', () {
      final msg = PasswordValidator.validate('Abcdef!!', isSignUp: true);
      expect(msg, contains('angka'));
    });

    test('sign-up: missing special char returns message', () {
      final msg = PasswordValidator.validate('Abcdef12', isSignUp: true);
      expect(msg, contains('spesial'));
    });

    test('sign-up: common password rejected', () {
      final msg = PasswordValidator.validate('Password1!', isSignUp: true);
      expect(msg, contains('umum'));
    });

    test('sign-up: sequential chars rejected', () {
      final msg = PasswordValidator.validate('Abcdef1!abc', isSignUp: true);
      expect(msg, isNotNull);
    });

    test('sign-up: repeated chars rejected', () {
      final msg = PasswordValidator.validate('Aaaa1!Bbb', isSignUp: true);
      expect(msg, isNotNull);
    });

    test('sign-up: strong password returns null', () {
      expect(PasswordValidator.validate('Tr0ub4dor&3', isSignUp: true), isNull);
      expect(PasswordValidator.validate('X9#mPqL2@wZ', isSignUp: true), isNull);
    });
  });

  group('PasswordValidator.getStrength', () {
    test('empty password → 0', () => expect(PasswordValidator.getStrength(''), 0));

    test('only lowercase short → 1', () {
      expect(PasswordValidator.getStrength('abcdefgh'), lessThanOrEqualTo(2));
    });

    test('strong password → 4', () {
      expect(PasswordValidator.getStrength('X9#mPqL2@wZ'), 4);
    });

    test('common password → max 1', () {
      expect(PasswordValidator.getStrength('password123'), lessThanOrEqualTo(1));
    });
  });

  group('PasswordValidator.getStrengthLabel', () {
    test('returns Indonesian labels', () {
      expect(PasswordValidator.getStrengthLabel(''), 'Sangat Lemah');
      expect(PasswordValidator.getStrengthLabel('X9#mPqL2@wZ'), 'Kuat');
    });
  });

  group('PasswordValidator.isCommonPassword', () {
    test('known common passwords return true', () {
      expect(PasswordValidator.isCommonPassword('password'), isTrue);
      expect(PasswordValidator.isCommonPassword('12345678'), isTrue);
      expect(PasswordValidator.isCommonPassword('admin123'), isTrue);
    });

    test('unique password returns false', () {
      expect(PasswordValidator.isCommonPassword('X9#mPqL2@wZ'), isFalse);
    });

    test('case insensitive check', () {
      expect(PasswordValidator.isCommonPassword('PASSWORD'), isTrue);
      expect(PasswordValidator.isCommonPassword('Password'), isTrue);
    });
  });

  group('PasswordValidator.hasSequentialCharacters', () {
    test('abc → true', () => expect(PasswordValidator.hasSequentialCharacters('abc'), isTrue));
    test('123 → true', () => expect(PasswordValidator.hasSequentialCharacters('123'), isTrue));
    test('cba → true (descending)', () => expect(PasswordValidator.hasSequentialCharacters('cba'), isTrue));
    test('random → false', () => expect(PasswordValidator.hasSequentialCharacters('x7#'), isFalse));
    test('short (< 3) → false', () => expect(PasswordValidator.hasSequentialCharacters('ab'), isFalse));
  });

  group('PasswordValidator.hasRepeatedCharacters', () {
    test('aaa → true', () => expect(PasswordValidator.hasRepeatedCharacters('aaa'), isTrue));
    test('111 → true', () => expect(PasswordValidator.hasRepeatedCharacters('111'), isTrue));
    test('no repeats → false', () => expect(PasswordValidator.hasRepeatedCharacters('abcd'), isFalse));
    test('short (< 3) → false', () => expect(PasswordValidator.hasRepeatedCharacters('aa'), isFalse));
  });

  group('PasswordValidator.getRequirementsMessage', () {
    test('contains Indonesian password rules', () {
      final msg = PasswordValidator.getRequirementsMessage();
      expect(msg, contains('8'));
      expect(msg, contains('huruf besar'));
      expect(msg, contains('huruf kecil'));
      expect(msg, contains('angka'));
      expect(msg, contains('spesial'));
    });
  });
}
