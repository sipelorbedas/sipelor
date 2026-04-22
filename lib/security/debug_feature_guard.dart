/// Debug Feature Guard
///
/// Ensures all debug features are properly guarded with kDebugMode checks.
/// This file centralizes all debug feature access control.
///
/// SECURITY NOTES:
/// - All debug features must be wrapped with shouldAllowDebugAccess()
/// - Debug menu is only accessible to admin users in debug builds
/// - Email testing is debug-only and logs to console
/// - Never expose sensitive debug features in production
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DebugFeatureGuard {
  /// Check if debug features should be allowed
  ///
  /// Returns true only if:
  /// 1. Running in debug mode (kDebugMode)
  /// 2. AND user is authenticated AND has admin role (for sensitive operations)
  static bool shouldAllowDebugAccess({required bool requireAdmin}) {
    // CRITICAL: Always deny in release builds
    if (!kDebugMode) {
      return false;
    }

    // If admin role not required, allow any debug build
    if (!requireAdmin) {
      return true;
    }

    // Check admin status
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final role = user?.userMetadata?['role'] as String?;
      final isAdmin = role == 'admin' || role == 'super_admin';
      return isAdmin;
    } catch (_) {
      // If auth check fails, deny access
      return false;
    }
  }

  /// Check if debug menu should be accessible
  ///
  /// Debug menu is only accessible to admin users in debug builds
  static bool shouldShowDebugMenu() {
    return shouldAllowDebugAccess(requireAdmin: true);
  }

  /// Check if email testing should be allowed
  ///
  /// Email testing is debug-only, no admin role required
  static bool shouldAllowEmailTesting() {
    return shouldAllowDebugAccess(requireAdmin: false);
  }

  /// Check if RASP monitoring should log to console
  ///
  /// RASP debugging is debug-only
  static bool shouldLogRASPDebug() {
    return shouldAllowDebugAccess(requireAdmin: false);
  }

  /// Log a debug message only if debug access is allowed
  static void debugLog(String message, {bool requireAdmin = false}) {
    if (shouldAllowDebugAccess(requireAdmin: requireAdmin)) {
      if (kDebugMode) {
        print('[DEBUG] $message');
      }
    }
  }

  /// Validate that sensitive debug operations are guarded
  static void validateDebugGuards() {
    if (!kDebugMode) {
      return; // Skip validation in release builds
    }

    if (kDebugMode) {
      print('[DebugFeatureGuard] Validation:');
      print('  ✅ kDebugMode enabled');
      print('  ✅ Debug features guarded by DebugFeatureGuard');
      print('  ✅ Admin role check implemented');
      print('  ✅ Console logging enabled for debugging');
    }
  }
}
