import 'package:intl/intl.dart';

/// Helper class for time formatting and timezone conversion
class TimeHelper {
  /// Convert UTC DateTime to Indonesian timezone (WIB = UTC+7)
  /// 
  /// Indonesia has 3 timezones:
  /// - WIB (Waktu Indonesia Barat): UTC+7 - Jakarta, Java, Sumatra
  /// - WITA (Waktu Indonesia Tengah): UTC+8 - Bali, Kalimantan, Sulawesi
  /// - WIT (Waktu Indonesia Timur): UTC+9 - Papua, Maluku
  /// 
  /// By default, we use WIB (UTC+7) which covers most of Indonesia
  static DateTime toIndonesiaTime(DateTime utcTime, {int offsetHours = 7}) {
    return utcTime.add(Duration(hours: offsetHours));
  }

  /// Convert UTC DateTime to WIB (UTC+7)
  static DateTime toWIB(DateTime utcTime) {
    return toIndonesiaTime(utcTime, offsetHours: 7);
  }

  /// Convert UTC DateTime to WITA (UTC+8)
  static DateTime toWITA(DateTime utcTime) {
    return toIndonesiaTime(utcTime, offsetHours: 8);
  }

  /// Convert UTC DateTime to WIT (UTC+9)
  static DateTime toWIT(DateTime utcTime) {
    return toIndonesiaTime(utcTime, offsetHours: 9);
  }

  /// Format time for chat messages in Indonesian timezone
  /// Returns format: HH:mm (e.g., 14:30)
  static String formatChatTime(DateTime utcTime, {int offsetHours = 7}) {
    final localTime = toIndonesiaTime(utcTime, offsetHours: offsetHours);
    return DateFormat('HH:mm').format(localTime);
  }

  /// Format date for chat date separators in Indonesian
  /// Returns: "Hari ini", "Kemarin", or "dd MMM yyyy"
  static String formatChatDate(DateTime utcTime, {int offsetHours = 7}) {
    final localTime = toIndonesiaTime(utcTime, offsetHours: offsetHours);
    final now = DateTime.now().add(Duration(hours: offsetHours));
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (messageDate == today) {
      return 'Hari ini';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else {
      return DateFormat('dd MMM yyyy', 'id_ID').format(localTime);
    }
  }

  /// Format time for chat list (conversation list)
  /// Returns: "HH:mm" for today, "Kemarin", day name, or date
  static String formatConversationTime(DateTime utcTime, {int offsetHours = 7}) {
    final localTime = toIndonesiaTime(utcTime, offsetHours: offsetHours);
    final now = DateTime.now().add(Duration(hours: offsetHours));
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(localTime.year, localTime.month, localTime.day);

    if (messageDate == today) {
      return DateFormat('HH:mm').format(localTime);
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      return 'Kemarin';
    } else if (now.difference(localTime).inDays < 7) {
      return DateFormat('EEE', 'id_ID').format(localTime);
    } else {
      return DateFormat('dd/MM/yy').format(localTime);
    }
  }

  /// Format full date and time in Indonesian
  /// Returns format: "dd MMM yyyy, HH:mm WIB"
  static String formatFullDateTime(DateTime utcTime, {int offsetHours = 7, String timezone = 'WIB'}) {
    final localTime = toIndonesiaTime(utcTime, offsetHours: offsetHours);
    return '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(localTime)} $timezone';
  }

  /// Get timezone name based on offset
  static String getTimezoneName(int offsetHours) {
    switch (offsetHours) {
      case 7:
        return 'WIB';
      case 8:
        return 'WITA';
      case 9:
        return 'WIT';
      default:
        return 'UTC+$offsetHours';
    }
  }
}
