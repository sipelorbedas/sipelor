import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Memory Leak Detector
///
/// Features:
/// - Track widget lifecycles
/// - Detect undisposed resources
/// - Monitor StreamControllers
/// - Monitor ChangeNotifiers
/// - Alert on potential leaks
///
/// Usage:
/// ```dart
/// // Track a disposable resource
/// MemoryLeakDetector.trackDisposable('my_controller', myController);
///
/// // In dispose:
/// @override
/// void dispose() {
///   MemoryLeakDetector.markDisposed('my_controller');
///   myController.dispose();
///   super.dispose();
/// }
///
/// // Or use mixin:
/// class MyWidget extends StatefulWidget with MemoryLeakDetectionMixin {
///   // Your widget code
/// }
/// ```
class MemoryLeakDetector {
  static final Map<String, _TrackedResource> _trackedResources = {};
  static Timer? _checkTimer;
  static bool _isInitialized = false;

  /// Initialize memory leak detector
  static void initialize({
    Duration checkInterval = const Duration(seconds: 60),
  }) {
    if (_isInitialized) return;
    _isInitialized = true;

    if (kDebugMode) {
      debugPrint('🔍 Memory Leak Detector initialized');

      _checkTimer = Timer.periodic(checkInterval, (_) {
        _checkForLeaks();
      });
    }
  }

  /// Dispose memory leak detector
  static void dispose() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _trackedResources.clear();
    _isInitialized = false;
  }

  /// Track a disposable resource
  static void trackDisposable(
    String id,
    dynamic resource, {
    String? description,
  }) {
    if (!kDebugMode) return;

    _trackedResources[id] = _TrackedResource(
      id: id,
      resource: resource,
      description: description,
      createdAt: DateTime.now(),
      type: _getResourceType(resource),
    );

    debugPrint('📍 Tracking: $id (${_getResourceType(resource)})');
  }

  /// Mark a resource as disposed
  static void markDisposed(String id) {
    if (!kDebugMode) return;

    if (_trackedResources.containsKey(id)) {
      final resource = _trackedResources[id]!;
      final lifetime = DateTime.now().difference(resource.createdAt);

      _trackedResources.remove(id);

      debugPrint('✅ Disposed: $id (lifetime: ${lifetime.inSeconds}s)');
    }
  }

  /// Check for potential memory leaks
  static void _checkForLeaks() {
    if (!kDebugMode) return;

    final now = DateTime.now();
    final warnings = <String>[];

    for (final resource in _trackedResources.values) {
      final age = now.difference(resource.createdAt);

      // Warn if resource has been alive for more than 10 minutes
      if (age > const Duration(minutes: 10)) {
        warnings.add(
          '⚠️  Potential leak: ${resource.id} (${resource.type}) - '
          'Alive for ${age.inMinutes} minutes',
        );
      }
    }

    if (warnings.isNotEmpty) {
      debugPrint('\n${'=' * 60}');
      debugPrint('🚨 MEMORY LEAK WARNINGS');
      debugPrint('=' * 60);
      for (final warning in warnings) {
        debugPrint(warning);
      }
      debugPrint('=' * 60 + '\n');
    }
  }

  /// Get current tracked resources
  static List<Map<String, dynamic>> getTrackedResources() {
    return _trackedResources.values.map((r) {
      final age = DateTime.now().difference(r.createdAt);
      return {
        'id': r.id,
        'type': r.type,
        'description': r.description,
        'age_seconds': age.inSeconds,
        'created_at': r.createdAt.toIso8601String(),
      };
    }).toList();
  }

  /// Print memory report
  static void printReport() {
    if (!kDebugMode) return;

    debugPrint('\n${'=' * 60}');
    debugPrint('🔍 MEMORY LEAK DETECTOR REPORT');
    debugPrint('=' * 60);
    debugPrint('Total tracked resources: ${_trackedResources.length}');
    debugPrint('');

    if (_trackedResources.isEmpty) {
      debugPrint('✅ No tracked resources (all disposed properly)');
    } else {
      debugPrint('Active resources:');
      for (final resource in _trackedResources.values) {
        final age = DateTime.now().difference(resource.createdAt);
        debugPrint(
          '  - ${resource.id} (${resource.type}) - Age: ${age.inSeconds}s',
        );
      }
    }

    debugPrint('=' * 60 + '\n');
  }

  /// Get resource type name
  static String _getResourceType(dynamic resource) {
    if (resource is StreamController) return 'StreamController';
    if (resource is ChangeNotifier) return 'ChangeNotifier';
    if (resource is TextEditingController) return 'TextEditingController';
    if (resource is ScrollController) return 'ScrollController';
    if (resource is AnimationController) return 'AnimationController';
    if (resource is Timer) return 'Timer';
    return resource.runtimeType.toString();
  }
}

/// Tracked resource model
class _TrackedResource {
  final String id;
  final dynamic resource;
  final String? description;
  final DateTime createdAt;
  final String type;

