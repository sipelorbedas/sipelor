import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/build_config.dart';

class AutoLogoutService {
  static final AutoLogoutService _instance = AutoLogoutService._internal();
  factory AutoLogoutService() => _instance;
  AutoLogoutService._internal();

  Timer? _inactivityTimer;
  // FIX: Gunakan BuildConfig.autoLogoutMinutes agar konsisten dengan config terpusat
  Duration get _inactivityDuration =>
      Duration(minutes: BuildConfig.autoLogoutMinutes);
  BuildContext? _context;
  bool _isEnabled = true;

  void initialize(BuildContext context) {
    _context = context;
    _resetTimer();
  }

  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (enabled) {
      _resetTimer();
    } else {
      _cancelTimer();
    }
  }

  void _resetTimer() {
    if (!_isEnabled) return;
    
    _cancelTimer();
    _inactivityTimer = Timer(_inactivityDuration, () {
      _performLogout();
    });
  }

  void _cancelTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void onUserActivity() {
    _resetTimer();
  }

  Future<void> _performLogout() async {
    if (_context == null || !_context!.mounted) return;

    try {
      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();
      
      // Navigate to splash/login screen
      if (_context != null && _context!.mounted) {
        Navigator.of(_context!).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );

        // Show logout message
        ScaffoldMessenger.of(_context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Anda telah logout otomatis karena tidak aktif selama ${BuildConfig.autoLogoutMinutes} menit',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error during auto logout: $e');
    }
  }

  void dispose() {
    _cancelTimer();
    _context = null;
  }
}
