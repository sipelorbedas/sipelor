import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/push_notification.dart';

/// Helper service for creating notifications
/// This is typically called from backend/Edge Functions but can also be used
/// from the Flutter app for testing or admin functions
class NotificationHelper {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Create a notification for a specific user
  static Future<void> createNotification({
    required String userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Declare insertData outside try-catch so it's accessible in catch block
    Map<String, dynamic>? insertData;

    try {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '📝 [NotificationHelper] Creating notification for user: $userId',
          );
        }
        if (kDebugMode) print('📝 [NotificationHelper] Type: $type');
        if (kDebugMode) print('📝 [NotificationHelper] Title: $title');
        if (kDebugMode) print('📝 [NotificationHelper] Body: $body');
      }

      insertData = {
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        if (kDebugMode) {
          print('📝 [NotificationHelper] Insert data: $insertData');
        }
      }

      // Insert without select to avoid RLS policy issues
      // We don't need the response, just need to trigger the insert
      await _supabase.from('notifications').insert(insertData);

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ [NotificationHelper] Notification created successfully');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [NotificationHelper] Error creating notification: $e');
        }
        if (kDebugMode) {
          print('❌ [NotificationHelper] Error type: ${e.runtimeType}');
        }

        // Try to extract PostgrestException details
        if (e.toString().contains('PostgrestException')) {
          if (kDebugMode) {
            print('❌ [NotificationHelper] This is a Postgrest/Database error');
          }
          if (kDebugMode) {
            print('❌ [NotificationHelper] Full error details: $e');
          }
        }

        // Check for specific error patterns
        if (e.toString().contains('permission denied')) {
          if (kDebugMode) {
            print('❌ [NotificationHelper] RLS POLICY ERROR: Permission denied');
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] SOLUTION: Run FIX_NOTIFICATION_RLS_POLICY_V2.sql in Supabase',
            );
          }
        } else if (e.toString().contains(
          'violates row-level security policy',
        )) {
          if (kDebugMode) {
            print(
              '❌ [NotificationHelper] RLS POLICY ERROR: Row-level security violation',
            );
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] SOLUTION: RLS policy WITH CHECK condition failed',
            );
          }
        } else if (e.toString().contains('violates check constraint') &&
            e.toString().contains('type_check')) {
          if (kDebugMode) {
            print(
              '❌ [NotificationHelper] CONSTRAINT ERROR: Notification type not allowed',
            );
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] SOLUTION: Run FIX_NOTIFICATION_TYPE_CONSTRAINT.sql in Supabase',
            );
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] This adds missing notification types to database constraint',
            );
          }
        } else if (e.toString().contains('column') &&
            e.toString().contains('does not exist')) {
          if (kDebugMode) {
            print('❌ [NotificationHelper] SCHEMA ERROR: Column mismatch');
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] SOLUTION: Check notifications table schema',
            );
          }
        } else if (e.toString().contains('null value')) {
          if (kDebugMode) {
            print(
              '❌ [NotificationHelper] DATA ERROR: NULL constraint violation',
            );
          }
          if (kDebugMode) {
            print(
              '💡 [NotificationHelper] SOLUTION: Check required fields in table',
            );
          }
        }

        if (kDebugMode) {
          print('❌ [NotificationHelper] Stack trace: $stackTrace');
        }
        if (insertData != null) {
          if (kDebugMode) {
            print('❌ [NotificationHelper] Insert data was: $insertData');
          }
        }
      }
      // Don't rethrow - notification failure shouldn't block the main operation
      // The error is already logged for debugging
    }
  }

  /// Create booking confirmed notification (status changed to confirmed)
  static Future<void> notifyBookingConfirmed({
    required String userId,
    required String bookingId,
    String? venueName,
  }) async {
    // Fetch venue name if not provided
    String displayVenueName = venueName ?? 'Training Soccer';
    if (venueName == null || venueName == 'venue') {
      try {
        // Fetch booking to get venue name
        final booking = await _supabase
            .from('bookings')
            .select('field_id')
            .eq('id', bookingId)
            .single();

        final fieldId = booking['field_id'] as String;
        final field = await _supabase
            .from('fields')
            .select('venue_name')
            .eq('id', fieldId)
            .single();

        displayVenueName = field['venue_name'] as String;
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('⚠️ [NotificationHelper] Could not fetch venue name: $e');
          }
        }
        // Use default if fetch fails
      }
    }

    await createNotification(
      userId: userId,
      type: NotificationType.bookingApproved,
      title: 'Booking Disetujui! ✅',
      body:
          'Booking Anda untuk $displayVenueName telah disetujui. \nTap untuk download E-Tiket.',
      data: {'booking_id': bookingId, 'action': 'view_booking'},
    );
  }

  /// Create booking completed notification (status changed to completed)
  static Future<void> notifyBookingCompleted({
    required String userId,
    required String bookingId,
    String? venueName,
  }) async {
    // Fetch venue name if not provided
    String displayVenueName = venueName ?? 'Training Soccer';
    if (venueName == null || venueName == 'venue') {
      try {
        // Fetch booking to get venue name
        final booking = await _supabase
            .from('bookings')
            .select('field_id')
            .eq('id', bookingId)
            .single();

        final fieldId = booking['field_id'] as String;
        final field = await _supabase
            .from('fields')
            .select('venue_name')
            .eq('id', fieldId)
            .single();

        displayVenueName = field['venue_name'] as String;
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('⚠️ [NotificationHelper] Could not fetch venue name: $e');
          }
        }
        // Use default if fetch fails
      }
    }

    await createNotification(
      userId: userId,
      type: NotificationType.bookingCompleted,
      title: 'Booking Selesai ✅',
      body:
          'Bagaimana pengalaman Anda? Yuk beri review untuk $displayVenueName!',
      data: {'booking_id': bookingId, 'action': 'write_review'},
    );
  }

  /// Create booking approved notification (legacy - for admin approval)
  static Future<void> notifyBookingApproved({
    required String userId,
    required String bookingId,
    required String venueName,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingApproved,
      title: 'Booking Disetujui! ✅',
      body:
          'Booking Anda untuk $venueName telah disetujui. \nSilakan lakukan pembayaran.',
      data: {'booking_id': bookingId, 'action': 'view_booking'},
    );
  }

  /// Create booking rejected notification
  static Future<void> notifyBookingRejected({
    required String userId,
    required String bookingId,
    required String venueName,
    String? reason,
  }) async {
    final reasonText = reason != null ? ' Alasan: $reason' : '';
    await createNotification(
      userId: userId,
      type: NotificationType.bookingRejected,
      title: 'Booking Ditolak ❌',
      body: 'Booking Anda untuk $venueName ditolak.$reasonText',
      data: {
        'booking_id': bookingId,
        'action': 'view_booking',
        'reason': reason,
      },
    );
  }

  /// Create payment reminder notification
  static Future<void> notifyPaymentReminder({
    required String userId,
    required String bookingId,
    required String venueName,
    required int minutesLeft,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentReminder,
      title: 'Segera Bayar! ⏰',
      body:
          'Booking $venueName akan expired dalam $minutesLeft menit. \nSegera lakukan pembayaran!',
      data: {
        'booking_id': bookingId,
        'action': 'pay_booking',
        'minutes_left': minutesLeft,
      },
    );
  }

  /// Create advance payment reminder notification for H-3 bookings.
  static Future<void> notifyAdvancePaymentReminder({
    required String userId,
    required String bookingId,
    required String venueName,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.paymentReminder,
      title: 'Pembayaran H-3 Dibuka ⏰',
      body:
          'Booking $venueName akan memasuki H-3. Segera lakukan pembayaran hari ini agar status booking tetap terjaga.',
      data: {
        'booking_id': bookingId,
        'action': 'pay_booking',
        'reminder_type': 'h3',
      },
    );
  }

  /// Create promo notification
  static Future<void> notifyPromoAvailable({
    required String userId,
    required String promoTitle,
    required String promoDescription,
    String? promoCode,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.promoAvailable,
      title: 'Promo Baru! 🎉',
      body: '$promoTitle - $promoDescription',
      data: {'promo_code': promoCode, 'action': 'view_promo'},
    );
  }

  /// Broadcast promo to all users
  static Future<void> broadcastPromo({
    required String promoTitle,
    required String promoDescription,
    String? promoCode,
  }) async {
    try {
      // Fetch all user IDs
      final response = await _supabase.from('profiles').select('id');
      final userIds = (response as List)
          .map((user) => user['id'] as String)
          .toList();

      // Create notification for each user
      for (final userId in userIds) {
        await notifyPromoAvailable(
          userId: userId,
          promoTitle: promoTitle,
          promoDescription: promoDescription,
          promoCode: promoCode,
        );
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ [NotificationHelper] Promo broadcasted to ${userIds.length} users',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [NotificationHelper] Error broadcasting promo: $e');
        }
      }
      rethrow;
    }
  }

  /// Create review reminder notification
  static Future<void> notifyReviewReminder({
    required String userId,
    required String bookingId,
    required String venueName,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.reviewReminder,
      title: 'Bagaimana Pengalaman Anda? ⭐',
      body: 'Berikan review untuk booking $venueName Anda',
      data: {'booking_id': bookingId, 'action': 'write_review'},
    );
  }

  /// Create maintenance schedule notification
  static Future<void> notifyMaintenanceSchedule({
    required String userId,
    required String venueName,
    required DateTime maintenanceDate,
    String? description,
  }) async {
    final dateStr =
        '${maintenanceDate.day}/${maintenanceDate.month}/${maintenanceDate.year}';
    await createNotification(
      userId: userId,
      type: NotificationType.maintenanceSchedule,
      title: 'Jadwal Maintenance 🔧',
      body: '$venueName akan maintenance pada $dateStr. ${description ?? ""}',
      data: {
        'venue_name': venueName,
        'maintenance_date': maintenanceDate.toIso8601String(),
        'action': 'view_venue',
      },
    );
  }

  /// Create booking expired notification
  static Future<void> notifyBookingExpired({
    required String userId,
    required String bookingId,
    required String venueName,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.bookingExpired,
      title: 'Booking Expired ⌛',
      body: 'Booking Anda untuk $venueName telah expired karena belum dibayar.',
      data: {'booking_id': bookingId, 'action': 'view_booking'},
    );
  }

  /// Create payment verified notification
  static Future<void> notifyPaymentVerified({
    required String userId,
    required String bookingId,
    String? venueName,
  }) async {
    // Fetch venue name if not provided
    String displayVenueName = venueName ?? 'Training Soccer';
    if (venueName == null) {
      try {
        // Fetch booking to get venue name
        final booking = await _supabase
            .from('bookings')
            .select('field_id')
            .eq('id', bookingId)
            .single();

        final fieldId = booking['field_id'] as String;
        final field = await _supabase
            .from('fields')
            .select('venue_name')
            .eq('id', fieldId)
            .single();

        displayVenueName = field['venue_name'] as String;
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('⚠️ [NotificationHelper] Could not fetch venue name: $e');
          }
        }
        // Use default if fetch fails
      }
    }

    await createNotification(
      userId: userId,
      type: NotificationType.paymentVerified,
      title: 'Pembayaran Terverifikasi! ✅',
      body:
          'Pembayaran Anda untuk booking $displayVenueName telah terverifikasi. \nTap untuk download E-Tiket.',
      data: {'booking_id': bookingId, 'action': 'view_booking'},
    );
  }

  /// Create payment rejected notification
  static Future<void> notifyPaymentRejected({
    required String userId,
    required String bookingId,
    String? venueName,
  }) async {
    // Fetch venue name if not provided
    String displayVenueName = venueName ?? 'Training Soccer';
    if (venueName == null) {
      try {
        // Fetch booking to get venue name
        final booking = await _supabase
            .from('bookings')
            .select('field_id')
            .eq('id', bookingId)
            .single();

        final fieldId = booking['field_id'] as String;
        final field = await _supabase
            .from('fields')
            .select('venue_name')
            .eq('id', fieldId)
            .single();

        displayVenueName = field['venue_name'] as String;
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) {
            print('⚠️ [NotificationHelper] Could not fetch venue name: $e');
          }
        }
        // Use default if fetch fails
      }
    }

    await createNotification(
      userId: userId,
      type: NotificationType.bookingRejected,
      title: 'Pembayaran Ditolak ❌',
      body:
          'Pembayaran Anda untuk booking $displayVenueName ditolak. \nSilakan upload bukti pembayaran yang valid.',
      data: {'booking_id': bookingId, 'action': 'view_booking'},
    );
  }

  /// Create general notification
  static Future<void> notifyGeneral({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await createNotification(
      userId: userId,
      type: NotificationType.general,
      title: title,
      body: body,
      data: data,
    );
  }

  /// Broadcast general notification to all users
  static Future<void> broadcastGeneral({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Fetch all user IDs
      final response = await _supabase.from('profiles').select('id');
      final userIds = (response as List)
          .map((user) => user['id'] as String)
          .toList();

      // Create notification for each user
      for (final userId in userIds) {
        await notifyGeneral(
          userId: userId,
          title: title,
          body: body,
          data: data,
        );
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ [NotificationHelper] Notification broadcasted to ${userIds.length} users',
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) {
          print('❌ [NotificationHelper] Error broadcasting notification: $e');
        }
      }
      rethrow;
    }
  }
}