  _TrackedResource({
    required this.id,
    required this.resource,
    required this.createdAt,
    required this.type,
    this.description,
  });
}

/// Mixin for automatic memory leak detection in StatefulWidgets
mixin MemoryLeakDetectionMixin<T extends StatefulWidget> on State<T> {
  final Map<String, dynamic> _trackedResources = {};
  late final String _widgetId;

  @override
  void initState() {
    super.initState();
    _widgetId = '${widget.runtimeType}_$hashCode';
    MemoryLeakDetector.trackDisposable(
      _widgetId,
      this,
      description: 'Widget instance',
    );
  }

  /// Track a resource for automatic disposal checking
  void trackResource(String name, dynamic resource) {
    final id = '${_widgetId}_$name';
    _trackedResources[name] = id;
    MemoryLeakDetector.trackDisposable(id, resource);
  }

  @override
  void dispose() {
    // Mark widget as disposed
    MemoryLeakDetector.markDisposed(_widgetId);

    // Check if all tracked resources were disposed
    for (final entry in _trackedResources.entries) {
      if (kDebugMode) {
        debugPrint(
          '⚠️  Resource "${entry.key}" in ${widget.runtimeType} '
          'may not have been disposed!',
        );
      }
    }

    super.dispose();
  }

  /// Mark a resource as disposed (call this in your dispose method)
  void disposeResource(String name) {
    final id = _trackedResources[name];
    if (id != null) {
      MemoryLeakDetector.markDisposed(id);
      _trackedResources.remove(name);
    }
  }
}

/// Disposable Resource Manager
/// Helper to manage multiple disposable resources
class DisposableResourceManager {
  final Map<String, dynamic> _resources = {};
  bool _isDisposed = false;

  /// Add a resource to manage
  void add(String name, dynamic resource) {
    if (_isDisposed) {
      throw StateError('Cannot add resources after disposal');
    }
    _resources[name] = resource;
    MemoryLeakDetector.trackDisposable(name, resource);
  }

  /// Get a resource by name
  T? get<T>(String name) {
    return _resources[name] as T?;
  }

  /// Dispose all managed resources
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final entry in _resources.entries) {
      try {
        final resource = entry.value;

        // Dispose based on type
        if (resource is ChangeNotifier) {
          resource.dispose();
        } else if (resource is StreamController) {
          resource.close();
        } else if (resource is TextEditingController) {
          resource.dispose();
        } else if (resource is ScrollController) {
          resource.dispose();
        } else if (resource is AnimationController) {
          resource.dispose();
        } else if (resource is Timer) {
          resource.cancel();
        }

        MemoryLeakDetector.markDisposed(entry.key);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error disposing ${entry.key}: $e');
        }
      }
    }

    _resources.clear();
  }
}

/// Stream Subscription Manager
/// Helps manage multiple stream subscriptions
class StreamSubscriptionManager {
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;

  /// Add a subscription to manage
  void add(StreamSubscription subscription) {
    if (_isDisposed) {
      throw StateError('Cannot add subscriptions after disposal');
    }
    _subscriptions.add(subscription);
  }

  /// Cancel all subscriptions
  Future<void> dispose() async {
    if (_isDisposed) return;
    _isDisposed = true;

    for (final subscription in _subscriptions) {
      try {
        await subscription.cancel();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error canceling subscription: $e');
        }
      }
    }

    _subscriptions.clear();
  }

  /// Get number of active subscriptions
  int get count => _subscriptions.length;
}

/// Auto-disposing StreamController
/// Automatically tracks and warns about undisposed controllers
class TrackedStreamController<T> {
  final String id;
  final StreamController<T> _controller;

  TrackedStreamController({
    required this.id,
    bool sync = false,
    void Function()? onListen,
    void Function()? onCancel,
  }) : _controller = StreamController<T>(
          sync: sync,
          onListen: onListen,
          onCancel: onCancel,
        ) {
    MemoryLeakDetector.trackDisposable(id, this);
  }

  Stream<T> get stream => _controller.stream;
  StreamSink<T> get sink => _controller.sink;
  bool get isClosed => _controller.isClosed;
  bool get hasListener => _controller.hasListener;

  void add(T event) => _controller.add(event);
  void addError(Object error, [StackTrace? stackTrace]) =>
      _controller.addError(error, stackTrace);

  Future<void> close() {
    MemoryLeakDetector.markDisposed(id);
    return _controller.close();
  }
}

/// Auto-disposing ChangeNotifier
/// Automatically tracks and warns about undisposed notifiers
class TrackedChangeNotifier extends ChangeNotifier {
  final String id;

  TrackedChangeNotifier(this.id) {
    MemoryLeakDetector.trackDisposable(id, this);
  }

  @override
  void dispose() {
    MemoryLeakDetector.markDisposed(id);
    super.dispose();
  }
}
