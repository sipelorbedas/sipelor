import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage onboarding tutorial state
class OnboardingService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String _hasSeenBookingTutorialKey = 'has_seen_booking_tutorial';

  /// Check if user has seen the onboarding tutorial
  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenOnboardingKey) ?? false;
    } catch (e) {
      if (kDebugMode) print('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as seen
  static Future<void> markOnboardingAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenOnboardingKey, true);
      if (kDebugMode) print('✅ Onboarding marked as seen');
    } catch (e) {
      if (kDebugMode) print('Error marking onboarding as seen: $e');
    }
  }

  /// Check if user has seen the booking tutorial
  static Future<bool> hasSeenBookingTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_hasSeenBookingTutorialKey) ?? false;
    } catch (e) {
      if (kDebugMode) print('Error checking booking tutorial status: $e');
      return false;
    }
  }

  /// Mark booking tutorial as seen
  static Future<void> markBookingTutorialAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenBookingTutorialKey, true);
      if (kDebugMode) print('✅ Booking tutorial marked as seen');
    } catch (e) {
      if (kDebugMode) print('Error marking booking tutorial as seen: $e');
    }
  }

  /// Reset all onboarding states (for testing)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasSeenOnboardingKey);
      await prefs.remove(_hasSeenBookingTutorialKey);
      if (kDebugMode) print('✅ Onboarding states reset');
    } catch (e) {
      if (kDebugMode) print('Error resetting onboarding: $e');
    }
  }
}
