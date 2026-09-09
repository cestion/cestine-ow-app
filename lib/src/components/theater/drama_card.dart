import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/story_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../badge/content_badge.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/widgets.dart';
import 'drama_card_vm.dart';
import 'drama_cast_actors_dialog.dart';

const _cardUserIcon = 'assets/drama/card_user.svg';
const _cardPlayCountIcon = 'assets/drama/card_player_play.svg';
const _cardCompleteIcon = 'assets/drama/card_play.svg';
const _cardHotIcon = 'assets/drama/card_hot.svg';
const _cardLikeIcon = 'assets/drama/card_heart.svg';
const _cardStarIcon = 'assets/drama/card_star.svg';
const _cardStarOutlineIcon = 'assets/drama/brand_star.svg';

/// Figma「剧场卡片v2」圆角 12。
const _dramaCardRadius = BorderRadius.all(Radius.circular(12));
const _dramaCardTopRadius = BorderRadius.vertical(top: Radius.circular(12));

class DramaCard extends StatelessWidget {
  final DramaCardVm vm;
  final VoidCallback? onTap;
  final bool favorite;
  final VoidCallback? onFavoriteToggle;
  final bool isGrid;

  /// 双列封面 3:4。
  static const gridCoverAspectRatio = 3 / 4;

  /// `_GridDramaCard` 信息区固定高度。
  /// padding 10/8/10/10(=18) + 标题 14×1.3(=18.2) + 间距 4 + 副文 11×1.2(=13.2)
  /// ≈ 53.4；Android 字号取整后易到 54–55，留到 58 避免底部 1px overflow。
  static const gridInfoHeight = 58.0;

  /// 网格内容区宽度（已扣除外层 padding）对应的 cell 宽/高，避免行间多出空白。
  static double gridChildAspectRatioFor(
    double gridWidth, {
    int crossAxisCount = 2,
    double crossAxisSpacing = StorySpacing.xs,
  }) {
    final cardWidth =
        (gridWidth - crossAxisSpacing * (crossAxisCount - 1)) / crossAxisCount;
    if (cardWidth <= 0) return 0.60;
    // +1 吸收封面 3:4 取整，避免格子比卡片矮出 1px 导致 Column overflow。
    return cardWidth / (cardWidth / gridCoverAspectRatio + gridInfoHeight + 1);
  }

  const DramaCard({
    super.key,
    required this.vm,
    this.onTap,
    this.favorite = false,
    this.onFavoriteToggle,
    this.isGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGrid) {
      return GridDramaCard(vm: vm, onTap: onTap);
    }

    final theme = Theme.of(context);
    final l10n = context.l10n;

    return _ListDramaCard(
      vm: vm,
      onTap: onTap,
      favorite: favorite,
      onFavoriteToggle: onFavoriteToggle,
      theme: theme,
      l10n: l10n,
    );
  }
}

class GridDramaCard extends StatelessWidget {
  final DramaCardVm vm;
  final VoidCallback? onTap;
  final bool showPlayCount;

