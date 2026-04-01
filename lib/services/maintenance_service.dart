import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/maintenance_schedule.dart';

/// Service for managing venue maintenance schedules
class MaintenanceService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all maintenance schedules
  static Future<List<MaintenanceSchedule>>
  fetchAllMaintenanceSchedules() async {
    try {
      final response = await _client
          .from('maintenance_schedules')
          .select('*, venues(name), fields(area), staff(name)')
          .order('start_date', ascending: false);

      final List<MaintenanceSchedule> schedules = (response as List)
          .map(
            (json) =>
                MaintenanceSchedule.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched ${schedules.length} maintenance schedules');
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching maintenance schedules: $e');
      }
      rethrow;
    }
  }

  /// Fetch upcoming maintenance schedules
  static Future<List<MaintenanceSchedule>> fetchUpcomingMaintenance() async {
    try {
      final now = DateTime.now().toIso8601String();

      final response = await _client
          .from('maintenance_schedules')
          .select('*, venues(name), fields(area), staff(name)')
          .gte('start_date', now)
          .neq('status', 'cancelled')
          .order('start_date', ascending: true)
          .limit(20);

      final List<MaintenanceSchedule> schedules = (response as List)
          .map(
            (json) =>
                MaintenanceSchedule.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched ${schedules.length} upcoming maintenance schedules');
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching upcoming maintenance: $e');
      }
      rethrow;
    }
  }

  /// Fetch maintenance schedules by venue
  static Future<List<MaintenanceSchedule>> fetchMaintenanceByVenue(
    String venueId,
  ) async {
    try {
      final response = await _client
          .from('maintenance_schedules')
          .select('*, venues(name), fields(area), staff(name)')
          .eq('venue_id', venueId)
          .order('start_date', ascending: false);

      final List<MaintenanceSchedule> schedules = (response as List)
          .map(
            (json) =>
                MaintenanceSchedule.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        if (kDebugMode) {
          print(
          '✅ Fetched ${schedules.length} maintenance schedules for venue: $venueId',
        );
        }
      }

      return schedules;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching maintenance by venue: $e');
      }
      rethrow;
    }
  }

  /// Create new maintenance schedule
  static Future<MaintenanceSchedule> createMaintenanceSchedule({
    required String venueId,
    String? fieldId,
    required String title,
    String? description,
    required DateTime startDate,
    required DateTime endDate,
    String? assignedTo,
  }) async {
    try {
      final response = await _client
          .from('maintenance_schedules')
          .insert({
            'venue_id': venueId,
            'field_id': fieldId,
            'title': title,
            'description': description,
            'start_date': startDate.toIso8601String(),
            'end_date': endDate.toIso8601String(),
            'status': MaintenanceStatus.scheduled.value,
            'assigned_to': assignedTo,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('*, venues(name), fields(area), staff(name)')
          .single();

      final schedule = MaintenanceSchedule.fromJson(
        response,
      );

      // Update field status to maintenance if field specified
      if (fieldId != null) {
        await _client
            .from('fields')
            .update({
              'status': 'maintenance',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', fieldId);
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ Created maintenance schedule: ${schedule.title}');
      }

      return schedule;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error creating maintenance schedule: $e');
      }
      rethrow;
    }
  }

  /// Update maintenance schedule
  static Future<MaintenanceSchedule> updateMaintenanceSchedule({
    required String scheduleId,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    MaintenanceStatus? status,
    String? assignedTo,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (description != null) updateData['description'] = description;
      if (startDate != null) {
        updateData['start_date'] = startDate.toIso8601String();
      }
      if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
      if (status != null) updateData['status'] = status.value;
      if (assignedTo != null) updateData['assigned_to'] = assignedTo;
      if (notes != null) updateData['notes'] = notes;

      final response = await _client
          .from('maintenance_schedules')
          .update(updateData)
          .eq('id', scheduleId)
          .select('*, venues(name), fields(area), staff(name)')
          .single();

      final schedule = MaintenanceSchedule.fromJson(
        response,
      );

      // Update field status if maintenance completed
      if (status == MaintenanceStatus.completed && schedule.fieldId != null) {
        await _client
            .from('fields')
            .update({
              'status': 'available',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', schedule.fieldId!);
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ Updated maintenance schedule: $scheduleId');
      }

      return schedule;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error updating maintenance schedule: $e');
      }
      rethrow;
    }
  }

  /// Delete maintenance schedule
  static Future<void> deleteMaintenanceSchedule(String scheduleId) async {
    try {
      // Get schedule first to restore field status
      final schedule = await _client
          .from('maintenance_schedules')
          .select()
          .eq('id', scheduleId)
          .single();

      final maintenanceSchedule = MaintenanceSchedule.fromJson(
        schedule,
      );

      // Restore field status if exists
      if (maintenanceSchedule.fieldId != null) {
        await _client
            .from('fields')
            .update({
              'status': 'available',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', maintenanceSchedule.fieldId!);
      }

      // Delete schedule
      await _client.from('maintenance_schedules').delete().eq('id', scheduleId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Deleted maintenance schedule: $scheduleId');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error deleting maintenance schedule: $e');
      }
      rethrow;
    }
  }

  /// Check if venue/field has active maintenance
  static Future<bool> hasActiveMaintenance({
    required String venueId,
    String? fieldId,
  }) async {
    try {
      final now = DateTime.now().toIso8601String();

      var query = _client
          .from('maintenance_schedules')
          .select()
          .eq('venue_id', venueId)
          .lte('start_date', now)
          .gte('end_date', now)
          .inFilter('status', ['scheduled', 'in_progress']);

      if (fieldId != null) {
        query = query.eq('field_id', fieldId);
      }

      final response = await query;

      return (response as List).isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error checking active maintenance: $e');
      }
      return false;
    }
  }
}
