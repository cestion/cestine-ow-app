import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'feed_paused_play_overlay.dart';

/// Binds [FeedPausedPlayOverlay] to playing / user-paused listenables.
class FeedPausedPlayOverlayListenables extends StatelessWidget {
  const FeedPausedPlayOverlayListenables({
    super.key,
    required this.playing,
    required this.userPaused,
    required this.onTap,
    this.ended = false,
  });

  final ValueListenable<bool> playing;
  final ValueListenable<bool> userPaused;
  final VoidCallback onTap;
  final bool ended;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: playing,
      builder: (context, isPlaying, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: userPaused,
          builder: (context, pausedByUser, _) {
            final paused = ended || pausedByUser;
            return FeedPausedPlayOverlay(
              visible: !isPlaying && paused,
              onTap: onTap,
            );
          },
        );
      },
    );
  }
}
