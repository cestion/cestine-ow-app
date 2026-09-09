import 'package:flutter/material.dart';

import '../../../controller/video_feed_controller.dart';
import 'feed_paused_play_overlay.dart';

/// Center play/pause button overlay for the video feed.
class VideoFeedCenterButton extends StatelessWidget {
  final VideoFeedController controller;

  const VideoFeedCenterButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return FeedPausedPlayOverlay(
      visible: true,
      onTap: controller.togglePlayPause,
    );
  }
}
