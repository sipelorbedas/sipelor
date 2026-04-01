import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user_role.dart';

/// Authentication guard utilities for role-based access control
class AuthGuard {
  /// Check if user is logged in, redirect to login if not
  static Future<bool> requireAuth(BuildContext context) async {
    if (!SupabaseService.isLoggedIn) {
      // Redirect to login screen
      Navigator.of(context).pushReplacementNamed('/login');
      return false;
    }
    return true;
  }

  /// Check if user is admin, show error if not
  static Future<bool> requireAdmin(
    BuildContext context, {
    bool showError = true,
  }) async {
    if (!SupabaseService.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed('/');
      return false;
    }

    final isAdmin = await SupabaseService.isAdmin();
    if (!isAdmin) {
      if (showError) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akses ditolak. Hanya admin yang dapat mengakses halaman ini.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    return true;
  }

  /// Get current user role
  static Future<UserRole> getCurrentRole() async {
    return await SupabaseService.getCurrentUserRole();
  }

  /// Navigate to appropriate screen based on role
  static Future<void> navigateByRole(BuildContext context) async {
    // Check if context is still mounted
    if (!context.mounted) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [AuthGuard] Context not mounted, skipping navigation');
      }
      return;
    }

    if (!SupabaseService.isLoggedIn) {
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
      return;
    }

    // Clear cache to ensure fresh data
    final user = SupabaseService.currentUser;
    if (user != null) {
      SupabaseService.clearProfileCache(user.id);
      if (kDebugMode) {
        if (kDebugMode) print('🔄 [AuthGuard] Cleared profile cache for user: ${user.id}');
      }
    }

    final role = await SupabaseService.getCurrentUserRole();
    
    if (kDebugMode) {
      if (kDebugMode) print('🔍 [AuthGuard] User role: ${role.toString()}');
      if (kDebugMode) print('🔍 [AuthGuard] Is admin: ${role.isAdmin}');
      if (kDebugMode) print('🔍 [AuthGuard] Role name: ${role.displayName}');
    }

    // Check context again after async operation
    if (!context.mounted) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [AuthGuard] Context not mounted after role check, skipping navigation');
      }
      return;
    }
    
    if (kDebugMode) {
      if (kDebugMode) print('✅ [AuthGuard] Role: ${role.displayName}, navigating to home');
    }
    // Admin panel tersedia via web browser (website/admin/)
    // Flutter app semua user diarahkan ke home
    if (context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  /// Widget wrapper that checks admin access
  static Widget adminOnly({
    required Widget child,
    Widget? fallback,
  }) {
    return FutureBuilder<bool>(
      future: SupabaseService.isAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        return fallback ?? 
          Builder(
            builder: (context) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Akses Ditolak',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Hanya admin yang dapat mengakses halaman ini.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
      },
    );
  }

  /// Widget wrapper that checks authentication
  static Widget authRequired({
    required Widget child,
    Widget? fallback,
  }) {
    return SupabaseService.isLoggedIn
        ? child
        : fallback ??
            Builder(
              builder: (context) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.login,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Login Diperlukan',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Silakan login untuk melanjutkan.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
  }
}
