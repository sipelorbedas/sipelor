import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/push_notification.dart';
import 'notification_helper.dart';
import 'audit_service.dart';
import 'encrypted_preferences_service.dart';

/// Service for tracking and notifying users about security events
/// 
/// Security events include:
/// - Login from new device/location
/// - Password changes
/// - Email changes
/// - Failed login attempts
/// - Payment confirmations
/// - Booking status changes
class SecurityEventNotificationService {
  static SupabaseClient get _client => Supabase.instance.client;
  static final _encryptedPrefs = EncryptedPreferencesService();

  // Keys for tracking
  static const String _lastLoginDeviceKey = 'last_login_device';
  static const String _knownDevicesKey = 'known_devices';
  static const String _lastLoginLocationKey = 'last_login_location';
  static const String _failedLoginCountKey = 'failed_login_count';
  static const String _failedLoginTimestampKey = 'failed_login_timestamp';

  // Notification preferences keys
  static const String _notifyLoginNewDeviceKey = 'notify_login_new_device';
  static const String _notifyPasswordChangeKey = 'notify_password_change';
  static const String _notifyEmailChangeKey = 'notify_email_change';
  static const String _notifyFailedLoginsKey = 'notify_failed_logins';
  static const String _notifyPaymentKey = 'notify_payment';
  static const String _notifyBookingStatusKey = 'notify_booking_status';

