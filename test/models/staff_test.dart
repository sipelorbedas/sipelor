import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/staff.dart';

void main() {
  group('StaffRole Enum', () {
    test('displayName should return correct names', () {
      expect(StaffRole.admin.displayName, 'Admin');
      expect(StaffRole.operator.displayName, 'Operator');
      expect(StaffRole.manager.displayName, 'Manager');
    });

    test('value should return correct values', () {
      expect(StaffRole.admin.value, 'admin');
      expect(StaffRole.operator.value, 'operator');
      expect(StaffRole.manager.value, 'manager');
    });

    test('fromString should parse role correctly', () {
      expect(StaffRole.fromString('admin'), StaffRole.admin);
      expect(StaffRole.fromString('Admin'), StaffRole.admin);
      expect(StaffRole.fromString('ADMIN'), StaffRole.admin);
      expect(StaffRole.fromString('operator'), StaffRole.operator);
      expect(StaffRole.fromString('manager'), StaffRole.manager);
    });

    test('fromString should return operator for invalid role', () {
      expect(StaffRole.fromString('invalid'), StaffRole.operator);
      expect(StaffRole.fromString(''), StaffRole.operator);
      expect(StaffRole.fromString('unknown'), StaffRole.operator);
    });
  });

  group('Staff Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testStaff = Staff(
      id: 'staff123',
      userId: 'user456',
      name: 'John Doe',
      email: 'john@example.com',
      phone: '08123456789',
      role: StaffRole.admin,
      assignedVenues: ['venue1', 'venue2'],
      isActive: true,
      lastLogin: testDateTime,
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('should create Staff with all fields', () {
      expect(testStaff.id, 'staff123');
      expect(testStaff.userId, 'user456');
      expect(testStaff.name, 'John Doe');
      expect(testStaff.email, 'john@example.com');
      expect(testStaff.phone, '08123456789');
      expect(testStaff.role, StaffRole.admin);
      expect(testStaff.assignedVenues, ['venue1', 'venue2']);
      expect(testStaff.isActive, true);
      expect(testStaff.lastLogin, testDateTime);
      expect(testStaff.createdAt, testDateTime);
    });

    test('should create Staff with null optional fields', () {
      final staffWithoutOptionals = Staff(
        id: 'staff123',
        userId: 'user456',
        name: 'Jane Doe',
        email: 'jane@example.com',
        role: StaffRole.operator,
        assignedVenues: [],
        isActive: true,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(staffWithoutOptionals.phone, isNull);
      expect(staffWithoutOptionals.lastLogin, isNull);
      expect(staffWithoutOptionals.assignedVenues, isEmpty);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'staff123',
        'user_id': 'user456',
        'name': 'John Doe',
        'email': 'john@example.com',
        'phone': '08123456789',
        'role': 'admin',
        'assigned_venues': ['venue1', 'venue2'],
        'is_active': true,
        'last_login': '2024-01-01T12:00:00.000',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final staff = Staff.fromJson(json);

      expect(staff.id, 'staff123');
      expect(staff.name, 'John Doe');
      expect(staff.email, 'john@example.com');
      expect(staff.role, StaffRole.admin);
      expect(staff.assignedVenues, ['venue1', 'venue2']);
      expect(staff.isActive, true);
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'id': 'staff123',
        'user_id': 'user456',
        'name': 'Jane Doe',
        'email': 'jane@example.com',
        'role': 'operator',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final staff = Staff.fromJson(json);

      expect(staff.phone, isNull);
      expect(staff.lastLogin, isNull);
      expect(staff.assignedVenues, isEmpty);
      expect(staff.isActive, true); // Default value
    });

    test('toJson should convert Staff to JSON correctly', () {
      final json = testStaff.toJson();

      expect(json['id'], 'staff123');
      expect(json['user_id'], 'user456');
      expect(json['name'], 'John Doe');
      expect(json['email'], 'john@example.com');
      expect(json['phone'], '08123456789');
      expect(json['role'], 'admin');
      expect(json['assigned_venues'], ['venue1', 'venue2']);
      expect(json['is_active'], true);
      expect(json['last_login'], testDateTime.toIso8601String());
    });

    test('copyWith should update specified fields only', () {
      final updated = testStaff.copyWith(
        name: 'Jane Smith',
        role: StaffRole.manager,
      );

      expect(updated.name, 'Jane Smith');
      expect(updated.role, StaffRole.manager);
      expect(updated.id, testStaff.id);
      expect(updated.email, testStaff.email);
      expect(updated.phone, testStaff.phone);
    });

    test('copyWith should handle all fields', () {
      final newDateTime = DateTime(2024, 2, 1);
      final updated = testStaff.copyWith(
        id: 'new-id',
        userId: 'new-user',
        name: 'New Name',
        email: 'new@email.com',
        phone: '0999999999',
        role: StaffRole.operator,
        assignedVenues: ['venue3'],
        isActive: false,
        lastLogin: newDateTime,
        createdAt: newDateTime,
        updatedAt: newDateTime,
      );

      expect(updated.id, 'new-id');
      expect(updated.userId, 'new-user');
      expect(updated.name, 'New Name');
      expect(updated.email, 'new@email.com');
      expect(updated.phone, '0999999999');
      expect(updated.role, StaffRole.operator);
      expect(updated.assignedVenues, ['venue3']);
      expect(updated.isActive, false);
      expect(updated.lastLogin, newDateTime);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testStaff.toJson();
      final reconstructed = Staff.fromJson(json);

      expect(reconstructed.id, testStaff.id);
      expect(reconstructed.name, testStaff.name);
      expect(reconstructed.role, testStaff.role);
      expect(reconstructed.assignedVenues, testStaff.assignedVenues);
      expect(reconstructed.isActive, testStaff.isActive);
    });
  });
}
