/// Data Integrity Verifier — SIPELOR BEDAS
/// 
/// Provides HMAC-based integrity verification for sensitive data payloads
/// (booking records, payment data, user profiles) to detect unauthorized
/// server-side or man-in-the-middle modification.
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Verification result for a data payload.
class IntegrityResult {
  final bool isValid;
  final String? error;

  const IntegrityResult.valid() : isValid = true, error = null;
  const IntegrityResult.invalid(this.error) : isValid = false;
}

/// Verifies and signs data integrity using HMAC-SHA256.
class DataIntegrityVerifier {
  static const _storage = FlutterSecureStorage();
  static const _signingKeyStorageKey = 'data_integrity_signing_key';
  static const _defaultAlgorithm = 'HMAC-SHA256';

  // ─── Key Management ───────────────────────────────────────────────────────

  /// Initialize or retrieve the per-device signing key.
  static Future<String> _getSigningKey() async {
    try {
      final existing = await _storage.read(key: _signingKeyStorageKey);
      if (existing != null && existing.isNotEmpty) return existing;

      // Generate a new random key (256-bit)
      final key = _generateRandomKey();
      await _storage.write(key: _signingKeyStorageKey, value: key);
      return key;
    } catch (e) {
      if (kDebugMode) print('⚠️  [DataIntegrity] Key retrieval error: $e');
      // Fall back to a deterministic key based on a constant
      return sha256.convert(utf8.encode('sipelor-bedas-fallback-key-2026')).toString();
    }
  }

  static String _generateRandomKey() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final hash = sha256.convert(utf8.encode('sipelor-$now-${now * 31}'));
    return hash.toString();
  }

  // ─── Signing ──────────────────────────────────────────────────────────────

  /// Sign a map payload. Returns the HMAC signature string.
  static Future<String> signPayload(Map<String, dynamic> payload) async {
    try {
      final key = await _getSigningKey();
      final normalized = _normalizePayload(payload);
      return _hmacSha256(normalized, key);
    } catch (e) {
      if (kDebugMode) print('❌ [DataIntegrity] signPayload error: $e');
      rethrow;
    }
  }

  /// Sign a raw string. Returns HMAC signature.
  static Future<String> signString(String data) async {
    final key = await _getSigningKey();
    return _hmacSha256(data, key);
  }

  // ─── Verification ─────────────────────────────────────────────────────────

  /// Verify a map payload against its stored signature.
  static Future<IntegrityResult> verifyPayload({
    required Map<String, dynamic> payload,
    required String signature,
  }) async {
    try {
      final key = await _getSigningKey();
      final normalized = _normalizePayload(payload);
      final expected = _hmacSha256(normalized, key);

      if (expected == signature) {
        return const IntegrityResult.valid();
      }
      return const IntegrityResult.invalid('Signature mismatch — data may have been tampered');
    } catch (e) {
      return IntegrityResult.invalid('Verification error: $e');
    }
  }

  /// Verify a raw string against its signature.
  static Future<IntegrityResult> verifyString({
    required String data,
    required String signature,
  }) async {
    try {
      final key = await _getSigningKey();
      final expected = _hmacSha256(data, key);
      if (expected == signature) return const IntegrityResult.valid();
      return const IntegrityResult.invalid('String integrity check failed');
    } catch (e) {
      return IntegrityResult.invalid('Verification error: $e');
    }
  }

  // ─── Booking-Specific Helpers ─────────────────────────────────────────────

  /// Generate an integrity token for a booking record.
  /// Token covers: bookingId + userId + amount + status
  static Future<String> signBooking({
    required String bookingId,
    required String userId,
    required double amount,
    required String status,
  }) async {
    final payload = {
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount.toStringAsFixed(2),
      'status': status,
    };
    return signPayload(payload);
  }

  /// Verify a booking record's integrity token.
  static Future<IntegrityResult> verifyBooking({
    required String bookingId,
    required String userId,
    required double amount,
    required String status,
    required String token,
  }) async {
    final payload = {
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount.toStringAsFixed(2),
      'status': status,
    };
    return verifyPayload(payload: payload, signature: token);
  }

  // ─── Static Verification (server-provided HMAC) ───────────────────────────

  /// Verify a server-provided HMAC using a shared secret (e.g. Supabase webhook secret).
  static bool verifyServerHmac({
    required String payload,
    required String signature,
    required String sharedSecret,
  }) {
    try {
      final key = utf8.encode(sharedSecret);
      final data = utf8.encode(payload);
      final hmac = Hmac(sha256, key);
      final computed = hmac.convert(data).toString();
      return computed == signature;
    } catch (e) {
      if (kDebugMode) print('❌ [DataIntegrity] Server HMAC error: $e');
      return false;
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  static String _hmacSha256(String data, String key) {
    final keyBytes = utf8.encode(key);
    final dataBytes = utf8.encode(data);
    final hmac = Hmac(sha256, keyBytes);
    return hmac.convert(dataBytes).toString();
  }

  /// Normalize a map to a deterministic JSON string for consistent hashing.
  static String _normalizePayload(Map<String, dynamic> payload) {
    final sorted = Map.fromEntries(
      payload.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return jsonEncode(sorted);
  }

  /// Get algorithm name for audit logging.
  static String get algorithm => _defaultAlgorithm;
}
