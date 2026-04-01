import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/booking.dart';
import '../models/revenue_analytics.dart';

/// Service for detailed revenue analytics
class RevenueAnalyticsService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Generate revenue analytics for a specific period
  static Future<RevenueAnalytics> generateAnalytics({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch all bookings in the period
      final response = await _client
          .from('bookings')
          .select('*, fields(venue_name, area, venue_type)')
          .gte('booking_date', startDate.toIso8601String())
          .lte('booking_date', endDate.toIso8601String())
          .order('booking_date', ascending: true);

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      // Calculate metrics
      final totalBookings = bookings.length;
      final confirmedBookings = bookings
          .where((b) => b.status == BookingStatus.confirmed)
          .length;
      final pendingBookings = bookings
          .where((b) => b.status == BookingStatus.pending)
          .length;
      final cancelledBookings = bookings
          .where((b) => b.status == BookingStatus.cancelled)
          .length;

      final confirmedRevenue = bookings
          .where((b) => b.status == BookingStatus.confirmed)
          .fold<double>(0.0, (sum, b) => sum + b.totalAmount.toDouble());

      final pendingRevenue = bookings
          .where((b) => b.status == BookingStatus.pending)
          .fold<double>(0.0, (sum, b) => sum + b.totalAmount.toDouble());

      final totalRevenue = confirmedRevenue + pendingRevenue;

      final averageBookingValue = confirmedBookings > 0
          ? confirmedRevenue / confirmedBookings
          : 0.0;

      // Revenue by venue type
      final Map<String, double> revenueByVenueType = {};
      final Map<String, int> bookingsByVenueType = {};

      for (final booking in bookings) {
        if (booking.status != BookingStatus.cancelled) {
          final type = booking.venueType ?? 'Unknown';
          revenueByVenueType[type] =
              (revenueByVenueType[type] ?? 0) + booking.totalAmount.toDouble();
          bookingsByVenueType[type] = (bookingsByVenueType[type] ?? 0) + 1;
        }
      }

      // Revenue by venue
      final Map<String, double> revenueByVenue = {};
      for (final booking in bookings) {
        if (booking.status != BookingStatus.cancelled) {
          final venue = booking.venueName ?? 'Unknown';
          revenueByVenue[venue] =
              (revenueByVenue[venue] ?? 0) + booking.totalAmount.toDouble();
        }
      }

      // Daily breakdown
      final Map<String, DailyRevenue> dailyMap = {};
      for (final booking in bookings) {
        if (booking.status != BookingStatus.cancelled) {
          final dateKey = DateFormat('yyyy-MM-dd').format(booking.bookingDate);
          
          if (!dailyMap.containsKey(dateKey)) {
            dailyMap[dateKey] = DailyRevenue(
              date: booking.bookingDate,
              revenue: 0,
              bookings: 0,
            );
          }

          dailyMap[dateKey] = DailyRevenue(
            date: dailyMap[dateKey]!.date,
            revenue: dailyMap[dateKey]!.revenue + booking.totalAmount.toDouble(),
            bookings: dailyMap[dateKey]!.bookings + 1,
          );
        }
      }

      final dailyBreakdown = dailyMap.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      if (kDebugMode) {
        if (kDebugMode) print('✅ Generated analytics for period: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}');
        if (kDebugMode) print('   Total Revenue: Rp ${NumberFormat('#,###').format(totalRevenue)}');
        if (kDebugMode) print('   Total Bookings: $totalBookings');
      }

      return RevenueAnalytics(
        period: startDate,
        totalRevenue: totalRevenue,
        confirmedRevenue: confirmedRevenue,
        pendingRevenue: pendingRevenue,
        totalBookings: totalBookings,
        confirmedBookings: confirmedBookings,
        pendingBookings: pendingBookings,
        cancelledBookings: cancelledBookings,
        averageBookingValue: averageBookingValue,
        revenueByVenueType: revenueByVenueType,
        bookingsByVenueType: bookingsByVenueType,
        revenueByVenue: revenueByVenue,
        dailyBreakdown: dailyBreakdown,
      );
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error generating analytics: $e');
      }
      rethrow;
    }
  }

  /// Generate venue performance metrics
  static Future<List<VenuePerformance>> generateVenuePerformance({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Fetch bookings with venue/field info
      // Note: fields table doesn't have venue_id column, only venue_name and venue_type
      final response = await _client
          .from('bookings')
          .select('*, fields(venue_name, venue_type)')
          .gte('booking_date', startDate.toIso8601String())
          .lte('booking_date', endDate.toIso8601String());

      final bookings = (response as List)
          .map((json) => Booking.fromJson(json as Map<String, dynamic>))
          .toList();

      // Group by venue
      final Map<String, Map<String, dynamic>> venueData = {};

      for (final booking in bookings) {
        final venueId = booking.venueId;
        final venueName = booking.venueName ?? 'Unknown';
        final venueType = booking.venueType ?? 'Unknown';

        if (!venueData.containsKey(venueId)) {
          venueData[venueId] = {
            'venueId': venueId,
            'venueName': venueName,
            'venueType': venueType,
            'totalRevenue': 0.0,
            'totalBookings': 0,
          };
        }

        if (booking.status != BookingStatus.cancelled) {
          venueData[venueId]!['totalRevenue'] += booking.totalAmount.toDouble();
          venueData[venueId]!['totalBookings']++;
        }
      }

      // Fetch venue reviews for ratings
      final venuePerformances = <VenuePerformance>[];

      for (final data in venueData.values) {
        // Get average rating from reviews table
        final reviewsResponse = await _client
            .from('reviews')
            .select('rating')
            .eq('venue_id', data['venueId']);

        final reviews = reviewsResponse as List;
        final avgRating = reviews.isNotEmpty
            ? reviews.map((r) => r['rating'] as int).reduce((a, b) => a + b) / reviews.length
            : 0.0;

        // Calculate occupancy rate (simplified - would need time slots data for accurate calculation)
        final occupancyRate = (data['totalBookings'] as int) * 2.5; // Mock calculation

        venuePerformances.add(VenuePerformance(
          venueId: data['venueId'],
          venueName: data['venueName'],
          venueType: data['venueType'],
          totalRevenue: data['totalRevenue'],
          totalBookings: data['totalBookings'],
          averageRating: avgRating,
          totalReviews: reviews.length,
          occupancyRate: occupancyRate.clamp(0.0, 100.0),
        ));
      }

      // Sort by revenue descending
      venuePerformances.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));

      if (kDebugMode) {
        if (kDebugMode) print('✅ Generated performance for ${venuePerformances.length} venues');
      }

      return venuePerformances;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error generating venue performance: $e');
      }
      rethrow;
    }
  }

  /// Get monthly revenue for the last N months
  static Future<Map<String, double>> getMonthlyRevenue(int months) async {
    try {
      final endDate = DateTime.now();
      final startDate = DateTime(endDate.year, endDate.month - months, 1);

      final response = await _client
          .from('bookings')
          .select('booking_date, total_amount, status')
          .gte('booking_date', startDate.toIso8601String())
          .lte('booking_date', endDate.toIso8601String())
          .neq('status', 'cancelled');

      final bookings = response as List;

      final Map<String, double> monthlyRevenue = {};

      for (final booking in bookings) {
        final date = DateTime.parse(booking['booking_date']);
        final monthKey = DateFormat('MMM yyyy').format(date);
        final amount = (booking['total_amount'] as int).toDouble();

        monthlyRevenue[monthKey] = (monthlyRevenue[monthKey] ?? 0) + amount;
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ Generated monthly revenue for last $months months');
      }

      return monthlyRevenue;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error getting monthly revenue: $e');
      }
      rethrow;
    }
  }

  /// Get year-over-year comparison
  static Future<Map<String, dynamic>> getYearOverYearComparison() async {
    try {
      final currentYear = DateTime.now().year;
      final lastYear = currentYear - 1;

      final currentYearStart = DateTime(currentYear, 1, 1);
      final currentYearEnd = DateTime.now();
      final lastYearStart = DateTime(lastYear, 1, 1);
      final lastYearEnd = DateTime(lastYear, 12, 31);

      final currentYearAnalytics = await generateAnalytics(
        startDate: currentYearStart,
        endDate: currentYearEnd,
      );

      final lastYearAnalytics = await generateAnalytics(
        startDate: lastYearStart,
        endDate: lastYearEnd,
      );

      final revenueGrowth = lastYearAnalytics.totalRevenue > 0
          ? ((currentYearAnalytics.totalRevenue - lastYearAnalytics.totalRevenue) /
                  lastYearAnalytics.totalRevenue) *
              100
          : 0.0;

      final bookingGrowth = lastYearAnalytics.totalBookings > 0
          ? ((currentYearAnalytics.totalBookings - lastYearAnalytics.totalBookings) /
                  lastYearAnalytics.totalBookings) *
              100
          : 0.0;

      return {
        'currentYear': currentYearAnalytics,
        'lastYear': lastYearAnalytics,
        'revenueGrowth': revenueGrowth,
        'bookingGrowth': bookingGrowth,
      };
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error getting YoY comparison: $e');
      }
      rethrow;
    }
  }
}
