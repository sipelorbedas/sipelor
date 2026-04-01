import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_helper.dart';

/// Service for bulk operations on bookings, fields, etc.
class BulkOperationsService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Bulk update booking status
  static Future<int> bulkUpdateBookingStatus({
    required List<String> bookingIds,
    required String newStatus,
  }) async {
    try {
      int successCount = 0;

      for (final bookingId in bookingIds) {
        try {
          await _client
              .from('bookings')
              .update({
                'status': newStatus,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bookingId);

          successCount++;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to update booking $bookingId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ Bulk updated $successCount/${bookingIds.length} bookings to status: $newStatus',
          );
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk update booking status: $e');
      }
      rethrow;
    }
  }

  /// Bulk delete bookings
  static Future<int> bulkDeleteBookings(List<String> bookingIds) async {
    try {
      int successCount = 0;

      for (final bookingId in bookingIds) {
        try {
          await _client.from('bookings').delete().eq('id', bookingId);
          successCount++;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to delete booking $bookingId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ Bulk deleted $successCount/${bookingIds.length} bookings');
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk delete bookings: $e');
      }
      rethrow;
    }
  }

  /// Bulk update field status
  static Future<int> bulkUpdateFieldStatus({
    required List<String> fieldIds,
    required String newStatus,
  }) async {
    try {
      int successCount = 0;

      for (final fieldId in fieldIds) {
        try {
          await _client
              .from('fields')
              .update({
                'status': newStatus,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', fieldId);

          successCount++;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to update field $fieldId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ Bulk updated $successCount/${fieldIds.length} fields to status: $newStatus',
          );
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk update field status: $e');
      }
      rethrow;
    }
  }

  /// Bulk update field prices
  static Future<int> bulkUpdateFieldPrices({
    required List<String> fieldIds,
    required int newPrice,
  }) async {
    try {
      int successCount = 0;

      for (final fieldId in fieldIds) {
        try {
          await _client
              .from('fields')
              .update({
                'price_per_hour': newPrice,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', fieldId);

          successCount++;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) {
              print('❌ Failed to update field price $fieldId: $e');
            }
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
            '✅ Bulk updated $successCount/${fieldIds.length} field prices to: $newPrice',
          );
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk update field prices: $e');
      }
      rethrow;
    }
  }

  /// Bulk approve bookings (update status and payment status)
  static Future<int> bulkApproveBookings(List<String> bookingIds) async {
    try {
      int successCount = 0;

      for (final bookingId in bookingIds) {
        try {
          final bookingData = await _client
              .from('bookings')
              .select('user_id, field_id')
              .eq('id', bookingId)
              .single();

          final userId = bookingData['user_id'] as String;
          final fieldId = bookingData['field_id'] as String;

          await _client
              .from('bookings')
              .update({
                'status': 'confirmed',
                'payment_status': 'verified',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bookingId);

          successCount++;

          try {
            final fieldResponse = await _client
                .from('fields')
                .select('venue_name')
                .eq('id', fieldId)
                .single();
            final venueName = fieldResponse['venue_name'] as String? ?? 'Venue';

            await NotificationHelper.notifyPaymentVerified(
              userId: userId,
              bookingId: bookingId,
              venueName: venueName,
            );
            await NotificationHelper.notifyBookingConfirmed(
              userId: userId,
              bookingId: bookingId,
              venueName: venueName,
            );
          } catch (notifyError) {
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                  '⚠️ [BulkApproveBookings] Notification error: $notifyError',
                );
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to approve booking $bookingId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ Bulk approved $successCount/${bookingIds.length} bookings');
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk approve bookings: $e');
      }
      rethrow;
    }
  }

  /// Bulk reject bookings
  static Future<int> bulkRejectBookings(
    List<String> bookingIds, {
    String? reason,
  }) async {
    try {
      int successCount = 0;

      for (final bookingId in bookingIds) {
        try {
          await _client
              .from('bookings')
              .update({
                'status': 'cancelled',
                'notes': reason ?? 'Ditolak oleh admin',
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', bookingId);

          successCount++;

          // TODO: Send notification to user about rejection
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to reject booking $bookingId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ Bulk rejected $successCount/${bookingIds.length} bookings');
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk reject bookings: $e');
      }
      rethrow;
    }
  }

  /// Bulk delete fields
  static Future<int> bulkDeleteFields(List<String> fieldIds) async {
    try {
      int successCount = 0;

      for (final fieldId in fieldIds) {
        try {
          // Check if field has active bookings
          final bookings = await _client
              .from('bookings')
              .select('id')
              .eq('field_id', fieldId)
              .inFilter('status', ['pending', 'confirmed']);

          if ((bookings as List).isEmpty) {
            await _client.from('fields').delete().eq('id', fieldId);
            successCount++;
          } else {
            if (kDebugMode) {
              if (kDebugMode) {
                print('⚠️  Cannot delete field $fieldId: has active bookings');
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ Failed to delete field $fieldId: $e');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ Bulk deleted $successCount/${fieldIds.length} fields');
        }
      }

      return successCount;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk delete fields: $e');
      }
      rethrow;
    }
  }

  /// Bulk export data to CSV
  static Future<String> bulkExportToCSV({
    required String table,
    required List<String> ids,
  }) async {
    try {
      final response = await _client.from(table).select().inFilter('id', ids);

      final data = response as List;

      if (data.isEmpty) {
        return 'No data to export';
      }

      // Generate CSV content
      final keys = (data.first as Map<String, dynamic>).keys.toList();
      String csv = '${keys.join(',')}\n';

      for (final row in data) {
        final values = keys.map((key) {
          final value = (row as Map<String, dynamic>)[key]?.toString() ?? '';
          // Escape commas and quotes in values
          return value.contains(',') || value.contains('"')
              ? '"${value.replaceAll('"', '""')}"'
              : value;
        });
        csv += '${values.join(',')}\n';
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print('✅ Bulk exported ${data.length} records from $table');
        }
      }

      return csv;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error in bulk export: $e');
      }
      rethrow;
    }
  }
}
