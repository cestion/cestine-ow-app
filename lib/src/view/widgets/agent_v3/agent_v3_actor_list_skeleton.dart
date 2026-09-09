import 'package:flutter/material.dart';

import '../../../widgets/story_skeleton.dart';

const _cardDesignWidth = 175.5;
const _cardDesignHeight = 234.0;
const _cardAspectRatio = _cardDesignWidth / _cardDesignHeight;

/// 经纪人 V3 角色列表共用骨架屏。
///
/// 回收、升级列表使用卡片内操作区；候场列表通过 [showExternalActions]
/// 保留卡片下方的双操作按钮空间，避免真实数据出现时列表高度跳变。
class AgentV3ActorListSkeleton extends StatelessWidget {
  const AgentV3ActorListSkeleton({
    super.key,
    this.showExternalActions = false,
    this.itemCount = 6,
  }) : assert(itemCount > 0);

  final bool showExternalActions;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        key: const ValueKey('agent-v3-actor-list-skeleton'),
        child: ShimmerScope(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 24) / 2;
              final cardHeight = cardWidth / _cardAspectRatio;
              final itemHeight = cardHeight + (showExternalActions ? 48 : 0);

              return GridView.builder(
                key: const ValueKey('agent-v3-actor-list-skeleton-grid'),
                padding: EdgeInsets.fromLTRB(
                  8,
                  0,
                  8,
                  8 + MediaQuery.paddingOf(context).bottom,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: showExternalActions ? 16 : 8,
                  mainAxisExtent: itemHeight,
                ),
                itemCount: itemCount,
                itemBuilder: (_, _) => _ActorCardSkeleton(
                  showExternalActions: showExternalActions,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActorCardSkeleton extends StatelessWidget {
  const _ActorCardSkeleton({required this.showExternalActions});

  final bool showExternalActions;

  @override
  Widget build(BuildContext context) {
    final card = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            const StorySkeletonBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StorySkeletonBox(
                    width: constraints.maxWidth * 0.5,
                    height: 14,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  const SizedBox(height: 5),
                  StorySkeletonBox(
                    width: constraints.maxWidth * 0.32,
                    height: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                children: [
                  StorySkeletonBox(
                    width: double.infinity,
                    height: 26,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  const SizedBox(height: 8),
                  StorySkeletonBox(
                    width: double.infinity,
                    height: showExternalActions ? 32 : 40,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!showExternalActions) return card;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: card),
        const SizedBox(height: 8),
        Row(
          children: [
            const StorySkeletonBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StorySkeletonBox(
                width: double.infinity,
                height: 40,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
