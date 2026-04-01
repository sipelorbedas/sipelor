import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/field.dart';
import '../models/booking.dart';

/// Offline Cache Service — menyimpan data ke file JSON lokal
/// agar aplikasi tetap bisa menampilkan data saat offline.
///
/// Data yang di-cache:
/// - Fields / Lapangan  (TTL: 24 jam)
/// - Bookings user      (TTL: 1 jam)
/// - User profile       (TTL: 6 jam)
///
/// Cara pakai:
/// ```dart
/// final offline = OfflineCacheService();
/// await offline.initialize();
///
/// // Saat online — simpan ke cache
/// await offline.cacheFields(fields);
///
/// // Saat offline — ambil dari cache
/// final fields = await offline.getCachedFields();
/// ```
class OfflineCacheService {
  static final OfflineCacheService _instance = OfflineCacheService._internal();
  factory OfflineCacheService() => _instance;
  OfflineCacheService._internal();

  static const String _prefixTimestamp = 'offline_ts_';
  static const Duration _fieldsTTL = Duration(hours: 24);
  static const Duration _bookingsTTL = Duration(hours: 1);
  static const Duration _profileTTL = Duration(hours: 6);
  static const Duration _reviewsTTL = Duration(minutes: 30);

  SharedPreferences? _prefs;
  Directory? _cacheDir;

