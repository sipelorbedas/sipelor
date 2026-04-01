import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/staff.dart';

/// Model for available users (not yet staff)
class AvailableUser {
  final String id;
  final String username;
  final String email;
  final String? fullName;

  AvailableUser({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
  });

  factory AvailableUser.fromJson(Map<String, dynamic> json) {
    return AvailableUser(
      id: json['id'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
    );
  }

  String get displayName => fullName ?? username;
}

/// Service for managing staff/operators
class StaffService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all staff members
  static Future<List<Staff>> fetchAllStaff() async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .order('created_at', ascending: false);

      final List<Staff> staff = (response as List)
          .map((json) => Staff.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched ${staff.length} staff members');
      }

      return staff;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching staff: $e');
      }
      rethrow;
    }
  }

  /// Fetch staff by ID
  static Future<Staff?> fetchStaffById(String staffId) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .eq('id', staffId)
          .single();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched staff: $staffId');
      }

      return Staff.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching staff: $e');
      }
      return null;
    }
  }

  /// Fetch staff by user ID
  static Future<Staff?> fetchStaffByUserId(String userId) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .eq('user_id', userId)
          .single();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched staff for user: $userId');
      }

      return Staff.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching staff by user ID: $e');
      }
      return null;
    }
  }

  /// Create new staff member
  static Future<Staff> createStaff({
    required String userId,
    required String name,
    required String email,
    String? phone,
    required StaffRole role,
    required List<String> assignedVenues,
  }) async {
    try {
      final response = await _client.from('staff').insert({
        'user_id': userId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.value,
        'assigned_venues': assignedVenues,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final staff = Staff.fromJson(response);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Created staff: ${staff.name}');
      }

      return staff;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error creating staff: $e');
      }
      rethrow;
    }
  }

  /// Update staff member
  static Future<Staff> updateStaff({
    required String staffId,
    String? name,
    String? phone,
    StaffRole? role,
    List<String>? assignedVenues,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (role != null) updateData['role'] = role.value;
      if (assignedVenues != null) updateData['assigned_venues'] = assignedVenues;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _client
          .from('staff')
          .update(updateData)
          .eq('id', staffId)
          .select()
          .single();

      final staff = Staff.fromJson(response);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Updated staff: $staffId');
      }

      return staff;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error updating staff: $e');
      }
      rethrow;
    }
  }

  /// Delete staff member
  static Future<void> deleteStaff(String staffId) async {
    try {
      await _client.from('staff').delete().eq('id', staffId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Deleted staff: $staffId');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error deleting staff: $e');
      }
      rethrow;
    }
  }

  /// Toggle staff active status
  static Future<void> toggleStaffStatus(String staffId, bool isActive) async {
    try {
      await _client.from('staff').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', staffId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Toggled staff status: $staffId -> $isActive');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error toggling staff status: $e');
      }
      rethrow;
    }
  }

  /// Fetch staff by venue ID
  static Future<List<Staff>> fetchStaffByVenue(String venueId) async {
    try {
      final response = await _client
          .from('staff')
          .select()
          .contains('assigned_venues', [venueId])
          .eq('is_active', true);

      final List<Staff> staff = (response as List)
          .map((json) => Staff.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched ${staff.length} staff for venue: $venueId');
      }

      return staff;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching staff by venue: $e');
      }
      rethrow;
    }
  }

  /// Update staff last login
  static Future<void> updateLastLogin(String staffId) async {
    try {
      await _client.from('staff').update({
        'last_login': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', staffId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Updated last login for staff: $staffId');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error updating last login: $e');
      }
      // Non-critical error, don't rethrow
    }
  }

  /// Fetch users who are not yet staff members
  static Future<List<AvailableUser>> fetchAvailableUsers() async {
    try {
      // First, get all user IDs who are already staff
      final staffResponse = await _client
          .from('staff')
          .select('user_id');

      final staffUserIds = (staffResponse as List)
          .map((s) => s['user_id'] as String)
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('📝 Found ${staffUserIds.length} existing staff members');
      }

      // Then, get all users from profiles who are NOT in staff
      final usersQuery = _client
          .from('profiles')
          .select('id, username, email, full_name')
          .order('username', ascending: true);

      // Filter out users who are already staff
      final usersResponse = await usersQuery;

      final availableUsers = (usersResponse as List)
          .where((user) => !staffUserIds.contains(user['id']))
          .map((json) => AvailableUser.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Found ${availableUsers.length} available users for staff assignment');
      }

      return availableUsers;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching available users: $e');
      }
      rethrow;
    }
  }
}
