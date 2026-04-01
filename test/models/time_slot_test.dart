import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/time_slot.dart';

void main() {
  group('TimeSlot Model', () {
    final testDateTime = DateTime(2024, 1, 1, 12, 0);
    
    final testTimeSlot = TimeSlot(
      id: 'slot123',
      fieldId: 'field456',
      startTime: '09:00',
      endTime: '11:00',
      pricePerHour: 75000,
      isAvailable: true,
      specialUsername: 'pimpinan',
      specialPrice: 0,
      createdAt: testDateTime,
      updatedAt: testDateTime,
    );

    test('should create TimeSlot with all fields', () {
      expect(testTimeSlot.id, 'slot123');
      expect(testTimeSlot.fieldId, 'field456');
      expect(testTimeSlot.startTime, '09:00');
      expect(testTimeSlot.endTime, '11:00');
      expect(testTimeSlot.pricePerHour, 75000);
      expect(testTimeSlot.isAvailable, true);
      expect(testTimeSlot.specialUsername, 'pimpinan');
      expect(testTimeSlot.specialPrice, 0);
    });

    test('should create TimeSlot with minimal fields', () {
      final minimalSlot = TimeSlot(
        fieldId: 'field789',
        startTime: '13:00',
        endTime: '15:00',
        pricePerHour: 50000,
      );

      expect(minimalSlot.id, isNull);
      expect(minimalSlot.isAvailable, true); // Default
      expect(minimalSlot.specialUsername, isNull);
      expect(minimalSlot.specialPrice, isNull);
      expect(minimalSlot.createdAt, isNull);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'id': 'slot123',
        'field_id': 'field456',
        'start_time': '09:00',
        'end_time': '11:00',
        'price_per_hour': 75000,
        'is_available': true,
        'special_username': 'pimpinan',
        'special_price': 0,
        'created_at': '2024-01-01T12:00:00.000',
        'updated_at': '2024-01-01T12:00:00.000',
      };

      final slot = TimeSlot.fromJson(json);

      expect(slot.id, 'slot123');
      expect(slot.fieldId, 'field456');
      expect(slot.startTime, '09:00');
      expect(slot.endTime, '11:00');
      expect(slot.pricePerHour, 75000);
      expect(slot.isAvailable, true);
      expect(slot.specialUsername, 'pimpinan');
      expect(slot.specialPrice, 0);
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'field_id': 'field789',
        'start_time': '13:00',
        'end_time': '15:00',
        'price_per_hour': 50000,
      };

      final slot = TimeSlot.fromJson(json);

      expect(slot.id, isNull);
      expect(slot.isAvailable, true); // Default
      expect(slot.specialUsername, isNull);
      expect(slot.specialPrice, isNull);
    });

    test('toJson should convert TimeSlot to JSON correctly', () {
      final json = testTimeSlot.toJson();

      expect(json['id'], 'slot123');
      expect(json['field_id'], 'field456');
      expect(json['start_time'], '09:00');
      expect(json['end_time'], '11:00');
      expect(json['price_per_hour'], 75000);
      expect(json['is_available'], true);
      expect(json['special_username'], 'pimpinan');
      expect(json['special_price'], 0);
    });

    test('toJson should handle null fields correctly', () {
      final minimalSlot = TimeSlot(
        fieldId: 'field789',
        startTime: '13:00',
        endTime: '15:00',
        pricePerHour: 50000,
      );

      final json = minimalSlot.toJson();

      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json.containsKey('updated_at'), false);
      expect(json['special_username'], isNull);
      expect(json['special_price'], isNull);
    });

    test('getPriceForUser should return special price for matching username', () {
      final price = testTimeSlot.getPriceForUser('pimpinan');
      expect(price, 0);
    });

    test('getPriceForUser should be case insensitive', () {
      final price1 = testTimeSlot.getPriceForUser('PIMPINAN');
      final price2 = testTimeSlot.getPriceForUser('Pimpinan');
      final price3 = testTimeSlot.getPriceForUser('pImPiNaN');
      
      expect(price1, 0);
      expect(price2, 0);
      expect(price3, 0);
    });

    test('getPriceForUser should return normal price for non-matching username', () {
      final price = testTimeSlot.getPriceForUser('regular-user');
      expect(price, 75000);
    });

    test('getPriceForUser should return normal price for null username', () {
      final price = testTimeSlot.getPriceForUser(null);
      expect(price, 75000);
    });

    test('getPriceForUser should return normal price when no special price set', () {
      final regularSlot = TimeSlot(
        fieldId: 'field789',
        startTime: '13:00',
        endTime: '15:00',
        pricePerHour: 50000,
      );

      final price = regularSlot.getPriceForUser('anyone');
      expect(price, 50000);
    });

    test('hasSpecialPrice should return true when both fields are set', () {
      expect(testTimeSlot.hasSpecialPrice, true);
    });

    test('hasSpecialPrice should return false when either field is null', () {
      final slot1 = TimeSlot(
        fieldId: 'field1',
        startTime: '09:00',
        endTime: '11:00',
        pricePerHour: 50000,
        specialUsername: 'user',
      );

      final slot2 = TimeSlot(
        fieldId: 'field2',
        startTime: '09:00',
        endTime: '11:00',
        pricePerHour: 50000,
        specialPrice: 0,
      );

      final slot3 = TimeSlot(
        fieldId: 'field3',
        startTime: '09:00',
        endTime: '11:00',
        pricePerHour: 50000,
      );

      expect(slot1.hasSpecialPrice, false);
      expect(slot2.hasSpecialPrice, false);
      expect(slot3.hasSpecialPrice, false);
    });

    test('timeRange should return formatted string', () {
      expect(testTimeSlot.timeRange, '09:00 - 11:00');
    });

    test('copyWith should update specified fields only', () {
      final updated = testTimeSlot.copyWith(
        isAvailable: false,
        pricePerHour: 100000,
      );

      expect(updated.isAvailable, false);
      expect(updated.pricePerHour, 100000);
      expect(updated.id, testTimeSlot.id);
      expect(updated.fieldId, testTimeSlot.fieldId);
      expect(updated.startTime, testTimeSlot.startTime);
    });

    test('copyWith should handle all fields', () {
      final newDateTime = DateTime(2024, 2, 1);
      final updated = testTimeSlot.copyWith(
        id: 'new-id',
        fieldId: 'new-field',
        startTime: '14:00',
        endTime: '16:00',
        pricePerHour: 100000,
        isAvailable: false,
        specialUsername: 'new-user',
        specialPrice: 50000,
        createdAt: newDateTime,
        updatedAt: newDateTime,
      );

      expect(updated.id, 'new-id');
      expect(updated.fieldId, 'new-field');
      expect(updated.startTime, '14:00');
      expect(updated.endTime, '16:00');
      expect(updated.pricePerHour, 100000);
      expect(updated.isAvailable, false);
      expect(updated.specialUsername, 'new-user');
      expect(updated.specialPrice, 50000);
    });

    test('toString should include key info', () {
      final str = testTimeSlot.toString();
      
      expect(str, contains('slot123'));
      expect(str, contains('field456'));
      expect(str, contains('09:00 - 11:00'));
      expect(str, contains('75000'));
      expect(str, contains('true'));
      expect(str, contains('pimpinan'));
      expect(str, contains('0'));
    });

    test('isAvailable can be modified', () {
      final slot = TimeSlot(
        fieldId: 'field1',
        startTime: '09:00',
        endTime: '11:00',
        pricePerHour: 50000,
        isAvailable: true,
      );

      expect(slot.isAvailable, true);
      slot.isAvailable = false;
      expect(slot.isAvailable, false);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testTimeSlot.toJson();
      final reconstructed = TimeSlot.fromJson(json);

      expect(reconstructed.id, testTimeSlot.id);
      expect(reconstructed.fieldId, testTimeSlot.fieldId);
      expect(reconstructed.startTime, testTimeSlot.startTime);
      expect(reconstructed.endTime, testTimeSlot.endTime);
      expect(reconstructed.pricePerHour, testTimeSlot.pricePerHour);
      expect(reconstructed.isAvailable, testTimeSlot.isAvailable);
      expect(reconstructed.specialUsername, testTimeSlot.specialUsername);
      expect(reconstructed.specialPrice, testTimeSlot.specialPrice);
    });
  });
}
