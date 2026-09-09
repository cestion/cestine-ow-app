import 'package:flutter/widgets.dart';

/// TikTok-style fast, snapping page view scroll physics.
class SnappyPageScrollPhysics extends PageScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 0.2, // Low mass for fast startup reaction
    stiffness: 300.0, // High stiffness for snappy snapping back
    damping: 17.0, // Critical damping to prevent wiggles
  );
}
