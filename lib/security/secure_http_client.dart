/// Secure HTTP Client with built-in security features
/// Implements certificate pinning, request signing, and security headers
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:http_certificate_pinning/http_certificate_pinning.dart';
import '../config/ssl_config.dart';
import 'request_signing.dart';
import 'security_headers_validator.dart';

/// Secure HTTP client with comprehensive security features
class SecureHttpClient {
  late final Dio _dio;
  final String baseUrl;
  final String? apiKey;
  final String? secretKey;
  final bool enableCertificatePinning;

  SecureHttpClient({
    required this.baseUrl,
    this.apiKey,
    this.secretKey,
    this.enableCertificatePinning = true,
    Duration? timeout,
  }) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: timeout ?? const Duration(seconds: 30),
      receiveTimeout: timeout ?? const Duration(seconds: 30),
      sendTimeout: timeout ?? const Duration(seconds: 30),
      headers: SecurityHeadersValidator.createSecurityHeaders(),
    ));

    // Add certificate pinning interceptor if enabled
    // Uses CertificatePinningInterceptor (recommended Dio integration)
    if (enableCertificatePinning && SSLConfig.sslPinningEnabled) {
      final fingerprints = SSLConfig.certificatePins
          .map((pin) => pin.replaceFirst('sha256/', ''))
          .toList();
      _dio.interceptors.add(CertificatePinningInterceptor(
        allowedSHAFingerprints: fingerprints,
        timeout: SSLConfig.sslHandshakeTimeout,
      ));
    }

    _setupInterceptors();
  }

  /// Setup request/response interceptors
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _onRequest(options);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _onResponse(response);
          return handler.next(response);
        },
        onError: (error, handler) {
          _onError(error);
          return handler.next(error);
        },
      ),
    );
  }

  /// Pre-process requests
  void _onRequest(RequestOptions options) {
    // Validate URL security
    final uri = Uri.parse(options.uri.toString());
    SecurityHeadersValidator.validateConnection(uri: uri);
    SecurityHeadersValidator.checkSensitiveDataInUrl(uri);

    // Add request signing if API keys are provided
    if (apiKey != null && secretKey != null) {
      final signedHeaders = RequestSigning.createSignedHeaders(
        method: options.method,
        path: options.path,
        body: options.data is Map<String, dynamic>
            ? options.data as Map<String, dynamic>
            : null,
        apiKey: apiKey!,
        secretKey: secretKey!,
      );
      options.headers.addAll(signedHeaders);
    }

    // Add security headers
    options.headers.addAll({
      'User-Agent': 'SIPELOR-Mobile/1.0.0',
      'X-Requested-With': 'XMLHttpRequest',
    });

    if (kDebugMode) {
      if (kDebugMode) print('🌐 Request: ${options.method} ${options.path}');
    }
  }

  /// Post-process responses
  void _onResponse(Response response) {
    // Validate security headers in response
    final headers = <String, String>{};
    response.headers.forEach((key, values) {
      headers[key] = values.join(', ');
    });

    final validation = SecurityHeadersValidator.validateResponseHeaders(headers);

    if (!validation.isSecure && kDebugMode) {
      if (kDebugMode) print('⚠️  Insecure response headers detected');
    }

    if (kDebugMode) {
      if (kDebugMode) {
        print(
          '✅ Response: ${response.statusCode} ${response.requestOptions.path}');
      }
    }
  }

  /// Handle errors
  void _onError(DioException error) {
    if (kDebugMode) {
      if (kDebugMode) print('❌ HTTP Error: ${error.message}');
      if (error.response != null) {
        if (kDebugMode) print('   Status: ${error.response?.statusCode}');
      }
    }
  }

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }

  /// Get underlying Dio instance (for advanced usage)
  Dio get dio => _dio;
}
