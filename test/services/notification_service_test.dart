import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/services/notification_service.dart';
import 'package:sipelor/models/booking.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationService', () {
    setUp(() async {
      // Clear shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('getUnreadCount returns 0 for empty booking list', () async {
      final unreadCount = await NotificationService.getUnreadCount([]);
      expect(unreadCount, equals(0));
    });

    test('getUnreadCount returns correct count for pending bookings', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'booking-2',
          venueId: 'venue-1',
          fieldId: 'field-2',
          userId: 'user-1',
          bookingId: 'BOOK002',
          venueName: 'Test Venue',
          fieldName: 'Field 2',
          date: DateTime.now(),
          startTime: '13:00',
          endTime: '15:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(2));
    });

    test('getUnreadCount returns correct count for confirmed bookings', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.confirmed,
          paymentStatus: PaymentStatus.paid,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(1));
    });

    test('getUnreadCount returns correct count for completed bookings', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.completed,
          paymentStatus: PaymentStatus.paid,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(1));
    });

    test('getUnreadCount returns 0 for cancelled bookings', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.cancelled,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(0));
    });

    test('getUnreadCount returns 0 for rejected bookings', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.rejected,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(0));
    });

    test('markAllAsSeen should mark bookings as seen', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      // Initially unread
      int unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(1));

      // Mark as seen
      await NotificationService.markAllAsSeen(bookings);

      // Should now be 0
      unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(0));
    });

    test('markAsSeen should mark specific booking as seen', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
        Booking(
          id: 'booking-2',
          venueId: 'venue-1',
          fieldId: 'field-2',
          userId: 'user-1',
          bookingId: 'BOOK002',
          venueName: 'Test Venue',
          fieldName: 'Field 2',
          date: DateTime.now(),
          startTime: '13:00',
          endTime: '15:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      // Initially 2 unread
      int unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(2));

      // Mark one as seen
      await NotificationService.markAsSeen(bookings[0]);

      // Should now be 1
      unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(1));
    });

    test('notification count updates when booking status changes', () async {
      final booking = Booking(
        id: 'booking-1',
        venueId: 'venue-1',
        fieldId: 'field-1',
        userId: 'user-1',
        bookingId: 'BOOK001',
        venueName: 'Test Venue',
        fieldName: 'Field 1',
        date: DateTime.now(),
        startTime: '09:00',
        endTime: '11:00',
        status: BookingStatus.pending,
        paymentStatus: PaymentStatus.pending,
        totalPrice: 150000,
        createdAt: DateTime.now(),
      );

      // Initially unread
      int unreadCount = await NotificationService.getUnreadCount([booking]);
      expect(unreadCount, equals(1));

      // Mark as seen
      await NotificationService.markAsSeen(booking);
      unreadCount = await NotificationService.getUnreadCount([booking]);
      expect(unreadCount, equals(0));

      // Change status to confirmed (should be unread again)
      final updatedBooking = Booking(
        id: booking.id,
        venueId: booking.venueId,
        fieldId: booking.fieldId,
        userId: booking.userId,
        bookingId: booking.bookingId,
        venueName: booking.venueName,
        fieldName: booking.fieldName,
        date: booking.date,
        startTime: booking.startTime,
        endTime: booking.endTime,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.paid,
        totalPrice: booking.totalPrice,
        createdAt: booking.createdAt,
      );

      unreadCount = await NotificationService.getUnreadCount([updatedBooking]);
      expect(unreadCount, equals(1));
    });

    test('clearAll should reset all notification states', () async {
      final bookings = [
        Booking(
          id: 'booking-1',
          venueId: 'venue-1',
          fieldId: 'field-1',
          userId: 'user-1',
          bookingId: 'BOOK001',
          venueName: 'Test Venue',
          fieldName: 'Field 1',
          date: DateTime.now(),
          startTime: '09:00',
          endTime: '11:00',
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          totalPrice: 150000,
          createdAt: DateTime.now(),
        ),
      ];

      // Mark as seen
      await NotificationService.markAllAsSeen(bookings);

      // Clear all
      await NotificationService.clearAll();

      // Should be unread again
      final unreadCount = await NotificationService.getUnreadCount(bookings);
      expect(unreadCount, equals(1));
    });
  });
}
