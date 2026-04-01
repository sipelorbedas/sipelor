/// Booking Repository Interface
/// 
/// Defines the contract for booking data operations.
/// This interface can be implemented by different data sources
/// (Supabase, REST API, Local DB, etc.)
library;

import '../../models/booking.dart';

/// Repository interface for booking operations
abstract class IBookingRepository {
  /// Get all bookings for a specific user
  /// 
  /// Returns a list of [Booking] objects ordered by creation date.
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Booking>> getUserBookings(String userId);
  
  /// Get a single booking by ID
  /// 
  /// Returns null if booking not found.
  /// Throws [RepositoryException] if the operation fails.
  Future<Booking?> getBookingById(String id);
  
  /// Create a new booking
  /// 
  /// Returns the created [Booking] with generated ID and timestamps.
  /// Throws [RepositoryException] if creation fails.
  Future<Booking> createBooking(Booking booking);
  
  /// Update an existing booking
  /// 
  /// Returns the updated [Booking].
  /// Throws [RepositoryException] if update fails.
  Future<Booking> updateBooking(String id, Map<String, dynamic> updates);
  
  /// Cancel a booking
  /// 
  /// Updates the booking status to cancelled.
  /// Throws [RepositoryException] if cancellation fails.
  Future<void> cancelBooking(String id);
  
  /// Delete a booking
  /// 
  /// Permanently removes the booking from the database.
  /// Throws [RepositoryException] if deletion fails.
  Future<void> deleteBooking(String id);
  
  /// Get bookings by status
  /// 
  /// Returns all bookings matching the given status.
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Booking>> getBookingsByStatus(String userId, String status);
  
  /// Get bookings by date range
  /// 
  /// Returns bookings within the specified date range.
  /// Throws [RepositoryException] if the operation fails.
  Future<List<Booking>> getBookingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  );
}

/// Exception thrown when repository operations fail
class RepositoryException implements Exception {
  final String message;
  final dynamic originalError;
  
  RepositoryException(this.message, [this.originalError]);
  
  @override
  String toString() {
    if (originalError != null) {
      return 'RepositoryException: $message (Caused by: $originalError)';
    }
    return 'RepositoryException: $message';
  }
}
