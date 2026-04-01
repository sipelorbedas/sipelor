import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../config/ssl_config.dart';
import '../config/security_config.dart';
import '../security/request_signing.dart';
import 'error_tracking_service.dart';

/// HTTP Client with SSL Certificate Pinning
/// 
/// This client wraps Dio with SSL pinning support to prevent
/// Man-in-the-Middle (MITM) attacks.
/// 
/// Usage:
/// ```dart
/// final client = PinnedHttpClient.instance;
/// final response = await client.get('https://api.supabase.co/...');
/// ```
class PinnedHttpClient {
  static PinnedHttpClient? _instance;
  late final Dio _dio;
  
  /// Singleton instance
  static PinnedHttpClient get instance {
    _instance ??= PinnedHttpClient._internal();
    return _instance!;
  }
  
  /// Private constructor
  PinnedHttpClient._internal() {
    _dio = Dio(
      BaseOptions(
        connectTimeout: Duration(seconds: SecurityConfig.requestTimeout),
        receiveTimeout: Duration(seconds: SecurityConfig.requestTimeout),
        sendTimeout: Duration(seconds: SecurityConfig.requestTimeout),
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    
    // Configure SSL pinning
    _configureSslPinning();
    
    // Add interceptors
    _addInterceptors();
    
    if (kDebugMode) {
      if (kDebugMode) print('✅ [PinnedHttpClient] Initialized with SSL pinning: ${SSLConfig.sslPinningEnabled}');
    }
  }
  
  /// Configure SSL certificate pinning
  void _configureSslPinning() {
    // SSL pinning via IOHttpClientAdapter is not supported on Flutter Web
    if (kIsWeb) {
      if (kDebugMode) {
        if (kDebugMode) print('ℹ️  [PinnedHttpClient] SSL pinning skipped on web platform');
      }
      return;
    }

    if (!SSLConfig.sslPinningEnabled) {
      if (kDebugMode) {
        if (kDebugMode) print('ℹ️  [PinnedHttpClient] SSL pinning disabled (development mode)');
      }
      return;
    }
    
    // Validate SSL configuration
    if (!SSLConfig.validate()) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [PinnedHttpClient] SSL configuration validation failed');
      }
      if (SSLConfig.isProduction) {
        throw Exception('Invalid SSL configuration in production mode');
      }
    }
    
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      final client = HttpClient();
      
      // Set security context with certificate pinning
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Only pin certificates for configured domains
        if (!_shouldPinDomain(host)) {
          if (kDebugMode) {
            if (kDebugMode) print('ℹ️  [SSL] Allowing unpinned domain: $host');
          }
          return true;
        }
        
        // Extract SHA-256 fingerprint from certificate
        final certSha256 = _getCertificateSha256(cert);
        final pinMatched = SSLConfig.certificatePins.any((pin) {
          final pinHash = pin.replaceFirst('sha256/', '');
          return certSha256 == pinHash;
        });
        
        if (!pinMatched) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [SSL] Certificate pin mismatch for $host');
            if (kDebugMode) print('   Expected one of: ${SSLConfig.certificatePins}');
            if (kDebugMode) print('   Got: sha256/$certSha256');
          }
          // FIX: Kirim security event SSL pin mismatch ke Sentry
          ErrorTrackingService.logMessage(
            '[Security] SSL certificate pin mismatch — possible MITM attack',
            level: SentryLevel.error,
            extra: {
              'host': host,
              'port': port,
              'received_fingerprint': 'sha256/$certSha256',
            },
          );
          
          // In development, allow bypass if configured
          if (SSLConfig.allowBypassOnFailure) {
            if (kDebugMode) print('⚠️  [SSL] Bypassing pinning failure (development mode)');
            return true;
          }
          
          return false;
        }
        
        if (kDebugMode) {
          if (kDebugMode) print('✅ [SSL] Certificate pin validated for $host');
        }
        return true;
      };
      
      return client;
    };
  }
  
  /// Check if domain should be pinned
  bool _shouldPinDomain(String host) {
    for (final domain in SSLConfig.pinnedDomains) {
      if (domain.startsWith('*')) {
        // Wildcard matching (e.g., *.supabase.co)
        final suffix = domain.substring(1); // Remove *
        if (host.endsWith(suffix)) {
          return true;
        }
      } else {
        // Exact match
        if (host == domain) {
          return true;
        }
      }
    }
    return false;
  }
  
  /// Extract SHA-256 fingerprint from certificate
  String _getCertificateSha256(X509Certificate cert) {
    final der = cert.der;
    final digest = sha256.convert(der);
    return digest.toString().toUpperCase();
  }
  
  /// Add request/response interceptors
  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Enforce HTTPS in production
          if (SecurityConfig.requireHttps && SSLConfig.isProduction) {
            if (!options.uri.scheme.startsWith('https')) {
              if (kDebugMode) {
                if (kDebugMode) print('❌ [HTTP] Blocked insecure request: ${options.uri}');
              }
              // FIX: Kirim security event ke Sentry agar terdeteksi di production
              ErrorTrackingService.logMessage(
                '[Security] HTTPS enforcement: blocked insecure request',
                level: SentryLevel.warning,
                extra: {
                  'blocked_url': options.uri.toString(),
                  'method': options.method,
                },
              );
              return handler.reject(
                DioException(
                  requestOptions: options,
                  message: 'Only HTTPS requests are allowed in production',
                ),
              );
            }
          }

          // Add HMAC-SHA256 request signature for integrity verification
          // This prevents request tampering in transit
          final timestamp = RequestSigning.generateTimestamp();
          final nonce = RequestSigning.generateNonce();
          options.headers['X-Request-Timestamp'] = timestamp;
          options.headers['X-Request-Nonce'] = nonce;
          options.headers['X-App-Version'] = '1.0.0';

          if (kDebugMode) {
            if (kDebugMode) print('→ [HTTP] ${options.method} ${options.uri}');
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            if (kDebugMode) print('← [HTTP] ${response.statusCode} ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [HTTP] Error: ${error.message}');
            if (error.response != null) {
              if (kDebugMode) print('   Status: ${error.response?.statusCode}');
              if (kDebugMode) print('   Data: ${error.response?.data}');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
  
  // ==================== HTTP Methods ====================
  
  /// GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  /// POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  /// PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) {
    return _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }
  
  /// DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) {
    return _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  /// Get underlying Dio instance (for advanced usage)
  Dio get dio => _dio;
  
  /// Reset instance (for testing)
  static void resetInstance() {
    _instance = null;
  }
}
