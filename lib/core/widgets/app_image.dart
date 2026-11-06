import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/shimmer.dart';

/// The single reusable image widget for the whole app — "ImageCase".
///
/// Handles all cases any property/agent/area image needs:
///   - a network URL (cached aggressively, with shimmer placeholder while it loads)
///   - a local asset path (with a graceful fallback if it's missing)
///   - fallback icon if URL is missing or fails to load
///
/// Optimized with:
///   - [memCacheWidth] & [memCacheHeight] to prevent memory bloat and scroll stutter
///   - Shimmer skeleton loading placeholder matching image dimensions
///   - Smooth fade-in transitions
class ImageCase extends StatelessWidget {
  const ImageCase({
    super.key,
    this.url,
    this.assetPath,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.home_work_rounded,
    this.borderRadius,
    this.backgroundColor = const Color(0xFFF1F6F8),
    this.iconColor = const Color(0xFF007A5E),
  });

  /// Network image URL. Takes priority over [assetPath] when both are set.
  final String? url;

  /// Local asset path, used when [url] is null/empty.
  final String? assetPath;

  final double width;
  final double height;
  final BoxFit fit;

  /// Shown when there's no image, or the image fails to load.
  final IconData fallbackIcon;

  /// Rounds the corners of the whole widget.
  final BorderRadius? borderRadius;

  final Color backgroundColor;
  final Color iconColor;

  /// Sanitizes and resolves any image URL (handles relative paths, backslashes,
  /// protocol-relative URLs, and invalid values like 'null').
  static String? sanitizeUrl(String? raw) {
    if (raw == null) return null;
    var s = raw.trim();
    if (s.isEmpty || s.toLowerCase() == 'null' || s.toLowerCase() == 'undefined') {
      return null;
    }
    s = s.replaceAll(r'\', '/');
    if (s.startsWith('//')) {
      s = 'https:$s';
    } else if (!s.startsWith('http://') && !s.startsWith('https://')) {
      if (s.startsWith('/')) {
        s = 'https://api.diginiwas.com$s';
      } else {
        s = 'https://api.diginiwas.com/$s';
      }
    } else if (s.startsWith('http://')) {
      s = s.replaceFirst('http://', 'https://');
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    Widget image;
    final resolvedUrl = sanitizeUrl(url);

    if (resolvedUrl != null && resolvedUrl.isNotEmpty) {
      final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 2.0;
      final targetMemWidth = (width.isFinite && width > 0)
          ? (width * dpr).round().clamp(100, 1080)
          : null;
      final targetMemHeight = (height.isFinite && height > 0)
          ? (height * dpr).round().clamp(100, 1080)
          : null;

      image = CachedNetworkImage(
        imageUrl: resolvedUrl,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: targetMemWidth,
        memCacheHeight: targetMemHeight,
        maxWidthDiskCache: 1200,
        maxHeightDiskCache: 1200,
        fadeInDuration: const Duration(milliseconds: 250),
        fadeOutDuration: const Duration(milliseconds: 150),
        placeholder: (context, _) => _placeholder(),
        errorWidget: (context, _, __) => _defaultEmptyBox(),
      );
    } else if (assetPath != null && assetPath!.trim().isNotEmpty) {
      image = Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: width.isFinite ? (width * 2).round().clamp(100, 1080) : null,
        cacheHeight: height.isFinite ? (height * 2).round().clamp(100, 1080) : null,
        errorBuilder: (context, error, stackTrace) => _defaultEmptyBox(),
      );
    } else {
      image = _defaultEmptyBox();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }

  Widget _placeholder() {
    final radiusVal = borderRadius != null ? borderRadius!.topLeft.x : 0.0;
    return ShimmerWidget(
      child: ShimmerBox(
        width: width,
        height: height,
        borderRadius: radiusVal,
        color: backgroundColor,
      ),
    );
  }

  Widget _defaultEmptyBox() {
    return Container(
      width: width,
      height: height,
      color: backgroundColor,
      alignment: Alignment.center,
      child: Icon(
        fallbackIcon,
        color: iconColor.withValues(alpha: 0.6),
        size: (height * 0.22).clamp(18, 44).toDouble(),
      ),
    );
  }
}
