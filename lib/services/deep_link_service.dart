import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';

/// Service untuk handle deep links dan URL schemes
/// 
/// Supported schemes:
/// - sipelor:// (custom scheme)
/// - io.supabase.sipelor:// (Supabase auth callback)
/// 
/// Example links:
/// - sipelor://reset-password?token=xxx
/// - sipelor://verify-email?token=xxx
/// - sipelor://booking/booking-id-123
/// - sipelor://venue/venue-id-123
/// - sipelor://ticket/booking-id-123
/// - sipelor://chat/booking-id-123
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  BuildContext? _context;

  /// Initialize deep link handling
  /// Call this in main.dart after MaterialApp is built
  Future<void> initialize(BuildContext context) async {
    _context = context;

    try {
      // Handle initial deep link (app opened via deep link when not running)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('[DeepLink] Initial link: ${initialUri.toString()}');
        await _handleDeepLink(initialUri);
      }

      // Handle deep links while app is running
      _appLinks.uriLinkStream.listen((Uri uri) {
        debugPrint('[DeepLink] Received while running: ${uri.toString()}');
        _handleDeepLink(uri);
      }, onError: (error) {
        debugPrint('[DeepLink] Error: $error');
      });
    } catch (e) {
      debugPrint('[DeepLink] Initialization error: $e');
    }
  }

  /// Handle incoming deep link
  Future<void> _handleDeepLink(Uri uri) async {
    if (_context == null) {
      debugPrint('[DeepLink] Context not available, deferring...');
      // Defer handling until context is available
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_context != null) _handleDeepLink(uri);
      });
      return;
    }

    try {
      switch (uri.scheme) {
        case 'sipelor':
          await _handleSipelorLink(uri);
          break;
        case 'io.supabase.sipelor':
          await _handleSupabaseLink(uri);
          break;
        default:
          debugPrint('[DeepLink] Unknown scheme: ${uri.scheme}');
      }
    } catch (e) {
      debugPrint('[DeepLink] Handling error: $e');
      _showErrorSnackbar('Gagal membuka link: $e');
    }
  }

  /// Handle sipelor:// scheme links
  Future<void> _handleSipelorLink(Uri uri) async {
    if (_context == null) return;

    final path = uri.host;
    final params = uri.queryParameters;

    debugPrint('[DeepLink] Handling sipelor://$path with params: $params');

    switch (path) {
      case 'reset-password':
        final token = params['token'];
        if (token != null && token.isNotEmpty) {
          Navigator.of(_context!).pushNamed(
            '/reset-password',
            arguments: {'token': token},
          );
        } else {
          _showErrorSnackbar('Token reset password tidak valid');
        }
        break;

      case 'verify-email':
        final token = params['token'];
        if (token != null && token.isNotEmpty) {
          await _verifyEmail(token);
        } else {
          _showErrorSnackbar('Token verifikasi tidak valid');
        }
        break;

      case 'booking':
        final bookingId = uri.pathSegments.isNotEmpty 
            ? uri.pathSegments[0] 
            : params['id'];
        if (bookingId != null && bookingId.isNotEmpty) {
          // Check if user is logged in
          if (!isSupabaseInitialized || Supabase.instance.client.auth.currentSession == null) {
            _showErrorSnackbar('Silakan login terlebih dahulu');
            Navigator.of(_context!).pushReplacementNamed('/');
          } else {
            Navigator.of(_context!).pushNamed(
              '/booking-detail',
              arguments: {'bookingId': bookingId},
            );
          }
        } else {
          _showErrorSnackbar('ID booking tidak valid');
        }
        break;

      case 'ticket':
        final bookingId = uri.pathSegments.isNotEmpty 
            ? uri.pathSegments[0] 
            : params['id'];
        if (bookingId != null && bookingId.isNotEmpty) {
          if (!isSupabaseInitialized || Supabase.instance.client.auth.currentSession == null) {
            _showErrorSnackbar('Silakan login terlebih dahulu');
            Navigator.of(_context!).pushReplacementNamed('/');
          } else {
            Navigator.of(_context!).pushNamed(
              '/e-ticket',
              arguments: {'bookingId': bookingId},
            );
          }
        } else {
          _showErrorSnackbar('ID booking tidak valid');
        }
        break;

      case 'venue':
        final venueId = uri.pathSegments.isNotEmpty 
            ? uri.pathSegments[0] 
            : params['id'];
        if (venueId != null && venueId.isNotEmpty) {
          Navigator.of(_context!).pushNamed(
            '/venue-detail',
            arguments: {'venueId': venueId},
          );
        } else {
          _showErrorSnackbar('ID venue tidak valid');
        }
        break;

      case 'chat':
        final bookingId = uri.pathSegments.isNotEmpty 
            ? uri.pathSegments[0] 
            : params['bookingId'];
        if (bookingId != null && bookingId.isNotEmpty) {
          if (!isSupabaseInitialized || Supabase.instance.client.auth.currentSession == null) {
            _showErrorSnackbar('Silakan login terlebih dahulu');
            Navigator.of(_context!).pushReplacementNamed('/');
          } else {
            Navigator.of(_context!).pushNamed(
              '/user-chat',
              arguments: {'bookingId': bookingId},
            );
          }
        } else {
          _showErrorSnackbar('ID booking tidak valid');
        }
        break;

      case 'home':
      case '':
        // Navigate to home
        if (Supabase.instance.client.auth.currentSession != null) {
          Navigator.of(_context!).pushReplacementNamed('/home');
        } else {
          Navigator.of(_context!).pushReplacementNamed('/');
        }
        break;

      default:
        debugPrint('[DeepLink] Unknown path: $path');
        _showErrorSnackbar('Link tidak dikenali');
        // Navigate to home as fallback
        if (Supabase.instance.client.auth.currentSession != null) {
          Navigator.of(_context!).pushReplacementNamed('/home');
        }
    }
  }

  /// Handle io.supabase.sipelor:// scheme (auth callbacks)
  Future<void> _handleSupabaseLink(Uri uri) async {
    debugPrint('[DeepLink] Supabase auth callback received');
    debugPrint('[DeepLink] Full URI: $uri');
    
    if (uri.host == 'login-callback') {
      // OAuth callback - Supabase SDK will process the URL automatically
      // We need to wait for the session to be established
      
      debugPrint('[DeepLink] OAuth callback detected, waiting for session...');
      
      // Wait a bit for Supabase to process the OAuth callback
      await Future.delayed(const Duration(milliseconds: 800));
      
      // Check session with retry mechanism (max 3 attempts)
      int attempts = 0;
      const maxAttempts = 3;
      
      while (attempts < maxAttempts) {
        final session = Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          debugPrint('[DeepLink] OAuth successful! Session found.');
          debugPrint('[DeepLink] User ID: ${session.user.id}');
          debugPrint('[DeepLink] User email: ${session.user.email}');
          
          if (_context != null && _context!.mounted) {
            _showSuccessSnackbar('Login berhasil!');
            
            // Wait a bit for UI to be ready
            await Future.delayed(const Duration(milliseconds: 200));
            
            if (_context != null && _context!.mounted) {
              // Use pushNamedAndRemoveUntil to clear the navigation stack
              Navigator.of(_context!).pushNamedAndRemoveUntil(
                '/home',
                (route) => false,
              );
            }
          }
          return;
        }
        
        // Session not found yet, retry
        attempts++;
        debugPrint('[DeepLink] Session not found yet, attempt $attempts/$maxAttempts');
        
        if (attempts < maxAttempts) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
      // If we get here, session was not established
      debugPrint('[DeepLink] OAuth callback processed but no session found');
      _showErrorSnackbar('Login gagal. Silakan coba lagi.');
      
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushReplacementNamed('/');
      }
    }
  }

  /// Verify email with token
  Future<void> _verifyEmail(String token) async {
    try {
      debugPrint('[DeepLink] Verifying email with token');
      
      // Supabase automatically handles email verification when the link is clicked
      // We just need to check if the user is now verified
      
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.auth.refreshSession();
        
        final updatedUser = Supabase.instance.client.auth.currentUser;
        if (updatedUser?.emailConfirmedAt != null) {
          _showSuccessSnackbar('Email berhasil diverifikasi!');
          
          // Navigate to home if logged in
          if (_context != null) {
            Navigator.of(_context!).pushReplacementNamed('/home');
          }
        } else {
          _showErrorSnackbar('Verifikasi email gagal. Silakan coba lagi.');
        }
      } else {
        _showInfoSnackbar('Silakan login untuk melanjutkan');
        if (_context != null) {
          Navigator.of(_context!).pushReplacementNamed('/');
        }
      }
    } catch (e) {
      debugPrint('[DeepLink] Email verification error: $e');
      _showErrorSnackbar('Error verifikasi email: $e');
    }
  }

  /// Show success snackbar
  void _showSuccessSnackbar(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Show info snackbar
  void _showInfoSnackbar(String message) {
    if (_context == null) return;
    
    ScaffoldMessenger.of(_context!).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Generate deep link for sharing
  static String generateDeepLink(String path, {Map<String, String>? params}) {
    final uri = Uri(
      scheme: 'sipelor',
      host: path,
      queryParameters: params,
    );
    return uri.toString();
  }

  /// Generate booking deep link
  static String generateBookingLink(String bookingId) {
    return 'sipelor://booking/$bookingId';
  }

  /// Generate e-ticket deep link
  static String generateTicketLink(String bookingId) {
    return 'sipelor://ticket/$bookingId';
  }

  /// Generate venue deep link
  static String generateVenueLink(String venueId) {
    return 'sipelor://venue/$venueId';
  }

  /// Generate chat deep link
  static String generateChatLink(String bookingId) {
    return 'sipelor://chat/$bookingId';
  }
}
