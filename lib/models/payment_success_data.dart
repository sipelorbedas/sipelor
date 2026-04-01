class PaymentSuccessData {
  final String bookingCode;
  final String bookingDate;
  final String bookingTime;
  final String venueName;
  final String fieldName;
  final String paymentMethod;
  final double totalAmount;

  PaymentSuccessData({
    required this.bookingCode,
    required this.bookingDate,
    required this.bookingTime,
    required this.venueName,
    required this.fieldName,
    required this.paymentMethod,
    required this.totalAmount,
  });
}
