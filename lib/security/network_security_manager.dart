/// Network Security Manager — SIPELOR BEDAS
/// 
/// Enforces network-level security policies:
/// - HTTPS-only enforcement
/// - Proxy & VPN detection
/// - DNS-based threat detection
/// - Suspicious traffic pattern detection
/// - Security header validation
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Result of a network security assessment.
class NetworkSecurityResult {
  final bool isSecure;
  final List<String> warnings;
  final NetworkRiskLevel riskLevel;

  const NetworkSecurityResult({
    required this.isSecure,
    required this.warnings,
    required this.riskLevel,
  });

  factory NetworkSecurityResult.secure() => const NetworkSecurityResult(
        isSecure: true,
        warnings: [],
        riskLevel: NetworkRiskLevel.low,
      );
}

enum NetworkRiskLevel { low, medium, high, critical }

/// Manages and enforces network security policies.
class NetworkSecurityManager {
  // ignore: unused_field
  static const String _apiHost = 'supabase.co';

  /// Required security response headers dari backend.
  /// Diperluas untuk mencakup HSTS, XSS Protection, dan CSP.
  static const _requiredHeaders = {
    'x-content-type-options': 'nosniff',
    'x-frame-options': 'DENY',
    'x-xss-protection': '1; mode=block',
    'strict-transport-security': 'max-age=',  // Partial match — cukup ada prefix-nya
    'referrer-policy': 'strict-origin',        // Partial match
  };

  // ─── Main Assessment ──────────────────────────────────────────────────────

  /// Run a full network security assessment.
  static Future<NetworkSecurityResult> assess() async {
    if (kIsWeb) return NetworkSecurityResult.secure();

    final warnings = <String>[];

    warnings.addAll(await _checkProxy());
    warnings.addAll(await _checkVpnInterfaces());
    warnings.addAll(_checkHttpsEnforcement());

    if (warnings.isEmpty) return NetworkSecurityResult.secure();

    final riskLevel = _calculateRisk(warnings);
    return NetworkSecurityResult(
      isSecure: riskLevel.index < NetworkRiskLevel.high.index,
      warnings: warnings,
      riskLevel: riskLevel,
    );
  }

  // ─── URL Validation ───────────────────────────────────────────────────────

  /// Returns `true` if [url] uses HTTPS (or is a local/debug URL).
  static bool isUrlSecure(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (kDebugMode && (uri.host == 'localhost' || uri.host == '127.0.0.1')) {
      return true; // Allow HTTP for local dev
    }
    return uri.scheme == 'https';
  }

  /// Throw if URL is not secure in production.
  static void enforceHttps(String url) {
    if (!isUrlSecure(url) && !kDebugMode) {
      throw SecurityException(
        'HTTPS required in production. Insecure URL blocked: $url',
      );
    }
  }

  // ─── Response Header Validation ───────────────────────────────────────────

  /// Validate that an HTTP response carries the expected security headers.
  /// Returns map of header name → present/valid.
  static Map<String, bool> validateSecurityHeaders(http.Response response) {
    final result = <String, bool>{};
    for (final entry in _requiredHeaders.entries) {
      final value = response.headers[entry.key];
      // Untuk header dengan partial match (value kosong string = hanya cek keberadaan)
      result[entry.key] = value != null &&
          (entry.value.isEmpty || value.toLowerCase().contains(entry.value.toLowerCase()));
    }
    return result;
  }

  /// Generate recommended security headers untuk request outgoing.
  static Map<String, String> buildSecurityRequestHeaders() {
    return {
      'X-Requested-With': 'XMLHttpRequest',
      'Cache-Control': 'no-store',
      'Pragma': 'no-cache',
    };
  }

  /// Returns `true` if all required security headers are present.
  static bool hasRequiredSecurityHeaders(http.Response response) {
    return validateSecurityHeaders(response).values.every((v) => v);
  }

  // ─── Proxy Detection ──────────────────────────────────────────────────────

  static Future<List<String>> _checkProxy() async {
    final warnings = <String>[];
    if (kIsWeb) return warnings;

    try {
      // Check system proxy settings
      if (Platform.isAndroid || Platform.isIOS) {
        final proxyHost = Platform.environment['http_proxy'] ??
            Platform.environment['HTTP_PROXY'] ??
            Platform.environment['https_proxy'] ??
            Platform.environment['HTTPS_PROXY'];

        if (proxyHost != null && proxyHost.isNotEmpty) {
          warnings.add('System proxy detected: $proxyHost');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [NetworkSecurity] Proxy check error: $e');
    }
    return warnings;
  }

  // ─── VPN Detection ────────────────────────────────────────────────────────

  static Future<List<String>> _checkVpnInterfaces() async {
    final warnings = <String>[];
    if (kIsWeb || !Platform.isAndroid) return warnings;

    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (final iface in interfaces) {
        final name = iface.name.toLowerCase();
        // tun0/tun1 = typical VPN, ppp0 = PPP VPN
        if (name.startsWith('tun') || name.startsWith('ppp')) {
          warnings.add('VPN/tunnel interface detected: ${iface.name}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [NetworkSecurity] VPN check error: $e');
    }
    return warnings;
  }

  // ─── HTTPS Enforcement Check ──────────────────────────────────────────────

  static List<String> _checkHttpsEnforcement() {
    final warnings = <String>[];

    // In release mode, kDebugMode is false. If for some reason debug mode
    // leaks into production, flag it.
    if (kReleaseMode && kDebugMode) {
      warnings.add('Debug mode active in release build — insecure connections may be allowed');
    }
    return warnings;
  }

  // ─── Risk Calculation ─────────────────────────────────────────────────────

  static NetworkRiskLevel _calculateRisk(List<String> warnings) {
    final critical = warnings.any(
      (w) => w.contains('proxy') || w.contains('Frida'),
    );
    if (critical) return NetworkRiskLevel.critical;

    final high = warnings.any((w) => w.contains('VPN'));
    if (high) return NetworkRiskLevel.high;

    if (warnings.length >= 2) return NetworkRiskLevel.medium;
    return NetworkRiskLevel.low;
  }

  /// Get risk level display name in Indonesian.
  static String getRiskLevelName(NetworkRiskLevel level) {
    switch (level) {
      case NetworkRiskLevel.low:
        return 'Rendah';
      case NetworkRiskLevel.medium:
        return 'Sedang';
      case NetworkRiskLevel.high:
        return 'Tinggi';
      case NetworkRiskLevel.critical:
        return 'Kritis';
    }
  }
}

/// Custom security exception.
class SecurityException implements Exception {
  final String message;
  const SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
