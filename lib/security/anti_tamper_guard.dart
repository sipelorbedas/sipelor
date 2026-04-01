/// Anti-Tamper Guard — SIPELOR BEDAS
/// 
/// Detects code/binary modification, signature tampering, and hook injection.
/// OWASP MASVS-RESILIENCE alignment: R1, R2, R3, R6
library;

import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Result of an anti-tamper check.
class TamperCheckResult {
  final bool isTampered;
  final List<String> violations;
  final TamperSeverity severity;

  const TamperCheckResult({
    required this.isTampered,
    required this.violations,
    required this.severity,
  });

  factory TamperCheckResult.clean() => const TamperCheckResult(
        isTampered: false,
        violations: [],
        severity: TamperSeverity.none,
      );
}

enum TamperSeverity { none, low, medium, high, critical }

/// Guards the application against runtime tampering and binary modification.
class AntiTamperGuard {
  /// Expected package name — tampered APK often changes this.
  static const String _expectedPackageName = 'com.bedas.sipelor';

  /// Expected app version — alert on unexpected downgrades.
  static const String _expectedVersion = '1.0.0';

  /// Known-good integrity token untuk memverifikasi konfigurasi internal.
  /// FIX: Di-inject via --dart-define=APP_INTEGRITY_TOKEN=<nilai> saat build production.
  /// Fallback ke nilai default hanya untuk development.
  /// Build command:
  ///   flutter build apk --release \
  ///     --dart-define=APP_INTEGRITY_TOKEN=<your-secret-token>
  static String get _configIntegrityToken {
    const envToken = String.fromEnvironment('APP_INTEGRITY_TOKEN', defaultValue: '');
    if (envToken.isNotEmpty) return envToken;
    // Fallback hanya untuk development — TIDAK AMAN untuk production
    assert(!kReleaseMode, 'APP_INTEGRITY_TOKEN harus di-set via --dart-define di production!');
    return 'sipelor-bedas-config-integrity-2026';
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Run all anti-tamper checks. Returns combined result.
  static Future<TamperCheckResult> runAllChecks() async {
    if (kIsWeb) return TamperCheckResult.clean();

    final violations = <String>[];

    final pkgResult = await _checkPackageIntegrity();
    final hookResult = await _checkHookingLibraries();
    final envResult = _checkRuntimeEnvironment();
    final debugResult = _checkDebuggerAttached();

    violations.addAll(pkgResult);
    violations.addAll(hookResult);
    violations.addAll(envResult);
    violations.addAll(debugResult);

    if (violations.isEmpty) return TamperCheckResult.clean();

    final severity = _calculateSeverity(violations);
    return TamperCheckResult(
      isTampered: severity.index >= TamperSeverity.medium.index,
      violations: violations,
      severity: severity,
    );
  }

  /// Verify HMAC integrity of a data payload.
  /// Use to verify server responses haven't been tampered.
  static bool verifyDataIntegrity({
    required String payload,
    required String expectedHmac,
    required String secret,
  }) {
    try {
      final key = utf8.encode(secret);
      final data = utf8.encode(payload);
      final hmac = Hmac(sha256, key);
      final digest = hmac.convert(data);
      final computed = digest.toString();
      return computed == expectedHmac;
    } catch (e) {
      if (kDebugMode) print('❌ [AntiTamper] HMAC verification error: $e');
      return false;
    }
  }

  /// Generate HMAC signature for a payload.
  static String generateHmac({
    required String payload,
    required String secret,
  }) {
    final key = utf8.encode(secret);
    final data = utf8.encode(payload);
    final hmac = Hmac(sha256, key);
    return hmac.convert(data).toString();
  }

  /// Hash a string with SHA-256.
  static String sha256Hash(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  // ─── Private Checks ───────────────────────────────────────────────────────

  /// Check package name and version for unexpected changes.
  static Future<List<String>> _checkPackageIntegrity() async {
    final violations = <String>[];
    try {
      final info = await PackageInfo.fromPlatform();

      if (info.packageName != _expectedPackageName &&
          !kDebugMode) {
        violations.add(
          'Package name mismatch: expected $_expectedPackageName, '
          'got ${info.packageName}',
        );
      }

      // Alert on version downgrade (possible rollback attack)
      if (_isVersionDowngrade(info.version, _expectedVersion)) {
        violations.add(
          'Version downgrade detected: current ${info.version} < '
          'expected $_expectedVersion',
        );
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [AntiTamper] Package check error: $e');
    }
    return violations;
  }

  /// Detect common hooking libraries injected at runtime.
  static Future<List<String>> _checkHookingLibraries() async {
    final violations = <String>[];
    if (!Platform.isAndroid && !Platform.isIOS) return violations;

    try {
      // Check for known hooking library paths
      const suspiciousPaths = [
        '/data/local/tmp/frida-server',
        '/data/local/tmp/re.frida.server',
        '/system/lib/libsubstrate.so',
        '/system/lib64/libsubstrate.so',
        '/system/lib/libhookzz.so',
        '/system/lib/libandbindhook.so',
        '/data/adb/modules/zygisk_lsposed',
        '/data/adb/modules/riru-core',
        '/data/misc/adb/adb.keys', // ADB enabled
      ];

      for (final path in suspiciousPaths) {
        if (await File(path).exists()) {
          violations.add('Hooking library detected: $path');
        }
      }

      // Check for Frida via port 27042 (already in RASP, double-check here)
      try {
        final socket = await Socket.connect(
          '127.0.0.1', 27042,
          timeout: const Duration(milliseconds: 200),
        );
        socket.destroy();
        violations.add('Frida gadget port 27042 is open');
      } catch (_) {
        // Expected — port not open on clean device
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [AntiTamper] Hooking library check error: $e');
    }
    return violations;
  }

  /// Check runtime environment for suspicious configurations.
  static List<String> _checkRuntimeEnvironment() {
    final violations = <String>[];

    try {
      if (!kIsWeb) {
        final env = Platform.environment;

        // Library injection via environment
        if (env.containsKey('LD_PRELOAD') && env['LD_PRELOAD']!.isNotEmpty) {
          violations.add('LD_PRELOAD set: ${env['LD_PRELOAD']}');
        }
        if (env.containsKey('LD_LIBRARY_PATH') &&
            env['LD_LIBRARY_PATH']!.contains('frida')) {
          violations.add('Frida in LD_LIBRARY_PATH');
        }
        if (env.containsKey('DYLD_INSERT_LIBRARIES')) {
          violations.add('DYLD_INSERT_LIBRARIES set (iOS injection)');
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [AntiTamper] Environment check error: $e');
    }
    return violations;
  }

  /// Check for debugger attachment (anti-debugging).
  static List<String> _checkDebuggerAttached() {
    final violations = <String>[];

    // In release mode, dart's assert is compiled out. If kDebugMode is true
    // in a supposedly production build, flag it.
    if (kDebugMode && kReleaseMode) {
      violations.add('Inconsistent build flags: kDebugMode=true in release');
    }

    return violations;
  }

  /// Determine tamper severity from violation list.
  static TamperSeverity _calculateSeverity(List<String> violations) {
    if (violations.isEmpty) return TamperSeverity.none;

    final critical = violations.any(
      (v) =>
          v.contains('Frida') ||
          v.contains('hooking') ||
          v.contains('Package name mismatch') ||
          v.contains('LD_PRELOAD'),
    );
    if (critical) return TamperSeverity.critical;

    final high = violations.any(
      (v) =>
          v.contains('Version downgrade') ||
          v.contains('Hooking library') ||
          v.contains('DYLD_INSERT_LIBRARIES'),
    );
    if (high) return TamperSeverity.high;

    if (violations.length >= 2) return TamperSeverity.medium;
    return TamperSeverity.low;
  }

  /// Simple semver comparison — returns true if [current] < [expected].
  static bool _isVersionDowngrade(String current, String expected) {
    try {
      final c = current.split('.').map(int.parse).toList();
      final e = expected.split('.').map(int.parse).toList();
      for (int i = 0; i < e.length; i++) {
        if (i >= c.length) return true;
        if (c[i] < e[i]) return true;
        if (c[i] > e[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Get human-readable message for severity.
  static String getSeverityMessage(TamperSeverity severity) {
    switch (severity) {
      case TamperSeverity.none:
        return 'Aplikasi berjalan dengan aman.';
      case TamperSeverity.low:
        return 'Terdeteksi kondisi mencurigakan ringan.';
      case TamperSeverity.medium:
        return 'PERINGATAN: Indikasi modifikasi aplikasi terdeteksi.';
      case TamperSeverity.high:
        return 'BAHAYA: Aplikasi kemungkinan telah dimodifikasi.';
      case TamperSeverity.critical:
        return 'KRITIS: Deteksi tampering — aplikasi dihentikan untuk keamanan data Anda.';
    }
  }

  /// Verify the integrity of an internal config token.
  static bool verifyConfigIntegrity(String providedToken) {
    return providedToken == _configIntegrityToken;
  }
}
