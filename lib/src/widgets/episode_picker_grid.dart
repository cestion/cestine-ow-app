import 'package:flutter/material.dart';

import '../styles/story_colors.dart';
import '../styles/story_text_styles.dart';

/// 选集网格统一的 gridDelegate（5 列）。
const SliverGridDelegateWithFixedCrossAxisCount kEpisodeGridDelegate =
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 5,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
    );

/// 单个选集格子，供 box / sliver 两种网格复用。
Widget buildEpisodeTile({
  required Brightness brightness,
  required int episodeNo,
  required bool isCurrent,
  required ValueChanged<int> onSelect,
}) {
  return GestureDetector(
    onTap: () => onSelect(episodeNo),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: isCurrent
            ? StoryColors.brandTeal.withValues(alpha: 0.16)
            : StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          '$episodeNo',
          style: StoryTextStyles.bodyMedium(
            color: StoryColors.foregroundOf(brightness),
          ).copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    ),
  );
}

/// 可复用的剧集选择网格
///
/// 用于 [VideoFeedPage] 和剧情详情页的选集区域，
/// 统一 UI 风格并避免重复实现。
///
/// 注意：默认 `shrinkWrap: true` 会一次性构建全部格子，仅适用于集数较少
/// 或本身高度受限的场景（如紧凑 sheet）。若嵌入可滚动父容器且集数较多，
/// 请改用 [EpisodePickerSliverGrid] 以获得懒加载。
class EpisodePickerGrid extends StatelessWidget {
  final int totalEpisodes;
  final int currentEpisode;
  final ValueChanged<int> onSelect;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final EdgeInsetsGeometry? padding;

  const EpisodePickerGrid({
    super.key,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.onSelect,
    this.scrollController,
    this.shrinkWrap = true,
    this.physics,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return GridView.builder(
      controller: scrollController,
      shrinkWrap: shrinkWrap,
      padding: padding,
      physics:
          physics ??
          (shrinkWrap
              ? const NeverScrollableScrollPhysics()
              : const ClampingScrollPhysics()),
      gridDelegate: kEpisodeGridDelegate,
      itemCount: totalEpisodes,
      itemBuilder: (ctx, index) {
        final epNo = index + 1;
        return buildEpisodeTile(
          brightness: brightness,
          episodeNo: epNo,
          isCurrent: epNo == currentEpisode,
          onSelect: onSelect,
        );
      },
    );
  }
}

/// [EpisodePickerGrid] 的 Sliver 版本，用于 [CustomScrollView]。
///
/// 相比 `shrinkWrap` 的 box 版本，格子随滚动懒加载，适合集数较多的详情页。
class EpisodePickerSliverGrid extends StatelessWidget {
  final int totalEpisodes;
  final int currentEpisode;
  final ValueChanged<int> onSelect;

  const EpisodePickerSliverGrid({
    super.key,
    required this.totalEpisodes,
    required this.currentEpisode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return SliverGrid(
      gridDelegate: kEpisodeGridDelegate,
      delegate: SliverChildBuilderDelegate((ctx, index) {
        final epNo = index + 1;
        return buildEpisodeTile(
          brightness: brightness,
          episodeNo: epNo,
          isCurrent: epNo == currentEpisode,
          onSelect: onSelect,
        );
      }, childCount: totalEpisodes),
    );
  }
}
