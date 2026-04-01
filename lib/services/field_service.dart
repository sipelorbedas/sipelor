/// Field Service — SIPELOR BEDAS
/// 
/// Dedicated service for field & venue management.
/// Extracted from SupabaseService as part of service architecture refactoring.
/// 
/// MIGRATION NOTE: Screens should gradually migrate from SupabaseService.fetchFields()
/// to FieldService.fetchFields() to allow independent testing and maintenance.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/field.dart';
import '../models/venue.dart' as venue_model;
import '../utils/secure_logger.dart';
import '../security/data_integrity_verifier.dart';

/// Service for field and venue operations.
class FieldService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ─── Venue Operations ─────────────────────────────────────────────────────

  /// Fetch all venues, grouped from fields table.
  static Future<List<venue_model.Venue>> fetchVenues({
    bool activeOnly = false,
  }) async {
    try {
      SecureLogger.info('[FieldService] Fetching venues...');

      var query = _client.from('fields').select();
      if (activeOnly) {
        query = query.eq('status', 'available');
      }
      final response = await query;

      // Group fields by venue_name + venue_type to derive unique venues
      final venueMap = <String, Map<String, dynamic>>{};
      for (final field in response as List) {
        final venueName = field['venue_name'] as String;
        final venueType = field['venue_type'] as String;
        final key = '$venueName-$venueType';

        if (!venueMap.containsKey(key)) {
          venueMap[key] = {
            'id': field['id'],
            'name': venueName,
            'venue_type': venueType,
            'description': field['description'],
            'address': 'Jalak Harupat',
            'city': 'Bandung',
            'image_url': (field['image_urls'] is List &&
                    (field['image_urls'] as List).isNotEmpty)
                ? (field['image_urls'] as List).first
                : null,
            'rating': 0.0,
            'total_reviews': 0,
            'is_active': field['status'] == 'available',
            'created_at': field['created_at'],
          };
        }
      }

      final venues = venueMap.values
          .map((v) => venue_model.Venue.fromJson(v))
          .toList();

      SecureLogger.success('[FieldService] Fetched ${venues.length} venues');
      return venues;
    } catch (e) {
      SecureLogger.error('[FieldService] fetchVenues error', e);
      throw Exception('Failed to fetch venues: $e');
    }
  }

  /// Fetch a single venue by ID.
  static Future<venue_model.Venue?> fetchVenueById(String venueId) async {
    try {
      final response = await _client
          .from('fields')
          .select()
          .eq('id', venueId)
          .maybeSingle();

      if (response == null) return null;

      final venueData = {
        'id': response['id'],
        'name': response['venue_name'],
        'venue_type': response['venue_type'],
        'description': response['description'],
        'address': 'Jalak Harupat',
        'city': 'Bandung',
        'image_url': (response['image_urls'] is List &&
                (response['image_urls'] as List).isNotEmpty)
            ? (response['image_urls'] as List).first
            : null,
        'rating': response['rating'] ?? 0.0,
        'total_reviews': response['total_reviews'] ?? 0,
        'is_active': response['status'] == 'available',
        'created_at': response['created_at'],
      };

      return venue_model.Venue.fromJson(venueData);
    } catch (e) {
      SecureLogger.error('[FieldService] fetchVenueById error', e);
      return null;
    }
  }

  // ─── Field Operations ─────────────────────────────────────────────────────

  /// Fetch all fields with optional filtering.
  static Future<List<Field>> fetchFields({
    bool activeOnly = false,
    String? venueType,
  }) async {
    try {
      var query = _client.from('fields').select();

      if (activeOnly) query = query.eq('status', 'available');
      if (venueType != null && venueType.isNotEmpty) {
        query = query.eq('venue_type', venueType);
      }

      final response = await query.order('name');
      return (response as List).map((f) => Field.fromJson(Map<String, dynamic>.from(f as Map))).toList();
    } catch (e) {
      SecureLogger.error('[FieldService] fetchFields error', e);
      throw Exception('Failed to fetch fields: $e');
    }
  }

  /// Fetch a field by its ID.
  static Future<Field?> fetchFieldById(String fieldId) async {
    try {
      final response = await _client
          .from('fields')
          .select()
          .eq('id', fieldId)
          .maybeSingle();

      if (response == null) return null;
      return Field.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      SecureLogger.error('[FieldService] fetchFieldById error', e);
      return null;
    }
  }

  /// Create a new field (admin only).
  static Future<Field> createField({
    required String name,
    required String venueName,
    required String venueType,
    required String area,
    required double pricePerHour,
    String? description,
    List<String>? facilities,
    List<String>? imageUrls,
  }) async {
    try {
      final fieldData = {
        'name': name,
        'venue_name': venueName,
        'venue_type': venueType,
        'area': area,
        'price_per_hour': pricePerHour,
        'description': description,
        'facilities': facilities ?? [],
        'image_urls': imageUrls ?? [],
        'status': 'available',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Sign the data for integrity tracking
      final token = await DataIntegrityVerifier.signPayload(fieldData);
      fieldData['integrity_token'] = token;

      final response = await _client
          .from('fields')
          .insert(fieldData)
          .select()
          .single();

      SecureLogger.success('[FieldService] Field created: $name');
      return Field.fromJson(response);
    } catch (e) {
      SecureLogger.error('[FieldService] createField error', e);
      throw Exception('Failed to create field: $e');
    }
  }

  /// Update an existing field (admin only).
  static Future<Field> updateField({
    required String fieldId,
    String? name,
    String? venueName,
    String? venueType,
    String? area,
    double? pricePerHour,
    String? description,
    List<String>? facilities,
    List<String>? imageUrls,
    FieldStatus? status,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'name': ?name,
        'venue_name': ?venueName,
        'venue_type': ?venueType,
        'area': ?area,
        'price_per_hour': ?pricePerHour,
        'description': ?description,
        'facilities': ?facilities,
        'image_urls': ?imageUrls,
        if (status != null) 'status': status.value,
      };

      final response = await _client
          .from('fields')
          .update(updates)
          .eq('id', fieldId)
          .select()
          .single();

      SecureLogger.success('[FieldService] Field updated: $fieldId');
      return Field.fromJson(Map<String, dynamic>.from(response as Map));
    } catch (e) {
      SecureLogger.error('[FieldService] updateField error', e);
      throw Exception('Failed to update field: $e');
    }
  }

  /// Delete a field (admin only).
  static Future<void> deleteField(String fieldId) async {
    try {
      await _client.from('fields').delete().eq('id', fieldId);
      SecureLogger.success('[FieldService] Field deleted: $fieldId');
    } catch (e) {
      SecureLogger.error('[FieldService] deleteField error', e);
      throw Exception('Failed to delete field: $e');
    }
  }

  // ─── Availability ─────────────────────────────────────────────────────────

  /// Check if a field is available for the given date and time range.
  static Future<bool> isFieldAvailable({
    required String fieldId,
    required DateTime date,
    required String startTime,
    required String endTime,
    String? excludeBookingId,
  }) async {
    try {
      var query = _client
          .from('bookings')
          .select('id')
          .eq('field_id', fieldId)
          .eq('booking_date', date.toIso8601String().split('T').first)
          .inFilter('status', ['pending', 'confirmed']);

      if (excludeBookingId != null) {
        query = query.neq('id', excludeBookingId);
      }

      final existing = await query;

      // Client-side time overlap check
      for (final booking in existing as List) {
        final bStart = booking['start_time'] as String? ?? '';
        final bEnd = booking['end_time'] as String? ?? '';
        if (_timeRangesOverlap(startTime, endTime, bStart, bEnd)) {
          return false;
        }
      }

      return true;
    } catch (e) {
      SecureLogger.error('[FieldService] isFieldAvailable error', e);
      return false;
    }
  }

  static bool _timeRangesOverlap(
    String start1, String end1, String start2, String end2,
  ) {
    try {
      final s1 = _parseTime(start1);
      final e1 = _parseTime(end1);
      final s2 = _parseTime(start2);
      final e2 = _parseTime(end2);
      return s1 < e2 && s2 < e1;
    } catch (_) {
      return false;
    }
  }

  static int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return 0;
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }
}
