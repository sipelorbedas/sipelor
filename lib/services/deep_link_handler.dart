/// Deep Link Handler Service for SIPELOR BEDAS
/// 
/// Handles deep links from:
/// - Email verification links (via web redirect page)
/// - Password reset links
/// - Magic link authentication
/// - OAuth callbacks (Google, Apple, etc.)
/// 
/// Deep link schemes:
/// - sipelor://callback?code=XXX&type=signup  → PKCE flow (via web redirect page)
/// - sipelor://callback#access_token=XXX       → Legacy implicit flow
/// - sipelor://reset-password                  → Password reset
/// - sipelor://auth/callback                   → Authentication callback
/// - io.supabase.sipelor://login-callback      → OAuth callback
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

class DeepLinkHandler {
  static final DeepLinkHandler _instance = DeepLinkHandler._internal();
  factory DeepLinkHandler() => _instance;
  DeepLinkHandler._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;

  /// Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    _context = context;

    // Handle deep link when app is already running (foreground/background)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      if (kDebugMode) {
        if (kDebugMode) print('🔗 [DeepLink] Received while running: $uri');
      }
      _handleDeepLink(uri);
    }, onError: (err) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] Stream error: $err');
      }
    });

    // Handle deep link when app starts from terminated state
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) {
          if (kDebugMode) print('🔗 [DeepLink] Initial (cold start): $initialUri');
        }
        // Small delay to ensure the app UI is fully ready
        await Future.delayed(const Duration(milliseconds: 500));
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] Error getting initial link: $e');
      }
    }
  }

  /// Main deep link dispatcher
  Future<void> _handleDeepLink(Uri uri) async {
    if (kDebugMode) {
      if (kDebugMode) print('🔗 [DeepLink] Processing: $uri');
      if (kDebugMode) print('   Scheme : ${uri.scheme}');
      if (kDebugMode) print('   Host   : ${uri.host}');
      if (kDebugMode) print('   Path   : ${uri.path}');
      if (kDebugMode) print('   Query  : ${uri.queryParameters}');
      if (kDebugMode) print('   Fragment: ${uri.fragment}');
    }

    try {
      // ── Parse parameters from both query string AND fragment ────────────────
      // Fragment params (legacy implicit flow):
      //   sipelor://callback#access_token=XXX&type=signup
      // Query params (PKCE flow via web redirect page):
      //   sipelor://callback?code=XXX&type=signup
      final fragmentParams = uri.fragment.isNotEmpty
          ? Uri.splitQueryString(uri.fragment)
          : <String, String>{};

      final type = uri.queryParameters['type'] ?? fragmentParams['type'];
      final error = uri.queryParameters['error'] ?? fragmentParams['error'];
      final errorDescription = uri.queryParameters['error_description'] ??
          fragmentParams['error_description'];

      // ── Error first ─────────────────────────────────────────────────────────
      if (error != null) {
        _handleError(error, errorDescription);
        return;
      }

      // ── OAuth callback (io.supabase.sipelor://login-callback) ────────────────
      if (uri.scheme == 'io.supabase.sipelor' && uri.host == 'login-callback') {
        await _handleOAuthCallback(uri);
        return;
      }

      // ── Password reset ───────────────────────────────────────────────────────
      if (uri.path == '/reset-password' || uri.host == 'reset-password') {
        await _handlePasswordReset(uri);
        return;
      }

      // ── Auth / email verification callback ──────────────────────────────────
      final isCallbackPath = uri.path == '/callback' ||
          uri.path == '/auth/callback' ||
          uri.host == 'callback' ||
          uri.host == 'auth';

      if (isCallbackPath) {
        await _handleAuthCallback(uri, type, fragmentParams);
        return;
      }

      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [DeepLink] Unhandled path: ${uri.path}, host: ${uri.host}');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] Unhandled exception: $e');
      }
      _showError('Error membuka link: $e');
    }
  }

  /// Handle auth callback — supports both PKCE (code) and implicit (access_token) flows.
  ///
  /// PKCE flow comes from the web redirect page (auth-callback.html):
  ///   sipelor://callback?code=XXX&type=signup
  ///
  /// Implicit flow (legacy):
  ///   sipelor://callback#access_token=XXX&type=signup
  Future<void> _handleAuthCallback(
    Uri uri,
    String? type,
    Map<String, String> fragmentParams,
  ) async {
    if (kDebugMode) {
      if (kDebugMode) print('🔐 [DeepLink] Auth callback — type: $type');
    }

    try {
      final supabase = Supabase.instance.client;

      // Detect flow type
      final hasCode = uri.queryParameters.containsKey('code');
      final hasAccessToken = fragmentParams.containsKey('access_token');

      if (hasCode) {
        // ── PKCE flow: exchange code for session ─────────────────────────────
        if (kDebugMode) {
          if (kDebugMode) print('🔑 [DeepLink] PKCE flow — exchanging code...');
        }
        await supabase.auth.getSessionFromUrl(uri);
      } else if (hasAccessToken) {
        // ── Implicit flow: set session from tokens in fragment ───────────────
        if (kDebugMode) {
          if (kDebugMode) print('🔑 [DeepLink] Implicit flow — setting session from tokens...');
        }
        await supabase.auth.getSessionFromUrl(uri);
      } else {
        if (kDebugMode) {
          if (kDebugMode) {
            print('⚠️  [DeepLink] Auth callback received with no code or token. '
              'Checking current session...');
          }
        }
        // Maybe the session was already set by Supabase SDK — check and navigate
        final session = supabase.auth.currentSession;
        if (session != null) {
          _showSuccess('Login berhasil!');
          _navigateToHome();
        }
        return;
      }

      // ── Navigate based on type ───────────────────────────────────────────────
      if (type == 'recovery') {
        if (kDebugMode) {
          if (kDebugMode) print('🔑 [DeepLink] Password recovery — navigating to reset screen');
        }
        _navigateToResetPassword();
      } else {
        // signup, magiclink, email_change, or generic
        final successMsg = type == 'signup'
            ? 'Email berhasil diverifikasi! 🎉'
            : type == 'email_change'
                ? 'Email berhasil diubah!'
                : 'Login berhasil!';

        if (kDebugMode) {
          if (kDebugMode) print('✅ [DeepLink] Auth success — type: $type');
        }
        _showSuccess(successMsg);
        _navigateToHome();
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] Auth callback error: $e');
      }
      _showError('Gagal memverifikasi: $e');
    }
  }

  /// Handle password reset callback
  Future<void> _handlePasswordReset(Uri uri) async {
    if (kDebugMode) {
      if (kDebugMode) print('🔑 [DeepLink] Password reset callback');
    }

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.auth.getSessionFromUrl(uri);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [DeepLink] Password reset session set for ${response.session.user.email}');
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushReplacementNamed(
          '/reset-password',
          arguments: {'token': response.session.accessToken},
        );
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] Password reset error: $e');
      }
      _showError('Gagal membuka halaman reset password: $e');
    }
  }

  /// Handle OAuth callback (Google, Apple, Facebook)
  Future<void> _handleOAuthCallback(Uri uri) async {
    if (kDebugMode) {
      if (kDebugMode) print('🔐 [DeepLink] OAuth callback: $uri');
    }

    try {
      await Future.delayed(const Duration(milliseconds: 800));

      // Retry up to 3 times waiting for Supabase to set the session
      for (int attempt = 1; attempt <= 3; attempt++) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          if (kDebugMode) {
            if (kDebugMode) {
              print('✅ [DeepLink] OAuth session established '
                '(attempt $attempt) — ${session.user.email}');
            }
          }
          await Future.delayed(const Duration(milliseconds: 200));
          _showSuccess('Login berhasil!');
          _navigateToHome();
          return;
        }

        if (kDebugMode) {
          if (kDebugMode) print('⏳ [DeepLink] OAuth session not ready, attempt $attempt/3');
        }
        if (attempt < 3) await Future.delayed(const Duration(milliseconds: 500));
      }

      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] OAuth — no session after 3 attempts');
      }
      _showError('Login gagal. Silakan coba lagi.');
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [DeepLink] OAuth error: $e');
      }
      _showError('Error saat login: $e');
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushReplacementNamed('/login');
      }
    }
  }

  /// Handle error parameter in deep link URL
  void _handleError(String error, String? description) {
    if (kDebugMode) {
      if (kDebugMode) print('❌ [DeepLink] Error param: $error — $description');
    }

    final message = description ??
        (error == 'access_denied'
            ? 'Akses ditolak'
            : error == 'invalid_request'
                ? 'Link tidak valid atau sudah kedaluwarsa'
                : 'Terjadi kesalahan');

    _showError(message);
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _navigateToHome() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/home',
          (route) => false,
        );
      }
    });
  }

  void _navigateToResetPassword() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/reset-password',
          (route) => false,
        );
      }
    });
  }

  // ── Snackbar helpers ──────────────────────────────────────────────────────

  void _showSuccess(String message) {
    if (_context == null || !_context!.mounted) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showError(String message) {
    if (_context == null || !_context!.mounted) return;
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Clean up resources
  void dispose() {
    _linkSubscription?.cancel();
    _context = null;
  }
}
