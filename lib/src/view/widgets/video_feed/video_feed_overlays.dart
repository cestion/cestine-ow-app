import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/player_long_press_menu.dart';
import '../../../components/common/story_toast.dart';
import '../../../controller/engagement_state.dart';
import '../../../controller/video_feed_controller.dart';
import '../../../core/story_constants.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/feed_playable_item.dart';
import '../../../model/recommend_feed_model.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/auth_navigation.dart';
import '../../report_page.dart';
import '../drama_detail/drama_detail_sheet.dart';
import 'video_feed_widgets.dart';
import '../../../foundation/navigator.dart';

/// Status overlay layer for the video feed — assembles header, bottom info,
/// right actions, center play button. Playback failures use a toast with retry
/// instead of a full-screen blocking overlay.
class VideoFeedOverlays extends ConsumerStatefulWidget {
  final VideoFeedController controller;
  final int episodeNo;
  final bool isLiveChrome;
  final String title;
  final bool isFullscreen;
  final VoidCallback? onEpisodeSelector;
  final VoidCallback? onToggleFullscreen;
  final VoidCallback? onTitleTap;
  final VoidCallback? onBack;

  /// 详情弹层选择剧集后切换 feed 到该集。
  final ValueChanged<int>? onSelectEpisode;

  /// Comment / drama sheet: collapse the player into the top band.
  final Future<T> Function<T>(Future<T> Function() action)?
  holdWithCollapsedPlayer;

  /// Reports sheet height for player band flush alignment.
  final ValueNotifier<double>? sheetHeightNotifier;

  /// Hold auto-advance while system share is open.
  final Future<void> Function(Future<void> Function() share)? aroundShare;

  /// Open characters tab of the drama sheet (collapsed player).
  final VoidCallback? onOpenCharacters;

  const VideoFeedOverlays({
    super.key,
    required this.controller,
    required this.episodeNo,
    required this.isLiveChrome,
    required this.title,
    this.isFullscreen = false,
    this.onEpisodeSelector,
    this.onToggleFullscreen,
    this.onTitleTap,
    this.onBack,
    this.onSelectEpisode,
    this.holdWithCollapsedPlayer,
    this.sheetHeightNotifier,
    this.aroundShare,
    this.onOpenCharacters,
  });

  @override
  ConsumerState<VideoFeedOverlays> createState() => _VideoFeedOverlaysState();
}

class _VideoFeedOverlaysState extends ConsumerState<VideoFeedOverlays> {
  static final ValueNotifier<Duration> _idlePosition = ValueNotifier<Duration>(
    Duration.zero,
  );

