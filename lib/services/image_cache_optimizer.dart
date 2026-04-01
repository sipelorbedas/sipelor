import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Image Cache Optimizer Service
///
/// Features:
/// - Optimized image caching configuration
/// - Memory-efficient image loading
/// - Progressive image loading
/// - Cache management
///
/// Usage:
/// ```dart
/// ImageCacheOptimizer.configure();
/// 
/// // Use optimized image widget
/// ImageCacheOptimizer.buildOptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
/// );
/// ```
class ImageCacheOptimizer {
  /// Configure global image cache settings
  static void configure() {
    // Configure Flutter's image cache
    PaintingBinding.instance.imageCache.maximumSize = 100; // Max number of images
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

    if (kDebugMode) {
      if (kDebugMode) print('✅ Image cache configured:');
      if (kDebugMode) print('   - Max images: 100');
      if (kDebugMode) print('   - Max size: 50 MB');
    }
  }

  /// Build optimized cached network image
  static Widget buildOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder != null
            ? (context, url) => placeholder
            : (context, url) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[200],
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        errorWidget: errorWidget != null
            ? (context, url, error) => errorWidget
            : (context, url, error) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                  ),
                ),
        // Performance optimizations
        memCacheWidth: width?.toInt(),
        memCacheHeight: height?.toInt(),
        maxWidthDiskCache: 1000,
        maxHeightDiskCache: 1000,
        fadeInDuration: const Duration(milliseconds: 200),
        fadeOutDuration: const Duration(milliseconds: 100),
      ),
    );
  }

  /// Build optimized image for thumbnails (smaller cache)
  static Widget buildThumbnail({
    required String imageUrl,
    double size = 80,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    return buildOptimizedImage(
      imageUrl: imageUrl,
      width: size,
      height: size,
      fit: fit,
      borderRadius: borderRadius,
    );
  }

  /// Build optimized full-size image
  static Widget buildFullImage({
    required String imageUrl,
    BoxFit fit = BoxFit.contain,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => const Center(
        child: Icon(Icons.error_outline, color: Colors.red, size: 48),
      ),
      // Don't resize for full images
      fadeInDuration: const Duration(milliseconds: 300),
    );
  }

  /// Clear image cache
  static Future<void> clearCache() async {
    // Clear Flutter's image cache
    PaintingBinding.instance.imageCache.clear();
    PaintingBinding.instance.imageCache.clearLiveImages();

    // Clear CachedNetworkImage cache
    await CachedNetworkImage.evictFromCache(null as String);

    if (kDebugMode) {
      if (kDebugMode) print('🗑️  Image cache cleared');
    }
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    final imageCache = PaintingBinding.instance.imageCache;
    
    return {
      'current_size': imageCache.currentSize,
      'current_size_bytes': imageCache.currentSizeBytes,
      'maximum_size': imageCache.maximumSize,
      'maximum_size_bytes': imageCache.maximumSizeBytes,
      'live_image_count': imageCache.liveImageCount,
      'pending_image_count': imageCache.pendingImageCount,
    };
  }

  /// Print cache statistics
  static void printStats() {
    if (!kDebugMode) return;

    final stats = getCacheStats();
    if (kDebugMode) print('\n╔════════════════════════════════════════╗');
    if (kDebugMode) print('║     🖼️  IMAGE CACHE STATISTICS        ║');
    if (kDebugMode) print('╠════════════════════════════════════════╣');
    if (kDebugMode) print('║ Images: ${stats['current_size']}/${stats['maximum_size']}');
    if (kDebugMode) print('║ Size: ${(stats['current_size_bytes'] / 1024 / 1024).toStringAsFixed(1)} MB / ${(stats['maximum_size_bytes'] / 1024 / 1024).toStringAsFixed(0)} MB');
    if (kDebugMode) print('║ Live Images: ${stats['live_image_count']}');
    if (kDebugMode) print('║ Pending: ${stats['pending_image_count']}');
    if (kDebugMode) print('╚════════════════════════════════════════╝\n');
  }
}
