import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Database Query Optimizer
///
/// Features:
/// - Query result caching
/// - Batch operations
/// - Optimized query patterns
/// - Cache invalidation
/// - Query performance tracking
///
/// Usage:
/// ```dart
/// // Use cached query
/// final venues = await DatabaseOptimizer.cachedQuery(
///   key: 'all_venues',
///   query: () => supabase.from('venues').select(),
///   duration: Duration(minutes: 5),
/// );
///
/// // Batch insert
/// await DatabaseOptimizer.batchInsert(
///   'bookings',
///   [booking1, booking2, booking3],
/// );
/// ```
class DatabaseOptimizer {
  static final Map<String, _CachedQuery> _queryCache = {};
  static final Map<String, Timer> _cacheTimers = {};

  /// Execute a cached query
  static Future<T> cachedQuery<T>({
    required String key,
    required Future<T> Function() query,
    Duration duration = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    // Check if cache exists and is valid
    if (!forceRefresh && _queryCache.containsKey(key)) {
      final cached = _queryCache[key]!;
      if (cached.isValid) {
        if (kDebugMode) {
          debugPrint('✅ Cache HIT: $key');
        }
        return cached.data as T;
      }
    }

    if (kDebugMode) {
      debugPrint('❌ Cache MISS: $key - Fetching from database');
    }

    // Execute query and cache result
    final stopwatch = Stopwatch()..start();
    final result = await query();
    stopwatch.stop();

    if (kDebugMode) {
      debugPrint('📊 Query $key took ${stopwatch.elapsed.inMilliseconds}ms');
    }

    // Store in cache
    _queryCache[key] = _CachedQuery(
      data: result,
      expiresAt: DateTime.now().add(duration),
    );

    // Set up cache invalidation timer
    _cacheTimers[key]?.cancel();
    _cacheTimers[key] = Timer(duration, () {
      _queryCache.remove(key);
      _cacheTimers.remove(key);
      if (kDebugMode) {
        debugPrint('🗑️  Cache expired: $key');
      }
    });

    return result;
  }

  /// Invalidate cache for a specific key
  static void invalidateCache(String key) {
    _queryCache.remove(key);
    _cacheTimers[key]?.cancel();
    _cacheTimers.remove(key);

    if (kDebugMode) {
      debugPrint('🗑️  Cache invalidated: $key');
    }
  }

  /// Invalidate cache with pattern matching
  static void invalidateCachePattern(String pattern) {
    final keysToRemove = _queryCache.keys
        .where((key) => key.contains(pattern))
        .toList();

    for (final key in keysToRemove) {
      invalidateCache(key);
    }

    if (kDebugMode) {
      debugPrint('🗑️  Cache invalidated (pattern: $pattern): $keysToRemove');
    }
  }

  /// Clear all cache
  static void clearCache() {
    _queryCache.clear();
    for (final timer in _cacheTimers.values) {
      timer.cancel();
    }
    _cacheTimers.clear();

    if (kDebugMode) {
      debugPrint('🗑️  All cache cleared');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'total_entries': _queryCache.length,
      'entries': _queryCache.keys.toList(),
      'memory_estimate': _estimateCacheSize(),
    };
  }

  /// Estimate cache size (rough estimate)
  static String _estimateCacheSize() {
    // This is a rough estimate
    final entries = _queryCache.length;
    final estimatedKB = entries * 10; // Assume 10KB per entry
    if (estimatedKB < 1024) {
      return '$estimatedKB KB';
    } else {
      return '${(estimatedKB / 1024).toStringAsFixed(2)} MB';
    }
  }

  /// Batch insert operation
  static Future<void> batchInsert(
    String table,
    List<Map<String, dynamic>> records, {
    int batchSize = 100,
  }) async {
    if (records.isEmpty) return;

    final supabase = Supabase.instance.client;
    final batches = <List<Map<String, dynamic>>>[];

    // Split into batches
    for (var i = 0; i < records.length; i += batchSize) {
      final end = (i + batchSize < records.length)
          ? i + batchSize
          : records.length;
      batches.add(records.sublist(i, end));
    }

    if (kDebugMode) {
      debugPrint('🔄 Batch inserting ${records.length} records into $table');
      debugPrint('   Split into ${batches.length} batches of $batchSize');
    }

    // Execute batches
    for (var i = 0; i < batches.length; i++) {
      final batch = batches[i];
      final stopwatch = Stopwatch()..start();

      await supabase.from(table).insert(batch);

      stopwatch.stop();
      if (kDebugMode) {
        debugPrint(
          '✅ Batch ${i + 1}/${batches.length} inserted '
          '(${stopwatch.elapsed.inMilliseconds}ms)',
        );
      }
    }
  }

  /// Batch update operation
  static Future<void> batchUpdate(
    String table,
    List<Map<String, dynamic>> records,
    String primaryKey, {
    int batchSize = 100,
  }) async {
    if (records.isEmpty) return;

    final supabase = Supabase.instance.client;

    if (kDebugMode) {
      debugPrint('🔄 Batch updating ${records.length} records in $table');
    }

    // Execute updates (Supabase doesn't support true batch updates,
    // so we do them sequentially but optimize with upsert)
    for (final record in records) {
      await supabase.from(table).upsert(record, onConflict: primaryKey);
    }

    if (kDebugMode) {
      debugPrint('✅ Batch update completed');
    }
  }

  /// Batch delete operation
  static Future<void> batchDelete(
    String table,
    String column,
    List<dynamic> values, {
    int batchSize = 100,
  }) async {
    if (values.isEmpty) return;

    final supabase = Supabase.instance.client;

    if (kDebugMode) {
      debugPrint('🔄 Batch deleting ${values.length} records from $table');
    }

    // Split into batches
    for (var i = 0; i < values.length; i += batchSize) {
      final end = (i + batchSize < values.length)
          ? i + batchSize
          : values.length;
      final batch = values.sublist(i, end);

      await supabase.from(table).delete().inFilter(column, batch);
    }

    if (kDebugMode) {
      debugPrint('✅ Batch delete completed');
    }
  }

  /// Optimized pagination query
  static Future<List<T>> paginatedQuery<T>({
    required String table,
    required T Function(Map<String, dynamic>) fromJson,
    String columns = '*',
    int page = 0,
    int pageSize = 20,
    String? orderBy,
    bool ascending = true,
    Map<String, dynamic>? filters,
  }) async {
    final supabase = Supabase.instance.client;

    dynamic query = supabase.from(table).select(columns);

    // Apply filters
    if (filters != null) {
      filters.forEach((key, value) {
        query = query.eq(key, value);
      });
    }

    // Apply ordering
    if (orderBy != null) {
      query = query.order(orderBy, ascending: ascending);
    }

    // Apply range for pagination
    query = query.range(page * pageSize, (page + 1) * pageSize - 1);

    final response = await query;
    return (response as List).map((item) => fromJson(item)).toList();
  }

  /// Count query with caching
  static Future<int> cachedCount({
    required String table,
    Map<String, dynamic>? filters,
    Duration cacheDuration = const Duration(minutes: 5),
  }) async {
    final filterKey = filters?.toString() ?? 'all';
    final cacheKey = 'count_${table}_$filterKey';

    return await cachedQuery(
      key: cacheKey,
      duration: cacheDuration,
      query: () async {
        final supabase = Supabase.instance.client;
        var query = supabase.from(table).select('*');

        // Apply filters
        if (filters != null) {
          filters.forEach((key, value) {
            query = query.eq(key, value);
          });
        }

        final response = await query.count(CountOption.exact);
        return response.count ?? 0;
      },
    );
  }

  /// Preload related data (similar to eager loading)
  static Future<List<Map<String, dynamic>>> queryWithRelations({
    required String table,
    required String columns,
    Map<String, dynamic>? filters,
  }) async {
    final supabase = Supabase.instance.client;
    var query = supabase.from(table).select(columns);

    // Apply filters
    if (filters != null) {
      for (final entry in filters.entries) {
        query = query.eq(entry.key, entry.value);
      }
    }

    return await query;
  }
}

/// Cached query model
class _CachedQuery {
  final dynamic data;
  final DateTime expiresAt;