  /// Initialize service with default preferences
  static Future<void> initialize() async {
    try {
      await _encryptedPrefs.initialize();
      
      // Set default preferences if not set
      final hasLoginNotif = await _encryptedPrefs.containsKey(_notifyLoginNewDeviceKey);
      if (!hasLoginNotif) {
        await setNotificationPreference(SecurityEventType.loginNewDevice, true);
        await setNotificationPreference(SecurityEventType.passwordChange, true);
        await setNotificationPreference(SecurityEventType.emailChange, true);
        await setNotificationPreference(SecurityEventType.failedLogins, true);
        await setNotificationPreference(SecurityEventType.payment, true);
        await setNotificationPreference(SecurityEventType.bookingStatus, true);
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SecurityEventNotif] Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error initializing: $e');
      }
    }
  }

  // ==================== Device Tracking ====================

  /// Get current device identifier
  static Future<String> _getCurrentDeviceId() async {
    // Create a device fingerprint based on device info
    // In production, use device_info_plus package for better fingerprinting
    return 'device_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Check if device is known (previously logged in)
  static Future<bool> isKnownDevice() async {
    try {
      final currentDevice = await _getCurrentDeviceId();
      final knownDevices = await _encryptedPrefs.getStringList(_knownDevicesKey) ?? [];
      
      return knownDevices.contains(currentDevice);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error checking known device: $e');
      }
      return false; // Assume unknown on error for security
    }
  }

  /// Register current device as known
  static Future<void> registerDevice() async {
    try {
      final currentDevice = await _getCurrentDeviceId();
      final knownDevices = await _encryptedPrefs.getStringList(_knownDevicesKey) ?? [];
      
      if (!knownDevices.contains(currentDevice)) {
        knownDevices.add(currentDevice);
        await _encryptedPrefs.setStringList(_knownDevicesKey, knownDevices);
        
        if (kDebugMode) {
          if (kDebugMode) print('✅ [SecurityEventNotif] Device registered: $currentDevice');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error registering device: $e');
      }
    }
  }

  /// Clear all known devices (useful for testing or security reset)
  static Future<void> clearKnownDevices() async {
    await _encryptedPrefs.remove(_knownDevicesKey);
  }

  // ==================== Event Tracking ====================

  /// Track login event
  static Future<void> trackLogin({
    required String userId,
    required String email,
  }) async {
    try {
      final isKnown = await isKnownDevice();
      
      if (!isKnown) {
        // New device login
        if (kDebugMode) {
          if (kDebugMode) print('🆕 [SecurityEventNotif] Login from new device detected');
        }
        
        await _sendNotification(
          userId: userId,
          eventType: SecurityEventType.loginNewDevice,
          title: '🔐 Login dari Perangkat Baru',
          message: 'Akun Anda baru saja login dari perangkat baru. Jika bukan Anda, segera ubah password.',
          data: {
            'event_type': 'login_new_device',
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
        
        // Register this device
        await registerDevice();
      }

      // Log to audit
      await AuditService.logAction(
        action: 'login',
        entityType: 'user',
        entityId: userId,
        changes: {
          'email': email,
          'device_new': !isKnown,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking login: $e');
      }
    }
  }

  /// Track password change
  static Future<void> trackPasswordChange({
    required String userId,
    required String email,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🔑 [SecurityEventNotif] Password change detected');
      }

      await _sendNotification(
        userId: userId,
        eventType: SecurityEventType.passwordChange,
        title: '🔐 Password Diubah',
        message: 'Password akun Anda telah diubah. Jika bukan Anda, segera hubungi support.',
        data: {
          'event_type': 'password_change',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Log to audit (already logged by password service, but add security flag)
      await AuditService.logAction(
        action: 'security_event_password_change',
        entityType: 'user',
        entityId: userId,
        changes: {
          'email': email,
          'notification_sent': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking password change: $e');
      }
    }
  }

  /// Track email change
  static Future<void> trackEmailChange({
    required String userId,
    required String oldEmail,
    required String newEmail,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('📧 [SecurityEventNotif] Email change detected');
      }

      await _sendNotification(
        userId: userId,
        eventType: SecurityEventType.emailChange,
        title: '📧 Email Diubah',
        message: 'Email akun Anda telah diubah dari $oldEmail ke $newEmail.',
        data: {
          'event_type': 'email_change',
          'old_email': oldEmail,
          'new_email': newEmail,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      await AuditService.logAction(
        action: 'security_event_email_change',
        entityType: 'user',
        entityId: userId,
        changes: {
          'old_email': oldEmail,
          'new_email': newEmail,
          'notification_sent': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking email change: $e');
      }
    }
  }

  /// Track failed login attempts
  static Future<void> trackFailedLogin({
    required String email,
  }) async {
    try {
      // Get current count
      final count = await _encryptedPrefs.getInt(_failedLoginCountKey) ?? 0;
      final newCount = count + 1;
      
      await _encryptedPrefs.setInt(_failedLoginCountKey, newCount);
      await _encryptedPrefs.setString(
        _failedLoginTimestampKey,
        DateTime.now().toIso8601String(),
      );

      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [SecurityEventNotif] Failed login attempt #$newCount for: $email');
      }

      // Send notification after 5 failed attempts
      if (newCount >= 5) {
        // Try to get user ID from email
        final user = _client.auth.currentUser;
        if (user != null && user.email == email) {
          await _sendNotification(
            userId: user.id,
            eventType: SecurityEventType.failedLogins,
            title: '⚠️  Percobaan Login Gagal',
            message: 'Ada $newCount percobaan login gagal pada akun Anda. Pertimbangkan untuk mengubah password.',
            data: {
              'event_type': 'failed_logins',
              'count': newCount.toString(),
              'timestamp': DateTime.now().toIso8601String(),
            },
          );
        }

        // Reset count after notification
        await _encryptedPrefs.setInt(_failedLoginCountKey, 0);
      }

      // Log to audit
      await AuditService.logAction(
        action: 'failed_login_attempt',
        entityType: 'user',
        changes: {
          'email': email,
          'attempt_count': newCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking failed login: $e');
      }
    }
  }

  /// Reset failed login count (call after successful login)
  static Future<void> resetFailedLoginCount() async {
    try {
      await _encryptedPrefs.setInt(_failedLoginCountKey, 0);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error resetting failed login count: $e');
      }
    }
  }

  /// Track payment confirmation
  static Future<void> trackPayment({
    required String userId,
    required String bookingId,
    required double amount,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('💰 [SecurityEventNotif] Payment confirmed');
      }

      await _sendNotification(
        userId: userId,
        eventType: SecurityEventType.payment,
        title: '💰 Pembayaran Terkonfirmasi',
        message: 'Pembayaran sebesar Rp ${amount.toStringAsFixed(0)} telah dikonfirmasi.',
        data: {
          'event_type': 'payment',
          'booking_id': bookingId,
          'amount': amount.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking payment: $e');
      }
    }
  }

  /// Track booking status change (approved/rejected by admin)
  /// Note: This is already handled by NotificationHelper in supabase_service
  /// This method is for additional security logging
  static Future<void> trackBookingStatusChange({
    required String userId,
    required String bookingId,
    required String newStatus,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('📋 [SecurityEventNotif] Booking status changed: $newStatus');
      }

      // Log to audit for security tracking
      await AuditService.logAction(
        action: 'booking_status_change_notified',
        entityType: 'booking',
        entityId: bookingId,
        changes: {
          'user_id': userId,
          'new_status': newStatus,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error tracking booking status: $e');
      }
    }
  }

  // ==================== Notification Sending ====================

  /// Send security event notification
  static Future<void> _sendNotification({
    required String userId,
    required SecurityEventType eventType,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if user has enabled this notification type
      final isEnabled = await getNotificationPreference(eventType);
      
      if (!isEnabled) {
        if (kDebugMode) {
          if (kDebugMode) print('ℹ️  [SecurityEventNotif] Notification disabled by user: $eventType');
        }
        return;
      }

      // Send push notification via NotificationHelper
      await NotificationHelper.createNotification(
        userId: userId,
        title: title,
        body: message,
        type: NotificationType.general,
        data: data ?? {},
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SecurityEventNotif] Notification sent: $eventType');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error sending notification: $e');
      }
    }
  }

  // ==================== User Preferences ====================

  /// Get notification preference for event type
  static Future<bool> getNotificationPreference(SecurityEventType eventType) async {
    try {
      final key = _getPreferenceKey(eventType);
      return await _encryptedPrefs.getBool(key) ?? true; // Default: enabled
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error getting preference: $e');
      }
      return true; // Default to enabled for security
    }
  }

  /// Set notification preference for event type
  static Future<void> setNotificationPreference(
    SecurityEventType eventType,
    bool enabled,
  ) async {
    try {
      final key = _getPreferenceKey(eventType);
      await _encryptedPrefs.setBool(key, enabled);
      
      if (kDebugMode) {
        if (kDebugMode) print('✅ [SecurityEventNotif] Preference updated: $eventType = $enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SecurityEventNotif] Error setting preference: $e');
      }
    }
  }

  /// Get all notification preferences
  static Future<Map<SecurityEventType, bool>> getAllPreferences() async {
    final Map<SecurityEventType, bool> preferences = {};
    
    for (final type in SecurityEventType.values) {
      preferences[type] = await getNotificationPreference(type);
    }
    
    return preferences;
  }

  /// Get preference key for event type
  static String _getPreferenceKey(SecurityEventType eventType) {
    switch (eventType) {
      case SecurityEventType.loginNewDevice:
        return _notifyLoginNewDeviceKey;
      case SecurityEventType.passwordChange:
        return _notifyPasswordChangeKey;
      case SecurityEventType.emailChange:
        return _notifyEmailChangeKey;
      case SecurityEventType.failedLogins:
        return _notifyFailedLoginsKey;
      case SecurityEventType.payment:
        return _notifyPaymentKey;
      case SecurityEventType.bookingStatus:
        return _notifyBookingStatusKey;
    }
  }

  /// Get event type display name
  static String getEventTypeDisplayName(SecurityEventType eventType) {
    switch (eventType) {
      case SecurityEventType.loginNewDevice:
        return 'Login dari Perangkat Baru';
      case SecurityEventType.passwordChange:
        return 'Perubahan Password';
      case SecurityEventType.emailChange:
        return 'Perubahan Email';
      case SecurityEventType.failedLogins:
        return 'Percobaan Login Gagal';
      case SecurityEventType.payment:
        return 'Konfirmasi Pembayaran';
      case SecurityEventType.bookingStatus:
        return 'Status Booking';
    }
  }

  /// Get event type description
  static String getEventTypeDescription(SecurityEventType eventType) {
    switch (eventType) {
      case SecurityEventType.loginNewDevice:
        return 'Notifikasi saat ada login dari perangkat yang belum dikenal';
      case SecurityEventType.passwordChange:
        return 'Notifikasi saat password akun diubah';
      case SecurityEventType.emailChange:
        return 'Notifikasi saat email akun diubah';
      case SecurityEventType.failedLogins:
        return 'Notifikasi saat ada banyak percobaan login gagal';
      case SecurityEventType.payment:
        return 'Notifikasi saat pembayaran dikonfirmasi';
      case SecurityEventType.bookingStatus:
        return 'Notifikasi saat status booking berubah';
    }
  }
}

/// Security event types
enum SecurityEventType {
  loginNewDevice,
  passwordChange,
  emailChange,
  failedLogins,
  payment,
  bookingStatus,
}
