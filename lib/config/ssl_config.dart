import 'package:flutter/foundation.dart';

/// SSL Certificate Pinning Configuration
/// 
/// This configuration contains SHA-256 hashes of SSL certificates
/// used to prevent Man-in-the-Middle (MITM) attacks.
/// 
/// SECURITY NOTES:
/// - Certificates are pinned for production builds only
/// - Development builds bypass pinning for easier debugging
/// - Multiple pins are used for certificate rotation
/// 
/// MAINTENANCE:
/// - Check certificate expiry every 6 months
/// - Update pins before certificate rotation
/// - Always maintain at least 2 valid pins (current + backup)
/// 
/// Last Updated: 2026-01-26
/// Next Review: 2026-07-26
class SSLConfig {
  // ==================== Environment Detection ====================
  
  /// Check if running in production mode
  static bool get isProduction {
    return kReleaseMode;
  }
  
  /// Check if running in development mode
  static bool get isDevelopment {
    return kDebugMode;
  }
  
  // ==================== SSL Pinning Configuration ====================
  
  /// Enable SSL certificate pinning
  /// 
  /// Production: true (enforced)
  /// Development: false (bypass for debugging)
  static bool get sslPinningEnabled {
    // Always enable in production
    if (isProduction) {
      return true;
    }
    
    // In development, can be toggled via environment variable
    const devPinning = String.fromEnvironment('ENABLE_SSL_PINNING');
    return devPinning.toLowerCase() == 'true';
  }
  
  // ==================== Certificate Pins ====================
  
  /// Supabase domain for certificate pinning
  static const String supabaseDomain = 'gbhprmibbcqfwjgrkfzq.supabase.co';

  /// Primary certificate SHA-256 fingerprint
  ///
  /// Extracted: 2026-03-13 (diverifikasi dengan scripts/check_certificate_expiry.ps1)
  /// Issuer: Google Trust Services (WE1)
  /// Subject: CN=supabase.co
  /// Valid: 2026-03-02 → 2026-05-31
  ///
  /// ⚠️  PERLU DIPERBARUI sebelum 2026-05-31!
  static const String primaryCertificatePin =
      'sha256/OYvM4tmVyyPLCSqTe1tYvZW0CKRfv4mre7EUA0eJrn0=';

  /// Backup certificate SHA-256 fingerprint
  ///
  /// Google Trust Services WE1 Intermediate CA — lebih stabil, jarang berubah.
  /// Referensi: https://pki.goog/repository/
  static const String backupCertificatePin =
      'sha256/zCTnfLwLKbS9S2sbp+uFz4KZOocFvXxkV06Ce9O5M2w=';
  
  /// All certificate pins to check
  /// 
  /// At least one of these must match for connection to succeed
  static List<String> get certificatePins => [
    primaryCertificatePin,
    backupCertificatePin,
  ];
  
  // ==================== Pinning Rules ====================
  
  /// Domains that require certificate pinning
  static List<String> get pinnedDomains => [
    supabaseDomain,
    '*.supabase.co', // All Supabase subdomains
  ];
  
  /// Timeout for SSL handshake (seconds)
  static const int sslHandshakeTimeout = 10;
  
  /// Allow connection on pinning failure in development
  static bool get allowBypassOnFailure => isDevelopment;
  
  // ==================== Certificate Information ====================
  
  /// Get certificate information summary
  static Map<String, dynamic> getCertificateInfo() {
    return {
      'ssl_pinning_enabled': sslPinningEnabled,
      'environment': isProduction ? 'production' : 'development',
      'pinned_domain': supabaseDomain,
      'primary_pin': '${primaryCertificatePin.substring(0, 20)}...',
      'backup_pin': '${backupCertificatePin.substring(0, 20)}...',
      'total_pins': certificatePins.length,
      'last_updated': '2026-03-13',
      'next_review': '2026-05-15',
    };
  }
  
  /// Get certificate expiry warning
  static String? getCertificateExpiryWarning() {
    final now = DateTime.now();
    // ⚠️ Sertifikat aktif expires 2026-05-31 — review WAJIB sebelum tanggal ini
    final nextReview = DateTime(2026, 5, 15); // 2 minggu sebelum expire
    
    final daysUntilReview = nextReview.difference(now).inDays;
    
    if (daysUntilReview < 0) {
      return '⚠️ URGENT: Certificate pins are overdue for review! Review immediately.';
    } else if (daysUntilReview < 30) {
      return '⚠️ Certificate pins need review in $daysUntilReview days.';
    } else if (daysUntilReview < 60) {
      return 'ℹ️ Certificate pins review scheduled in $daysUntilReview days.';
    }
    
    return null;
  }
  
  // ==================== Validation ====================
  
  /// Validate SSL configuration
  static bool validate() {
    // Must have at least 2 pins for redundancy
    if (certificatePins.length < 2) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SSLConfig] Warning: Less than 2 certificate pins configured');
      }
      return false;
    }
    
    // All pins must be in correct format
    for (final pin in certificatePins) {
      if (!pin.startsWith('sha256/')) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [SSLConfig] Invalid pin format: $pin');
        }
        return false;
      }
    }
    
    // Check expiry warning
    final warning = getCertificateExpiryWarning();
    if (warning != null && isProduction) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [SSLConfig] $warning');
      }
    }
    
    return true;
  }
}
