import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/story_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_format.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../utils/mining_power.dart';
import '../../widgets/widgets.dart';
import '../badge/content_badge.dart';
import '../common/actor_role_avatar.dart';
import '../common/story_per_hour_unit_label.dart';

const _cardPlayIcon = 'assets/drama/card_play.svg';
const _cardLikeIcon = 'assets/drama/brand_tinder.svg';
const _cardStarIcon = 'assets/drama/card_star_outline.svg';

/// 通用双列「短剧卡片」— Figma 搜索 `655:106441` / `655:132896`。
///
/// 个人主页等场景可复用；[likeCount] / [storyPerHour] / [creatorAvatarUrl]
/// 为推荐搜索等扩展字段（[DramaListItem] 契约可能暂无）。
/// 封面 232:310 + 信息区固定 72（@175.5w → 306.5h）。
class ContentDramaGridCard extends StatelessWidget {
  final DramaListItem drama;
  final int? likeCount;
  final double? storyPerHour;
  final String? creatorAvatarUrl;
  final VoidCallback? onTap;

  /// When false, hides the drama [ContentBadge] on the cover.
  final bool showContentBadge;

  const ContentDramaGridCard({
    super.key,
    required this.drama,
    this.likeCount,
    this.storyPerHour,
    this.creatorAvatarUrl,
    this.onTap,
    this.showContentBadge = false,
  });

  factory ContentDramaGridCard.fromFeedItem(
    FeedItem item, {
    Key? key,
    VoidCallback? onTap,
    bool showContentBadge = false,
  }) {
    return ContentDramaGridCard(
      key: key,
      drama: item.toDramaListItem(),
      likeCount: item.likeCount,
      storyPerHour: item.totalComputingPower,
      creatorAvatarUrl: item.creatorAvatar,
      onTap: onTap,
      showContentBadge: showContentBadge,
    );
  }

  static const coverAspectRatio = 232 / 310;
  static const infoHeight = 72.0;
  static const gridCrossAxisCount = 2;
  static const gridSpacing = 8.0;

  /// Fallback @ Figma 375 宽（卡宽 175.5 → 306.5h ≈ 0.573）。
  static const gridChildAspectRatio = 175.5 / (175.5 * 310 / 232 + 72);

  /// 网格内容区宽度（已扣除外层 padding）对应的 cell 宽/高。
  static double gridChildAspectRatioFor(double gridWidth) {
    final cardWidth =
        (gridWidth - gridSpacing * (gridCrossAxisCount - 1)) /
        gridCrossAxisCount;
    if (cardWidth <= 0) return gridChildAspectRatio;
    return cardWidth / (cardWidth / coverAspectRatio + infoHeight);
  }

