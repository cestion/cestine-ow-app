import 'package:flutter/material.dart';

import '../../../widgets/story_skeleton.dart';

/// 经纪人 V3 首屏骨架：角色卡、分页、主操作与快捷入口。
class AgentV3PageSkeleton extends StatelessWidget {
  const AgentV3PageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: const ValueKey('agent-v3-page-skeleton'),
      child: ShimmerScope(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final widthFromViewport =
                        constraints.maxWidth * 310.5 / 375;
                    final widthFromHeight = constraints.maxHeight * 310.5 / 414;
                    final cardWidth = widthFromViewport < widthFromHeight
                        ? widthFromViewport
                        : widthFromHeight;
                    return Center(
                      child: StorySkeletonBox(
                        width: cardWidth,
                        height: constraints.maxHeight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: StorySkeletonBox(width: 8, height: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const StorySkeletonBox(
                    width: double.infinity,
                    height: 44,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (var index = 0; index < 4; index++) ...[
                        if (index > 0) const SizedBox(width: 10),
                        const Expanded(
                          child: StorySkeletonBox(
                            width: double.infinity,
                            height: 58,
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
