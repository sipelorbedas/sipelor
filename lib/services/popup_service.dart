import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk mengambil popup banner aktif dari Supabase.
/// Popup ditampilkan sekali per hari setelah pengguna login.
class PopupService {
  /// Ambil satu popup banner yang aktif dan paling baru.
  /// Mengembalikan null jika tidak ada popup aktif atau terjadi error.
  static Future<Map<String, dynamic>?> fetchActivePopup() async {
    try {
      final supabase = Supabase.instance.client;

      final data = await supabase
          .from('popup_banners')
          .select('id, image_url, link_url, is_active')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return data;
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  [PopupService] fetchActivePopup error: $e');
      }
      return null;
    }
  }
}
