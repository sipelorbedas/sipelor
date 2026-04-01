import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// HTTP Cache Service for API Response Caching
///
/// Features:
/// - In-memory cache for ultra-fast access
/// - Persistent cache using SharedPreferences
/// - TTL (Time To Live) support
/// - Cache invalidation
/// - Size limits to prevent excessive storage
///
/// Usage:
/// ```dart
/// final cache = HttpCacheService();
/// await cache.initialize();
///
/// // Cache response
/// await cache.set('venues_list', jsonData, ttl: Duration(minutes: 5));
///
/// // Get from cache
/// final data = await cache.get('venues_list');
///
/// // Clear specific cache
/// await cache.delete('venues_list');
/// ```
class HttpCacheService {
  static final HttpCacheService _instance = HttpCacheService._internal();
  factory HttpCacheService() => _instance;
  HttpCacheService._internal();

  SharedPreferences? _prefs;
  final Map<String, _CacheEntry> _memoryCache = {};
  
  // Configuration
  static const int _maxMemoryCacheSize = 50; // Max items in memory
  static const int _maxDiskCacheSize = 100; // Max items on disk
  static const String _cachePrefix = 'http_cache_';
  static const Duration _defaultTTL = Duration(minutes: 5);

  // FIX: Throttle disk limit check — jangan panggil tiap set()
  int _setCallCount = 0;
  static const int _diskLimitCheckInterval = 10; // Cek setiap 10 set() calls

  /// Initialize cache service
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      // FIX: Pindahkan cleanup ke background agar tidak memblokir startup
      Future.microtask(_cleanExpiredCache);
      
