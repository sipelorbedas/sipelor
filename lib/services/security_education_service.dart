import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk mengelola security education dan warnings
class SecurityEducationService {
  static const String _firstLoginKey = 'security_first_login_shown';
  static const String _lastSecurityTipShownKey = 'last_security_tip_shown';
  
  /// Check apakah ini first login user
  static Future<bool> isFirstLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_firstLoginKey) ?? false);
    } catch (e) {
      if (kDebugMode) print('Error checking first login: $e');
      return false; // Default to false to avoid showing repeatedly on error
    }
  }
  
  /// Mark bahwa security warning sudah ditampilkan
  static Future<void> markFirstLoginShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_firstLoginKey, true);
      await prefs.setInt(_lastSecurityTipShownKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      if (kDebugMode) print('Error marking first login shown: $e');
    }
  }
  
  /// Reset first login status (untuk testing atau user baru)
  static Future<void> resetFirstLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_firstLoginKey);
      await prefs.remove(_lastSecurityTipShownKey);
    } catch (e) {
      if (kDebugMode) print('Error resetting first login: $e');
    }
  }
  
  /// Get last time security tip was shown
  static Future<DateTime?> getLastSecurityTipShown() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_lastSecurityTipShownKey);
      if (timestamp != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('Error getting last security tip shown: $e');
      return null;
    }
  }
  
  /// Check if should show periodic security reminder (setiap 30 hari)
  static Future<bool> shouldShowPeriodicReminder() async {
    try {
      final lastShown = await getLastSecurityTipShown();
      if (lastShown == null) return true;
      
      final daysSinceLastShown = DateTime.now().difference(lastShown).inDays;
      return daysSinceLastShown >= 30;
    } catch (e) {
      if (kDebugMode) print('Error checking periodic reminder: $e');
      return false;
    }
  }
}
