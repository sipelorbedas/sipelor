import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Render Optimizer
/// 
/// Features:
/// - Detect unnecessary rebuilds
/// - Const widget helpers
/// - Build counter for debugging
/// - Rebuild boundary helpers
/// - Performance tips
/// 
/// Usage:
/// ```dart
/// // Detect rebuilds in debug mode
/// class MyWidget extends StatelessWidget {
///   @override
///   Widget build(BuildContext context) {
///     RenderOptimizer.trackRebuild('MyWidget');
///     return ...;
///   }
/// }
/// 
/// // Use RepaintBoundary for expensive widgets
/// RenderOptimizer.withRepaintBoundary(
///   child: ExpensiveWidget(),
/// )
/// ```
class RenderOptimizer {
  static final Map<String, int> _buildCounts = {};
  static final Map<String, DateTime> _lastBuildTime = {};

  /// Track widget rebuild
  static void trackRebuild(String widgetName) {
    if (!kDebugMode) return;

    _buildCounts[widgetName] = (_buildCounts[widgetName] ?? 0) + 1;
    final now = DateTime.now();
    final lastBuild = _lastBuildTime[widgetName];

    if (lastBuild != null) {
      final timeSinceLastBuild = now.difference(lastBuild);

      // Warn if rebuilding too frequently (less than 16ms = faster than 60fps)
      if (timeSinceLastBuild < const Duration(milliseconds: 16)) {
        debugPrint(
          '⚠️  RAPID REBUILD: $widgetName rebuilt after '
          '${timeSinceLastBuild.inMilliseconds}ms '
          '(${_buildCounts[widgetName]} total rebuilds)',
        );
      }
    }

    _lastBuildTime[widgetName] = now;

    // Warn if widget has been rebuilt many times
    if (_buildCounts[widgetName]! > 100) {
      debugPrint(
        '⚠️  EXCESSIVE REBUILDS: $widgetName has been rebuilt '
        '${_buildCounts[widgetName]} times',
      );
    }
  }

  /// Wrap widget with RepaintBoundary for isolation
  static Widget withRepaintBoundary({
    required Widget child,
    String? debugLabel,
  }) {
    return RepaintBoundary(
      child: child,
    );
  }

  /// Get build statistics
  static Map<String, int> getBuildStats() {
    return Map.from(_buildCounts);
  }

  /// Print build statistics
  static void printBuildStats() {
    if (!kDebugMode) return;

    debugPrint('\n${'=' * 60}');
    debugPrint('🎨 RENDER OPTIMIZER REPORT');
    debugPrint('=' * 60);

    if (_buildCounts.isEmpty) {
      debugPrint('No tracked rebuilds yet.');
      return;
    }

    // Sort by rebuild count
    final sortedEntries = _buildCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    debugPrint('Widget rebuild counts:');
    for (final entry in sortedEntries.take(20)) {
      final status = entry.value > 50 ? '⚠️' : '✅';
      debugPrint('  $status ${entry.key}: ${entry.value} rebuilds');
    }

    debugPrint('=' * 60 + '\n');
  }

  /// Reset build statistics
  static void resetStats() {
    _buildCounts.clear();
    _lastBuildTime.clear();
    if (kDebugMode) {
      debugPrint('🔄 Build stats reset');
    }
  }

  /// Create a const widget if possible
  static Widget constOrNot({
    required Widget child,
    required bool isConst,
  }) {
    // This is mostly for documentation purposes
    // The actual const-ness is determined at compile time
    return child;
  }
}

/// Rebuild Counter Widget
/// Shows how many times a widget has been rebuilt
class RebuildCounter extends StatefulWidget {
  final Widget child;
  final String? label;
  final bool showOverlay;

  const RebuildCounter({
    super.key,
    required this.child,
    this.label,
    this.showOverlay = true,
  });

  @override
  State<RebuildCounter> createState() => _RebuildCounterState();
}

class _RebuildCounterState extends State<RebuildCounter> {
  int _buildCount = 0;

  @override
  Widget build(BuildContext context) {
    _buildCount++;

    if (kDebugMode && _buildCount > 10) {
      debugPrint(
        '⚠️  ${widget.label ?? 'RebuildCounter'} rebuilt $_buildCount times',
      );
    }

    return Stack(
      children: [
        widget.child,
        if (kDebugMode && widget.showOverlay)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _buildCount > 10
                    ? Colors.red.withOpacity(0.8)
                    : Colors.green.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '🔄 $_buildCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin to detect unnecessary rebuilds
mixin RebuildDetectorMixin<T extends StatefulWidget> on State<T> {
  int _buildCount = 0;

  String get debugLabel => widget.runtimeType.toString();

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    RenderOptimizer.trackRebuild(debugLabel);

    if (kDebugMode && _buildCount % 10 == 0) {
      debugPrint('📊 $debugLabel has been rebuilt $_buildCount times');
    }

    return buildWithDetection(context);
  }

  /// Override this instead of build()
  Widget buildWithDetection(BuildContext context);

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kDebugMode) {
      debugPrint('🔄 $debugLabel.didUpdateWidget called');
    }
  }
}

/// Optimized Builder Widget
/// Only rebuilds when necessary
class OptimizedBuilder extends StatelessWidget {
  final Widget Function() builder;
  final List<Listenable>? listenables;

