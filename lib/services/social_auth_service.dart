import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'audit_service.dart';

/// Service for social authentication (Google OAuth)
/// Handles OAuth flows via Supabase Auth
/// 
/// Note: Only Google OAuth is currently supported.
/// Apple and Facebook methods are available but not used in UI.
class SocialAuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Sign in with Google OAuth
  /// 
  /// This uses Supabase's built-in OAuth support
  /// Make sure to configure Google OAuth in Supabase Dashboard:
  /// 1. Go to Authentication > Providers > Google
  /// 2. Enable Google provider
  /// 3. Add your Google OAuth Client ID and Secret
  /// 4. Add authorized redirect URIs
  /// 
  /// Returns:
  /// - Success: true
  /// - Error: false (with error logged)
  static Future<bool> signInWithGoogle() async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🔵 [SocialAuth] Starting Google OAuth flow');
        if (kDebugMode) print('🔵 [SocialAuth] Platform: ${kIsWeb ? "Web" : "Mobile"}');
      }

      // Use external application (native browser) for proper mobile viewport handling
      // The native browser (Chrome/Safari) correctly renders Google's mobile OAuth page
      // with proper scaling and viewport settings that WebView doesn't handle well
      //
      // NOTE: If redirect page is not full width, use custom mobile-optimized page.
      // See: docs/QUICK_OAUTH_FIX.md for setup (5 minutes)
      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _getOAuthRedirectUrl(),
        authScreenLaunchMode: kIsWeb 
            ? LaunchMode.platformDefault 
            : LaunchMode.externalApplication,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SocialAuth] Google OAuth flow initiated');
        if (kDebugMode) print('📝 [SocialAuth] Response: $response');
      }

      // The actual sign-in happens when the redirect URL is called
      // We can't directly check success here since it's async via browser
      // The app will receive the callback via deep link
      return true;
    } on AuthException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Google OAuth error: ${e.message}');
        if (kDebugMode) print('❌ [SocialAuth] Status code: ${e.statusCode}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Google OAuth unknown error: $e');
      }
      return false;
    }
  }

  /// Sign in with Apple OAuth
  /// 
  /// ⚠️ DEPRECATED: Not currently used in the application
  /// 
  /// This uses Supabase's built-in OAuth support
  /// Make sure to configure Apple OAuth in Supabase Dashboard:
  /// 1. Go to Authentication > Providers > Apple
  /// 2. Enable Apple provider
  /// 3. Add your Apple OAuth credentials
  /// 
  /// Note: Apple OAuth requires iOS/macOS or web with HTTPS
  @Deprecated('Apple sign-in not currently supported')
  static Future<bool> signInWithApple() async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🔵 [SocialAuth] Starting Apple OAuth flow');
      }

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _getOAuthRedirectUrl(),
        authScreenLaunchMode: kIsWeb 
            ? LaunchMode.platformDefault 
            : LaunchMode.externalApplication,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SocialAuth] Apple OAuth flow initiated');
      }

      return true;
    } on AuthException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Apple OAuth error: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Apple OAuth unknown error: $e');
      }
      return false;
    }
  }

  /// Sign in with Facebook OAuth
  /// 
  /// ⚠️ DEPRECATED: Not currently used in the application
  /// 
  /// This uses Supabase's built-in OAuth support
  /// Make sure to configure Facebook OAuth in Supabase Dashboard:
  /// 1. Go to Authentication > Providers > Facebook
  /// 2. Enable Facebook provider
  /// 3. Add your Facebook App ID and Secret
  @Deprecated('Facebook sign-in not currently supported')
  static Future<bool> signInWithFacebook() async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🔵 [SocialAuth] Starting Facebook OAuth flow');
      }

      final response = await _client.auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: _getOAuthRedirectUrl(),
        authScreenLaunchMode: kIsWeb 
            ? LaunchMode.platformDefault 
            : LaunchMode.externalApplication,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SocialAuth] Facebook OAuth flow initiated');
      }

      return true;
    } on AuthException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Facebook OAuth error: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Facebook OAuth unknown error: $e');
      }
      return false;
    }
  }

  /// Handle OAuth callback after successful authentication
  /// This should be called when the app receives the deep link redirect
  static Future<bool> handleOAuthCallback(Uri uri) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('🔵 [SocialAuth] Handling OAuth callback');
        if (kDebugMode) print('📝 [SocialAuth] URI: $uri');
      }

      // Supabase handles the OAuth callback automatically via deep links
      // We just need to check if the user is now signed in
      final user = _client.auth.currentUser;
      if (user != null) {
        if (kDebugMode) {
          if (kDebugMode) print('✅ [SocialAuth] OAuth sign-in successful');
          if (kDebugMode) print('📝 [SocialAuth] User ID: ${user.id}');
          if (kDebugMode) print('📝 [SocialAuth] User email: ${user.email}');
        }

        // Log the OAuth sign-in
        await AuditService.logAction(
          action: 'oauth_signin',
          entityType: 'user',
          entityId: user.id,
          changes: {
            'timestamp': DateTime.now().toIso8601String(),
            'provider': user.appMetadata['provider'] ?? 'unknown',
            'email': user.email,
          },
        );

        return true;
      }

      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [SocialAuth] OAuth callback received but user not signed in');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SocialAuth] Error handling OAuth callback: $e');
      }
      return false;
    }
  }

  /// Get OAuth redirect URL
  /// Using direct deep link for seamless redirect without intermediate page
  /// 
  /// IMPORTANT: Make sure Supabase Dashboard is configured with ONLY this URL:
  /// - io.supabase.sipelor://login-callback/
  /// 
  /// Remove any other URLs (Netlify, Vercel, GitHub Pages, etc.) from Supabase
  /// to prevent redirect issues.
  static String _getOAuthRedirectUrl() {
    // Always use direct deep link - no intermediate web page
    return 'io.supabase.sipelor://login-callback/';
  }

  /// Check if user signed in via OAuth
  static bool isOAuthUser() {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    final provider = user.appMetadata['provider'] as String?;
    return provider != null && provider != 'email';
  }

  /// Get OAuth provider name
  static String? getOAuthProvider() {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    return user.appMetadata['provider'] as String?;
  }
}