  static const cardRadius = StoryRadius.brLg;
  static const _ipAvatarSize = 32.0;
  static const _ipAvatarOverlap = 16.0;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final actors = _actorsWithAvatar(drama);
    final metaLeft = _metaLeftLabel(l10n, drama);
    final creatorLabel = _creatorLabel(drama.creatorName);
    final cardBg = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : Colors.white;
    final borderColor = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : const Color(0xFFF0F0F3);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: cardRadius,
          border: Border.all(color: borderColor, width: 0.3),
        ),
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CoverImage(url: drama.dramaCoverUrl),
                    if (showContentBadge)
                      ContentBadge.positionedCardCorner(
                        badge: drama.badge,
                        variant: ContentBadgeVariant.drama,
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 40,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: StorySpacing.md,
                      right: StorySpacing.md,
                      bottom: StorySpacing.md,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (actors.isNotEmpty || storyPerHour != null)
                            _IpAvatarGlassPill(
                              actors: actors,
                              storyPerHour: storyPerHour,
                            ),
                          if (actors.isNotEmpty || storyPerHour != null)
                            const SizedBox(height: StorySpacing.sm),
                          _CoverStatsRow(
                            completeCount:
                                drama.totalCompletedViewCount ??
                                drama.totalPlayCount ??
                                0,
                            likeCount: likeCount ?? 0,
                            avgRating: drama.avgRating,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: infoHeight,
                child: Padding(
                  padding: const EdgeInsets.all(StorySpacing.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        drama.dramaTitle?.trim().isNotEmpty == true
                            ? drama.dramaTitle!.trim()
                            : l10n.dramaUnnamed,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          color: StoryColors.foregroundOf(brightness),
                        ),
                        strutStyle: const StrutStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          forceStrutHeight: true,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (metaLeft != null || creatorLabel != null) ...[
                        const SizedBox(height: StorySpacing.sm),
                        SizedBox(
                          height: 16,
                          child: Row(
                            children: [
                              if (metaLeft != null)
                                Expanded(
                                  child: Text(
                                    metaLeft,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      letterSpacing: 0.04,
                                      color: StoryColors.mutedForegroundOf(
                                        brightness,
                                      ),
                                    ),
                                    strutStyle: const StrutStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      forceStrutHeight: true,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              else
                                const Spacer(),
                              if (creatorLabel != null) ...[
                                if ((creatorAvatarUrl ?? '').isNotEmpty) ...[
                                  ClipOval(
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: StoryCachedImage(
                                        imageUrl: creatorAvatarUrl!,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Flexible(
                                  child: Text(
                                    creatorLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      letterSpacing: 0.04,
                                      color: StoryColors.mutedForegroundOf(
                                        brightness,
                                      ),
                                    ),
                                    strutStyle: const StrutStyle(
                                      fontSize: 12,
                                      height: 16 / 12,
                                      forceStrutHeight: true,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static List<DramaActorCollection> _actorsWithAvatar(DramaListItem drama) {
    final collections = drama.actorCollections;
    if (collections == null || collections.isEmpty) return const [];
    final seen = <String>{};
    final out = <DramaActorCollection>[];
    for (final actor in collections) {
      final id = actor.id?.trim();
      if (id != null && id.isNotEmpty && !seen.add(id)) continue;
      if (actor.avatarUrl?.trim().isNotEmpty != true) continue;
      out.add(actor);
      if (out.length >= 4) break;
    }
    return out;
  }

  static String? _metaLeftLabel(AppLocalizations l10n, DramaListItem drama) {
    final tags =
        drama.tags?.map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ??
        const <String>[];
    final firstTag = tags.isNotEmpty ? tags.first : null;
    final episodes = drama.totalEpisodes;

    if (firstTag != null && episodes != null) {
      return '$firstTag · ${l10n.creatorDramaEpisodeCount(episodes).trim()}';
    }
    if (firstTag != null) return firstTag;
    if (episodes != null) {
      return l10n.creatorDramaEpisodeCount(episodes).trim();
    }
    return null;
  }

  static String? _creatorLabel(String? creatorName) {
    final name = creatorName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.startsWith('@') ? name : '@$name';
  }
}

class _IpAvatarGlassPill extends StatelessWidget {
  final List<DramaActorCollection> actors;
  final double? storyPerHour;

  const _IpAvatarGlassPill({required this.actors, this.storyPerHour});

  @override
  Widget build(BuildContext context) {
    const size = ContentDramaGridCard._ipAvatarSize;
    const overlap = ContentDramaGridCard._ipAvatarOverlap;
    final width = actors.isEmpty
        ? 0.0
        : size + (actors.length - 1) * (size - overlap);

    return ClipRRect(
      borderRadius: BorderRadius.circular(88),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color.fromRGBO(119, 119, 119, 0.25),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(88),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (actors.isNotEmpty)
                  SizedBox(
                    width: width,
                    height: size,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < actors.length; i++)
                          Positioned(
                            left: i * (size - overlap),
                            child: ActorRoleAvatar(
                              size: size,
                              avatarUrl: actors[i].avatarUrl,
                              actorId: actors[i].id,
                              actorName: actors[i].name,
                              ringColor: Colors.white,
                              tappable: false,
                            ),
                          ),
                      ],
                    ),
                  ),
                if (actors.isNotEmpty && storyPerHour != null)
                  const SizedBox(width: 6),
                if (storyPerHour != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        formatPowerValue(storyPerHour),
                        style: const TextStyle(
                          fontSize: 13,
                          height: 18 / 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      StoryPerHourUnitLabel(
                        iconSize: 10,
                        textStyle: TextStyle(
                          fontSize: 10,
                          height: 12 / 10,
                          letterSpacing: 0.08,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CoverStatsRow extends StatelessWidget {
  final int completeCount;
  final int likeCount;
  final double? avgRating;

  const _CoverStatsRow({
    required this.completeCount,
    required this.likeCount,
    this.avgRating,
  });

  static const _iconSize = 12.0;
  static const _textStyle = TextStyle(
    fontSize: 14,
    height: 20 / 14,
    color: StoryColors.onOverlay,
  );

  @override
  Widget build(BuildContext context) {
    final rating = avgRating;
    return Row(
      children: [
        _StatChip(
          iconAsset: _cardPlayIcon,
          label: StoryFormat.formatCount(completeCount),
        ),
        const SizedBox(width: StorySpacing.base),
        _StatChip(
          iconAsset: _cardLikeIcon,
          label: StoryFormat.formatCount(likeCount),
        ),
        if (rating != null) ...[
          const SizedBox(width: StorySpacing.base),
          _StatChip(iconAsset: _cardStarIcon, label: rating.toStringAsFixed(1)),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String iconAsset;
  final String label;

  const _StatChip({required this.iconAsset, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconAsset,
          width: _CoverStatsRow._iconSize,
          height: _CoverStatsRow._iconSize,
          colorFilter: const ColorFilter.mode(
            StoryColors.onOverlay,
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 2),
        Text(label, style: _CoverStatsRow._textStyle),
      ],
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
