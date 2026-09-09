import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/story_toast.dart';
import '../../../controller/engagement_state.dart';
import '../../../controller/recommend_feed_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/route_names.dart';
import '../../../utils/auth_navigation.dart';
import '../drama_detail/drama_detail_sheet.dart';
import '../video_feed/video_feed_widgets.dart';
import '../../../foundation/navigator.dart';

/// Recommend overlay chrome (gradients, info, role rail, actions, episode bar).
///
/// Native slots stay in [RecommendFeedBody] so loadMore / chrome rebuilds
/// do not recreate platform views.
class RecommendFeedChrome extends ConsumerWidget {
  final RecommendFeedItem current;
  final DramaDetail? detail;
  final RecommendFeedState feed;
  final DramaPlayResponse? play;
  final bool chromeHidden;
  final bool showEpisodeCta;
  final int totalEpisodes;
  final bool ended;
  final ValueListenable<bool> playing;
  final ValueListenable<bool> userPaused;
  final ValueListenable<Duration> duration;
  final ValueNotifier<Duration> positionNotifier;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLongPress;
  final VoidCallback onClearScreen;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onOpenFullDrama;
  final ValueChanged<DramaDetailSheetTab> onOpenDetailTab;

  /// Unified engagement callbacks for like / favorite / comment.
  final FeedEngagementCallbacks engagement;

  final VoidCallback onExitClearScreen;

  /// When set, short-video comment sheet collapses the player surface.
  final ValueNotifier<bool>? playerSheetOpen;

  /// Optional sheet height for player band flush alignment.
  final ValueNotifier<double>? sheetHeightNotifier;

  /// Home recommend keeps CTA above a bottom-flush progress bar; playlist /
  /// drama-player chrome centers the episode strip like [VideoFeedPage].
  final bool pinProgressToBottom;

  /// When null, [VideoFeedEpisodeBar] uses its default「选集 · 全N集」label.
  final String? selectorLabel;

  /// Hold auto-advance while system share is open.
  final Future<void> Function(Future<void> Function() share)? aroundShare;

  /// Short-video comments: collapse player + hold auto-advance (same as
  /// drama detail sheet). Without this, shell route cover tears down surfaces.
  final Future<T> Function<T>(Future<T> Function() action)? holdAutoAdvance;

  const RecommendFeedChrome({
    super.key,
    required this.current,
    required this.detail,
    required this.feed,
    this.play,
    required this.chromeHidden,
    required this.showEpisodeCta,
    required this.totalEpisodes,
    required this.ended,
    required this.playing,
    required this.userPaused,
    required this.duration,
    required this.positionNotifier,
    required this.onTogglePlayPause,
    required this.onLongPress,
    required this.onClearScreen,
    required this.onSeek,
    required this.onOpenFullDrama,
    required this.onOpenDetailTab,
    required this.engagement,
    required this.onExitClearScreen,
    this.playerSheetOpen,
    this.sheetHeightNotifier,
    this.pinProgressToBottom = true,
    this.selectorLabel,
    this.aroundShare,
    this.holdAutoAdvance,
  });

  DramaDetail get _drama =>
      detail ??
      DramaDetail(
        id: current.dramaId,
        userId: current.creatorId,
        title: current.title,
        description: current.description,
        coverUrl: current.coverUrl,
        totalEpisodes: current.totalEpisodes,
        badge: current.badge,
        creatorName: current.creatorName,
        creatorAvatarUrl: current.creatorAvatar,
        favoriteCount: current.favoriteCount,
      );

  int get _episodeNo => (current.episodeNo != null && current.episodeNo! >= 1)
      ? current.episodeNo!
      : 1;

  String? _creatorHandle(String? name) {
    final trimmed = name?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed.startsWith('@') ? trimmed : '@$trimmed';
  }

  Future<void> _onDoubleTapLike(BuildContext context, WidgetRef ref) async {
    if (!await ensureLoggedInOrRedirect(context, ref)) return;
    if (!context.mounted) return;

    final episodeId = (current.episodeId ?? play?.episodeId)?.trim() ?? '';
    if (episodeId.isEmpty) return;

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: current.dramaId,
      episodeId: episodeId,
      episodeNo: play?.episodeNo ?? _episodeNo,
    );
    final eng = ref.read(episodeEngagementProvider(key));
    final liked =
        eng.likedByMe ?? current.likedByMe ?? play?.likedByMe ?? false;
    if (liked) return;

