/// Request Signing and Authentication Middleware
/// Adds cryptographic signatures to API requests for integrity verification
library;

import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Request signing utility for API security
class RequestSigning {
  /// Generate HMAC-SHA256 signature for request
  static String generateSignature({
    required String method,
    required String path,
    required Map<String, dynamic>? body,
    required String timestamp,
    required String secretKey,
  }) {
    // Create string to sign: METHOD|PATH|TIMESTAMP|BODY_HASH
    final bodyHash = body != null ? _hashBody(body) : '';
    final stringToSign = '$method|$path|$timestamp|$bodyHash';
    
    // Generate HMAC-SHA256 signature
    final key = utf8.encode(secretKey);
    final bytes = utf8.encode(stringToSign);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return base64.encode(digest.bytes);
  }

  /// Hash request body for signature
  static String _hashBody(Map<String, dynamic> body) {
    final jsonString = jsonEncode(body);
    final bytes = utf8.encode(jsonString);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify request signature
  static bool verifySignature({
    required String signature,
    required String method,
    required String path,
    required Map<String, dynamic>? body,
    required String timestamp,
    required String secretKey,
  }) {
    final expectedSignature = generateSignature(
      method: method,
      path: path,
      body: body,
      timestamp: timestamp,
      secretKey: secretKey,
    );
    
    return signature == expectedSignature;
  }

  /// Generate timestamp for request (Unix timestamp in milliseconds)
  static String generateTimestamp() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Validate timestamp (prevent replay attacks)
  /// Returns true if timestamp is within acceptable window (5 minutes)
  static bool isTimestampValid(String timestamp, {int maxAgeMinutes = 5}) {
    try {
      final requestTime = int.parse(timestamp);
      final now = DateTime.now().millisecondsSinceEpoch;
      final difference = now - requestTime;
      final maxAge = maxAgeMinutes * 60 * 1000; // Convert to milliseconds
      
      return difference >= 0 && difference <= maxAge;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Invalid timestamp format: $e');
      }
      return false;
    }
  }

  /// Generate request nonce (prevents replay attacks)
  static String generateNonce() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch;
    return base64.encode(utf8.encode('$timestamp-$random'));
  }

  /// Create signed headers for HTTP request
  static Map<String, String> createSignedHeaders({
    required String method,
    required String path,
    required Map<String, dynamic>? body,
    required String apiKey,
    required String secretKey,
  }) {
    final timestamp = generateTimestamp();
    final nonce = generateNonce();
    final signature = generateSignature(
      method: method,
      path: path,
      body: body,
      timestamp: timestamp,
      secretKey: secretKey,
    );
    
    return {
      'X-API-Key': apiKey,
      'X-Signature': signature,
      'X-Timestamp': timestamp,
      'X-Nonce': nonce,
      'Content-Type': 'application/json',
    };
  }
}

/// API Request Interceptor for signing
class SignedRequestInterceptor {
  final String apiKey;
  final String secretKey;

  SignedRequestInterceptor({
    required this.apiKey,
    required this.secretKey,
  });

  /// Add security headers to request
  Map<String, String> addSecurityHeaders({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    Map<String, String>? existingHeaders,
  }) {
    final signedHeaders = RequestSigning.createSignedHeaders(
      method: method,
      path: path,
      body: body,
      apiKey: apiKey,
      secretKey: secretKey,
    );
    
    return {
      ...?existingHeaders,
      ...signedHeaders,
    };
  }
}
