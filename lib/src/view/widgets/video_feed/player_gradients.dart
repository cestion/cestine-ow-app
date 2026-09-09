import 'package:flutter/material.dart';

import '../../../core/story_constants.dart';
import '../../../styles/story_colors.dart';

class PlayerTopGradient extends StatelessWidget {
  const PlayerTopGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      height: StorySizes.playerGradientTopHeight,
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [StoryColors.overlayMedium, Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }
}

class PlayerBottomGradient extends StatelessWidget {
  const PlayerBottomGradient({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: StorySizes.playerGradientBottomHeight,
      child: IgnorePointer(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, StoryColors.overlayHeavy],
            ),
          ),
        ),
      ),
    );
  }
}
