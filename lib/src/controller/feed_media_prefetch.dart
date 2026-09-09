import 'dart:async';

import '../core/video_url_helpers.dart';
import '../model/models.dart';
import '../services/video_precache_service.dart';

/// Shared HLS/MP4 segment warming for drama and recommend feeds.
class FeedMediaPrefetch {
  FeedMediaPrefetch._();

  static void warmHttpUrl(
    String? url, {
    required VideoPrecacheContext context,
    double budgetRatio = 1.0,
    PrecachePriority priority = PrecachePriority.ahead,
  }) {
    final trimmed = url?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        !VideoUrlHelpers.isHttpUrl(trimmed)) {
      return;
    }
    unawaited(
      VideoPrecacheService.instance.precacheUrl(
        trimmed,
        context: context,
        budgetRatio: budgetRatio,
        priority: priority,
      ),
    );
  }

  static Future<void> warmPlay(
    DramaPlayResponse play, {
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    double budgetRatio = 1.0,
    PrecachePriority priority = PrecachePriority.ahead,
  }) {
    return VideoPrecacheService.instance.precachePlay(
      play,
      context: context,
      budgetRatio: budgetRatio,
      priority: priority,
    );
  }
}
