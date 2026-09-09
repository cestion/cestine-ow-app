import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/story_share.dart';
import '../../../components/common/story_bottom_sheet.dart';
import '../../../components/common/story_toast.dart';
import '../../../controller/engagement_state.dart';
import 'feed_engagement_callbacks.dart';
import '../../../controller/follow_state.dart';
import '../../../provider/app_providers.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../routes/route_names.dart';
import '../../../utils/auth_navigation.dart';
import '../../../utils/story_haptics.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_format.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../widgets/error_handler.dart';
import '../../../widgets/story_avatar.dart';
import '../drama_detail/drama_detail_sheet.dart';
import '../video_comment/comment_bottom_sheet.dart';
import 'video_feed_episode_bar.dart';
import '../../../foundation/navigator.dart';

class VideoFeedRightActions extends ConsumerWidget {
  static double _creatorBlockHeight({
    required bool hasCreatorIdentity,
    required bool canFollow,
  }) {
    final badgeOverflow = hasCreatorIdentity && canFollow
        ? _FeedCreatorAvatarFollow.badgeOverflowHeight
        : 0;
    return StorySizes.avatarMedium + badgeOverflow;
  }

  /// Unified identity / metadata for the rail. Creator fields are already
  /// resolved detail-over-card by the [FeedPlayableItem] adapters — the rail
  /// no longer juggles separate creator overrides + drama fallbacks.
  final FeedPlayableItem item;

  /// Optional work id override for share / identity helpers. Episode engagement
  /// (like / favorite / comment counts) always keys off [item.dramaId] +
  /// [DramaPlayResponse.episodeId] — same as [_engagementKey].
  final String? favoriteEngagementId;

  /// Share title fallback (e.g. router-args title while detail is loading).
  final String? shareTitle;

  /// Episode / short-video copy for share text. Prefer this over
  /// [FeedPlayableItem.description] when detail overlays the whole-drama
  /// synopsis onto the playable adapter.
  final String? shareDescription;
  final DramaPlayResponse? play;

  /// Unified engagement callbacks for like / favorite / comment interactions.
  final FeedEngagementCallbacks engagement;

  /// 详情弹层中选择剧集时回调（把 feed 切换到该集）。
  final ValueChanged<int>? onSelectEpisode;

  /// Holds auto-advance while the comment / drama overlay is open.
  final Future<T> Function<T>(Future<T> Function() action)? holdAutoAdvance;

  /// When set, comment tap uses this instead of the player comment sheet.
  final VoidCallback? onComment;

  /// Notifies the feed when a root-navigator sheet opens / closes so the
  /// player surface can collapse for short-video comment overlays.
  final ValueNotifier<bool>? playerSheetOpen;

  /// Optional sheet height for player band flush alignment.
  final ValueNotifier<double>? sheetHeightNotifier;

  /// Match [VideoFeedEpisodeBar.pinProgressToBottom] for bottom alignment.
  final bool pinProgressToBottom;

  /// Match [VideoFeedEpisodeBar.showEpisodeCta] for bottom chrome height.
  final bool showEpisodeCta;

  /// Hold auto-advance while system share is presented.
  final Future<void> Function(Future<void> Function() share)? aroundShare;

  /// Card-level engagement seeds (recommend feed item) when [play] is absent.
  final int? cardLikeCount;
  final bool? cardLikedByMe;
  final int? cardCommentCount;
  final bool? cardFavoritedByMe;
  final int? cardFavoriteCount;

  const VideoFeedRightActions({
    super.key,
    required this.item,
    this.favoriteEngagementId,
    this.shareTitle,
    this.shareDescription,
    required this.play,
    required this.engagement,
    this.onSelectEpisode,
    this.holdAutoAdvance,
    this.onComment,
    this.playerSheetOpen,
    this.sheetHeightNotifier,
    this.pinProgressToBottom = false,
    this.showEpisodeCta = true,
    this.aroundShare,
    this.cardLikeCount,
    this.cardLikedByMe,
    this.cardCommentCount,
    this.cardFavoritedByMe,
    this.cardFavoriteCount,
  });

