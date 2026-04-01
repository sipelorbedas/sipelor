/// User role enum for role-based access control
enum UserRole {
  user,
  admin,
  superadmin;

  /// Convert string to UserRole enum
  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return UserRole.superadmin;
      case 'admin':
        return UserRole.admin;
      case 'user':
      default:
        return UserRole.user;
    }
  }

  /// Convert UserRole enum to string
  @override
  String toString() {
    return name;
  }

  /// Check if role is admin or superadmin
  bool get isAdmin {
    return this == UserRole.admin || this == UserRole.superadmin;
  }

  /// Check if role is superadmin
  bool get isSuperadmin {
    return this == UserRole.superadmin;
  }

  /// Check if role is user
  bool get isUser {
    return this == UserRole.user;
  }

  /// Display name for the role
  String get displayName {
    switch (this) {
      case UserRole.superadmin:
        return 'Super Administrator';
      case UserRole.admin:
        return 'Administrator';
      case UserRole.user:
        return 'User';
    }
  }
}
