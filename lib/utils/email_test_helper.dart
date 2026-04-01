/// Email Testing Helper for SIPELOR BEDAS
/// 
/// Helper class untuk test email functionality:
/// - Verification emails
/// - Password reset emails
/// - Custom email notifications
/// 
/// Usage:
/// ```dart
/// await EmailTestHelper.testVerificationEmail('test@example.com');
/// await EmailTestHelper.testPasswordResetEmail('test@example.com');
/// ```
library;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmailTestHelper {
  static SupabaseClient get supabase => Supabase.instance.client;

  /// Test verification email (resend)
  /// 
  /// Sends a verification email to the specified email address.
  /// User must already exist in the system.
  /// 
  /// Example:
  /// ```dart
  /// await EmailTestHelper.testVerificationEmail('test@example.com');
  /// ```
  static Future<Map<String, dynamic>> testVerificationEmail(String email) async {
    try {
      await supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      );

      return {
        'success': true,
        'message': '✅ Verification email sent to: $email\n📧 Check your inbox!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error sending verification email: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test signup (triggers automatic verification email)
  /// 
  /// Creates a new user and automatically sends verification email.
  /// 
  /// Example:
  /// ```dart
  /// await EmailTestHelper.testSignupWithVerification(
  ///   'newuser@example.com',
  ///   'SecurePass123!',
  /// );
  /// ```
  static Future<Map<String, dynamic>> testSignupWithVerification(
    String email,
    String password,
  ) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return {
          'success': true,
          'message': '✅ User created: ${response.user!.id}\n'
              '📧 Verification email sent automatically to: $email\n'
              '📬 Check your inbox and click verification link',
          'userId': response.user!.id,
        };
      } else {
        return {
          'success': false,
          'message': '❌ Failed to create user',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error during signup: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test password reset email
  /// 
  /// Sends password reset email with deep link to app.
  /// 
  /// Example:
  /// ```dart
  /// await EmailTestHelper.testPasswordResetEmail('test@example.com');
  /// ```
  static Future<Map<String, dynamic>> testPasswordResetEmail(
    String email, {
    String? redirectTo,
  }) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: redirectTo ?? 'sipelor://reset-password',
      );

      return {
        'success': true,
        'message': '✅ Password reset email sent to: $email\n'
            '📧 Check your inbox!\n'
            '🔗 Link will redirect to: ${redirectTo ?? 'sipelor://reset-password'}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error sending password reset: $e',
        'error': e.toString(),
      };
    }
  }

  /// Check if user exists and their verification status
  /// 
  /// Example:
  /// ```dart
  /// final status = await EmailTestHelper.checkUserStatus('test@example.com');
  /// print(status['message']);
  /// ```
  static Future<Map<String, dynamic>> checkUserStatus(String email) async {
    try {
      final response = await supabase.rpc('check_user_for_test_email', params: {
        'test_email': email,
      });

      return {
        'success': true,
        'message': response.toString(),
        'data': response,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error checking user status: $e',
        'error': e.toString(),
      };
    }
  }

  /// View recent email notifications from custom triggers
  /// 
  /// Example:
  /// ```dart
  /// final logs = await EmailTestHelper.getEmailNotificationLogs(limit: 10);
  /// ```
  static Future<Map<String, dynamic>> getEmailNotificationLogs({
    int limit = 20,
  }) async {
    try {
      final response = await supabase
          .from('email_notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return {
        'success': true,
        'message': '✅ Retrieved $limit email notification logs',
        'data': response,
        'count': (response as List).length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': '❌ Error fetching email logs: $e',
        'error': e.toString(),
      };
    }
  }

  /// Test all email types at once
  /// 
  /// Useful for comprehensive testing.
  /// 
  /// Example:
  /// ```dart
  /// await EmailTestHelper.testAllEmails('test@example.com');
  /// ```
  static Future<Map<String, dynamic>> testAllEmails(String email) async {
    final results = <String, dynamic>{};

    // Test 1: Check user status
    if (kDebugMode) print('🔍 Checking user status...');
    results['userStatus'] = await checkUserStatus(email);
    if (kDebugMode) print(results['userStatus']['message']);
    if (kDebugMode) print('');

    // Test 2: Verification email
    if (kDebugMode) print('📧 Testing verification email...');
    results['verification'] = await testVerificationEmail(email);
    if (kDebugMode) print(results['verification']['message']);
    if (kDebugMode) print('');

    await Future.delayed(const Duration(seconds: 2));

    // Test 3: Password reset
    if (kDebugMode) print('🔐 Testing password reset email...');
    results['passwordReset'] = await testPasswordResetEmail(email);
    if (kDebugMode) print(results['passwordReset']['message']);
    if (kDebugMode) print('');

    // Test 4: Check email logs
    if (kDebugMode) print('📋 Checking email notification logs...');
    results['emailLogs'] = await getEmailNotificationLogs(limit: 5);
    if (kDebugMode) print(results['emailLogs']['message']);

    return {
      'success': true,
      'message': '✅ All email tests completed',
      'results': results,
    };
  }

  /// Print formatted test results
  static void printTestResults(Map<String, dynamic> result) {
    if (kDebugMode) print('\n${'=' * 50}');
    if (kDebugMode) print('EMAIL TEST RESULTS');
    if (kDebugMode) print('=' * 50);
    if (kDebugMode) print(result['message']);
    if (result.containsKey('error')) {
      if (kDebugMode) print('\n❌ ERROR: ${result['error']}');
    }
    if (kDebugMode) print('=' * 50 + '\n');
  }
}
