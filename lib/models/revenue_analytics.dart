import 'package:intl/intl.dart';

/// Revenue analytics model for detailed financial insights
class RevenueAnalytics {
  final DateTime period;
  final double totalRevenue;
  final double confirmedRevenue;
  final double pendingRevenue;
  final int totalBookings;
  final int confirmedBookings;
  final int pendingBookings;
  final int cancelledBookings;
  final double averageBookingValue;
  final Map<String, double> revenueByVenueType;
  final Map<String, int> bookingsByVenueType;
  final Map<String, double> revenueByVenue;
  final List<DailyRevenue> dailyBreakdown;

  RevenueAnalytics({
    required this.period,
    required this.totalRevenue,
    required this.confirmedRevenue,
    required this.pendingRevenue,
    required this.totalBookings,
    required this.confirmedBookings,
    required this.pendingBookings,
    required this.cancelledBookings,
    required this.averageBookingValue,
    required this.revenueByVenueType,
    required this.bookingsByVenueType,
    required this.revenueByVenue,
    required this.dailyBreakdown,
  });

  String get formattedPeriod => DateFormat('MMMM yyyy').format(period);
  
  double get conversionRate => totalBookings > 0 
      ? (confirmedBookings / totalBookings) * 100 
      : 0.0;

  double get cancellationRate => totalBookings > 0
      ? (cancelledBookings / totalBookings) * 100
      : 0.0;
}

/// Daily revenue breakdown
class DailyRevenue {
  final DateTime date;
  final double revenue;
  final int bookings;

  DailyRevenue({
    required this.date,
    required this.revenue,
    required this.bookings,
  });

  String get formattedDate => DateFormat('dd MMM').format(date);
}

/// Venue performance metrics
class VenuePerformance {
  final String venueId;
  final String venueName;
  final String venueType;
  final double totalRevenue;
  final int totalBookings;
  final double averageRating;
  final int totalReviews;
  final double occupancyRate; // Percentage of booked slots

  VenuePerformance({
    required this.venueId,
    required this.venueName,
    required this.venueType,
    required this.totalRevenue,
    required this.totalBookings,
    required this.averageRating,
    required this.totalReviews,
    required this.occupancyRate,
  });
}

/// Report configuration model
class ReportConfig {
  final ReportType type;
  final ReportFrequency frequency;
  final List<String> recipients; // Email addresses
  final bool isActive;
  final DateTime? lastSent;
  final DateTime? nextScheduled;

  ReportConfig({
    required this.type,
    required this.frequency,
    required this.recipients,
    required this.isActive,
    this.lastSent,
    this.nextScheduled,
  });

  factory ReportConfig.fromJson(Map<String, dynamic> json) {
    return ReportConfig(
      type: ReportType.fromString(json['type'] as String),
      frequency: ReportFrequency.fromString(json['frequency'] as String),
      recipients: (json['recipients'] as List).cast<String>(),
      isActive: json['is_active'] as bool,
      lastSent: json['last_sent'] != null
          ? DateTime.parse(json['last_sent'] as String)
          : null,
      nextScheduled: json['next_scheduled'] != null
          ? DateTime.parse(json['next_scheduled'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'frequency': frequency.value,
      'recipients': recipients,
      'is_active': isActive,
      'last_sent': lastSent?.toIso8601String(),
      'next_scheduled': nextScheduled?.toIso8601String(),
    };
  }
}

/// Report type enum
enum ReportType {
  revenue,
  bookings,
  performance;

  String get value {
    switch (this) {
      case ReportType.revenue:
        return 'revenue';
      case ReportType.bookings:
        return 'bookings';
      case ReportType.performance:
        return 'performance';
    }
  }

  String get displayName {
    switch (this) {
      case ReportType.revenue:
        return 'Laporan Pendapatan';
      case ReportType.bookings:
        return 'Laporan Booking';
      case ReportType.performance:
        return 'Laporan Performa';
    }
  }

  static ReportType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'revenue':
        return ReportType.revenue;
      case 'bookings':
        return ReportType.bookings;
      case 'performance':
        return ReportType.performance;
      default:
        return ReportType.revenue;
    }
  }
}

/// Report frequency enum
enum ReportFrequency {
  daily,
  weekly,
  monthly;

  String get value {
    switch (this) {
      case ReportFrequency.daily:
        return 'daily';
      case ReportFrequency.weekly:
        return 'weekly';
      case ReportFrequency.monthly:
        return 'monthly';
    }
  }

  String get displayName {
    switch (this) {
      case ReportFrequency.daily:
        return 'Harian';
      case ReportFrequency.weekly:
        return 'Mingguan';
      case ReportFrequency.monthly:
        return 'Bulanan';
    }
  }

  static ReportFrequency fromString(String value) {
    switch (value.toLowerCase()) {
      case 'daily':
        return ReportFrequency.daily;
      case 'weekly':
        return ReportFrequency.weekly;
      case 'monthly':
        return ReportFrequency.monthly;
      default:
        return ReportFrequency.weekly;
    }
  }
}
