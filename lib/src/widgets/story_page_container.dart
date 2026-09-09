import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';

/// Consistent page layout container matching web's PageContainer pattern.
/// Provides uniform horizontal padding and background.
class StoryPageContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const StoryPageContainer({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: StoryColors.backgroundOf(theme.brightness),
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: StorySpacing.screenHorizontal),
      child: child,
    );
  }
}
