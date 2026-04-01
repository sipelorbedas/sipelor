import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_role.dart';
import '../models/field.dart';
import '../models/venue.dart' as venue_model;
import '../models/booking.dart';
import '../utils/secure_logger.dart';
import '../config/build_config.dart';
import 'notification_helper.dart';
import 'file_encryption_service.dart';

class SupabaseService {
  static SupabaseClient get _client => Supabase.instance.client;

  // PERFORMANCE: Cache for user profiles to avoid repeated database queries
  static final Map<String, Map<String, dynamic>> _profileCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  // Get current user
  static User? get currentUser => _client.auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // PERFORMANCE: Clear profile cache (call when profile is updated)
  static void clearProfileCache([String? userId]) {
    if (userId != null) {
      _profileCache.remove(userId);
      _cacheTimestamps.remove(userId);
    } else {
      _profileCache.clear();
      _cacheTimestamps.clear();
    }
  }

  // Get current user role
  static Future<UserRole> getCurrentUserRole() async {
    try {
      final user = currentUser;
      if (user == null) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GetUserRole] No current user');
        }
        return UserRole.user;
      }

      if (kDebugMode) {
        if (kDebugMode) print('🔍 [GetUserRole] Fetching role for user: ${user.id}');
      }

      // ATTEMPT 1: Try using RPC function to bypass RLS policies
      // This is similar to get_email_by_username and should work around
      // the infinite recursion error in RLS policies
      try {
        if (kDebugMode) {
          if (kDebugMode) print('📝 [GetUserRole] Attempting RPC function to get role...');
        }

        final roleResult = await _client.rpc(
          'get_role_by_user_id',
          params: {'input_user_id': user.id},
        );

        final roleString = roleResult as String?;

        if (roleString != null) {
          final role = UserRole.fromString(roleString);
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [GetUserRole] Got role via RPC: $roleString (isAdmin: ${role.isAdmin})',
            );
            }
          }
          return role;
        }
      } catch (rpcError) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GetUserRole] RPC function failed: $rpcError');
          if (kDebugMode) print('📝 [GetUserRole] Falling back to direct query...');
        }
      }

      // ATTEMPT 2: Try getting user metadata from auth
      // Supabase auth can store custom metadata that doesn't require database queries
      try {
        if (kDebugMode) {
          if (kDebugMode) print('📝 [GetUserRole] Checking user metadata...');
        }

        final metadata = user.userMetadata;
        if (metadata != null && metadata.containsKey('role')) {
          final roleString = metadata['role'] as String?;
          if (roleString != null) {
            final role = UserRole.fromString(roleString);
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                '✅ [GetUserRole] Got role from metadata: $roleString (isAdmin: ${role.isAdmin})',
              );
              }
            }
            return role;
          }
        }
      } catch (metadataError) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GetUserRole] Metadata check failed: $metadataError');
        }
      }

      // ATTEMPT 3: Fallback to direct database query
      if (kDebugMode) {
        if (kDebugMode) print('📝 [GetUserRole] Attempting direct database query...');
      }

      final profile = await getUserProfile(user.id);
      if (profile == null) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GetUserRole] No profile found for user');
        }
        return UserRole.user;
      }

      final roleString = profile['role'] as String?;
      if (kDebugMode) {
        if (kDebugMode) print('🔍 [GetUserRole] Profile data: $profile');
        if (kDebugMode) print('🔍 [GetUserRole] Role string from DB: $roleString');
      }

      final role = UserRole.fromString(roleString ?? 'user');
      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '✅ [GetUserRole] Parsed role: ${role.toString()} (isAdmin: ${role.isAdmin})',
        );
        }
      }

      return role;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [GetUserRole] All attempts failed. Error: $e');
        if (kDebugMode) {
          print(
          '⚠️  [GetUserRole] Defaulting to user role. Please fix database RLS policies!',
        );
        }
      }
      return UserRole.user;
    }
  }

  // Check if current user is admin
  static Future<bool> isAdmin() async {
    final role = await getCurrentUserRole();
    return role.isAdmin;
  }

  // Check if specific user is admin
  static Future<bool> isUserAdmin(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile == null) return false;

      final roleString = profile['role'] as String?;
      final role = UserRole.fromString(roleString ?? 'user');
      return role.isAdmin;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [IsUserAdmin] Error: $e');
      }
      return false;
    }
  }

  // Update user role (admin only)
  static Future<void> updateUserRole({
    required String userId,
    required UserRole role,
  }) async {
    try {
      // Check if current user is admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can update user roles');
      }

      await _client
          .from('profiles')
          .update({
            'role': role.toString(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // PERFORMANCE: Clear cache after role update
      clearProfileCache(userId);

      SecureLogger.success('[UpdateUserRole] Role updated successfully');
    } catch (e) {
      SecureLogger.error('[UpdateUserRole] Error: $e');
      throw Exception('Failed to update user role: $e');
    }
  }

  // ── WhatsApp / Phone OTP Verification ────────────────────────────────────

  /// Kirim OTP ke nomor WhatsApp untuk user yang sudah sign-in.
  /// Dipanggil setelah signUp dengan email (email confirmation dinonaktifkan).
  static Future<void> sendPhoneOtpForVerification({
    required String phone,
  }) async {
    try {
      await _client.auth.updateUser(UserAttributes(phone: phone));
      if (kDebugMode) print('✅ [PhoneOTP] OTP sent to $phone via updateUser');
    } catch (e) {
      if (kDebugMode) print('❌ [PhoneOTP] sendPhoneOtpForVerification error: $e');
      rethrow;
    }
  }

  /// Kirim OTP ke nomor WhatsApp untuk user yang belum sign-in (fallback).
  static Future<void> signInWithPhoneOtp(String phone) async {
    try {
      await _client.auth.signInWithOtp(phone: phone);
      if (kDebugMode) print('✅ [PhoneOTP] OTP sent to $phone via signInWithOtp');
    } catch (e) {
      if (kDebugMode) print('❌ [PhoneOTP] signInWithPhoneOtp error: $e');
      rethrow;
    }
  }

  /// Verifikasi OTP WhatsApp — phone change flow (user sudah sign-in dengan email).
  static Future<AuthResponse> verifyPhoneChangeOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.phoneChange,
      );
      if (kDebugMode) print('✅ [PhoneOTP] Phone change OTP verified for $phone');
      return res;
    } catch (e) {
      if (kDebugMode) print('❌ [PhoneOTP] verifyPhoneChangeOtp error: $e');
      rethrow;
    }
  }

  /// Verifikasi OTP WhatsApp — SMS/sign-in flow (user belum sign-in).
  static Future<AuthResponse> verifyPhoneSignInOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final res = await _client.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );
      if (kDebugMode) print('✅ [PhoneOTP] Phone sign-in OTP verified for $phone');
      return res;
    } catch (e) {
      if (kDebugMode) print('❌ [PhoneOTP] verifyPhoneSignInOtp error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '📝 [SignUp] Starting signup with email: $email, username: $username',
        );
        }
      }

      // Step 1: Sign up user with email verification
      if (kDebugMode) {
        if (kDebugMode) print('📝 [SignUp] Calling auth.signUp...');
      }

      // Configure email redirect URL for verification.
      // On mobile: uses BuildConfig.emailRedirectUrl which should point to
      // landing/auth/callback.html hosted on HTTPS. That page JS-redirects to
      // sipelor://callback, bypassing Chrome Custom Tab's HTTP-302 custom-scheme block.
      // Set via: --dart-define=EMAIL_REDIRECT_URL=https://yoursite.com/auth/callback.html
      final emailRedirectTo = kIsWeb
          ? 'https://sipelor.app/verify' // Production web URL
          : BuildConfig
                .emailRedirectUrl; // See BuildConfig for setup instructions

      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username, 'full_name': username},
        emailRedirectTo: emailRedirectTo,
      );

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '✅ [SignUp] Auth signup successful. User ID: ${response.user?.id}',
        );
        }
        if (kDebugMode) {
          print(
          '📧 [SignUp] Email confirmation required: ${response.user?.emailConfirmedAt == null}',
        );
        }
        if (response.user?.emailConfirmedAt == null) {
          if (kDebugMode) print('📧 [SignUp] Verification email should be sent to: $email');
          if (kDebugMode) print('📧 [SignUp] Check your inbox and spam folder');
        }
      }

      // Step 2: Insert user profile into public.profiles table
      // Note: Using upsert to handle cases where trigger might have already created it
      if (response.user != null) {
        try {
          if (kDebugMode) {
            if (kDebugMode) print('📝 [SignUp] Saving user profile to database...');
          }

          // Use upsert instead of insert to handle both cases:
          // 1. Trigger already created the profile
          // 2. We need to create/update it
          await _client.from('profiles').upsert({
            'id': response.user!.id,
            'username': username,
            'email': email,
            'full_name': username,
            'avatar_url': null,
            'bio': null,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          if (kDebugMode) {
            if (kDebugMode) print('✅ [SignUp] Profile saved successfully');
          }

          // Verify the profile was actually saved
          try {
            final profile = await _client
                .from('profiles')
                .select()
                .eq('id', response.user!.id)
                .single();
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                '✅ [SignUp] Profile verification: Data confirmed in database',
              );
              }
              if (kDebugMode) print('✅ [SignUp] Profile data: $profile');
            }
          } catch (verifyError) {
            if (kDebugMode) {
              if (kDebugMode) print('⚠️  [SignUp] Could not verify profile: $verifyError');
            }
          }
        } catch (profileError) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [SignUp] Profile save failed: $profileError');
            if (kDebugMode) print('❌ [SignUp] Error type: ${profileError.runtimeType}');

            // Don't fail the signup, but log the error for debugging
            // The auth user was created successfully
            if (kDebugMode) {
              print(
              '⚠️  [SignUp] Auth user was created but profile save had issues',
            );
            }
            if (kDebugMode) print('⚠️  [SignUp] User may need to complete profile setup later');
          }
        }
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SignUp] Signup process completed successfully');
      }
      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignUp] Auth exception: ${e.message}');
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignUp] Unknown error: $e');
      }
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign in with username and password
  static Future<AuthResponse> signIn({
    required String username,
    required String password,
  }) async {
    try {
      // Normalize username: trim whitespace
      final normalizedUsername = username.trim();

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '📝 [SignIn] Attempting signin with username: $normalizedUsername',
        );
        }
      }

      // Step 1: Get user email from database using RPC function
      // This function bypasses RLS, allowing anonymous users to look up email by username
      if (kDebugMode) {
        if (kDebugMode) print('📝 [SignIn] Calling database function to get email...');
      }

      String? email;
      try {
        final result = await _client.rpc(
          'get_email_by_username',
          params: {'input_username': normalizedUsername},
        );

        email = result as String?;

        if (kDebugMode) {
          if (email != null) {
            if (kDebugMode) print('✅ [SignIn] Found user email via RPC: $email');
          } else {
            if (kDebugMode) print('⚠️  [SignIn] RPC returned null - username not found');
          }
        }
      } catch (rpcError) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [SignIn] RPC function failed: $rpcError');
          if (kDebugMode) print('📝 [SignIn] Falling back to direct table query...');
        }

        // Fallback: Try direct query (will work if RLS allows it)
        try {
          final profileResponse = await _client
              .from('profiles')
              .select('email')
              .ilike('username', normalizedUsername)
              .maybeSingle();

          email = profileResponse?['email'] as String?;

          if (kDebugMode) {
            if (email != null) {
              if (kDebugMode) print('✅ [SignIn] Found user email via fallback query: $email');
            } else {
              if (kDebugMode) print('⚠️  [SignIn] Fallback query returned null');
            }
          }
        } catch (queryError) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [SignIn] Fallback query also failed: $queryError');
          }
        }
      }

      if (email == null || email.isEmpty) {
        if (!normalizedUsername.contains('@')) {
          // ── Fallback 1: cari email di tabel opd_organizations ─────────────
          // Diperlukan karena akun OPD lama mungkin dibuat dengan email asli
          // (bukan username@sipelor.go.id) dan profiles.username belum di-set.
          // Kolom opd_organizations.email menyimpan email asli yang juga
          // dipakai di auth.users, sehingga jika ditemukan login akan berhasil.
          try {
            final opdResult = await _client
                .from('opd_organizations')
                .select('email, username')
                .ilike('username', normalizedUsername)
                .maybeSingle();

            if (opdResult != null) {
              final opdEmail    = (opdResult['email'] as String?)?.trim() ?? '';
              final opdUsername = (opdResult['username'] as String?)?.trim() ?? '';
              if (opdEmail.isNotEmpty) {
                email = opdEmail;
              } else if (opdUsername.isNotEmpty) {
                email = '$opdUsername@sipelor.go.id';
              }
              if (kDebugMode) {
                print('📝 [SignIn] Found via opd_organizations: $email');
              }
            }
          } catch (opdError) {
            if (kDebugMode) {
              print('⚠️ [SignIn] opd_organizations lookup failed: $opdError');
            }
          }

          // ── Fallback 2: konstruksi email dari username ────────────────────
          // Untuk akun OPD yang dibuat tanpa email asli (email = username@sipelor.go.id).
          if (email == null || email.isEmpty) {
            email = '$normalizedUsername@sipelor.go.id';
            if (kDebugMode) {
              print(
                '📝 [SignIn] Username not found in profiles/OPD — '
                'trying constructed email: $email',
              );
            }
          }
        } else {
          // Input sudah berupa email tapi tidak ditemukan → lempar error
          if (kDebugMode) {
            print('❌ [SignIn] No email found for username: $normalizedUsername');
          }
          throw Exception(
            'Username not found. Please check your username and try again.',
          );
        }
      }

      // Step 2: Sign in with the fetched email
      if (kDebugMode) {
        if (kDebugMode) print('📝 [SignIn] Signing in with email...');
      }
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SignIn] Successfully signed in');
      }

      // PERFORMANCE: Clear profile cache after successful login
      // This ensures fresh profile data with correct role is fetched
      clearProfileCache();

      return response;
    } on AuthException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignIn] Auth exception: ${e.message}');
      }

      // Handle "Email not confirmed" error
      if (e.message.contains('Email not confirmed')) {
        throw Exception(
          'Please verify your email before signing in. Check your email for the verification link.',
        );
      }
      rethrow;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignIn] Database error: ${e.message}');
      }

      // Handle database-related errors
      if (e.code == 'PGRST116' || e.message.contains('0 rows')) {
        throw Exception(
          'Username not found. Please check your username and try again.',
        );
      }

      throw Exception('Database error: ${e.message}');
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignIn] Error: $e');
      }

      // Handle case where user is not found
      if (e.toString().contains('Username not found')) {
        rethrow;
      }

      if (e.toString().contains('Account configuration error')) {
        rethrow;
      }

      throw Exception('Sign in failed: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _client.auth.signOut();

      // PERFORMANCE: Clear all caches on sign out
      clearProfileCache();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      // PERFORMANCE: Check cache first
      final cachedProfile = _profileCache[userId];
      final cacheTimestamp = _cacheTimestamps[userId];

      if (cachedProfile != null && cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(cacheTimestamp);
        if (cacheAge < _cacheDuration) {
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [GetUserProfile] Using cached profile for $userId (age: ${cacheAge.inSeconds}s)',
            );
            }
          }
          return cachedProfile;
        }
      }

      // Cache miss or expired, fetch from database
      if (kDebugMode) {
        if (kDebugMode) print('🔄 [GetUserProfile] Fetching profile from database for $userId');
      }

      // ATTEMPT 1: Try RPC function first (bypasses RLS)
      try {
        if (kDebugMode) {
          if (kDebugMode) print('📝 [GetUserProfile] Attempting RPC function...');
        }

        final rpcResult = await _client.rpc(
          'get_user_profile_data',
          params: {'input_user_id': userId},
        );

        if (rpcResult != null && rpcResult is List && rpcResult.isNotEmpty) {
          final profile = rpcResult[0] as Map<String, dynamic>;

          // Store in cache
          _profileCache[userId] = profile;
          _cacheTimestamps[userId] = DateTime.now();

          if (kDebugMode) {
            if (kDebugMode) print('✅ [GetUserProfile] Got profile via RPC function');
          }

          return profile;
        }
      } catch (rpcError) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GetUserProfile] RPC function failed: $rpcError');
          if (kDebugMode) print('📝 [GetUserProfile] Falling back to direct query...');
        }
      }

      // ATTEMPT 2: Fallback to direct query
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      // Store in cache
      _profileCache[userId] = response;
      _cacheTimestamps[userId] = DateTime.now();

      return response;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', userId);

      // PERFORMANCE: Clear cache after update
      clearProfileCache(userId);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  // Get total users count (admin only)
  static Future<int> getTotalUsersCount() async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can fetch users count');
      }

      SecureLogger.info('[GetTotalUsersCount] Fetching total users count');

      final response = await _client
          .from('profiles')
          .select('id')
          .count(CountOption.exact);

      final count = response.count ?? 0;
      SecureLogger.success('[GetTotalUsersCount] Total users: $count');
      return count;
    } catch (e) {
      SecureLogger.error('[GetTotalUsersCount] Error', e);
      throw Exception('Failed to fetch users count: $e');
    }
  }

  // Get all usernames (admin only)
  static Future<List<String>> getAllUsernames() async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can fetch usernames');
      }

      SecureLogger.info('[GetAllUsernames] Fetching all usernames');

      final response = await _client
          .from('profiles')
          .select('username')
          .order('username', ascending: true);

      final usernames = (response as List)
          .map((profile) => profile['username'] as String?)
          .where((username) => username != null && username.isNotEmpty)
          .cast<String>()
          .toList();

      SecureLogger.success(
        '[GetAllUsernames] Fetched ${usernames.length} usernames',
      );
      return usernames;
    } catch (e) {
      SecureLogger.error('[GetAllUsernames] Error', e);
      throw Exception('Failed to fetch usernames: $e');
    }
  }

  // ── OPD Account Detection ─────────────────────────────────────────────────

  /// Cek apakah user yang sedang login adalah akun OPD/Pimpinan.
  /// Mengembalikan data OPD (termasuk discount_percentage) jika ya, null jika bukan OPD.
  static Future<Map<String, dynamic>?> getOpdInfo() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final userEmail = user.email ?? '';
      if (userEmail.isEmpty) return null;

      // Cari di opd_organizations berdasarkan email atau konstruksi username@sipelor.go.id
      // Attempt 1: Match by email langsung
      Map<String, dynamic>? opdRow;
      try {
        final res = await _client
            .from('opd_organizations')
            .select('id, name, discount_percentage, is_active, username, email')
            .eq('is_active', true)
            .or('email.eq.$userEmail,email.ilike.$userEmail')
            .maybeSingle();
        opdRow = res;
      } catch (_) {}

      // Attempt 2: Jika email berformat username@sipelor.go.id, cari by username
      if (opdRow == null && userEmail.endsWith('@sipelor.go.id')) {
        final username = userEmail.replaceAll('@sipelor.go.id', '');
        try {
          final res = await _client
              .from('opd_organizations')
              .select('id, name, discount_percentage, is_active, username, email')
              .eq('is_active', true)
              .ilike('username', username)
              .maybeSingle();
          opdRow = res;
        } catch (_) {}
      }

      if (opdRow == null) return null;
      return opdRow;
    } catch (e) {
      if (kDebugMode) print('⚠️ [GetOpdInfo] Error: $e');
      return null;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception('Failed to send reset password email: $e');
    }
  }

  // Resend verification email
  static Future<void> resendVerificationEmail(String email) async {
    try {
      SecureLogger.info(
        '[ResendVerification] Sending verification email to: $email',
      );
      // Note: Currently showing user-friendly message
      // In production, you might use Supabase functions or other mechanisms
      // to resend the verification email
      SecureLogger.success(
        '[ResendVerification] Verification email resend requested',
      );
    } catch (e) {
      SecureLogger.error('[ResendVerification] Error', e);
      throw Exception('Failed to send verification email: $e');
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> authStateChanges() {
    return _client.auth.onAuthStateChange;
  }

  // ============================================
  // VENUE MANAGEMENT
  // ============================================

  // Fetch all venues from fields table (no separate venues table)
  static Future<List<venue_model.Venue>> fetchVenues({
    bool activeOnly = false,
  }) async {
    try {
      SecureLogger.info('[FetchVenues] Fetching venues from fields...');

      // Fetch all fields to extract unique venues
      var query = _client.from('fields').select();

      if (activeOnly) {
        query = query.eq('status', 'available');
      }

      final response = await query;

      // Group fields by venue_name to get unique venues
      final venueMap = <String, Map<String, dynamic>>{};

      for (var field in response as List) {
        final venueName = field['venue_name'] as String;
        final venueType = field['venue_type'] as String;

        // Use venue_name + venue_type as unique key
        final key = '$venueName-$venueType';

        if (!venueMap.containsKey(key)) {
          // Create venue entry from field data
          venueMap[key] = {
            'id':
                field['id'], // Use field ID as venue ID (since no separate venue table)
            'name': venueName,
            'venue_type': venueType,
            'description': field['description'],
            'address': 'Jalak Harupat', // Default address
            'city': 'Bandung', // Default city
            'image_url':
                (field['image_urls'] is List &&
                    (field['image_urls'] as List).isNotEmpty)
                ? (field['image_urls'] as List).first
                : null,
            'rating': 0.0, // Default rating
            'total_reviews': 0, // Will be calculated separately if needed
            'is_active': field['status'] == 'available',
            'created_at': field['created_at'],
            'updated_at': field['updated_at'],
          };
        }
      }

      final venues = venueMap.values
          .map((json) => venue_model.Venue.fromJson(json))
          .toList();

      SecureLogger.success(
        '[FetchVenues] Successfully fetched ${venues.length} unique venues from fields',
      );
      return venues;
    } catch (e) {
      SecureLogger.error('[FetchVenues] Error', e);
      throw Exception('Failed to fetch venues from fields: $e');
    }
  }

  // Fetch venue by ID (from fields table since no separate venues table)
  static Future<venue_model.Venue?> fetchVenueById(String venueId) async {
    try {
      SecureLogger.info(
        '[FetchVenueById] Fetching venue from fields: $venueId',
      );

      // Fetch field by ID (venueId is actually a field ID)
      final response = await _client
          .from('fields')
          .select()
          .eq('id', venueId)
          .single();

      // Convert field data to venue model
      final venueData = {
        'id': response['id'],
        'name': response['venue_name'],
        'venue_type': response['venue_type'],
        'description': response['description'],
        'address': 'Jalak Harupat', // Default address
        'city': 'Bandung', // Default city
        'image_url':
            (response['image_urls'] is List &&
                (response['image_urls'] as List).isNotEmpty)
            ? (response['image_urls'] as List).first
            : null,
        'rating': 0.0, // Default rating
        'total_reviews': 0, // Default reviews count
        'is_active': response['status'] == 'available',
        'created_at': response['created_at'],
        'updated_at': response['updated_at'],
      };

      final venue = venue_model.Venue.fromJson(venueData);

      SecureLogger.success(
        '[FetchVenueById] Successfully fetched venue from field: ${venue.name}',
      );
      return venue;
    } catch (e) {
      SecureLogger.error('[FetchVenueById] Error', e);
      return null;
    }
  }

  // ============================================
  // FIELD MANAGEMENT
  // ============================================

  // Fetch all fields
  static Future<List<Field>> fetchFields({
    String? area,
    bool activeOnly = false,
  }) async {
    try {
      SecureLogger.info('[FetchFields] Fetching fields...');

      var query = _client.from('fields').select();

      if (area != null) {
        query = query.eq('area', area);
      }

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      // Timeout 15 detik mencegah query hang tak terbatas (RLS/network issue)
      final response = await query
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 15));

      final fields = (response as List)
          .map((json) => Field.fromJson(json as Map<String, dynamic>))
          .toList();

      SecureLogger.success(
        '[FetchFields] Successfully fetched ${fields.length} fields',
      );

      // Peringatan jika tidak ada fields sama sekali — kemungkinan RLS issue
      if (fields.isEmpty && kDebugMode) {
        print(
          '⚠️ [FetchFields] Tidak ada data fields di database!\n'
          '   → Kemungkinan RLS tabel "fields" memblokir read untuk user ini.\n'
          '   → Jalankan: website/admin/sql/fix_rls_fields_and_bookings.sql\n'
          '   → Atau pastikan tabel "fields" sudah berisi data.',
        );
      }

      return fields;
    } catch (e) {
      SecureLogger.error('[FetchFields] Error', e);
      if (kDebugMode) {
        print(
          '❌ [FetchFields] Gagal fetch fields: $e\n'
          '   → Jika error RLS/permission, jalankan:\n'
          '      website/admin/sql/fix_rls_fields_and_bookings.sql\n'
          '      di Supabase Dashboard → SQL Editor',
        );
      }
      throw Exception('Failed to fetch fields: $e');
    }
  }

  // Fetch field by ID
  static Future<Field?> fetchFieldById(String fieldId) async {
    try {
      SecureLogger.info('[FetchFieldById] Fetching field: $fieldId');

      final response = await _client
          .from('fields')
          .select()
          .eq('id', fieldId)
          .single();

      final field = Field.fromJson(response);

      SecureLogger.success(
        '[FetchFieldById] Successfully fetched field: ${field.venueName}',
      );
      return field;
    } catch (e) {
      SecureLogger.error('[FetchFieldById] Error', e);
      return null;
    }
  }

  // Create new field (admin only)
  static Future<Field> createField({
    String? venueId,
    required String venueName,
    required String venueType,
    required String area,
    String? satuan,
    String? description,
    required int pricePerHour,
    FieldStatus status = FieldStatus.available,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? ukuranLapangan,
    String? kapasitas,
    bool? tempatParkir,
    bool? mushola,
    bool? cctv,
    bool? ruangTunggu,
    bool? ruangGanti,
  }) async {
    try {
      // Check if current user is admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can create fields');
      }

      SecureLogger.info('[CreateField] Creating new field: $venueName');

      final insertData = {
        'venue_name': venueName,
        'venue_type': venueType,
        'area': area,
        'satuan': satuan,
        'description': description,
        'price_per_hour': pricePerHour,
        'status': status.value,
        'is_active': status == FieldStatus.available, // Backward compatibility
        'image_urls': imageUrls,
        'latitude': latitude,
        'longitude': longitude,
        'ukuran_lapangan': ukuranLapangan,
        'kapasitas': kapasitas,
        'tempat_parkir': tempatParkir,
        'mushola': mushola,
        'cctv': cctv,
        'ruang_tunggu': ruangTunggu,
        'ruang_ganti': ruangGanti,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add venue_id if provided
      if (venueId != null) {
        insertData['venue_id'] = venueId;
      }

      final response = await _client
          .from('fields')
          .insert(insertData)
          .select()
          .single();

      final field = Field.fromJson(response);

      SecureLogger.success(
        '[CreateField] Field created successfully: ${field.id}',
      );
      return field;
    } catch (e) {
      SecureLogger.error('[CreateField] Error', e);
      throw Exception('Failed to create field: $e');
    }
  }

  // Update field (admin only)
  static Future<Field> updateField({
    required String fieldId,
    String? venueId,
    String? venueName,
    String? venueType,
    String? area,
    String? satuan,
    String? description,
    int? pricePerHour,
    FieldStatus? status,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? ukuranLapangan,
    String? kapasitas,
    bool? tempatParkir,
    bool? mushola,
    bool? cctv,
    bool? ruangTunggu,
    bool? ruangGanti,
  }) async {
    try {
      // Check if current user is admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can update fields');
      }

      SecureLogger.info('[UpdateField] Updating field: $fieldId');

      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (venueId != null) updates['venue_id'] = venueId;
      if (venueName != null) updates['venue_name'] = venueName;
      if (venueType != null) updates['venue_type'] = venueType;
      if (area != null) updates['area'] = area;
      if (satuan != null) updates['satuan'] = satuan;
      if (description != null) updates['description'] = description;
      if (pricePerHour != null) updates['price_per_hour'] = pricePerHour;
      if (status != null) {
        updates['status'] = status.value;
        updates['is_active'] =
            status == FieldStatus.available; // Backward compatibility
      }
      if (imageUrls != null) updates['image_urls'] = imageUrls;
      if (latitude != null) updates['latitude'] = latitude;
      if (longitude != null) updates['longitude'] = longitude;
      if (ukuranLapangan != null) updates['ukuran_lapangan'] = ukuranLapangan;
      if (kapasitas != null) updates['kapasitas'] = kapasitas;
      if (tempatParkir != null) updates['tempat_parkir'] = tempatParkir;
      if (mushola != null) updates['mushola'] = mushola;
      if (cctv != null) updates['cctv'] = cctv;
      if (ruangTunggu != null) updates['ruang_tunggu'] = ruangTunggu;
      if (ruangGanti != null) updates['ruang_ganti'] = ruangGanti;

      final response = await _client
          .from('fields')
          .update(updates)
          .eq('id', fieldId)
          .select()
          .single();

      final field = Field.fromJson(response);

      SecureLogger.success('[UpdateField] Field updated successfully');
      return field;
    } catch (e) {
      SecureLogger.error('[UpdateField] Error', e);
      throw Exception('Failed to update field: $e');
    }
  }

  // Delete field (admin only)
  static Future<void> deleteField(String fieldId) async {
    try {
      // Check if current user is admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can delete fields');
      }

      SecureLogger.info('[DeleteField] Deleting field: $fieldId');

      await _client.from('fields').delete().eq('id', fieldId);

      SecureLogger.success('[DeleteField] Field deleted successfully');
    } catch (e) {
      SecureLogger.error('[DeleteField] Error', e);
      throw Exception('Failed to delete field: $e');
    }
  }

  // Toggle field active status (admin only)
  static Future<void> toggleFieldStatus(
    String fieldId,
    FieldStatus newStatus,
  ) async {
    try {
      await updateField(fieldId: fieldId, status: newStatus);
      SecureLogger.success(
        '[ToggleFieldStatus] Field status updated to: ${newStatus.value}',
      );
    } catch (e) {
      SecureLogger.error('[ToggleFieldStatus] Error', e);
      throw Exception('Failed to toggle field status: $e');
    }
  }

  // ============================================
  // STORAGE MANAGEMENT
  // ============================================

  // Upload image to Supabase Storage
  static Future<String> uploadFieldImage({
    required String fileName,
    required List<int> fileBytes,
  }) async {
    try {
      SecureLogger.info('[UploadFieldImage] Uploading image: $fileName');

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'field_${timestamp}_$fileName';

      // Convert List<int> to Uint8List
      final uint8ListBytes = Uint8List.fromList(fileBytes);

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      } else if (extension == 'gif') {
        contentType = 'image/gif';
      }

      // Upload to 'field-images' bucket
      await _client.storage
          .from('field-images')
          .uploadBinary(
            uniqueFileName,
            uint8ListBytes,
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );

      // Get public URL
      final publicUrl = _client.storage
          .from('field-images')
          .getPublicUrl(uniqueFileName);

      SecureLogger.success(
        '[UploadFieldImage] Image uploaded successfully: $publicUrl',
      );
      return publicUrl;
    } catch (e) {
      SecureLogger.error('[UploadFieldImage] Error', e);
      throw Exception('Failed to upload image: $e');
    }
  }

  // Delete image from Supabase Storage
  static Future<void> deleteFieldImage(String imageUrl) async {
    try {
      SecureLogger.info('[DeleteFieldImage] Deleting image: $imageUrl');

      // Extract filename from URL
      final uri = Uri.parse(imageUrl);
      final fileName = uri.pathSegments.last;

      await _client.storage.from('field-images').remove([fileName]);

      SecureLogger.success('[DeleteFieldImage] Image deleted successfully');
    } catch (e) {
      SecureLogger.error('[DeleteFieldImage] Error', e);
      // Don't throw error if image deletion fails
      // as it might not exist or already be deleted
      SecureLogger.warning('[DeleteFieldImage] Continuing despite error');
    }
  }

  // Upload profile image to Supabase Storage
  // IMPORTANT: Make sure 'profile-avatars' bucket exists in Supabase Storage
  // and is configured as PUBLIC for the getPublicUrl to work.
  // To create bucket: Go to Supabase Dashboard > Storage > Create bucket > Set public = true
  static Future<String> uploadProfileImage({
    required String userId,
    required File file,
  }) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('[UploadProfileImage] Uploading profile image for user: $userId');
      }

      // Read file bytes
      final fileBytes = await file.readAsBytes();

      // Get file extension
      final fileName = file.path.split('/').last;
      final extension = fileName.split('.').last.toLowerCase();

      // Create unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = 'avatar_${userId}_$timestamp.$extension';

      // Determine content type based on extension
      String contentType = 'image/jpeg';
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'webp') {
        contentType = 'image/webp';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '[UploadProfileImage] File: $uniqueFileName, Type: $contentType, Size: ${fileBytes.length} bytes',
        );
        }
      }

      // Upload to 'profile-avatars' bucket
      await _client.storage
          .from('profile-avatars')
          .uploadBinary(
            uniqueFileName,
            fileBytes,
            fileOptions: FileOptions(
              contentType: contentType,
              upsert: true, // Allow overwriting
            ),
          );

      if (kDebugMode) {
        if (kDebugMode) print('[UploadProfileImage] Upload completed successfully');
      }

      // Get public URL with cache busting
      final baseUrl = _client.storage
          .from('profile-avatars')
          .getPublicUrl(uniqueFileName);

      // Add timestamp as query parameter to bust cache
      final publicUrl = '$baseUrl?t=$timestamp';

      if (kDebugMode) {
        if (kDebugMode) print('[UploadProfileImage] Image uploaded successfully: $publicUrl');
      }

      return publicUrl;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('[UploadProfileImage] Error: $e');
      }
      throw Exception('Failed to upload profile image: $e');
    }
  }

  // Delete profile image from Supabase Storage
  static Future<void> deleteProfileImage(String imageUrl) async {
    try {
      if (kDebugMode) {
        if (kDebugMode) print('[DeleteProfileImage] Deleting image: $imageUrl');
      }

      // Extract filename from URL (remove query parameters if present)
      final uri = Uri.parse(imageUrl);
      String fileName = uri.pathSegments.last;

      // Remove query parameters from filename if present (e.g., ?t=1234567890)
      if (fileName.contains('?')) {
        fileName = fileName.split('?').first;
      }

      if (kDebugMode) {
        if (kDebugMode) print('[DeleteProfileImage] Extracted filename: $fileName');
      }

      await _client.storage.from('profile-avatars').remove([fileName]);

      if (kDebugMode) {
        if (kDebugMode) print('[DeleteProfileImage] Image deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('[DeleteProfileImage] Error: $e');
      }
      // Don't throw error if image deletion fails
    }
  }

  // ============================================
  // BOOKING MANAGEMENT
  // ============================================

  // Create new booking
  /// Generate a unique booking ID in format SJH-YYYYMMDD-XXXX
  /// SJH = Stadion Jalak Harupat
  /// YYYYMMDD = Date
  /// XXXX = Random alphanumeric (4 chars)
  static Future<String> _generateBookingId() async {
    const int maxAttempts = 5;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        // Get current date for the date part
        final now = DateTime.now();
        final datePart =
            '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

        // Generate random alphanumeric code (4 characters)
        final random = Random();
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
        final randomCode = List.generate(
          4,
          (index) => chars[random.nextInt(chars.length)],
        ).join();

        // Format as SJH-YYYYMMDD-XXXX
        final bookingId = 'SJH-$datePart-$randomCode';

        if (kDebugMode) {
          if (kDebugMode) {
            print(
            '🎲 [GenerateBookingId] Generated candidate: $bookingId (attempt ${attempt + 1})',
          );
          }
        }

        // Verify uniqueness
        final existing = await _client
            .from('bookings')
            .select('id')
            .eq('booking_id', bookingId)
            .maybeSingle();

        if (existing == null) {
          // Booking ID is unique
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [GenerateBookingId] Unique booking ID confirmed: $bookingId',
            );
            }
          }
          return bookingId;
        } else {
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '⚠️  [GenerateBookingId] Collision detected for $bookingId, retrying...',
            );
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [GenerateBookingId] Error on attempt ${attempt + 1}: $e');
        }
        if (attempt == maxAttempts - 1) {
          // Last attempt failed, use timestamp fallback
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fallbackId = 'SJH-${timestamp.toString()}';
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '📝 [GenerateBookingId] Using timestamp fallback: $fallbackId',
            );
            }
          }
          return fallbackId;
        }
      }
    }

    // Fallback if all attempts fail (very unlikely)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fallbackId = 'SJH-${timestamp.toString()}';
    if (kDebugMode) {
      if (kDebugMode) {
        print(
        '📝 [GenerateBookingId] All attempts failed, using fallback: $fallbackId',
      );
      }
    }
    return fallbackId;
  }

  static Future<Booking> createBooking({
    required String fieldId,
    required String venueId,
    required DateTime bookingDate,
    required String startTime,
    required String endTime,
    required int durationHours,
    required int totalAmount,
    String? notes,
    // OPD fields (opsional)
    int discountPercentage = 0,
    String? opdId,
    String bookingType = 'regular',
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create booking');
      }

      SecureLogger.info('[CreateBooking] Creating booking for field: $fieldId');

      // Generate unique booking ID
      final bookingId = await _generateBookingId();

      // Validate booking ID was generated
      if (bookingId.isEmpty) {
        throw Exception('Failed to generate booking ID');
      }

      SecureLogger.info('[CreateBooking] Generated booking_id: $bookingId');

      // Extra validation
      if (kDebugMode) {
        if (kDebugMode) print('✅ [CreateBooking] booking_id validation passed: $bookingId');
      }

      // Check for existing bookings to prevent double booking
      final dateString = bookingDate.toIso8601String().split('T')[0];
      SecureLogger.info(
        '[CreateBooking] Checking availability for date: $dateString, time: $startTime - $endTime',
      );

      // ─── ATTEMPT 1: Cek via RPC (bypass RLS, termasuk blokir OPD/Pimpinan) ─
      bool blockedByRpc = false;
      try {
        final rpcResult = await _client.rpc(
          'get_blocked_slots',
          params: {
            'p_field_id': fieldId,
            'p_date': dateString,
          },
        );
        if (rpcResult != null && rpcResult is List) {
          blockedByRpc = true; // RPC tersedia, gunakan hasilnya
          for (final row in rpcResult) {
            final data = row as Map<String, dynamic>;
            final status = data['status'] as String? ?? '';
            final hasProof = data['has_payment_proof'] as bool? ?? false;
            if (status == 'confirmed' || (status == 'pending' && hasProof)) {
              final rStart = _normalizeTimeStr(data['start_time']);
              final rEnd = _normalizeTimeStr(data['end_time']);
              if (_timeOverlaps(startTime, endTime, rStart, rEnd)) {
                SecureLogger.warning(
                  '[CreateBooking] Slot diblokir (RPC): $rStart - $rEnd',
                );
                throw Exception(
                  'Jadwal ini sudah dipesan. Silakan pilih waktu lain.',
                );
              }
            }
          }
          if (kDebugMode) {
            if (kDebugMode) print('✅ [CreateBooking] Slot tersedia (cek via RPC)');
          }
        }
      } catch (rpcErr) {
        if (rpcErr.toString().contains('Jadwal ini sudah dipesan')) rethrow;
        if (kDebugMode) {
          if (kDebugMode) {
            print(
            '⚠️ [CreateBooking] RPC tidak tersedia, fallback ke direct query: $rpcErr',
          );
          }
        }
      }

      // ─── ATTEMPT 2: Direct query (fallback jika RPC tidak tersedia) ────────
      if (!blockedByRpc) {
        // Fetch bookings that should block the time slot:
        // 1. Confirmed bookings (admin has verified payment)
        // 2. Pending bookings that have payment proof uploaded
        // Note: Pending bookings WITHOUT payment proof should NOT block slots
        final existingBookings = await _client
            .from('bookings')
            .select('id, start_time, end_time, status, booking_id')
            .eq('field_id', fieldId)
            .eq('booking_date', dateString)
            .inFilter('status', ['pending', 'confirmed']); // Get active bookings

        // Filter bookings: only consider those with payment proof or confirmed status
        final blockingBookings = <Map<String, dynamic>>[];

        for (final booking in existingBookings) {
          final bookingStatus = booking['status'] as String;
          final bookingId = booking['id'] as String;

          // Always include confirmed bookings
          if (bookingStatus == 'confirmed') {
            blockingBookings.add(booking);
            continue;
          }

          // For pending bookings, check if payment proof exists
          if (bookingStatus == 'pending') {
            final paymentProofExists = await _client
                .from('payment_proofs')
                .select('id')
                .eq('booking_id', bookingId)
                .maybeSingle();

            // Only block if payment proof has been uploaded
            if (paymentProofExists != null) {
              blockingBookings.add(booking);
            } else {
              if (kDebugMode) {
                if (kDebugMode) {
                  print(
                  '⏭️  [CreateBooking] Skipping pending booking ${booking['booking_id']} - no payment proof yet',
                );
                }
              }
            }
          }
        }

        // Check if the requested time slot overlaps with any blocking booking
        for (final booking in blockingBookings) {
          final existingStart = _normalizeTimeStr(booking['start_time']);
          final existingEnd = _normalizeTimeStr(booking['end_time']);

          // Check for any overlap
          // Overlap occurs if: (start1 < end2) AND (start2 < end1)
          if (_timeOverlaps(startTime, endTime, existingStart, existingEnd)) {
            SecureLogger.warning(
              '[CreateBooking] Time slot already booked: $existingStart - $existingEnd',
            );
            throw Exception(
              'Jadwal ini sudah dipesan. Silakan pilih waktu lain.',
            );
          }
        }
      }

      SecureLogger.info(
        '[CreateBooking] Time slot available, proceeding with booking',
      );

      // Use the provided venueId directly (typically the field ID)
      // Note: There's no separate venues table and fields table doesn't have venue_id column
      final actualVenueId = venueId;
      SecureLogger.info(
        '[CreateBooking] Using venue_id for booking: $actualVenueId',
      );

      // Final validation before insert
      if (kDebugMode) {
        if (kDebugMode) print('📝 [CreateBooking] About to insert with:');
        if (kDebugMode) print('   booking_id: $bookingId');
        if (kDebugMode) print('   user_id: ${user.id}');
        if (kDebugMode) print('   field_id: $fieldId');
        if (kDebugMode) print('   venue_id: $actualVenueId');
        if (kDebugMode) print('   booking_date: $dateString');
      }

      // OPD booking: jika diskon 100% langsung dikonfirmasi otomatis
      final isOpdFree = bookingType != 'regular' && discountPercentage >= 100;
      final discountAmount = (totalAmount * discountPercentage / 100).round();

      final response = await _client
          .from('bookings')
          .insert({
            'booking_id': bookingId,
            'user_id': user.id,
            'field_id': fieldId,
            'venue_id': actualVenueId,
            'booking_date': dateString,
            'start_time': startTime,
            'end_time': endTime,
            'duration_hours': durationHours,
            'total_amount': totalAmount,
            'status': isOpdFree ? 'confirmed' : 'pending',
            'payment_status': isOpdFree ? 'verified' : 'pending',
            'notes': notes,
            // OPD specific fields
            if (bookingType != 'regular') 'booking_type': bookingType,
            'opd_id': ?opdId,
            if (discountPercentage > 0) 'discount_percentage': discountPercentage,
            if (discountPercentage > 0) 'discount_amount': discountAmount,
          })
          .select()
          .single();

      final booking = Booking.fromJson(response);

      SecureLogger.success(
        '[CreateBooking] Booking created successfully: ${booking.bookingId}',
      );
      return booking;
    } catch (e) {
      SecureLogger.error('[CreateBooking] Error', e);

      // Provide user-friendly error messages
      if (e.toString().contains('infinite recursion')) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [CreateBooking] DATABASE RLS POLICY ERROR detected');
          if (kDebugMode) print('📋 Fix required: Update Supabase RLS policies');
          if (kDebugMode) print('📄 See: docs/SUPABASE_RLS_POLICY_FIX.md');
        }
        throw Exception(
          'Kesalahan database. Silakan hubungi administrator untuk memperbaiki konfigurasi database.',
        );
      } else if (e.toString().contains('policy') ||
          e.toString().contains('permission')) {
        throw Exception(
          'Anda tidak memiliki izin untuk membuat booking. Silakan hubungi administrator.',
        );
      } else if (e.toString().contains('Jadwal ini sudah dipesan')) {
        // Re-throw the time slot conflict message as is
        rethrow;
      }

      throw Exception(
        'Gagal membuat booking: ${e.toString().replaceAll('Exception: ', '')}',
      );
    }
  }

  /// Normalisasi string waktu dari berbagai format ke "HH:mm"
  /// Mendukung: "08:00:00" (Postgres time), "08:00", "8:00"
  static String _normalizeTimeStr(dynamic value) {
    if (value == null) return '00:00';
    final s = value.toString();
    final parts = s.split(':');
    if (parts.length >= 2) {
      return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
    }
    return s;
  }

  // Helper function to check if two time slots overlap
  static bool _timeOverlaps(
    String start1,
    String end1,
    String start2,
    String end2,
  ) {
    // Parse time strings to minutes since midnight for comparison
    int parseTime(String time) {
      final parts = time.split(':');
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    }

    final s1 = parseTime(start1);
    final e1 = parseTime(end1);
    final s2 = parseTime(start2);
    final e2 = parseTime(end2);

    // Two time ranges overlap if: (start1 < end2) AND (start2 < end1)
    return (s1 < e2) && (s2 < e1);
  }

  // Fetch user bookings
  static Future<List<Booking>> fetchUserBookings({String? userId}) async {
    try {
      final user = currentUser;
      if (user == null && userId == null) {
        throw Exception('User must be logged in');
      }

      final targetUserId = userId ?? user!.id;
      if (kDebugMode) print('📝 [FetchUserBookings] Fetching bookings for user: $targetUserId');

      // Fetch bookings first
      final bookingsResponse = await _client
          .from('bookings')
          .select()
          .eq('user_id', targetUserId)
          .order('created_at', ascending: false);

      if (kDebugMode) print('📝 [FetchUserBookings] Raw bookings response: $bookingsResponse');

      final bookingsList = bookingsResponse as List;

      // Fetch field details for each booking
      final List<Booking> bookings = [];
      for (var bookingJson in bookingsList) {
        final bookingId = bookingJson['id'] as String;
        final fieldId = bookingJson['field_id'] as String;

        // Check if payment proof exists for this booking
        if (kDebugMode) {
          print(
          '📝 [FetchUserBookings] Checking payment proof for booking: $bookingId',
        );
        }
        final hasPaymentProof = await _checkPaymentProofExists(bookingId);

        // Tag the booking with whether it has payment proof
        // Pending bookings without proof are shown so user can continue payment
        bookingJson['has_payment_proof'] = hasPaymentProof;

        // Fetch field details
        try {
          final fieldResponse = await _client
              .from('fields')
              .select('venue_name, area, venue_type')
              .eq('id', fieldId)
              .single();

          if (kDebugMode) {
            print(
            '📝 [FetchUserBookings] Field data for $fieldId: $fieldResponse',
          );
          }

          // Add field data to booking JSON
          bookingJson['fields'] = fieldResponse;
        } catch (e) {
          if (kDebugMode) {
            print(
            '⚠️ [FetchUserBookings] Could not fetch field data for $fieldId: $e',
          );
          }
        }

        bookings.add(Booking.fromJson(bookingJson as Map<String, dynamic>));
      }

      if (kDebugMode) {
        print(
        '✅ [FetchUserBookings] Successfully fetched ${bookings.length} bookings with field details (excluding bookings without payment proof)',
      );
      }
      return bookings;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchUserBookings] Error: $e');
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  /// Check if payment proof exists for a booking
  static Future<bool> _checkPaymentProofExists(String bookingUuid) async {
    try {
      final response = await _client
          .from('payment_proofs')
          .select('id')
          .eq('booking_id', bookingUuid)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        print(
        '⚠️ [CheckPaymentProof] Error checking payment proof for $bookingUuid: $e',
      );
      }
      return false;
    }
  }

  /// Get a single booking by ID (UUID)
  static Future<Booking> getBookingById(String bookingId) async {
    try {
      if (kDebugMode) print('📝 [GetBookingById] Fetching booking: $bookingId');

      // Fetch booking
      final bookingResponse = await _client
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .single();

      if (kDebugMode) print('📝 [GetBookingById] Raw booking response: $bookingResponse');

      final fieldId = bookingResponse['field_id'] as String;

      // Fetch field details
      try {
        final fieldResponse = await _client
            .from('fields')
            .select('venue_name, area, venue_type')
            .eq('id', fieldId)
            .single();

        if (kDebugMode) print('📝 [GetBookingById] Field data: $fieldResponse');

        // Add field data to booking JSON
        bookingResponse['fields'] = fieldResponse;
      } catch (e) {
        if (kDebugMode) print('⚠️ [GetBookingById] Could not fetch field data: $e');
      }

      final booking = Booking.fromJson(bookingResponse);
      if (kDebugMode) print('✅ [GetBookingById] Successfully fetched booking');
      return booking;
    } catch (e) {
      if (kDebugMode) print('❌ [GetBookingById] Error: $e');
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Fetch bookings for a specific field and date
  static Future<List<Booking>> fetchFieldBookingsByDate({
    required String fieldId,
    required DateTime date,
  }) async {
    try {
      final dateString = date.toIso8601String().split('T')[0];
      if (kDebugMode) {
        print(
        '📝 [FetchFieldBookingsByDate] Fetching bookings for field: $fieldId on date: $dateString',
      );
      }

      // ─── ATTEMPT 1: RPC get_blocked_slots (SECURITY DEFINER) ──────────────
      // RPC ini membypass RLS sehingga booking OPD/Pimpinan yang dibuat admin
      // tetap terlihat oleh user biasa untuk keperluan cek ketersediaan slot.
      // Jika RPC belum ada di database, jalankan: docs/fix_opd_blocking_rls.sql
      try {
        final rpcResult = await _client.rpc(
          'get_blocked_slots',
          params: {
            'p_field_id': fieldId,
            'p_date': dateString,
          },
        );

        if (rpcResult != null && rpcResult is List) {
          final blockingBookings = <Booking>[];

          for (final row in rpcResult) {
            final data = row as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'pending';
            final hasPaymentProof = data['has_payment_proof'] as bool? ?? false;

            // Termasuk: confirmed ATAU pending yang sudah ada bukti bayar
            if (status == 'confirmed' ||
                (status == 'pending' && hasPaymentProof)) {
              blockingBookings.add(
                Booking(
                  id: data['id'] as String,
                  bookingId: data['booking_id'] as String? ?? '',
                  userId: '',
                  fieldId: fieldId,
                  venueId: fieldId,
                  bookingDate: date,
                  startTime: _normalizeTimeStr(data['start_time']),
                  endTime: _normalizeTimeStr(data['end_time']),
                  durationHours: 0,
                  totalAmount: 0,
                  status: BookingStatus.fromString(status),
                  paymentStatus: PaymentStatus.pending,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  bookingType: BookingType.fromString(
                    data['booking_type'] as String? ?? 'regular',
                  ),
                  bookedForLabel: data['booked_for_label'] as String?,
                  opdId: data['opd_id'] as String?,
                ),
              );
            }
          }

          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [FetchFieldBookingsByDate] RPC: ${blockingBookings.length} blocking bookings (termasuk OPD/Pimpinan)',
            );
            }
          }

          // ── Enrich OPD bookings dengan nama OPD dari opd_organizations ──────
          // Agar UI bisa menampilkan "Nama OPD / Pimpinan" bukan hanya tipe-nya
          final opdIds = blockingBookings
              .where((b) => b.bookingType.isOfficialBooking && b.opdId != null)
              .map((b) => b.opdId!)
              .toSet()
              .toList();
          if (opdIds.isNotEmpty) {
            try {
              final opdResp = await _client
                  .from('opd_organizations')
                  .select('id, name')
                  .inFilter('id', opdIds);
              final opdMap = <String, String>{
                for (final o in (opdResp as List))
                  o['id'] as String: o['name'] as String? ?? '',
              };
              return blockingBookings.map((b) {
                if (b.opdId != null && opdMap.containsKey(b.opdId)) {
                  return b.copyWith(opdName: opdMap[b.opdId]);
                }
                return b;
              }).toList();
            } catch (_) {
              // OPD name enrichment is optional — return as-is on failure
            }
          }

          return blockingBookings;
        }
      } catch (rpcError) {
        if (kDebugMode) {
          if (kDebugMode) {
            print(
            '⚠️ [FetchFieldBookingsByDate] RPC tidak tersedia, beralih ke direct query: $rpcError',
          );
          }
          if (kDebugMode) {
            print(
            '⚠️ [FetchFieldBookingsByDate] Jadwal OPD/Pimpinan mungkin tidak terblokir karena RLS!',
          );
          }
          if (kDebugMode) {
            print(
            '⚠️ [FetchFieldBookingsByDate] → Jalankan docs/fix_opd_blocking_rls.sql di Supabase SQL Editor',
          );
          }
        }
      }

      // ─── ATTEMPT 2: Direct query (fallback, mungkin terbatas RLS) ─────────
      final response = await _client
          .from('bookings')
          .select()
          .eq('field_id', fieldId)
          .eq('booking_date', dateString)
          .inFilter('status', ['pending', 'confirmed']); // Only active bookings

      // Filter bookings: only include those that should actually block the time slot
      // 1. Confirmed bookings (payment verified by admin) → always block
      // 2. Pending bookings WITH payment proof uploaded → block the slot
      // 3. Pending bookings WITHOUT payment proof → DON'T block (user hasn't completed the booking)
      final blockingBookings = <Booking>[];

      for (final json in response) {
        final booking = Booking.fromJson(json);

        // Always include confirmed bookings
        if (booking.status == BookingStatus.confirmed) {
          blockingBookings.add(booking);
          if (kDebugMode) {
            if (kDebugMode) print('   ✅ Including confirmed booking: ${booking.bookingId}');
          }
          continue;
        }

        // For pending bookings, check if payment proof exists
        if (booking.status == BookingStatus.pending) {
          final paymentProofExists = await _client
              .from('payment_proofs')
              .select('id')
              .eq('booking_id', booking.id)
              .maybeSingle();

          if (paymentProofExists != null) {
            // Payment proof uploaded → block the slot
            blockingBookings.add(booking);
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                '   ✅ Including pending booking with payment proof: ${booking.bookingId}',
              );
              }
            }
          } else {
            // No payment proof → don't block the slot
            if (kDebugMode) {
              if (kDebugMode) {
                print(
                '   ⏭️  Skipping pending booking without payment proof: ${booking.bookingId}',
              );
              }
            }
          }
        }
      }

      if (kDebugMode) {
        print(
        '✅ [FetchFieldBookingsByDate] Found ${blockingBookings.length} blocking bookings (filtered from ${(response as List).length} total)',
      );
      }
      return blockingBookings;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchFieldBookingsByDate] Error: $e');
      throw Exception('Failed to fetch field bookings: $e');
    }
  }

  // Fetch all bookings (admin only)
  static Future<List<Booking>> fetchAllBookings() async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can fetch all bookings');
      }

      if (kDebugMode) {
        if (kDebugMode) print('📝 [FetchAllBookings] Starting to fetch all bookings');
      }

      // PERFORMANCE FIX: Fetch all payment proofs in a single query instead of N+1 queries
      // Make this non-blocking - if payment proofs fail, we still show bookings
      List allPaymentProofs = [];
      try {
        allPaymentProofs = await _client
            .from('payment_proofs')
            .select('id, booking_id, file_path, status, created_at')
            .order('created_at', ascending: false);

        if (kDebugMode) {
          if (kDebugMode) {
            print(
            '✅ [FetchAllBookings] Fetched ${allPaymentProofs.length} payment proofs',
          );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [FetchAllBookings] Error fetching payment proofs: $e');
          if (kDebugMode) print('⚠️  [FetchAllBookings] Continuing without payment proofs data');
        }
        // Continue execution - bookings will show "Belum Ada" for payment proof
        allPaymentProofs = [];
      }

      // Create a Set of booking UUIDs that have payment proofs for O(1) lookup
      final bookingUuidsWithProofs = allPaymentProofs
          .map((proof) => proof['booking_id'] as String)
          .toSet();

      // Fetch ALL bookings to show in admin dashboard
      // Admin should see all bookings immediately, regardless of payment proof status
      // Business logic: User creates booking → Shows in admin dashboard → User uploads payment proof
      if (kDebugMode) {
        if (kDebugMode) print('📝 [FetchAllBookings] Fetching bookings from database...');
      }

      // PERFORMANCE FIX: Use nested select to join fields in ONE query (eliminates N+1)
      List bookingsResponse;
      try {
        bookingsResponse = await _client
            .from('bookings')
            .select('*, fields!field_id(venue_name, area, venue_type)')
            .order('created_at', ascending: false);

        if (kDebugMode) {
          if (kDebugMode) {
            print(
            '✅ [FetchAllBookings] Fetch with join succeeded, got ${bookingsResponse.length} records',
          );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [FetchAllBookings] Error fetching bookings: $e');
          if (kDebugMode) print('⚠️  [FetchAllBookings] Retrying without join...');
        }

        // Fallback: fetch without join if FK name is unexpected
        try {
          bookingsResponse = await _client
              .from('bookings')
              .select('*, fields(venue_name, area, venue_type)')
              .order('created_at', ascending: false);
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [FetchAllBookings] Fallback fetch succeeded, got ${bookingsResponse.length} records',
            );
            }
          }
        } catch (e2) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [FetchAllBookings] Fallback also failed: $e2');
          }
          throw Exception('Cannot fetch bookings. RLS policy error: $e');
        }
      }

      final bookingsList = bookingsResponse;

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '📊 [FetchAllBookings] Processing ${bookingsList.length} bookings...',
        );
        }
      }

      if (bookingsList.isEmpty) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  [FetchAllBookings] No bookings found in database');
        }
        return [];
      }

      // Process all bookings — fields data already joined from select query (no N+1)
      final List<Booking> bookings = [];
      int processedCount = 0;
      int errorCount = 0;

      for (var bookingJson in bookingsList) {
        try {
          final mutableJson = Map<String, dynamic>.from(bookingJson as Map);

          // Annotate payment proof status using pre-fetched batch (O(1) lookup)
          final bookingUuid = mutableJson['id'] as String;
          mutableJson['has_payment_proof'] =
              bookingUuidsWithProofs.contains(bookingUuid);

          // Ensure fields key exists — join should already populate this,
          // but provide fallback if FK join returned null
          if (mutableJson['fields'] == null) {
            mutableJson['fields'] = {
              'venue_name': 'Venue',
              'area': 'Lapangan',
              'venue_type': 'Lapangan',
            };
          }

          bookings.add(Booking.fromJson(mutableJson));
          processedCount++;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [FetchAllBookings] Error parsing booking: $e');
          }
          errorCount++;
          continue;
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '📊 [FetchAllBookings] Processed: $processedCount, Errors: $errorCount',
        );
        }
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [FetchAllBookings] Fetched ${bookings.length} bookings total');
      }
      return bookings;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchAllBookings] Error: $e');
      throw Exception('Failed to fetch all bookings: $e');
    }
  }

  // Fetch bookings by date range (admin only)
  static Future<List<Booking>> fetchBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can fetch bookings by date range');
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '📝 [FetchBookingsByDateRange] Fetching bookings from $startDate to $endDate',
        );
        }
      }

      // Format dates for query
      final startDateString = DateFormat('yyyy-MM-dd').format(startDate);
      final endDateString = DateFormat('yyyy-MM-dd').format(endDate);

      // Fetch bookings in date range
      final bookingsResponse = await _client
          .from('bookings')
          .select()
          .gte('booking_date', startDateString)
          .lt('booking_date', endDateString)
          .order('booking_date', ascending: false);

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '✅ [FetchBookingsByDateRange] Fetched ${bookingsResponse.length} bookings',
        );
        }
      }

      final List<Booking> bookings = [];

      for (var bookingJson in bookingsResponse) {
        final fieldId = bookingJson['field_id'] as String;

        // Fetch field details
        try {
          final fieldResponse = await _client
              .from('fields')
              .select('venue_name, area, venue_type')
              .eq('id', fieldId)
              .single();

          bookingJson['fields'] = fieldResponse;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '⚠️ [FetchBookingsByDateRange] Error fetching field data: $e',
            );
            }
          }

          bookingJson['fields'] = {
            'venue_name': 'Venue',
            'area': 'Lapangan',
            'venue_type': 'Lapangan',
          };
        }

        try {
          bookings.add(Booking.fromJson(bookingJson));
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [FetchBookingsByDateRange] Error parsing booking: $e');
          }
          continue;
        }
      }

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '✅ [FetchBookingsByDateRange] Successfully processed ${bookings.length} bookings',
        );
        }
      }
      return bookings;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchBookingsByDateRange] Error: $e');
      throw Exception('Failed to fetch bookings by date range: $e');
    }
  }

  // Update booking status (admin only)
  static Future<void> updateBookingStatus({
    required String
    bookingId, // This is the UUID (id), not booking_id (BOOK001)
    required BookingStatus status,
  }) async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can update booking status');
      }

      if (kDebugMode) print('📝 [UpdateBookingStatus] Updating booking UUID: $bookingId');

      // Fetch booking details first with explicit columns only
      if (kDebugMode) print('📝 [UpdateBookingStatus] Fetching booking details...');
      final bookingResponse = await _client
          .from('bookings')
          .select('id, user_id, field_id, status')
          .eq('id', bookingId)
          .single();

      final userId = bookingResponse['user_id'] as String;
      final fieldId = bookingResponse['field_id'] as String;
      final oldStatus = BookingStatus.fromString(
        bookingResponse['status'] as String,
      );

      if (kDebugMode) {
        print(
        '📝 [UpdateBookingStatus] Booking details fetched: userId=$userId, fieldId=$fieldId, oldStatus=${oldStatus.value}',
      );
      }

      // Update booking status
      if (kDebugMode) {
        print(
        '📝 [UpdateBookingStatus] Attempting to update status to: ${status.value}',
      );
      }
      if (kDebugMode) print('📝 [UpdateBookingStatus] Old status: ${oldStatus.value}');

      try {
        // Build update payload: always update status, and sync payment_status
        // when booking is confirmed (→ verified) or cancelled (→ rejected)
        final Map<String, dynamic> updatePayload = {'status': status.value};
        if (status == BookingStatus.confirmed) {
          updatePayload['payment_status'] = 'verified';
        } else if (status == BookingStatus.cancelled) {
          updatePayload['payment_status'] = 'rejected';
        } else if (status == BookingStatus.pending) {
          updatePayload['payment_status'] = 'pending';
        }

        if (kDebugMode) print('📝 [UpdateBookingStatus] Executing update query...');
        await _client
            .from('bookings')
            .update(updatePayload)
            .eq('id', bookingId);

        if (kDebugMode) print('✅ [UpdateBookingStatus] Update query executed successfully');

        // Verify the update with explicit columns
        if (kDebugMode) print('📝 [UpdateBookingStatus] Verifying update...');
        final verifyResponse = await _client
            .from('bookings')
            .select('id, status, payment_status')
            .eq('id', bookingId)
            .single();

        final updatedStatus = verifyResponse['status'] as String;
        if (updatedStatus != status.value) {
          throw Exception(
            'Status not updated correctly. Expected: ${status.value}, Got: $updatedStatus',
          );
        }

        if (kDebugMode) {
          print(
          '✅ [UpdateBookingStatus] Verification passed: status=$updatedStatus, payment_status=${verifyResponse['payment_status']}',
        );
        }
      } catch (e) {
        if (kDebugMode) print('❌ [UpdateBookingStatus] Update failed: $e');
        if (kDebugMode) print('❌ [UpdateBookingStatus] Error type: ${e.runtimeType}');

        // Check if it's the specific database schema error
        if (e.toString().contains('column f.name does not exist')) {
          if (kDebugMode) print('');
          if (kDebugMode) {
            print(
            '╔════════════════════════════════════════════════════════════╗',
          );
          }
          if (kDebugMode) {
            print(
            '║              ⚠️  DATABASE POLICY ERROR                    ║',
          );
          }
          if (kDebugMode) {
            print(
            '╠════════════════════════════════════════════════════════════╣',
          );
          }
          if (kDebugMode) {
            print(
            '║ Error: "column f.name does not exist"                     ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ This is a database-side RLS policy or trigger error.      ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ The database policy is trying to access "f.name" from     ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ the fields table, but this column does not exist.         ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ SOLUTION: Fix the database RLS policy or trigger that     ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ references the bookings/fields tables.                    ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ Likely location: RLS policy on bookings table             ║',
          );
          }
          if (kDebugMode) print('║ Change: f.name → v.name (or use f.venue_name)            ║');
          if (kDebugMode) {
            print(
            '╚════════════════════════════════════════════════════════════╝',
          );
          }
          if (kDebugMode) print('');
          throw Exception(
            'Database RLS policy error: The database is trying to access a column "f.name" '
            'that does not exist in the fields table. This needs to be fixed in the database '
            'RLS policies or triggers. Please contact the database administrator.',
          );
        }

        if (e.toString().contains('policy') ||
            e.toString().contains('permission')) {
          if (kDebugMode) print('⚠️  [UpdateBookingStatus] RLS POLICY ERROR detected');
          if (kDebugMode) print('📋 Fix: Admin needs UPDATE permission on bookings table');
          throw Exception(
            'Admin tidak memiliki izin untuk update booking. Silakan periksa RLS policy.',
          );
        }
        rethrow;
      }

      // Fetch field details for notification after successful update
      String venueName = 'Venue';
      try {
        if (kDebugMode) {
          print(
          '📝 [UpdateBookingStatus] Fetching field details for notification...',
        );
        }
        final fieldResponse = await _client
            .from('fields')
            .select('venue_name')
            .eq('id', fieldId)
            .single();
        venueName = fieldResponse['venue_name'] as String? ?? 'Venue';
        if (kDebugMode) {
          print(
          '📝 [UpdateBookingStatus] Field details fetched: venueName=$venueName',
        );
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ [UpdateBookingStatus] Could not fetch field details: $e');
      }

      // Send notification based on status change
      if (kDebugMode) print('📝 [UpdateBookingStatus] Sending notification...');
      await _sendBookingStatusNotification(
        userId: userId,
        bookingId: bookingId,
        venueName: venueName,
        oldStatus: oldStatus,
        newStatus: status,
      );
      if (kDebugMode) print('✅ [UpdateBookingStatus] Notification sent successfully');
    } catch (e) {
      if (kDebugMode) print('❌ [UpdateBookingStatus] Error: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Helper method to send booking status notifications
  static Future<void> _sendBookingStatusNotification({
    required String userId,
    required String bookingId,
    required String venueName,
    required BookingStatus oldStatus,
    required BookingStatus newStatus,
  }) async {
    try {
      // Only send notification if status actually changed
      if (oldStatus == newStatus) {
        if (kDebugMode) print('ℹ️ [Notification] Status unchanged, skipping notification');
        return;
      }

      // Send notification based on new status
      if (newStatus == BookingStatus.confirmed) {
        // Booking confirmed/approved
        if (kDebugMode) print('📤 [Notification] Sending booking confirmed notification...');
        await NotificationHelper.notifyBookingConfirmed(
          userId: userId,
          bookingId: bookingId,
          venueName: venueName,
        );
        if (kDebugMode) print('✅ [Notification] Booking confirmed notification sent');
      } else if (newStatus == BookingStatus.completed) {
        // Booking completed - prompt for review
        if (kDebugMode) print('📤 [Notification] Sending booking completed notification...');
        await NotificationHelper.notifyBookingCompleted(
          userId: userId,
          bookingId: bookingId,
          venueName: venueName,
        );
        if (kDebugMode) print('✅ [Notification] Booking completed notification sent');
      } else if (newStatus == BookingStatus.cancelled) {
        // Booking rejected/cancelled
        if (kDebugMode) print('📤 [Notification] Sending booking cancelled notification...');
        await NotificationHelper.notifyBookingRejected(
          userId: userId,
          bookingId: bookingId,
          venueName: venueName,
          reason: null,
        );
        if (kDebugMode) print('✅ [Notification] Booking cancelled notification sent');
      } else {
        if (kDebugMode) {
          print(
          'ℹ️ [Notification] No notification for status: ${newStatus.value}',
        );
        }
      }
    } catch (e, stackTrace) {
      // Don't fail the whole operation if notification fails
      if (kDebugMode) print('⚠️ [Notification] Failed to send notification: $e');
      if (kDebugMode) print('⚠️ [Notification] Stack trace: $stackTrace');
    }
  }

  // Update payment status (admin only)
  static Future<void> updatePaymentStatus({
    required String
    bookingId, // This is the UUID (id), not booking_id (BOOK001)
    required PaymentStatus status,
  }) async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can update payment status');
      }

      if (kDebugMode) {
        print(
        '📝 [UpdatePaymentStatus] Updating payment for booking UUID: $bookingId',
      );
      }

      // Fetch booking details to get user_id for notification
      final bookingData = await _client
          .from('bookings')
          .select('user_id, field_id')
          .eq('id', bookingId)
          .single();

      final userId = bookingData['user_id'] as String;

      await _client
          .from('bookings')
          .update({
            'payment_status': status.value,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);

      if (kDebugMode) {
        print(
        '✅ [UpdatePaymentStatus] Payment status updated to: ${status.value}',
      );
      }

      // Send notification to user
      try {
        if (status == PaymentStatus.verified) {
          await NotificationHelper.notifyPaymentVerified(
            userId: userId,
            bookingId: bookingId,
          );
          if (kDebugMode) print('✅ [UpdatePaymentStatus] Notification sent to user');
        } else if (status == PaymentStatus.rejected) {
          await NotificationHelper.notifyPaymentRejected(
            userId: userId,
            bookingId: bookingId,
          );
          if (kDebugMode) print('✅ [UpdatePaymentStatus] Notification sent to user');
        }
      } catch (e) {
        if (kDebugMode) print('⚠️ [UpdatePaymentStatus] Failed to send notification: $e');
        // Don't throw error if notification fails
      }
    } catch (e) {
      if (kDebugMode) print('❌ [UpdatePaymentStatus] Error: $e');
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Cancel booking (user can cancel their own pending bookings)
  static Future<void> cancelBooking(String bookingId) async {
    // This is the UUID (id), not booking_id (BOOK001)
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      if (kDebugMode) print('📝 [CancelBooking] Cancelling booking UUID: $bookingId');

      await _client
          .from('bookings')
          .update({
            'status': 'cancelled',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId)
          .eq('user_id', user.id)
          .eq('status', 'pending'); // Only pending bookings can be cancelled

      if (kDebugMode) print('✅ [CancelBooking] Booking cancelled successfully');
    } catch (e) {
      if (kDebugMode) print('❌ [CancelBooking] Error: $e');
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Delete incomplete booking (booking without payment proof)
  // This is used when user abandons booking before uploading payment proof
  static Future<void> deleteIncompleteBooking(String bookingId) async {
    // Declare user outside try so it's accessible in catch block
    final user = currentUser;
    if (user == null) {
      throw Exception('User must be logged in');
    }

    // This is the UUID (id), not booking_id (BOOK001)
    try {
      if (kDebugMode) print('🗑️  [DeleteIncompleteBooking] Deleting booking UUID: $bookingId');

      // Check if booking has payment proof
      final paymentProof = await _client
          .from('payment_proofs')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();

      // If payment proof exists, just cancel instead of delete
      if (paymentProof != null) {
        if (kDebugMode) {
          print(
          '⚠️  [DeleteIncompleteBooking] Booking has payment proof, cancelling instead of deleting',
        );
        }
        await cancelBooking(bookingId);
        return;
      }

      // Delete the booking entirely since no payment proof was uploaded
      await _client
          .from('bookings')
          .delete()
          .eq('id', bookingId)
          .eq('user_id', user.id)
          .eq('status', 'pending'); // Only pending bookings can be deleted

      if (kDebugMode) {
        print(
        '✅ [DeleteIncompleteBooking] Incomplete booking deleted successfully',
      );
      }

      // Verify deletion by checking if it still exists
      final stillExists = await _client
          .from('bookings')
          .select('id')
          .eq('id', bookingId)
          .maybeSingle();

      if (stillExists != null) {
        // Deletion was silently skipped (e.g., status wasn't pending anymore)
        // Fallback: cancel the booking so it doesn't appear as active in admin
        if (kDebugMode) {
          print(
          '⚠️  [DeleteIncompleteBooking] Deletion had no effect, falling back to cancel',
        );
        }
        await _client
            .from('bookings')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', bookingId)
            .eq('user_id', user.id);
        if (kDebugMode) print('✅ [DeleteIncompleteBooking] Booking cancelled as fallback');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [DeleteIncompleteBooking] Error: $e');
      // Last resort fallback: try to cancel without status filter
      try {
        await _client
            .from('bookings')
            .update({
              'status': 'cancelled',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', bookingId)
            .eq('user_id', user.id);
        if (kDebugMode) print('✅ [DeleteIncompleteBooking] Fallback cancel succeeded');
      } catch (e2) {
        if (kDebugMode) print('❌ [DeleteIncompleteBooking] Fallback cancel failed: $e2');
        throw Exception('Failed to delete/cancel incomplete booking: $e');
      }
    }
  }

  // ============================================
  // PAYMENT PROOF MANAGEMENT
  // ============================================

  /// Upload payment proof to Supabase Storage and save record to database
  /// Returns the public URL of the uploaded file
  static Future<String> uploadPaymentProof({
    required String bookingId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in to upload payment proof');
      }

      if (kDebugMode) {
        print(
        '📝 [UploadPaymentProof] Uploading payment proof for booking: $bookingId',
      );
      }
      if (kDebugMode) print('📝 [UploadPaymentProof] File: $fileName');

      // Generate unique file name with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = fileName.split('.').last;
      final storagePath = '${user.id}/${bookingId}_$timestamp.$fileExtension';

      if (kDebugMode) print('📝 [UploadPaymentProof] Storage path: $storagePath');

      // Read file as bytes
      final file = await _readFileAsBytes(filePath);
      if (file == null) {
        throw Exception('Failed to read file');
      }

      if (kDebugMode) print('📝 [UploadPaymentProof] File size: ${file.length} bytes');

      // SECURITY: Encrypt file bytes before upload
      if (kDebugMode) print('📝 [UploadPaymentProof] Encrypting file before upload...');
      final encryptionService = FileEncryptionService();
      await encryptionService.initialize();
      final encryptedBytes = await encryptionService.encryptBytes(file);
      final bytesToUpload = encryptedBytes ?? file; // fallback to plain if encryption fails
      if (encryptedBytes == null && kDebugMode) {
        if (kDebugMode) print('⚠️ [UploadPaymentProof] Encryption failed, uploading unencrypted (fallback)');
      } else if (kDebugMode) {
        if (kDebugMode) print('✅ [UploadPaymentProof] File encrypted successfully');
      }

      // Upload to Supabase Storage
      if (kDebugMode) print('📝 [UploadPaymentProof] Uploading to storage...');
      final uploadPath = await _client.storage
          .from('payment-proofs')
          .uploadBinary(storagePath, bytesToUpload);

      if (kDebugMode) print('✅ [UploadPaymentProof] File uploaded to storage: $uploadPath');

      // Get public URL
      final publicUrl = _client.storage
          .from('payment-proofs')
          .getPublicUrl(storagePath);

      if (kDebugMode) print('📝 [UploadPaymentProof] Public URL: $publicUrl');

      // Get the booking UUID from booking_id (BOOK001 -> actual UUID)
      final bookingData = await _client
          .from('bookings')
          .select('id')
          .eq('booking_id', bookingId)
          .single();

      final bookingUuid = bookingData['id'] as String;
      if (kDebugMode) print('📝 [UploadPaymentProof] Booking UUID: $bookingUuid');

      // Save payment proof record to database
      if (kDebugMode) print('📝 [UploadPaymentProof] Saving record to database...');
      await _client.from('payment_proofs').insert({
        'booking_id': bookingUuid,
        'user_id': user.id,
        'file_path': publicUrl,
        'file_name': fileName,
        'status': 'pending',
        // Don't set created_at and updated_at manually - let database defaults handle it
      });

      if (kDebugMode) print('✅ [UploadPaymentProof] Payment proof record saved to database');

      // Update booking payment status to 'pending' (waiting for verification)
      await _client
          .from('bookings')
          .update({
            'payment_status': 'pending',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('booking_id', bookingId);

      if (kDebugMode) print('✅ [UploadPaymentProof] Booking payment status updated');
      if (kDebugMode) print('✅ [UploadPaymentProof] Upload completed successfully');

      return publicUrl;
    } catch (e) {
      if (kDebugMode) print('❌ [UploadPaymentProof] Error: $e');
      throw Exception('Failed to upload payment proof: $e');
    }
  }

  /// Read file as bytes (helper function)
  static Future<Uint8List?> _readFileAsBytes(String filePath) async {
    try {
      final file = await _readFile(filePath);
      return file;
    } catch (e) {
      if (kDebugMode) print('❌ [ReadFileAsBytes] Error: $e');
      return null;
    }
  }

  /// Platform-specific file reading
  static Future<Uint8List> _readFile(String filePath) async {
    try {
      // For mobile/desktop platforms
      final file = await File(filePath).readAsBytes();
      return file;
    } catch (e) {
      if (kDebugMode) print('❌ [ReadFile] Error reading file: $e');
      rethrow;
    }
  }

  /// Fetch payment proofs for a booking
  static Future<List<Map<String, dynamic>>> fetchPaymentProofs({
    required String bookingId,
  }) async {
    try {
      if (kDebugMode) print('📝 [FetchPaymentProofs] Fetching proofs for booking: $bookingId');

      final response = await _client
          .from('payment_proofs')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      if (kDebugMode) print('✅ [FetchPaymentProofs] Found ${(response as List).length} proofs');
      return (response).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) print('❌ [FetchPaymentProofs] Error: $e');
      throw Exception('Failed to fetch payment proofs: $e');
    }
  }

  /// Fetch payment proof URL by booking UUID
  static Future<String?> fetchPaymentProofByBookingUuid({
    required String bookingUuid,
  }) async {
    try {
      if (kDebugMode) {
        print(
        '📝 [FetchPaymentProofByUuid] Fetching proof for booking UUID: $bookingUuid',
      );
      }

      final response = await _client
          .from('payment_proofs')
          .select('file_path')
          .eq('booking_id', bookingUuid)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        if (kDebugMode) {
          print(
          'ℹ️ [FetchPaymentProofByUuid] No proof found for booking: $bookingUuid',
        );
        }
        return null;
      }

      final proofUrl = (response as List).first['file_path'] as String?;

      if (proofUrl == null) {
        if (kDebugMode) print('ℹ️ [FetchPaymentProofByUuid] Proof URL is null');
        return null;
      }

      // Extract storage path from public URL and generate signed URL
      // Public URL format: https://[project].supabase.co/storage/v1/object/public/payment-proofs/[path]
      try {
        final uri = Uri.parse(proofUrl);
        final pathSegments = uri.pathSegments;

        // Find the index of 'payment-proofs' in the path
        final bucketIndex = pathSegments.indexOf('payment-proofs');
        if (bucketIndex != -1 && bucketIndex < pathSegments.length - 1) {
          // Extract the storage path after 'payment-proofs'
          final storagePath = pathSegments.sublist(bucketIndex + 1).join('/');
          if (kDebugMode) print('📝 [FetchPaymentProofByUuid] Storage path: $storagePath');

          // Generate signed URL with 1 hour expiry
          final signedUrl = await _client.storage
              .from('payment-proofs')
              .createSignedUrl(storagePath, 3600); // 1 hour

          if (kDebugMode) print('✅ [FetchPaymentProofByUuid] Generated signed URL');
          return signedUrl;
        }
      } catch (e) {
        if (kDebugMode) {
          print(
          '⚠️ [FetchPaymentProofByUuid] Could not generate signed URL, using public URL: $e',
        );
        }
      }

      // Fallback to public URL if signed URL generation fails
      if (kDebugMode) print('✅ [FetchPaymentProofByUuid] Using public URL: $proofUrl');
      return proofUrl;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchPaymentProofByUuid] Error: $e');
      return null;
    }
  }

  /// Verify payment proof (admin only)
  static Future<void> verifyPaymentProof({
    required String proofId,
    required bool isApproved,
    String? rejectionReason,
  }) async {
    try {
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can verify payment proofs');
      }

      if (kDebugMode) print('📝 [VerifyPaymentProof] Verifying proof: $proofId');

      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      // Update payment proof status
      await _client
          .from('payment_proofs')
          .update({
            'status': isApproved ? 'verified' : 'rejected',
            'verified_by': user.id,
            'verified_at': DateTime.now().toIso8601String(),
            'verification_notes': rejectionReason,
            // Don't set updated_at manually - let database defaults handle it
          })
          .eq('id', proofId);

      // If approved, update booking payment status
      if (isApproved) {
        final proofData = await _client
            .from('payment_proofs')
            .select('booking_id')
            .eq('id', proofId)
            .single();

        final bookingId = proofData['booking_id'] as String;

        // Fetch user_id for notification
        final bookingData = await _client
            .from('bookings')
            .select('user_id')
            .eq('id', bookingId)
            .single();

        final userId = bookingData['user_id'] as String;

        await _client
            .from('bookings')
            .update({
              'payment_status': 'verified',
              'status': 'confirmed',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', bookingId);

        // Send notification to user
        try {
          await NotificationHelper.notifyPaymentVerified(
            userId: userId,
            bookingId: bookingId,
          );
          if (kDebugMode) print('✅ [VerifyPaymentProof] Notification sent to user');
        } catch (e) {
          if (kDebugMode) print('⚠️ [VerifyPaymentProof] Failed to send notification: $e');
          // Don't throw error if notification fails
        }
      } else {
        // If rejected, also send notification
        final proofData = await _client
            .from('payment_proofs')
            .select('booking_id')
            .eq('id', proofId)
            .single();

        final bookingId = proofData['booking_id'] as String;

        // Fetch user_id for notification
        final bookingData = await _client
            .from('bookings')
            .select('user_id')
            .eq('id', bookingId)
            .single();

        final userId = bookingData['user_id'] as String;

        // Send notification to user
        try {
          await NotificationHelper.notifyPaymentRejected(
            userId: userId,
            bookingId: bookingId,
          );
          if (kDebugMode) print('✅ [VerifyPaymentProof] Rejection notification sent to user');
        } catch (e) {
          if (kDebugMode) print('⚠️ [VerifyPaymentProof] Failed to send notification: $e');
          // Don't throw error if notification fails
        }
      }

      if (kDebugMode) {
        print(
        '✅ [VerifyPaymentProof] Payment proof ${isApproved ? 'approved' : 'rejected'}',
      );
      }
    } catch (e) {
      if (kDebugMode) print('❌ [VerifyPaymentProof] Error: $e');
      throw Exception('Failed to verify payment proof: $e');
    }
  }

  // ============================================
  // TIME SLOTS MANAGEMENT
  // ============================================

  /// Fetch all time slots untuk field tertentu
  static Future<List<Map<String, dynamic>>> fetchTimeSlots({
    required String fieldId,
  }) async {
    try {
      if (kDebugMode) print('🔍 [FetchTimeSlots] Loading time slots for field: $fieldId');

      final response = await _client
          .from('time_slots')
          .select()
          .eq('field_id', fieldId)
          .order('start_time', ascending: true);

      if (kDebugMode) print('✅ [FetchTimeSlots] Found ${(response as List).length} time slots');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) print('❌ [FetchTimeSlots] Error: $e');
      throw Exception('Failed to fetch time slots: $e');
    }
  }

  /// Create new time slot (admin only)
  static Future<String> createTimeSlot({
    required String fieldId,
    required String startTime,
    required String endTime,
    required int pricePerHour,
    bool isAvailable = true,
    String? specialUsername,
    int? specialPrice,
    bool silentDuplicateError = false,
  }) async {
    try {
      // Check admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can create time slots');
      }

      final data = {
        'field_id': fieldId,
        'start_time': startTime,
        'end_time': endTime,
        'price_per_hour': pricePerHour,
        'is_available': isAvailable,
        'special_username': specialUsername,
        'special_price': specialPrice,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('time_slots')
          .insert(data)
          .select()
          .single();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [CreateTimeSlot] Time slot created: ${response['id']}');
      }
      return response['id'] as String;
    } catch (e) {
      final errorStr = e.toString();
      // Don't log duplicate errors if silentDuplicateError is true
      final isDuplicateError =
          errorStr.contains('duplicate key') ||
          errorStr.contains('23505') ||
          errorStr.contains('unique constraint') ||
          errorStr.contains('time_slots_unique_field_time');

      if (!silentDuplicateError || !isDuplicateError) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [CreateTimeSlot] Error: $e');
        }
      }

      throw Exception('Failed to create time slot: $e');
    }
  }

  /// Update time slot (admin only)
  static Future<void> updateTimeSlot({
    required String timeSlotId,
    String? startTime,
    String? endTime,
    int? pricePerHour,
    bool? isAvailable,
    String? specialUsername,
    int? specialPrice,
  }) async {
    try {
      // Check admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can update time slots');
      }

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (startTime != null) data['start_time'] = startTime;
      if (endTime != null) data['end_time'] = endTime;
      if (pricePerHour != null) data['price_per_hour'] = pricePerHour;
      if (isAvailable != null) data['is_available'] = isAvailable;
      if (specialUsername != null) data['special_username'] = specialUsername;
      if (specialPrice != null) data['special_price'] = specialPrice;

      await _client.from('time_slots').update(data).eq('id', timeSlotId);

      if (kDebugMode) print('✅ [UpdateTimeSlot] Time slot updated: $timeSlotId');
    } catch (e) {
      if (kDebugMode) print('❌ [UpdateTimeSlot] Error: $e');
      throw Exception('Failed to update time slot: $e');
    }
  }

  /// Delete time slot (admin only)
  static Future<void> deleteTimeSlot(String timeSlotId) async {
    try {
      // Check admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can delete time slots');
      }

      await _client.from('time_slots').delete().eq('id', timeSlotId);

      if (kDebugMode) print('✅ [DeleteTimeSlot] Time slot deleted: $timeSlotId');
    } catch (e) {
      if (kDebugMode) print('❌ [DeleteTimeSlot] Error: $e');
      throw Exception('Failed to delete time slot: $e');
    }
  }

  /// Block time slot for specific date (admin only)
  /// Creates an admin booking to block the time slot
  /// Clean up all ADMIN_BLOCK bookings (admin only)
  /// Removes all admin block bookings from the database
  static Future<void> cleanupAdminBlocks() async {
    try {
      // Check admin
      final currentUserIsAdmin = await isAdmin();
      if (!currentUserIsAdmin) {
        throw Exception('Only admins can cleanup admin blocks');
      }

      // Delete all ADMIN_BLOCK bookings
      await _client.from('bookings').delete().eq('notes', 'ADMIN_BLOCK');

      if (kDebugMode) {
        print(
        '✅ [CleanupAdminBlocks] All ADMIN_BLOCK bookings deleted successfully',
      );
      }
    } catch (e) {
      if (kDebugMode) print('❌ [CleanupAdminBlocks] Error: $e');
      throw Exception('Failed to cleanup admin blocks: $e');
    }
  }

  /// Get time slots untuk user tertentu (termasuk harga khusus)
  /// Returns list of time slots dengan harga yang sudah disesuaikan
  static Future<List<Map<String, dynamic>>> getTimeSlotsForUser({
    required String fieldId,
    String? username,
  }) async {
    try {
      if (kDebugMode) {
        print(
        '🔍 [GetTimeSlotsForUser] Loading for field: $fieldId, user: $username',
      );
      }

      final timeSlots = await fetchTimeSlots(fieldId: fieldId);

      // Jika username provided, cek apakah ada special price
      if (username != null) {
        for (var slot in timeSlots) {
          final specialUsername = slot['special_username'] as String?;
          final specialPrice = slot['special_price'] as int?;

          if (specialUsername != null &&
              specialUsername.toLowerCase() == username.toLowerCase() &&
              specialPrice != null) {
            // Tambahkan field untuk tracking
            slot['effective_price'] = specialPrice;
            slot['is_special_price'] = true;
            if (kDebugMode) {
              print(
              '💰 [GetTimeSlotsForUser] Special price for $username: $specialPrice',
            );
            }
          } else {
            slot['effective_price'] = slot['price_per_hour'];
            slot['is_special_price'] = false;
          }
        }
      } else {
        // No username, use normal price
        for (var slot in timeSlots) {
          slot['effective_price'] = slot['price_per_hour'];
          slot['is_special_price'] = false;
        }
      }

      if (kDebugMode) print('✅ [GetTimeSlotsForUser] Loaded ${timeSlots.length} time slots');
      return timeSlots;
    } catch (e) {
      if (kDebugMode) print('❌ [GetTimeSlotsForUser] Error: $e');
      throw Exception('Failed to get time slots for user: $e');
    }
  }

  // ============================================
  // REVIEWS MANAGEMENT
  // ============================================

  /// Create a new review for a booking
  static Future<void> createReview({
    required String bookingId, // UUID of booking
    required int rating,
    String? comment,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in to create a review');
      }

      if (kDebugMode) print('📝 [CreateReview] Creating review for booking: $bookingId');
      if (kDebugMode) {
        print(
        '📝 [CreateReview] Rating: $rating, Comment: ${comment != null ? "Yes" : "No"}',
      );
      }

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Check if booking exists and belongs to user
      final bookingData = await _client
          .from('bookings')
          .select('id, user_id, status, field_id')
          .eq('id', bookingId)
          .single();

      if (bookingData['user_id'] != user.id) {
        throw Exception('You can only review your own bookings');
      }

      // Check if booking is completed
      if (bookingData['status'] != 'completed') {
        throw Exception('You can only review completed bookings');
      }

      // Check if review already exists
      final existingReview = await _client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .limit(1);

      if (existingReview.isNotEmpty) {
        throw Exception('You have already reviewed this booking');
      }

      // IMPORTANT: Since venues table no longer exists, we use field_id as venue_id
      // All venue data is now stored in fields table
      // The database schema still requires venue_id (NOT NULL constraint)
      // So we use field_id as venue_id for backward compatibility
      final fieldId = bookingData['field_id'] as String;

      // Insert review
      // Note: Don't manually set created_at and updated_at - let database handle with defaults
      // RLS Policy Required: Allow authenticated users to INSERT where user_id = auth.uid()
      try {
        await _client.from('reviews').insert({
          'booking_id': bookingId,
          'user_id': user.id,
          'venue_id':
              fieldId, // Use field_id as venue_id since venues table doesn't exist
          'rating': rating,
          'comment': comment,
        });
        if (kDebugMode) print('✅ [CreateReview] Review created successfully');

        // No need to update venue rating since there's no venues table
        // Ratings are calculated dynamically from reviews
      } on PostgrestException catch (e) {
        if (kDebugMode) print('❌ [CreateReview] PostgrestException: ${e.message}');
        if (kDebugMode) print('❌ [CreateReview] Code: ${e.code}, Details: ${e.details}');

        // Check if it's an RLS policy error
        if (e.code == '42501') {
          if (kDebugMode) print('');
          if (kDebugMode) {
            print(
            '╔════════════════════════════════════════════════════════════╗',
          );
          }
          if (kDebugMode) {
            print(
            '║          ⚠️  RLS POLICY ERROR - ACTION REQUIRED           ║',
          );
          }
          if (kDebugMode) {
            print(
            '╠════════════════════════════════════════════════════════════╣',
          );
          }
          if (kDebugMode) {
            print(
            '║ The reviews table is missing an INSERT policy.            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ To fix this, run in Supabase SQL Editor:                  ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ CREATE POLICY "Users can insert their own reviews"        ║',
          );
          }
          if (kDebugMode) {
            print(
            '║   ON reviews FOR INSERT                                    ║',
          );
          }
          if (kDebugMode) {
            print(
            '║   WITH CHECK (auth.uid() = user_id);                       ║',
          );
          }
          if (kDebugMode) {
            print(
            '║                                                            ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ Or in Supabase Dashboard:                                 ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ 1. Go to Authentication > Policies                        ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ 2. Select "reviews" table                                 ║',
          );
          }
          if (kDebugMode) {
            print(
            '║ 3. Add INSERT policy with CHECK: auth.uid() = user_id     ║',
          );
          }
          if (kDebugMode) {
            print(
            '╚════════════════════════════════════════════════════════════╝',
          );
          }
          if (kDebugMode) print('');

          throw Exception(
            'Database permission error: RLS policy not configured.\n'
            'Please contact administrator to enable review submissions.',
          );
        }

        throw Exception('Database error: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [CreateReview] Error: $e');
      throw Exception('Failed to create review: $e');
    }
  }

  /// Update venue rating based on all reviews
  /// Note: Since there's no separate venues table, this is a no-op
  /// Rating calculations would need to be done dynamically from reviews
  static Future<void> _updateVenueRating(String venueId) async {
    try {
      if (kDebugMode) {
        print(
        '📊 [UpdateVenueRating] Skipping venue rating update (no venues table)',
      );
      }
      if (kDebugMode) print('   Venue ID: $venueId');

      // Get all reviews for this venue through bookings for logging
      final reviews = await fetchReviewsByVenueId(venueId: venueId);

      if (reviews.isEmpty) {
        if (kDebugMode) print('ℹ️  [UpdateVenueRating] No reviews found for this venue');
      } else {
        // Calculate average rating for logging
        final totalRating = reviews.fold<int>(
          0,
          (sum, review) => sum + (review['rating'] as int),
        );
        final averageRating = totalRating / reviews.length;
        if (kDebugMode) {
          print(
          'ℹ️  [UpdateVenueRating] Venue has rating: ${averageRating.toStringAsFixed(2)} from ${reviews.length} reviews',
        );
        }
        if (kDebugMode) print('   Note: Rating not persisted (no venues table)');
      }
    } catch (e) {
      if (kDebugMode) print('❌ [UpdateVenueRating] Error: $e');
      // Don't throw error, as review was already created successfully
      // Rating update failure should not block the review submission
    }
  }

  /// Fetch review for a specific booking
  static Future<Map<String, dynamic>?> fetchReviewByBookingId({
    required String bookingId, // UUID of booking
  }) async {
    try {
      if (kDebugMode) {
        print(
        '📝 [FetchReviewByBookingId] Fetching review for booking: $bookingId',
      );
      }

      final response = await _client
          .from('reviews')
          .select()
          .eq('booking_id', bookingId)
          .limit(1);

      if (response.isEmpty) {
        if (kDebugMode) {
          print(
          'ℹ️ [FetchReviewByBookingId] No review found for booking: $bookingId',
        );
        }
        return null;
      }

      final review = (response as List).first as Map<String, dynamic>;
      if (kDebugMode) {
        print(
        '✅ [FetchReviewByBookingId] Review found: Rating ${review['rating']}',
      );
      }
      return review;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchReviewByBookingId] Error: $e');
      return null;
    }
  }

  /// Update an existing review
  static Future<void> updateReview({
    required String reviewId,
    required int rating,
    String? comment,
  }) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in to update a review');
      }

      if (kDebugMode) print('📝 [UpdateReview] Updating review: $reviewId');

      // Validate rating
      if (rating < 1 || rating > 5) {
        throw Exception('Rating must be between 1 and 5');
      }

      // Get venue_id before updating
      String? venueId;
      try {
        final reviewData = await _client
            .from('reviews')
            .select('bookings(venue_id)')
            .eq('id', reviewId)
            .single();
        venueId =
            (reviewData['bookings'] as Map<String, dynamic>?)?['venue_id']
                as String?;
      } catch (e) {
        if (kDebugMode) print('⚠️ [UpdateReview] Could not fetch venue_id: $e');
      }

      await _client
          .from('reviews')
          .update({
            'rating': rating,
            'comment': comment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reviewId)
          .eq('user_id', user.id); // Ensure user owns the review

      if (kDebugMode) print('✅ [UpdateReview] Review updated successfully');

      // Update venue rating after review is updated
      if (venueId != null) {
        await _updateVenueRating(venueId);
      }
    } catch (e) {
      if (kDebugMode) print('❌ [UpdateReview] Error: $e');
      throw Exception('Failed to update review: $e');
    }
  }

  /// Delete a review
  static Future<void> deleteReview({required String reviewId}) async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('User must be logged in to delete a review');
      }

      if (kDebugMode) print('📝 [DeleteReview] Deleting review: $reviewId');

      // Get venue_id before deleting
      String? venueId;
      try {
        final reviewData = await _client
            .from('reviews')
            .select('bookings(venue_id)')
            .eq('id', reviewId)
            .single();
        venueId =
            (reviewData['bookings'] as Map<String, dynamic>?)?['venue_id']
                as String?;
      } catch (e) {
        if (kDebugMode) print('⚠️ [DeleteReview] Could not fetch venue_id: $e');
      }

      await _client
          .from('reviews')
          .delete()
          .eq('id', reviewId)
          .eq('user_id', user.id); // Ensure user owns the review

      if (kDebugMode) print('✅ [DeleteReview] Review deleted successfully');

      // Update venue rating after review is deleted
      if (venueId != null) {
        await _updateVenueRating(venueId);
      }
    } catch (e) {
      if (kDebugMode) print('❌ [DeleteReview] Error: $e');
      throw Exception('Failed to delete review: $e');
    }
  }

  /// Fetch all reviews with booking details for admin
  static Future<List<Map<String, dynamic>>>
  fetchAllReviewsWithBookings() async {
    try {
      if (kDebugMode) {
        print(
        '📝 [FetchAllReviewsWithBookings] Fetching all reviews with booking details',
      );
      }

      // Fetch reviews with booking info (without fields join)
      final response = await _client
          .from('reviews')
          .select('''
            *,
            bookings!inner(
              booking_id,
              booking_date,
              user_id,
              field_id,
              venue_id,
              profiles!inner(full_name)
            )
          ''')
          .order('created_at', ascending: false);

      // Fetch all fields to map field_id to field details
      final fieldsResponse = await _client
          .from('fields')
          .select('id, venue_name, area');
      final fieldsMap = <String, Map<String, dynamic>>{};
      for (final field in fieldsResponse as List) {
        fieldsMap[field['id'] as String] = field as Map<String, dynamic>;
      }

      // Transform the response to flatten the data
      final reviews = (response as List).map((review) {
        final booking = review['bookings'] as Map<String, dynamic>?;
        final profile = booking?['profiles'] as Map<String, dynamic>?;
        final fieldId = booking?['field_id'] as String?;
        final field = fieldId != null ? fieldsMap[fieldId] : null;

        return {
          'id': review['id'],
          'booking_id': booking?['booking_id'],
          'user_id': review['user_id'],
          'rating': review['rating'],
          'comment': review['comment'],
          'created_at': review['created_at'],
          'updated_at': review['updated_at'],
          'user_name': profile?['full_name'],
          'venue_name': field?['venue_name'],
          'field_area': field?['area'],
          'booking_date': booking?['booking_date'],
        };
      }).toList();

      if (kDebugMode) {
        print(
        '✅ [FetchAllReviewsWithBookings] Fetched ${reviews.length} reviews',
      );
      }
      return reviews;
    } catch (e) {
      if (kDebugMode) print('❌ [FetchAllReviewsWithBookings] Error: $e');
      return [];
    }
  }

  /// Fetch reviews for a specific venue
  /// Fetch reviews by venue ID
  /// [venueId] must be a valid String UUID matching the venue_id column type in database
  static Future<List<Map<String, dynamic>>> fetchReviewsByVenueId({
    required String venueId,
  }) async {
    try {
      if (kDebugMode) print('🔍 [FetchReviewsByVenueId] ===== START =====');
      if (kDebugMode) print('📝 [FetchReviewsByVenueId] Fetching reviews for venue: $venueId');
      if (kDebugMode) print('📝 [FetchReviewsByVenueId] VenueId type: ${venueId.runtimeType}');

      // Validate venueId is not empty
      if (venueId.trim().isEmpty) {
        if (kDebugMode) print('❌ [FetchReviewsByVenueId] Invalid venueId: empty string');
        return [];
      }

      // DEBUG: Test if we can access reviews table at all (without RLS filter)
      try {
        final allReviewsTest = await _client
            .from('reviews')
            .select('id, booking_id')
            .limit(5);
        if (kDebugMode) {
          print(
          '🧪 [DEBUG] Reviews table accessible: ${allReviewsTest.length} reviews found',
        );
        }
        if (allReviewsTest.isNotEmpty) {
          final sampleBookingIds = (allReviewsTest as List)
              .map((r) => r['booking_id'])
              .take(3)
              .join(", ");
          if (kDebugMode) print('🧪 [DEBUG] Sample booking_ids in reviews: $sampleBookingIds');
        }
      } catch (e) {
        if (kDebugMode) print('🧪 [DEBUG] ERROR accessing reviews table: $e');
      }

      // STRATEGY: Query reviews directly with bookings join to bypass RLS
      // RLS on bookings table blocks direct queries, but joins work fine

      // First try: Query reviews with booking.venue_id = venueId
      // Ensure venueId is passed as String for UUID comparison
      var response = await _client
          .from('reviews')
          .select('''
            id,
            user_id,
            booking_id,
            rating,
            comment,
            created_at,
            profiles!reviews_user_id_fkey(full_name, avatar_url),
            bookings!inner(venue_id)
          ''')
          .eq(
            'bookings.venue_id',
            venueId.toString(),
          ) // Explicit String conversion
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print(
        '📝 [FetchReviewsByVenueId] Strategy 1 (venue_id): Found ${response.length} reviews',
      );
      }

      // Fallback: If no results, try using field_id
      if (response.isEmpty) {
        if (kDebugMode) {
          print(
          '⚠️ [FetchReviewsByVenueId] Strategy 1 failed, trying Strategy 2 (field_id)...',
        );
        }

        // Get all fields for this venue
        // Ensure venueId is passed as String for UUID comparison
        final fieldsResponse = await _client
            .from('fields')
            .select('id')
            .eq('venue_id', venueId.toString()); // Explicit String conversion

        final fieldIds = (fieldsResponse as List)
            .map((field) => field['id'] as String)
            .toList();

        if (kDebugMode) {
          print(
          '📝 [FetchReviewsByVenueId] Strategy 2: Found ${fieldIds.length} fields',
        );
        }
        if (kDebugMode) {
          print(
          '🧪 [DEBUG] Field IDs: ${fieldIds.take(3).join(", ")}${fieldIds.length > 3 ? "..." : ""}',
        );
        }

        if (fieldIds.isEmpty) {
          if (kDebugMode) print('❌ [FetchReviewsByVenueId] No fields found for venue');
          if (kDebugMode) print('🔍 [FetchReviewsByVenueId] ===== END (No Fields) =====');
          return [];
        }

        // DEBUG: Test if we can query reviews with this field using left join (less restrictive)
        try {
          final testQuery = await _client
              .from('reviews')
              .select('id, booking_id, bookings(field_id)')
              .inFilter('bookings.field_id', fieldIds)
              .limit(5);
          if (kDebugMode) {
            print(
            '🧪 [DEBUG] Test query with left join: ${testQuery.length} results',
          );
          }
          if (testQuery.isNotEmpty) {
            if (kDebugMode) print('🧪 [DEBUG] Sample result: ${testQuery[0]}');
          }
        } catch (e) {
          if (kDebugMode) print('🧪 [DEBUG] Test query error: $e');
        }

        // Query reviews with booking.field_id IN (fieldIds)
        response = await _client
            .from('reviews')
            .select('''
              id,
              user_id,
              booking_id,
              rating,
              comment,
              created_at,
              profiles!reviews_user_id_fkey(full_name, avatar_url),
              bookings!inner(field_id)
            ''')
            .inFilter('bookings.field_id', fieldIds)
            .order('created_at', ascending: false);

        if (kDebugMode) {
          print(
          '📝 [FetchReviewsByVenueId] Strategy 2 (field_id): Found ${response.length} reviews',
        );
        }
      }

      if (response.isEmpty) {
        if (kDebugMode) print('❌ [FetchReviewsByVenueId] No reviews found for venue $venueId');
        if (kDebugMode) print('🔍 [FetchReviewsByVenueId] ===== END (No Reviews) =====');
        return [];
      }

      if (kDebugMode) {
        print(
        '📝 [FetchReviewsByVenueId] Raw response: ${response.length} reviews',
      );
      }
      if (response.isNotEmpty) {
        if (kDebugMode) {
          print(
          '📝 [FetchReviewsByVenueId] First review: ${(response as List)[0]}',
        );
        }
      }

      // Transform the response to flatten the data
      final reviews = (response as List).map((review) {
        final profile = review['profiles'] as Map<String, dynamic>?;

        return {
          'id': review['id'],
          'user_id': review['user_id'],
          'booking_id': review['booking_id'],
          'rating': review['rating'],
          'comment': review['comment'],
          'created_at': review['created_at'],
          'user_name': profile?['full_name'] ?? 'User',
          'user_avatar': profile?['avatar_url'],
        };
      }).toList();

      if (kDebugMode) {
        print(
        '✅ [FetchReviewsByVenueId] Fetched ${reviews.length} reviews for venue $venueId',
      );
      }
      if (kDebugMode) print('🔍 [FetchReviewsByVenueId] ===== END (Success) =====');
      return reviews;
    } catch (e, stackTrace) {
      if (kDebugMode) print('❌ [FetchReviewsByVenueId] Error: $e');
      if (kDebugMode) print('❌ [FetchReviewsByVenueId] Stack: $stackTrace');
      if (kDebugMode) print('🔍 [FetchReviewsByVenueId] ===== END (Error) =====');
      return [];
    }
  }

  /// Fetch reviews by venue name (FALLBACK when venue_id is not available)
  /// This is a workaround for when fields don't have venue_id set up properly
  static Future<List<Map<String, dynamic>>> fetchReviewsByVenueName({
    required String venueName,
  }) async {
    try {
      if (kDebugMode) print('🔍 [FetchReviewsByVenueName] ===== START =====');
      if (kDebugMode) {
        print(
        '📝 [FetchReviewsByVenueName] Fetching reviews for venue name: "$venueName"',
      );
      }
      if (kDebugMode) {
        print(
        '⚠️ [FetchReviewsByVenueName] This is FALLBACK method - venue_id should be fixed in database!',
      );
      }

      // Get all fields for this venue name
      final fieldsResponse = await _client
          .from('fields')
          .select('id')
          .ilike('venue_name', '%$venueName%');

      final fieldIds = (fieldsResponse as List)
          .map((field) => field['id'] as String)
          .toList();

      if (kDebugMode) {
        print(
        '📝 [FetchReviewsByVenueName] Found ${fieldIds.length} fields matching venue name',
      );
      }

      if (fieldIds.isEmpty) {
        if (kDebugMode) {
          print(
          '❌ [FetchReviewsByVenueName] No fields found for venue "$venueName"',
        );
        }
        if (kDebugMode) print('🔍 [FetchReviewsByVenueName] ===== END (No Fields) =====');
        return [];
      }

      // Query reviews with booking.field_id IN (fieldIds) using join to bypass RLS
      final response = await _client
          .from('reviews')
          .select('''
            id,
            user_id,
            booking_id,
            rating,
            comment,
            created_at,
            profiles!reviews_user_id_fkey(full_name, avatar_url),
            bookings!inner(field_id)
          ''')
          .inFilter('bookings.field_id', fieldIds)
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print(
        '📝 [FetchReviewsByVenueName] Raw response: ${response.length} reviews',
      );
      }
      if (response.isNotEmpty) {
        if (kDebugMode) {
          print(
          '📝 [FetchReviewsByVenueName] First review: ${(response as List)[0]}',
        );
        }
      }

      // Transform the response to flatten the data
      final reviews = (response as List).map((review) {
        final profile = review['profiles'] as Map<String, dynamic>?;

        return {
          'id': review['id'],
          'user_id': review['user_id'],
          'booking_id': review['booking_id'],
          'rating': review['rating'],
          'comment': review['comment'],
          'created_at': review['created_at'],
          'user_name': profile?['full_name'] ?? 'User',
          'user_avatar': profile?['avatar_url'],
        };
      }).toList();

      if (kDebugMode) {
        print(
        '✅ [FetchReviewsByVenueName] Fetched ${reviews.length} reviews for venue "$venueName"',
      );
      }
      if (kDebugMode) print('🔍 [FetchReviewsByVenueName] ===== END (Success) =====');
      return reviews;
    } catch (e, stackTrace) {
      if (kDebugMode) print('❌ [FetchReviewsByVenueName] Error: $e');
      if (kDebugMode) print('❌ [FetchReviewsByVenueName] Stack: $stackTrace');
      if (kDebugMode) print('🔍 [FetchReviewsByVenueName] ===== END (Error) =====');
      return [];
    }
  }

  /// Stream reviews for a venue with real-time updates.
  /// Only shows reviews from users who have a completed booking for this venue.
  ///
  /// PERFORMANCE: Uses batch queries to eliminate N+1 pattern:
  ///   - 1 stream trigger (reviews table change)
  ///   - 1 batch query  (fetch bookings for all review booking_ids)
  ///   - 1 batch query  (fetch profiles for all reviewer user_ids)
  ///   Total: O(3) queries per update, regardless of review count.
  ///
  /// [venueId] UUID — typically `field.id` since venue data is stored in fields table.
  static Stream<List<Map<String, dynamic>>> streamReviewsByVenueId({
    required String venueId,
    bool debugMode = false,
  }) async* {
    if (kDebugMode) {
      if (kDebugMode) print('🔍 [StreamReviewsByVenueId] Starting stream for venue: $venueId');
    }

    if (venueId.trim().isEmpty) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [StreamReviewsByVenueId] Invalid venueId: empty string');
      }
      yield [];
      return;
    }

    try {
      await for (final _ in _client
          .from('reviews')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)) {
        try {
          // STEP 1: Fetch all reviews (triggered by stream — lightweight)
          final allReviews = await _client
              .from('reviews')
              .select('id, booking_id, user_id, rating, comment, created_at')
              .order('created_at', ascending: false);

          if (allReviews.isEmpty) {
            yield [];
            continue;
          }

          // STEP 2: Collect booking IDs — BATCH fetch all at once (1 query, not N)
          final bookingIds = allReviews
              .map((r) => r['booking_id'] as String?)
              .where((id) => id != null && id.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList();

          if (bookingIds.isEmpty) {
            yield [];
            continue;
          }

          final bookings = await _client
              .from('bookings')
              .select('id, venue_id, field_id')
              .inFilter('id', bookingIds);

          // Build O(1) lookup map
          final bookingMap = <String, Map<String, dynamic>>{
            for (final b in bookings)
              b['id'] as String: b,
          };

          // STEP 3: Filter reviews for this venue (client-side, O(n))
          // venueId matches booking.venue_id OR booking.field_id
          // (field_id is used as venueId since there is no separate venues table)
          final venueReviews = allReviews.where((r) {
            final b = bookingMap[r['booking_id'] as String? ?? ''];
            if (b == null) return false;
            return b['venue_id'] == venueId || b['field_id'] == venueId;
          }).toList();

          if (venueReviews.isEmpty) {
            yield [];
            continue;
          }

          // STEP 4: Batch fetch profiles for all reviewers (1 query, not N)
          final userIds = venueReviews
              .map((r) => r['user_id'] as String? ?? '')
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

          final profiles = await _client
              .from('profiles')
              .select('id, full_name, avatar_url')
              .inFilter('id', userIds);

          final profileMap = <String, Map<String, dynamic>>{
            for (final p in profiles)
              p['id'] as String: p,
          };

          // STEP 5: Map to final format
          final reviewsWithProfiles = venueReviews.map((review) {
            final profile = profileMap[review['user_id'] as String? ?? ''];
            return <String, dynamic>{
              'id': review['id'],
              'user_id': review['user_id'],
              'booking_id': review['booking_id'],
              'rating': review['rating'],
              'comment': review['comment'],
              'created_at': review['created_at'],
              'user_name': profile?['full_name'] as String? ?? 'User',
              'user_avatar': profile?['avatar_url'],
            };
          }).toList();

          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '✅ [StreamReviewsByVenueId] Yielding ${reviewsWithProfiles.length} reviews '
              '(from ${allReviews.length} total, ${venueReviews.length} for this venue)',
            );
            }
          }

          yield reviewsWithProfiles;
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [StreamReviewsByVenueId] Error processing stream update: $e');
          }
          yield [];
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [StreamReviewsByVenueId] Stream error: $e');
      yield [];
    }
  }
}
