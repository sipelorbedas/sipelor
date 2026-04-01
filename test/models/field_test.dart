import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/models/field.dart';

void main() {
  // ─── Helper ─────────────────────────────────────────────────────────────────
  Map<String, dynamic> baseJson({
    String status = 'available',
    dynamic imageUrls,
    bool? isActive,
  }) =>
      {
        'id': 'field-uuid-001',
        'venue_name': 'Lapangan Futsal Jalak Harupat',
        'venue_type': 'Futsal',
        'area': 'Bandung Barat',
        'price_per_hour': 150000,
        'satuan': 'per jam',
        'description': 'Lapangan futsal indoor berkualitas',
        'status': status,
        'image_urls': imageUrls,
        'latitude': -6.9963,
        'longitude': 107.5296,
        'ukuran_lapangan': '16.8m x 24.95m',
        'kapasitas': '14 orang',
        'tempat_parkir': true,
        'mushola': true,
        'cctv': true,
        'ruang_tunggu': false,
        'ruang_ganti': true,
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
        'is_active': ?isActive,
      };

  // ─── Field.fromJson ──────────────────────────────────────────────────────────
  group('Field.fromJson', () {
    test('parses all required fields', () {
      final f = Field.fromJson(baseJson(imageUrls: [
        'https://example.com/img1.jpg',
        'https://example.com/img2.jpg',
      ]));
      expect(f.id, 'field-uuid-001');
      expect(f.venueName, 'Lapangan Futsal Jalak Harupat');
      expect(f.venueType, 'Futsal');
      expect(f.area, 'Bandung Barat');
      expect(f.pricePerHour, 150000);
      expect(f.satuan, 'per jam');
      expect(f.description, 'Lapangan futsal indoor berkualitas');
      expect(f.status, FieldStatus.available);
      expect(f.imageUrls?.length, 2);
      expect(f.latitude, closeTo(-6.9963, 0.0001));
      expect(f.longitude, closeTo(107.5296, 0.0001));
      expect(f.ukuranLapangan, '16.8m x 24.95m');
      expect(f.kapasitas, '14 orang');
      expect(f.tempatParkir, true);
      expect(f.mushola, true);
      expect(f.cctv, true);
      expect(f.ruangTunggu, false);
      expect(f.ruangGanti, true);
    });

    test('parses single string image_url as list of one', () {
      final f = Field.fromJson(
          baseJson(imageUrls: 'https://example.com/single.jpg'));
      expect(f.imageUrls?.length, 1);
      expect(f.imageUrls?.first, 'https://example.com/single.jpg');
    });

    test('handles null image_urls gracefully', () {
      final f = Field.fromJson(baseJson(imageUrls: null));
      expect(f.imageUrls, isNull);
    });

    test('backward compat: uses is_active when status is absent', () {
      final json = baseJson()..remove('status');
      json['is_active'] = true;
      final f = Field.fromJson(json);
      expect(f.status, FieldStatus.available);
      expect(f.isActive, true);
    });

    test('backward compat: is_active=false maps to maintenance', () {
      final json = baseJson()..remove('status');
      json['is_active'] = false;
      final f = Field.fromJson(json);
      expect(f.status, FieldStatus.maintenance);
      expect(f.isActive, false);
    });

    test('status field takes precedence over is_active', () {
      final json = baseJson(status: 'booked');
      json['is_active'] = true; // should be ignored
      final f = Field.fromJson(json);
      expect(f.status, FieldStatus.booked);
    });

    test('handles null optional fields', () {
      final json = <String, dynamic>{
        'id': 'field-uuid',
        'venue_name': 'Test',
        'venue_type': 'Badminton',
        'area': 'Bandung',
        'price_per_hour': 100000,
        'status': 'available',
        'created_at': '2026-01-01T00:00:00Z',
        'updated_at': '2026-01-01T00:00:00Z',
      };
      final f = Field.fromJson(json);
      expect(f.satuan, isNull);
      expect(f.description, isNull);
      expect(f.imageUrls, isNull);
      expect(f.latitude, isNull);
      expect(f.longitude, isNull);
      expect(f.ukuranLapangan, isNull);
    });
  });

  // ─── Field.toJson ────────────────────────────────────────────────────────────
  group('Field.toJson', () {
    test('serializes all fields', () {
      final f = Field(
        id: 'field-001',
        venueName: 'Lapangan A',
        venueType: 'Futsal',
        area: 'Bandung',
        pricePerHour: 100000,
        status: FieldStatus.available,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        imageUrls: ['https://example.com/img.jpg'],
      );
      final json = f.toJson();
      expect(json['id'], 'field-001');
      expect(json['venue_name'], 'Lapangan A');
      expect(json['status'], 'available');
      expect(json['is_active'], true); // backward compat
      expect(json['image_urls'], isNotNull);
    });
  });

  // ─── Field.copyWith ──────────────────────────────────────────────────────────
  group('Field.copyWith', () {
    late Field original;
    setUp(() {
      original = Field.fromJson(baseJson());
    });

    test('produces identical copy when nothing overridden', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.venueName, original.venueName);
    });

    test('overrides only specified fields', () {
      final updated = original.copyWith(
        status: FieldStatus.maintenance,
        pricePerHour: 200000,
      );
      expect(updated.status, FieldStatus.maintenance);
      expect(updated.pricePerHour, 200000);
      expect(updated.venueName, original.venueName);
    });
  });

  // ─── FieldStatus ────────────────────────────────────────────────────────────
  group('FieldStatus', () {
    test('fromString parses all valid values', () {
      expect(FieldStatus.fromString('available'), FieldStatus.available);
      expect(FieldStatus.fromString('booked'), FieldStatus.booked);
      expect(FieldStatus.fromString('maintenance'), FieldStatus.maintenance);
    });

    test('fromString is case-insensitive', () {
      expect(FieldStatus.fromString('AVAILABLE'), FieldStatus.available);
      expect(FieldStatus.fromString('Booked'), FieldStatus.booked);
    });

    test('fromString defaults to available for unknown', () {
      expect(FieldStatus.fromString('unknown'), FieldStatus.available);
    });

    test('displayName returns correct strings', () {
      expect(FieldStatus.available.displayName, 'Available');
      expect(FieldStatus.booked.displayName, 'Booked');
      expect(FieldStatus.maintenance.displayName, 'Maintenance');
    });

    test('value getter returns lowercase string', () {
      expect(FieldStatus.available.value, 'available');
      expect(FieldStatus.booked.value, 'booked');
      expect(FieldStatus.maintenance.value, 'maintenance');
    });

    test('isActive reflects available status only', () {
      final available = Field(
        id: 'f1',
        venueName: 'T',
        venueType: 'Futsal',
        area: 'A',
        pricePerHour: 100000,
        status: FieldStatus.available,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final booked = available.copyWith(status: FieldStatus.booked);
      final maintenance = available.copyWith(status: FieldStatus.maintenance);
      expect(available.isActive, true);
      expect(booked.isActive, false);
      expect(maintenance.isActive, false);
    });
  });
}
