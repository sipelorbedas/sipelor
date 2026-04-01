/// Pricing / booking mode — derived from the field's [Field.satuan] value.
enum BookingMode {
  perJam,    // default — charged per hour
  perSesi,   // flat fee per session (e.g. "per sesi")
  harian,    // flat fee per day (e.g. "per hari" / "per pertandingan")
  perOrang;  // charged per person per hour (e.g. "per orang")

  /// Derive the booking mode from a raw [satuan] string stored in the DB.
  static BookingMode fromSatuan(String? satuan) {
    final s = (satuan ?? '').toLowerCase().trim();
    if (s.contains('orang'))                         return BookingMode.perOrang;
    if (s.contains('sesi') || s.contains('2jam') || s.contains('2 jam')) return BookingMode.perSesi;
    if (s.contains('hari') || s.contains('pertandingan') ||
        s.contains('resepsi') || s.contains('harian')) {
      return BookingMode.harian;
    }
    return BookingMode.perJam;
  }

  /// Derive booking mode, giving priority to [venueName] for resepsi fields.
  /// Resepsi override only applies when venueName contains 'resepsi' AND
  /// carries a numeric duration (e.g. "Resepsi 8", "Resepsi18").
  /// Fields where satuan is "2 jam" but venueName has no numeric resepsi duration
  /// are treated as [perSesi] — i.e. priced per 2-hour block.
  static BookingMode fromField(String? satuan, String? venueName) {
    // Only treat as resepsi (harian) when venueName has a parseable duration number.
    // E.g. "Resepsi 8" → harian(8 jam), "Resepsi18" → harian(18 jam).
    // "GOR Resepsi XYZ" without a number falls through to fromSatuan.
    if (resepsiDurationFromName(venueName) != null) return BookingMode.harian;
    return fromSatuan(satuan);
  }

  /// Extract the resepsi duration (in hours) from [venueName].
  /// Returns a positive value < 24 when venueName matches pattern like
  /// "Resepsi 8" → 8, "Resepsi18" → 18. Returns null otherwise.
  static int? resepsiDurationFromName(String? venueName) {
    final name = (venueName ?? '').toLowerCase().trim();
    if (!name.contains('resepsi')) return null;
    final match = RegExp(r'\d+').firstMatch(name);
    if (match != null) {
      final parsed = int.tryParse(match.group(0)!);
      if (parsed != null && parsed > 0 && parsed < 24) return parsed;
    }
    return null;
  }
}

/// Field status enum
enum FieldStatus {
  available,
  booked,
  maintenance;

  String get displayName {
    switch (this) {
      case FieldStatus.available:
        return 'Available';
      case FieldStatus.booked:
        return 'Booked';
      case FieldStatus.maintenance:
        return 'Maintenance';
    }
  }

  String get value {
    switch (this) {
      case FieldStatus.available:
        return 'available';
      case FieldStatus.booked:
        return 'booked';
      case FieldStatus.maintenance:
        return 'maintenance';
    }
  }

  static FieldStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'available':
        return FieldStatus.available;
      case 'booked':
        return FieldStatus.booked;
      case 'maintenance':
        return FieldStatus.maintenance;
      default:
        return FieldStatus.available;
    }
  }
}

/// Field model for sports field/venue
class Field {
  final String id;
  final String? venueId; // Note: This column doesn't exist in database, will always be null. Use field.id as venueId when needed.
  final String venueName;
  final String venueType;
  final String area;
  final String? satuan; // Unit for pricing (e.g., "per jam", "per hari", etc.)
  final String? description;
  final int pricePerHour;
  final FieldStatus status;
  final List<String>? imageUrls;
  final double? latitude;
  final double? longitude;
  final String? ukuranLapangan; // Field size (e.g., "16.8m x 24.95m")
  final String? kapasitas; // Capacity (e.g., "14 orang")
  final bool? tempatParkir; // Parking availability
  final bool? mushola; // Prayer room availability
  final bool? cctv; // CCTV availability
  final bool? ruangTunggu; // Waiting room availability
  final bool? ruangGanti; // Changing room availability
  final DateTime createdAt;
  final DateTime updatedAt;

