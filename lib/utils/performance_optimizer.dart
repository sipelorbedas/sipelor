import 'package:flutter/foundation.dart';
import 'dart:async';

/// Enhanced Performance Optimizer
/// 
/// Provides utilities for monitoring and optimizing app performance.
/// Tracks critical metrics and provides optimization recommendations.
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // Performance metrics storage
  final Map<String, List<Duration>> _operationDurations = {};
  final Map<String, int> _operationCounts = {};
  
  // Thresholds for warnings
  static const Duration _slowOperationThreshold = Duration(milliseconds: 500);
  static const Duration _verySlowOperationThreshold = Duration(seconds: 2);
  static const int _frequentOperationThreshold = 100;

  /// Measure the duration of an operation
  Future<T> measureOperation<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    if (!kDebugMode) {
      // In production, just run the operation
      return await operation();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = await operation();
      stopwatch.stop();
      
      _recordDuration(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordDuration(operationName, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Measure synchronous operation
  T measureSync<T>(
    String operationName,
    T Function() operation,
  ) {
    if (!kDebugMode) {
      return operation();
    }

    final stopwatch = Stopwatch()..start();
    try {
      final result = operation();
      stopwatch.stop();
      
      _recordDuration(operationName, stopwatch.elapsed);
      
      return result;
    } catch (e) {
      stopwatch.stop();
      _recordDuration(operationName, stopwatch.elapsed);
      rethrow;
    }
  }

  /// Record operation duration
  void _recordDuration(String operationName, Duration duration) {
    // Store duration
    _operationDurations.putIfAbsent(operationName, () => []);
    _operationDurations[operationName]!.add(duration);

    // Increment count
    _operationCounts[operationName] = (_operationCounts[operationName] ?? 0) + 1;

    // Log slow operations
    if (duration > _verySlowOperationThreshold) {
      debugPrint('🔴 [Performance] VERY SLOW: $operationName took ${duration.inMilliseconds}ms');
    } else if (duration > _slowOperationThreshold) {
      debugPrint('🟡 [Performance] SLOW: $operationName took ${duration.inMilliseconds}ms');
    }

    // Warn about frequent operations
    final count = _operationCounts[operationName]!;
    if (count == _frequentOperationThreshold) {
      debugPrint('⚠️  [Performance] FREQUENT: $operationName called $count times');
    }
  }

  /// Get performance statistics for an operation
  Map<String, dynamic>? getStats(String operationName) {
    final durations = _operationDurations[operationName];
    if (durations == null || durations.isEmpty) {
      return null;
    }

    final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    final avgMs = totalMs / durations.length;
    final maxMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a > b ? a : b);
    final minMs = durations.map((d) => d.inMilliseconds).reduce((a, b) => a < b ? a : b);
    final count = _operationCounts[operationName] ?? 0;

    return {
      'operation': operationName,
      'count': count,
      'avg_ms': avgMs.toStringAsFixed(2),
      'max_ms': maxMs,
      'min_ms': minMs,
      'total_ms': totalMs,
    };
  }

  /// Get all performance statistics
  Map<String, Map<String, dynamic>> getAllStats() {
    final stats = <String, Map<String, dynamic>>{};
    
    for (final operationName in _operationDurations.keys) {
      final operationStats = getStats(operationName);
      if (operationStats != null) {
        stats[operationName] = operationStats;
      }
    }

    return stats;
  }

  /// Print performance report
  void printReport() {
    if (!kDebugMode) return;

    final stats = getAllStats();
    if (stats.isEmpty) {
      debugPrint('📊 [Performance] No operations recorded');
      return;
    }

    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════════╗');
    debugPrint('║              📊 PERFORMANCE REPORT                        ║');
    debugPrint('╠════════════════════════════════════════════════════════════╣');
    
    // Sort by average duration (slowest first)
    final sortedStats = stats.entries.toList()
      ..sort((a, b) {
        final avgA = double.parse(a.value['avg_ms']);
        final avgB = double.parse(b.value['avg_ms']);
        return avgB.compareTo(avgA);
      });

    for (final entry in sortedStats) {
      final name = entry.key;
      final data = entry.value;
      debugPrint('║ ${_truncate(name, 30).padRight(30)} │ Count: ${data['count'].toString().padLeft(5)} │ Avg: ${data['avg_ms'].toString().padLeft(8)}ms ║');
    }
    
    debugPrint('╚════════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Get optimization recommendations
  List<String> getRecommendations() {
    final recommendations = <String>[];
    final stats = getAllStats();

    for (final entry in stats.entries) {
      final name = entry.key;
      final data = entry.value;
      final avgMs = double.parse(data['avg_ms']);
      final count = data['count'] as int;

      // Check for slow operations
      if (avgMs > _verySlowOperationThreshold.inMilliseconds) {
        recommendations.add(
          'CRITICAL: $name is very slow (avg: ${avgMs.toStringAsFixed(0)}ms). Consider optimization or caching.',
        );
      } else if (avgMs > _slowOperationThreshold.inMilliseconds) {
        recommendations.add(
          'WARNING: $name is slow (avg: ${avgMs.toStringAsFixed(0)}ms). Consider optimization.',
        );
      }

      // Check for frequent operations
      if (count > _frequentOperationThreshold * 2) {
        recommendations.add(
          'INFO: $name is called very frequently ($count times). Consider caching or debouncing.',
        );
      }
    }

    return recommendations;
  }

  /// Print optimization recommendations
  void printRecommendations() {
    if (!kDebugMode) return;

    final recommendations = getRecommendations();
    if (recommendations.isEmpty) {
      debugPrint('✅ [Performance] No optimization recommendations');
      return;
    }

    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════════╗');
    debugPrint('║         💡 PERFORMANCE RECOMMENDATIONS                    ║');
    debugPrint('╠════════════════════════════════════════════════════════════╣');
    
    for (var i = 0; i < recommendations.length; i++) {
      final lines = _wrapText(recommendations[i], 56);
      for (var j = 0; j < lines.length; j++) {
        final prefix = j == 0 ? '${i + 1}. ' : '   ';
        debugPrint('║ $prefix${lines[j].padRight(56 - prefix.length)} ║');
      }
      if (i < recommendations.length - 1) {
        debugPrint('╟────────────────────────────────────────────────────────────╢');
      }
    }
    
    debugPrint('╚════════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Clear all recorded metrics
  void reset() {
    _operationDurations.clear();
    _operationCounts.clear();
    debugPrint('🔄 [Performance] Metrics reset');
  }

  // Helper methods
  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  List<String> _wrapText(String text, int maxWidth) {
    final lines = <String>[];
    var currentLine = '';
    
    for (final word in text.split(' ')) {
      if ((currentLine + word).length > maxWidth) {
        if (currentLine.isNotEmpty) {
          lines.add(currentLine.trim());
          currentLine = '';
        }
      }
      currentLine += '$word ';
    }
    
    if (currentLine.isNotEmpty) {
      lines.add(currentLine.trim());
    }
    
    return lines;
  }
}
