import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/story_constants.dart';

/// Centered play icon shown when the active feed card is paused.
class FeedPausedPlayOverlay extends StatelessWidget {
  const FeedPausedPlayOverlay({
    super.key,
    required this.visible,
    required this.onTap,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Positioned.fill(
      child: Center(
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: SvgPicture.asset(
            'assets/drama/player_play.svg',
            width: StorySizes.playerPlayIconWidth,
            height: StorySizes.playerPlayIconHeight,
          ),
        ),
      ),
    );
  }
}
