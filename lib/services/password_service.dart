import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/password_validator.dart';
import 'audit_service.dart';
import 'rate_limiter_service.dart';
import 'security_event_notification_service.dart';

/// Service for managing password operations
/// Implements secure password change and reset functionality
class PasswordService {
  static SupabaseClient get _client => Supabase.instance.client;
  static final RateLimiterService _rateLimiter = RateLimiterService();

  /// Change user password with validation and security measures
  /// 
  /// Security features:
  /// - Rate limiting: 3 attempts per hour
  /// - Old password verification
  /// - New password validation
  /// - Audit logging
  /// - Session management (Supabase auto-invalidates other sessions)
  /// 
  /// Returns:
  /// - Success: null
  /// - Error: Error message string
  static Future<String?> changePassword({
    required String oldPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return 'User tidak terautentikasi';
      }

      // Rate limiting check
      final canProceed = await _rateLimiter.checkRateLimit(
        key: 'password_change_${user.id}',
        maxAttempts: 3,
        window: const Duration(hours: 1),
        blockDuration: const Duration(hours: 2),
      );

      if (!canProceed) {
        final blockedDuration = _rateLimiter.getBlockedDuration('password_change_${user.id}');
        if (blockedDuration != null) {
          final minutes = blockedDuration.inMinutes;
          return 'Terlalu banyak percobaan. Coba lagi dalam $minutes menit';
        }
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti';
      }

      // Validate inputs
      if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
        return 'Semua field harus diisi';
      }

      if (newPassword != confirmPassword) {
        return 'Password baru tidak cocok';
      }

      if (oldPassword == newPassword) {
        return 'Password baru harus berbeda dari password lama';
      }

      // Validate new password strength
      final validationError = PasswordValidator.validate(newPassword, isSignUp: true);
      if (validationError != null) {
        return validationError;
      }

      // Verify old password by attempting to sign in
      // This is the recommended way to verify current password
      final email = user.email;
      if (email == null) {
        return 'Email user tidak ditemukan';
      }

      try {
        // Verify old password by signing in
        await _client.auth.signInWithPassword(
          email: email,
          password: oldPassword,
        );
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [PasswordService] Old password verification failed: $e');
        }
        return 'Password lama tidak sesuai';
      }

      // Update password using Supabase auth
      // This automatically invalidates all other sessions except current one
      try {
        await _client.auth.updateUser(
          UserAttributes(password: newPassword),
        );
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [PasswordService] Password update failed: $e');
        }
        return 'Gagal mengubah password. Silakan coba lagi';
      }

      // Log the password change to audit logs
      await AuditService.logAction(
        action: 'password_changed',
        entityType: 'user',
        entityId: user.id,
        changes: {
          'timestamp': DateTime.now().toIso8601String(),
          'user_email': email,
        },
      );

      // Track password change for security notifications
      await SecurityEventNotificationService.trackPasswordChange(
        userId: user.id,
        email: email,
      );

      // Reset rate limiter on success
      _rateLimiter.resetAttempts('password_change_${user.id}');

      if (kDebugMode) {
        if (kDebugMode) print('✅ [PasswordService] Password changed successfully for user: ${user.id}');
      }

      return null; // Success
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [PasswordService] Error changing password: $e');
      }
      return 'Terjadi kesalahan. Silakan coba lagi';
    }
  }

  /// Request password reset via email
  /// 
  /// Security features:
  /// - Rate limiting: 3 requests per hour per email
  /// - No user enumeration (same response whether email exists or not)
  /// - Token expires in 1 hour (configured in Supabase)
  /// - Audit logging of all attempts
  /// 
  /// Returns:
  /// - Success: null
  /// - Error: Error message string
  static Future<String?> requestPasswordReset({
    required String email,
  }) async {
    try {
      // Validate email format
      if (email.isEmpty) {
        return 'Email tidak boleh kosong';
      }

      if (!_isValidEmail(email)) {
        return 'Format email tidak valid';
      }

      // Rate limiting check
      final canProceed = await _rateLimiter.checkRateLimit(
        key: 'password_reset_$email',
        maxAttempts: 3,
        window: const Duration(hours: 1),
        blockDuration: const Duration(hours: 2),
      );

      if (!canProceed) {
        final blockedDuration = _rateLimiter.getBlockedDuration('password_reset_$email');
        if (blockedDuration != null) {
          final minutes = blockedDuration.inMinutes;
          return 'Terlalu banyak percobaan. Coba lagi dalam $minutes menit';
        }
        return 'Terlalu banyak percobaan. Silakan coba lagi nanti';
      }

      // Log the password reset attempt
      // Note: We log this regardless of whether the email exists
      await AuditService.logAction(
        action: 'password_reset_requested',
        entityType: 'user',
        changes: {
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      // Request password reset from Supabase
      // This sends an email with a reset link
      // The token expires in 1 hour (default Supabase setting)
      try {
        await _client.auth.resetPasswordForEmail(
          email,
          redirectTo: _getPasswordResetRedirectUrl(),
        );
      } catch (e) {
        // Don't reveal whether the email exists or not (prevent user enumeration)
        // Log the error but return success message
        if (kDebugMode) {
          if (kDebugMode) print('❌ [PasswordService] Password reset request error: $e');
        }
        // Still return success to prevent user enumeration
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [PasswordService] Password reset requested for: $email');
      }

      // Always return success to prevent user enumeration
      // The user will only receive an email if the account exists
      return null; // Success
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [PasswordService] Error requesting password reset: $e');
      }
      // Even on error, return success message to prevent user enumeration
      return null;
    }
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Get password reset redirect URL
  /// This should point to your app's deep link or web page
  /// that handles the password reset token
  static String _getPasswordResetRedirectUrl() {
    // Use deep link scheme for mobile app
    // This must match the scheme configured in:
    // - android/app/src/main/AndroidManifest.xml
    // - ios/Runner/Info.plist
    // - Supabase Project Settings > Authentication > URL Configuration > Redirect URLs
    
    return 'sipelor://reset-password';
  }

  /// Get remaining password change attempts
  static int getRemainingPasswordChangeAttempts() {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    return _rateLimiter.getRemainingAttempts(
      key: 'password_change_${user.id}',
      maxAttempts: 3,
      window: const Duration(hours: 1),
    );
  }

  /// Get remaining password reset attempts for an email
  static int getRemainingPasswordResetAttempts(String email) {
    return _rateLimiter.getRemainingAttempts(
      key: 'password_reset_$email',
      maxAttempts: 3,
      window: const Duration(hours: 1),
    );
  }

  /// Check if user is blocked from password changes
  static Duration? getPasswordChangeBlockedDuration() {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return _rateLimiter.getBlockedDuration('password_change_${user.id}');
  }

  /// Check if email is blocked from password reset
  static Duration? getPasswordResetBlockedDuration(String email) {
    return _rateLimiter.getBlockedDuration('password_reset_$email');
  }
}
