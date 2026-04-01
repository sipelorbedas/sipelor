/// Supabase implementation of Booking Repository
/// 
/// This implementation uses Supabase as the data source for booking operations.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';
import 'interfaces/i_booking_repository.dart';

/// Supabase implementation of [IBookingRepository]
class SupabaseBookingRepository implements IBookingRepository {
  final SupabaseClient _client;
  
  /// Creates a new [SupabaseBookingRepository]
  /// 
  /// Requires a [SupabaseClient] instance for database operations.
  SupabaseBookingRepository(this._client);
  
  @override
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to get user bookings', e);
    }
  }
  
  @override
  Future<Booking?> getBookingById(String id) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('id', id)
          .maybeSingle();
      
      if (response == null) return null;
      
      return Booking.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to get booking by ID', e);
    }
  }
  
  @override
  Future<Booking> createBooking(Booking booking) async {
    try {
      final response = await _client
          .from('bookings')
          .insert(booking.toJson())
          .select()
          .single();
      
      return Booking.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to create booking', e);
    }
  }
  
  @override
  Future<Booking> updateBooking(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _client
          .from('bookings')
          .update(updates)
          .eq('id', id)
          .select()
          .single();
      
      return Booking.fromJson(response);
    } catch (e) {
      throw RepositoryException('Failed to update booking', e);
    }
  }
  
  @override
  Future<void> cancelBooking(String id) async {
    try {
      await _client
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', id);
    } catch (e) {
      throw RepositoryException('Failed to cancel booking', e);
    }
  }
  
  @override
  Future<void> deleteBooking(String id) async {
    try {
      await _client
          .from('bookings')
          .delete()
          .eq('id', id);
    } catch (e) {
      throw RepositoryException('Failed to delete booking', e);
    }
  }
  
  @override
  Future<List<Booking>> getBookingsByStatus(String userId, String status) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('status', status)
          .order('created_at', ascending: false);
      
      return (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to get bookings by status', e);
    }
  }
  
  @override
  Future<List<Booking>> getBookingsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _client
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .gte('booking_date', startDate.toIso8601String())
          .lte('booking_date', endDate.toIso8601String())
          .order('booking_date', ascending: true);
      
      return (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw RepositoryException('Failed to get bookings by date range', e);
    }
  }
}
