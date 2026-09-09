import 'package:flutter/material.dart';

import '../../../styles/story_colors.dart';

/// 参演位分页指示器，对应 Figma Page Control `14:6260`。
class AgentV3PageIndicator extends StatelessWidget {
  final int itemCount;
  final int occupiedItemCount;
  final int selectedIndex;

  const AgentV3PageIndicator({
    super.key,
    this.itemCount = 5,
    required this.occupiedItemCount,
    this.selectedIndex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final primary = StoryColors.foregroundOf(Theme.of(context).brightness);
    final occupiedCount = occupiedItemCount.clamp(0, itemCount);

    return SizedBox(
      height: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(itemCount, (index) {
          final isSelected = index == selectedIndex;
          final isOccupied = index < occupiedCount;
          final isOutlined = !isSelected && !isOccupied;
          return Padding(
            padding: EdgeInsets.only(right: index == itemCount - 1 ? 0 : 8),
            child: Container(
              key: ValueKey('agent-v3-page-indicator-$index'),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOutlined
                    ? Colors.transparent
                    : primary.withValues(alpha: isSelected ? 1 : 0.3),
                border: isOutlined
                    ? Border.all(color: primary.withValues(alpha: 0.3))
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
