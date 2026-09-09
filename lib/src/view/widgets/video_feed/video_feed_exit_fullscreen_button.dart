import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Floating exit-fullscreen control (recommend / drama fullscreen).
///
/// Anchored [bottomInset] from the bottom and [rightInset] from the right of
/// the parent [Stack].
class VideoFeedExitFullscreenButton extends StatelessWidget {
  static const double size = 36;
  static const double bottomInset = 30;
  static const double rightInset = 20;
  static const String asset = 'assets/drama/fullsreen_exit.svg';

  final VoidCallback onTap;

  const VideoFeedExitFullscreenButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: rightInset,
      bottom: bottomInset,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SvgPicture.asset(asset, width: size, height: size),
      ),
    );
  }
}
