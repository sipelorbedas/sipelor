import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/maintenance_schedule.dart';

void main() {
  group('MaintenanceStatus Enum', () {
    test('displayName should return correct names', () {
      expect(MaintenanceStatus.scheduled.displayName, 'Dijadwalkan');
      expect(MaintenanceStatus.inProgress.displayName, 'Sedang Berlangsung');
      expect(MaintenanceStatus.completed.displayName, 'Selesai');
      expect(MaintenanceStatus.cancelled.displayName, 'Dibatalkan');
    });

    test('value should return correct values', () {
      expect(MaintenanceStatus.scheduled.value, 'scheduled');
      expect(MaintenanceStatus.inProgress.value, 'in_progress');
      expect(MaintenanceStatus.completed.value, 'completed');
      expect(MaintenanceStatus.cancelled.value, 'cancelled');
    });

    test('fromString should parse correctly', () {
      expect(MaintenanceStatus.fromString('scheduled'), MaintenanceStatus.scheduled);
      expect(MaintenanceStatus.fromString('in_progress'), MaintenanceStatus.inProgress);
      expect(MaintenanceStatus.fromString('completed'), MaintenanceStatus.completed);
      expect(MaintenanceStatus.fromString('cancelled'), MaintenanceStatus.cancelled);
    });

    test('fromString should be case insensitive', () {
      expect(MaintenanceStatus.fromString('SCHEDULED'), MaintenanceStatus.scheduled);
      expect(MaintenanceStatus.fromString('In_Progress'), MaintenanceStatus.inProgress);
    });

    test('fromString should default to scheduled for invalid input', () {
      expect(MaintenanceStatus.fromString('invalid'), MaintenanceStatus.scheduled);
    });
  });

  group('MaintenanceSchedule Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    final startDate = DateTime(2024, 1, 10);
    final endDate = DateTime(2024, 1, 12);
    
    final testSchedule = MaintenanceSchedule(
      id: 'maint123',
      venueId: 'venue456',
      fieldId: 'field789',
      title: 'Regular Maintenance',
      description: 'Monthly routine maintenance',
      startDate: startDate,
      endDate: endDate,
      status: MaintenanceStatus.scheduled,
      assignedTo: 'staff123',
      notes: 'Check all equipment',
      createdAt: testDateTime,
      updatedAt: testDateTime,
      venueName: 'Best Arena',
      fieldName: 'Field A',
      assignedStaffName: 'John Doe',
    );

    test('should create MaintenanceSchedule with all fields', () {
      expect(testSchedule.id, 'maint123');
      expect(testSchedule.venueId, 'venue456');
      expect(testSchedule.fieldId, 'field789');
      expect(testSchedule.title, 'Regular Maintenance');
      expect(testSchedule.description, 'Monthly routine maintenance');
      expect(testSchedule.startDate, startDate);
      expect(testSchedule.endDate, endDate);
      expect(testSchedule.status, MaintenanceStatus.scheduled);
      expect(testSchedule.assignedTo, 'staff123');
      expect(testSchedule.notes, 'Check all equipment');
      expect(testSchedule.venueName, 'Best Arena');
    });

    test('should create MaintenanceSchedule with null optional fields', () {
      final minimalSchedule = MaintenanceSchedule(
        id: 'maint456',
        venueId: 'venue789',
        title: 'Quick Fix',
        startDate: startDate,
        endDate: endDate,
        status: MaintenanceStatus.inProgress,
        createdAt: testDateTime,
        updatedAt: testDateTime,
      );

      expect(minimalSchedule.fieldId, isNull);
      expect(minimalSchedule.description, isNull);
      expect(minimalSchedule.assignedTo, isNull);
      expect(minimalSchedule.notes, isNull);
      expect(minimalSchedule.venueName, isNull);
      expect(minimalSchedule.fieldName, isNull);
      expect(minimalSchedule.assignedStaffName, isNull);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'maint123',
        'venue_id': 'venue456',
        'field_id': 'field789',
        'title': 'Regular Maintenance',
        'description': 'Monthly routine maintenance',
        'start_date': '2024-01-10T00:00:00.000',
        'end_date': '2024-01-12T00:00:00.000',
        'status': 'scheduled',
        'assigned_to': 'staff123',
        'notes': 'Check all equipment',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
        'venues': {'name': 'Best Arena'},
        'fields': {'area': 'Field A'},
        'staff': {'name': 'John Doe'},
      };

      final schedule = MaintenanceSchedule.fromJson(json);

      expect(schedule.id, 'maint123');
      expect(schedule.title, 'Regular Maintenance');
      expect(schedule.status, MaintenanceStatus.scheduled);
      expect(schedule.venueName, 'Best Arena');
      expect(schedule.fieldName, 'Field A');
      expect(schedule.assignedStaffName, 'John Doe');
    });

    test('fromJson should handle null joined data', () {
      final json = {
        'id': 'maint456',
        'venue_id': 'venue789',
        'title': 'Quick Fix',
        'start_date': '2024-01-10T00:00:00.000',
        'end_date': '2024-01-12T00:00:00.000',
        'status': 'in_progress',
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final schedule = MaintenanceSchedule.fromJson(json);

      expect(schedule.venueName, isNull);
      expect(schedule.fieldName, isNull);
      expect(schedule.assignedStaffName, isNull);
    });

    test('toJson should convert to JSON correctly', () {
      final json = testSchedule.toJson();

      expect(json['id'], 'maint123');
      expect(json['venue_id'], 'venue456');
      expect(json['field_id'], 'field789');
      expect(json['title'], 'Regular Maintenance');
      expect(json['description'], 'Monthly routine maintenance');
      expect(json['start_date'], startDate.toIso8601String());
      expect(json['end_date'], endDate.toIso8601String());
      expect(json['status'], 'scheduled');
      expect(json['assigned_to'], 'staff123');
      expect(json['notes'], 'Check all equipment');
    });

    test('copyWith should update specified fields only', () {
      final updated = testSchedule.copyWith(
        status: MaintenanceStatus.inProgress,
        notes: 'Updated notes',
      );

      expect(updated.status, MaintenanceStatus.inProgress);
      expect(updated.notes, 'Updated notes');
      expect(updated.id, testSchedule.id);
      expect(updated.title, testSchedule.title);
    });

    test('isActive should return true only for inProgress', () {
      expect(testSchedule.copyWith(status: MaintenanceStatus.inProgress).isActive, true);
      expect(testSchedule.copyWith(status: MaintenanceStatus.scheduled).isActive, false);
      expect(testSchedule.copyWith(status: MaintenanceStatus.completed).isActive, false);
      expect(testSchedule.copyWith(status: MaintenanceStatus.cancelled).isActive, false);
    });

    test('isPending should return true only for scheduled', () {
      expect(testSchedule.copyWith(status: MaintenanceStatus.scheduled).isPending, true);
      expect(testSchedule.copyWith(status: MaintenanceStatus.inProgress).isPending, false);
    });

    test('isDone should return true only for completed', () {
      expect(testSchedule.copyWith(status: MaintenanceStatus.completed).isDone, true);
      expect(testSchedule.copyWith(status: MaintenanceStatus.scheduled).isDone, false);
      expect(testSchedule.copyWith(status: MaintenanceStatus.inProgress).isDone, false);
    });
  });
}
