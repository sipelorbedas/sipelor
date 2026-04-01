/// Unit tests for Booking Providers
/// Tests all Riverpod providers for booking functionality
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:sipelor/models/booking.dart';
import 'package:sipelor/repositories/interfaces/i_booking_repository.dart';
import 'package:sipelor/providers/booking_providers.dart';

// Generate mocks
@GenerateMocks([IBookingRepository])
import 'booking_providers_test.mocks.dart';

void main() {
  group('Booking Providers', () {
    late MockIBookingRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockIBookingRepository();
      
      container = ProviderContainer(
        overrides: [
          bookingRepositoryProvider.overrideWithValue(mockRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('userBookingsProvider', () {
      test('should return list of bookings for user', () async {
        // Arrange
        final userId = 'user123';
        final mockBookings = [
          Booking(
            id: '1',
            bookingId: 'BOOK001',
            userId: userId,
            fieldId: 'field1',
            venueId: 'venue1',
            bookingDate: DateTime.parse('2026-02-10'),
            startTime: '09:00',
            endTime: '11:00',
            durationHours: 2,
            totalAmount: 100000,
            status: BookingStatus.confirmed,
            paymentStatus: PaymentStatus.verified,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getUserBookings(userId))
            .thenAnswer((_) async => mockBookings);

        // Act
        final result = await container.read(userBookingsProvider(userId).future);

        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, 1);
        expect(result.first.userId, userId);
        verify(mockRepository.getUserBookings(userId)).called(1);
      });

      test('should handle errors gracefully', () async {
        // Arrange
        final userId = 'user123';
        when(mockRepository.getUserBookings(userId))
            .thenThrow(Exception('Failed to fetch bookings'));

        // Act
        final asyncValue = container.read(userBookingsProvider(userId));

        // Assert
        await expectLater(
          asyncValue.future,
          throwsException,
        );
      });

      test('should return empty list when no bookings', () async {
        // Arrange
        final userId = 'user123';
        when(mockRepository.getUserBookings(userId))
            .thenAnswer((_) async => []);

        // Act
        final result = await container.read(userBookingsProvider(userId).future);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('bookingByIdProvider', () {
      test('should return booking when found', () async {
        // Arrange
        final bookingId = 'booking123';
        final mockBooking = Booking(
          id: bookingId,
          bookingId: 'BOOK001',
          userId: 'user123',
          fieldId: 'field1',
          venueId: 'venue1',
          bookingDate: DateTime.parse('2026-02-10'),
          startTime: '09:00',
          endTime: '11:00',
          durationHours: 2,
          totalAmount: 100000,
          status: BookingStatus.confirmed,
          paymentStatus: PaymentStatus.verified,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockRepository.getBookingById(bookingId))
            .thenAnswer((_) async => mockBooking);

        // Act
        final result = await container.read(bookingByIdProvider(bookingId).future);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, bookingId);
      });

      test('should return null when booking not found', () async {
        // Arrange
        final bookingId = 'nonexistent';
        when(mockRepository.getBookingById(bookingId))
            .thenAnswer((_) async => null);

        // Act
        final result = await container.read(bookingByIdProvider(bookingId).future);

        // Assert
        expect(result, isNull);
      });
    });

    group('bookingsByStatusProvider', () {
      test('should return bookings filtered by status', () async {
        // Arrange
        final userId = 'user123';
        final status = 'pending';
        final params = (userId: userId, status: status);
        
        final mockBookings = [
          Booking(
            id: '1',
            bookingId: 'BOOK001',
            userId: userId,
            fieldId: 'field1',
            venueId: 'venue1',
            bookingDate: DateTime.parse('2026-02-10'),
            startTime: '09:00',
            endTime: '11:00',
            durationHours: 2,
            totalAmount: 100000,
            status: BookingStatus.pending,
            paymentStatus: PaymentStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getBookingsByStatus(userId, status))
            .thenAnswer((_) async => mockBookings);

        // Act
        final result = await container.read(
          bookingsByStatusProvider(params).future,
        );

        // Assert
        expect(result.length, 1);
        expect(result.first.status, BookingStatus.pending);
      });
    });

    group('bookingsByDateRangeProvider', () {
      test('should return bookings within date range', () async {
        // Arrange
        final userId = 'user123';
        final startDate = DateTime.parse('2026-02-01');
        final endDate = DateTime.parse('2026-02-28');
        final params = (userId: userId, start: startDate, end: endDate);

        final mockBookings = [
          Booking(
            id: '1',
            bookingId: 'BOOK001',
            userId: userId,
            fieldId: 'field1',
            venueId: 'venue1',
            bookingDate: DateTime.parse('2026-02-10'),
            startTime: '09:00',
            endTime: '11:00',
            durationHours: 2,
            totalAmount: 100000,
            status: BookingStatus.pending,
            paymentStatus: PaymentStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getBookingsByDateRange(userId, startDate, endDate))
            .thenAnswer((_) async => mockBookings);

        // Act
        final result = await container.read(
          bookingsByDateRangeProvider(params).future,
        );

        // Assert
        expect(result.length, 1);
        expect(result.first.bookingDate.isAfter(startDate), isTrue);
        expect(result.first.bookingDate.isBefore(endDate), isTrue);
      });
    });

    group('BookingNotifier', () {
      test('should load bookings on initialization', () async {
        // Arrange
        final userId = 'user123';
        final mockBookings = [
          Booking(
            id: '1',
            bookingId: 'BOOK001',
            userId: userId,
            fieldId: 'field1',
            venueId: 'venue1',
            bookingDate: DateTime.parse('2026-02-10'),
            startTime: '09:00',
            endTime: '11:00',
            durationHours: 2,
            totalAmount: 100000,
            status: BookingStatus.confirmed,
            paymentStatus: PaymentStatus.verified,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockRepository.getUserBookings(userId))
            .thenAnswer((_) async => mockBookings);

        // Act
        final notifier = container.read(bookingNotifierProvider(userId).notifier);
        final state = await container.read(bookingNotifierProvider(userId).future);

        // Assert
        expect(state, isA<List<Booking>>());
        expect(state.length, 1);
      });

      test('should create booking and refresh list', () async {
        // Arrange
        final userId = 'user123';
        final newBooking = Booking(
          id: '',
          bookingId: 'BOOK002',
          userId: userId,
          fieldId: 'field1',
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
        );

        final createdBooking = newBooking.copyWith(id: 'booking-new-123');

        when(mockRepository.createBooking(any))
            .thenAnswer((_) async => createdBooking);
        when(mockRepository.getUserBookings(userId))
            .thenAnswer((_) async => [createdBooking]);

        // Act
        final notifier = container.read(bookingNotifierProvider(userId).notifier);
        final result = await notifier.createBooking(newBooking);

        // Assert
        expect(result.id, 'booking-new-123');
        verify(mockRepository.createBooking(any)).called(1);
        verify(mockRepository.getUserBookings(userId)).called(greaterThan(0));
      });

      test('should cancel booking and refresh list', () async {
        // Arrange
        final userId = 'user123';
        final bookingId = 'booking123';

        when(mockRepository.cancelBooking(bookingId))
            .thenAnswer((_) async => null);
        when(mockRepository.getUserBookings(userId))
            .thenAnswer((_) async => []);

        // Act
        final notifier = container.read(bookingNotifierProvider(userId).notifier);
        await notifier.cancelBooking(bookingId);

        // Assert
        verify(mockRepository.cancelBooking(bookingId)).called(1);
        verify(mockRepository.getUserBookings(userId)).called(greaterThan(0));
      });
    });
  });
}
