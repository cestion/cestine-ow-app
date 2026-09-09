import 'package:flutter/material.dart';

import 'player_gradients.dart';

/// Unified per-page wrapper for vertical video feeds.
///
/// Encapsulates the shared pattern used by both [RecommendFeedBody] and
/// [VideoFeedPage]: cover + gradients + optional chrome, all inside one
/// [Stack] so they slide together during vertical swipes.
class FeedPageItem extends StatelessWidget {
  /// The cover / poster widget (typically [VideoFeedPageItem]).
  final Widget child;

  /// Optional chrome overlay (gradients are always included separately).
  /// Pass `null` for neighbor pages that should not show interactive chrome.
  final Widget? chrome;

  const FeedPageItem({super.key, required this.child, this.chrome});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        const PlayerTopGradient(),
        const PlayerBottomGradient(),
        ?chrome,
      ],
    );
  }
}
