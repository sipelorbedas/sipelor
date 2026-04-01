enum PaymentStatus {
  pending,
  uploaded,
  verified,
  failed
}

enum PaymentMethod {
  bjb,
  mandiri,
  bri,
  gopay,
  ovo,
  dana,
  linkaja,
  qris
}

class PaymentConfirmationData {
  final String venueName;
  final String fieldName;
  final String bookingDateTime;
  final PaymentMethod paymentMethod;
  final String accountNumber;
  final String accountName;
  final double totalPrice;
  final DateTime paymentDeadline;
  final String userName;
  final String? venueType; // Jenis Venue (Futsal, Badminton, dll)

  // OPD fields
  final bool isOpdFreeBooking;   // true jika OPD dengan diskon 100%
  final int discountPercentage;  // 0–100, diskon OPD yang diterapkan
  final double originalPrice;    // Harga sebelum diskon
  final String? opdName;         // Nama OPD (untuk ditampilkan)

  PaymentConfirmationData({
    required this.venueName,
    required this.fieldName,
    required this.bookingDateTime,
    required this.paymentMethod,
    required this.accountNumber,
    required this.accountName,
    required this.totalPrice,
    required this.paymentDeadline,
    required this.userName,
    this.venueType,
    this.isOpdFreeBooking = false,
    this.discountPercentage = 0,
    double? originalPrice,
    this.opdName,
  }) : originalPrice = originalPrice ?? totalPrice;
}

class PaymentProof {
  final String? filePath;
  final String? fileName;
  final DateTime? uploadedAt;
  final PaymentStatus status;

  PaymentProof({
    this.filePath,
    this.fileName,
    this.uploadedAt,
    this.status = PaymentStatus.pending,
  });
}
