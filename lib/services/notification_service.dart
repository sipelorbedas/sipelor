import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/booking.dart';

/// Service to track booking notification states (read/unread)
class NotificationService {
  static const String _seenBookingsKey = 'seen_bookings';

  /// Get the list of seen booking states
  /// Returns a map of booking_id -> state_hash
  static Future<Map<String, String>> _getSeenBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final seenJson = prefs.getString(_seenBookingsKey);
      
      if (seenJson == null) {
        return {};
      }
      
      final decoded = json.decode(seenJson) as Map<String, dynamic>;
      return Map<String, String>.from(decoded);
    } catch (e) {
      if (kDebugMode) print('Error getting seen bookings: $e');
      return {};
    }
  }

  /// Save the seen booking states
  static Future<void> _saveSeenBookings(Map<String, String> seenBookings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = json.encode(seenBookings);
      await prefs.setString(_seenBookingsKey, encoded);
    } catch (e) {
      if (kDebugMode) print('Error saving seen bookings: $e');
    }
  }

  /// Generate a state hash for a booking
  /// This includes both booking status and payment status
  static String _generateStateHash(Booking booking) {
    return '${booking.status.value}_${booking.paymentStatus.value}';
  }

  /// Count unread booking notifications
  /// A booking is considered unread if:
  /// 1. Booking status is pending (awaiting confirmation)
  /// 2. Booking status is confirmed (ready to download e-ticket)
  /// 3. Booking status is completed (prompt to review venue)
  /// AND the state has changed since last seen
  static Future<int> getUnreadCount(List<Booking> bookings) async {
    try {
      final seenBookings = await _getSeenBookings();
      int unreadCount = 0;

      if (kDebugMode) print('🔍 [NotificationService] Checking ${bookings.length} bookings');
      if (kDebugMode) print('🔍 [NotificationService] Seen bookings: $seenBookings');

      for (final booking in bookings) {
        // Pending bookings without payment proof always count as unread
        // regardless of "seen" state — user must take action (pay)
        if (booking.status == BookingStatus.pending && !booking.hasPaymentProof) {
          unreadCount++;
          if (kDebugMode) print('   ⚠️ Pending-unpaid always unread: ${booking.bookingId} (total: $unreadCount)');
          continue;
        }

        final currentState = _generateStateHash(booking);
        final lastSeenState = seenBookings[booking.id];

        // Show badge for confirmed or completed if state changed since last seen
        final hasNotification =
            booking.status == BookingStatus.confirmed ||
            booking.status == BookingStatus.completed;

        if (kDebugMode) print('🔍 [NotificationService] Booking ${booking.bookingId}:');
        if (kDebugMode) print('   - Current state: $currentState');
        if (kDebugMode) print('   - Last seen state: $lastSeenState');
        if (kDebugMode) print('   - Has notification: $hasNotification');
        if (kDebugMode) print('   - State changed: ${lastSeenState != currentState}');

        // If there's a notification and the state has changed (or never seen)
        if (hasNotification && lastSeenState != currentState) {
          unreadCount++;
          if (kDebugMode) print('   ✅ Counted as unread (total: $unreadCount)');
        } else {
          if (kDebugMode) print('   ❌ Not counted as unread');
        }
      }

      if (kDebugMode) print('🔔 [NotificationService] Final unread count: $unreadCount');
      return unreadCount;
    } catch (e) {
      if (kDebugMode) print('❌ [NotificationService] Error counting unread notifications: $e');
      return 0;
    }
  }

  /// Mark all current bookings as seen
  /// Pending bookings without payment proof are intentionally NOT marked as seen
  /// so they keep generating a badge until the user pays.
  static Future<void> markAllAsSeen(List<Booking> bookings) async {
    try {
      // Load existing seen state to preserve it for pending-unpaid bookings
      final existing = await _getSeenBookings();
      final seenBookings = Map<String, String>.from(existing);

      for (final booking in bookings) {
        // Skip pending-unpaid: they must always appear as unread
        if (booking.status == BookingStatus.pending && !booking.hasPaymentProof) {
          continue;
        }
        seenBookings[booking.id] = _generateStateHash(booking);
      }

      await _saveSeenBookings(seenBookings);
      if (kDebugMode) print('✅ Marked bookings as seen (skipped pending-unpaid)');
    } catch (e) {
      if (kDebugMode) print('Error marking bookings as seen: $e');
    }
  }

  /// Clear all seen booking data
  /// Useful for testing or when user logs out
  static Future<void> clearSeenBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_seenBookingsKey);
      if (kDebugMode) print('✅ Cleared seen bookings data');
    } catch (e) {
      if (kDebugMode) print('Error clearing seen bookings: $e');
    }
  }

  /// Check if there are any newly confirmed bookings
  /// Returns the count of bookings that just became confirmed
  static Future<int> getNewlyConfirmedCount(List<Booking> bookings) async {
    try {
      final seenBookings = await _getSeenBookings();
      int newlyConfirmedCount = 0;

      for (final booking in bookings) {
        final currentState = _generateStateHash(booking);
        final lastSeenState = seenBookings[booking.id];

        // Check if booking is now confirmed and state has changed
        if (booking.status == BookingStatus.confirmed && 
            lastSeenState != currentState) {
          newlyConfirmedCount++;
        }
      }

      return newlyConfirmedCount;
    } catch (e) {
      if (kDebugMode) print('Error counting newly confirmed bookings: $e');
      return 0;
    }
  }
}
