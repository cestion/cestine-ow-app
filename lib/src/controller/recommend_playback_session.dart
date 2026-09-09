import 'package:flutter/foundation.dart';

import 'recommend_feed_controller.dart';

/// Sheet / share overlay session — holds auto-advance and drives player
/// band collapse via [playerSheetOpen].
///
/// Recommend short-video comments must use the same hold path as drama detail
/// sheets so [overlayHoldsAdvance] blocks shell-route teardown.
class RecommendPlaybackSession {
  RecommendPlaybackSession({
    required this.controller,
    required this.playerSheetOpen,
  });

  final RecommendFeedController controller;
  final ValueNotifier<bool> playerSheetOpen;

  Future<T> holdWithCollapsedPlayer<T>(Future<T> Function() action) async {
    playerSheetOpen.value = true;
    try {
      return await controller.holdAutoAdvance(action);
    } finally {
      playerSheetOpen.value = false;
    }
  }

  Future<void> aroundShare(Future<void> Function() share) async {
    await controller.holdAutoAdvance(share);
  }
}
