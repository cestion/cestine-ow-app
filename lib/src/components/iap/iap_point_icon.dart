import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../styles/story_colors.dart';

/// Figma「点数」图标（assets/iap/point.svg），固定品牌红。
class IapPointIcon extends StatelessWidget {
  const IapPointIcon({super.key, this.size = 16});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/iap/point.svg',
      width: size,
      height: size,
      colorFilter: const ColorFilter.mode(
        StoryColors.brandTealRed,
        BlendMode.srcIn,
      ),
    );
  }
}
