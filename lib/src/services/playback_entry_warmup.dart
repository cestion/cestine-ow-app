import 'dart:async';

import '../core/story_constants.dart';
import '../core/video_url_helpers.dart';
import 'playback_frame_cache_service.dart';
import 'video_precache_service.dart';

/// Best-effort warmups before navigating into a full-screen feed.
class PlaybackEntryWarmup {
  PlaybackEntryWarmup._();

  /// Loads a cached JPEG (memory/disk) so the feed cover can paint instantly.
  ///
  /// When [episodeId] is known, also primes the legacy `drama_epN` key so
  /// older disk entries still hit after the shared `drama:episodeId` key.
  static void primeFrameCache({
    required String dramaId,
    required int episodeNo,
    String? episodeId,
  }) {
    final primary = PlaybackFrameCacheService.frameCacheKey(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
    );
    unawaited(PlaybackFrameCacheService.instance.get(primary));

    final ep = episodeId?.trim() ?? '';
    if (ep.isEmpty) return;
    final legacy = PlaybackFrameCacheService.frameCacheKey(
      dramaId: dramaId,
      episodeNo: episodeNo,
    );
    if (legacy.isNotEmpty && legacy != primary) {
      unawaited(PlaybackFrameCacheService.instance.get(legacy));
    }
  }

  /// Primes [episodeNo] ± [radius] (default from [StoryConstants]).
  ///
  /// Optional [episodeIdsByNo] supplies episodeIds so primary keys match the
  /// shared `drama:episodeId` format used by recommend + drama feeds.
  static void primeFrameCacheAround({
    required String dramaId,
    required int episodeNo,
    int? radius,
    Map<int, String?>? episodeIdsByNo,
  }) {
    final span = radius ?? StoryConstants.playbackFramePrimeRadius;
    if (episodeNo < 1 || span < 0) return;
    for (var ep = episodeNo - span; ep <= episodeNo + span; ep++) {
      if (ep < 1) continue;
      primeFrameCache(
        dramaId: dramaId,
        episodeNo: ep,
        episodeId: episodeIdsByNo?[ep],
      );
    }
  }

  /// True when [VideoPrecacheService] recently warmed [url] on disk.
  static bool isPlayUrlDiskWarmed(String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return false;
    if (!VideoUrlHelpers.isHttpUrl(trimmed)) return false;
    return VideoPrecacheService.instance.isFreshlyWarmed(trimmed);
  }
}
