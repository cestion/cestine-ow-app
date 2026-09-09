import 'package:better_native_video_player/better_native_video_player.dart';
import 'package:flutter/material.dart';

import 'video_feed_player_surface.dart';

/// Stable [ObjectKey] per controller — [fitCollapsedBand] updates via
/// [VideoFeedPlayerSurface.didUpdateWidget] (Positioned geometry only).
///
/// Do not cache-and-replace widgets when [fitCollapsedBand] flips; that
/// remounts UiKitView and triggers iOS `recreating_view`.
class FeedPlayerSurfaceCache {
  final Set<NativeVideoPlayerController> _tracked =
      <NativeVideoPlayerController>{};

  VideoFeedPlayerSurface surfaceFor(
    NativeVideoPlayerController native, {
    bool pinProgressToBottom = true,
    bool retainPlayerKey = false,
    bool fitCollapsedBand = false,
  }) {
    _tracked.add(native);
    return VideoFeedPlayerSurface(
      key: ObjectKey(native),
      controller: native,
      retainPlayerKey: retainPlayerKey,
      pinProgressToBottom: pinProgressToBottom,
      fitCollapsedBand: fitCollapsedBand,
    );
  }

  void remove(NativeVideoPlayerController native) => _tracked.remove(native);

  void clear() => _tracked.clear();
}