  // ─── Inisialisasi ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    if (!kIsWeb) {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/offline_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }
    }
    if (kDebugMode) {
      if (kDebugMode) print('✅ [OfflineCache] Initialized — dir: ${_cacheDir?.path}');
    }
  }

  // ─── Fields / Lapangan ───────────────────────────────────────────────────

  /// Simpan daftar lapangan ke cache lokal
  Future<void> cacheFields(List<Field> fields) async {
    try {
      final jsonList = fields.map((f) => f.toJson()).toList();
      await _writeJsonFile('fields.json', jsonList);
      await _setTimestamp('fields');
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Cached ${fields.length} fields');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Gagal cache fields: $e');
    }
  }

  /// Ambil daftar lapangan dari cache (null jika expired / tidak ada)
  Future<List<Field>?> getCachedFields() async {
    if (!_isFresh('fields', _fieldsTTL)) return null;
    try {
      final data = await _readJsonFile('fields.json');
      if (data == null) return null;
      final list = (data as List).map((e) => Field.fromJson(e as Map<String, dynamic>)).toList();
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Loaded ${list.length} cached fields');
      }
      return list;
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Error membaca cached fields: $e');
      return null;
    }
  }

  // ─── Bookings ────────────────────────────────────────────────────────────

  /// Simpan daftar booking user ke cache lokal
  Future<void> cacheBookings(List<Booking> bookings) async {
    try {
      final jsonList = bookings.map((b) => b.toJson()).toList();
      await _writeJsonFile('bookings.json', jsonList);
      await _setTimestamp('bookings');
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Cached ${bookings.length} bookings');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Gagal cache bookings: $e');
    }
  }

  /// Ambil daftar booking user dari cache (null jika expired / tidak ada)
  Future<List<Booking>?> getCachedBookings() async {
    if (!_isFresh('bookings', _bookingsTTL)) return null;
    try {
      final data = await _readJsonFile('bookings.json');
      if (data == null) return null;
      final list = (data as List).map((e) => Booking.fromJson(e as Map<String, dynamic>)).toList();
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Loaded ${list.length} cached bookings');
      }
      return list;
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Error membaca cached bookings: $e');
      return null;
    }
  }

  // ─── User Profile ────────────────────────────────────────────────────────

  /// Simpan profil user ke cache lokal
  Future<void> cacheUserProfile(Map<String, dynamic> profile) async {
    try {
      await _writeJsonFile('user_profile.json', profile);
      await _setTimestamp('user_profile');
      if (kDebugMode) print('💾 [OfflineCache] Cached user profile');
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Gagal cache profile: $e');
    }
  }

  /// Ambil profil user dari cache (null jika expired / tidak ada)
  Future<Map<String, dynamic>?> getCachedUserProfile() async {
    if (!_isFresh('user_profile', _profileTTL)) return null;
    try {
      final data = await _readJsonFile('user_profile.json');
      if (data == null) return null;
      if (kDebugMode) print('💾 [OfflineCache] Loaded cached user profile');
      return Map<String, dynamic>.from(data as Map);
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Error membaca cached profile: $e');
      return null;
    }
  }

  // ─── Reviews ─────────────────────────────────────────────────────────────

  /// Simpan daftar review untuk venue tertentu ke cache lokal
  Future<void> cacheReviews(
    String venueId,
    List<Map<String, dynamic>> reviews,
  ) async {
    if (venueId.trim().isEmpty) return;
    try {
      await _writeJsonFile('reviews_$venueId.json', reviews);
      await _setTimestamp('reviews_$venueId');
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Cached ${reviews.length} reviews for venue $venueId');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Gagal cache reviews: $e');
    }
  }

  /// Ambil daftar review dari cache (null jika expired / tidak ada)
  Future<List<Map<String, dynamic>>?> getCachedReviews(String venueId) async {
    if (venueId.trim().isEmpty) return null;
    if (!_isFresh('reviews_$venueId', _reviewsTTL)) return null;
    try {
      final data = await _readJsonFile('reviews_$venueId.json');
      if (data == null) return null;
      final list = (data as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (kDebugMode) {
        if (kDebugMode) print('💾 [OfflineCache] Loaded ${list.length} cached reviews for venue $venueId');
      }
      return list;
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Error membaca cached reviews: $e');
      return null;
    }
  }

  // ─── Info & Manajemen ─────────────────────────────────────────────────────

  /// Waktu terakhir sync untuk key tertentu
  DateTime? getLastSyncTime(String key) {
    final ms = _prefs?.getInt('$_prefixTimestamp$key');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  /// Deskripsi singkat waktu sync terakhir
  String getLastSyncDescription(String key) {
    final time = getLastSyncTime(key);
    if (time == null) return 'Belum pernah disinkronkan';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit yang lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam yang lalu';
    return '${diff.inDays} hari yang lalu';
  }

  /// Hapus seluruh cache offline
  Future<void> clearAll() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await _cacheDir!.create();
      }
      final prefs = _prefs;
      if (prefs != null) {
        final keys = prefs.getKeys().where((k) => k.startsWith(_prefixTimestamp));
        for (final k in keys) {
          await prefs.remove(k);
        }
      }
      if (kDebugMode) print('🗑️  [OfflineCache] Cache cleared');
    } catch (e) {
      if (kDebugMode) print('⚠️  [OfflineCache] Error clearing cache: $e');
    }
  }

  /// Ukuran total cache dalam bytes
  Future<int> getCacheSizeBytes() async {
    if (_cacheDir == null || !await _cacheDir!.exists()) return 0;
    int total = 0;
    await for (final entity in _cacheDir!.list()) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }

  // ─── Internal Helpers ─────────────────────────────────────────────────────

  File? _file(String name) {
    if (_cacheDir == null) return null;
    return File('${_cacheDir!.path}/$name');
  }

  Future<void> _writeJsonFile(String name, dynamic data) async {
    if (kIsWeb) return; // Web tidak support file system
    final file = _file(name);
    if (file == null) return;
    // FIX: Hapus flush: true — mempercepat write I/O (OS flush berkala sudah cukup)
    await file.writeAsString(jsonEncode(data));
  }

  Future<dynamic> _readJsonFile(String name) async {
    if (kIsWeb) return null;
    final file = _file(name);
    if (file == null || !await file.exists()) return null;
    final content = await file.readAsString();
    if (content.isEmpty) return null;
    return jsonDecode(content);
  }

  Future<void> _setTimestamp(String key) async {
    await _prefs?.setInt(
      '$_prefixTimestamp$key',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool _isFresh(String key, Duration ttl) {
    final ms = _prefs?.getInt('$_prefixTimestamp$key');
    if (ms == null) return false;
    final saved = DateTime.fromMillisecondsSinceEpoch(ms);
    return DateTime.now().difference(saved) < ttl;
  }
}
