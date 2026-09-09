import 'package:flutter/material.dart';

import '../../../components/theater/theater_home_chrome.dart';
import '../../../model/recommend_feed_model.dart';
import 'video_feed_actor_rail.dart';
import 'video_feed_bottom_info.dart';

/// Shared left-rail placement for portrait feed chrome.
class FeedActorRailPositioned extends StatelessWidget {
  const FeedActorRailPositioned({
    super.key,
    required this.actors,
    this.onTap,
    this.pinProgressToBottom = true,
    this.showEpisodeCta = true,
    this.synopsisMaxLines = 2,
  });

  final List<RecommendFeedActor> actors;
  final VoidCallback? onTap;
  final bool pinProgressToBottom;
  final bool showEpisodeCta;
  final int synopsisMaxLines;

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();
    return Positioned(
      left: 0,
      top: TheaterHomeChrome.heightOf(context),
      bottom: VideoFeedBottomInfo.actorRailBottomOf(
        context,
        pinProgressToBottom: pinProgressToBottom,
        showEpisodeCta: showEpisodeCta,
        synopsisMaxLines: synopsisMaxLines,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: VideoFeedActorRail(actors: actors, onTap: onTap),
      ),
    );
  }
}
