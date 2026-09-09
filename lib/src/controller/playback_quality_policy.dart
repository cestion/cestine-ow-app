import 'package:better_native_video_player/better_native_video_player.dart';

import '../core/story_constants.dart';

/// Pure helpers for HLS ABR height caps (hard ceiling + cellular soft peak).
abstract final class PlaybackQualityPolicy {
  PlaybackQualityPolicy._();

  /// Startup peak height: cellular soft peak, otherwise the hard ceiling.
  static int startupMaxHeight({required bool isCellular}) {
    return isCellular
        ? StoryConstants.cellularSoftPeakVideoHeight
        : StoryConstants.maxPlaybackVideoHeight;
  }

  /// True when a temporary cellular soft peak should later be released to Auto.
  static bool shouldReleaseSoftPeak({
    required bool isCellular,
    required int appliedMaxHeight,
  }) {
    return isCellular &&
        appliedMaxHeight < StoryConstants.maxPlaybackVideoHeight;
  }

  /// Real (non-auto) ladder rungs with a usable height.
  static List<NativeVideoPlayerQuality> realHeightQualities(
    Iterable<NativeVideoPlayerQuality> qualities,
  ) {
    return [
      for (final q in qualities)
        if (!q.isAuto && (q.height ?? 0) > 0) q,
    ];
  }

  /// Whether any real rung exceeds [maxHeight] (cap is otherwise a no-op).
  static bool hasVariantAbove(int maxHeight, List<NativeVideoPlayerQuality> qs) {
    return qs.any((q) => (q.height ?? 0) > maxHeight);
  }

  /// Highest rung ≤ [maxHeight], or the lowest rung when all exceed the cap.
  ///
  /// Returns null when there is nothing meaningful to set (≤1 real rung, or
  /// no rung above the cap).
  static NativeVideoPlayerQuality? chooseUnderMaxHeight({
    required Iterable<NativeVideoPlayerQuality> qualities,
    required int maxHeight,
  }) {
    final qs = realHeightQualities(qualities);
    if (qs.length <= 1) return null;
    if (!hasVariantAbove(maxHeight, qs)) return null;

    final withinCap = qs.where((q) => (q.height ?? 0) <= maxHeight);
    if (withinCap.isNotEmpty) {
      return withinCap.reduce(_preferHigher);
    }
    return qs.reduce(_preferLower);
  }

  static NativeVideoPlayerQuality _preferHigher(
    NativeVideoPlayerQuality a,
    NativeVideoPlayerQuality b,
  ) {
    final ha = a.height ?? 0;
    final hb = b.height ?? 0;
    if (ha != hb) return ha > hb ? a : b;
    final ba = a.bitrate ?? 0;
    final bb = b.bitrate ?? 0;
    return ba >= bb ? a : b;
  }

  static NativeVideoPlayerQuality _preferLower(
    NativeVideoPlayerQuality a,
    NativeVideoPlayerQuality b,
  ) {
    final ha = a.height ?? 0;
    final hb = b.height ?? 0;
    if (ha != hb) return ha < hb ? a : b;
    final ba = a.bitrate ?? 0;
    final bb = b.bitrate ?? 0;
    return ba <= bb ? a : b;
  }
}
