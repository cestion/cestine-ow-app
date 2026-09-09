import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

/// 底部弹层顶部拖拽把手，与 `CommentBottomSheet` 共用同一视觉规范。
class StorySheetDragHandle extends StatelessWidget {
  final Brightness brightness;

  const StorySheetDragHandle({super.key, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 4,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: StoryColors.mutedForegroundOf(brightness).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
