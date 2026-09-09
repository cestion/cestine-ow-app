import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../../foundation/playback_visibility.dart';

/// Shared app lifecycle decisions for feed pages.
///
/// Both [VideoFeedPage] and [RecommendFeedBody] ignore [AppLifecycleState.inactive]
/// (Control Center / notification shade) to avoid mute/resume races on iOS.
class FeedAppLifecyclePolicy {
  FeedAppLifecyclePolicy._();

  static bool shouldMarkBackground(AppLifecycleState state) {
    return state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden;
  }

  static bool shouldMarkForeground(AppLifecycleState state) {
    return state == AppLifecycleState.resumed;
  }
}

/// Main-shell drawer / tab / route-cover decisions for embedded feeds.
class FeedShellOcclusionPolicy {
  FeedShellOcclusionPolicy._();

  static bool shouldSoftHideForTab({
    required int tabIndex,
    required int theaterTabIndex,
  }) {
    return tabIndex != theaterTabIndex;
  }

  static bool shouldHardTeardownForShellCover({
    required bool shellRouteCovered,
    required bool overlayHoldsAdvance,
  }) {
    return PlaybackVisibility.shellCoverShouldTeardown(
      shellRouteCovered: shellRouteCovered,
      overlayHoldsAdvance: overlayHoldsAdvance,
    );
  }
}

/// Waits for one frame with a bounded timeout — used before remount / resume.
Future<void> waitOneFeedPostFrame({
  Duration timeout = const Duration(seconds: 2),
}) {
  final done = Completer<void>();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!done.isCompleted) done.complete();
  });
  return done.future.timeout(timeout, onTimeout: () {});
}

/// Defers Platform View teardown until after the auth/login route starts
/// animating — synchronous UiKitView dispose blocks the push transition.
void scheduleFeedAuthCoverSurfaceTeardown({
  required bool Function() mounted,
  required bool Function() stillCovering,
  required bool Function() shouldUnmount,
  required VoidCallback unmount,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted() || !stillCovering()) return;
    if (shouldUnmount()) unmount();
  });
}
