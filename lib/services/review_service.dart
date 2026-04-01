/// Review Service — SIPELOR BEDAS
/// 
/// Dedicated service for review and rating operations.
/// Extracted from SupabaseService as part of service architecture refactoring.
library;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/secure_logger.dart';
import '../security/input_sanitizer.dart';

/// Service for review and rating operations.
class ReviewService {
  static SupabaseClient get _client => Supabase.instance.client;

  // ─── Submit Review ────────────────────────────────────────────────────────

  /// Submit a new review for a completed booking.
  static Future<void> createReview({
    required String bookingId,
    required String userId,
    required int rating,
    required String comment,
  }) async {
    try {
      // Input validation
      if (rating < 1 || rating > 5) {
        throw ArgumentError('Rating harus antara 1 dan 5');
      }

      // Sanitize comment against XSS/injection
      final sanitizedComment = InputSanitizer.sanitizeForDisplay(comment);
      if (sanitizedComment.length > 500) {
        throw ArgumentError('Komentar maksimal 500 karakter');
      }

      // Check if review already exists for this booking
      final existing = await _client
          .from('reviews')
          .select('id')
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Review untuk booking ini sudah ada');
      }

      // Verify booking belongs to user and is completed
      final booking = await _client
          .from('bookings')
          .select('id, user_id, status')
          .eq('id', bookingId)
          .single();

      if (booking['user_id'] != userId) {
        throw Exception('Booking tidak ditemukan');
      }
      if (booking['status'] != 'completed') {
        throw Exception('Review hanya bisa diberikan untuk booking yang sudah selesai');
      }

      // Insert review
      await _client.from('reviews').insert({
        'booking_id': bookingId,
        'user_id': userId,
        'rating': rating,
        'comment': sanitizedComment,
        'created_at': DateTime.now().toIso8601String(),
      });

      SecureLogger.success('[ReviewService] Review submitted for booking: $bookingId');
    } catch (e) {
      SecureLogger.error('[ReviewService] createReview error', e);
      rethrow;
    }
  }

  // ─── Fetch Reviews ────────────────────────────────────────────────────────

  /// Fetch reviews for a venue by venueId (= fieldId).
  /// Uses BATCH queries — no N+1.
  static Future<List<Map<String, dynamic>>> fetchReviewsByVenueId({
    required String venueId,
  }) async {
    try {
      if (venueId.trim().isEmpty) return [];

      // STEP 1: Batch fetch all reviews for this venue via join on bookings
      final allReviews = await _client
          .from('reviews')
          .select('id, booking_id, user_id, rating, comment, created_at')
          .order('created_at', ascending: false);

      if ((allReviews as List).isEmpty) return [];

      // STEP 2: Get all relevant booking IDs at once
      final bookingIds = allReviews
          .map((r) => r['booking_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet()
          .toList();

      final bookings = await _client
          .from('bookings')
          .select('id, venue_id, field_id')
          .inFilter('id', bookingIds);

      final bookingMap = {
        for (final b in bookings as List)
          b['id'] as String: b as Map<String, dynamic>,
      };

      // STEP 3: Filter for this venue
      final venueReviews = allReviews.where((r) {
        final b = bookingMap[r['booking_id'] as String? ?? ''];
        if (b == null) return false;
        return b['venue_id'] == venueId || b['field_id'] == venueId;
      }).toList();

      if (venueReviews.isEmpty) return [];

      // STEP 4: Batch fetch user profiles
      final userIds = venueReviews
          .map((r) => r['user_id'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final profiles = await _client
          .from('profiles')
          .select('id, full_name, avatar_url')
          .inFilter('id', userIds);

      final profileMap = {
        for (final p in profiles as List)
          p['id'] as String: p as Map<String, dynamic>,
      };

      // STEP 5: Map to result format
      return venueReviews.map((review) {
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
    } catch (e) {
      SecureLogger.error('[ReviewService] fetchReviewsByVenueId error', e);
      return [];
    }
  }

  /// Real-time stream of reviews for a venue.
  /// Resolves N+1 with batch queries on each update.
  static Stream<List<Map<String, dynamic>>> streamReviewsByVenueId({
    required String venueId,
  }) async* {
    if (venueId.trim().isEmpty) {
      yield [];
      return;
    }

    try {
      await for (final _ in _client
          .from('reviews')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)) {
        try {
          final reviews = await fetchReviewsByVenueId(venueId: venueId);
          yield reviews;
        } catch (e) {
          SecureLogger.error('[ReviewService] streamReviewsByVenueId processing error', e);
          yield [];
        }
      }
    } catch (e) {
      SecureLogger.error('[ReviewService] streamReviewsByVenueId stream error', e);
      yield [];
    }
  }

  /// Fetch review for a specific booking.
  static Future<Map<String, dynamic>?> fetchReviewByBookingId({
    required String bookingId,
  }) async {
    try {
      final response = await _client
          .from('reviews')
          .select('*, profiles(full_name, avatar_url)')
          .eq('booking_id', bookingId)
          .maybeSingle();

      return response;
    } catch (e) {
      SecureLogger.error('[ReviewService] fetchReviewByBookingId error', e);
      return null;
    }
  }

  // ─── Update / Delete ──────────────────────────────────────────────────────

  /// Update an existing review.
  static Future<void> updateReview({
    required String reviewId,
    required String userId,
    int? rating,
    String? comment,
  }) async {
    try {
      // Verify ownership
      final existing = await _client
          .from('reviews')
          .select('user_id')
          .eq('id', reviewId)
          .single();

      if (existing['user_id'] != userId) {
        throw Exception('Tidak diizinkan mengubah review ini');
      }

      final updates = <String, dynamic>{
        'rating': ?rating,
        if (comment != null) 'comment': InputSanitizer.sanitizeForDisplay(comment),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('reviews').update(updates).eq('id', reviewId);
      SecureLogger.success('[ReviewService] Review updated: $reviewId');
    } catch (e) {
      SecureLogger.error('[ReviewService] updateReview error', e);
      rethrow;
    }
  }

  /// Delete a review (owner or admin).
  static Future<void> deleteReview({
    required String reviewId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      if (!isAdmin) {
        final existing = await _client
            .from('reviews')
            .select('user_id')
            .eq('id', reviewId)
            .single();

        if (existing['user_id'] != userId) {
          throw Exception('Tidak diizinkan menghapus review ini');
        }
      }

      await _client.from('reviews').delete().eq('id', reviewId);
      SecureLogger.success('[ReviewService] Review deleted: $reviewId');
    } catch (e) {
      SecureLogger.error('[ReviewService] deleteReview error', e);
      rethrow;
    }
  }

  // ─── Rating Calculation ───────────────────────────────────────────────────

  /// Calculate average rating for a venue from its reviews.
  static double calculateAverageRating(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) return 0.0;
    final total = reviews.fold<double>(
      0.0,
      (sum, r) => sum + ((r['rating'] as num?)?.toDouble() ?? 0.0),
    );
    return double.parse((total / reviews.length).toStringAsFixed(1));
  }

  /// Get rating distribution (1-5 star counts).
  static Map<int, int> getRatingDistribution(List<Map<String, dynamic>> reviews) {
    final dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (final r in reviews) {
      final rating = (r['rating'] as num?)?.toInt() ?? 0;
      if (rating >= 1 && rating <= 5) {
        dist[rating] = (dist[rating] ?? 0) + 1;
      }
    }
    return dist;
  }
}
