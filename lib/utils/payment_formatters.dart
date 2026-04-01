import '../models/payment_confirmation_data.dart';

class PaymentFormatters {
  // Currency formatter
  static String formatCurrency(double amount) {
    return 'Rp. ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  // Date/Time formatter
  static String formatBookingDateTime(DateTime dateTime) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    const days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];

    final day = days[dateTime.weekday % 7];
    final date = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day, $date $month $year | $hour.$minute';
  }

  // Payment method name
  static String getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bjb:
        return 'Transfer BJB';
      case PaymentMethod.mandiri:
        return 'Transfer Mandiri';
      case PaymentMethod.bri:
        return 'BRI';
      case PaymentMethod.gopay:
        return 'GoPay';
      case PaymentMethod.ovo:
        return 'OVO';
      case PaymentMethod.dana:
        return 'DANA';
      case PaymentMethod.linkaja:
        return 'LinkAja';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }

  // Payment method logo
  static String getPaymentMethodLogo(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.bjb:
        return 'assets/images/logo_bjb.png';
      case PaymentMethod.mandiri:
        return 'assets/images/logo_mandiri.png';
      case PaymentMethod.bri:
        return 'assets/images/logo_bri.png';
      case PaymentMethod.gopay:
        return 'assets/images/logo_gopay.png';
      case PaymentMethod.ovo:
        return 'assets/images/logo_ovo.png';
      case PaymentMethod.dana:
        return 'assets/images/logo_dana.png';
      case PaymentMethod.linkaja:
        return 'assets/images/logo_linkaja.png';
      case PaymentMethod.qris:
        return 'assets/images/QRIS.png';
    }
  }

  // Extract date from booking datetime string
  // Input format: "Sabtu, 3 Januari 2023 | 18.00"
  // Output format: "Sabtu, 3 Januari 2023"
  static String extractDate(String bookingDateTime) {
    final parts = bookingDateTime.split('|');
    return parts.isNotEmpty ? parts[0].trim() : bookingDateTime;
  }

  // Extract time from booking datetime string
  // Input format: "Sabtu, 3 Januari 2023 | 18.00"
  // Output format: "18.00"
  static String extractTime(String bookingDateTime) {
    final parts = bookingDateTime.split('|');
    return parts.length > 1 ? parts[1].trim() : '';
  }

  // Extract field number from field name
  // Input examples: "Lapangan 2", "Field 2", "2"
  // Output: "2"
  static String extractFieldNumber(String fieldName) {
    // Try to extract number from the string
    final match = RegExp(r'\d+').firstMatch(fieldName);
    return match != null ? match.group(0)! : fieldName;
  }

  // Format currency in short format (e.g., Rp 38.5Jt)
  static String formatCurrencyShort(double amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return 'Rp ${millions.toStringAsFixed(1)}Jt';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return 'Rp ${thousands.toStringAsFixed(0)}Rb';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  /// Format currency to compact format (for charts/small spaces)
  /// Example: 1500000 -> Rp 1.5M
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}K';
    } else {
      return 'Rp ${amount.toStringAsFixed(0)}';
    }
  }

  /// Format amount only without currency symbol
  /// Example: 150000 -> 150.000
  static String formatAmountOnly(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  /// Format booking status display text
  static String formatBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  /// Format payment status display text
  static String formatPaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'verified':
        return 'Terverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  /// Format to Rupiah (alias for formatCurrency)
  static String formatToRupiah(double amount) {
    return formatCurrency(amount);
  }
}
