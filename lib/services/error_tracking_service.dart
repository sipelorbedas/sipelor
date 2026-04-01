import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Simple transaction handle returned when Sentry is unavailable.
class _NoopTransaction {
  final String name;
  final String operation;
  bool _finished = false;
  _NoopTransaction(this.name, this.operation);
  bool get finished => _finished;
  void finish() => _finished = true;
}

/// Service for error tracking and monitoring using Sentry.
/// Handles crash reporting, error logging, and performance monitoring.
class ErrorTrackingService {
  static bool _initialized = false;
  static ISentrySpan? _activeSpan;

  // ─── Initialization ───────────────────────────────────────────────────────

  /// Initialize Sentry for error tracking.
  ///
  /// Configure Sentry DSN:
  /// - Development: Use separate DSN or disable
  /// - Production: Use production DSN from environment variable
  ///
  /// Get DSN from: https://sentry.io/settings/[org]/projects/[project]/keys/
  static Future<void> initialize() async {
    if (_initialized) {
      if (kDebugMode) print('⚠️  [ErrorTracking] Already initialized, skipping');
      return;
    }

    try {
      const sentryDsn = String.fromEnvironment('SENTRY_DSN', defaultValue: '');

      if (sentryDsn.isEmpty) {
        if (kDebugMode) {
          print('ℹ️  [ErrorTracking] Sentry DSN not configured, error tracking disabled');
          print('ℹ️  [ErrorTracking] To enable: Set SENTRY_DSN environment variable');
        }
        _initialized = true;
        return;
      }

      // Ambil versi app secara dinamis dari package info
      final packageInfo = await PackageInfo.fromPlatform();
      final releaseString =
          '${packageInfo.packageName}@${packageInfo.version}+${packageInfo.buildNumber}';

      await SentryFlutter.init(
        (options) {
          options.dsn = sentryDsn;
          options.environment = kDebugMode ? 'development' : 'production';
          options.sampleRate = kDebugMode ? 1.0 : 0.5;
          options.tracesSampleRate = 0.1;
          options.enableAutoSessionTracking = true;
          options.attachThreads = true;
          options.attachScreenshot = true;
          options.maxCacheItems = 30;
          options.maxBreadcrumbs = 50;
          options.release = releaseString; // Dinamis — otomatis update setiap rilis
          options.debug = kDebugMode;

          options.beforeSend = (event, hint) {
            // Di debug mode, jangan kirim ke Sentry (tampilkan di console saja)
            if (kDebugMode) return null;
            final message = event.message?.formatted ?? '';
            final exceptionMsg = event.throwable?.toString() ?? '';
            if (_containsSensitiveData(message) || _containsSensitiveData(exceptionMsg)) {
              return null;
            }
            return event;
          };
        },
        // appRunner wajib kosong karena runApp() sudah dipanggil di main()
        // SentryFlutter.init hanya digunakan untuk konfigurasi SDK saja
        appRunner: () {},
      );

      _initialized = true;
      if (kDebugMode) print('✅ [ErrorTracking] Sentry initialized successfully');
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] Failed to initialize Sentry: $e');
    }
  }

  // ─── Exception & Message Capture ──────────────────────────────────────────

  /// Capture an exception directly (alias wrapping logError).
  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
  }) async {
    if (!_initialized) {
      if (kDebugMode) print('⚠️  [ErrorTracking] captureException called before init: $exception');
      return;
    }
    try {
      await Sentry.captureException(exception, stackTrace: stackTrace);
      if (kDebugMode) print('📝 [ErrorTracking] Exception captured: $exception');
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] captureException failed: $e');
    }
  }

  /// Capture a plain message.
  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
  }) async {
    if (!_initialized) {
      if (kDebugMode) print('⚠️  [ErrorTracking] captureMessage before init: $message');
      return;
    }
    if (_containsSensitiveData(message)) {
      if (kDebugMode) print('🔒 [ErrorTracking] Sensitive message filtered');
      return;
    }
    try {
      await Sentry.captureMessage(message, level: level);
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] captureMessage failed: $e');
    }
  }

  // ─── Contextual Logging ───────────────────────────────────────────────────

  /// Log an error with an optional [exception] and [stackTrace].
  ///
  /// Signature is intentionally flexible to serve both internal usage
  /// and the test suite:
  ///   logError('context', exception, stackTrace)
  ///   logError(exception, stackTrace)
  static Future<void> logError(
    dynamic error, [
    dynamic exception,
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  ]) async {
    if (!_initialized) {
      if (kDebugMode) print('⚠️  [ErrorTracking] Not initialized, logging to console: $error');
      return;
    }
    try {
      // If second arg is a StackTrace, treat (error, stackTrace) usage
      final actualException = exception is StackTrace ? null : exception;
      final actualTrace = exception is StackTrace ? exception : stackTrace;

      await Sentry.captureException(
        actualException ?? error,
        stackTrace: actualTrace,
        withScope: (scope) {
          if (error is String) scope.setTag('context', error);
          if (extra != null) {
            for (var entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
        },
      );
      if (kDebugMode) print('📝 [ErrorTracking] Error logged: $error');
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] logError failed: $e');
    }
  }

  /// Log a plain message to Sentry.
  static Future<void> logMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    if (!_initialized) return;
    try {
      await Sentry.captureMessage(
        message,
        level: level,
        withScope: (scope) {
          if (extra != null) {
            for (var entry in extra.entries) {
              scope.setExtra(entry.key, entry.value);
            }
          }
        },
      );
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] logMessage failed: $e');
    }
  }

  // ─── Breadcrumbs ──────────────────────────────────────────────────────────

  /// Add a breadcrumb for tracking user actions.
  static void addBreadcrumb({
    required String message,
    String? category,
    Map<String, dynamic>? data,
    SentryLevel level = SentryLevel.info,
  }) {
    if (!_initialized) return;
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: level,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] addBreadcrumb failed: $e');
    }
  }

  // ─── User Context ─────────────────────────────────────────────────────────

  /// Set user context for Sentry (verbose alias).
  static void setUser({
    required String id,
    String? email,
    String? username,
    Map<String, dynamic>? data,
  }) {
    if (!_initialized) return;
    try {
      Sentry.configureScope(
        (scope) => scope.setUser(SentryUser(
          id: id,
          email: email,
          username: username,
          data: data,
        )),
      );
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] setUser failed: $e');
    }
  }

  /// Set user context — test-friendly alias for [setUser].
  static void setUserContext({
    required String userId,
    String? email,
    String? username,
    Map<String, dynamic>? data,
  }) {
    setUser(id: userId, email: email, username: username, data: data);
  }

  /// Clear user context.
  static void clearUser() {
    if (!_initialized) return;
    try {
      Sentry.configureScope((scope) => scope.setUser(null));
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] clearUser failed: $e');
    }
  }

  /// Clear user context — test-friendly alias for [clearUser].
  static void clearUserContext() => clearUser();

  // ─── Tags ─────────────────────────────────────────────────────────────────

  /// Set a global tag on the Sentry scope.
  static void setTag(String key, String value) {
    if (!_initialized) return;
    try {
      Sentry.configureScope((scope) => scope.setTag(key, value));
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] setTag failed: $e');
    }
  }

  // ─── Performance Transactions ─────────────────────────────────────────────

  /// Start a performance transaction.
  ///
  /// Always returns a non-null handle: either a real [ISentrySpan] or a
  /// [_NoopTransaction] when Sentry is not initialized.
  static Object startTransaction(String name, String operation) {
    if (!_initialized) {
      return _NoopTransaction(name, operation);
    }
    try {
      final span = Sentry.startTransaction(name, operation);
      _activeSpan = span;
      return span;
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] startTransaction failed: $e');
      return _NoopTransaction(name, operation);
    }
  }

  /// Finish a transaction returned by [startTransaction].
  static Future<void> finishTransaction(dynamic transaction) async {
    if (transaction == null) return;
    try {
      if (transaction is ISentrySpan) {
        await transaction.finish();
      } else if (transaction is _NoopTransaction) {
        transaction.finish();
      }
    } catch (e) {
      if (kDebugMode) print('❌ [ErrorTracking] finishTransaction failed: $e');
    }
  }

  // ─── Sensitive Data Filter ────────────────────────────────────────────────

  static bool _containsSensitiveData(String message) {
    final lower = message.toLowerCase();
    const sensitivePatterns = [
      'password', 'token', 'secret', 'api_key', 'apikey',
      'auth', 'authorization', 'bearer', 'credit_card', 'cvv', 'ssn',
    ];
    return sensitivePatterns.any(lower.contains);
  }
}
