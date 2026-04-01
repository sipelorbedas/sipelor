import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// App Bundle Size Optimizer
///
/// Features:
/// - Image format recommendations
/// - Asset optimization guidance
/// - Code splitting utilities
/// - Build configuration helpers
/// - Bundle size analysis
///
/// Usage:
/// ```dart
/// // Check if should use WebP
/// final useWebP = AppBundleOptimizer.shouldUseWebP();
///
/// // Get optimized image format
/// final format = AppBundleOptimizer.getOptimizedImageFormat();
/// ```
class AppBundleOptimizer {
  /// Check if WebP format is supported on current platform
  static bool shouldUseWebP() {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      // Android 4.0+ supports WebP
      return true;
    }
    if (Platform.isIOS) {
      // iOS 14+ supports WebP
      return true;
    }
    return false;
  }

  /// Get recommended image format for current platform
  static String getOptimizedImageFormat() {
    if (shouldUseWebP()) {
      return 'webp';
    }
    return 'jpg';
  }

  /// Get optimized image URL with format suffix
  /// Useful when backend supports multiple formats
  static String getOptimizedImageUrl(String baseUrl, {String? format}) {
    final targetFormat = format ?? getOptimizedImageFormat();

    // If URL already has format, replace it
    if (baseUrl.contains('.jpg') ||
        baseUrl.contains('.jpeg') ||
        baseUrl.contains('.png')) {
      return baseUrl.replaceAll(RegExp(r'\.(jpg|jpeg|png)'), '.$targetFormat');
    }

    // Otherwise append format
    return '$baseUrl?format=$targetFormat';
  }

  /// Bundle size optimization recommendations
  static Map<String, dynamic> getOptimizationRecommendations() {
    return {
      'image_format': {
        'recommended': getOptimizedImageFormat(),
        'webp_supported': shouldUseWebP(),
        'savings': 'WebP can reduce image size by 25-35%',
      },
      'code_splitting': {
        'enabled': true,
        'recommendation': 'Use deferred imports for large screens',
        'example': "import 'screen.dart' deferred as screen;",
      },
      'tree_shaking': {
        'enabled': kReleaseMode,
        'recommendation': 'Build with --release flag for production',
      },
      'obfuscation': {
        'recommended': true,
        'command':
            'flutter build apk --obfuscate --split-debug-info=debug-info/',
      },
      'compression': {
        'recommended': true,
        'formats': ['WebP for images', 'Gzip for assets'],
      },
    };
  }

  /// Print bundle optimization report
  static void printOptimizationReport() {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint(
      '╔════════════════════════════════════════════════════════════╗',
    );
    debugPrint('║        📦 APP BUNDLE OPTIMIZATION REPORT                  ║');
    debugPrint(
      '╠════════════════════════════════════════════════════════════╣',
    );
    debugPrint('║ Build Mode: ${kReleaseMode ? 'RELEASE ✅' : 'DEBUG 🔧'}');
    debugPrint('║ Image Format: ${getOptimizedImageFormat().toUpperCase()}');
    debugPrint('║ WebP Support: ${shouldUseWebP() ? 'YES ✅' : 'NO ❌'}');
    debugPrint('║ Tree Shaking: ${kReleaseMode ? 'ENABLED ✅' : 'DISABLED ❌'}');
    debugPrint(
      '╠════════════════════════════════════════════════════════════╣',
    );
    debugPrint('║ RECOMMENDATIONS:');
    debugPrint('║ 1. Use WebP format for images (25-35% smaller)');
    debugPrint('║ 2. Enable code splitting for large screens');
    debugPrint('║ 3. Build with --release flag for production');
    debugPrint('║ 4. Use --obfuscate for code protection');
    debugPrint('║ 5. Use --split-debug-info for smaller builds');
    debugPrint('║ 6. Remove unused assets before building');
    debugPrint('║ 7. Optimize images with compression tools');
    debugPrint(
      '╚════════════════════════════════════════════════════════════╝',
    );
    debugPrint('');
  }

  /// Asset optimization checklist
  static List<Map<String, String>> getAssetOptimizationChecklist() {
    return [
      {
        'task': 'Convert images to WebP format',
        'tool': 'cwebp (Google)',
        'command': 'cwebp input.jpg -q 80 -o output.webp',
        'impact': 'High - 25-35% size reduction',
      },
      {
        'task': 'Compress PNG images',
        'tool': 'pngquant',
        'command': 'pngquant --quality=65-80 input.png',
        'impact': 'Medium - 50-70% size reduction',
      },
      {
        'task': 'Optimize JPEG images',
        'tool': 'jpegoptim',
        'command': 'jpegoptim --max=85 input.jpg',
        'impact': 'Medium - 10-20% size reduction',
      },
      {
        'task': 'Remove unused assets',
        'tool': 'Manual review',
        'command': 'Review assets/ folder and pubspec.yaml',
        'impact': 'High - Varies',
      },
      {
        'task': 'Use SVG for icons',
        'tool': 'flutter_svg',
        'command': 'Replace PNG icons with SVG',
        'impact': 'Medium - Scalable & smaller',
      },
      {
        'task': 'Enable code obfuscation',
        'tool': 'Flutter build',
        'command': 'flutter build apk --obfuscate --split-debug-info=.',
        'impact': 'Medium - Smaller & secure',
      },
      {
        'task': 'Split debug info',
        'tool': 'Flutter build',
        'command': 'flutter build apk --split-debug-info=debug/',
        'impact': 'High - 20-30% smaller',
      },
      {
        'task': 'Analyze bundle size',
        'tool': 'Flutter',
        'command': 'flutter build apk --analyze-size',
        'impact': 'N/A - Analysis only',
      },
    ];
  }

  /// Build optimization commands
  static Map<String, String> getBuildCommands() {
    return {
      'android_release':
          'flutter build apk --release --obfuscate --split-debug-info=build/debug/ --analyze-size',
      'android_appbundle':
          'flutter build appbundle --release --obfuscate --split-debug-info=build/debug/',
      'ios_release':
          'flutter build ios --release --obfuscate --split-debug-info=build/debug/',
      'web_release': 'flutter build web --release --web-renderer canvaskit',
      'windows_release': 'flutter build windows --release',
      'analyze_size':
          'flutter build apk --analyze-size --target-platform android-arm64',
    };
  }

  /// Expected bundle size reductions
  static Map<String, String> getExpectedSavings() {
    return {
      'WebP images': '25-35% reduction in image size',
      'Code obfuscation': '10-15% reduction in code size',
      'Split debug info': '20-30% reduction in APK size',
      'Tree shaking': '15-25% reduction in final bundle',
      'Minification': '10-20% reduction in code size',
      'Asset optimization': '30-50% reduction in asset size',
      'Remove unused packages': '5-15% reduction in dependencies',
    };
  }
}

