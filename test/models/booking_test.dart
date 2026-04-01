import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/booking.dart';

void main() {
  // ─── Helper ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> baseJson({
    String status = 'pending',
    String paymentStatus = 'pending',
    String bookingType = 'regular',
    String? opdId,
    String? bookedForLabel,
    bool? hasPaymentProof,
  }) =>
      {
        'id': 'uuid-001',
        'booking_id': 'SJH-20260301-0001',
        'user_id': 'user-uuid',
        'field_id': 'field-uuid',
        'venue_id': 'venue-uuid',
        'booking_date': '2026-03-01',
        'start_time': '08:00',
        'end_time': '10:00',
        'duration_hours': 2,
        'total_amount': 300000,
        'status': status,
        'payment_status': paymentStatus,
        'notes': 'Test booking',
        'created_at': '2026-03-01T08:00:00Z',
        'updated_at': '2026-03-01T08:00:00Z',
        'booking_type': bookingType,
        'opd_id': ?opdId,
        'booked_for_label': ?bookedForLabel,
        'has_payment_proof': ?hasPaymentProof,
      };

  // ─── Booking.fromJson ────────────────────────────────────────────────────────
  group('Booking.fromJson', () {
    test('parses all required fields correctly', () {
      final b = Booking.fromJson(baseJson());
      expect(b.id, 'uuid-001');
      expect(b.bookingId, 'SJH-20260301-0001');
      expect(b.userId, 'user-uuid');
      expect(b.fieldId, 'field-uuid');
      expect(b.venueId, 'venue-uuid');
      expect(b.startTime, '08:00');
      expect(b.endTime, '10:00');
      expect(b.durationHours, 2);
      expect(b.totalAmount, 300000);
      expect(b.notes, 'Test booking');
    });

    test('falls back venueId to fieldId when venue_id is null', () {
      final json = baseJson()..remove('venue_id');
      final b = Booking.fromJson(json);
      expect(b.venueId, 'field-uuid'); // fallback to field_id
    });

    test('parses nested fields join data', () {
      final json = baseJson()
        ..['fields'] = {
          'venue_name': 'Lapangan Futsal A',
          'area': 'Bandung Barat',
          'venue_type': 'Futsal',
        };
      final b = Booking.fromJson(json);
      expect(b.venueName, 'Lapangan Futsal A');
      expect(b.fieldArea, 'Bandung Barat');
      expect(b.venueType, 'Futsal');
    });

    test('has_payment_proof defaults to true when absent', () {
      final b = Booking.fromJson(baseJson());
      expect(b.hasPaymentProof, true);
    });

    test('has_payment_proof false is respected', () {
      final b = Booking.fromJson(baseJson(hasPaymentProof: false));
      expect(b.hasPaymentProof, false);
    });

    test('parses OPD booking type', () {
      final b = Booking.fromJson(baseJson(
        bookingType: 'opd',
        opdId: 'opd-uuid',
        bookedForLabel: 'Acara Bupati Cup 2026',
      ));
      expect(b.bookingType, BookingType.opd);
      expect(b.opdId, 'opd-uuid');
      expect(b.bookedForLabel, 'Acara Bupati Cup 2026');
    });

    test('parses pimpinan booking type', () {
      final b = Booking.fromJson(baseJson(bookingType: 'pimpinan'));
      expect(b.bookingType, BookingType.pimpinan);
      expect(b.bookingType.isOfficialBooking, true);
    });

    test('parses opd_name from opd_organizations nested join', () {
      final json = baseJson()
        ..['opd_organizations'] = {'name': 'Dinas Pendidikan'};
      final b = Booking.fromJson(json);
      expect(b.opdName, 'Dinas Pendidikan');
    });
  });

  // ─── Booking.toJson ──────────────────────────────────────────────────────────
  group('Booking.toJson', () {
    test('serializes booking_date as date-only string', () {
      final b = Booking(
        id: 'uuid-001',
        bookingId: 'SJH-001',
        userId: 'user',
        fieldId: 'field',
        venueId: 'venue',
        bookingDate: DateTime(2026, 3, 1),
        startTime: '08:00',
        endTime: '10:00',
        durationHours: 2,
        totalAmount: 300000,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      );
      final json = b.toJson();
      expect(json['booking_date'], '2026-03-01');
      expect(json['id'], 'uuid-001');
      expect(json['status'], 'pending');
      expect(json['payment_status'], 'pending');
      expect(json['booking_type'], 'regular');
    });

    test('includes opd_name only when not null', () {
      final b = Booking(
        id: 'uuid-001',
        bookingId: 'SJH-001',
        userId: 'user',
        fieldId: 'field',
        venueId: 'venue',
        bookingDate: DateTime(2026, 3, 1),
        startTime: '08:00',
        endTime: '10:00',
        durationHours: 2,
        totalAmount: 300000,
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
        opdName: 'Dinas Olahraga',
      );
      expect(b.toJson().containsKey('opd_name'), true);

      final bNoOpd = b.copyWith(opdName: null);
      expect(bNoOpd.toJson().containsKey('opd_name'), false);
    });
  });

  // ─── Booking.copyWith ────────────────────────────────────────────────────────
  group('Booking.copyWith', () {
    late Booking original;
    setUp(() {
      original = Booking.fromJson(baseJson());
    });

    test('copies all fields when nothing is overridden', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.status, original.status);
    });

    test('overrides only specified fields', () {
      final updated = original.copyWith(
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.verified,
        totalAmount: 400000,
      );
      expect(updated.status, BookingStatus.confirmed);
      expect(updated.paymentStatus, PaymentStatus.verified);
      expect(updated.totalAmount, 400000);
      expect(updated.id, original.id); // unchanged
      expect(updated.userId, original.userId); // unchanged
    });
  });

  // ─── BookingStatus ───────────────────────────────────────────────────────────
  group('BookingStatus', () {
    test('fromString parses all valid values', () {
      expect(BookingStatus.fromString('pending'), BookingStatus.pending);
      expect(BookingStatus.fromString('confirmed'), BookingStatus.confirmed);
      expect(BookingStatus.fromString('completed'), BookingStatus.completed);
      expect(BookingStatus.fromString('cancelled'), BookingStatus.cancelled);
    });

    test('fromString is case-insensitive', () {
      expect(BookingStatus.fromString('PENDING'), BookingStatus.pending);
      expect(BookingStatus.fromString('Confirmed'), BookingStatus.confirmed);
    });

    test('fromString returns pending for unknown value', () {
      expect(BookingStatus.fromString('unknown'), BookingStatus.pending);
      expect(BookingStatus.fromString(''), BookingStatus.pending);
    });

    test('value getter returns lowercase string', () {
      expect(BookingStatus.pending.value, 'pending');
      expect(BookingStatus.confirmed.value, 'confirmed');
      expect(BookingStatus.completed.value, 'completed');
      expect(BookingStatus.cancelled.value, 'cancelled');
    });

    test('displayName returns Indonesian labels', () {
      expect(BookingStatus.pending.displayName, 'Menunggu');
      expect(BookingStatus.confirmed.displayName, 'Dikonfirmasi');
      expect(BookingStatus.completed.displayName, 'Selesai');
      expect(BookingStatus.cancelled.displayName, 'Dibatalkan');
    });
  });

  // ─── PaymentStatus ───────────────────────────────────────────────────────────
  group('PaymentStatus', () {
    test('fromString parses all valid values', () {
      expect(PaymentStatus.fromString('pending'), PaymentStatus.pending);
      expect(PaymentStatus.fromString('verified'), PaymentStatus.verified);
      expect(PaymentStatus.fromString('rejected'), PaymentStatus.rejected);
    });

    test('fromString is case-insensitive', () {
      expect(PaymentStatus.fromString('VERIFIED'), PaymentStatus.verified);
    });

    test('fromString returns pending for unknown value', () {
      expect(PaymentStatus.fromString('unknown'), PaymentStatus.pending);
    });

    test('displayName returns Indonesian labels', () {
      expect(PaymentStatus.pending.displayName, 'Menunggu Verifikasi');
      expect(PaymentStatus.verified.displayName, 'Terverifikasi');
      expect(PaymentStatus.rejected.displayName, 'Ditolak');
    });
  });

  // ─── BookingType ─────────────────────────────────────────────────────────────
  group('BookingType', () {
    test('fromString parses all valid values', () {
      expect(BookingType.fromString('regular'), BookingType.regular);
      expect(BookingType.fromString('opd'), BookingType.opd);
      expect(BookingType.fromString('pimpinan'), BookingType.pimpinan);
    });

    test('fromString returns regular for unknown value', () {
      expect(BookingType.fromString(''), BookingType.regular);
      expect(BookingType.fromString('other'), BookingType.regular);
    });

    test('isOfficialBooking is true only for opd and pimpinan', () {
      expect(BookingType.regular.isOfficialBooking, false);
      expect(BookingType.opd.isOfficialBooking, true);
      expect(BookingType.pimpinan.isOfficialBooking, true);
    });

    test('displayName returns correct labels', () {
      expect(BookingType.regular.displayName, 'Reguler');
      expect(BookingType.opd.displayName, 'OPD');
      expect(BookingType.pimpinan.displayName, 'Pimpinan');
    });

    test('value getter returns lowercase string', () {
      expect(BookingType.regular.value, 'regular');
      expect(BookingType.opd.value, 'opd');
      expect(BookingType.pimpinan.value, 'pimpinan');
    });
  });
}
