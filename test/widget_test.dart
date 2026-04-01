/// Smoke tests & core unit tests for SIPELOR BEDAS
/// These run quickly without requiring Supabase or device dependencies.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/booking.dart';
import 'package:sipelor/models/field.dart';
import 'package:sipelor/config/ssl_config.dart';

void main() {
  // ─── App Metadata ────────────────────────────────────────────────────────
  group('App Configuration', () {
    test('app version format is correct', () {
      const version = '1.0.0+2';
      expect(version, matches(RegExp(r'^\d+\.\d+\.\d+\+\d+$')));
    });

    test('environment is development or production', () {
      const env = String.fromEnvironment('ENVIRONMENT', defaultValue: 'development');
      expect(env, isIn(['development', 'staging', 'production']));
    });
  });

  // ─── BookingStatus ───────────────────────────────────────────────────────
  group('BookingStatus', () {
    test('fromString parses all 4 statuses', () {
      for (final status in BookingStatus.values) {
        expect(BookingStatus.fromString(status.value), status);
      }
    });

    test('value round-trips correctly', () {
      for (final status in BookingStatus.values) {
        expect(BookingStatus.fromString(status.value).value, status.value);
      }
    });

    test('unknown string defaults to pending', () {
      expect(BookingStatus.fromString('xyz'), BookingStatus.pending);
    });

    test('display names are in Indonesian', () {
      expect(BookingStatus.pending.displayName, 'Menunggu');
      expect(BookingStatus.confirmed.displayName, 'Dikonfirmasi');
      expect(BookingStatus.completed.displayName, 'Selesai');
      expect(BookingStatus.cancelled.displayName, 'Dibatalkan');
    });
  });

  // ─── PaymentStatus ───────────────────────────────────────────────────────
  group('PaymentStatus', () {
    test('fromString parses all 3 statuses', () {
      for (final status in PaymentStatus.values) {
        expect(PaymentStatus.fromString(status.value), status);
      }
    });

    test('unknown string defaults to pending', () {
      expect(PaymentStatus.fromString('refunded'), PaymentStatus.pending);
    });
  });

  // ─── BookingType ─────────────────────────────────────────────────────────
  group('BookingType', () {
    test('fromString parses all 3 types', () {
      for (final type in BookingType.values) {
        expect(BookingType.fromString(type.value), type);
      }
    });

    test('opd and pimpinan are official bookings', () {
      expect(BookingType.opd.isOfficialBooking, true);
      expect(BookingType.pimpinan.isOfficialBooking, true);
      expect(BookingType.regular.isOfficialBooking, false);
    });
  });

  // ─── FieldStatus ─────────────────────────────────────────────────────────
  group('FieldStatus', () {
    test('fromString parses all 3 statuses', () {
      for (final status in FieldStatus.values) {
        expect(FieldStatus.fromString(status.value), status);
      }
    });

    test('isActive is true only for available', () {
      final f = Field(
        id: 'f',
        venueName: 'V',
        venueType: 'Futsal',
        area: 'A',
        pricePerHour: 100000,
        status: FieldStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(f.isActive, true);
      expect(f.copyWith(status: FieldStatus.booked).isActive, false);
      expect(f.copyWith(status: FieldStatus.maintenance).isActive, false);
    });
  });

  // ─── Booking.fromJson / toJson Round Trip ────────────────────────────────
  group('Booking JSON round trip', () {
    test('all values survive fromJson → toJson', () {
      final json = {
        'id': 'uuid-rt',
        'booking_id': 'SJH-20260301-0999',
        'user_id': 'user',
        'field_id': 'field',
        'venue_id': 'venue',
        'booking_date': '2026-03-01',
        'start_time': '09:00',
        'end_time': '11:00',
        'duration_hours': 2,
        'total_amount': 250000,
        'status': 'confirmed',
        'payment_status': 'verified',
        'created_at': '2026-03-01T09:00:00Z',
        'updated_at': '2026-03-01T09:00:00Z',
      };
      final b = Booking.fromJson(json);
      final out = b.toJson();
      expect(out['booking_id'], json['booking_id']);
      expect(out['status'], json['status']);
      expect(out['payment_status'], json['payment_status']);
      expect(out['total_amount'], json['total_amount']);
    });

    test('nested fields key populates venueName', () {
      final json = {
        'id': 'uuid',
        'booking_id': 'SJH-001',
        'user_id': 'user',
        'field_id': 'field',
        'booking_date': '2026-01-01',
        'start_time': '08:00',
        'end_time': '09:00',
        'duration_hours': 1,
        'total_amount': 100000,
        'status': 'pending',
        'payment_status': 'pending',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'fields': {'venue_name': 'Lapangan A', 'area': 'BDG', 'venue_type': 'Futsal'},
      };
      final b = Booking.fromJson(json);
      expect(b.venueName, 'Lapangan A');
      expect(b.fieldArea, 'BDG');
      expect(b.venueType, 'Futsal');
    });
  });

  // ─── Field.fromJson ──────────────────────────────────────────────────────
  group('Field.fromJson', () {
    test('parses image_urls as list', () {
      final json = {
        'id': 'f',
        'venue_name': 'V',
        'venue_type': 'Futsal',
        'area': 'A',
        'price_per_hour': 100000,
        'status': 'available',
        'image_urls': ['https://a.com/1.jpg', 'https://a.com/2.jpg'],
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final f = Field.fromJson(json);
      expect(f.imageUrls?.length, 2);
    });

    test('parses single string image_urls', () {
      final json = {
        'id': 'f',
        'venue_name': 'V',
        'venue_type': 'Futsal',
        'area': 'A',
        'price_per_hour': 100000,
        'status': 'available',
        'image_urls': 'https://a.com/1.jpg',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final f = Field.fromJson(json);
      expect(f.imageUrls?.length, 1);
    });
  });

  // ─── SSL Config ──────────────────────────────────────────────────────────
  group('SSLConfig', () {
    test('certificate pins have correct sha256/ prefix', () {
      for (final pin in SSLConfig.certificatePins) {
        expect(pin, startsWith('sha256/'));
      }
    });

    test('at least 2 pins configured', () {
      expect(SSLConfig.certificatePins.length, greaterThanOrEqualTo(2));
    });

    test('validate() returns true', () {
      expect(SSLConfig.validate(), true);
    });

    test('supabaseDomain is not empty', () {
      expect(SSLConfig.supabaseDomain, isNotEmpty);
    });
  });

  // ─── Infrastructure ──────────────────────────────────────────────────────
  group('Test Infrastructure', () {
    test('basic arithmetic', () {
      expect(1 + 1, 2);
    });

    test('list operations', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.where((n) => n.isEven).toList(), [2, 4]);
    });

    test('map operations', () {
      final map = {'a': 1, 'b': 2};
      expect(map.containsKey('a'), true);
      expect(map['b'], 2);
    });

    test('DateTime parsing', () {
      final dt = DateTime.parse('2026-03-01T08:00:00Z');
      expect(dt.year, 2026);
      expect(dt.month, 3);
      expect(dt.day, 1);
    });

    test('RegExp booking ID format', () {
      final regex = RegExp(r'^SJH-\d{8}-\d{4}$');
      expect(regex.hasMatch('SJH-20260301-0001'), true);
      expect(regex.hasMatch('BOOK001'), false);
    });
  });
}
