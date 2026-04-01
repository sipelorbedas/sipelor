import 'package:flutter/foundation.dart';

/// Build Configuration
/// 
/// Manages different build environments and their configurations.
/// Supports: development, staging, production
/// 
/// Usage:
/// ```dart
/// if (BuildConfig.isProduction) {
///   // Production-only code
/// }
/// ```
class BuildConfig {
  // ==================== Environment Detection ====================
  
  /// Current environment name
  /// Set via --dart-define=ENVIRONMENT=production
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );
  
  /// Check if running in production
  static bool get isProduction {
    // kReleaseMode is sufficient — if ENVIRONMENT not passed, still treat as production
    return kReleaseMode;
  }
  
  /// Check if running in staging
  static bool get isStaging {
    return environment == 'staging';
  }
  
  /// Check if running in development
  static bool get isDevelopment {
    return environment == 'development' || kDebugMode;
  }
  
  // ==================== Feature Flags ====================
  
  /// Enable SSL certificate pinning
  /// Production: Always enabled
  /// Development: Can be toggled via --dart-define
  static bool get sslPinningEnabled {
    if (isProduction) {
      return true; // Always on in production
    }
    
    const pinning = String.fromEnvironment('ENABLE_SSL_PINNING');
    return pinning.toLowerCase() == 'true';
  }
  
  /// Enable verbose logging
  static bool get verboseLogging {
    if (isProduction) {
      return false; // Never in production
    }
    
    const verbose = String.fromEnvironment('VERBOSE_LOGGING');
    return verbose.toLowerCase() == 'true' || isDevelopment;
  }
  
  /// Enable debug tools
  static bool get debugToolsEnabled {
    return isDevelopment || isStaging;
  }

  /// Enable error tracking (Sentry) — always true when DSN is configured
  static bool get errorTrackingEnabled => true;

  /// Enable deep linking (always enabled)
  static bool get deepLinkingEnabled => true;

  /// Enable offline caching mode
  static bool get offlineModeEnabled => true;

  /// Enable auto-logout on inactivity
  static bool get autoLogoutEnabled => true;

  /// Auto-logout inactivity window in minutes
  static int get autoLogoutMinutes => 15;

  /// Maximum upload file size in MB
  static int get maxUploadSizeMB => 10;

  /// JPEG compression quality (0–100)
  static int get imageCompressionQuality => 80;

  /// Application display name
  static const String appName = 'SIPELOR BEDAS';

  /// Application semantic version (major.minor.patch)
  static const String appVersion = '1.0.0';

  /// Build number
  static const int appBuildNumber = 2;

  /// Cache expiry duration in minutes
  static int get cacheExpiryMinutes => 30;

  // ==================== Deep Link / Auth Configuration ====================

  /// Email redirect URL used in Supabase signUp(emailRedirectTo: ...)
  ///
  /// IMPORTANT: This must be an HTTPS URL pointing to landing/auth/callback.html
  /// because Chrome Custom Tab (used by Gmail) blocks HTTP 302 redirects to
  /// custom schemes (sipelor://), but DOES allow JS-initiated redirects.
  ///
  /// Setup steps:
  ///   1. Host landing/auth/callback.html at an HTTPS URL
  ///      (e.g. GitHub Pages: https://<user>.github.io/<repo>/auth/callback.html)
  ///   2. Add that URL to Supabase Dashboard → Auth → URL Configuration → Redirect URLs
  ///   3. Pass the URL via:
  ///      flutter run --dart-define=EMAIL_REDIRECT_URL=https://yoursite.com/auth/callback.html
  ///
  /// Fallback: uses sipelor://callback directly (works for direct deep link taps,
  /// but may fail inside Gmail Chrome Custom Tab on some Android versions).
  static const String emailRedirectUrl = String.fromEnvironment(
    'EMAIL_REDIRECT_URL',
    defaultValue: 'sipelor://callback', // Fallback — replace with your hosted URL
  );

  // ==================== API Configuration ====================

  /// API base URL (if different per environment)
  static String get apiBaseUrl {
    const customUrl = String.fromEnvironment('API_BASE_URL');
    if (customUrl.isNotEmpty) {
      return customUrl;
    }
    
    // Use Supabase URL from environment
    return ''; // Supabase handles this internally
  }
  
  /// API timeout (seconds)
  static int get apiTimeout {
    const timeout = String.fromEnvironment('API_TIMEOUT');
    if (timeout.isNotEmpty) {
      return int.tryParse(timeout) ?? 30;
    }
    return 30;
  }
  
  // ==================== Build Information ====================
  
  /// Get build configuration summary
  static Map<String, dynamic> getSummary() {
    return {
      'environment': environment,
      'is_production': isProduction,
      'is_staging': isStaging,
      'is_development': isDevelopment,
      'ssl_pinning': sslPinningEnabled,
      'verbose_logging': verboseLogging,
      'debug_tools': debugToolsEnabled,
      'build_mode': kReleaseMode ? 'release' : 'debug',
    };
  }
  
  /// Print build configuration (debug only)
  static void printConfig() {
    if (!kDebugMode) return;
    
    if (kDebugMode) print('');
    if (kDebugMode) print('╔════════════════════════════════════════════════════════════╗');
    if (kDebugMode) print('║              🚀 SIPELOR BUILD CONFIGURATION              ║');
    if (kDebugMode) print('╠════════════════════════════════════════════════════════════╣');
    if (kDebugMode) print('║ Environment      : ${environment.padRight(36)} ║');
    if (kDebugMode) print('║ Build Mode       : ${(kReleaseMode ? 'Release' : 'Debug').padRight(36)} ║');
    if (kDebugMode) print('║ SSL Pinning      : ${(sslPinningEnabled ? '✅ Enabled' : '❌ Disabled').padRight(36)} ║');
    if (kDebugMode) print('║ Verbose Logging  : ${(verboseLogging ? '✅ Enabled' : '❌ Disabled').padRight(36)} ║');
    if (kDebugMode) print('║ Debug Tools      : ${(debugToolsEnabled ? '✅ Enabled' : '❌ Disabled').padRight(36)} ║');
    if (kDebugMode) print('╚════════════════════════════════════════════════════════════╝');
    if (kDebugMode) print('');
  }
}