  FeedPlaybackStatus? _lastStatus;
  bool _chromeHidden = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowErrorToast();
  }

  @override
  void didUpdateWidget(covariant VideoFeedOverlays oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeShowErrorToast();
  }

  void _maybeShowErrorToast() {
    final status = widget.controller.status;
    final becameError =
        status == FeedPlaybackStatus.error &&
        _lastStatus != FeedPlaybackStatus.error;
    _lastStatus = status;
    if (!becameError) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.controller.status != FeedPlaybackStatus.error) return;
      final l10n = context.l10n;
      StoryToast.error(
        context,
        l10n.playerPlayFailed,
        actionLabel: l10n.dramaDetailRetry,
        onAction: widget.controller.retry,
        rootOverlay: true,
      );
    });
  }

  Future<void> _onNotInterested() async {
    final l10n = context.l10n;
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;

    final episodeId = widget.controller.currentPlay?.episodeId?.trim();
    if (episodeId == null || episodeId.isEmpty) {
      StoryToast.error(context, l10n.playerPlayFailed);
      return;
    }

    final result = await ref
        .read(recommendRepositoryProvider)
        .dislike(episodeId);
    if (!mounted) return;
    if (result.isFailure) {
      final msg = result.errorOrNull?.userMessage ?? l10n.playerPlayFailed;
      StoryToast.error(context, msg);
      return;
    }
    StoryToast.success(context, l10n.playerNotInterestedDone);
  }

  void _showLongPressMenu() {
    final controller = widget.controller;
    // 自己的作品不显示「不感兴趣」与「举报」。
    final creatorId = controller.dramaDetail?.userId?.trim() ?? '';
    final myId = ref.read(authControllerProvider).userId?.trim() ?? '';
    final isOwnWork = creatorId.isNotEmpty && creatorId == myId;
    unawaited(() async {
      controller.beginOverlayHold();
      var reported = false;
      try {
        final action = await PlayerLongPressMenu.show(
          context: context,
          dramaId: controller.dramaId,
          episodeNo: controller.currentEpisodeNo,
          episodeId: controller.currentPlay?.episodeId,
          contentType: controller.contentType,
          creatorId: controller.dramaDetail?.userId,
          creatorName: controller.dramaDetail?.creatorName,
          creatorAvatarUrl: controller.dramaDetail?.creatorAvatarUrl,
          contentTitle: controller.dramaDetail?.title ?? widget.title,
          contentCoverUrl: controller.dramaDetail?.coverUrl,
          autoPlayEnabled: controller.autoPlayEnabled,
          onAutoPlayChanged: (next) {
            controller.autoPlayEnabled = next;
          },
          onClearScreen: () {
            if (!mounted) return;
            setState(() => _chromeHidden = true);
          },
          onNotInterested: () {
            unawaited(_onNotInterested());
          },
          isOwnWork: isOwnWork,
        );
        if (action != PlayerLongPressMenu.reportAction) return;
        if (!mounted) return;
        if (!await ensureLoggedInOrRedirect(context, ref)) return;
        if (!mounted) return;
        // Pause/resume comes from PlaybackAuthRouteObserver (/report) —
        // same cover→pause / reveal→resume path as other full-screen routes.
        // Overlay hold still skips RouteAware unmount so surfaces stay up.
        final result = await context.storyPushForResult<Object?>(RouteNames.report,
          arguments: <String, dynamic>{
            'dramaId': controller.dramaId,
            'episodeNo': controller.currentEpisodeNo,
            'episodeId': controller.currentPlay?.episodeId,
            'contentType': controller.contentType.apiValue,
            'userId': controller.dramaDetail?.userId,
            'targetDisplayName': controller.dramaDetail?.creatorName,
            'targetAvatarUrl': controller.dramaDetail?.creatorAvatarUrl,
            'contentTitle': controller.dramaDetail?.title ?? widget.title,
            'contentCoverUrl': controller.dramaDetail?.coverUrl,
          });
        reported = isReportPageSuccess(result);
      } finally {
        controller.endOverlayHold(advanceIfCompleted: !reported);
      }
      if (!reported || !mounted) return;
      final next = controller.currentEpisodeNo + 1;
      if (next > controller.totalEpisodes) return;
      widget.onSelectEpisode?.call(next);
    }());
  }

  /// Double-tap like: heart burst is owned by [FeedGestureOverlay]; here we
  /// only ensure auth and like when not already liked (never unlike).
  Future<void> _onDoubleTapLike() async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!mounted) return;

    final controller = widget.controller;
    final epNo = widget.episodeNo;
    final play = controller.playForEpisode(epNo);
    final episodeId = play?.episodeId;
    if (episodeId == null || episodeId.isEmpty) return;

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: controller.dramaId,
      episodeId: episodeId,
      episodeNo: play?.episodeNo ?? epNo,
    );
    final eng = ref.read(episodeEngagementProvider(key));
    final liked = eng.likedByMe ?? play?.likedByMe ?? false;
    if (liked) return;

    final success = await controller.toggleLike(episodeNo: epNo);
    if (!success && mounted) {
      final err = ref.read(episodeEngagementProvider(key)).lastError;
      if (err != null) {
        StoryToast.error(context, context.l10nError(err), rootOverlay: true);
      }
    }
  }

  String? _creatorHandle(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  void _openCreatorProfile(String userId) {
    if (!mounted || userId.isEmpty) return;
    context.storyPush(RouteNames.publicProfile, arguments: {'userId': userId});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final status = controller.status;
    final epNo = widget.episodeNo;
    final isLiveChrome = widget.isLiveChrome;
    final total = controller.episodeCount;
    final pagePlay = controller.playForEpisode(epNo);
    final chromeSeed = controller.engagementChromeSeedFor(epNo);
    final progressPosition = isLiveChrome
        ? controller.positionNotifier
        : _idlePosition;
    final progressDuration = isLiveChrome ? controller.duration : Duration.zero;

    final backgroundGesture = FeedGestureOverlay(
      chromeHidden: _chromeHidden,
      onEnterClearScreen: () {
        if (!mounted || _chromeHidden) return;
        setState(() => _chromeHidden = true);
      },
      onExitClearScreen: () {
        if (!mounted || !_chromeHidden) return;
        setState(() => _chromeHidden = false);
      },
      onTap: isLiveChrome ? controller.togglePlayPause : () {},
      onLongPress: _showLongPressMenu,
      onDoubleTapLike: _onDoubleTapLike,
    );

    Widget? centerPlayButton() {
      if (!isLiveChrome) return null;
      // Leaf rebuild on pause — PageView must not watch isPlaying.
      return ListenableBuilder(
        listenable: Listenable.merge([
          controller.playingListenable,
          controller.userPausedListenable,
        ]),
        builder: (context, _) {
          final show =
              !controller.playingListenable.value &&
              (controller.userPausedListenable.value ||
                  controller.status == FeedPlaybackStatus.completed);
          if (!show) return const SizedBox.shrink();
          return FeedPausedPlayOverlay(
            visible: true,
            onTap: controller.togglePlayPause,
          );
        },
      );
    }

    if (_chromeHidden) {
      return Stack(
        fit: StackFit.expand,
        children: [
          backgroundGesture,
          VideoFeedEpisodeBar(
            totalEpisodes: total,
            positionNotifier: progressPosition,
            duration: progressDuration,
            onSeek: isLiveChrome ? controller.seekTo : (_) {},
            showEpisodeCta: false,
            showFullscreen: false,
          ),
          VideoFeedExitFullscreenButton(
            onTap: () => setState(() => _chromeHidden = false),
          ),
          ?centerPlayButton(),
        ],
      );
    }

    if (widget.isFullscreen) {
      final isShortVideo = controller.isShortVideo;
      final showEpisodeCta = !isShortVideo;
      return Stack(
        fit: StackFit.expand,
        children: [
          backgroundGesture,
          VideoFeedHeaderOverlay(
            episodeNo: epNo,
            totalEpisodes: total,
            title: widget.title,
            onEpisodeTap: !isShortVideo ? widget.onEpisodeSelector : null,
            onBack: widget.onBack,
            showEpisodeLabel: !isShortVideo,
          ),
          ?centerPlayButton(),
          if (isLiveChrome && status == FeedPlaybackStatus.buffering)
            const Center(
              child: SizedBox(
                width: StorySizes.loadingSmall,
                height: StorySizes.loadingSmall,
                child: CircularProgressIndicator(
                  strokeWidth: StorySizes.loadingStroke,
                  color: StoryColors.onOverlay,
                ),
              ),
            ),
          VideoFeedEpisodeBar(
            totalEpisodes: total,
            positionNotifier: progressPosition,
            duration: progressDuration,
            onSeek: isLiveChrome ? controller.seekTo : (_) {},
            onEpisodeSelector: showEpisodeCta ? widget.onEpisodeSelector : null,
            onFullscreen: widget.onToggleFullscreen,
            isFullscreen: true,
            // Exit control kept while already fullscreen (enter is removed
            // from portrait chrome for drama + short video).
            showEpisodeCta: showEpisodeCta,
          ),
        ],
      );
    }

    final drama = controller.dramaDetail;
    final railActors = RecommendFeedActor.forRail(roles: drama?.roles);
    final isShortVideo = controller.isShortVideo;
    // Short drama: keep episode CTA, hide enter-fullscreen.
    // Short video: progress only (no episode strip / fullscreen).
    final showEpisodeCta = !isShortVideo;
    const showFullscreen = false;
    final creatorHandle = isShortVideo
        ? _creatorHandle(drama?.creatorName)
        : null;
    // Match the right-rail avatar: only [DramaDetail.userId] / seeded creator.
    // Do not fall back to [DramaPlayResponse.userId] — that can be the viewer
    // and would open self-profile without a back affordance.
    final creatorUserId = drama?.userId?.trim() ?? '';
    final onTitleTap = isShortVideo
        ? (creatorUserId.isEmpty
              ? null
              : () => _openCreatorProfile(creatorUserId))
        : widget.onTitleTap;
    // Short dramas must show the active episode description. Passing an empty
    // string while its play payload is loading deliberately prevents
    // VideoFeedBottomInfo from falling back to the whole-drama synopsis.
    final episodeSynopsis = isShortVideo ? null : (pagePlay?.description ?? '');

    // Resolve the rail identity once: drama detail wins (now carrying the
    // work id even when arg-seeded), then the play payload (identity only —
    // title / creator / cover are not on the play response), then a minimal
    // controller-scoped item while detail is still loading.
    final railItem =
        drama?.toPlayable(
          episodeNo: epNo,
          episodeId: pagePlay?.episodeId,
          contentType: controller.contentType,
        ) ??
        pagePlay?.toPlayable(
          title: widget.title,
          contentType: controller.contentType,
        ) ??
        FeedPlayableItem.basic(
          dramaId: controller.dramaId,
          episodeNo: epNo,
          title: widget.title,
          contentType: controller.contentType,
        );

    return Stack(
      fit: StackFit.expand,
      children: [
        backgroundGesture,
        VideoFeedHeaderOverlay(
          episodeNo: epNo,
          totalEpisodes: total,
          title: widget.title,
          onEpisodeTap: !isShortVideo ? widget.onEpisodeSelector : null,
          onBack: widget.onBack,
          showEpisodeLabel: !isShortVideo,
        ),
        VideoFeedBottomInfo(
          drama: drama,
          currentEpisodeNo: epNo,
          showRoles: false,
          showEpisodeCta: showEpisodeCta,
          displayTitle: creatorHandle,
          synopsis: episodeSynopsis,
          onTitleTap: onTitleTap,
        ),
        if (railActors.isNotEmpty)
          FeedActorRailPositioned(
            actors: railActors,
            synopsisMaxLines: 1,
            showEpisodeCta: showEpisodeCta,
            onTap: () {
              final open = widget.onOpenCharacters;
              if (open != null) {
                open();
                return;
              }
              unawaited(
                (widget.holdWithCollapsedPlayer ??
                    widget.controller.holdAutoAdvance)(
                  () => DramaDetailSheet.show(
                    context: context,
                    dramaId: controller.dramaId,
                    coverUrl: drama?.coverUrl,
                    initialTab: DramaDetailSheetTab.characters,
                    sheetHeightNotifier: widget.sheetHeightNotifier,
                  ),
                ),
              );
            },
          ),
        VideoFeedEpisodeBar(
          totalEpisodes: total,
          positionNotifier: progressPosition,
          duration: progressDuration,
          onSeek: isLiveChrome ? controller.seekTo : (_) {},
          onEpisodeSelector: showEpisodeCta ? widget.onEpisodeSelector : null,
          showEpisodeCta: showEpisodeCta,
          showFullscreen: showFullscreen,
        ),
        VideoFeedRightActions(
          item: railItem,
          shareTitle: widget.title,
          shareDescription: isShortVideo
              ? (pagePlay?.description ?? drama?.description)
              : episodeSynopsis,
          play: pagePlay,
          cardLikedByMe: chromeSeed.likedByMe,
          cardLikeCount: chromeSeed.likeCount,
          cardCommentCount: chromeSeed.commentCount,
          cardFavoritedByMe: chromeSeed.favoritedByMe,
          cardFavoriteCount: chromeSeed.favoriteCount,
          engagement: FeedEngagementCallbacks(
            onLike: () => controller.toggleLike(episodeNo: epNo),
            onFavorite: () => controller.toggleFavorite(episodeNo: epNo),
            onCommentPosted: controller.onCommentPosted,
          ),
          onSelectEpisode: widget.onSelectEpisode,
          holdAutoAdvance:
              widget.holdWithCollapsedPlayer ?? controller.holdAutoAdvance,
          sheetHeightNotifier: widget.sheetHeightNotifier,
          showEpisodeCta: showEpisodeCta,
          aroundShare: widget.aroundShare,
        ),
        ?centerPlayButton(),
        if (isLiveChrome && status == FeedPlaybackStatus.buffering)
          const Center(
            child: SizedBox(
              width: StorySizes.loadingSmall,
              height: StorySizes.loadingSmall,
              child: CircularProgressIndicator(
                strokeWidth: StorySizes.loadingStroke,
                color: StoryColors.onOverlay,
              ),
            ),
          ),
      ],
    );
  }
}

/// Full-screen loading scaffold for the video feed initial state.
class VideoFeedLoadingScaffold extends StatelessWidget {
  final String? coverUrl;

  const VideoFeedLoadingScaffold({super.key, this.coverUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: StoryColors.overlayHeavy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          VideoFeedPageItem(
            episodeNo: 1,
            totalEpisodes: 1,
            coverUrl: coverUrl,
            isCurrentPage: true,
            revealPlayer: false,
            showLoading: coverUrl == null || coverUrl!.isEmpty,
          ),
          if (coverUrl != null && coverUrl!.isNotEmpty)
            const Center(
              child: SizedBox(
                width: StorySizes.loadingSmall,
                height: StorySizes.loadingSmall,
                child: CircularProgressIndicator(
                  strokeWidth: StorySizes.loadingStroke,
                  color: StoryColors.onOverlay,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
