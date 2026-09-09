import 'package:flutter/material.dart';

import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_skeleton.dart';

/// 与 [GameActorCard] 布局一致的演员卡片骨架。
class GameActorCardSkeleton extends StatelessWidget {
  final bool compact;

  const GameActorCardSkeleton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return StoryCardSkeleton(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: StorySkeletonBox(
              width: double.infinity,
              height: double.infinity,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(StorySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: StorySkeletonBox(
                        width: double.infinity,
                        height: 18,
                      ),
                    ),
                    SizedBox(width: 4),
                    StorySkeletonBox(width: 36, height: 12),
                  ],
                ),
                const SizedBox(height: StorySpacing.sm),
                const StorySkeletonBox(width: double.infinity, height: 6),
                const SizedBox(height: StorySpacing.md),
                if (!compact) ...[
                  const Row(
                    children: [
                      Expanded(
                        child: StorySkeletonBox(
                          width: double.infinity,
                          height: 36,
                        ),
                      ),
                      SizedBox(width: StorySpacing.md),
                      Expanded(
                        child: StorySkeletonBox(
                          width: double.infinity,
                          height: 36,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.md),
                ],
                const StorySkeletonBox(width: 120, height: 14),
                const SizedBox(height: StorySpacing.md),
                const Row(
                  children: [
                    Expanded(
                      child: StorySkeletonBox(
                        width: double.infinity,
                        height: 40,
                        borderRadius: StoryRadius.brSm,
                      ),
                    ),
                    SizedBox(width: StorySpacing.md),
                    Expanded(
                      child: StorySkeletonBox(
                        width: double.infinity,
                        height: 40,
                        borderRadius: StoryRadius.brSm,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 派遣槽横向滚动区骨架（与 [GameDeployedActorsSection] 高度对齐）。
class GameDeployedSlotsSkeleton extends StatelessWidget {
  final int slotCount;

  const GameDeployedSlotsSkeleton({super.key, this.slotCount = 3});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 450,
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: slotCount,
        separatorBuilder: (_, _) => const SizedBox(width: StorySpacing.md),
        itemBuilder: (_, _) => const SizedBox(
          width: 280,
          child: GameActorCardSkeleton(compact: true),
        ),
      ),
    );
  }
}

/// 本周数据面板骨架（与 [GameWeeklyStatsPanel] 对齐）。
class GameWeeklyStatsSkeleton extends StatelessWidget {
  const GameWeeklyStatsSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const StoryCardSkeleton(
      padding: EdgeInsets.all(StorySpacing.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              StorySkeletonBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              SizedBox(width: StorySpacing.xs),
              StorySkeletonBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              SizedBox(width: StorySpacing.xs),
              StorySkeletonBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ],
          ),
          SizedBox(height: StorySpacing.md),
          _MetricRowSkeleton(),
          SizedBox(height: StorySpacing.sm),
          _MetricRowSkeleton(),
          SizedBox(height: StorySpacing.sm),
          _MetricRowSkeleton(),
          SizedBox(height: StorySpacing.md),
          Row(
            children: [
              Expanded(
                child: StorySkeletonBox(
                  width: double.infinity,
                  height: 36,
                  borderRadius: StoryRadius.brSm,
                ),
              ),
              SizedBox(width: StorySpacing.md),
              Expanded(
                child: StorySkeletonBox(
                  width: double.infinity,
                  height: 36,
                  borderRadius: StoryRadius.brSm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRowSkeleton extends StatelessWidget {
  const _MetricRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        StorySkeletonBox(width: 100, height: 12),
        Spacer(),
        StorySkeletonBox(width: 72, height: 14),
      ],
    );
  }
}

/// 排序筛选行骨架。
class GameSortFiltersSkeleton extends StatelessWidget {
  const GameSortFiltersSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        StorySkeletonBox(
          width: 56,
          height: 28,
          borderRadius: StoryRadius.brPill,
        ),
        SizedBox(width: 8),
        StorySkeletonBox(
          width: 56,
          height: 28,
          borderRadius: StoryRadius.brPill,
        ),
        SizedBox(width: 8),
        StorySkeletonBox(
          width: 56,
          height: 28,
          borderRadius: StoryRadius.brPill,
        ),
      ],
    );
  }
}

/// 经纪工坊首屏骨架，与 [GamePage] 区块结构一致。
class GamePageSkeleton extends StatelessWidget {
  final int actorCount;

  const GamePageSkeleton({super.key, this.actorCount = 3});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StorySkeletonBox(width: 96, height: 22),
        const SizedBox(height: StorySpacing.md),
        const GameDeployedSlotsSkeleton(),
        const SizedBox(height: StorySpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < 5; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              const StorySkeletonBox(
                width: 32,
                height: 32,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ],
          ],
        ),
        const SizedBox(height: StorySpacing.xl),
        const GameWeeklyStatsSkeleton(),
        const SizedBox(height: StorySpacing.xl),
        const Row(
          children: [
            StorySkeletonBox(width: 80, height: 22),
            SizedBox(width: 6),
            StorySkeletonBox(width: 24, height: 14),
          ],
        ),
        const SizedBox(height: StorySpacing.sm),
        const GameSortFiltersSkeleton(),
        const SizedBox(height: StorySpacing.md),
        for (var i = 0; i < actorCount; i++) ...[
          if (i > 0) const SizedBox(height: StorySpacing.md),
          const GameActorCardSkeleton(),
        ],
      ],
    );
  }
}
