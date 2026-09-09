import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../controller/engagement_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../provider/app_providers.dart';
import '../../../utils/auth_navigation.dart';
import '../../../components/components.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_format.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

/// Like, bookmark/favorite, and share action bar for drama detail.
///
/// Reads and mutates the shared engagement store — no local optimistic copy,
/// so any other live page (video feed, theater) stays in sync automatically.
/// Constructor values act as display fallbacks / store seeds only.
class DramaEngagementBar extends ConsumerWidget {
  final String dramaId;
  final VoidCallback? onShare;
  final String? episodeApiId;
  final int episodeNo;
  final int? likeCount;
  final int? favoriteCount;
  final double? avgRating;
  final bool likedByMe;
  final bool favoritedByMe;
  final bool ratedByMe;
  final VoidCallback? onRate;

  const DramaEngagementBar({
    super.key,
    required this.dramaId,
    this.onShare,
    this.episodeApiId,
    this.episodeNo = 1,
    this.likeCount,
    this.favoriteCount,
    this.avgRating,
    this.likedByMe = false,
    this.favoritedByMe = false,
    this.ratedByMe = false,
    this.onRate,
  });

  EpisodeEngagementKey? get _episodeKey {
    final episodeId = episodeApiId;
    if (episodeId == null) return null;
    return EpisodeEngagementKey.tryForEpisode(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
    );
  }

  Future<void> _handleLike(BuildContext context, WidgetRef ref) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!context.mounted) return;

    final key = _episodeKey;
    if (key == null) {
      StoryToast.error(context, context.l10n.videoNotReady);
      return;
    }

    final notifier = ref.read(episodeEngagementProvider(key).notifier);
    notifier.applyVisible(likedByMe: likedByMe, likeCount: likeCount);
    final result = await notifier.toggleLike(
      episodeNo: episodeNo,
      likedByMeBaseline: likedByMe,
    );
    if (result != null && result.isFailure && context.mounted) {
      StoryToast.error(context, context.l10nError(result.errorOrNull!));
    }
  }

  Future<void> _handleFavorite(BuildContext context, WidgetRef ref) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!context.mounted) return;

    final notifier = ref.read(dramaEngagementProvider(dramaId).notifier);
    notifier.applyVisible(
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
    );
    final result = await notifier.toggleFavorite(
      episodeNo: episodeNo,
      favoritedByMeBaseline: favoritedByMe,
    );
    if (result != null && result.isFailure && context.mounted) {
      StoryToast.error(context, context.l10nError(result.errorOrNull!));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final l10n = context.l10n;

    final dramaEng = ref.watch(dramaEngagementProvider(dramaId));
    final key = _episodeKey;
    final epEng = key == null
        ? const EpisodeEngagementState()
        : ref.watch(episodeEngagementProvider(key));

    final effectiveLiked = epEng.likedByMe ?? likedByMe;
    final effectiveLikeCount = epEng.likeCount ?? likeCount ?? 0;
    final effectiveFavorited = dramaEng.favoritedByMe ?? favoritedByMe;
    final effectiveFavoriteCount = dramaEng.favoriteCount ?? favoriteCount ?? 0;
    final effectiveAvgRating = dramaEng.avgRating ?? avgRating;
    final effectiveRatedByMe = dramaEng.ratedByMe || ratedByMe;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: StorySpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _ActionButton(
            svgAsset: effectiveLiked
                ? 'assets/drama/detail_like_s.svg'
                : 'assets/drama/detail_like.svg',
            label: StoryFormat.formatCount(effectiveLikeCount),
            color: effectiveLiked ? StoryColors.destructive : null,
            preserveSvgColors: effectiveLiked,
            brightness: brightness,
            onTap: () => _handleLike(context, ref),
          ),
          _ActionButton(
            svgAsset: effectiveFavorited
                ? 'assets/drama/detail_favorite_s.svg'
                : 'assets/drama/detail_favorite.svg',
            label: StoryFormat.formatCount(effectiveFavoriteCount),
            color: effectiveFavorited ? StoryColors.warning : null,
            preserveSvgColors: effectiveFavorited,
            brightness: brightness,
            onTap: () => _handleFavorite(context, ref),
          ),
          _ActionButton(
            svgAsset: effectiveRatedByMe
                ? 'assets/drama/detail_star_s.svg'
                : 'assets/drama/detail_star.svg',
            label: effectiveAvgRating != null
                ? effectiveAvgRating.toStringAsFixed(1)
                : l10n.dramaRatingLabel,
            color: effectiveRatedByMe ? StoryColors.warning : null,
            preserveSvgColors: effectiveRatedByMe,
            brightness: brightness,
            onTap: onRate,
          ),
          _ActionButton(
            svgAsset: 'assets/drama/detail_share.svg',
            brightness: brightness,
            onTap: onShare,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String? svgAsset;
  final String? label;
  final Color? color;
  final bool preserveSvgColors;
  final Brightness brightness;
  final VoidCallback? onTap;

  const _ActionButton({
    this.svgAsset,
    this.label,
    this.color,
    this.preserveSvgColors = false,
    required this.brightness,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = color ?? StoryColors.mutedForegroundOf(brightness);
    final hasLabel = label != null && label!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: StorySpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (svgAsset != null)
              SizedBox(
                width: 20,
                height: 20,
                child: preserveSvgColors
                    ? SvgPicture.asset(svgAsset!, width: 20, height: 20)
                    : SvgPicture.asset(
                        svgAsset!,
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(fgColor, BlendMode.srcIn),
                      ),
              ),
            if (hasLabel) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: StoryTextStyles.caption(
                  color: fgColor,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
