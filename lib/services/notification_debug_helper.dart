import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Debug helper to test notification system
class NotificationDebugHelper {
  static SupabaseClient get _supabase => Supabase.instance.client;

  /// Check notification service connection status
  static Future<void> checkConnectionStatus() async {
    final user = _supabase.auth.currentUser;
    
    if (kDebugMode) {
      if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (kDebugMode) print('📊 [NotificationDebug] Connection Status');
      if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      if (kDebugMode) print('User logged in: ${user != null}');
      if (user != null) {
        if (kDebugMode) print('User ID: ${user.id}');
        if (kDebugMode) print('User email: ${user.email}');
      }
      if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    }
  }

  /// Test sending a notification directly to database
  static Future<void> sendTestNotification({String? customMessage}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [NotificationDebug] Cannot send test: No user logged in');
        }
        return;
      }

      final testData = {
        'user_id': user.id,
        'type': 'general',
        'title': 'Test Notification 🧪',
        'body': customMessage ?? 
            'This is a test notification sent at ${DateTime.now().toIso8601String()}',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      if (kDebugMode) {
        if (kDebugMode) print('📤 [NotificationDebug] Sending test notification...');
        if (kDebugMode) print('Data: $testData');
      }

      final response = await _supabase
          .from('notifications')
          .insert(testData)
          .select()
          .single();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [NotificationDebug] Test notification sent successfully!');
        if (kDebugMode) print('Response: $response');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationDebug] Error sending test notification: $e');
        if (kDebugMode) print('Stack trace: $stackTrace');
      }
    }
  }

  /// List recent notifications from database
  static Future<void> listRecentNotifications({int limit = 5}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [NotificationDebug] Cannot list: No user logged in');
        }
        return;
      }

      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      if (kDebugMode) {
        if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        if (kDebugMode) print('📋 [NotificationDebug] Recent Notifications ($limit)');
        if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        
        if ((response as List).isEmpty) {
          if (kDebugMode) print('No notifications found');
        } else {
          for (var i = 0; i < (response as List).length; i++) {
            final notif = response[i];
            if (kDebugMode) print('${i + 1}. ${notif['title']}');
            if (kDebugMode) print('   Body: ${notif['body']}');
            if (kDebugMode) print('   Type: ${notif['type']}');
            if (kDebugMode) print('   Read: ${notif['is_read']}');
            if (kDebugMode) print('   Created: ${notif['created_at']}');
            if (kDebugMode) print('   ─────────────────────────────────');
          }
        }
        if (kDebugMode) print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationDebug] Error listing notifications: $e');
      }
    }
  }

  /// Check if notifications table is accessible
  static Future<bool> checkTableAccess() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [NotificationDebug] No user logged in');
        }
        return false;
      }

      final count = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .count();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [NotificationDebug] Table accessible. Count: ${count.count}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationDebug] Table access error: $e');
      }
      return false;
    }
  }

  /// Test realtime subscription
  static Future<void> testRealtimeSubscription() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [NotificationDebug] No user logged in');
      }
      return;
    }

    if (kDebugMode) {
      if (kDebugMode) print('🔌 [NotificationDebug] Creating test realtime subscription...');
    }

    final channel = _supabase
        .channel('notification_test_${DateTime.now().millisecondsSinceEpoch}')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: user.id,
          ),
          callback: (payload) {
            if (kDebugMode) {
              if (kDebugMode) print('🔔 [NotificationDebug] Realtime event received!');
              if (kDebugMode) print('Payload: ${payload.newRecord}');
            }
          },
        )
        .subscribe((status, error) {
          if (kDebugMode) {
            if (kDebugMode) print('📡 [NotificationDebug] Subscription status: $status');
            if (error != null) {
              if (kDebugMode) print('❌ [NotificationDebug] Subscription error: $error');
            }
          }
        });

    if (kDebugMode) {
      if (kDebugMode) {
        print(
        '✅ [NotificationDebug] Test subscription created. Now send a test notification!',
      );
      }
    }

    // Auto cleanup after 30 seconds
    Future.delayed(const Duration(seconds: 30), () async {
      await channel.unsubscribe();
      if (kDebugMode) {
        if (kDebugMode) print('🔌 [NotificationDebug] Test subscription closed');
      }
    });
  }

  /// Full diagnostic check
  static Future<void> runFullDiagnostic() async {
    if (kDebugMode) {
      if (kDebugMode) print('\n');
      if (kDebugMode) print('╔════════════════════════════════════════════════════════════╗');
      if (kDebugMode) print('║         🔍 NOTIFICATION SYSTEM DIAGNOSTIC                 ║');
      if (kDebugMode) print('╚════════════════════════════════════════════════════════════╝');
      if (kDebugMode) print('');
    }

    // 1. Check connection status
    await checkConnectionStatus();
    await Future.delayed(const Duration(milliseconds: 500));

    // 2. Check table access
    if (kDebugMode) print('\n📋 Checking table access...');
    await checkTableAccess();
    await Future.delayed(const Duration(milliseconds: 500));

    // 3. List recent notifications
    if (kDebugMode) print('\n📋 Listing recent notifications...');
    await listRecentNotifications(limit: 3);
    await Future.delayed(const Duration(milliseconds: 500));

    // 4. Test realtime subscription
    if (kDebugMode) print('\n📡 Testing realtime subscription...');
    await testRealtimeSubscription();
    await Future.delayed(const Duration(seconds: 2));

    // 5. Send test notification
    if (kDebugMode) print('\n📤 Sending test notification...');
    await sendTestNotification(
      customMessage: 'Diagnostic test - ${DateTime.now()}',
    );

    if (kDebugMode) {
      if (kDebugMode) print('\n');
      if (kDebugMode) print('╔════════════════════════════════════════════════════════════╗');
      if (kDebugMode) print('║         ✅ DIAGNOSTIC COMPLETE                            ║');
      if (kDebugMode) print('╠════════════════════════════════════════════════════════════╣');
      if (kDebugMode) print('║ If you saw a realtime event above, notifications work!    ║');
      if (kDebugMode) print('║ If not, check:                                            ║');
      if (kDebugMode) print('║ 1. Supabase Realtime is enabled                          ║');
      if (kDebugMode) print('║ 2. RLS policies allow INSERT on notifications table      ║');
      if (kDebugMode) print('║ 3. Push notification service is initialized              ║');
      if (kDebugMode) print('╚════════════════════════════════════════════════════════════╝');
      if (kDebugMode) print('');
    }
  }
}