  String? get _shareDescription {
    final fromPlay = play?.description?.trim();
    if (fromPlay != null && fromPlay.isNotEmpty) return fromPlay;
    final fromOverride = shareDescription?.trim();
    if (fromOverride != null && fromOverride.isNotEmpty) return fromOverride;
    return item.description?.trim();
  }

  EpisodeEngagementKey? get _engagementKey =>
      EpisodeEngagementKey.tryForEpisode(
        dramaId: item.dramaId,
        episodeId: play?.episodeId ?? item.episodeId,
        episodeNo: play?.episodeNo ?? item.episodeNo,
      );

  T? _engagementField<T>(T? card, T? fromPlay, T? fromStore) {
    // Shared store is authoritative once seeded / mutated (toggle, detail page,
    // comment sheet). Card/play are fallbacks only while the store is cold.
    return fromStore ?? fromPlay ?? card;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = _engagementKey;
    final epEng = key == null
        ? const EpisodeEngagementState()
        : ref.watch(episodeEngagementProvider(key));

    final likeCount = _engagementField(
      cardLikeCount,
      play?.likeCount,
      epEng.likeCount,
    );
    final commentCount = _engagementField(
      cardCommentCount,
      play?.commentCount,
      epEng.commentCount,
    );
    final favoriteCount = _engagementField(
      cardFavoriteCount,
      play?.favoriteCount,
      epEng.favoriteCount,
    );
    final likedByMe =
        _engagementField(cardLikedByMe, play?.likedByMe, epEng.likedByMe) ??
        false;
    final favoritedByMe =
        _engagementField(
          cardFavoritedByMe,
          play?.favoritedByMe,
          epEng.favoritedByMe,
        ) ??
        false;
    final creatorName = item.creatorName?.trim() ?? '';
    final creatorAvatar = item.creatorAvatarUrl?.trim();
    final creatorUserId = item.creatorUserId?.trim() ?? '';
    final myUserId = ref.watch(
      authControllerProvider.select((c) => c.userId?.trim() ?? ''),
    );
    final canFollow = creatorUserId.isNotEmpty && creatorUserId != myUserId;
    // Wait for a stable creator identity before painting StampIdenticon /
    // Stamp CDN — a partial DramaDetail seed (no userId) used to flash the
    // generic mosaic then swap to the user-seeded one.
    final hasCreatorIdentity =
        creatorUserId.isNotEmpty ||
        resolveCustomAvatarUrl(creatorAvatar) != null;

    // Match [VideoFeedBottomInfo] so the share action bottom aligns with
    // the synopsis / intro block above the episode bar.
    final bottomOffset =
        VideoFeedEpisodeBar.contentHeightOf(
          context,
          pinProgressToBottom: pinProgressToBottom,
          showEpisodeCta: showEpisodeCta,
        ) +
        StorySpacing.xs;

    final rail = Positioned(
      right: StorySizes.videoFeedRailRightInset,
      bottom: bottomOffset,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: StorySizes.videoFeedRailItemGap + 2,
            ),
            child: SizedBox(
              width: StorySizes.videoFeedRailWidth,
              height: _creatorBlockHeight(
                hasCreatorIdentity: hasCreatorIdentity,
                canFollow: canFollow,
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: hasCreatorIdentity
                    ? _FeedCreatorAvatarFollow(
                        key: ValueKey(
                          creatorUserId.isEmpty ? item.dramaId : creatorUserId,
                        ),
                        imageUrl:
                            (creatorAvatar != null && creatorAvatar.isNotEmpty)
                            ? creatorAvatar
                            : null,
                        userId: creatorUserId.isEmpty ? null : creatorUserId,
                        fallbackText: creatorName.isNotEmpty
                            ? creatorName
                            : null,
                        enableFollow: canFollow,
                        onOpenProfile: () {
                          if (creatorUserId.isEmpty || !context.mounted) {
                            return;
                          }
                          context.storyPush(RouteNames.publicProfile, arguments: {'userId': creatorUserId});
                        },
                      )
                    : SizedBox(
                        width: StorySizes.avatarMedium,
                        height: StorySizes.avatarMedium,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: StoryColors.onOverlay.withValues(alpha: 0.2),
                            border: Border.all(
                              color: StoryColors.onOverlay,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ),
          _VideoFeedRailAction(
            svgAsset: likedByMe
                ? 'assets/drama/player_like_s.svg'
                : 'assets/drama/player_like.svg',
            label: StoryFormat.formatCount(likeCount ?? 0),
            preserveSvgColors: likedByMe,
            onTap: () async {
              if (!await ensureLoggedInOrRedirect(context, ref)) return;
              final success = await engagement.onLike();
              if (success && context.mounted) {
                final newLiked = !likedByMe;
                StoryToast.success(
                  context,
                  newLiked
                      ? context.l10n.dramaLiked
                      : context.l10n.dramaUnliked,
                );
              } else if (!success && context.mounted) {
                // 失败提示（如拉黑关系中无法点赞）。
                final key = _engagementKey;
                final err = key == null
                    ? null
                    : ref.read(episodeEngagementProvider(key)).lastError;
                if (err != null) {
                  StoryToast.error(
                    context,
                    context.l10nError(err),
                    rootOverlay: true,
                  );
                }
              }
            },
          ),
          const SizedBox(height: StorySizes.videoFeedRailItemGap),
          _VideoFeedRailAction(
            svgAsset: 'assets/drama/player_comment.svg',
            label: StoryFormat.formatCount(commentCount ?? 0),
            onTap: () {
              if (onComment != null) {
                onComment!();
                return;
              }
              unawaited(_showCommentSheet(context, ref));
            },
          ),
          const SizedBox(height: StorySizes.videoFeedRailItemGap),
          _VideoFeedRailAction(
            svgAsset: favoritedByMe
                ? 'assets/drama/player_favorite_s.svg'
                : 'assets/drama/player_favorite.svg',
            label: StoryFormat.formatCount(favoriteCount ?? 0),
            preserveSvgColors: favoritedByMe,
            onTap: () async {
              if (!await ensureLoggedInOrRedirect(context, ref)) return;
              final success = await engagement.onFavorite();
              if (success && context.mounted) {
                final newFavorited = !favoritedByMe;
                StoryToast.success(
                  context,
                  newFavorited
                      ? context.l10n.dramaFavorited
                      : context.l10n.dramaUnfavorited,
                );
              } else if (!success && context.mounted) {
                // 失败提示（如拉黑关系中无法收藏）。
                final key = _engagementKey;
                final err = key == null
                    ? null
                    : ref.read(episodeEngagementProvider(key)).lastError;
                if (err != null) {
                  StoryToast.error(
                    context,
                    context.l10nError(err),
                    rootOverlay: true,
                  );
                }
              }
            },
          ),
          const SizedBox(height: StorySizes.videoFeedRailItemGap),
          _VideoFeedRailAction(
            svgAsset: 'assets/drama/player_share.svg',
            label: context.l10n.playerShare,
            onTap: () => StoryShare.sharePlayable(
              context: context,
              contentType: item.contentType,
              dramaId: item.dramaId,
              episodeId: item.episodeId ?? play?.episodeId,
              title: item.title.isNotEmpty ? item.title : shareTitle,
              episodeNo: play?.episodeNo ?? item.episodeNo,
              description: _shareDescription,
              aroundShare: aroundShare,
            ),
          ),
        ],
      ),
    );
    return rail;
  }

