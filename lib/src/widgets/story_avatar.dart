import 'package:flutter/material.dart';

import 'stamp_identicon.dart';
import 'story_cached_image.dart';

/// Platform-default avatar patterns that are not user-uploaded content.
///
/// Matches web `resolveProfileAvatarUrl.ts`: these should fall back to Stamp
/// (via [StoryAvatar.userId]) / local identicon rather than being shown as
/// a custom photo.
const _platformDefaultPatterns = [
  'cdn.stamp.fyi/avatar/',
  'static-images.actqa.com/avatar_test.png',
  'static-images.actqa.com/default-avatar/',
];

/// Returns `true` if [url] is a platform-generated default avatar placeholder.
bool isPlatformDefaultAvatar(String? url) {
  if (url == null || url.isEmpty) return false;
  final lower = url.toLowerCase();
  return _platformDefaultPatterns.any(lower.contains);
}

/// Custom avatar URL after stripping empty / platform-default placeholders.
String? resolveCustomAvatarUrl(String? avatarUrl) {
  final raw = avatarUrl?.trim();
  if (raw == null || raw.isEmpty) return null;
  if (isPlatformDefaultAvatar(raw)) return null;
  return raw;
}

enum StoryAvatarShape { circle, rounded }

/// User/actor avatar aligned with web `UserProfileAvatar`:
/// custom URL → Stamp (`userId`) → local color-block collage.
///
/// While a network image loads, the placeholder is the same [StampIdenticon]
/// seed used for the terminal fallback — so the mosaic pattern does not
/// change mid-load. Callers should avoid mounting this widget with a missing
/// [userId] that later appears (that would still swap seeds); see the video
/// feed creator rail which waits for a stable identity first.
class StoryAvatar extends StatelessWidget {
  final String? imageUrl;

  /// Used to build Stamp CDN URL / local identicon seed (web `userId`).
  final String? userId;
  final String? fallbackText;
  final double size;
  final StoryAvatarShape shape;
  final Color? ringColor;
  final double ringWidth;

  const StoryAvatar({
    super.key,
    this.imageUrl,
    this.userId,
    this.fallbackText,
    this.size = 40,
    this.shape = StoryAvatarShape.circle,
    this.ringColor,
    this.ringWidth = 1.5,
  });

  String get _seed {
    final id = userId?.trim();
    if (id != null && id.isNotEmpty) return id;
    final text = fallbackText?.trim();
    if (text != null && text.isNotEmpty) return text;
    return 'story';
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = switch (shape) {
      StoryAvatarShape.circle => BorderRadius.circular(size / 2),
      StoryAvatarShape.rounded => BorderRadius.circular(size / 4),
    };

    final collage = StampIdenticon(
      seed: _seed,
      size: size,
      borderRadius: borderRadius,
    );

    final customUrl = resolveCustomAvatarUrl(imageUrl);
    final stampId = userId?.trim();
    final stampUrl = (stampId != null && stampId.isNotEmpty)
        ? stampAvatarUrl(stampId, logicalSize: size)
        : null;

    final Widget avatarWidget;
    if (customUrl != null) {
      avatarWidget = ClipRRect(
        borderRadius: borderRadius,
        child: StoryCachedImage(
          imageUrl: customUrl,
          width: size,
          height: size,
          memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
              .round(),
          placeholder: collage,
          errorWidget: stampUrl != null
              ? ClipRRect(
                  borderRadius: borderRadius,
                  child: StoryCachedImage(
                    imageUrl: stampUrl,
                    width: size,
                    height: size,
                    memCacheWidth:
                        (size * MediaQuery.devicePixelRatioOf(context)).round(),
                    placeholder: collage,
                    errorWidget: collage,
                  ),
                )
              : collage,
        ),
      );
    } else if (stampUrl != null) {
      avatarWidget = ClipRRect(
        borderRadius: borderRadius,
        child: StoryCachedImage(
          imageUrl: stampUrl,
          width: size,
          height: size,
          memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
              .round(),
          placeholder: collage,
          errorWidget: collage,
        ),
      );
    } else {
      avatarWidget = collage;
    }

    return Container(
      width: size,
      height: size,
      foregroundDecoration: BoxDecoration(
        borderRadius: borderRadius,
        border: ringColor != null
            ? Border.all(color: ringColor!, width: ringWidth)
            : null,
      ),
      child: avatarWidget,
    );
  }
}

class OverlappingAvatars extends StatelessWidget {
  final List<String> imageUrls;
  final double size;

  const OverlappingAvatars({
    super.key,
    required this.imageUrls,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: size,
      width: size + (imageUrls.length - 1) * (size * 0.6),
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(imageUrls.length, (index) {
          return Positioned(
            left: index * (size * 0.6),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).cardColor,
                  width: 1.5,
                ),
              ),
              child: StoryAvatar(imageUrl: imageUrls[index], size: size - 3),
            ),
          );
        }),
      ),
    );
  }
}
