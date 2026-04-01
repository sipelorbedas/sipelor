import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for automatically cleaning up old notifications
/// Deletes notifications older than specified hours to save database storage
class NotificationCleanupService {
  static SupabaseClient get _supabase => Supabase.instance.client;
  static Timer? _cleanupTimer;
  static bool _isInitialized = false;

  /// Initialize auto-cleanup for old notifications
  /// 
  /// [hoursOld] - Delete notifications older than this many hours (default: 24)
  /// [checkIntervalHours] - Run cleanup check every X hours (default: 6)
  /// 
  /// Example:
  /// ```dart
  /// // Delete notifications older than 24 hours, check every 6 hours
  /// NotificationCleanupService.initialize(hoursOld: 24, checkIntervalHours: 6);
  /// ```
  static Future<void> initialize({
    int hoursOld = 24,
    int checkIntervalHours = 6,
  }) async {
    if (_isInitialized) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [NotificationCleanup] Already initialized');
      }
      return;
    }

    try {
      if (kDebugMode) {
        if (kDebugMode) print('🧹 [NotificationCleanup] Initializing auto-cleanup service');
        if (kDebugMode) print('🧹 [NotificationCleanup] Will delete notifications older than $hoursOld hours');
        if (kDebugMode) print('🧹 [NotificationCleanup] Check interval: every $checkIntervalHours hours');
      }

      // Run immediate cleanup on initialization
      await _performCleanup(hoursOld);

      // Schedule periodic cleanup
      _cleanupTimer = Timer.periodic(
        Duration(hours: checkIntervalHours),
        (_) => _performCleanup(hoursOld),
      );

      _isInitialized = true;

      if (kDebugMode) {
        if (kDebugMode) print('✅ [NotificationCleanup] Auto-cleanup service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationCleanup] Error initializing service: $e');
      }
    }
  }

  /// Perform cleanup of old notifications
  static Future<void> _performCleanup(int hoursOld) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursOld));
      final cutoffString = cutoffTime.toIso8601String();

      if (kDebugMode) {
        if (kDebugMode) print('🧹 [NotificationCleanup] Starting cleanup...');
        if (kDebugMode) print('🧹 [NotificationCleanup] Cutoff time: $cutoffString');
      }

      // Count notifications to be deleted (for logging)
      final countResponse = await _supabase
          .from('notifications')
          .select('id')
          .lt('created_at', cutoffString);

      final count = (countResponse as List).length;

      if (count == 0) {
        if (kDebugMode) {
          if (kDebugMode) print('✅ [NotificationCleanup] No old notifications to delete');
        }
        return;
      }

      if (kDebugMode) {
        if (kDebugMode) print('🧹 [NotificationCleanup] Found $count notifications to delete');
      }

      // Delete old notifications
      await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', cutoffString);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [NotificationCleanup] Successfully deleted $count old notifications');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationCleanup] Error during cleanup: $e');
      }
    }
  }

  /// Manually trigger cleanup (for testing or manual cleanup)
  /// 
  /// [hoursOld] - Delete notifications older than this many hours
  /// 
  /// Returns the number of notifications deleted
  static Future<int> manualCleanup({int hoursOld = 24}) async {
    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursOld));
      final cutoffString = cutoffTime.toIso8601String();

      if (kDebugMode) {
        if (kDebugMode) print('🧹 [NotificationCleanup] Manual cleanup triggered');
        if (kDebugMode) print('🧹 [NotificationCleanup] Deleting notifications older than $hoursOld hours');
      }

      // Count before deletion
      final countResponse = await _supabase
          .from('notifications')
          .select('id')
          .lt('created_at', cutoffString);

      final count = (countResponse as List).length;

      if (count == 0) {
        if (kDebugMode) {
          if (kDebugMode) print('✅ [NotificationCleanup] No old notifications to delete');
        }
        return 0;
      }

      // Delete
      await _supabase
          .from('notifications')
          .delete()
          .lt('created_at', cutoffString);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [NotificationCleanup] Deleted $count notifications');
      }

      return count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationCleanup] Manual cleanup failed: $e');
      }
      return 0;
    }
  }

  /// Get statistics about notifications in database
  static Future<Map<String, dynamic>> getStatistics() async {
    try {
      // Total notifications
      final totalResponse = await _supabase
          .from('notifications')
          .select('id');
      final total = (totalResponse as List).length;

      // Unread notifications
      final unreadResponse = await _supabase
          .from('notifications')
          .select('id')
          .eq('is_read', false);
      final unread = (unreadResponse as List).length;

      // Notifications from last 24 hours
      final cutoff24h = DateTime.now().subtract(const Duration(hours: 24));
      final recent24hResponse = await _supabase
          .from('notifications')
          .select('id')
          .gte('created_at', cutoff24h.toIso8601String());
      final recent24h = (recent24hResponse as List).length;

      // Notifications older than 24 hours
      final old24h = total - recent24h;

      final stats = {
        'total': total,
        'unread': unread,
        'read': total - unread,
        'recent_24h': recent24h,
        'older_than_24h': old24h,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        if (kDebugMode) print('📊 [NotificationCleanup] Statistics:');
        if (kDebugMode) print('   Total: $total');
        if (kDebugMode) print('   Unread: $unread');
        if (kDebugMode) print('   Read: ${total - unread}');
        if (kDebugMode) print('   Recent (24h): $recent24h');
        if (kDebugMode) print('   Old (>24h): $old24h');
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationCleanup] Error getting statistics: $e');
      }
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Stop the auto-cleanup service
  static void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _isInitialized = false;

    if (kDebugMode) {
      if (kDebugMode) print('🛑 [NotificationCleanup] Service stopped');
    }
  }

  /// Check if service is running
  static bool get isInitialized => _isInitialized;
}
