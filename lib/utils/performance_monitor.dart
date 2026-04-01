import 'dart:async';
import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance Monitor for tracking app performance metrics
///
/// Features:
/// - Memory usage tracking
/// - Frame rendering performance
/// - Widget build time measurement
/// - Route transition tracking
/// - Performance logs and alerts
///
/// Usage:
/// ```dart
/// // Initialize in main()
/// PerformanceMonitor.initialize();
///
/// // Track specific operations
/// final stopwatch = PerformanceMonitor.startTimer('fetch_venues');
/// await fetchVenues();
/// PerformanceMonitor.stopTimer(stopwatch, 'fetch_venues');
///
/// // Track widget builds
/// @override
/// Widget build(BuildContext context) {
///   return PerformanceMonitor.trackBuild(
///     'VenueCard',
///     () => YourWidget(),
///   );
/// }
/// ```
class PerformanceMonitor {
  static bool _isInitialized = false;
  static final Map<String, List<Duration>> _performanceMetrics = {};
  static Timer? _memoryCheckTimer;

  /// Initialize performance monitoring
  static void initialize({
    bool enableMemoryTracking = true,
    Duration memoryCheckInterval = const Duration(seconds: 30),
  }) {
    if (_isInitialized) return;

    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🎯 Performance Monitor initialized');

      // Track memory periodically in debug mode
      if (enableMemoryTracking) {
        _memoryCheckTimer = Timer.periodic(memoryCheckInterval, (_) {
          _checkMemoryUsage();
        });
      }

      // Track frame rendering
      if (WidgetsBinding.instance.platformDispatcher.onReportTimings != null) {
        WidgetsBinding.instance.addTimingsCallback(_onFrameRendered);
      }
    }
  }

  /// Dispose performance monitor
  static void dispose() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
    _performanceMetrics.clear();
    _isInitialized = false;
  }

  /// Start a performance timer
  static Stopwatch startTimer(String label) {
    final stopwatch = Stopwatch()..start();
    return stopwatch;
  }

  /// Stop a performance timer and log the duration
  static void stopTimer(Stopwatch stopwatch, String label) {
    stopwatch.stop();
    _recordMetric(label, stopwatch.elapsed);

    if (kDebugMode) {
      final duration = stopwatch.elapsed;
      final threshold = const Duration(milliseconds: 500);

      if (duration > threshold) {
        debugPrint('⚠️  SLOW: $label took ${duration.inMilliseconds}ms');
      } else {
        debugPrint('✅ $label took ${duration.inMilliseconds}ms');
      }
    }
  }

  /// Track widget build performance
  static Widget trackBuild(String widgetName, Widget Function() builder) {
    if (!kDebugMode) {
      return builder();
    }

    final stopwatch = Stopwatch()..start();
    final widget = builder();
    stopwatch.stop();

    _recordMetric('build_$widgetName', stopwatch.elapsed);

    if (stopwatch.elapsed > const Duration(milliseconds: 16)) {
      debugPrint(
        '⚠️  SLOW BUILD: $widgetName took ${stopwatch.elapsed.inMilliseconds}ms',
      );
    }

    return widget;
  }

  /// Track async operations
  static Future<T> trackAsync<T>(
    String operationName,
    Future<T> Function() operation,
  ) async {
    final stopwatch = startTimer(operationName);
    try {
      final result = await operation();
      stopTimer(stopwatch, operationName);
      return result;
    } catch (e) {
      stopTimer(stopwatch, '$operationName (ERROR)');
      rethrow;
    }
  }

  /// Record a performance metric
  static void _recordMetric(String label, Duration duration) {
    _performanceMetrics.putIfAbsent(label, () => []);
    _performanceMetrics[label]!.add(duration);

    // Keep only last 100 measurements
    if (_performanceMetrics[label]!.length > 100) {
      _performanceMetrics[label]!.removeAt(0);
    }
  }

  /// Get average duration for a metric
  static Duration? getAverageDuration(String label) {
    final metrics = _performanceMetrics[label];
    if (metrics == null || metrics.isEmpty) return null;

    final totalMicroseconds = metrics.fold<int>(
      0,
      (sum, d) => sum + d.inMicroseconds,
    );
    return Duration(microseconds: totalMicroseconds ~/ metrics.length);
  }

  /// Get all metrics summary
  static Map<String, Map<String, dynamic>> getMetricsSummary() {
    final summary = <String, Map<String, dynamic>>{};

    for (final entry in _performanceMetrics.entries) {
      final metrics = entry.value;
      if (metrics.isEmpty) continue;

      final durations = metrics.map((d) => d.inMilliseconds).toList()..sort();
      final count = durations.length;

      summary[entry.key] = {
        'count': count,
        'avg': durations.reduce((a, b) => a + b) / count,
        'min': durations.first,
        'max': durations.last,
        'p50': durations[count ~/ 2],
        'p95': durations[(count * 0.95).floor()],
        'p99': durations[(count * 0.99).floor()],
      };
    }

    return summary;
  }

  /// Print performance report
  static void printReport() {
    if (!kDebugMode) return;

    debugPrint('\n${'=' * 60}');
    debugPrint('📊 PERFORMANCE REPORT');
    debugPrint('=' * 60);

    final summary = getMetricsSummary();

    if (summary.isEmpty) {
      debugPrint('No performance data collected yet.');
      return;
    }

    for (final entry in summary.entries) {
      debugPrint('\n${entry.key}:');
      debugPrint('  Count: ${entry.value['count']}');
      debugPrint('  Avg: ${entry.value['avg'].toStringAsFixed(2)}ms');
      debugPrint('  Min: ${entry.value['min']}ms');
      debugPrint('  Max: ${entry.value['max']}ms');
      debugPrint('  P50: ${entry.value['p50']}ms');
      debugPrint('  P95: ${entry.value['p95']}ms');
      debugPrint('  P99: ${entry.value['p99']}ms');
    }

    debugPrint('\n${'=' * 60}\n');
  }

  /// Check memory usage
  static void _checkMemoryUsage() {
    if (!kDebugMode) return;

    developer.Timeline.startSync('PerformanceMonitor.checkMemory');

    // Note: Detailed memory profiling requires DevTools
    // This is a placeholder for memory tracking
    debugPrint('💾 Memory check performed at ${DateTime.now()}');

    developer.Timeline.finishSync();
  }

  /// Callback when frames are rendered
  static void _onFrameRendered(List<FrameTiming> timings) {
    if (!kDebugMode) return;

    for (final timing in timings) {
      final buildDuration = timing.buildDuration;
      final rasterDuration = timing.rasterDuration;
      final totalDuration = buildDuration + rasterDuration;

      // 16ms = 60fps, 8ms = 120fps
      if (totalDuration > const Duration(milliseconds: 16)) {
        debugPrint(
          '⚠️  FRAME DROP: Build: ${buildDuration.inMilliseconds}ms, '
          'Raster: ${rasterDuration.inMilliseconds}ms',
        );
      }
    }
  }

  /// Log a performance marker
  static void logMarker(String message) {
    if (kDebugMode) {
      developer.Timeline.instantSync(message);
      debugPrint('📍 $message');
    }
  }

  /// Start a timeline event
  static void startTimelineEvent(String name) {
    if (kDebugMode) {
      developer.Timeline.startSync(name);
    }
  }

  /// Finish a timeline event
  static void finishTimelineEvent() {
    if (kDebugMode) {
      developer.Timeline.finishSync();
    }
  }
}

