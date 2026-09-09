import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Network image with memory-cache sizing tuned for list/grid layouts.
class StoryCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Map<String, String>? httpHeaders;
  final Widget? placeholder;
  final Widget? errorWidget;

  const StoryCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.httpHeaders,
    this.placeholder,
    this.errorWidget,
  });

  /// Derive [memCacheWidth] from logical width and device pixel ratio.
  static int memCacheForLogicalWidth(
    BuildContext context,
    double logicalWidth,
  ) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return (logicalWidth * dpr).round();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: httpHeaders,
        width: width,
        height: height,
        fit: fit,
        alignment: alignment,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: placeholder == null ? null : (_, _) => placeholder!,
        errorWidget: errorWidget == null ? null : (_, _, _) => errorWidget!,
      ),
    );
  }
}