  Future<void> _showCommentSheet(BuildContext context, WidgetRef ref) async {
    final key = _engagementKey;
    if (key != null) {
      // Seed so the store's post-increment starts from the real total.
      ref
          .read(episodeEngagementProvider(key).notifier)
          .seed(commentCount: play?.commentCount ?? cardCommentCount);
    }

    var shortVideoSheet = false;
    Future<int?> open() async {
      if (item.contentType.isShortVideo) {
        shortVideoSheet = true;
        // Short video: comments-only sheet (no drama / characters tabs).
        final sheet = playerSheetOpen;
        final managedByHold = holdAutoAdvance != null;
        if (!managedByHold) sheet?.value = true;
        try {
          await StoryBottomSheet.showCommentSheet<void>(
            context: context,
            builder: (_) => CommentBottomSheet(
              dramaId: item.dramaId,
              episodeId: play?.episodeId ?? item.episodeId,
              episodeNo: play?.episodeNo ?? item.episodeNo,
              commentCount: play?.commentCount ?? cardCommentCount ?? 0,
              onCommentCountChanged: (_) => engagement.onCommentPosted(),
              sheetHeightNotifier: sheetHeightNotifier,
            ),
          );
        } finally {
          if (!managedByHold) sheet?.value = false;
        }
        return null;
      }
      // Short drama: full overlay with 评论 / 短剧 / 角色 tabs.
      final sheet = playerSheetOpen;
      final managedByHold = holdAutoAdvance != null;
      if (!managedByHold) sheet?.value = true;
      try {
        return await DramaDetailSheet.show(
          context: context,
          dramaId: item.dramaId,
          coverUrl: item.coverUrl,
          initialTab: DramaDetailSheetTab.comments,
          episodeNo: play?.episodeNo ?? item.episodeNo,
          episodeId: play?.episodeId ?? item.episodeId,
          contentType: item.contentType,
          sheetHeightNotifier: sheetHeightNotifier,
        );
      } finally {
        if (!managedByHold) sheet?.value = false;
      }
    }

    final hold = holdAutoAdvance;
    final selected = hold == null ? await open() : await hold(open);
    if (!context.mounted) return;
    if (selected != null) {
      onSelectEpisode?.call(selected);
      return;
    }
    // Short-video sheet bumps via onCommentCountChanged; drama sheet syncs on
    // dismiss so the rail picks up any comment-count changes from the store.
    if (shortVideoSheet) return;
    engagement.onCommentPosted();
  }
}