  Field({
    required this.id,
    this.venueId,
    required this.venueName,
    required this.venueType,
    required this.area,
    this.satuan,
    this.description,
    required this.pricePerHour,
    required this.status,
    this.imageUrls,
    this.latitude,
    this.longitude,
    this.ukuranLapangan,
    this.kapasitas,
    this.tempatParkir,
    this.mushola,
    this.cctv,
    this.ruangTunggu,
    this.ruangGanti,
    required this.createdAt,
    required this.updatedAt,
  });

  // Backward compatibility helper
  bool get isActive => status == FieldStatus.available;

  factory Field.fromJson(Map<String, dynamic> json) {
    // Parse image_urls - it can be a List or a single String
    List<String>? imageUrls;
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageUrls = (json['image_urls'] as List)
            .map((e) => e.toString())
            .toList();
      } else if (json['image_urls'] is String) {
        imageUrls = [json['image_urls'] as String];
      }
    }

    // Parse status - handle both new status field and old is_active for backward compatibility
    FieldStatus status = FieldStatus.available;
    if (json['status'] != null) {
      status = FieldStatus.fromString(json['status'] as String);
    } else if (json['is_active'] != null) {
      // Backward compatibility: convert is_active to status
      status = (json['is_active'] as bool) ? FieldStatus.available : FieldStatus.maintenance;
    }

    return Field(
      id: json['id'] as String,
      venueId: json['venue_id'] as String?,
      venueName: (json['venue_name'] as String?) ?? '',
      venueType: (json['venue_type'] as String?) ?? '',
      area: (json['area'] as String?) ?? '',
      satuan: json['satuan'] as String?,
      description: json['description'] as String?,
      // Use (as num).toInt() to handle both int and double from Supabase
      pricePerHour: (json['price_per_hour'] as num?)?.toInt() ?? 0,
      status: status,
      imageUrls: imageUrls,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      ukuranLapangan: json['ukuran_lapangan'] as String?,
      kapasitas: json['kapasitas'] as String?,
      tempatParkir: json['tempat_parkir'] as bool?,
      mushola: json['mushola'] as bool?,
      cctv: json['cctv'] as bool?,
      ruangTunggu: json['ruang_tunggu'] as bool?,
      ruangGanti: json['ruang_ganti'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'venue_name': venueName,
      'venue_type': venueType,
      'area': area,
      'satuan': satuan,
      'description': description,
      'price_per_hour': pricePerHour,
      'status': status.value,
      'is_active': isActive, // Keep for backward compatibility
      'image_urls': imageUrls,
      'latitude': latitude,
      'longitude': longitude,
      'ukuran_lapangan': ukuranLapangan,
      'kapasitas': kapasitas,
      'tempat_parkir': tempatParkir,
      'mushola': mushola,
      'cctv': cctv,
      'ruang_tunggu': ruangTunggu,
      'ruang_ganti': ruangGanti,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Field copyWith({
    String? id,
    String? venueId,
    String? venueName,
    String? venueType,
    String? area,
    String? satuan,
    String? description,
    int? pricePerHour,
    FieldStatus? status,
    List<String>? imageUrls,
    double? latitude,
    double? longitude,
    String? ukuranLapangan,
    String? kapasitas,
    bool? tempatParkir,
    bool? mushola,
    bool? cctv,
    bool? ruangTunggu,
    bool? ruangGanti,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Field(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      venueType: venueType ?? this.venueType,
      area: area ?? this.area,
      satuan: satuan ?? this.satuan,
      description: description ?? this.description,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      status: status ?? this.status,
      imageUrls: imageUrls ?? this.imageUrls,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      ukuranLapangan: ukuranLapangan ?? this.ukuranLapangan,
      kapasitas: kapasitas ?? this.kapasitas,
      tempatParkir: tempatParkir ?? this.tempatParkir,
      mushola: mushola ?? this.mushola,
      cctv: cctv ?? this.cctv,
      ruangTunggu: ruangTunggu ?? this.ruangTunggu,
      ruangGanti: ruangGanti ?? this.ruangGanti,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