/// Performance Overlay Widget
/// Shows real-time performance metrics
class PerformanceOverlay extends StatefulWidget {
  final Widget child;
  final bool showOverlay;

  const PerformanceOverlay({
    super.key,
    required this.child,
    this.showOverlay = false,
  });

  @override
  State<PerformanceOverlay> createState() => _PerformanceOverlayState();
}

class _PerformanceOverlayState extends State<PerformanceOverlay> {
  Timer? _updateTimer;
  Map<String, Map<String, dynamic>> _metrics = {};

  @override
  void initState() {
    super.initState();
    if (widget.showOverlay && kDebugMode) {
      _updateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (mounted) {
          setState(() {
            _metrics = PerformanceMonitor.getMetricsSummary();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (widget.showOverlay && kDebugMode)
          Positioned(
            top: 100,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black.withOpacity(0.7),
              constraints: const BoxConstraints(maxWidth: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📊 Performance',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_metrics.isEmpty)
                    const Text(
                      'No data yet...',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    )
                  else
                    ..._metrics.entries
                        .take(5)
                        .map(
                          (e) => Text(
                            '${e.key}: ${e.value['avg'].toStringAsFixed(0)}ms',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin for tracking widget lifecycle performance
mixin PerformanceTrackingMixin<T extends StatefulWidget> on State<T> {
  String get performanceLabel => runtimeType.toString();

  @override
  void initState() {
    super.initState();
    PerformanceMonitor.logMarker('$performanceLabel.initState');
  }

  /// FIX: Build sekarang properly mengukur durasi dengan stopTimer setelah buildWithTracking()
  /// Sebelumnya: startTimer dipanggil tapi stopTimer tidak pernah dipanggil (timer orphan).
  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return buildWithTracking(context);

    final stopwatch = PerformanceMonitor.startTimer('build_$performanceLabel');
    final widget = buildWithTracking(context);
    PerformanceMonitor.stopTimer(stopwatch, 'build_$performanceLabel');
    return widget;
  }

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    PerformanceMonitor.logMarker('$performanceLabel.didUpdateWidget');
  }

  @override
  void dispose() {
    PerformanceMonitor.logMarker('$performanceLabel.dispose');
    super.dispose();
  }

  /// Override this instead of build()
  Widget buildWithTracking(BuildContext context);
}
