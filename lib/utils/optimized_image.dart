import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Optimized Image Widget with consistent caching configuration
/// 
/// Features:
/// - Automatic image caching using cached_network_image
/// - Memory cache optimization
/// - Disk cache optimization
/// - Shimmer loading effect
/// - Error handling with fallback
/// - Support for fade-in animation
/// 
/// Usage:
/// ```dart
/// OptimizedImage(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 200,
///   height: 200,
///   fit: BoxFit.cover,
/// )
/// ```
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String? placeholder;
  final Duration fadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int maxCacheSize; // MB
  final Duration cacheValidDuration;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.memCacheWidth,
    this.memCacheHeight,
    this.maxCacheSize = 100, // 100MB default
    this.cacheValidDuration = const Duration(days: 7),
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: fadeInDuration,
      memCacheWidth: memCacheWidth ?? _calculateMemCacheSize(width),
      memCacheHeight: memCacheHeight ?? _calculateMemCacheSize(height),
      maxWidthDiskCache: 1024, // Max 1024px width for disk cache
      maxHeightDiskCache: 1024, // Max 1024px height for disk cache
      placeholder: (context, url) => _buildShimmerPlaceholder(context),
      errorWidget: (context, url, error) => _buildErrorWidget(context),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  /// Calculate optimal memory cache size based on display size
  /// This prevents loading full-resolution images into memory
  int? _calculateMemCacheSize(double? size) {
    if (size == null) return null;
    
    // Use 2x for retina displays, but cap at 1024px
    final cacheSize = (size * 2).toInt();
    return cacheSize > 1024 ? 1024 : cacheSize;
  }

  Widget _buildShimmerPlaceholder(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
        child: placeholder != null
            ? Center(
                child: Icon(
                  Icons.image,
                  color: Colors.grey[400],
                  size: 40,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            color: Colors.grey[400],
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Optimized Avatar Image with circular clipping
class OptimizedAvatar extends StatelessWidget {
  final String imageUrl;
  final double radius;
  final String? fallbackText;

  const OptimizedAvatar({
    super.key,
    required this.imageUrl,
    this.radius = 20,
    this.fallbackText,
  });

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[200],
      child: ClipOval(
        child: OptimizedImage(
          imageUrl: imageUrl,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          memCacheWidth: (radius * 4).toInt(), // 2x for retina
          memCacheHeight: (radius * 4).toInt(),
        ),
      ),
    );
  }
}

/// Image Cache Manager
/// Provides utilities to manage cached images
class ImageCacheManager {
  /// Clear all cached images
  static Future<void> clearCache() async {
    await CachedNetworkImage.evictFromCache('');
  }

  /// Clear specific image from cache
  static Future<void> clearImageCache(String url) async {
    await CachedNetworkImage.evictFromCache(url);
  }

  /// Preload images for better performance
  /// Call this before navigating to screens with images
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      } catch (e) {
        debugPrint('Failed to preload image: $url - $e');
      }
    }
  }

  /// Get cache size (approximate)
  /// Note: CachedNetworkImage doesn't provide direct API for this
  /// You may need to implement custom cache manager for accurate size
  static Future<String> getCacheSize() async {
    // This is a placeholder - implement with actual cache directory check
    return 'N/A';
  }
}

/// Image Quality Presets
class ImageQuality {
  /// Low quality for thumbnails and lists (faster loading, less memory)
  static const thumbnail = _ImageQualityConfig(
    memCacheWidth: 200,
    memCacheHeight: 200,
    maxDiskWidth: 400,
    maxDiskHeight: 400,
  );

  /// Medium quality for cards and previews
  static const medium = _ImageQualityConfig(
    memCacheWidth: 400,
    memCacheHeight: 400,
    maxDiskWidth: 800,
    maxDiskHeight: 800,
  );

  /// High quality for detail views
  static const high = _ImageQualityConfig(
    memCacheWidth: 800,
    memCacheHeight: 800,
    maxDiskWidth: 1024,
    maxDiskHeight: 1024,
  );
}

class _ImageQualityConfig {
  final int memCacheWidth;
  final int memCacheHeight;
  final int maxDiskWidth;
  final int maxDiskHeight;

  const _ImageQualityConfig({
    required this.memCacheWidth,
    required this.memCacheHeight,
    required this.maxDiskWidth,
    required this.maxDiskHeight,
  });
}