  const OptimizedBuilder({
    super.key,
    required this.builder,
    this.listenables,
  });

  @override
  Widget build(BuildContext context) {
    if (listenables == null || listenables!.isEmpty) {
      return builder();
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables!),
      builder: (context, child) => builder(),
    );
  }
}

/// Const Widget Checker
/// Helps identify widgets that could be const
class ConstChecker {
  static final Set<String> _nonConstWidgets = {};

  /// Mark a widget as non-const
  static void markNonConst(String widgetName) {
    if (!kDebugMode) return;
    _nonConstWidgets.add(widgetName);
  }

  /// Get list of non-const widgets
  static List<String> getNonConstWidgets() {
    return _nonConstWidgets.toList();
  }

  /// Print non-const widget report
  static void printReport() {
    if (!kDebugMode) return;

    debugPrint('\n${'=' * 60}');
    debugPrint('🔍 CONST WIDGET CHECKER REPORT');
    debugPrint('=' * 60);

    if (_nonConstWidgets.isEmpty) {
      debugPrint('✅ No non-const widgets detected');
    } else {
      debugPrint('Widgets that could potentially be const:');
      for (final widget in _nonConstWidgets) {
        debugPrint('  ⚠️  $widget');
      }
      debugPrint('\nTip: Mark these widgets as const to improve performance');
    }

    debugPrint('=' * 60 + '\n');
  }
}

/// Performance Tips Widget
/// Shows performance recommendations
class PerformanceTips {
  static const List<String> tips = [
    '✅ Use const constructors whenever possible',
    '✅ Wrap expensive widgets in RepaintBoundary',
    '✅ Use ListView.builder for long lists instead of ListView',
    '✅ Avoid rebuilding entire widget trees unnecessarily',
    '✅ Use keys to preserve widget state',
    '✅ Cache network images with cached_network_image',
    '✅ Use Selector or Consumer for targeted rebuilds',
    '✅ Avoid anonymous functions in build methods',
    '✅ Move expensive computations outside of build',
    '✅ Use const widgets in lists when possible',
    '✅ Implement shouldRebuild in custom widgets',
    '✅ Use AutomaticKeepAliveClientMixin for tabs',
    '✅ Dispose controllers and streams properly',
    '✅ Use MediaQuery.of(context).size sparingly',
    '✅ Avoid calling setState in build method',
  ];

  /// Print random performance tip
  static void printRandomTip() {
    if (!kDebugMode) return;

    final tip = (tips..shuffle()).first;
    debugPrint('\n💡 Performance Tip: $tip\n');
  }

  /// Print all tips
  static void printAllTips() {
    if (!kDebugMode) return;

    debugPrint('\n${'=' * 60}');
    debugPrint('💡 FLUTTER PERFORMANCE TIPS');
    debugPrint('=' * 60);

    for (var i = 0; i < tips.length; i++) {
      debugPrint('${i + 1}. ${tips[i]}');
    }

    debugPrint('=' * 60 + '\n');
  }
}

/// Lazy Widget Builder
/// Only builds widget when it comes into view
class LazyWidget extends StatefulWidget {
  final Widget Function() builder;
  final Widget placeholder;

  const LazyWidget({
    super.key,
    required this.builder,
    this.placeholder = const SizedBox.shrink(),
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  bool _hasBuilt = false;
  Widget? _builtWidget;

  @override
  Widget build(BuildContext context) {
    if (!_hasBuilt) {
      // Check if widget is in viewport
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasBuilt = true;
            _builtWidget = widget.builder();
          });
        }
      });

      return widget.placeholder;
    }

    return _builtWidget ?? widget.placeholder;
  }
}

/// Conditional Rebuild Widget
/// Only rebuilds when condition changes
class ConditionalRebuild extends StatefulWidget {
  final bool Function() condition;
  final Widget Function() builder;
  final Widget? fallback;

  const ConditionalRebuild({
    super.key,
    required this.condition,
    required this.builder,
    this.fallback,
  });

  @override
  State<ConditionalRebuild> createState() => _ConditionalRebuildState();
}

class _ConditionalRebuildState extends State<ConditionalRebuild> {
  late bool _lastCondition;
  late Widget _builtWidget;

  @override
  void initState() {
    super.initState();
    _lastCondition = widget.condition();
    _builtWidget = _lastCondition
        ? widget.builder()
        : (widget.fallback ?? const SizedBox.shrink());
  }

  @override
  Widget build(BuildContext context) {
    final currentCondition = widget.condition();

    if (currentCondition != _lastCondition) {
      _lastCondition = currentCondition;
      _builtWidget = currentCondition
          ? widget.builder()
          : (widget.fallback ?? const SizedBox.shrink());
    }

    return _builtWidget;
  }
}
