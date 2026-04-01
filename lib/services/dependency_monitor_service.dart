import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Dependency Monitor Service
///
/// Monitors and tracks dependency versions and security status
///
/// Features:
/// - Dependency version tracking
/// - Security vulnerability alerts
/// - Update recommendations
/// - Dependency health checks
class DependencyMonitorService {
  static final DependencyMonitorService _instance =
      DependencyMonitorService._internal();
  factory DependencyMonitorService() => _instance;
  DependencyMonitorService._internal();

  /// Critical dependencies to monitor
  static const Map<String, String> _criticalDependencies = {
    'supabase_flutter': '^2.6.0',
    'sentry_flutter': '^9.10.0',
    'flutter_riverpod': '^2.6.1',
    'google_maps_flutter': '^2.10.0',
    'cached_network_image': '^3.3.0',
    'flutter_secure_storage': '^10.0.0',
    'local_auth': '^3.0.0',
  };

  /// Known security vulnerabilities (update this list regularly)
  /// Format: package_name: version_with_vulnerability
  static const Map<String, List<String>> _knownVulnerabilities = {
    // Example: 'package_name': ['<1.0.0', '>=2.0.0 <2.1.0'],
    // Add known vulnerabilities here
  };

  /// Check for outdated dependencies
  Future<List<String>> checkOutdatedDependencies() async {
    final warnings = <String>[];

    // Note: This is a placeholder. In production, you would:
    // 1. Parse pubspec.lock
    // 2. Compare with pub.dev latest versions
    // 3. Check against vulnerability databases

    if (kDebugMode) {
      if (kDebugMode) print('\n╔════════════════════════════════════════╗');
      if (kDebugMode) print('║  📦 DEPENDENCY HEALTH CHECK           ║');
      if (kDebugMode) print('╠════════════════════════════════════════╣');
      if (kDebugMode) print('║ Critical Dependencies:');
      
      for (final entry in _criticalDependencies.entries) {
        if (kDebugMode) print('║   ✓ ${entry.key}: ${entry.value}');
      }
      
      if (kDebugMode) print('╠════════════════════════════════════════╣');
      if (kDebugMode) print('║ Recommendation:');
      if (kDebugMode) print('║   Run: flutter pub outdated');
      print('║   Check: https://pub.dev/packages');
      if (kDebugMode) print('╚════════════════════════════════════════╝\n');
    }

    return warnings;
  }

  /// Check for security vulnerabilities
  Future<List<String>> checkSecurityVulnerabilities() async {
    final vulnerabilities = <String>[];

    // Check against known vulnerabilities
    for (final entry in _knownVulnerabilities.entries) {
      vulnerabilities.add(
        'Vulnerability found in ${entry.key}: ${entry.value.join(', ')}',
      );
    }

    if (vulnerabilities.isNotEmpty && kDebugMode) {
      if (kDebugMode) print('\n⚠️  SECURITY VULNERABILITIES FOUND:');
      for (final vuln in vulnerabilities) {
        if (kDebugMode) print('   - $vuln');
      }
      if (kDebugMode) print('');
    }

    return vulnerabilities;
  }

  /// Get app version info
  Future<Map<String, String>> getAppVersionInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      
      return {
        'app_name': packageInfo.appName,
        'package_name': packageInfo.packageName,
        'version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
      };
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('Error getting app version info: $e');
      }
      return {};
    }
  }

  /// Print dependency health report
  Future<void> printHealthReport() async {
    if (!kDebugMode) return;

    final appInfo = await getAppVersionInfo();
    final outdated = await checkOutdatedDependencies();
    final vulnerabilities = await checkSecurityVulnerabilities();

    if (kDebugMode) print('\n${'=' * 60}');
    if (kDebugMode) print('📊 DEPENDENCY HEALTH REPORT');
    if (kDebugMode) print('=' * 60);
    if (kDebugMode) print('\nApp Information:');
    if (kDebugMode) print('  Name: ${appInfo['app_name']}');
    if (kDebugMode) print('  Version: ${appInfo['version']} (${appInfo['build_number']})');
    if (kDebugMode) print('  Package: ${appInfo['package_name']}');
    
    if (kDebugMode) print('\nDependency Status:');
    if (kDebugMode) print('  Critical Dependencies: ${_criticalDependencies.length}');
    if (kDebugMode) print('  Outdated Warnings: ${outdated.length}');
    if (kDebugMode) print('  Security Vulnerabilities: ${vulnerabilities.length}');
    
    if (outdated.isNotEmpty) {
      if (kDebugMode) print('\nOutdated Dependencies:');
      for (final warning in outdated) {
        if (kDebugMode) print('  ⚠️  $warning');
      }
    }
    
    if (vulnerabilities.isNotEmpty) {
      if (kDebugMode) print('\nSecurity Vulnerabilities:');
      for (final vuln in vulnerabilities) {
        if (kDebugMode) print('  🔴 $vuln');
      }
    }
    
    if (kDebugMode) print('\nRecommendations:');
    if (kDebugMode) print('  1. Run: flutter pub outdated');
    if (kDebugMode) print('  2. Update critical dependencies regularly');
    print('  3. Monitor: https://pub.dev/security-advisories');
    if (kDebugMode) print('  4. Use: dart pub global activate pana');
    print('  5. Check: https://snyk.io/ for vulnerabilities');
    
    if (kDebugMode) print('\n${'=' * 60}\n');
  }

  /// Dependency update checklist
  static List<Map<String, String>> getUpdateChecklist() {
    return [
      {
        'task': 'Check for outdated packages',
        'command': 'flutter pub outdated',
        'frequency': 'Weekly',
      },
      {
        'task': 'Update dependencies',
        'command': 'flutter pub upgrade --major-versions',
        'frequency': 'Monthly',
      },
      {
        'task': 'Check security advisories',
        'command': 'Visit pub.dev/security-advisories',
        'frequency': 'Monthly',
      },
      {
        'task': 'Run dependency analysis',
        'command': 'flutter pub deps',
        'frequency': 'Monthly',
      },
      {
        'task': 'Check for breaking changes',
        'command': 'Read CHANGELOG.md of packages',
        'frequency': 'Before updating',
      },
      {
        'task': 'Test after updates',
        'command': 'flutter test',
        'frequency': 'After each update',
      },
    ];
  }
}
