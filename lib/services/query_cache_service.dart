import 'dart:async';
import 'package:flutter/foundation.dart';

/// Query Cache Service for Database Query Results
///
/// Features:
/// - In-memory caching of frequently accessed queries
/// - Automatic cache invalidation
/// - Query result deduplication
/// - Request batching
///
/// Usage:
/// ```dart
/// final cache = QueryCacheService();
///
/// // Cache query result
/// final venues = await cache.getOrFetch(
///   key: 'active_venues',
///   fetcher: () => supabase.from('fields').select().eq('status', 'available'),
///   ttl: Duration(minutes: 5),
/// );
///
/// // Invalidate cache
/// cache.invalidate('active_venues');
/// ```
class QueryCacheService {
  static final QueryCacheService _instance = QueryCacheService._internal();
  factory QueryCacheService() => _instance;
  QueryCacheService._internal();

  final Map<String, _QueryCacheEntry> _cache = {};
  final Map<String, List<Completer>> _pendingRequests = {};

  static const int _maxCacheSize = 50;
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// Get cached result or fetch new data
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration? ttl,
  }) async {
    // Check cache first
    if (_cache.containsKey(key)) {
      final entry = _cache[key]!;
      if (!entry.isExpired) {
        if (kDebugMode) {
          if (kDebugMode) print('💾 Query Cache HIT: $key');
        }
        return entry.data as T;
      } else {
        _cache.remove(key);
      }
    }

    // Check if same request is already pending (deduplication)
    if (_pendingRequests.containsKey(key)) {
      if (kDebugMode) {
        if (kDebugMode) print('⏳ Query Cache WAIT (dedup): $key');
      }
      final completer = Completer<T>();
      _pendingRequests[key]!.add(completer);
      return completer.future;
    }

    // Fetch new data
    if (kDebugMode) {
      if (kDebugMode) print('❌ Query Cache MISS: $key - Fetching...');
    }

    _pendingRequests[key] = [];

    try {
      final data = await fetcher();
      
      // Cache the result
      final expiry = DateTime.now().add(ttl ?? _defaultTTL);
      _cache[key] = _QueryCacheEntry(
        data: data,
        expiry: expiry,
      );

      // Limit cache size
      if (_cache.length > _maxCacheSize) {
        _evictOldest();
      }

      // Complete pending requests
      if (_pendingRequests.containsKey(key)) {
        for (final completer in _pendingRequests[key]!) {
          completer.complete(data);
        }
        _pendingRequests.remove(key);
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ Query Cache SET: $key (expires: ${expiry.toLocal()})');
      }

      return data;
    } catch (e) {
      // Fail all pending requests
      if (_pendingRequests.containsKey(key)) {
        for (final completer in _pendingRequests[key]!) {
          completer.completeError(e);
        }
        _pendingRequests.remove(key);
      }
      rethrow;
    }
  }

  /// Invalidate specific cache entry
  void invalidate(String key) {
    _cache.remove(key);
    if (kDebugMode) {
      if (kDebugMode) print('🗑️  Query Cache INVALIDATED: $key');
    }
  }

  /// Invalidate multiple cache entries by pattern
  void invalidateByPattern(String pattern) {
    final regex = RegExp(pattern);
    final keysToRemove = _cache.keys.where((key) => regex.hasMatch(key)).toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode && keysToRemove.isNotEmpty) {
      if (kDebugMode) print('🗑️  Query Cache INVALIDATED (pattern): $pattern - ${keysToRemove.length} entries');
    }
  }

  /// Clear all cached queries
  void clearAll() {
    _cache.clear();
    if (kDebugMode) {
      if (kDebugMode) print('🗑️  Query Cache CLEARED');
    }
  }

  /// Evict oldest cache entry
  void _evictOldest() {
    if (_cache.isEmpty) return;

    String? oldestKey;
    DateTime? earliestExpiry;

    for (final entry in _cache.entries) {
      if (oldestKey == null || entry.value.expiry.isBefore(earliestExpiry!)) {
        oldestKey = entry.key;
        earliestExpiry = entry.value.expiry;
      }
    }

    if (oldestKey != null) {
      _cache.remove(oldestKey);
      if (kDebugMode) {
        if (kDebugMode) print('🗑️  Query Cache EVICTED: $oldestKey');
      }
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expiredCount = 0;
    for (final entry in _cache.values) {
      if (entry.isExpired) expiredCount++;
    }

    return {
      'total_cached': _cache.length,
      'expired_count': expiredCount,
      'pending_requests': _pendingRequests.length,
      'max_size': _maxCacheSize,
    };
  }

  /// Print cache statistics
  void printStats() {
    if (!kDebugMode) return;

    final stats = getStats();
    if (kDebugMode) print('\n╔════════════════════════════════════════╗');
    if (kDebugMode) print('║     🔍 QUERY CACHE STATISTICS         ║');
    if (kDebugMode) print('╠════════════════════════════════════════╣');
    if (kDebugMode) print('║ Cached Queries: ${stats['total_cached']}/${stats['max_size']}');
    if (kDebugMode) print('║ Expired: ${stats['expired_count']}');
    if (kDebugMode) print('║ Pending Requests: ${stats['pending_requests']}');
    if (kDebugMode) print('╚════════════════════════════════════════╝\n');
  }
}

/// Internal cache entry
class _QueryCacheEntry {
  final dynamic data;
  final DateTime expiry;

  _QueryCacheEntry({
    required this.data,
    required this.expiry,
  });

  bool get isExpired => DateTime.now().isAfter(expiry);
}
