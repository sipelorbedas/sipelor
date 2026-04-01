/// Runtime Application Self Protection (RASP)
/// Detects and prevents attacks at runtime
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';

/// RASP Security Check Results
class RASPCheckResult {
  final bool isSafe;
  final List<String> threats;
  final SecurityLevel securityLevel;

  RASPCheckResult({
    required this.isSafe,
    required this.threats,
    required this.securityLevel,
  });
}

/// Security levels
enum SecurityLevel {
  safe,        // No threats detected
  warning,     // Minor issues, app can continue
  danger,      // Major issues, recommend user caution
  critical,    // Severe threats, block app functionality
}

/// Runtime Application Self Protection
class RASPSecurity {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  // FIX: Gunakan Timer.periodic agar bisa di-cancel dan tidak stack recursively
  static Timer? _monitoringTimer;

  /// Perform comprehensive security check
  static Future<RASPCheckResult> performSecurityCheck() async {
    // Web platform does not support native security checks
    if (kIsWeb) {
      return RASPCheckResult(
        isSafe: true,
        threats: [],
        securityLevel: SecurityLevel.safe,
      );
    }

    final threats = <String>[];

    // Run all security checks
    final rootCheck = await _checkRootedDevice();
    final debugCheck = await _checkDebugMode();
    final emulatorCheck = await _checkEmulator();
    final integrityCheck = await _checkAppIntegrity();
    final environmentCheck = await _checkEnvironmentVariables();

    threats.addAll(rootCheck);
    threats.addAll(debugCheck);
    threats.addAll(emulatorCheck);
    threats.addAll(integrityCheck);
    threats.addAll(environmentCheck);

    // Determine security level
    final securityLevel = _determineSecurityLevel(threats);
    final isSafe = securityLevel == SecurityLevel.safe || 
                   securityLevel == SecurityLevel.warning;

    return RASPCheckResult(
      isSafe: isSafe,
      threats: threats,
      securityLevel: securityLevel,
    );
  }

  /// Check if device is rooted/jailbroken
  static Future<List<String>> _checkRootedDevice() async {
    final threats = <String>[];

    if (kIsWeb) return threats;

    if (Platform.isAndroid) {
      // Check common root indicators on Android
      final rootPaths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
        '/su/bin/su',
      ];

      for (final path in rootPaths) {
        if (await File(path).exists()) {
          threats.add('Root access detected: $path');
          break;
        }
      }

      // Check for Magisk
      if (await File('/sbin/.magisk').exists()) {
        threats.add('Magisk detected - device is rooted');
      }

      // Check build tags
      try {
        final androidInfo = await _deviceInfo.androidInfo;
        if (androidInfo.tags.contains('test-keys')) {
          threats.add('Device running test-keys build - likely rooted');
        }
      } catch (e) {
        if (kDebugMode) print('Error checking build tags: $e');
      }

    } else if (Platform.isIOS) {
      // Check common jailbreak indicators on iOS
      final jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
        '/private/var/lib/apt/',
      ];

      for (final path in jailbreakPaths) {
        if (await File(path).exists()) {
          threats.add('Jailbreak detected: $path');
          break;
        }
      }

