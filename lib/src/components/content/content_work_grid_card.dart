import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/recommend_search_models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_format.dart';
import '../../styles/story_spacing.dart';
import '../../widgets/story_cached_image.dart';
import '../../widgets/story_card.dart';
import '../badge/content_badge.dart';
import '../theater/drama_card.dart';

const _cardLikeIcon = 'assets/drama/card_heart.svg';
const _workCardRadius = BorderRadius.all(Radius.circular(12));
const _workCardTopRadius = BorderRadius.vertical(top: Radius.circular(12));

/// 通用双列「作品卡片」。
///
/// 短视频 / 剧集内容不同，尺寸与搜索短剧 tab 的 [DramaCard] 网格卡对齐。
class ContentWorkGridCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback? onTap;

  /// When false, hides the drama [ContentBadge] on episode covers.
  final bool showContentBadge;

  const ContentWorkGridCard({
    super.key,
    required this.item,
    this.onTap,
    this.showContentBadge = false,
  });

  static const coverAspectRatio = DramaCard.gridCoverAspectRatio;
  static const infoHeight = DramaCard.gridInfoHeight;
  static const gridCrossAxisCount = 2;
  static const gridSpacing = 8.0;

  static const gridChildAspectRatio = 0.60;

  /// 网格内容区宽度（已扣除外层 padding）对应的 cell 宽/高。
  static double gridChildAspectRatioFor(
    double gridWidth, {
    double crossAxisSpacing = StorySpacing.xs,
  }) {
    return DramaCard.gridChildAspectRatioFor(
      gridWidth,
      crossAxisSpacing: crossAxisSpacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;
    final isShortVideo = item.isShortVideo;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final creator = _creatorLabel(item.creatorName);
    final coverUrl = item.posterUrl?.trim() ?? '';
    final durationSec = item.durationSec;
    final durationLabel = durationSec != null && durationSec > 0
        ? StoryFormat.formatDuration(durationSec * 1000)
        : null;

    return StoryCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: _workCardRadius,
      border: Border.all(width: 0, color: Colors.transparent),
      backgroundColor: StoryColors.cardOf(brightness),
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
            borderRadius: _workCardTopRadius,
            child: AspectRatio(
              aspectRatio: coverAspectRatio,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _CoverImage(url: coverUrl),
                  if (!isShortVideo && showContentBadge)
                    ContentBadge.positionedCardCorner(
                      badge: item.badge,
                      variant: ContentBadgeVariant.drama,
                    ),
                  if (durationLabel != null)
                    Positioned(
                      top: StorySpacing.md,
                      right: StorySpacing.md,
                      child: Text(
                        durationLabel,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w400,
                          color: StoryColors.onOverlay,
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
                    child: Row(
                      children: [
                        _CoverStat(
                          iconAsset: _cardLikeIcon,
                          label: StoryFormat.formatCount(item.likeCount ?? 0),
                          iconSize: 9,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: infoHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: isShortVideo
                  ? _ShortVideoInfo(
                      headline: _shortVideoHeadline(l10n, item),
                      creator: creator,
                      fg: fg,
                      muted: muted,
                    )
                  : _EpisodeInfo(
                      headline: _episodeHeadline(l10n, item),
                      episodeLabel: item.episodeNo != null
                          ? l10n.searchEpisodeNo(item.episodeNo!)
                          : null,
                      creator: creator,
                      fg: fg,
                      muted: muted,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static String? _creatorLabel(String? creatorName) {
    final name = creatorName?.trim();
    if (name == null || name.isEmpty) return null;
    return name.startsWith('@') ? name : '@$name';
  }

  static String _shortVideoHeadline(AppLocalizations l10n, FeedItem item) {
    final desc = item.resolvedEpisodeDescription?.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    final title = item.title?.trim() ?? '';
    if (title.isNotEmpty) return title;
    return l10n.commonUntitled;
  }

  /// Drama episode cards show [FeedItem.title]; short videos use description.
  static String _episodeHeadline(AppLocalizations l10n, FeedItem item) {
    final description = item.resolvedEpisodeDescription?.trim() ?? '';
    if (description.isNotEmpty) return description;
    return l10n.commonUntitled;
  }
}

class _ShortVideoInfo extends StatelessWidget {
  final String headline;
  final String? creator;
  final Color fg;
  final Color muted;

  const _ShortVideoInfo({
    required this.headline,
    required this.creator,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headline(text: headline, color: fg),
        const SizedBox(height: 4),
        if (creator != null)
          Text(
            creator!,
            style: TextStyle(fontSize: 11, height: 1.2, color: muted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }
}

class _EpisodeInfo extends StatelessWidget {
  final String headline;
  final String? episodeLabel;
  final String? creator;
  final Color fg;
  final Color muted;

  const _EpisodeInfo({
    required this.headline,
    required this.episodeLabel,
    required this.creator,
    required this.fg,
    required this.muted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Headline(text: headline, color: fg),
        const SizedBox(height: 4),
        Row(
          children: [
            if (episodeLabel != null)
              Expanded(
                child: Text(
                  episodeLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, height: 1.2, color: muted),
                ),
              )
            else
              const Spacer(),
            if (creator != null)
              Expanded(
                child: Text(
                  creator!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, height: 1.2, color: muted),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  final String text;
  final Color color;

  const _Headline({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: color,
      ),
    );
  }
}

class _CoverStat extends StatelessWidget {
  final String iconAsset;
  final String label;
  final double iconSize;

  const _CoverStat({
    required this.iconAsset,
    required this.label,
    this.iconSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: Center(
            child: SvgPicture.asset(
              iconAsset,
              width: iconSize,
              height: iconSize,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
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

class _CoverImage extends StatelessWidget {
  final String url;

  const _CoverImage({required this.url});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final placeholderColor = StoryColors.actorHeroBadgeBgOf(brightness);
    if (url.isEmpty) {
      return ColoredBox(color: placeholderColor);
    }
    return StoryCachedImage(imageUrl: url);
  }
}
