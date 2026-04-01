import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/carousel_banner.dart';

/// Service untuk mengambil data carousel dari Supabase.
/// Tabel: `carousel_banners`
/// Bucket: `carousel-banners` (public)
class CarouselService {
  static const String _table = 'carousel_banners';
  static const String _bucket = 'carousel-banners';

  static SupabaseClient get _db => Supabase.instance.client;

  /// Ambil semua banner aktif, diurutkan berdasarkan sort_order.
  /// Mengembalikan fallback statis jika gagal (tabel belum ada / offline).
  static Future<List<CarouselBanner>> fetchActiveBanners() async {
    try {
      final response = await _db
          .from(_table)
          .select()
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final list = (response as List<dynamic>)
          .map((e) => CarouselBanner.fromJson(e as Map<String, dynamic>))
          .toList();

      if (kDebugMode) {
        if (kDebugMode) print('🎠 [CarouselService] Loaded ${list.length} banners from Supabase');
      }

      // Jika tabel kosong, gunakan fallback statis agar UI tidak kosong
      return list.isEmpty ? CarouselBanner.defaults : list;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [CarouselService] Failed to fetch banners, using defaults: $e');
      }
      return CarouselBanner.defaults;
    }
  }

  /// Generate public URL untuk gambar di storage bucket `carousel-banners`.
  static String getPublicUrl(String storagePath) {
    return _db.storage.from(_bucket).getPublicUrl(storagePath);
  }
}
