import 'package:flutter/material.dart';

import '../styles/story_colors.dart';

class StoryTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController? controller;
  final List<Widget> tabs;
  final bool isScrollable;
  final bool showDivider;
  final ValueChanged<int>? onTap;
  final Decoration? indicator;
  final Color? unselectedLabelColor;
  final Color? dividerColor;
  final EdgeInsetsGeometry? labelPadding;
  final TabAlignment? tabAlignment;

  const StoryTabBar({
    super.key,
    this.controller,
    required this.tabs,
    this.isScrollable = false,
    this.showDivider = true,
    this.onTap,
    this.indicator,
    this.unselectedLabelColor,
    this.dividerColor,
    this.labelPadding,
    this.tabAlignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return TabBar(
      controller: controller,
      tabs: tabs,
      isScrollable: isScrollable,
      onTap: onTap,
      tabAlignment: tabAlignment ?? (isScrollable ? TabAlignment.start : null),
      labelPadding: labelPadding,

      // Text styling
      labelColor: StoryColors.foregroundOf(brightness),
      unselectedLabelColor:
          unselectedLabelColor ?? StoryColors.mutedForegroundOf(brightness),
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),

      // Custom short thick indicator (overridable per page)
      indicator:
          indicator ??
          StoryTabIndicator(color: StoryColors.foregroundOf(brightness)),
      indicatorSize: TabBarIndicatorSize.label,

      // Divider styling
      dividerColor: showDivider
          ? (dividerColor ?? StoryColors.borderOf(brightness))
          : Colors.transparent,
      dividerHeight: showDivider ? 0.5 : 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(48);
}

class StoryTabIndicator extends Decoration {
  final Color color;
  final double width;
  final double height;
  final double borderRadius;

  const StoryTabIndicator({
    required this.color,
    this.width = 24.0,
    this.height = 3.0,
    this.borderRadius = 1.5,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _StoryTabIndicatorPainter(this, onChanged);
  }
}

class _StoryTabIndicatorPainter extends BoxPainter {
  final StoryTabIndicator decoration;

  _StoryTabIndicatorPainter(this.decoration, VoidCallback? onChanged)
    : super(onChanged);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Rect rect = offset & (configuration.size ?? Size.zero);
    final double x = rect.left + (rect.width - decoration.width) / 2;
    final double y = rect.bottom - decoration.height;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, decoration.width, decoration.height),
      Radius.circular(decoration.borderRadius),
    );

    final Paint paint = Paint()
      ..color = decoration.color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rrect, paint);
  }
}
