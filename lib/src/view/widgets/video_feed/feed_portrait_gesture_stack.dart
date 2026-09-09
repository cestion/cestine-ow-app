import 'package:flutter/material.dart';

import 'feed_gesture_overlay.dart';
import 'player_gradients.dart';

/// Portrait feed chrome base: top/bottom gradients + gesture layer.
///
/// Page-specific overlays (info rail, actions, header) are passed via
/// [chromeChildren] and [overlayChildren].
class FeedPortraitGestureStack extends StatelessWidget {
  const FeedPortraitGestureStack({
    super.key,
    required this.chromeHidden,
    required this.onEnterClearScreen,
    required this.onExitClearScreen,
    required this.onTap,
    this.onLongPress,
    this.onDoubleTapLike,
    this.showGradients = true,
    this.chromeChildren = const [],
    this.overlayChildren = const [],
  });

  final bool chromeHidden;
  final VoidCallback onEnterClearScreen;
  final VoidCallback onExitClearScreen;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final Future<void> Function()? onDoubleTapLike;
  final bool showGradients;
  final List<Widget> chromeChildren;
  final List<Widget> overlayChildren;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: [
        if (showGradients && !chromeHidden) ...[
          const PlayerTopGradient(),
          const PlayerBottomGradient(),
        ],
        FeedGestureOverlay(
          chromeHidden: chromeHidden,
          onEnterClearScreen: onEnterClearScreen,
          onExitClearScreen: onExitClearScreen,
          onTap: onTap,
          onLongPress: onLongPress,
          onDoubleTapLike: onDoubleTapLike,
        ),
        if (!chromeHidden) ...chromeChildren,
        ...overlayChildren,
      ],
    );
  }
}
