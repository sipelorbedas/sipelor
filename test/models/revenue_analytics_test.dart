import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/revenue_analytics.dart';

void main() {
  group('RevenueAnalytics Model', () {
    final testDate = DateTime(2024, 1, 15);
    
    final testAnalytics = RevenueAnalytics(
      period: testDate,
      totalRevenue: 10000000,
      confirmedRevenue: 8000000,
      pendingRevenue: 2000000,
      totalBookings: 100,
      confirmedBookings: 80,
      pendingBookings: 15,
      cancelledBookings: 5,
      averageBookingValue: 100000,
      revenueByVenueType: {'Futsal': 5000000, 'Badminton': 3000000},
      bookingsByVenueType: {'Futsal': 50, 'Badminton': 30},
      revenueByVenue: {'venue1': 6000000, 'venue2': 4000000},
      dailyBreakdown: [],
    );

    test('should create RevenueAnalytics with all fields', () {
      expect(testAnalytics.period, testDate);
      expect(testAnalytics.totalRevenue, 10000000);
      expect(testAnalytics.confirmedRevenue, 8000000);
      expect(testAnalytics.pendingRevenue, 2000000);
      expect(testAnalytics.totalBookings, 100);
      expect(testAnalytics.confirmedBookings, 80);
      expect(testAnalytics.pendingBookings, 15);
      expect(testAnalytics.cancelledBookings, 5);
      expect(testAnalytics.averageBookingValue, 100000);
    });

    test('formattedPeriod should return formatted month and year', () {
      expect(testAnalytics.formattedPeriod, contains('January'));
      expect(testAnalytics.formattedPeriod, contains('2024'));
    });

    test('conversionRate should calculate correctly', () {
      expect(testAnalytics.conversionRate, 80.0); // 80/100 * 100
    });

    test('cancellationRate should calculate correctly', () {
      expect(testAnalytics.cancellationRate, 5.0); // 5/100 * 100
    });

    test('conversion and cancellation rates should handle zero bookings', () {
      final emptyAnalytics = RevenueAnalytics(
        period: testDate,
        totalRevenue: 0,
        confirmedRevenue: 0,
        pendingRevenue: 0,
        totalBookings: 0,
        confirmedBookings: 0,
        pendingBookings: 0,
        cancelledBookings: 0,
        averageBookingValue: 0,
        revenueByVenueType: {},
        bookingsByVenueType: {},
        revenueByVenue: {},
        dailyBreakdown: [],
      );

      expect(emptyAnalytics.conversionRate, 0.0);
      expect(emptyAnalytics.cancellationRate, 0.0);
    });

    test('revenueByVenueType should contain correct data', () {
      expect(testAnalytics.revenueByVenueType['Futsal'], 5000000);
      expect(testAnalytics.revenueByVenueType['Badminton'], 3000000);
    });

    test('bookingsByVenueType should contain correct data', () {
      expect(testAnalytics.bookingsByVenueType['Futsal'], 50);
      expect(testAnalytics.bookingsByVenueType['Badminton'], 30);
    });
  });

  group('DailyRevenue Model', () {
    final testDate = DateTime(2024, 1, 15);
    
    test('should create DailyRevenue with all fields', () {
      final dailyRevenue = DailyRevenue(
        date: testDate,
        revenue: 500000,
        bookings: 10,
      );

      expect(dailyRevenue.date, testDate);
      expect(dailyRevenue.revenue, 500000);
      expect(dailyRevenue.bookings, 10);
    });

    test('formattedDate should return formatted date', () {
      final dailyRevenue = DailyRevenue(
        date: testDate,
        revenue: 500000,
        bookings: 10,
      );

      final formatted = dailyRevenue.formattedDate;
      expect(formatted, contains('15'));
      expect(formatted, contains('Jan'));
    });
  });

  group('VenuePerformance Model', () {
    test('should create VenuePerformance with all fields', () {
      final performance = VenuePerformance(
        venueId: 'venue123',
        venueName: 'Best Futsal Arena',
        venueType: 'Futsal',
        totalRevenue: 5000000,
        totalBookings: 50,
        averageRating: 4.5,
        totalReviews: 100,
        occupancyRate: 75.0,
      );

      expect(performance.venueId, 'venue123');
      expect(performance.venueName, 'Best Futsal Arena');
      expect(performance.venueType, 'Futsal');
      expect(performance.totalRevenue, 5000000);
      expect(performance.totalBookings, 50);
      expect(performance.averageRating, 4.5);
      expect(performance.totalReviews, 100);
      expect(performance.occupancyRate, 75.0);
    });
  });

  group('ReportType Enum', () {
    test('value should return correct strings', () {
      expect(ReportType.revenue.value, 'revenue');
      expect(ReportType.bookings.value, 'bookings');
      expect(ReportType.performance.value, 'performance');
    });

    test('displayName should return correct names', () {
      expect(ReportType.revenue.displayName, 'Laporan Pendapatan');
      expect(ReportType.bookings.displayName, 'Laporan Booking');
      expect(ReportType.performance.displayName, 'Laporan Performa');
    });

    test('fromString should parse correctly', () {
      expect(ReportType.fromString('revenue'), ReportType.revenue);
      expect(ReportType.fromString('bookings'), ReportType.bookings);
      expect(ReportType.fromString('performance'), ReportType.performance);
    });

    test('fromString should be case insensitive', () {
      expect(ReportType.fromString('REVENUE'), ReportType.revenue);
      expect(ReportType.fromString('Bookings'), ReportType.bookings);
    });

    test('fromString should default to revenue for invalid input', () {
      expect(ReportType.fromString('invalid'), ReportType.revenue);
    });
  });

  group('ReportFrequency Enum', () {
    test('value should return correct strings', () {
      expect(ReportFrequency.daily.value, 'daily');
      expect(ReportFrequency.weekly.value, 'weekly');
      expect(ReportFrequency.monthly.value, 'monthly');
    });

    test('displayName should return correct names', () {
      expect(ReportFrequency.daily.displayName, 'Harian');
      expect(ReportFrequency.weekly.displayName, 'Mingguan');
      expect(ReportFrequency.monthly.displayName, 'Bulanan');
    });

    test('fromString should parse correctly', () {
      expect(ReportFrequency.fromString('daily'), ReportFrequency.daily);
      expect(ReportFrequency.fromString('weekly'), ReportFrequency.weekly);
      expect(ReportFrequency.fromString('monthly'), ReportFrequency.monthly);
    });

    test('fromString should be case insensitive', () {
      expect(ReportFrequency.fromString('DAILY'), ReportFrequency.daily);
      expect(ReportFrequency.fromString('Weekly'), ReportFrequency.weekly);
    });

    test('fromString should default to weekly for invalid input', () {
      expect(ReportFrequency.fromString('invalid'), ReportFrequency.weekly);
    });
  });

  group('ReportConfig Model', () {
    final testDate = DateTime(2024, 1, 15);
    
    final testConfig = ReportConfig(
      type: ReportType.revenue,
      frequency: ReportFrequency.weekly,
      recipients: ['admin@example.com', 'manager@example.com'],
      isActive: true,
      lastSent: testDate,
      nextScheduled: testDate.add(Duration(days: 7)),
    );

    test('should create ReportConfig with all fields', () {
      expect(testConfig.type, ReportType.revenue);
      expect(testConfig.frequency, ReportFrequency.weekly);
      expect(testConfig.recipients, ['admin@example.com', 'manager@example.com']);
      expect(testConfig.isActive, true);
      expect(testConfig.lastSent, testDate);
      expect(testConfig.nextScheduled, isNotNull);
    });

    test('should create ReportConfig with null optional fields', () {
      final minimalConfig = ReportConfig(
        type: ReportType.bookings,
        frequency: ReportFrequency.daily,
        recipients: ['test@example.com'],
        isActive: false,
      );

      expect(minimalConfig.lastSent, isNull);
      expect(minimalConfig.nextScheduled, isNull);
    });

    test('fromJson should parse JSON correctly', () {
      final json = {
        'type': 'revenue',
        'frequency': 'weekly',
        'recipients': ['admin@example.com'],
        'is_active': true,
        'last_sent': '2024-01-15T00:00:00.000',
        'next_scheduled': '2024-01-22T00:00:00.000',
      };

      final config = ReportConfig.fromJson(json);

      expect(config.type, ReportType.revenue);
      expect(config.frequency, ReportFrequency.weekly);
      expect(config.recipients, ['admin@example.com']);
      expect(config.isActive, true);
      expect(config.lastSent?.year, 2024);
    });

    test('fromJson should handle null optional fields', () {
      final json = {
        'type': 'bookings',
        'frequency': 'daily',
        'recipients': ['test@example.com'],
        'is_active': false,
        'last_sent': null,
        'next_scheduled': null,
      };

      final config = ReportConfig.fromJson(json);

      expect(config.lastSent, isNull);
      expect(config.nextScheduled, isNull);
    });

    test('toJson should convert ReportConfig to JSON correctly', () {
      final json = testConfig.toJson();

      expect(json['type'], 'revenue');
      expect(json['frequency'], 'weekly');
      expect(json['recipients'], ['admin@example.com', 'manager@example.com']);
      expect(json['is_active'], true);
      expect(json['last_sent'], isNotNull);
      expect(json['next_scheduled'], isNotNull);
    });

    test('toJson should handle null optional fields', () {
      final minimalConfig = ReportConfig(
        type: ReportType.performance,
        frequency: ReportFrequency.monthly,
        recipients: [],
        isActive: false,
      );

      final json = minimalConfig.toJson();

      expect(json['last_sent'], isNull);
      expect(json['next_scheduled'], isNull);
    });

    test('round trip JSON conversion should preserve data', () {
      final json = testConfig.toJson();
      final reconstructed = ReportConfig.fromJson(json);

      expect(reconstructed.type, testConfig.type);
      expect(reconstructed.frequency, testConfig.frequency);
      expect(reconstructed.recipients, testConfig.recipients);
      expect(reconstructed.isActive, testConfig.isActive);
    });
  });
}
