import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Hourly STORY unit as `[points icon]/h` (replaces plain `STORY/h` text).
class StoryPerHourUnitLabel extends StatelessWidget {
  static const assetPath = 'assets/common/story_points_icon.svg';

  final double iconSize;
  final TextStyle? textStyle;

  const StoryPerHourUnitLabel({
    super.key,
    this.iconSize = 10,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset(
          assetPath,
          width: iconSize,
          height: iconSize,
        ),
        Text('/h', style: textStyle),
      ],
    );
  }
}
