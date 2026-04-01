/// Certificate Rotation Service
/// 
/// Manages SSL certificate pinning with support for certificate rotation.
/// Implements primary and backup pins to prevent service disruption during rotation.
library;

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

/// Service for managing certificate rotation
class CertificateRotationService {
  // Primary certificate pins (currently in use)
  static const List<String> primaryPins = [
    // TODO: Add your actual certificate pins here
    // Example: 'sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=',
  ];
  
  // Backup certificate pins (for rotation)
  static const List<String> backupPins = [
    // TODO: Add backup certificate pins here for rotation
    // Example: 'sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB=',
    // Example: 'sha256/CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC=',
  ];
  
  // Certificate expiry dates
  static const Map<String, DateTime> certificateExpiry = {
    // TODO: Add expiry dates for each pin
    // Example: 'sha256/AAA...': DateTime(2026, 12, 31),
  };
  
  /// Get all valid certificate pins (primary + backup)
  static List<String> getAllValidPins() {
    return [...primaryPins, ...backupPins];
  }
  
  /// Check if any certificate is expiring soon
  /// 
  /// [daysThreshold] Number of days before expiry to trigger alert (default: 30)
  /// Returns true if any certificate expires within the threshold
  static bool isCertificateExpiringSoon({int daysThreshold = 30}) {
    if (certificateExpiry.isEmpty) return false;
    
    final now = DateTime.now();
    
    for (final entry in certificateExpiry.entries) {
      final daysUntilExpiry = entry.value.difference(now).inDays;
      if (daysUntilExpiry <= daysThreshold) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Get detailed expiry information for all certificates
  /// 
  /// Returns a map of certificate pin to days remaining until expiry
  static Map<String, int> getCertificateExpiryDetails() {
    final now = DateTime.now();
    final details = <String, int>{};
    
    certificateExpiry.forEach((pin, expiry) {
      details[pin] = expiry.difference(now).inDays;
    });
    
    return details;
  }
  
  /// Validate certificate against configured pins
  /// 
  /// Returns true if the certificate matches any primary or backup pin
  static bool validateCertificate(X509Certificate cert) {
    final certPin = _getCertificatePin(cert);
    
    // Check against primary pins first
    if (primaryPins.contains(certPin)) {
      if (kDebugMode) {
        if (kDebugMode) print('✅ Certificate validated against PRIMARY pin');
      }
      return true;
    }
    
    // Check against backup pins
    if (backupPins.contains(certPin)) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ Certificate validated against BACKUP pin');
        if (kDebugMode) print('This indicates certificate rotation has occurred');
      }
      
      // Log this event for monitoring
      _logBackupPinUsage(certPin);
      return true;
    }
    
    // Certificate not recognized
    if (kDebugMode) {
      if (kDebugMode) print('❌ Certificate validation FAILED');
      if (kDebugMode) print('Certificate pin: $certPin');
    }
    
    return false;
  }
  
  /// Extract SHA-256 pin from certificate
  static String _getCertificatePin(X509Certificate cert) {
    try {
      // Get DER-encoded certificate
      final der = cert.der;
      
      // Calculate SHA-256 hash
      final digest = sha256.convert(der);
      
      // Convert to base64 and format as pin
      final pin = 'sha256/${base64.encode(digest.bytes)}';
      
      return pin;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Error extracting certificate pin: $e');
      }
      return '';
    }
  }
  
  /// Log backup pin usage for monitoring
  static void _logBackupPinUsage(String pin) {
    // TODO: Integrate with your monitoring system (e.g., Sentry)
    if (kDebugMode) {
      if (kDebugMode) print('📊 BACKUP PIN USED: ${pin.substring(0, 20)}...');
      if (kDebugMode) print('Action required: Update app with new primary pins');
    }
    
    // In production, send alert to monitoring system
    // ErrorTrackingService.logInfo('Backup certificate pin used', {
    //   'pin': pin,
    //   'timestamp': DateTime.now().toIso8601String(),
    // });
  }
  
  /// Perform rotation check and send alerts if needed
  /// 
  /// Should be called periodically (e.g., daily) to check certificate status
  static Future<void> checkAndAlertRotation() async {
    if (isCertificateExpiringSoon(daysThreshold: 30)) {
      final details = getCertificateExpiryDetails();
      
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ ======================================');
        if (kDebugMode) print('⚠️ CERTIFICATE ROTATION ALERT');
        if (kDebugMode) print('⚠️ ======================================');
        
        details.forEach((pin, daysRemaining) {
          if (kDebugMode) print('⚠️ Pin: ${pin.substring(0, 20)}...');
          if (kDebugMode) print('⚠️ Days remaining: $daysRemaining');
          if (kDebugMode) print('⚠️ ');
        });
        
        if (kDebugMode) print('⚠️ Action Required:');
        if (kDebugMode) print('⚠️ 1. Request new certificate from CA');
        if (kDebugMode) print('⚠️ 2. Add new pin to backupPins');
        if (kDebugMode) print('⚠️ 3. Deploy app update');
        if (kDebugMode) print('⚠️ 4. Install new certificate on server');
        if (kDebugMode) print('⚠️ 5. Move new pin to primaryPins');
        if (kDebugMode) print('⚠️ ======================================');
      }
      
      // TODO: Send alert to development team
      // await _sendRotationAlert(details);
    }
  }
  
  /// Get rotation status report
  static String getRotationStatusReport() {
    final buffer = StringBuffer();
    buffer.writeln('Certificate Rotation Status Report');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    buffer.writeln('Primary Pins: ${primaryPins.length}');
    buffer.writeln('Backup Pins: ${backupPins.length}');
    buffer.writeln();
    
    final details = getCertificateExpiryDetails();
    if (details.isNotEmpty) {
      buffer.writeln('Certificate Expiry Details:');
      details.forEach((pin, days) {
        final status = days <= 30 ? '⚠️ EXPIRING SOON' : '✅ OK';
        buffer.writeln('  ${pin.substring(0, 30)}... : $days days ($status)');
      });
    } else {
      buffer.writeln('No expiry dates configured');
    }
    
    buffer.writeln();
    buffer.writeln('=' * 50);
    
    return buffer.toString();
  }
}