      // Check if can write to system directories
      try {
        final testFile = File('/private/jailbreak.txt');
        await testFile.writeAsString('test');
        await testFile.delete();
        threats.add('Can write to system directories - jailbroken');
      } catch (e) {
        // Good - cannot write to system directories
      }
    }

    return threats;
  }

  /// Check if running in debug mode
  static Future<List<String>> _checkDebugMode() async {
    final threats = <String>[];

    if (kDebugMode) {
      threats.add('Running in debug mode - not for production use');
    }

    return threats;
  }

  /// Check if running on emulator/simulator
  static Future<List<String>> _checkEmulator() async {
    final threats = <String>[];

    if (kIsWeb) return threats;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        
        // Check common emulator indicators
        if (androidInfo.fingerprint.contains('generic') ||
            androidInfo.fingerprint.contains('emulator') ||
            androidInfo.model.contains('Emulator') ||
            androidInfo.model.contains('Android SDK') ||
            androidInfo.manufacturer.contains('Genymotion') ||
            androidInfo.product.contains('sdk') ||
            androidInfo.product.contains('vbox')) {
          threats.add('Running on Android emulator');
        }

        // Check hardware features
        if (androidInfo.isPhysicalDevice == false) {
          threats.add('Not a physical device');
        }

      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        
        if (!iosInfo.isPhysicalDevice) {
          threats.add('Running on iOS simulator');
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking emulator: $e');
    }

    return threats;
  }

  /// Check app integrity (tampering detection)
  /// OWASP MASVS-RESILIENCE: Detects Frida, Xposed, and hooking frameworks.
  static Future<List<String>> _checkAppIntegrity() async {
    final threats = <String>[];

    if (kIsWeb) return threats;

    try {
      if (Platform.isAndroid) {
        // --- Frida detection ---
        // Known Frida server binary locations
        final fridaPaths = [
          '/data/local/tmp/frida-server',
          '/data/local/tmp/re.frida.server',
          '/system/bin/frida-server',
        ];
        for (final p in fridaPaths) {
          if (await File(p).exists()) {
            threats.add('Frida server detected at $p');
            break;
          }
        }

        // Frida gadget library injection via open port 27042
        try {
          final socket = await Socket.connect('127.0.0.1', 27042,
              timeout: const Duration(milliseconds: 300));
          socket.destroy();
          threats.add('Frida gadget detected — port 27042 open');
        } catch (_) {
          // Expected: port not open on clean device
        }

        // --- Xposed / LSPosed detection ---
        final xposedPaths = [
          '/system/framework/XposedBridge.jar',
          '/data/adb/lspatch',
          '/system/lib/libxposed_art.so',
        ];
        for (final p in xposedPaths) {
          if (await File(p).exists()) {
            threats.add('Xposed/LSPosed framework detected at $p');
            break;
          }
        }

        // --- Substrate / Cydia for Android ---
        if (await File('/data/data/com.saurik.substrate').exists()) {
          threats.add('Cydia Substrate detected');
        }

        // --- Build tag integrity ---
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          if (androidInfo.tags.contains('test-keys')) {
            threats.add('Device using test-keys — custom/rooted ROM likely');
          }
        } catch (e) {
          if (kDebugMode) print('Error reading build tags: $e');
        }
      } else if (Platform.isIOS) {
        // --- Frida on iOS ---
        try {
          final socket = await Socket.connect('127.0.0.1', 27042,
              timeout: const Duration(milliseconds: 300));
          socket.destroy();
          threats.add('Frida gadget detected on iOS — port 27042 open');
        } catch (_) {
          // Expected on clean device
        }

        // --- Substrate paths ---
        final substratePaths = [
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/usr/lib/libcycript.dylib',
        ];
        for (final p in substratePaths) {
          if (await File(p).exists()) {
            threats.add('MobileSubstrate/Cycript detected at $p');
            break;
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error checking integrity: $e');
    }

    return threats;
  }

  /// Check suspicious environment variables
  static Future<List<String>> _checkEnvironmentVariables() async {
    final threats = <String>[];

    if (kIsWeb) return threats;

    try {
      final env = Platform.environment;

      // Check for debugging/development indicators
      if (env.containsKey('LD_PRELOAD')) {
        threats.add('LD_PRELOAD detected - possible library injection');
      }

      if (env.containsKey('DYLD_INSERT_LIBRARIES')) {
        threats.add('DYLD_INSERT_LIBRARIES detected - possible library injection');
      }

    } catch (e) {
      if (kDebugMode) print('Error checking environment: $e');
    }

    return threats;
  }

  /// Determine overall security level from threats
  static SecurityLevel _determineSecurityLevel(List<String> threats) {
    if (threats.isEmpty) {
      return SecurityLevel.safe;
    }

    // Count critical threats
    final criticalCount = threats.where((t) => 
      t.contains('root') ||
      t.contains('jailbreak') ||
      t.contains('Frida') ||
      t.contains('injection')
    ).length;

    if (criticalCount >= 2) {
      return SecurityLevel.critical;
    } else if (criticalCount == 1) {
      return SecurityLevel.danger;
    } else if (threats.length >= 3) {
      return SecurityLevel.danger;
    } else {
      return SecurityLevel.warning;
    }
  }

  /// Monitor for runtime attacks
  /// FIX: Gunakan Timer.periodic agar bisa di-cancel dan tidak stack recursively.
  /// Interval diperpanjang ke 15 menit di production untuk menghemat resource.
  static void startRuntimeMonitoring({
    Duration interval = const Duration(minutes: 15),
  }) {
    // Not applicable on web
    if (kIsWeb) return;

    // Batalkan monitoring sebelumnya jika ada
    _monitoringTimer?.cancel();

    if (kDebugMode) print('🔒 RASP monitoring started (interval: ${interval.inMinutes}m)');

    _monitoringTimer = Timer.periodic(interval, (_) async {
      try {
        final result = await performSecurityCheck();
        if (!result.isSafe) {
          _handleSecurityThreat(result);
        }
      } catch (e) {
        if (kDebugMode) print('⚠️  RASP monitoring error: $e');
      }
    });
  }

  /// Stop runtime monitoring dan batalkan timer
  static void stopRuntimeMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    if (kDebugMode) print('🔒 RASP monitoring stopped');
  }

  /// Handle detected security threat
  static void _handleSecurityThreat(RASPCheckResult result) {
    if (kDebugMode) {
      if (kDebugMode) print('⚠️  Security threat detected:');
      if (kDebugMode) print('  Level: ${result.securityLevel}');
      for (final threat in result.threats) {
        if (kDebugMode) print('  - $threat');
      }
    }

    // In production:
    // 1. Log to security monitoring system
    // 2. Notify user if appropriate
    // 3. Disable sensitive features if critical
    // 4. Optionally exit app if threat is severe
  }

  /// Check if app should continue running
  static Future<bool> shouldAllowExecution() async {
    final result = await performSecurityCheck();
    
    // Allow execution unless critical threats detected
    if (result.securityLevel == SecurityLevel.critical) {
      return false;
    }

    return true;
  }

  /// Get security recommendation message for user
  static String getSecurityMessage(RASPCheckResult result) {
    switch (result.securityLevel) {
      case SecurityLevel.safe:
        return 'Aplikasi berjalan dengan aman';
        
      case SecurityLevel.warning:
        return 'Terdeteksi kondisi tidak normal. '
               'Beberapa fitur mungkin dibatasi.';
        
      case SecurityLevel.danger:
        return 'PERINGATAN: Perangkat Anda terdeteksi tidak aman. '
               'Hindari melakukan transaksi sensitif.';
        
      case SecurityLevel.critical:
        return 'BAHAYA: Perangkat Anda terdeteksi telah dimodifikasi (root/jailbreak). '
               'Aplikasi tidak dapat berjalan untuk melindungi data Anda.';
    }
  }
}
