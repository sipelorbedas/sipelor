import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import '../models/booking.dart';
import '../services/audit_service.dart';

class ExportUtils {
  /// Export bookings to CSV
  static Future<File> exportBookingsToCSV(List<Booking> bookings) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Headers
        [
          'Booking ID',
          'User ID',
          'Venue Name',
          'Venue Type',
          'Field Area',
          'Booking Date',
          'Start Time',
          'End Time',
          'Duration (Hours)',
          'Total Amount',
          'Status',
          'Payment Status',
          'Notes',
          'Created At',
        ],
        // Data rows
        ...bookings.map((booking) => [
          booking.bookingId,
          booking.userId,
          booking.venueName ?? 'N/A',
          booking.venueType ?? 'N/A',
          booking.fieldArea ?? 'N/A',
          DateFormat('yyyy-MM-dd').format(booking.bookingDate),
          booking.startTime,
          booking.endTime,
          booking.durationHours,
          booking.totalAmount,
          booking.status.displayName,
          booking.paymentStatus.displayName,
          booking.notes ?? '',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(booking.createdAt),
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/bookings_export_$timestamp.csv';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(csv);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ExportUtils] Bookings exported to: $filePath');
      }

      return file;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ExportUtils] Error exporting bookings: $e');
      }
      throw Exception('Failed to export bookings: $e');
    }
  }

  /// Export audit logs to CSV
  static Future<File> exportAuditLogsToCSV(List<AuditLog> logs) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Headers
        [
          'Log ID',
          'User Name',
          'User ID',
          'Action',
          'Entity Type',
          'Entity ID',
          'Changes',
          'Created At',
        ],
        // Data rows
        ...logs.map((log) => [
          log.id,
          log.userName,
          log.userId,
          log.action,
          log.entityType,
          log.entityId ?? 'N/A',
          log.changes != null ? jsonEncode(log.changes) : 'N/A',
          DateFormat('yyyy-MM-dd HH:mm:ss').format(log.createdAt),
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/audit_logs_export_$timestamp.csv';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(csv);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ExportUtils] Audit logs exported to: $filePath');
      }

      return file;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ExportUtils] Error exporting audit logs: $e');
      }
      throw Exception('Failed to export audit logs: $e');
    }
  }

  /// Export revenue report to CSV
  static Future<File> exportRevenueReportToCSV(Map<String, double> monthlyRevenue) async {
    try {
      // Prepare CSV data
      List<List<dynamic>> csvData = [
        // Headers
        ['Month', 'Revenue (Rp)'],
        // Data rows
        ...monthlyRevenue.entries.map((entry) => [
          entry.key,
          entry.value,
        ]),
      ];

      // Convert to CSV string
      String csv = const ListToCsvConverter().convert(csvData);

      // Get documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/revenue_report_$timestamp.csv';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(csv);

      if (kDebugMode) {
        if (kDebugMode) print('✅ [ExportUtils] Revenue report exported to: $filePath');
      }

      return file;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ExportUtils] Error exporting revenue report: $e');
      }
      throw Exception('Failed to export revenue report: $e');
    }
  }
}