  _CachedQuery({required this.data, required this.expiresAt});

  bool get isValid => DateTime.now().isBefore(expiresAt);
}

/// Query Builder Helper
class OptimizedQueryBuilder {
  final String table;
  final SupabaseClient _client;
  final List<String> _selectedColumns = ['*'];
  final Map<String, dynamic> _filters = {};
  String? _orderColumn;
  bool _ascending = true;
  int? _limit;
  int? _offset;

  OptimizedQueryBuilder(this.table) : _client = Supabase.instance.client;

  /// Select specific columns (reduces data transfer)
  OptimizedQueryBuilder select(List<String> columns) {
    _selectedColumns.clear();
    _selectedColumns.addAll(columns);
    return this;
  }

  /// Add filter
  OptimizedQueryBuilder where(String column, dynamic value) {
    _filters[column] = value;
    return this;
  }

  /// Add ordering
  OptimizedQueryBuilder orderBy(String column, {bool ascending = true}) {
    _orderColumn = column;
    _ascending = ascending;
    return this;
  }

  /// Add limit
  OptimizedQueryBuilder limit(int count) {
    _limit = count;
    return this;
  }

  /// Add offset
  OptimizedQueryBuilder offset(int count) {
    _offset = count;
    return this;
  }

  /// Execute query
  Future<List<Map<String, dynamic>>> execute() async {
    dynamic query = _client.from(table).select(_selectedColumns.join(','));

    // Apply filters
    _filters.forEach((key, value) {
      query = query.eq(key, value);
    });

    // Apply ordering
    if (_orderColumn != null) {
      query = query.order(_orderColumn!, ascending: _ascending);
    }

    // Apply limit
    if (_limit != null) {
      query = query.limit(_limit!);
    }

    // Apply offset
    if (_offset != null) {
      if (_limit != null) {
        query = query.range(_offset!, _offset! + _limit! - 1);
      }
    }

    final response = await query;
    return List<Map<String, dynamic>>.from(response as List);
  }
}
