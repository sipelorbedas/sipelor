/// Model untuk Time Slot dengan support harga khusus per username
class TimeSlot {
  final String? id; // UUID dari database, null jika belum disimpan
  final String fieldId;
  final String startTime; // Format: "HH:mm"
  final String endTime; // Format: "HH:mm"
  final int pricePerHour;
  bool isAvailable;
  
  // Special pricing untuk user tertentu (pimpinan)
  final String? specialUsername; // Username yang dapat harga khusus
  final int? specialPrice; // Harga khusus (bisa 0 untuk gratis)
  
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TimeSlot({
    this.id,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    required this.pricePerHour,
    this.isAvailable = true,
    this.specialUsername,
    this.specialPrice,
    this.createdAt,
    this.updatedAt,
  });

  /// Factory constructor untuk parse dari JSON (database)
  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] as String?,
      fieldId: json['field_id'] as String,
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      pricePerHour: json['price_per_hour'] as int,
      isAvailable: json['is_available'] as bool? ?? true,
      specialUsername: json['special_username'] as String?,
      specialPrice: json['special_price'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert ke JSON untuk insert/update ke database
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'field_id': fieldId,
      'start_time': startTime,
      'end_time': endTime,
      'price_per_hour': pricePerHour,
      'is_available': isAvailable,
      'special_username': specialUsername,
      'special_price': specialPrice,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  /// Get harga yang berlaku untuk user tertentu
  /// Jika username cocok dengan specialUsername, return specialPrice
  /// Jika tidak, return pricePerHour normal
  int getPriceForUser(String? username) {
    if (username != null && 
        specialUsername != null && 
        username.toLowerCase() == specialUsername!.toLowerCase() &&
        specialPrice != null) {
      return specialPrice!;
    }
    return pricePerHour;
  }

  /// Check apakah time slot ini punya harga khusus
  bool get hasSpecialPrice => specialUsername != null && specialPrice != null;

  /// Get time range sebagai string
  String get timeRange => '$startTime - $endTime';

  /// Copy with method untuk update properties
  TimeSlot copyWith({
    String? id,
    String? fieldId,
    String? startTime,
    String? endTime,
    int? pricePerHour,
    bool? isAvailable,
    String? specialUsername,
    int? specialPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      fieldId: fieldId ?? this.fieldId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      isAvailable: isAvailable ?? this.isAvailable,
      specialUsername: specialUsername ?? this.specialUsername,
      specialPrice: specialPrice ?? this.specialPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TimeSlot(id: $id, fieldId: $fieldId, timeRange: $timeRange, '
        'price: $pricePerHour, available: $isAvailable, '
        'specialUser: $specialUsername, specialPrice: $specialPrice)';
  }
}
