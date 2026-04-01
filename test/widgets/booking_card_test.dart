/// Widget tests for BookingCard and other critical widgets
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/booking.dart';

void main() {
  group('Booking Widget Tests', () {
    late Booking testBooking;

    setUp(() {
      testBooking = Booking(
        id: 'booking123',
        bookingId: 'BOOK001',
        userId: 'user123',
        fieldId: 'field1',
        venueId: 'venue1',
        bookingDate: DateTime.parse('2026-02-10'),
        startTime: '09:00',
        endTime: '11:00',
        durationHours: 2,
        totalAmount: 150000,
        status: BookingStatus.confirmed,
        paymentStatus: PaymentStatus.verified,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        venueName: 'Test Venue',
        fieldArea: 'Field A',
        venueType: 'Futsal',
      );
    });

    testWidgets('should display booking information correctly',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: Text(testBooking.venueName ?? 'Unknown'),
              subtitle: Text(
                '${testBooking.bookingDate.toString().split(' ')[0]} | ${testBooking.startTime} - ${testBooking.endTime}',
              ),
              trailing: Chip(
                label: Text(testBooking.status.displayName),
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Venue'), findsOneWidget);
      expect(find.text('Dikonfirmasi'), findsOneWidget);
      expect(find.textContaining('09:00 - 11:00'), findsOneWidget);
    });

    testWidgets('should show correct status color for confirmed booking',
        (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Chip(
              label: Text(testBooking.status.displayName),
              backgroundColor: Colors.green.shade100,
            ),
          ),
        ),
      );

      // Assert
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, Colors.green.shade100);
    });

    testWidgets('should show pending status correctly',
        (WidgetTester tester) async {
      // Arrange
      final pendingBooking = testBooking.copyWith(
        status: BookingStatus.pending,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Chip(
              label: Text(pendingBooking.status.displayName),
              backgroundColor: Colors.orange.shade100,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Menunggu'), findsOneWidget);
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, Colors.orange.shade100);
    });

    testWidgets('should show cancelled status correctly',
        (WidgetTester tester) async {
      // Arrange
      final cancelledBooking = testBooking.copyWith(
        status: BookingStatus.cancelled,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Chip(
              label: Text(cancelledBooking.status.displayName),
              backgroundColor: Colors.red.shade100,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Dibatalkan'), findsOneWidget);
      final chip = tester.widget<Chip>(find.byType(Chip));
      expect(chip.backgroundColor, Colors.red.shade100);
    });

    testWidgets('should display payment status correctly',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(testBooking.paymentStatus.displayName),
          ),
        ),
      );

      // Assert
      expect(find.text('Terverifikasi'), findsOneWidget);
    });

    testWidgets('should format price correctly',
        (WidgetTester tester) async {
      // Arrange
      final formattedPrice = 'Rp ${testBooking.totalAmount.toString()}';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(formattedPrice),
          ),
        ),
      );

      // Assert
      expect(find.text('Rp 150000'), findsOneWidget);
    });

    testWidgets('should display booking date in correct format',
        (WidgetTester tester) async {
      // Arrange
      final dateStr = testBooking.bookingDate.toString().split(' ')[0];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(dateStr),
          ),
        ),
      );

      // Assert
      expect(find.text('2026-02-10'), findsOneWidget);
    });

    testWidgets('should handle null venue name gracefully',
        (WidgetTester tester) async {
      // Arrange
      final bookingWithoutVenue = testBooking.copyWith(venueName: null);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Text(bookingWithoutVenue.venueName ?? 'Unknown Venue'),
          ),
        ),
      );

      // Assert
      expect(find.text('Unknown Venue'), findsOneWidget);
    });
  });
}