    final success = await engagement.onLike();
    if (!success && context.mounted) {
      final err = ref.read(episodeEngagementProvider(key)).lastError;
      if (err != null) {
        StoryToast.error(context, context.l10nError(err), rootOverlay: true);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actors = RecommendFeedActor.forRail(
      feedActors: current.actors,
      roles: detail?.roles,
    );
    final isShortVideo = current.workType.isShortVideo;
    final creatorHandle = isShortVideo
        ? _creatorHandle(_drama.creatorName ?? current.creatorName)
        : null;
    final creatorUserId = (_drama.userId ?? current.creatorId)?.trim() ?? '';
    final onTitleTap = isShortVideo
        ? (creatorUserId.isEmpty
              ? null
              : () {
                  context.storyPush(RouteNames.publicProfile, arguments: {'userId': creatorUserId});
                })
        : () => onOpenDetailTab(DramaDetailSheetTab.drama);

    return FeedPortraitGestureStack(
      chromeHidden: chromeHidden,
      onEnterClearScreen: onClearScreen,
      onExitClearScreen: onExitClearScreen,
      onTap: onTogglePlayPause,
      onLongPress: onLongPress,
      onDoubleTapLike: identical(engagement, FeedEngagementCallbacks.empty)
          ? null
          : () => _onDoubleTapLike(context, ref),
      chromeChildren: [
        VideoFeedBottomInfo(
          drama: _drama,
          currentEpisodeNo: _episodeNo,
          showRoles: false,
          synopsisMaxLines: 2,
          pinProgressToBottom: pinProgressToBottom,
          showEpisodeCta: showEpisodeCta,
          prefixSynopsisWithEpisode: !isShortVideo,
          synopsis: current.description,
          displayTitle: creatorHandle,
          onTitleTap: onTitleTap,
        ),
        if (actors.isNotEmpty)
          FeedActorRailPositioned(
            actors: actors,
            onTap: () => onOpenDetailTab(DramaDetailSheetTab.characters),
            pinProgressToBottom: pinProgressToBottom,
            showEpisodeCta: showEpisodeCta,
          ),
        VideoFeedRightActions(
          item: current.toPlayable(detail: detail, play: play),
          favoriteEngagementId: current.favoriteTargetId,
          shareDescription: current.description,
          play: play,
          cardLikeCount: current.likeCount,
          cardLikedByMe: current.likedByMe,
          cardCommentCount: current.commentCount,
          cardFavoritedByMe: current.favoritedByMe,
          cardFavoriteCount: current.favoriteCount,
          pinProgressToBottom: pinProgressToBottom,
          showEpisodeCta: showEpisodeCta,
          engagement: engagement,
          playerSheetOpen: playerSheetOpen,
          sheetHeightNotifier: sheetHeightNotifier,
          aroundShare: aroundShare,
          holdAutoAdvance: holdAutoAdvance,
        ),
      ],
      overlayChildren: [
        ValueListenableBuilder<Duration>(
          valueListenable: duration,
          builder: (context, barDuration, _) {
            return VideoFeedEpisodeBar(
              totalEpisodes: totalEpisodes,
              positionNotifier: positionNotifier,
              duration: barDuration,
              onSeek: onSeek,
              onEpisodeSelector: !chromeHidden && showEpisodeCta
                  ? onOpenFullDrama
                  : null,
              selectorLabel: selectorLabel,
              showFullscreen: false,
              pinProgressToBottom: pinProgressToBottom,
              showEpisodeCta: !chromeHidden && showEpisodeCta,
            );
          },
        ),
        if (chromeHidden)
          VideoFeedExitFullscreenButton(onTap: onExitClearScreen),
        FeedPausedPlayOverlayListenables(
          playing: playing,
          userPaused: userPaused,
          ended: ended,
          onTap: onTogglePlayPause,
        ),
      ],
    );
  }
}