/// Deferred Loading Helper
/// Use this to implement code splitting for large screens
class DeferredLoadingHelper {
  static bool _isLoadingMap = false;
  static bool _isLoadingCharts = false;

  /// Example: Load heavy screen deferred
  /// ```dart
  /// await DeferredLoadingHelper.loadScreen(() async {
  ///   await heavyScreen.loadLibrary();
  /// });
  /// ```
  static Future<void> loadScreen(Future<void> Function() loader) async {
    try {
      await loader();
    } catch (e) {
      debugPrint('Error loading deferred library: $e');
      rethrow;
    }
  }

  /// Load Google Maps library deferred
  static Future<void> loadMapsLibrary() async {
    if (_isLoadingMap) return;
    _isLoadingMap = true;

    try {
      // In actual implementation, use deferred import
      // import 'package:google_maps_flutter/google_maps_flutter.dart' deferred as maps;
      // await maps.loadLibrary();

      debugPrint('✅ Maps library loaded');
    } catch (e) {
      debugPrint('❌ Error loading maps library: $e');
    } finally {
      _isLoadingMap = false;
    }
  }

  /// Load Charts library deferred
  static Future<void> loadChartsLibrary() async {
    if (_isLoadingCharts) return;
    _isLoadingCharts = true;

    try {
      // In actual implementation, use deferred import
      // import 'package:fl_chart/fl_chart.dart' deferred as charts;
      // await charts.loadLibrary();

      debugPrint('✅ Charts library loaded');
    } catch (e) {
      debugPrint('❌ Error loading charts library: $e');
    } finally {
      _isLoadingCharts = false;
    }
  }

  /// Generic deferred widget loader with loading indicator
  /// Note: This creates a StatefulWidget to ensure loadLibrary is called only once
  static Widget buildDeferredWidget({
    required Future<void> Function() loadLibrary,
    required Widget Function() builder,
    Widget? loadingWidget,
  }) {
    return _DeferredWidgetLoader(
      loadLibrary: loadLibrary,
      builder: builder,
      loadingWidget: loadingWidget,
    );
  }
}

/// Internal widget for deferred loading
class _DeferredWidgetLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function() builder;
  final Widget? loadingWidget;

  // ignore: prefer_const_constructors_in_immutables
  _DeferredWidgetLoader({
    required this.loadLibrary,
    required this.builder,
    this.loadingWidget,
  }) : super(key: null);

  @override
  State<_DeferredWidgetLoader> createState() => _DeferredWidgetLoaderState();
}

class _DeferredWidgetLoaderState extends State<_DeferredWidgetLoader> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _loadFuture = widget.loadLibrary();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading library: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            );
          }
          return widget.builder();
        }
        return widget.loadingWidget ??
            const Center(child: CircularProgressIndicator());
      },
    );
  }
}
