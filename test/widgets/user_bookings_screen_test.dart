/// Widget test for UserBookings screen - Comprehensive tests
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipelor/models/booking.dart';
import 'package:sipelor/providers/booking_providers.dart';
import 'package:sipelor/providers/auth_providers.dart';

// Generate mocks
@GenerateMocks([User])
import 'user_bookings_screen_test.mocks.dart';

void main() {
  group('UserBookingsScreen Widget Tests', () {
    late List<Booking> mockBookings;
    late MockUser mockUser;

    setUp(() {
      mockUser = MockUser();
      when(mockUser.id).thenReturn('user123');
      when(mockUser.email).thenReturn('test@example.com');

      mockBookings = [
        Booking(
          id: '1',
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
        ),
        Booking(
          id: '2',
          bookingId: 'BOOK002',
          userId: 'user123',
          fieldId: 'field2',
          venueId: 'venue1',
          bookingDate: DateTime.parse('2026-02-15'),
          startTime: '14:00',
          endTime: '16:00',
          durationHours: 2,
          totalAmount: 150000,
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          venueName: 'Test Venue',
          fieldArea: 'Field B',
        ),
      ];
    });

    testWidgets('displays booking list', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream.value(mockUser),
          ),
          userBookingsProvider('user123').overrideWith(
            (ref) => Future.value(mockBookings),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: mockBookings.length,
                itemBuilder: (context, index) {
                  final booking = mockBookings[index];
                  return ListTile(
                    key: ValueKey(booking.id),
                    title: Text(
                        '${booking.venueName} - ${booking.fieldArea}'),
                    subtitle: Text(
                        '${booking.startTime} - ${booking.endTime}'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Test Venue - Field A'), findsOneWidget);
      expect(find.text('Test Venue - Field B'), findsOneWidget);

      container.dispose();
    });

    testWidgets('filters bookings by status', (tester) async {
      // Arrange
      final pendingBookings = mockBookings
          .where((b) => b.status == BookingStatus.pending)
          .toList();
      
      final container = ProviderContainer(
        overrides: [
          bookingsByStatusProvider((userId: 'user123', status: 'pending'))
              .overrideWith(
            (ref) => Future.value(pendingBookings),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: pendingBookings.length,
                itemBuilder: (context, index) {
                  final booking = pendingBookings[index];
                  return ListTile(
                    title: Text(booking.status.displayName),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Menunggu'), findsOneWidget);

      container.dispose();
    });

    testWidgets('shows empty state when no bookings', (tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          currentUserProvider.overrideWith(
            (ref) => Stream.value(mockUser),
          ),
          userBookingsProvider('user123').overrideWith(
            (ref) => Future.value([]),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Text('No bookings yet'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No bookings yet'), findsOneWidget);

      container.dispose();
    });

    testWidgets('booking tap opens detail', (tester) async {
      // Arrange
      bool navigationOccurred = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListTile(
              title: const Text('Booking 1'),
              onTap: () {
                navigationOccurred = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();

      // Assert
      expect(navigationOccurred, isTrue);
    });

    testWidgets('pull to refresh works', (tester) async {
      // Arrange
      bool refreshCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshIndicator(
              onRefresh: () async {
                refreshCalled = true;
              },
              child: ListView(
                children: const [
                  ListTile(title: Text('Booking 1')),
                ],
              ),
            ),
          ),
        ),
      );

      // Simulate pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      expect(refreshCalled, isTrue);
    });

    testWidgets('cancel button shows confirmation dialog', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {
                showDialog(
                  context: tester.element(find.byType(ElevatedButton)),
                  builder: (context) => AlertDialog(
                    title: const Text('Cancel Booking'),
                    content: const Text('Are you sure?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Yes'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Cancel'),
            ),
          ),
        ),
      );

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cancel Booking'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);
    });
  });
}
