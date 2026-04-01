import 'dart:async';
import 'package:flutter/foundation.dart';

// ignore_for_file: avoid_print

/// Service to implement rate limiting to prevent brute force attacks
/// and API abuse
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  factory RateLimiterService() => _instance;
  RateLimiterService._internal();

  // Store attempts per key (e.g., username, IP, action)
  final Map<String, List<DateTime>> _attempts = {};

  // Store blocked keys with expiration time
  final Map<String, DateTime> _blockedUntil = {};

  // FIX: Timer untuk cleanup periodik agar _attempts tidak leak tak terbatas
  Timer? _cleanupTimer;

  /// Mulai periodic cleanup (panggil sekali di konstruktor / setelah DI init).
  /// Secara otomatis membersihkan entry expired setiap 5 menit.
  void startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) => _cleanupExpired());
  }

  /// Bersihkan semua entry yang sudah expired dari _attempts dan _blockedUntil.
  void _cleanupExpired() {
    final now = DateTime.now();

    // Hapus block entries yang sudah expired
    _blockedUntil.removeWhere((_, expiry) => now.isAfter(expiry));

    // Hapus attempts entries yang seluruh timestamps-nya sudah lama (> 2 jam)
    _attempts.removeWhere((_, times) {
      times.removeWhere((t) => now.difference(t) > const Duration(hours: 2));
      return times.isEmpty;
    });

    if (kDebugMode) {
      print('🧹 [RateLimiter] Cleanup: ${_attempts.length} keys, ${_blockedUntil.length} blocks remaining');
    }
  }

  /// Dispose — batalkan cleanup timer.
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }

  /// Check if action is allowed within rate limit
  /// Returns true if allowed, false if rate limited
  Future<bool> checkRateLimit({
    required String key,
    required int maxAttempts,
    required Duration window,
    Duration? blockDuration,
  }) async {
    try {
      final now = DateTime.now();

      // Check if key is currently blocked
      if (_blockedUntil.containsKey(key)) {
        final blockedUntil = _blockedUntil[key]!;
        if (now.isBefore(blockedUntil)) {
          final remaining = blockedUntil.difference(now);
          if (kDebugMode) {
            if (kDebugMode) print('🚫 Rate limit: $key is blocked for ${remaining.inSeconds}s');
          }
          return false;
        } else {
          // Block expired, remove it
          _blockedUntil.remove(key);
          _attempts.remove(key);
        }
      }

      // Get attempts for this key
      final attempts = _attempts[key] ?? [];

      // Remove attempts outside the time window
      attempts.removeWhere((time) => now.difference(time) > window);

      // Check if exceeded max attempts
      if (attempts.length >= maxAttempts) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️ Rate limit exceeded for: $key');
        }

        // Block the key if blockDuration is specified
        if (blockDuration != null) {
          _blockedUntil[key] = now.add(blockDuration);
          if (kDebugMode) {
            if (kDebugMode) print('🚫 Blocked $key for ${blockDuration.inMinutes} minutes');
          }
        }

        return false; // Rate limited
      }

      // Add current attempt
      attempts.add(now);
      _attempts[key] = attempts;

      if (kDebugMode) {
        if (kDebugMode) print('✅ Rate limit check passed: $key (${attempts.length}/$maxAttempts)');
      }

      return true; // Allowed
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error checking rate limit: $e');
      }
      // On error, allow the action (fail open)
      return true;
    }
  }

  /// Get remaining attempts before rate limit
  int getRemainingAttempts({
    required String key,
    required int maxAttempts,
    required Duration window,
  }) {
    try {
      final now = DateTime.now();

      // If blocked, return 0
      if (_blockedUntil.containsKey(key)) {
        final blockedUntil = _blockedUntil[key]!;
        if (now.isBefore(blockedUntil)) {
          return 0;
        }
      }

      final attempts = _attempts[key] ?? [];
      attempts.removeWhere((time) => now.difference(time) > window);

      final remaining = maxAttempts - attempts.length;
      return remaining > 0 ? remaining : 0;
    } catch (e) {
      return maxAttempts;
    }
  }

  /// Get time until unblocked
  Duration? getBlockedDuration(String key) {
    try {
      if (_blockedUntil.containsKey(key)) {
        final blockedUntil = _blockedUntil[key]!;
        final now = DateTime.now();
        if (now.isBefore(blockedUntil)) {
          return blockedUntil.difference(now);
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Reset attempts for a key (e.g., after successful authentication)
  void resetAttempts(String key) {
    _attempts.remove(key);
    _blockedUntil.remove(key);
    if (kDebugMode) {
      if (kDebugMode) print('🔄 Reset rate limit for: $key');
    }
  }

  /// Clear all rate limit data
  void clearAll() {
    _attempts.clear();
    _blockedUntil.clear();
    if (kDebugMode) {
      if (kDebugMode) print('🧹 Cleared all rate limit data');
    }
  }

  /// Check login rate limit (convenience method)
  /// FIX: maxAttempts diperbaiki dari 5 → 3 sesuai kebijakan keamanan (docs: 3 attempts = 1 jam lockout)
  Future<bool> checkLoginRateLimit(String username) async {
    return checkRateLimit(
      key: 'login_$username',
      maxAttempts: 3,
      window: const Duration(minutes: 15),
      blockDuration: const Duration(hours: 1),
    );
  }

  /// Check password reset rate limit (convenience method)
  Future<bool> checkPasswordResetRateLimit(String email) async {
    return checkRateLimit(
      key: 'password_reset_$email',
      maxAttempts: 3,
      window: const Duration(hours: 1),
      blockDuration: const Duration(hours: 2),
    );
  }

  /// Check booking creation rate limit (convenience method)
  Future<bool> checkBookingRateLimit(String userId) async {
    return checkRateLimit(
      key: 'booking_$userId',
      maxAttempts: 10,
      window: const Duration(hours: 1),
    );
  }

  /// Check API call rate limit (convenience method)
  Future<bool> checkApiRateLimit(String endpoint, String userId) async {
    return checkRateLimit(
      key: 'api_${endpoint}_$userId',
      maxAttempts: 60,
      window: const Duration(minutes: 1),
    );
  }
}
