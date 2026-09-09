import 'package:flutter/material.dart';

import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';

class StoryCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  const StoryCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.borderRadius,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(StorySpacing.cardPadding),
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          border: border ?? Border.all(color: theme.dividerColor, width: 0.5),
          borderRadius: borderRadius ?? StoryRadius.brLg,
          boxShadow: boxShadow,
        ),
        child: child,
      ),
    );
  }
}
