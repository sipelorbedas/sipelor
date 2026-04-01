import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/user_role.dart';

void main() {
  group('UserRole Enum', () {
    test('fromString should parse roles correctly', () {
      expect(UserRole.fromString('user'), UserRole.user);
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('superadmin'), UserRole.superadmin);
    });

    test('fromString should be case insensitive', () {
      expect(UserRole.fromString('USER'), UserRole.user);
      expect(UserRole.fromString('Admin'), UserRole.admin);
      expect(UserRole.fromString('SUPERADMIN'), UserRole.superadmin);
      expect(UserRole.fromString('SuperAdmin'), UserRole.superadmin);
    });

    test('fromString should default to user for invalid input', () {
      expect(UserRole.fromString('invalid'), UserRole.user);
      expect(UserRole.fromString(''), UserRole.user);
      expect(UserRole.fromString('unknown'), UserRole.user);
    });

    test('toString should return role name', () {
      expect(UserRole.user.toString(), 'user');
      expect(UserRole.admin.toString(), 'admin');
      expect(UserRole.superadmin.toString(), 'superadmin');
    });

    test('isAdmin should return true for admin roles', () {
      expect(UserRole.admin.isAdmin, true);
      expect(UserRole.superadmin.isAdmin, true);
      expect(UserRole.user.isAdmin, false);
    });

    test('isSuperadmin should return true only for superadmin', () {
      expect(UserRole.superadmin.isSuperadmin, true);
      expect(UserRole.admin.isSuperadmin, false);
      expect(UserRole.user.isSuperadmin, false);
    });

    test('isUser should return true only for user', () {
      expect(UserRole.user.isUser, true);
      expect(UserRole.admin.isUser, false);
      expect(UserRole.superadmin.isUser, false);
    });

    test('displayName should return correct display names', () {
      expect(UserRole.user.displayName, 'User');
      expect(UserRole.admin.displayName, 'Administrator');
      expect(UserRole.superadmin.displayName, 'Super Administrator');
    });

    test('should have exactly three role types', () {
      expect(UserRole.values.length, 3);
      expect(UserRole.values, contains(UserRole.user));
      expect(UserRole.values, contains(UserRole.admin));
      expect(UserRole.values, contains(UserRole.superadmin));
    });

    test('role hierarchy should be consistent', () {
      // Superadmin has all admin privileges
      if (UserRole.superadmin.isSuperadmin) {
        expect(UserRole.superadmin.isAdmin, true);
      }

      // Admin is admin but not superadmin
      if (UserRole.admin.isAdmin) {
        expect(UserRole.admin.isSuperadmin, false);
      }

      // User is neither admin nor superadmin
      if (UserRole.user.isUser) {
        expect(UserRole.user.isAdmin, false);
        expect(UserRole.user.isSuperadmin, false);
      }
    });

    test('round trip string conversion should work', () {
      for (final role in UserRole.values) {
        final str = role.toString();
        final parsed = UserRole.fromString(str);
        expect(parsed, role);
      }
    });
  });
}
