/// Unified playback visibility for recommend / video feeds.
///
/// Consolidates tab, drawer, shell route cover, auth overlay, app lifecycle,
/// and comment-sheet [overlayHoldsAdvance] into one decision surface.
enum PlaybackVisibilityKind {
  /// Feed is foreground and unobstructed.
  visible,

  /// Comment / drama sheet — surfaces stay mounted, player band collapses.
  sheetOverlay,

  /// Login / report — pause audio and tear down Platform Views so the
  /// opaque route transition is not contending with UiKitView/SurfaceView
  /// compositing (login jank / Impeller drawable timeouts).
  authOccluded,

  /// Tab switch, drawer, or full route cover — unmount surfaces.
  occluded,

  /// App background or feed inactive.
  suspended,
}

class PlaybackVisibility {
  PlaybackVisibility._();

  static PlaybackVisibilityKind resolve({
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
    required bool overlayHoldsAdvance,
  }) {
    if (!mounted || !feedActive || !appForeground) {
      return PlaybackVisibilityKind.suspended;
    }
    if (authOverlayCovering) {
      return PlaybackVisibilityKind.authOccluded;
    }
    if (overlayHoldsAdvance) {
      return PlaybackVisibilityKind.sheetOverlay;
    }
    if (isStandalone && standaloneRouteCovered) {
      return PlaybackVisibilityKind.occluded;
    }
    if (!isStandalone) {
      if (tabIndex != theaterTabIndex) {
        return PlaybackVisibilityKind.occluded;
      }
      if (drawerOpen) return PlaybackVisibilityKind.occluded;
      if (shellRouteCovered) return PlaybackVisibilityKind.occluded;
    }
    return PlaybackVisibilityKind.visible;
  }

  /// Native Platform Views may stay in the tree (sheet only).
  /// Auth login/report unmount so the covering route can paint smoothly.
  static bool shouldMountSurfaces(PlaybackVisibilityKind kind) {
    switch (kind) {
      case PlaybackVisibilityKind.visible:
      case PlaybackVisibilityKind.sheetOverlay:
        return true;
      case PlaybackVisibilityKind.authOccluded:
      case PlaybackVisibilityKind.occluded:
      case PlaybackVisibilityKind.suspended:
        return false;
    }
  }

  /// Recovery / unexpected-pause logic treats these as "on screen".
  static bool isPlaybackVisible(PlaybackVisibilityKind kind) {
    return kind == PlaybackVisibilityKind.visible ||
        kind == PlaybackVisibilityKind.sheetOverlay;
  }

  /// Shell route cover should tear down surfaces (sheet hold exempt).
  static bool shellCoverShouldTeardown({
    required bool shellRouteCovered,
    required bool overlayHoldsAdvance,
  }) {
    return shellRouteCovered && !overlayHoldsAdvance;
  }
}
