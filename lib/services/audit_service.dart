import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Audit log model
class AuditLog {
  final String id;
  final String userId;
  final String userName;
  final String action;
  final String entityType;
  final String? entityId;
  final Map<String, dynamic>? changes;
  final DateTime createdAt;

  AuditLog({
    required this.id,
    required this.userId,
    required this.userName,
    required this.action,
    required this.entityType,
    this.entityId,
    this.changes,
    required this.createdAt,
  });

  factory AuditLog.fromJson(Map<String, dynamic> json) {
    return AuditLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown',
      action: json['action'] as String,
      entityType: json['entity_type'] as String,
      entityId: json['entity_id'] as String?,
      changes: json['changes'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'changes': changes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Service for managing audit logs
class AuditService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Log an admin action
  static Future<void> logAction({
    required String action,
    required String entityType,
    String? entityId,
    Map<String, dynamic>? changes,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // Get user name from profile
      String userName = 'Admin';
      try {
        final profile = await _client
            .from('profiles')
            .select('full_name, username')
            .eq('id', user.id)
            .single();
        userName =
            profile['full_name'] as String? ??
            profile['username'] as String? ??
            'Admin';
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('Warning: Could not fetch user profile for audit log');
        }
      }

      await _client.from('audit_logs').insert({
        'user_id': user.id,
        'user_name': userName,
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'changes': changes,
        'created_at': DateTime.now().toIso8601String(),
      });

      if (kDebugMode) {
        if (kDebugMode) print('✅ [AuditLog] Logged action: $action on $entityType');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [AuditLog] Error logging action: $e');
      }
      // Don't throw - audit failures should not break main functionality
    }
  }

  /// Fetch all audit logs with pagination
  static Future<List<AuditLog>> fetchAuditLogs({
    int limit = 100,
    int offset = 0,
    String? entityType,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('audit_logs').select();

      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final logs = (response as List)
          .map((json) => AuditLog.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ [AuditService] Fetched ${logs.length} audit logs');
      }

      return logs;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [AuditService] Error fetching audit logs: $e');
      }
      throw Exception('Failed to fetch audit logs: $e');
    }
  }

  /// Get total count of audit logs
  static Future<int> getTotalAuditLogsCount({
    String? entityType,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _client.from('audit_logs').select('id');

      if (entityType != null) {
        query = query.eq('entity_type', entityType);
      }

      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.count();
      return response.count;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [AuditService] Error getting audit logs count: $e');
      }
      return 0;
    }
  }
}
