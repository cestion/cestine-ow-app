import 'package:flutter/foundation.dart';

import '../../../foundation/playback_visibility.dart';
import '../../../controller/feed_neighbor_mount_policy.dart';
import '../../../controller/feed_playback_telemetry.dart';
import '../video_feed/feed_player_surface_cache.dart';

/// Surface mount / sheet session helpers for [RecommendFeedBody].
///
/// Isolates Platform View mount flags and visibility resolution from the
/// bind queue / role ring (see [RecommendPlaybackController], [FeedRoleRing]).
/// Async promote / cold bind still run in the body via
/// [RecommendBindHost.bindOrPromote].
class RecommendSurfaceCoordinator {
  RecommendSurfaceCoordinator({
    required this.overlayHoldsAdvance,
    required this.onMountedChanged,
  });

  final bool Function() overlayHoldsAdvance;
  final VoidCallback onMountedChanged;

  final FeedPlayerSurfaceCache surfaceCache = FeedPlayerSurfaceCache();

  bool surfacesMounted = true;

  /// Neighbor B/C Platform Views stay unmounted until the active slot paints
  /// its first frame (same policy as [VideoFeedPage]).
  bool mountNeighborSurfaces = false;
  bool neighborMountScheduled = false;

  /// Single owner for poster reveal latch — keep cover off across brief
  /// slot / surfaceReady flickers while the same playback id stays current.
  String? coverRevealLatchedPlaybackId;

  PlaybackVisibilityKind resolveVisibility({
    required bool mounted,
    required bool feedActive,
    required bool appForeground,
    required bool authOverlayCovering,
    required bool standaloneRouteCovered,
    required bool isStandalone,
    required int tabIndex,
    required int theaterTabIndex,
    required bool drawerOpen,
    required bool shellRouteCovered,
  }) {
    return PlaybackVisibility.resolve(
      mounted: mounted,
      feedActive: feedActive,
      appForeground: appForeground,
      authOverlayCovering: authOverlayCovering,
      standaloneRouteCovered: standaloneRouteCovered,
      isStandalone: isStandalone,
      tabIndex: tabIndex,
      theaterTabIndex: theaterTabIndex,
      drawerOpen: drawerOpen,
      shellRouteCovered: shellRouteCovered,
      overlayHoldsAdvance: overlayHoldsAdvance(),
    );
  }

  bool shouldMount(PlaybackVisibilityKind kind) =>
      PlaybackVisibility.shouldMountSurfaces(kind);

  /// Whether a slot's native Platform View may enter the tree.
  bool shouldMountSlotPlatformView({required bool isActiveSlot}) {
    if (!surfacesMounted) return false;
    if (isActiveSlot) return true;
    return mountNeighborSurfaces;
  }

  void scheduleNeighborMountAfterFirstFrame({
    required bool warmEntry,
    required bool Function() stillNeeded,
    required VoidCallback onMount,
  }) {
    if (mountNeighborSurfaces || neighborMountScheduled) return;
    neighborMountScheduled = true;
    FeedNeighborMountPolicy.scheduleNeighborMount(
      activeHasFirstFrame: true,
      warmEntry: warmEntry,
      stillNeeded: () => stillNeeded() && !mountNeighborSurfaces,
      onAborted: () => neighborMountScheduled = false,
      onMount: () {
        mountNeighborSurfaces = true;
        onMount();
        onMountedChanged();
      },
    );
  }

  /// Immediate neighbor mount for remount / warm-resume (Tab return, auth
  /// overlay) when the active slot already painted a frame.
  void mountNeighborsImmediately({required VoidCallback onMount}) {
    if (mountNeighborSurfaces) {
      onMount();
      return;
    }
    mountNeighborSurfaces = true;
    neighborMountScheduled = true;
    onMount();
    onMountedChanged();
  }

  void restoreNeighborSurfacesAfterRemount({
    required bool activeHasFirstFrame,
    required bool Function() stillNeeded,
    required VoidCallback onNeighborMounted,
  }) {
    if (!surfacesMounted || mountNeighborSurfaces || !activeHasFirstFrame) {
      return;
    }
    if (FeedNeighborMountPolicy.mayMountNeighbors(
      activeHasFirstFrame: true,
      warmEntry: true,
    )) {
      mountNeighborsImmediately(onMount: onNeighborMounted);
      return;
    }
    scheduleNeighborMountAfterFirstFrame(
      warmEntry: true,
      stillNeeded: stillNeeded,
      onMount: onNeighborMounted,
    );
  }

  void resetNeighborMount() {
    mountNeighborSurfaces = false;
    neighborMountScheduled = false;
  }

  bool isPlaybackVisible(PlaybackVisibilityKind kind) =>
      PlaybackVisibility.isPlaybackVisible(kind);

  /// Unmount native surfaces. Preserves reveal latch while a sheet hold is
  /// active so the poster does not flash over video.
  void unmount({required String reason}) {
    if (!surfacesMounted) return;
    if (!overlayHoldsAdvance()) {
      coverRevealLatchedPlaybackId = null;
    }
    surfacesMounted = false;
    resetNeighborMount();
    FeedPlaybackTelemetry.surfaceRemount(feed: 'recommend', reason: reason);
    onMountedChanged();
  }

  void remount() {
    if (surfacesMounted) return;
    surfacesMounted = true;
    FeedPlaybackTelemetry.surfaceRemount(feed: 'recommend', reason: 'remount');
    onMountedChanged();
  }

  /// Soft remount must set [surfaceReady] before waiting for platform views:
  /// the player layer only mounts [NativeVideoPlayer] when both
  /// [surfacesMounted] and [surfaceReady] are true.
  static bool shouldArmSurfaceReady({
    required bool hasNative,
    required bool surfaceReady,
  }) {
    return hasNative && !surfaceReady;
  }

  void onSheetOpenChanged({required bool open, required double bandHeight}) {
    FeedPlaybackTelemetry.sheetCollapse(
      feed: 'recommend',
      open: open,
      bandHeight: bandHeight,
    );
  }

  void dispose() {
    surfaceCache.clear();
  }
}
