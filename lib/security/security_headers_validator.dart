/// Security Headers Validator
/// Validates and enforces security headers in HTTP responses
library;

import 'package:flutter/foundation.dart';

/// Security headers validation result
class HeaderValidationResult {
  final bool isSecure;
  final List<String> warnings;
  final List<String> errors;
  final Map<String, String> missingHeaders;

  HeaderValidationResult({
    required this.isSecure,
    required this.warnings,
    required this.errors,
    required this.missingHeaders,
  });

  bool get hasIssues => warnings.isNotEmpty || errors.isNotEmpty;
}

/// Validates HTTP security headers
class SecurityHeadersValidator {
  /// Validate response headers for security best practices
  static HeaderValidationResult validateResponseHeaders(
    Map<String, String> headers,
  ) {
    final warnings = <String>[];
    final errors = <String>[];
    final missingHeaders = <String, String>{};

    // Convert headers to lowercase for case-insensitive comparison
    final lowerHeaders = <String, String>{};
    headers.forEach((key, value) {
      lowerHeaders[key.toLowerCase()] = value;
    });

    // 1. Check Strict-Transport-Security (HSTS)
    if (!lowerHeaders.containsKey('strict-transport-security')) {
      warnings.add('Missing Strict-Transport-Security header');
      missingHeaders['Strict-Transport-Security'] = 
          'max-age=31536000; includeSubDomains';
    } else {
      final hsts = lowerHeaders['strict-transport-security']!;
      if (!hsts.contains('max-age')) {
        errors.add('HSTS header missing max-age directive');
      }
      if (!hsts.contains('includeSubDomains')) {
        warnings.add('HSTS should include includeSubDomains');
      }
    }

    // 2. Check Content-Security-Policy (CSP)
    if (!lowerHeaders.containsKey('content-security-policy')) {
      warnings.add('Missing Content-Security-Policy header');
      missingHeaders['Content-Security-Policy'] = 
          "default-src 'self'; script-src 'self'";
    }

    // 3. Check X-Content-Type-Options
    if (!lowerHeaders.containsKey('x-content-type-options')) {
      warnings.add('Missing X-Content-Type-Options header');
      missingHeaders['X-Content-Type-Options'] = 'nosniff';
    } else if (lowerHeaders['x-content-type-options'] != 'nosniff') {
      errors.add('X-Content-Type-Options should be set to "nosniff"');
    }

    // 4. Check X-Frame-Options
    if (!lowerHeaders.containsKey('x-frame-options')) {
      warnings.add('Missing X-Frame-Options header');
      missingHeaders['X-Frame-Options'] = 'DENY';
    } else {
      final xfo = lowerHeaders['x-frame-options']!.toUpperCase();
      if (xfo != 'DENY' && xfo != 'SAMEORIGIN') {
        errors.add('X-Frame-Options should be DENY or SAMEORIGIN');
      }
    }

    // 5. Check X-XSS-Protection
    if (!lowerHeaders.containsKey('x-xss-protection')) {
      warnings.add('Missing X-XSS-Protection header');
      missingHeaders['X-XSS-Protection'] = '1; mode=block';
    }

    // 6. Check Referrer-Policy
    if (!lowerHeaders.containsKey('referrer-policy')) {
      warnings.add('Missing Referrer-Policy header');
      missingHeaders['Referrer-Policy'] = 'no-referrer';
    }

    // 7. Check Permissions-Policy (formerly Feature-Policy)
    if (!lowerHeaders.containsKey('permissions-policy')) {
      warnings.add('Missing Permissions-Policy header');
      missingHeaders['Permissions-Policy'] = 
          'geolocation=(), microphone=(), camera=()';
    }

    // 8. Check for insecure headers
    if (lowerHeaders.containsKey('server')) {
      warnings.add('Server header reveals server information');
    }
    if (lowerHeaders.containsKey('x-powered-by')) {
      warnings.add('X-Powered-By header reveals technology stack');
    }

    // 9. Check Cache-Control for sensitive data
    if (lowerHeaders.containsKey('cache-control')) {
      final cacheControl = lowerHeaders['cache-control']!.toLowerCase();
      if (!cacheControl.contains('no-store') && 
          !cacheControl.contains('private')) {
        warnings.add('Sensitive data should use Cache-Control: no-store');
      }
    }

    final isSecure = errors.isEmpty;

    if (kDebugMode && !isSecure) {
      if (kDebugMode) print('🔒 Security Header Validation Issues:');
      for (final error in errors) {
        if (kDebugMode) print('  ❌ ERROR: $error');
      }
      for (final warning in warnings) {
        if (kDebugMode) print('  ⚠️  WARNING: $warning');
      }
    }

    return HeaderValidationResult(
      isSecure: isSecure,
      warnings: warnings,
      errors: errors,
      missingHeaders: missingHeaders,
    );
  }

  /// Create recommended security headers for requests
  static Map<String, String> createSecurityHeaders() {
    return {
      'X-Requested-With': 'XMLHttpRequest',
      'X-Client-Version': '1.0.0',
      'Accept': 'application/json',
      'Content-Type': 'application/json; charset=utf-8',
    };
  }

  /// Validate SSL/TLS connection
  static bool validateConnection({
    required Uri uri,
  }) {
    // Ensure HTTPS is used
    if (uri.scheme != 'https') {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Insecure connection: Using ${uri.scheme} instead of HTTPS');
      }
      return false;
    }

    // Check if using default HTTPS port or custom port
    if (uri.hasPort && uri.port != 443) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  Non-standard HTTPS port: ${uri.port}');
      }
    }

    return true;
  }

  /// Check for sensitive data in URL (should be in body/headers instead)
  static List<String> checkSensitiveDataInUrl(Uri uri) {
    final issues = <String>[];
    final query = uri.query.toLowerCase();
    
    final sensitivePatterns = {
      'password': 'Password in URL',
      'token': 'Token in URL',
      'api_key': 'API key in URL',
      'apikey': 'API key in URL',
      'secret': 'Secret in URL',
      'credit': 'Credit card info in URL',
      'ssn': 'SSN in URL',
    };

    sensitivePatterns.forEach((pattern, message) {
      if (query.contains(pattern)) {
        issues.add(message);
      }
    });

    if (issues.isNotEmpty && kDebugMode) {
      if (kDebugMode) print('⚠️  Sensitive data detected in URL:');
      for (final issue in issues) {
        if (kDebugMode) print('    - $issue');
      }
    }

    return issues;
  }
}