      if (kDebugMode) {
        if (kDebugMode) print('✅ HTTP Cache Service initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ Error initializing HTTP Cache Service: $e');
      }
    }
  }

  /// Get cached data
  Future<dynamic> get(String key) async {
    // Check memory cache first
    if (_memoryCache.containsKey(key)) {
      final entry = _memoryCache[key]!;
      if (!entry.isExpired) {
        if (kDebugMode) {
          if (kDebugMode) print('💾 Cache HIT (memory): $key');
        }
        return entry.data;
      } else {
        // Remove expired entry
        _memoryCache.remove(key);
      }
    }

    // Check disk cache
    if (_prefs != null) {
      final cacheKey = '$_cachePrefix$key';
      final jsonString = _prefs!.getString(cacheKey);
      
      if (jsonString != null) {
        try {
          final Map<String, dynamic> cacheData = jsonDecode(jsonString);
          final expiry = DateTime.parse(cacheData['expiry'] as String);
          
          if (DateTime.now().isBefore(expiry)) {
            final data = cacheData['data'];
            
            // Store in memory cache for faster access
            _memoryCache[key] = _CacheEntry(
              data: data,
              expiry: expiry,
            );
            
            if (kDebugMode) {
              if (kDebugMode) print('💾 Cache HIT (disk): $key');
            }
            return data;
          } else {
            // Remove expired entry
            await _prefs!.remove(cacheKey);
          }
        } catch (e) {
          if (kDebugMode) {
            if (kDebugMode) print('⚠️  Error reading cache: $e');
          }
        }
      }
    }

    if (kDebugMode) {
      if (kDebugMode) print('❌ Cache MISS: $key');
    }
    return null;
  }

  /// Set cached data
  Future<void> set(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    final expiry = DateTime.now().add(ttl ?? _defaultTTL);
    
    // Store in memory cache
    _memoryCache[key] = _CacheEntry(
      data: data,
      expiry: expiry,
    );
    
    // Limit memory cache size
    if (_memoryCache.length > _maxMemoryCacheSize) {
      _evictOldestMemoryCache();
    }

    // Store in disk cache
    if (_prefs != null) {
      try {
        final cacheKey = '$_cachePrefix$key';
        final cacheData = {
          'data': data,
          'expiry': expiry.toIso8601String(),
        };
        
        await _prefs!.setString(cacheKey, jsonEncode(cacheData));

        // FIX: Throttle disk limit enforcement — tidak perlu tiap set()
        _setCallCount++;
        if (_setCallCount % _diskLimitCheckInterval == 0) {
          unawaited(_enforceDiskCacheLimit());
        }
        
        if (kDebugMode) {
          if (kDebugMode) print('💾 Cache SET: $key (expires: ${expiry.toLocal()})');
        }
      } catch (e) {
        if (kDebugMode) {
          if (kDebugMode) print('⚠️  Error setting cache: $e');
        }
      }
    }
  }

  /// Delete specific cache entry
  Future<void> delete(String key) async {
    _memoryCache.remove(key);
    
    if (_prefs != null) {
      final cacheKey = '$_cachePrefix$key';
      await _prefs!.remove(cacheKey);
      
      if (kDebugMode) {
        if (kDebugMode) print('🗑️  Cache DELETED: $key');
      }
    }
  }

  /// Clear all cache
  /// FIX: Batch semua remove sekaligus via Future.wait agar tidak sequential blocking
  Future<void> clearAll() async {
    _memoryCache.clear();

    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();

      // Jalankan semua remove secara paralel, bukan sequential
      await Future.wait(cacheKeys.map((key) => _prefs!.remove(key)));

      if (kDebugMode) {
        if (kDebugMode) print('🗑️  All cache CLEARED (${cacheKeys.length} entries)');
      }
    }
  }

  /// Clear expired cache entries
  Future<void> _cleanExpiredCache() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix));
    int removedCount = 0;

    for (final key in cacheKeys) {
      final jsonString = _prefs!.getString(key);
      if (jsonString != null) {
        try {
          final Map<String, dynamic> cacheData = jsonDecode(jsonString);
          final expiry = DateTime.parse(cacheData['expiry'] as String);
          
          if (DateTime.now().isAfter(expiry)) {
            await _prefs!.remove(key);
            removedCount++;
          }
        } catch (e) {
          // Invalid cache entry, remove it
          await _prefs!.remove(key);
          removedCount++;
        }
      }
    }

    if (kDebugMode && removedCount > 0) {
      if (kDebugMode) print('🧹 Cleaned $removedCount expired cache entries');
    }
  }

  /// Evict oldest entry from memory cache
  void _evictOldestMemoryCache() {
    if (_memoryCache.isEmpty) return;

    // Find entry with earliest expiry
    String? oldestKey;
    DateTime? earliestExpiry;

    for (final entry in _memoryCache.entries) {
      if (oldestKey == null || entry.value.expiry.isBefore(earliestExpiry!)) {
        oldestKey = entry.key;
        earliestExpiry = entry.value.expiry;
      }
    }

    if (oldestKey != null) {
      _memoryCache.remove(oldestKey);
      if (kDebugMode) {
        if (kDebugMode) print('🗑️  Evicted oldest memory cache: $oldestKey');
      }
    }
  }

  /// Enforce disk cache size limit
  Future<void> _enforceDiskCacheLimit() async {
    if (_prefs == null) return;

    final keys = _prefs!.getKeys();
    final cacheKeys = keys.where((k) => k.startsWith(_cachePrefix)).toList();

    if (cacheKeys.length > _maxDiskCacheSize) {
      // Sort by expiry and remove oldest
      final entries = <String, DateTime>{};
      
      for (final key in cacheKeys) {
        final jsonString = _prefs!.getString(key);
        if (jsonString != null) {
          try {
            final Map<String, dynamic> cacheData = jsonDecode(jsonString);
            final expiry = DateTime.parse(cacheData['expiry'] as String);
            entries[key] = expiry;
          } catch (e) {
            // Invalid entry, will be removed
            entries[key] = DateTime.now();
          }
        }
      }

      // Sort by expiry (oldest first)
      final sortedKeys = entries.keys.toList()
        ..sort((a, b) => entries[a]!.compareTo(entries[b]!));

      // Remove excess entries
      final toRemove = cacheKeys.length - _maxDiskCacheSize;
      for (var i = 0; i < toRemove; i++) {
        await _prefs!.remove(sortedKeys[i]);
      }

      if (kDebugMode) {
        if (kDebugMode) print('🗑️  Removed $toRemove old disk cache entries');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int diskCacheCount = 0;
    
    if (_prefs != null) {
      final keys = _prefs!.getKeys();
      diskCacheCount = keys.where((k) => k.startsWith(_cachePrefix)).length;
    }

    return {
      'memory_cache_size': _memoryCache.length,
      'disk_cache_size': diskCacheCount,
      'max_memory_size': _maxMemoryCacheSize,
      'max_disk_size': _maxDiskCacheSize,
    };
  }

  /// Print cache statistics
  void printStats() {
    if (!kDebugMode) return;

    final stats = getStats();
    if (kDebugMode) print('\n╔════════════════════════════════════════╗');
    if (kDebugMode) print('║      📊 HTTP CACHE STATISTICS         ║');
    if (kDebugMode) print('╠════════════════════════════════════════╣');
    if (kDebugMode) print('║ Memory Cache: ${stats['memory_cache_size']}/${stats['max_memory_size']} items');
    if (kDebugMode) print('║ Disk Cache: ${stats['disk_cache_size']}/${stats['max_disk_size']} items');
    if (kDebugMode) print('╚════════════════════════════════════════╝\n');
  }
}

/// Internal cache entry class
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry({
    required this.data,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}
