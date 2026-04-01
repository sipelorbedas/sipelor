class ETicketData {
  final String venueName;
  final String fieldName;
  final String bookingDateTime;
  final String bookingCode;

  ETicketData({
    required this.venueName,
    required this.fieldName,
    required this.bookingDateTime,
    required this.bookingCode,
  });

  factory ETicketData.fromJson(Map<String, dynamic> json) {
    return ETicketData(
      venueName: json['venueName'] as String,
      fieldName: json['fieldName'] as String,
      bookingDateTime: json['bookingDateTime'] as String,
      bookingCode: json['bookingCode'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'venueName': venueName,
      'fieldName': fieldName,
      'bookingDateTime': bookingDateTime,
      'bookingCode': bookingCode,
    };
  }
}
