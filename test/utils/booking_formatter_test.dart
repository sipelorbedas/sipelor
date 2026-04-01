import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/booking.dart';

/// Tests for data formatting logic used across booking screens.
/// Mirrors the price formatting and status display logic found in
/// home_screen.dart, user_bookings_screen.dart, etc.
void main() {
  group('Price Formatting', () {
    // Mirrors _formatPriceNumber in HomeScreen
    String formatPrice(int price) {
      final priceStr = price.toString();
      final buffer = StringBuffer();
      var count = 0;
      for (var i = priceStr.length - 1; i >= 0; i--) {
        if (count > 0 && count % 3 == 0) buffer.write('.');
        buffer.write(priceStr[i]);
        count++;
      }
      return buffer.toString().split('').reversed.join('');
    }

    test('formats 150000 as "150.000"', () {
      expect(formatPrice(150000), '150.000');
    });

    test('formats 1000000 as "1.000.000"', () {
      expect(formatPrice(1000000), '1.000.000');
    });

    test('formats 75000 as "75.000"', () {
      expect(formatPrice(75000), '75.000');
    });

    test('formats 1000 as "1.000"', () {
      expect(formatPrice(1000), '1.000');
    });

    test('formats 500 as "500"', () {
      expect(formatPrice(500), '500');
    });

    test('formats 0 as "0"', () {
      expect(formatPrice(0), '0');
    });
  });

  group('Booking Status Display Logic', () {
    test('pending status shows correct display name', () {
      expect(BookingStatus.pending.displayName, 'Menunggu');
    });

    test('confirmed status shows correct display name', () {
      expect(BookingStatus.confirmed.displayName, 'Dikonfirmasi');
    });

    test('completed status shows correct display name', () {
      expect(BookingStatus.completed.displayName, 'Selesai');
    });

    test('cancelled status shows correct display name', () {
      expect(BookingStatus.cancelled.displayName, 'Dibatalkan');
    });
  });

  group('Time Slot Validation', () {
    test('valid time range is accepted', () {
      const startTime = '08:00';
      const endTime = '10:00';
      final [startH, startM] = startTime.split(':').map(int.parse).toList();
      final [endH, endM] = endTime.split(':').map(int.parse).toList();
      final startMinutes = startH * 60 + startM;
      final endMinutes = endH * 60 + endM;
      expect(endMinutes > startMinutes, true);
    });

    test('same start and end time is invalid', () {
      const startTime = '10:00';
      const endTime = '10:00';
      final [startH, startM] = startTime.split(':').map(int.parse).toList();
      final [endH, endM] = endTime.split(':').map(int.parse).toList();
      final startMinutes = startH * 60 + startM;
      final endMinutes = endH * 60 + endM;
      expect(endMinutes > startMinutes, false);
    });

    test('duration calculation is correct', () {
      const startTime = '08:00';
      const endTime = '11:00';
      final [startH, startM] = startTime.split(':').map(int.parse).toList();
      final [endH, endM] = endTime.split(':').map(int.parse).toList();
      final startMinutes = startH * 60 + startM;
      final endMinutes = endH * 60 + endM;
      final durationHours = (endMinutes - startMinutes) ~/ 60;
      expect(durationHours, 3);
    });
  });

  group('Booking ID Format Validation', () {
    test('SJH format is valid', () {
      const bookingId = 'SJH-20260301-0001';
      // Format: SJH-YYYYMMDD-XXXX
      final regex = RegExp(r'^SJH-\d{8}-\d{4}$');
      expect(regex.hasMatch(bookingId), true);
    });

    test('non-SJH format is invalid', () {
      const bookingId = 'BOOK001';
      final regex = RegExp(r'^SJH-\d{8}-\d{4}$');
      expect(regex.hasMatch(bookingId), false);
    });
  });
}
