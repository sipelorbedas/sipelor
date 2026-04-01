import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../models/revenue_analytics.dart';
import 'revenue_analytics_service.dart';

/// Service for generating and sending automated reports via email
class AutomatedReportsService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Fetch all report configurations
  static Future<List<ReportConfig>> fetchReportConfigs() async {
    try {
      final response = await _client
          .from('report_configs')
          .select()
          .order('created_at', ascending: false);

      final configs = (response as List)
          .map((json) => ReportConfig.fromJson(json as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('✅ Fetched ${configs.length} report configurations');
      }

      return configs;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error fetching report configs: $e');
      }
      return [];
    }
  }

  /// Create a new report configuration
  static Future<ReportConfig> createReportConfig({
    required ReportType type,
    required ReportFrequency frequency,
    required List<String> recipients,
  }) async {
    try {
      final nextScheduled = _calculateNextScheduled(frequency);

      final response = await _client.from('report_configs').insert({
        'type': type.value,
        'frequency': frequency.value,
        'recipients': recipients,
        'is_active': true,
        'next_scheduled': nextScheduled.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final config = ReportConfig.fromJson(response);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Created report config: ${config.type.displayName} - ${config.frequency.displayName}');
      }

      return config;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error creating report config: $e');
      }
      rethrow;
    }
  }

  /// Update report configuration
  static Future<void> updateReportConfig({
    required String configId,
    ReportFrequency? frequency,
    List<String>? recipients,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (frequency != null) {
        updateData['frequency'] = frequency.value;
        updateData['next_scheduled'] = _calculateNextScheduled(frequency).toIso8601String();
      }
      if (recipients != null) updateData['recipients'] = recipients;
      if (isActive != null) updateData['is_active'] = isActive;

      await _client
          .from('report_configs')
          .update(updateData)
          .eq('id', configId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Updated report config: $configId');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error updating report config: $e');
      }
      rethrow;
    }
  }

  /// Delete report configuration
  static Future<void> deleteReportConfig(String configId) async {
    try {
      await _client.from('report_configs').delete().eq('id', configId);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Deleted report config: $configId');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error deleting report config: $e');
      }
      rethrow;
    }
  }

  /// Generate and send reports (called by scheduled job or manually)
  static Future<void> generateAndSendReports() async {
    try {
      final configs = await fetchReportConfigs();
      final now = DateTime.now();

      for (final config in configs) {
        if (!config.isActive) continue;

        // Check if report is due
        if (config.nextScheduled != null && config.nextScheduled!.isBefore(now)) {
          await _generateAndSendReport(config);

          // Update last sent and calculate next scheduled
          await _client.from('report_configs').update({
            'last_sent': now.toIso8601String(),
            'next_scheduled': _calculateNextScheduled(config.frequency).toIso8601String(),
          }).eq('id', config.type.value); // Assuming type is used as ID
        }
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ Processed automated reports');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error generating and sending reports: $e');
      }
    }
  }

  /// Generate report content
  static Future<String> _generateReportContent(
    ReportType type,
    ReportFrequency frequency,
  ) async {
    final endDate = DateTime.now();
    DateTime startDate;

    // Calculate period based on frequency
    switch (frequency) {
      case ReportFrequency.daily:
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case ReportFrequency.weekly:
        startDate = endDate.subtract(const Duration(days: 7));
        break;
      case ReportFrequency.monthly:
        startDate = DateTime(endDate.year, endDate.month - 1, endDate.day);
        break;
    }

    final analytics = await RevenueAnalyticsService.generateAnalytics(
      startDate: startDate,
      endDate: endDate,
    );

    final periodStr = '${DateFormat('dd MMM yyyy').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}';

    // Generate HTML report
    final html = '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
    .content { padding: 20px; }
    .metric { background: #f4f4f4; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .metric h3 { margin-top: 0; color: #4CAF50; }
    .footer { background: #333; color: white; padding: 10px; text-align: center; margin-top: 20px; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #4CAF50; color: white; }
  </style>
</head>
<body>
  <div class="header">
    <h1>SIPELOR BEDAS - ${type.displayName}</h1>
    <p>Periode: $periodStr</p>
  </div>
  
  <div class="content">
    <div class="metric">
      <h3>📊 Ringkasan Pendapatan</h3>
      <p><strong>Total Pendapatan:</strong> Rp ${NumberFormat('#,###').format(analytics.totalRevenue)}</p>
      <p><strong>Pendapatan Terkonfirmasi:</strong> Rp ${NumberFormat('#,###').format(analytics.confirmedRevenue)}</p>
      <p><strong>Pendapatan Pending:</strong> Rp ${NumberFormat('#,###').format(analytics.pendingRevenue)}</p>
    </div>

    <div class="metric">
      <h3>📈 Statistik Booking</h3>
      <p><strong>Total Booking:</strong> ${analytics.totalBookings}</p>
      <p><strong>Booking Terkonfirmasi:</strong> ${analytics.confirmedBookings}</p>
      <p><strong>Booking Pending:</strong> ${analytics.pendingBookings}</p>
      <p><strong>Booking Dibatalkan:</strong> ${analytics.cancelledBookings}</p>
      <p><strong>Conversion Rate:</strong> ${analytics.conversionRate.toStringAsFixed(1)}%</p>
    </div>

    <div class="metric">
      <h3>💰 Rata-rata Nilai Booking</h3>
      <p>Rp ${NumberFormat('#,###').format(analytics.averageBookingValue)}</p>
    </div>

    <div class="metric">
      <h3>🏟️ Pendapatan per Jenis Venue</h3>
      <table>
        <tr>
          <th>Jenis Venue</th>
          <th>Jumlah Booking</th>
          <th>Total Pendapatan</th>
        </tr>
        ${analytics.revenueByVenueType.entries.map((e) => '''
        <tr>
          <td>${e.key}</td>
          <td>${analytics.bookingsByVenueType[e.key] ?? 0}</td>
          <td>Rp ${NumberFormat('#,###').format(e.value)}</td>
        </tr>
        ''').join()}
      </table>
    </div>
  </div>

  <div class="footer">
    <p>Report generated automatically by SIPELOR BEDAS System</p>
    <p>© 2026 DISPORA Kabupaten Bandung</p>
  </div>
</body>
</html>
''';

    return html;
  }

  /// Send report via Supabase Edge Function (which handles email sending)
  static Future<void> _generateAndSendReport(ReportConfig config) async {
    try {
      final reportContent = await _generateReportContent(config.type, config.frequency);

      // Call Supabase Edge Function to send email
      await _client.functions.invoke(
        'send-report-email',
        body: {
          'recipients': config.recipients,
          'subject': '${config.type.displayName} - ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
          'html_content': reportContent,
        },
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ Sent ${config.type.displayName} to ${config.recipients.length} recipients');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error sending report: $e');
      }
      // Don't rethrow to allow other reports to be sent
    }
  }

  /// Calculate next scheduled time based on frequency
  static DateTime _calculateNextScheduled(ReportFrequency frequency) {
    final now = DateTime.now();

    switch (frequency) {
      case ReportFrequency.daily:
        // Next day at 8 AM
        return DateTime(now.year, now.month, now.day + 1, 8, 0);
      case ReportFrequency.weekly:
        // Next Monday at 8 AM
        final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
        final nextMonday = now.add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
        return DateTime(nextMonday.year, nextMonday.month, nextMonday.day, 8, 0);
      case ReportFrequency.monthly:
        // First day of next month at 8 AM
        final nextMonth = now.month == 12 ? 1 : now.month + 1;
        final nextYear = now.month == 12 ? now.year + 1 : now.year;
        return DateTime(nextYear, nextMonth, 1, 8, 0);
    }
  }

  /// Manually trigger a report (for testing or on-demand generation)
  static Future<void> sendReportNow({
    required ReportType type,
    required List<String> recipients,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final config = ReportConfig(
        type: type,
        frequency: ReportFrequency.daily, // Doesn't matter for manual send
        recipients: recipients,
        isActive: true,
      );

      await _generateAndSendReport(config);

      if (kDebugMode) {
        if (kDebugMode) print('✅ Manual report sent successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error sending manual report: $e');
      }
      rethrow;
    }
  }
}
