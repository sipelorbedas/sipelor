/// Staff role enum
enum StaffRole {
  admin,
  operator,
  manager;

  String get displayName {
    switch (this) {
      case StaffRole.admin:
        return 'Admin';
      case StaffRole.operator:
        return 'Operator';
      case StaffRole.manager:
        return 'Manager';
    }
  }

  String get value {
    switch (this) {
      case StaffRole.admin:
        return 'admin';
      case StaffRole.operator:
        return 'operator';
      case StaffRole.manager:
        return 'manager';
    }
  }

  static StaffRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return StaffRole.admin;
      case 'operator':
        return StaffRole.operator;
      case 'manager':
        return StaffRole.manager;
      default:
        return StaffRole.operator;
    }
  }
}

/// Staff model
class Staff {
  final String id;
  final String userId; // Foreign key to profiles/auth.users
  final String name;
  final String email;
  final String? phone;
  final StaffRole role;
  final List<String> assignedVenues; // List of venue IDs
  final bool isActive;
  final DateTime? lastLogin;
  final DateTime createdAt;
  final DateTime updatedAt;

  Staff({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    required this.assignedVenues,
    required this.isActive,
    this.lastLogin,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Staff.fromJson(Map<String, dynamic> json) {
    return Staff(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      role: StaffRole.fromString(json['role'] as String),
      assignedVenues: (json['assigned_venues'] as List?)?.cast<String>() ?? [],
      isActive: json['is_active'] as bool? ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.value,
      'assigned_venues': assignedVenues,
      'is_active': isActive,
      'last_login': lastLogin?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Staff copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    StaffRole? role,
    List<String>? assignedVenues,
    bool? isActive,
    DateTime? lastLogin,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Staff(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedVenues: assignedVenues ?? this.assignedVenues,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
