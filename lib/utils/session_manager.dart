import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/build_config.dart';

/// Session manager — helper statik untuk cek expiry sesi.
/// FIX: Timeout disinkronkan dengan BuildConfig.autoLogoutMinutes (15 menit)
/// agar konsisten dengan AutoLogoutService. Sebelumnya hardcode 30 menit.
class SessionManager {
  /// FIX: Ambil timeout dari BuildConfig agar satu sumber kebenaran
  static Duration get defaultTimeout =>
      Duration(minutes: BuildConfig.autoLogoutMinutes);

  static DateTime? _lastActivity;
  static Duration? _customTimeout;

  /// Timeout aktif — custom jika di-set, fallback ke BuildConfig
  static Duration get _timeout => _customTimeout ?? defaultTimeout;

  /// Update last activity timestamp
  static void updateActivity() {
    _lastActivity = DateTime.now();
  }

  /// Check if session has expired
  static bool isSessionExpired() {
    if (_lastActivity == null) return false;
    return DateTime.now().difference(_lastActivity!) > _timeout;
  }

  /// Set custom timeout duration (opsional — override BuildConfig)
  static void setTimeout(Duration duration) {
    _customTimeout = duration;
  }

  /// Get time until session expires
  static Duration? getTimeUntilExpiry() {
    if (_lastActivity == null) return null;
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _timeout - elapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Reset session timer
  static void reset() {
    _lastActivity = null;
    _customTimeout = null;
  }

  /// Auto-logout if session expired
  static Future<void> checkAndHandleTimeout() async {
    if (isSessionExpired()) {
      if (kDebugMode) {
        print('⚠️  Session expired, logging out...');
      }
      await Supabase.instance.client.auth.signOut();
      reset();
    }
  }

  /// Initialize session on login
  static void initialize() {
    updateActivity();
  }
}
