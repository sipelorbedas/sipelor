import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/booking.dart';

/// Service to handle automatic cancellation of expired bookings
class BookingExpirationService {
  static Timer? _expirationCheckTimer;
  static const Duration _paymentTimeout = Duration(minutes: 30);
  static const Duration _checkInterval = Duration(minutes: 1);

  /// Initialize the expiration service
  /// This should be called when the app starts
  static Future<void> initialize() async {
    try {
      if (kDebugMode) print('🚀 [BookingExpiration] Initializing service...');

      // Run initial check
      await _checkAndCancelExpiredBookings();

      // Setup periodic check every minute
      _expirationCheckTimer?.cancel();
      _expirationCheckTimer = Timer.periodic(_checkInterval, (timer) {
        _checkAndCancelExpiredBookings();
      });

      if (kDebugMode) print('✅ [BookingExpiration] Service initialized');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [BookingExpiration] Error initializing service: $e');
      }
    }
  }

  /// Stop the expiration service
  static void dispose() {
    _expirationCheckTimer?.cancel();
    _expirationCheckTimer = null;
    if (kDebugMode) print('🛑 [BookingExpiration] Service stopped');
  }

  /// Check and cancel expired bookings
  static Future<void> _checkAndCancelExpiredBookings() async {
    try {
      if (kDebugMode) {
        if (kDebugMode) {
          print('🔍 [BookingExpiration] Checking for expired bookings...');
        }
      }

      final supabase = Supabase.instance.client;
      final now = DateTime.now();

      // Fetch all pending bookings (status = pending, payment_status = pending)
      final response = await supabase
          .from('bookings')
          .select()
          .eq('status', 'pending')
          .eq('payment_status', 'pending');

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '📊 [BookingExpiration] Found ${bookings.length} pending bookings',
          );
        }
      }

      int expiredCount = 0;

      // Check each booking for expiration
      for (final booking in bookings) {
        // Convert UTC createdAt to local time to avoid timezone issues
        final localCreatedAt = booking.createdAt.toLocal();
        final expirationTime = localCreatedAt.add(_paymentTimeout);
        final isExpired = now.isAfter(expirationTime);

        if (isExpired) {
          // Cancel the expired booking
          await _cancelBooking(booking);
          expiredCount++;

          if (kDebugMode) {
            final minutesExpired = now.difference(expirationTime).inMinutes;
            if (kDebugMode) {
              print(
                '⏰ [BookingExpiration] Cancelled expired booking: ${booking.bookingId} (expired $minutesExpired minutes ago)',
              );
            }
          }
        }
      }

      if (expiredCount > 0) {
        if (kDebugMode) {
          print(
            '✅ [BookingExpiration] Cancelled $expiredCount expired booking(s)',
          );
        }
      } else if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [BookingExpiration] No expired bookings found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [BookingExpiration] Error checking expired bookings: $e');
      }
    }
  }

  /// Cancel or delete a booking and release the slot
  static Future<void> _cancelBooking(Booking booking) async {
    try {
      final supabase = Supabase.instance.client;

      // Check if booking has payment proof
      final paymentProof = await supabase
          .from('payment_proofs')
          .select('id')
          .eq('booking_id', booking.id)
          .maybeSingle();

      // If no payment proof, DELETE the booking entirely
      if (paymentProof == null) {
        await supabase.from('bookings').delete().eq('id', booking.id);

        if (kDebugMode) {
          print(
            '🗑️  [BookingExpiration] Incomplete booking ${booking.bookingId} DELETED (no payment proof)',
          );
        }
      } else {
        // If payment proof exists, just mark as cancelled
        await supabase
            .from('bookings')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
              'notes': booking.notes != null
                  ? '${booking.notes}\n[AUTO-CANCELLED: Payment timeout after 30 minutes]'
                  : '[AUTO-CANCELLED: Payment timeout after 30 minutes]',
            })
            .eq('id', booking.id);

        if (kDebugMode) {
          print(
            '✅ [BookingExpiration] Booking ${booking.bookingId} cancelled (has payment proof)',
          );
        }
      }

      if (kDebugMode) {
        print(
          '✅ [BookingExpiration] Slot released for booking ${booking.bookingId}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          '❌ [BookingExpiration] Error processing booking ${booking.bookingId}: $e',
        );
      }
    }
  }

  /// Calculate payment deadline for a booking
  /// Note: createdAt should already be converted to local time by the caller
  static DateTime calculatePaymentDeadline(DateTime createdAt) {
    return createdAt.add(_paymentTimeout);
  }

  /// Calculate the H-3 payment due date for an advance booking
  /// This is the date when payment should be made for bookings scheduled
  /// more than 3 days in the future.
  static DateTime calculateAdvancePaymentDueDate(DateTime bookingDate) {
    final localBookingDate = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );
    return localBookingDate.subtract(const Duration(days: 3));
  }

  /// Calculate remaining time from now until the end of the H-3 payment day.
  static Duration getAdvancePaymentRemainingTime(DateTime bookingDate) {
    final dueDate = calculateAdvancePaymentDueDate(bookingDate);
    final dueEndOfDay = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      23,
      59,
      59,
    );
    final remaining = dueEndOfDay.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get number of full days until the booking date.
  static int getDaysUntilBooking(DateTime bookingDate) {
    final today = DateTime.now();
    final localToday = DateTime(today.year, today.month, today.day);
    final localBookingDate = DateTime(
      bookingDate.year,
      bookingDate.month,
      bookingDate.day,
    );
    return localBookingDate.difference(localToday).inDays;
  }

  /// Check if a booking is expired
  static bool isBookingExpired(Booking booking) {
    final now = DateTime.now();
    // Convert UTC createdAt to local time to avoid timezone issues
    final localCreatedAt = booking.createdAt.toLocal();
    final expirationTime = localCreatedAt.add(_paymentTimeout);
    return now.isAfter(expirationTime);
  }

  /// Get remaining time for payment
  /// Note: createdAt should already be converted to local time by the caller
  static Duration getRemainingTime(DateTime createdAt) {
    final now = DateTime.now();
    final deadline = calculatePaymentDeadline(createdAt);
    final remaining = deadline.difference(now);

    // Return zero duration if already expired
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Format remaining time as MM:SS
  static String formatRemainingTime(Duration duration) {
    if (duration.isNegative || duration == Duration.zero) {
      return '00:00';
    }

    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Manually trigger expiration check (useful for testing)
  static Future<void> triggerExpirationCheck() async {
    if (kDebugMode) {
      print('🔄 [BookingExpiration] Manual expiration check triggered');
    }
    await _checkAndCancelExpiredBookings();
  }
}
