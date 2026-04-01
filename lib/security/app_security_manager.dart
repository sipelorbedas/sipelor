/// App Security Manager — SIPELOR BEDAS
/// 
/// Central security orchestrator. Coordinates all security sub-systems:
///   Layer 1 — RASP (Runtime Application Self-Protection)
///   Layer 2 — Anti-Tamper Guard
///   Layer 3 — Network Security Manager
///   Layer 4 — Data Integrity Verifier
///   Layer 5 — Existing: SSL Pinning, Input Sanitizer, Request Signing
///
/// Usage:
///   await AppSecurityManager.initialize();     // Call once at startup
///   final report = await AppSecurityManager.runFullAudit();
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'rasp_security.dart';
import 'anti_tamper_guard.dart';
import 'network_security_manager.dart';

/// Overall security posture of the application.
enum SecurityPosture {
  /// All checks passed — app is safe to use.
  green,

  /// Minor anomalies detected — continue with caution.
  yellow,

  /// Significant threats detected — restrict sensitive operations.
  orange,

  /// Critical threats detected — block app or force logout.
  red,
}

/// Full security audit report.
class SecurityAuditReport {
  final SecurityPosture posture;
  final RASPCheckResult raspResult;
  final TamperCheckResult tamperResult;
  final NetworkSecurityResult networkResult;
  final DateTime timestamp;
  final List<String> allWarnings;
  final List<String> recommendations;

  const SecurityAuditReport({
    required this.posture,
    required this.raspResult,
    required this.tamperResult,
    required this.networkResult,
    required this.timestamp,
    required this.allWarnings,
    required this.recommendations,
  });

  bool get isSecure => posture == SecurityPosture.green || posture == SecurityPosture.yellow;
  bool get requiresAction => posture == SecurityPosture.orange || posture == SecurityPosture.red;
}

/// Central coordinator for all application security checks.
class AppSecurityManager {
  static bool _initialized = false;
  static SecurityAuditReport? _lastReport;
  static DateTime? _lastAuditTime;

  /// Minimum interval between full audits to avoid performance impact.
  static const Duration _auditCooldown = Duration(minutes: 5);

  /// FIX: Timer.periodic agar bisa di-cancel dan tidak stack recursively (memory leak)
  static Timer? _monitoringTimer;

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Initialize the security manager. Must be called before first use.
  static Future<void> initialize() async {
    if (_initialized) return;

    if (kDebugMode) debugPrint('🔒 [AppSecurityManager] Initializing security systems...');

    // Run initial audit (non-blocking in release, blocking in debug)
    if (kReleaseMode) {
      runFullAudit().then((report) {
        _lastReport = report;
        _logPosture(report);
      }).catchError((e) {
        if (kDebugMode) print('⚠️  [AppSecurityManager] Initial audit error: $e');
      });
    } else {
      _lastReport = await runFullAudit();
      _logPosture(_lastReport!);
    }

    _initialized = true;
    if (kDebugMode) debugPrint('✅ [AppSecurityManager] Security systems initialized');
  }

  // ─── Full Audit ───────────────────────────────────────────────────────────

  /// Run a full security audit across all layers.
  /// Returns cached result if called within [_auditCooldown].
  static Future<SecurityAuditReport> runFullAudit({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastReport != null &&
        _lastAuditTime != null &&
        DateTime.now().difference(_lastAuditTime!) < _auditCooldown) {
      return _lastReport!;
    }

    final timestamp = DateTime.now();

    // Run all checks (some are async, run in parallel where safe)
    final results = await Future.wait([
      RASPSecurity.performSecurityCheck(),
      AntiTamperGuard.runAllChecks(),
      NetworkSecurityManager.assess(),
    ]);

    final raspResult = results[0] as RASPCheckResult;
    final tamperResult = results[1] as TamperCheckResult;
    final networkResult = results[2] as NetworkSecurityResult;

    // Aggregate all warnings
    final allWarnings = [
      ...raspResult.threats,
      ...tamperResult.violations,
      ...networkResult.warnings,
    ];

    // Determine overall posture
    final posture = _determinePosture(raspResult, tamperResult, networkResult);

    // Generate recommendations
    final recommendations = _generateRecommendations(
      raspResult, tamperResult, networkResult,
    );

    final report = SecurityAuditReport(
      posture: posture,
      raspResult: raspResult,
      tamperResult: tamperResult,
      networkResult: networkResult,
      timestamp: timestamp,
      allWarnings: allWarnings,
      recommendations: recommendations,
    );

    _lastReport = report;
    _lastAuditTime = timestamp;

    return report;
  }

  // ─── Quick Checks ─────────────────────────────────────────────────────────

  /// Quick check — returns true if app is safe to execute.
  static Future<bool> isAppSafe() async {
    final report = await runFullAudit();
    return report.posture != SecurityPosture.red;
  }

  /// Check if sensitive operations (payments, profile changes) are safe.
  static Future<bool> isSensitiveOperationSafe() async {
    final report = await runFullAudit();
    return report.isSecure;
  }

