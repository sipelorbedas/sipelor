import 'package:flutter/material.dart';

/// Model untuk banner carousel di home screen.
/// Data diambil dari tabel `carousel_banners` di Supabase.
class CarouselBanner {
  final String id;
  final String title;
  final String subtitle;
  final String badgeText;
  final String? imageUrl;        // URL gambar (jika ada, tampilkan sebagai cover)
  final Color gradientStart;
  final Color gradientEnd;
  final int sortOrder;
  final bool isActive;
  final String? linkUrl;
  final DateTime createdAt;

  const CarouselBanner({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badgeText,
    this.imageUrl,
    required this.gradientStart,
    required this.gradientEnd,
    required this.sortOrder,
    required this.isActive,
    this.linkUrl,
    required this.createdAt,
  });

  factory CarouselBanner.fromJson(Map<String, dynamic> json) {
    return CarouselBanner(
      id:             json['id'] as String,
      title:          json['title'] as String? ?? '',
      subtitle:       json['subtitle'] as String? ?? '',
      badgeText:      json['badge_text'] as String? ?? '',
      imageUrl:       json['image_url'] as String?,
      gradientStart:  _parseColor(json['gradient_start'] as String?, const Color(0xFFD946EF)),
      gradientEnd:    _parseColor(json['gradient_end'] as String?, const Color(0xFFF97316)),
      sortOrder:      json['sort_order'] as int? ?? 0,
      isActive:       json['is_active'] as bool? ?? true,
      linkUrl:        json['link_url'] as String?,
      createdAt:      DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title':           title,
      'subtitle':        subtitle,
      'badge_text':      badgeText,
      'image_url':       imageUrl,
      'gradient_start':  _colorToHex(gradientStart),
      'gradient_end':    _colorToHex(gradientEnd),
      'sort_order':      sortOrder,
      'is_active':       isActive,
      'link_url':        linkUrl,
    };
  }

  static Color _parseColor(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final clean = hex.replaceAll('#', '').trim();
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return fallback;
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Fallback statis saat koneksi gagal / tabel belum ada
  static List<CarouselBanner> get defaults => [
    CarouselBanner(
      id:            'local-1',
      title:         'Diskon Sewa Stadion',
      subtitle:      'Hemat hingga 30%',
      badgeText:     'DISKON 30%',
      imageUrl:      null,
      gradientStart: const Color(0xFFD946EF),
      gradientEnd:   const Color(0xFFF97316),
      sortOrder:     0,
      isActive:      true,
      createdAt:     DateTime.now(),
    ),
    CarouselBanner(
      id:            'local-2',
      title:         'Bupati Cup 2026',
      subtitle:      'Daftar sekarang!',
      badgeText:     'GRATIS',
      imageUrl:      null,
      gradientStart: const Color(0xFF3B82F6),
      gradientEnd:   const Color(0xFF8B5CF6),
      sortOrder:     1,
      isActive:      true,
      createdAt:     DateTime.now(),
    ),
    CarouselBanner(
      id:            'local-3',
      title:         'Paket Latihan',
      subtitle:      'Promo spesial',
      badgeText:     'DISKON 25%',
      imageUrl:      null,
      gradientStart: const Color(0xFF10B981),
      gradientEnd:   const Color(0xFF14B8A6),
      sortOrder:     2,
      isActive:      true,
      createdAt:     DateTime.now(),
    ),
    CarouselBanner(
      id:            'local-4',
      title:         'Early Bird Tiket',
      subtitle:      'Beli sekarang lebih murah',
      badgeText:     'DISKON 20%',
      imageUrl:      null,
      gradientStart: const Color(0xFFEC4899),
      gradientEnd:   const Color(0xFFEF4444),
      sortOrder:     3,
      isActive:      true,
      createdAt:     DateTime.now(),
    ),
  ];
}
