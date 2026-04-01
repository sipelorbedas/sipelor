/// Riverpod providers for booking-related functionality
/// 
/// This file contains all providers for booking services and repositories
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/interfaces/i_booking_repository.dart';
import '../repositories/supabase_booking_repository.dart';
import '../models/booking.dart';

// ==================== Clients ====================

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// ==================== Repositories ====================

/// Booking repository provider
final bookingRepositoryProvider = Provider<IBookingRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseBookingRepository(client);
});

// ==================== State Providers ====================

/// Provider for fetching user bookings
final userBookingsProvider = FutureProvider.family<List<Booking>, String>(
  (ref, userId) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getUserBookings(userId);
  },
);

/// Provider for fetching a single booking by ID
final bookingByIdProvider = FutureProvider.family<Booking?, String>(
  (ref, bookingId) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getBookingById(bookingId);
  },
);

/// Provider for bookings by status
final bookingsByStatusProvider = FutureProvider.family<List<Booking>, ({String userId, String status})>(
  (ref, params) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getBookingsByStatus(params.userId, params.status);
  },
);

/// Provider for bookings by date range
final bookingsByDateRangeProvider = FutureProvider.family<List<Booking>, ({String userId, DateTime start, DateTime end})>(
  (ref, params) async {
    final repository = ref.watch(bookingRepositoryProvider);
    return repository.getBookingsByDateRange(params.userId, params.start, params.end);
  },
);

// ==================== Notifier Providers ====================

/// State notifier for managing booking operations
class BookingNotifier extends StateNotifier<AsyncValue<List<Booking>>> {
  final IBookingRepository _repository;
  final String _userId;

  BookingNotifier(this._repository, this._userId) : super(const AsyncValue.loading()) {
    loadBookings();
  }

  /// Load all bookings for the user
  Future<void> loadBookings() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getUserBookings(_userId));
  }

  /// Create a new booking
  Future<Booking> createBooking(Booking booking) async {
    final newBooking = await _repository.createBooking(booking);
    await loadBookings(); // Refresh list
    return newBooking;
  }

  /// Update a booking
  Future<Booking> updateBooking(String id, Map<String, dynamic> updates) async {
    final updatedBooking = await _repository.updateBooking(id, updates);
    await loadBookings(); // Refresh list
    return updatedBooking;
  }

  /// Cancel a booking
  Future<void> cancelBooking(String id) async {
    await _repository.cancelBooking(id);
    await loadBookings(); // Refresh list
  }

  /// Delete a booking
  Future<void> deleteBooking(String id) async {
    await _repository.deleteBooking(id);
    await loadBookings(); // Refresh list
  }
}

/// Provider for booking notifier
final bookingNotifierProvider = StateNotifierProvider.family<BookingNotifier, AsyncValue<List<Booking>>, String>(
  (ref, userId) {
    final repository = ref.watch(bookingRepositoryProvider);
    return BookingNotifier(repository, userId);
  },
);
