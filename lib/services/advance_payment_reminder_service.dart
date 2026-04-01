import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_helper.dart';
import '../models/booking.dart';

class AdvancePaymentReminderService {
  static Timer? _reminderTimer;
  static const Duration _checkInterval = Duration(hours: 6);

  /// Initialize advance payment reminder service.
  static Future<void> initialize() async {
    try {
      if (kDebugMode) {
        print('🚀 [AdvancePaymentReminder] Initializing service...');
      }
      await _sendDueDateReminders();

      _reminderTimer?.cancel();
      _reminderTimer = Timer.periodic(_checkInterval, (_) async {
        await _sendDueDateReminders();
      });

      if (kDebugMode) print('✅ [AdvancePaymentReminder] Service initialized');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvancePaymentReminder] Initialization failed: $e');
      }
    }
  }

  /// Dispose the service timer.
  static void dispose() {
    _reminderTimer?.cancel();
    _reminderTimer = null;
    if (kDebugMode) print('🛑 [AdvancePaymentReminder] Service stopped');
  }

  static Future<void> _sendDueDateReminders() async {
    try {
      final supabase = Supabase.instance.client;
      final today = DateTime.now();
      final h3Date = DateTime(
        today.year,
        today.month,
        today.day,
      ).add(const Duration(days: 3));
      final targetDate = h3Date.toIso8601String().split('T')[0];

      if (kDebugMode) {
        print(
          '🔍 [AdvancePaymentReminder] Checking bookings for H-3 date: $targetDate',
        );
      }

      final response = await supabase
          .from('bookings')
          .select()
          .eq('payment_status', 'pending')
          .eq('has_payment_proof', false)
          .inFilter('status', ['pending', 'confirmed'])
          .eq('booking_date', targetDate);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        print(
          '📊 [AdvancePaymentReminder] Found ${bookings.length} advance bookings for reminder',
        );
      }

      for (final booking in bookings) {
        if (await _hasReminderBeenSent(booking)) {
          if (kDebugMode) {
            print(
              '⏭️ [AdvancePaymentReminder] Reminder already sent for ${booking.bookingId}',
            );
          }
          continue;
        }

        final venueName =
            await _fetchVenueName(booking.fieldId) ??
            booking.venueName ??
            'Lapangan';

        await NotificationHelper.notifyAdvancePaymentReminder(
          userId: booking.userId,
          bookingId: booking.id,
          venueName: venueName,
        );

        if (kDebugMode) {
          print(
            '✅ [AdvancePaymentReminder] Notification sent for ${booking.bookingId}',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AdvancePaymentReminder] Error sending reminders: $e');
      }
    }
  }

  static Future<bool> _hasReminderBeenSent(Booking booking) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_id', booking.userId)
          .eq('type', 'payment_reminder')
          .contains('data', {'booking_id': booking.id})
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print(
          '⚠️ [AdvancePaymentReminder] Unable to check existing reminders: $e',
        );
      }
      return false;
    }
  }

  static Future<String?> _fetchVenueName(String fieldId) async {
    try {
      final supabase = Supabase.instance.client;
      final field = await supabase
          .from('fields')
          .select('venue_name')
          .eq('id', fieldId)
          .maybeSingle();
      if (field == null) return null;
      return field['venue_name'] as String?;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AdvancePaymentReminder] Could not fetch venue name: $e');
      }
      return null;
    }
  }
}
