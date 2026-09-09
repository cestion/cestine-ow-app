import 'package:flutter/material.dart';

import '../styles/story_spacing.dart';

enum StoryBreakpoint { mobile, tablet, desktop }

class StoryBreakpoints {
  StoryBreakpoints._();

  static const double mobileMaxWidth = 600;
  static const double tabletMinWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double desktopMinWidth = 1024;

  static StoryBreakpoint of(double width) {
    if (width < mobileMaxWidth) return StoryBreakpoint.mobile;
    if (width < desktopMinWidth) return StoryBreakpoint.tablet;
    return StoryBreakpoint.desktop;
  }
}

class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({super.key, required this.builder, this.child});

  final Widget? child;
  final Widget Function(
    BuildContext context,
    StoryBreakpoint breakpoint,
    Widget? child,
  )
  builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = StoryBreakpoints.of(constraints.maxWidth);
        return builder(context, breakpoint, child);
      },
    );
  }
}

extension StoryResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;

  StoryBreakpoint get breakpoint => StoryBreakpoints.of(screenWidth);

  bool get isMobile => screenWidth < StoryBreakpoints.tabletMinWidth;

  bool get isTablet =>
      screenWidth >= StoryBreakpoints.tabletMinWidth &&
      screenWidth < StoryBreakpoints.desktopMinWidth;

  bool get isDesktop => screenWidth >= StoryBreakpoints.desktopMinWidth;
}

const double storyResponsiveHorizontalPadding = StorySpacing.screenHorizontal;