class _FeedCreatorAvatarFollow extends ConsumerStatefulWidget {
  static const double badgeSize = 18;
  static const double badgeOverflowHeight = badgeSize / 2;

  final String? imageUrl;
  final String? userId;
  final String? fallbackText;
  final bool enableFollow;
  final VoidCallback onOpenProfile;

  const _FeedCreatorAvatarFollow({
    super.key,
    required this.imageUrl,
    required this.userId,
    required this.fallbackText,
    required this.enableFollow,
    required this.onOpenProfile,
  });

  @override
  ConsumerState<_FeedCreatorAvatarFollow> createState() =>
      _FeedCreatorAvatarFollowState();
}

enum _FollowBadgePhase { add, added, hidden }

class _FeedCreatorAvatarFollowState
    extends ConsumerState<_FeedCreatorAvatarFollow> {
  static const Duration _addedVisibleDuration = Duration(seconds: 2);

  _FollowBadgePhase? _localPhase;
  Timer? _hideTimer;

  @override
  void didUpdateWidget(covariant _FeedCreatorAvatarFollow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        oldWidget.enableFollow != widget.enableFollow) {
      _hideTimer?.cancel();
      _localPhase = null;
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  _FollowBadgePhase _phaseFor(FollowState follow, {required bool loggedIn}) {
    if (!widget.enableFollow) return _FollowBadgePhase.hidden;
    if (_localPhase != null) return _localPhase!;
    if (loggedIn && follow.isFollowing == null) {
      return _FollowBadgePhase.hidden;
    }
    if (follow.isFollowing == true) return _FollowBadgePhase.hidden;
    return _FollowBadgePhase.add;
  }

  Future<void> _onFollowTap() async {
    final id = widget.userId;
    if (id == null || id.isEmpty) return;
    final wasLoggedIn = ref.read(authControllerProvider).isLoggedIn;
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;

    final notifier = ref.read(followControllerProvider(id).notifier);
    await notifier.ensureLoaded();
    if (!mounted) return;

    final alreadyFollowing =
        ref.read(followControllerProvider(id)).isFollowing ?? false;
    // Guest saw "+" ; after login the relation may already be following.
    if (!wasLoggedIn && alreadyFollowing) {
      setState(() => _localPhase = _FollowBadgePhase.hidden);
      return;
    }
    if (alreadyFollowing) return;

    // Fire on tap — waiting for the API makes the haptic feel missing.
    // StoryHaptics also hits a native peek sound so feedback works while
    // AVPlayer holds the movie-playback audio session.
    unawaited(StoryHaptics.impact());

    final result = await notifier.toggle();
    if (!mounted) return;
    if (result == null) return;
    if (result.isFailure) {
      handleApiError(result.errorOrNull!, ctx: context);
      return;
    }

    setState(() => _localPhase = _FollowBadgePhase.added);
    _hideTimer?.cancel();
    _hideTimer = Timer(_addedVisibleDuration, () {
      if (!mounted) return;
      setState(() => _localPhase = _FollowBadgePhase.hidden);
    });
    StoryToast.success(context, context.l10n.playerFollowed);
  }

  Future<void> _onUnfollowTap() async {
    final id = widget.userId;
    if (id == null || id.isEmpty) return;
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;

    final result = await ref
        .read(followControllerProvider(id).notifier)
        .toggle();
    if (!mounted) return;
    if (result == null) return;
    if (result.isFailure) {
      handleApiError(result.errorOrNull!, ctx: context);
      return;
    }
    _hideTimer?.cancel();
    setState(() => _localPhase = _FollowBadgePhase.add);
    StoryToast.success(context, context.l10n.playerUnfollowed);
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.userId;
    final loggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    final followIsFollowing = (id != null && id.isNotEmpty)
        ? ref.watch(followControllerProvider(id).select((s) => s.isFollowing))
        : null;
    final follow = FollowState(isFollowing: followIsFollowing);
    final phase = _phaseFor(follow, loggedIn: loggedIn);
    final showBadge = phase != _FollowBadgePhase.hidden;
    final badgeAsset = phase == _FollowBadgePhase.added
        ? 'assets/common/added.svg'
        : 'assets/common/add.svg';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: StorySizes.avatarMedium,
          height:
              StorySizes.avatarMedium +
              (widget.enableFollow
                  ? _FeedCreatorAvatarFollow.badgeOverflowHeight
                  : 0),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              GestureDetector(
                onTap: widget.onOpenProfile,
                behavior: HitTestBehavior.opaque,
                child: StoryAvatar(
                  imageUrl: widget.imageUrl,
                  userId: widget.userId,
                  fallbackText: widget.fallbackText,
                  size: StorySizes.avatarMedium,
                  ringColor: StoryColors.onOverlay,
                ),
              ),
              if (showBadge)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: phase == _FollowBadgePhase.added
                          ? _onUnfollowTap
                          : _onFollowTap,
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.asset(
                        badgeAsset,
                        width: _FeedCreatorAvatarFollow.badgeSize,
                        height: _FeedCreatorAvatarFollow.badgeSize,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VideoFeedRailAction extends StatelessWidget {
  final String svgAsset;
  final String label;
  final bool preserveSvgColors;
  final VoidCallback? onTap;

  const _VideoFeedRailAction({
    required this.svgAsset,
    required this.label,
    this.preserveSvgColors = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final icon = preserveSvgColors
        ? SvgPicture.asset(
            svgAsset,
            width: StorySizes.videoFeedRailIconSize,
            height: StorySizes.videoFeedRailIconSize,
          )
        : SvgPicture.asset(
            svgAsset,
            width: StorySizes.videoFeedRailIconSize,
            height: StorySizes.videoFeedRailIconSize,
            colorFilter: const ColorFilter.mode(
              StoryColors.onOverlay,
              BlendMode.srcIn,
            ),
          );
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: StorySizes.videoFeedRailHitSize,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            Transform.translate(
              offset: const Offset(0, -1),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: StoryTextStyles.labelSmall(
                  color: StoryColors.onOverlay,
                ).copyWith(fontSize: 11, height: 1.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
