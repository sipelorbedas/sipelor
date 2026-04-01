import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'rate_limiter_service.dart';

/// Server-side rate limiting via Supabase Edge Function.
///
/// Falls back to in-memory [RateLimiterService] if Edge Function is unavailable.
///
/// Required: Deploy `supabase/functions/rate-limit/index.ts`
/// Required DB table: `rate_limit_log` (see Edge Function for schema)
class ServerRateLimiterService {
  static final ServerRateLimiterService _instance =
      ServerRateLimiterService._internal();
  factory ServerRateLimiterService() => _instance;
  ServerRateLimiterService._internal();

  final _rateLimiter = RateLimiterService();

  static const _fnName = 'rate-limit';

  /// Check if action is allowed. Returns true if allowed, false if rate-limited.
  /// Uses server-side Edge Function with in-memory fallback.
  Future<bool> checkRateLimit({
    required String action,
    required String key,
  }) async {
    try {
      // FIX: Add 5-second timeout so app doesn't hang if Edge Function is
      // not deployed or the network is unreachable. Falls back to local limiter.
      final response = await Supabase.instance.client.functions
          .invoke(_fnName, body: {'action': action, 'key': key})
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) {
                if (kDebugMode) print('⏱️ [ServerRateLimit] Edge Function timed out after 5s, using local fallback');
              }
              throw Exception('timeout');
            },
          );

      if (response.status != 200) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ [ServerRateLimit] Non-200 status: ${response.status}, falling back');
        }
        return _localFallback(action, key);
      }

      final data = response.data as Map<String, dynamic>;
      final allowed = data['allowed'] as bool? ?? true;

      if (!allowed && kDebugMode) {
        final remaining = data['remaining'] ?? 0;
        final blockedUntil = data['blockedUntil'];
        if (kDebugMode) print('🚫 [ServerRateLimit] Blocked: $action/$key remaining=$remaining blockedUntil=$blockedUntil');
      }

      return allowed;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [ServerRateLimit] Edge Function unavailable ($e), using local fallback');
      }
        return _localFallback(action, key);
    }
  }

  /// Local fallback
  Future<bool> _localFallback(String action, String key) async {
    switch (action) {
      case 'login':
        return _rateLimiter.checkLoginRateLimit(key);
      case 'password_reset':
        return _rateLimiter.checkPasswordResetRateLimit(key);
      case 'password_change':
        return _rateLimiter.checkRateLimit(
          key: 'password_change_$key',
          maxAttempts: 3,
          window: const Duration(hours: 1),
          blockDuration: const Duration(hours: 2),
        );
      case 'booking_create':
        return _rateLimiter.checkBookingRateLimit(key);
      default:
        return true; // unknown action — fail open
    }
  }

  /// Convenience: login rate limit
  Future<bool> checkLogin(String identifier) =>
      checkRateLimit(action: 'login', key: identifier);

  /// Convenience: password reset rate limit
  Future<bool> checkPasswordReset(String email) =>
      checkRateLimit(action: 'password_reset', key: email);

  /// Convenience: password change rate limit
  Future<bool> checkPasswordChange(String userId) =>
      checkRateLimit(action: 'password_change', key: userId);

  /// Convenience: booking creation rate limit
  Future<bool> checkBookingCreate(String userId) =>
      checkRateLimit(action: 'booking_create', key: userId);
}
