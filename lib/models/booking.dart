// Sentinel object for copyWith — lets callers explicitly pass null to clear nullable fields
const _unset = _Unset();
class _Unset { const _Unset(); }

/// Booking model for sports field bookings
class Booking {
  final String id;
  final String bookingId; // e.g., 'BOOK001'
  final String userId;
  final String fieldId;
  final String venueId;
  final DateTime bookingDate;
  final String startTime; // e.g., '08:00'
  final String endTime; // e.g., '10:00'
  final int durationHours;
  final int totalAmount;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Additional fields from join with fields table
  final String? venueName;
  final String? fieldArea;
  final String? venueType;
  // Whether payment proof has been uploaded for this booking
  final bool hasPaymentProof;
  // OPD / Pimpinan booking fields
  final BookingType bookingType;
  final String? opdId;          // FK to opd_organizations
  final String? bookedForLabel; // Display label, e.g. "Acara Bupati Cup 2026"
  final String? opdName;        // Nama OPD dari opd_organizations.name (diisi saat fetch)

  Booking({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.fieldId,
    required this.venueId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.venueName,
    this.fieldArea,
    this.venueType,
    this.hasPaymentProof = true,
    this.bookingType = BookingType.regular,
    this.opdId,
    this.bookedForLabel,
    this.opdName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Handle nested fields data from join
    String? venueName;
    String? fieldArea;
    String? venueType;
    
    // Try different possible field names for the joined data
    if (json['fields'] != null && json['fields'] is Map) {
      final fieldsData = json['fields'] as Map<String, dynamic>;
      venueName = fieldsData['venue_name'] as String?;
      fieldArea = fieldsData['area'] as String?;
      venueType = fieldsData['venue_type'] as String?;
    }
    
    // IMPORTANT: venue_id might reference field_id since venue table doesn't exist
    // All venue data is stored in fields table
    final fieldId = json['field_id'] as String;
    final venueId = json['venue_id'] as String? ?? fieldId; // Use field_id if venue_id is null
    
    return Booking(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      userId: json['user_id'] as String,
      fieldId: fieldId,
      venueId: venueId,
      bookingDate: DateTime.parse(json['booking_date'] as String),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      durationHours: json['duration_hours'] as int,
      totalAmount: json['total_amount'] as int,
      status: BookingStatus.fromString(json['status'] as String),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      venueName: venueName,
      fieldArea: fieldArea,
      venueType: venueType,
      hasPaymentProof: json['has_payment_proof'] as bool? ?? true,
      bookingType: BookingType.fromString(json['booking_type'] as String? ?? 'regular'),
      opdId: json['opd_id'] as String?,
      bookedForLabel: json['booked_for_label'] as String?,
      opdName: json['opd_name'] as String? ??
          (json['opd_organizations'] is Map
              ? (json['opd_organizations'] as Map<String, dynamic>)['name'] as String?
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'field_id': fieldId,
      'venue_id': venueId,
      'booking_date': bookingDate.toIso8601String().split('T')[0], // Format as date only
      'start_time': startTime,
      'end_time': endTime,
      'duration_hours': durationHours,
      'total_amount': totalAmount,
      'status': status.value,
      'payment_status': paymentStatus.value,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'booking_type': bookingType.value,
      'opd_id': opdId,
      'booked_for_label': bookedForLabel,
      if (opdName != null) 'opd_name': opdName,
    };
  }

  /// Create a copy of this Booking with the given fields replaced with new values.
  ///
  /// Nullable fields accept an explicit `null` to clear them — pass the sentinel
  /// `_unset` (default) to keep the current value.
  Booking copyWith({
    String? id,
    String? bookingId,
    String? userId,
    String? fieldId,
    String? venueId,
    DateTime? bookingDate,
    String? startTime,
    String? endTime,
    int? durationHours,
    int? totalAmount,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    Object? notes = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? venueName = _unset,
    Object? fieldArea = _unset,
    Object? venueType = _unset,
    bool? hasPaymentProof,
    BookingType? bookingType,
    Object? opdId = _unset,
    Object? bookedForLabel = _unset,
    Object? opdName = _unset,
  }) {
    return Booking(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      fieldId: fieldId ?? this.fieldId,
      venueId: venueId ?? this.venueId,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      totalAmount: totalAmount ?? this.totalAmount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes == _unset ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      venueName: venueName == _unset ? this.venueName : venueName as String?,
      fieldArea: fieldArea == _unset ? this.fieldArea : fieldArea as String?,
      venueType: venueType == _unset ? this.venueType : venueType as String?,
      hasPaymentProof: hasPaymentProof ?? this.hasPaymentProof,
      bookingType: bookingType ?? this.bookingType,
      opdId: opdId == _unset ? this.opdId : opdId as String?,
      bookedForLabel: bookedForLabel == _unset ? this.bookedForLabel : bookedForLabel as String?,
      opdName: opdName == _unset ? this.opdName : opdName as String?,
    );
  }
}

/// Booking type enum — regular user vs OPD/Pimpinan
enum BookingType {
  regular,
  opd,
  pimpinan;

  String get value {
    switch (this) {
      case BookingType.regular:
        return 'regular';
      case BookingType.opd:
        return 'opd';
      case BookingType.pimpinan:
        return 'pimpinan';
    }
  }

  static BookingType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'opd':
        return BookingType.opd;
      case 'pimpinan':
        return BookingType.pimpinan;
      default:
        return BookingType.regular;
    }
  }

  bool get isOfficialBooking =>
      this == BookingType.opd || this == BookingType.pimpinan;

  String get displayName {
    switch (this) {
      case BookingType.regular:
        return 'Reguler';
      case BookingType.opd:
        return 'OPD';
      case BookingType.pimpinan:
        return 'Pimpinan';
    }
  }
}

/// Booking status enum
enum BookingStatus {
  pending,
  confirmed,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case BookingStatus.pending:
        return 'pending';
      case BookingStatus.confirmed:
        return 'confirmed';
      case BookingStatus.completed:
        return 'completed';
      case BookingStatus.cancelled:
        return 'cancelled';
    }
  }

  static BookingStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return BookingStatus.pending;
      case 'confirmed':
        return BookingStatus.confirmed;
      case 'completed':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case BookingStatus.pending:
        return 'Menunggu';
      case BookingStatus.confirmed:
        return 'Dikonfirmasi';
      case BookingStatus.completed:
        return 'Selesai';
      case BookingStatus.cancelled:
        return 'Dibatalkan';
    }
  }
}

/// Payment status enum
enum PaymentStatus {
  pending,
  verified,
  rejected;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.verified:
        return 'verified';
      case PaymentStatus.rejected:
        return 'rejected';
    }
  }

  static PaymentStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return PaymentStatus.pending;
      case 'verified':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Menunggu Verifikasi';
      case PaymentStatus.verified:
        return 'Terverifikasi';
      case PaymentStatus.rejected:
        return 'Ditolak';
    }
  }
}