  /// Get the last audit report without re-running checks.
  static SecurityAuditReport? get lastReport => _lastReport;

  // ─── Periodic Monitoring ──────────────────────────────────────────────────

  /// Start background security monitoring (runs every 10 minutes).
  /// FIX: Menggunakan Timer.periodic agar bisa di-cancel dan tidak
  /// recursive stack (memory leak). Panggil stopPeriodicMonitoring() saat dispose.
  static void startPeriodicMonitoring({
    Duration interval = const Duration(minutes: 10),
    void Function(SecurityAuditReport)? onThreatDetected,
  }) {
    if (kIsWeb) return;

    // Batalkan monitoring sebelumnya jika ada
    _monitoringTimer?.cancel();

    if (kDebugMode) {
      debugPrint('🔒 [AppSecurityManager] Monitoring started (interval: ${interval.inMinutes}m)');
    }

    _monitoringTimer = Timer.periodic(interval, (_) async {
      try {
        final report = await runFullAudit(forceRefresh: true);
        _logPosture(report);

        if (report.requiresAction && onThreatDetected != null) {
          onThreatDetected(report);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️  [AppSecurityManager] Monitoring error: $e');
      }
    });
  }

  /// Stop background security monitoring dan batalkan timer.
  static void stopPeriodicMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    if (kDebugMode) {
      debugPrint('🔒 [AppSecurityManager] Monitoring stopped');
    }
  }

  // ─── Posture Determination ────────────────────────────────────────────────

  static SecurityPosture _determinePosture(
    RASPCheckResult rasp,
    TamperCheckResult tamper,
    NetworkSecurityResult network,
  ) {
    // Critical: RASP detected severe threats
    if (rasp.securityLevel == SecurityLevel.critical) return SecurityPosture.red;

    // Critical: App tampering confirmed
    if (tamper.isTampered && tamper.severity == TamperSeverity.critical) {
      return SecurityPosture.red;
    }

    // Orange: High-level threats
    if (rasp.securityLevel == SecurityLevel.danger) return SecurityPosture.orange;
    if (tamper.severity == TamperSeverity.high) return SecurityPosture.orange;
    if (network.riskLevel == NetworkRiskLevel.critical) return SecurityPosture.orange;

    // Yellow: Warnings present but manageable
    if (rasp.securityLevel == SecurityLevel.warning) return SecurityPosture.yellow;
    if (tamper.severity == TamperSeverity.medium) return SecurityPosture.yellow;
    if (network.riskLevel == NetworkRiskLevel.high) return SecurityPosture.yellow;
    if (network.riskLevel == NetworkRiskLevel.medium) return SecurityPosture.yellow;

    return SecurityPosture.green;
  }

  // ─── Recommendations ──────────────────────────────────────────────────────

  static List<String> _generateRecommendations(
    RASPCheckResult rasp,
    TamperCheckResult tamper,
    NetworkSecurityResult network,
  ) {
    final recs = <String>[];

    if (rasp.threats.any((t) => t.toLowerCase().contains('root'))) {
      recs.add('Gunakan perangkat yang tidak di-root untuk keamanan transaksi.');
    }
    if (rasp.threats.any((t) => t.toLowerCase().contains('emulator'))) {
      recs.add('Hindari penggunaan emulator untuk transaksi sensitif.');
    }
    if (tamper.violations.any((v) => v.contains('Frida'))) {
      recs.add('Deteksi alat hacking. Hubungi administrator segera.');
    }
    if (network.warnings.any((w) => w.contains('proxy'))) {
      recs.add('Proxy jaringan terdeteksi. Pastikan Anda menggunakan jaringan tepercaya.');
    }
    if (network.warnings.any((w) => w.contains('VPN'))) {
      recs.add('VPN aktif. Pastikan VPN yang digunakan tepercaya.');
    }

    return recs;
  }

  // ─── Logging ──────────────────────────────────────────────────────────────

  static void _logPosture(SecurityAuditReport report) {
    if (!kDebugMode) return;

    final icon = switch (report.posture) {
      SecurityPosture.green => '🟢',
      SecurityPosture.yellow => '🟡',
      SecurityPosture.orange => '🟠',
      SecurityPosture.red => '🔴',
    };

    debugPrint('$icon [AppSecurityManager] Posture: ${report.posture.name}');
    if (report.allWarnings.isNotEmpty) {
      debugPrint('⚠️  Warnings: ${report.allWarnings.length}');
      for (final w in report.allWarnings) {
        debugPrint('   - $w');
      }
    }
  }

  /// Get user-facing security status message in Indonesian.
  static String getStatusMessage(SecurityPosture posture) {
    switch (posture) {
      case SecurityPosture.green:
        return 'Aplikasi berjalan aman ✓';
      case SecurityPosture.yellow:
        return 'Peringatan keamanan terdeteksi. Berhati-hatilah.';
      case SecurityPosture.orange:
        return 'Risiko keamanan tinggi. Hindari transaksi sensitif.';
      case SecurityPosture.red:
        return 'Ancaman kritis terdeteksi. Aplikasi dibatasi untuk melindungi data Anda.';
    }
  }
}