  const GridDramaCard({
    super.key,
    required this.vm,
    this.onTap,
    this.showPlayCount = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = StoryColors.foregroundOf(theme.brightness);
    final muted = StoryColors.mutedForegroundOf(theme.brightness);
    final actors = vm.actorsWithAvatar;
    final creator = vm.gridCreator;
    final metaLine = vm.gridMetaLine;
    final hidePlayMetrics =
        !showPlayCount && (vm.isShortVideo || vm.isSingleEpisode);
    final coverStats = hidePlayMetrics
        ? vm.coverStats
              .where(
                (stat) =>
                    stat.kind != DramaCardCoverStatKind.play &&
                    stat.kind != DramaCardCoverStatKind.complete,
              )
              .toList(growable: false)
        : vm.coverStats;

    return StoryCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: _dramaCardRadius,
      border: Border.all(width: 0, color: Colors.transparent),
      backgroundColor: StoryColors.cardOf(theme.brightness),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.05),
          blurRadius: 12,
          offset: const Offset(0, 2),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: _dramaCardTopRadius,
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(url: vm.coverUrl),
                  if (!vm.isShortVideo && vm.showContentBadge)
                    ContentBadge.positionedCardCorner(
                      badge: vm.badge,
                      variant: ContentBadgeVariant.drama,
                    ),
                  if (vm.durationLabel != null)
                    Positioned(
                      top: StorySpacing.md,
                      right: StorySpacing.md,
                      child: Text(
                        vm.durationLabel!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: StoryColors.onOverlay,
                        ),
                      ),
                    ),
                  if (actors.isNotEmpty)
                    Positioned(
                      left: StorySpacing.sm,
                      right: StorySpacing.sm,
                      // Above cover play/heat/rating row.
                      bottom: 38,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DramaCardRolePill(
                          actors: actors,
                          onTap: () => DramaCastActorsDialog.show(
                            context,
                            actors: actors,
                          ),
                        ),
                      ),
                    ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 40,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x8C000000)],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: StorySpacing.sm,
                    right: StorySpacing.sm,
                    bottom: StorySpacing.sm,
                    child: _CoverStatsRow(stats: coverStats),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: DramaCard.gridInfoHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    vm.headline,
                    strutStyle: const StrutStyle(
                      fontSize: 14,
                      height: 1.3,
                      forceStrutHeight: true,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: fg,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (vm.isShortVideo)
                    _ShortVideoCreator(creator: creator, muted: muted)
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            metaLine ?? '',
                            strutStyle: const StrutStyle(
                              fontSize: 11,
                              height: 1.2,
                              forceStrutHeight: true,
                            ),
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.2,
                              color: muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (creator != null && creator.isNotEmpty)
                          Expanded(
                            child: Text(
                              creator.startsWith('@') ? creator : '@$creator',
                              strutStyle: const StrutStyle(
                                fontSize: 11,
                                height: 1.2,
                                forceStrutHeight: true,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.2,
                                color: muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortVideoCreator extends StatelessWidget {
  final String? creator;
  final Color muted;

  const _ShortVideoCreator({required this.creator, required this.muted});

  @override
  Widget build(BuildContext context) {
    final name = creator;
    if (name == null || name.isEmpty) return const SizedBox.shrink();
    return Text(
      name.startsWith('@') ? name : '@$name',
      strutStyle: const StrutStyle(
        fontSize: 11,
        height: 1.2,
        forceStrutHeight: true,
      ),
      style: TextStyle(fontSize: 11, height: 1.2, color: muted),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.left,
    );
  }
}

class _ListDramaCard extends StatelessWidget {
  final DramaCardVm vm;
  final VoidCallback? onTap;
  final bool favorite;
  final VoidCallback? onFavoriteToggle;
  final ThemeData theme;
  final AppLocalizations l10n;

  const _ListDramaCard({
    required this.vm,
    required this.onTap,
    required this.favorite,
    required this.onFavoriteToggle,
    required this.theme,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final title = vm.listTitle;
    final description = vm.listDescription;
    final tags = vm.tags;
    final secondary = StoryColors.mutedForegroundOf(theme.brightness);
    final actors = vm.actorsWithAvatar;

    return StoryCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: _dramaCardRadius,
      border: Border.all(width: 0, color: Colors.transparent),
      backgroundColor: StoryColors.cardOf(theme.brightness),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 600 / 500,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: _dramaCardTopRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _CoverImage(url: vm.coverUrl),
                      if (!vm.isShortVideo && vm.showContentBadge)
                        ContentBadge.positionedCardCorner(
                          badge: vm.badge,
                          variant: ContentBadgeVariant.drama,
                        ),
                      if (actors.isNotEmpty || vm.totalEpisodes != null)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.3),
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                              child: Row(
                                children: [
                                  if (actors.isNotEmpty)
                                    Flexible(
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: DramaCardRolePill(
                                          actors: actors,
                                          onTap: () =>
                                              DramaCastActorsDialog.show(
                                                context,
                                                actors: actors,
                                              ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  if (vm.totalEpisodes != null)
                                    Text(
                                      l10n.playerEpisodeTotal(
                                        vm.totalEpisodes!,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        height: 16 / 12,
                                        letterSpacing: 0.04,
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (onFavoriteToggle != null)
                  Positioned(
                    top: StorySpacing.sm,
                    right: StorySpacing.sm,
                    child: GestureDetector(
                      onTap: onFavoriteToggle,
                      child: Container(
                        padding: const EdgeInsets.all(StorySpacing.xs),
                        decoration: const BoxDecoration(
                          color: StoryColors.overlayMedium,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          favorite ? Icons.favorite : Icons.favorite_border,
                          color: favorite
                              ? StoryColors.likeActive
                              : StoryColors.onOverlay,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.w700,
                      color: StoryColors.foregroundOf(theme.brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _DramaTagsRow(tags: tags, theme: theme),
                ],
                if (description != null && description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      letterSpacing: -0.15,
                      color: secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                _DramaStatsRow(
                  creator: vm.listCreator,
                  playLabel: vm.listPlayLabel,
                  heatLabel: vm.listHeatLabel,
                  rating: vm.listRating,
                  theme: theme,
                  iconSize: 18,
                  textStyle: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverStatsRow extends StatelessWidget {
  final List<DramaCardCoverStatVm> stats;

  const _CoverStatsRow({required this.stats});

  /// Matches [ContentWorkGridCard] cover row: left / center / right with
  /// equal Spacers; missing trailing slot keeps a `0.0` placeholder so the
  /// middle (like) sits where the work card heart does.
  static const _placeholder = DramaCardCoverStatVm(
    kind: DramaCardCoverStatKind.complete,
    label: '0.0',
  );

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    if (stats.length == 2 &&
        stats[0].kind == DramaCardCoverStatKind.play &&
        stats[1].kind == DramaCardCoverStatKind.like) {
      return Row(
        children: [
          _CoverStat(stat: stats[0]),
          const SizedBox(width: 16),
          _CoverStat(stat: stats[1]),
        ],
      );
    }

    final left = stats.isNotEmpty ? stats[0] : null;
    final middle = stats.length > 1 ? stats[1] : null;
    final right = stats.length > 2 ? stats[2] : null;

    return Row(
      children: [
        if (left != null) _CoverStat(stat: left),
        const Spacer(),
        if (middle != null) _CoverStat(stat: middle),
        const Spacer(),
        if (right != null)
          _CoverStat(stat: right)
        else
          const Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: _CoverStat(stat: _placeholder),
          ),
      ],
    );
  }
}

class _CoverStat extends StatelessWidget {
  final DramaCardCoverStatVm stat;

  const _CoverStat({required this.stat});

  static String _assetFor(DramaCardCoverStatKind kind) => switch (kind) {
    DramaCardCoverStatKind.play => _cardPlayCountIcon,
    DramaCardCoverStatKind.complete => _cardCompleteIcon,
    DramaCardCoverStatKind.like => _cardLikeIcon,
    DramaCardCoverStatKind.heat => _cardHotIcon,
    DramaCardCoverStatKind.rating => _cardStarOutlineIcon,
  };

  static double _iconSizeFor(DramaCardCoverStatKind kind) =>
      kind == DramaCardCoverStatKind.like ? 9 : 12;

  @override
  Widget build(BuildContext context) {
    final iconSize = _iconSizeFor(stat.kind);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: Center(
            child: SvgPicture.asset(
              _assetFor(stat.kind),
              width: iconSize,
              height: iconSize,
              colorFilter: stat.tintIcon
                  ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                  : null,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          stat.label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _DramaCardSvgIcon extends StatelessWidget {
  final String asset;
  final double size;
  final Color? color;

  const _DramaCardSvgIcon({
    required this.asset,
    required this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (color == null) {
      return SvgPicture.asset(asset, width: size, height: size);
    }
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class _DramaStatsRow extends StatelessWidget {
  final String? creator;
  final String? playLabel;
  final String? heatLabel;
  final double? rating;
  final ThemeData theme;
  final double iconSize;
  final TextStyle textStyle;

  const _DramaStatsRow({
    required this.creator,
    required this.playLabel,
    required this.heatLabel,
    required this.rating,
    required this.theme,
    required this.iconSize,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final muted = textStyle.color ?? theme.colorScheme.onSurfaceVariant;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              if (creator != null && creator!.isNotEmpty) ...[
                _DramaCardSvgIcon(
                  asset: _cardUserIcon,
                  size: iconSize,
                  color: muted,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    creator!,
                    style: textStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              if (playLabel != null) ...[
                _DramaCardSvgIcon(
                  asset: _cardCompleteIcon,
                  size: iconSize,
                  color: muted,
                ),
                const SizedBox(width: 4),
                Text(playLabel!, style: textStyle),
                const SizedBox(width: 12),
              ],
              if (heatLabel != null) ...[
                _DramaCardSvgIcon(
                  asset: _cardHotIcon,
                  size: iconSize,
                  color: muted,
                ),
                const SizedBox(width: 4),
                Text(heatLabel!, style: textStyle),
              ],
            ],
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: 8),
          _DramaCardSvgIcon(asset: _cardStarIcon, size: iconSize),
          const SizedBox(width: 4),
          Text(
            rating!.toStringAsFixed(1),
            style: textStyle.copyWith(color: StoryColors.warning),
          ),
        ],
      ],
    );
  }
}

class _DramaTagsRow extends StatelessWidget {
  final List<String> tags;
  final ThemeData theme;

  const _DramaTagsRow({required this.tags, required this.theme});

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(theme.brightness);
    final bg = StoryColors.actorHeroBadgeBgOf(theme.brightness);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < tags.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tags[i],
                style: TextStyle(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                  color: fg,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  final String? url;
  const _CoverImage({this.url});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final placeholderColor = StoryColors.actorHeroBadgeBgOf(brightness);
    final iconColor = StoryColors.mutedForegroundOf(brightness);

    if (url == null || url!.isEmpty) {
      return ColoredBox(
        color: placeholderColor,
        child: Center(
          child: Icon(Icons.movie_outlined, color: iconColor, size: 36),
        ),
      );
    }
    return StoryCachedImage(
      imageUrl: url!,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        StoryImageCache.cardCover,
      ),
      placeholder: ColoredBox(color: placeholderColor),
      errorWidget: ColoredBox(
        color: placeholderColor,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: iconColor, size: 28),
        ),
      ),
    );
  }
}
