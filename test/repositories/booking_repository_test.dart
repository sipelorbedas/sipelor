/// Unit tests for Booking Repository
/// 
/// Tests the Supabase implementation of IBookingRepository
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sipelor/repositories/supabase_booking_repository.dart';
import 'package:sipelor/repositories/interfaces/i_booking_repository.dart';
import 'package:sipelor/models/booking.dart';

// Generate mocks
@GenerateMocks([SupabaseClient, SupabaseQueryBuilder])
import 'booking_repository_test.mocks.dart';

void main() {
  group('SupabaseBookingRepository', () {
    late SupabaseBookingRepository repository;
    late MockSupabaseClient mockClient;
    
    setUp(() {
      mockClient = MockSupabaseClient();
      repository = SupabaseBookingRepository(mockClient);
    });
    
    group('getUserBookings', () {
      test('should return list of bookings when successful', () async {
        // Arrange
        final userId = 'user123';
        final mockData = [
          {
            'id': '1',
            'user_id': userId,
            'venue_id': 'venue1',
            'field_id': 'field1',
            'booking_date': '2026-02-10T00:00:00.000Z',
            'start_time': '09:00',
            'end_time': '11:00',
            'total_price': 100000.0,
            'status': 'confirmed',
            'created_at': '2026-02-05T00:00:00.000Z',
          },
        ];
        
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        
        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => mockData);
        
        // Act
        final result = await repository.getUserBookings(userId);
        
        // Assert
        expect(result, isA<List<Booking>>());
        expect(result.length, equals(1));
        expect(result[0].userId, equals(userId));
        
        verify(mockClient.from('bookings')).called(1);
        verify(mockQueryBuilder.eq('user_id', userId)).called(1);
      });
      
      test('should throw RepositoryException on error', () async {
        // Arrange
        final userId = 'user123';
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        
        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.order(any, ascending: anyNamed('ascending')))
            .thenThrow(Exception('Database error'));
        
        // Act & Assert
        expect(
          () => repository.getUserBookings(userId),
          throwsA(isA<RepositoryException>()),
        );
      });
    });
    
    group('getBookingById', () {
      test('should return booking when found', () async {
        // Arrange
        final bookingId = 'booking123';
        final mockData = {
          'id': bookingId,
          'user_id': 'user123',
          'venue_id': 'venue1',
          'field_id': 'field1',
          'booking_date': '2026-02-10T00:00:00.000Z',
          'start_time': '09:00',
          'end_time': '11:00',
          'total_price': 100000.0,
          'status': 'confirmed',
          'created_at': '2026-02-05T00:00:00.000Z',
        };
        
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        
        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.maybeSingle()).thenAnswer((_) async => mockData);
        
        // Act
        final result = await repository.getBookingById(bookingId);
        
        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(bookingId));
      });
      
      test('should return null when booking not found', () async {
        // Arrange
        final bookingId = 'nonexistent';
        final mockQueryBuilder = MockSupabaseQueryBuilder();
        
        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.maybeSingle()).thenAnswer((_) async => null);
        
        // Act
        final result = await repository.getBookingById(bookingId);
        
        // Assert
        expect(result, isNull);
      });
    });
    
    group('createBooking', () {
      test('should create and return new booking', () async {
        // Arrange
        final newBooking = Booking(
          id: '',
          bookingId: 'BOOK002',
          userId: 'user123',
          fieldId: 'field1',
          venueId: 'venue1',
          bookingDate: DateTime.parse('2026-02-10'),
          startTime: '14:00',
          endTime: '16:00',
          durationHours: 2,
          totalAmount: 150000,
          status: BookingStatus.pending,
          paymentStatus: PaymentStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final createdData = {
          'id': 'booking-new-123',
          'booking_id': 'BOOK002',
          'user_id': 'user123',
          'field_id': 'field1',
          'venue_id': 'venue1',
          'booking_date': '2026-02-10',
          'start_time': '14:00',
          'end_time': '16:00',
          'duration_hours': 2,
          'total_amount': 150000,
          'status': 'pending',
          'payment_status': 'pending',
          'created_at': '2026-02-05T10:00:00Z',
          'updated_at': '2026-02-05T10:00:00Z',
        };

        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.insert(any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => createdData);

        // Act
        final result = await repository.createBooking(newBooking);

        // Assert
        expect(result.bookingId, 'BOOK002');
        expect(result.startTime, '14:00');
        verify(mockClient.from('bookings')).called(1);
      });
    });

    group('updateBooking', () {
      test('should update and return booking', () async {
        // Arrange
        final bookingId = 'booking123';
        final updates = {'status': 'confirmed'};
        final updatedData = {
          'id': bookingId,
          'booking_id': 'BOOK001',
          'user_id': 'user123',
          'field_id': 'field1',
          'venue_id': 'venue1',
          'booking_date': '2026-02-10',
          'start_time': '09:00',
          'end_time': '11:00',
          'duration_hours': 2,
          'total_amount': 100000,
          'status': 'confirmed',
          'payment_status': 'pending',
          'created_at': '2026-02-05T10:00:00Z',
          'updated_at': '2026-02-05T10:00:00Z',
        };

        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update(updates)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.single()).thenAnswer((_) async => updatedData);

        // Act
        final result = await repository.updateBooking(bookingId, updates);

        // Assert
        expect(result.status, BookingStatus.confirmed);
        verify(mockClient.from('bookings')).called(1);
      });
    });

    group('cancelBooking', () {
      test('should update booking status to cancelled', () async {
        // Arrange
        final bookingId = 'booking123';
        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.update({'status': 'cancelled'}))
            .thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenAnswer((_) async => null);

        // Act
        await repository.cancelBooking(bookingId);

        // Assert
        verify(mockClient.from('bookings')).called(1);
        verify(mockQueryBuilder.update({'status': 'cancelled'})).called(1);
      });
    });

    group('deleteBooking', () {
      test('should delete booking successfully', () async {
        // Arrange
        final bookingId = 'booking123';
        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.delete()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenAnswer((_) async => null);

        // Act
        await repository.deleteBooking(bookingId);

        // Assert
        verify(mockClient.from('bookings')).called(1);
        verify(mockQueryBuilder.delete()).called(1);
      });
    });

    group('getBookingsByStatus', () {
      test('should return bookings filtered by status', () async {
        // Arrange
        final userId = 'user123';
        final status = 'pending';
        final mockData = [
          {
            'id': '1',
            'booking_id': 'BOOK001',
            'user_id': userId,
            'field_id': 'field1',
            'venue_id': 'venue1',
            'booking_date': '2026-02-10',
            'start_time': '09:00',
            'end_time': '11:00',
            'duration_hours': 2,
            'total_amount': 100000,
            'status': status,
            'payment_status': 'pending',
            'created_at': '2026-02-05T10:00:00Z',
            'updated_at': '2026-02-05T10:00:00Z',
          },
        ];

        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getBookingsByStatus(userId, status);

        // Assert
        expect(result.length, 1);
        expect(result.first.status, BookingStatus.pending);
      });
    });

    group('getBookingsByDateRange', () {
      test('should return bookings within date range', () async {
        // Arrange
        final userId = 'user123';
        final startDate = DateTime.parse('2026-02-01');
        final endDate = DateTime.parse('2026-02-28');
        final mockData = [
          {
            'id': '1',
            'booking_id': 'BOOK001',
            'user_id': userId,
            'field_id': 'field1',
            'venue_id': 'venue1',
            'booking_date': '2026-02-10',
            'start_time': '09:00',
            'end_time': '11:00',
            'duration_hours': 2,
            'total_amount': 100000,
            'status': 'pending',
            'payment_status': 'pending',
            'created_at': '2026-02-05T10:00:00Z',
            'updated_at': '2026-02-05T10:00:00Z',
          },
        ];

        final mockQueryBuilder = MockSupabaseQueryBuilder();

        when(mockClient.from('bookings')).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.select()).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.eq(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.gte(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.lte(any, any)).thenReturn(mockQueryBuilder);
        when(mockQueryBuilder.order(any, ascending: anyNamed('ascending')))
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getBookingsByDateRange(
          userId,
          startDate,
          endDate,
        );

        // Assert
        expect(result.length, 1);
        expect(result.first.bookingDate.year, 2026);
        expect(result.first.bookingDate.month, 2);
      });
    });
  });
}

