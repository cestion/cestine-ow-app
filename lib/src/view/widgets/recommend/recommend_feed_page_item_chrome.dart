import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../controller/recommend_feed_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../drama_detail/drama_detail_sheet.dart';
import '../video_feed/video_feed_widgets.dart';
import 'recommend_feed_chrome.dart';

/// Per-page chrome for the recommend feed.
///
/// Each PageView page always paints chrome from its own [item] (title, actor
/// rail, bottom info, actions) so those layers slide with the card like
/// TikTok — never swap in another card's copy during early-activate.
///
/// Live progress / engagement wiring is gated by [isCurrent] + match flags.
class RecommendFeedPageItemChrome extends StatelessWidget {
  static final ValueNotifier<bool> _idlePlaying = ValueNotifier<bool>(false);
  static final ValueNotifier<Duration> _idlePosition = ValueNotifier<Duration>(
    Duration.zero,
  );

  /// Whether this page is the feed's current index (may lead the pager during
  /// early-activate).
  final bool isCurrent;

  /// The feed item for this page — chrome content is always bound to this.
  final RecommendFeedItem item;

  /// Drama detail for the active card, when it matches [item].
  final DramaDetail? detail;

  /// Full feed state.
  final RecommendFeedState feed;

  // ── Active-page state ──
  final ValueListenable<bool> chromeHidden;
  final bool ended;
  final ValueListenable<bool> playing;
  final ValueListenable<bool> userPaused;
  final ValueListenable<Duration> duration;
  final ValueNotifier<Duration> positionNotifier;
  final bool chromeMatchesActive;
  final bool chromeSyncedWithFeed;
  final bool standalone;
  final ValueNotifier<bool> playerSheetOpen;
  final ValueNotifier<double>? sheetHeightNotifier;

  // ── Active-page callbacks ──
  final VoidCallback onTogglePlayPause;
  final VoidCallback onLongPress;
  final VoidCallback onClearScreen;
  final VoidCallback onExitClearScreen;
  final void Function(Duration) onSeekActive;
  final VoidCallback onOpenFullDrama;
  final void Function(DramaDetailSheetTab) onOpenDetailTab;
  final Future<bool> Function() onLike;
  final Future<bool> Function() onFavorite;
  final VoidCallback onCommentPosted;
  final Future<void> Function(Future<void> Function() share)? aroundShare;

  /// Short-video comment sheet — same hold path as drama detail so
  /// [overlayHoldsAdvance] blocks shell-route teardown.
  final Future<T> Function<T>(Future<T> Function() action)?
  holdWithCollapsedPlayer;

  const RecommendFeedPageItemChrome({
    super.key,
    required this.isCurrent,
    required this.item,
    required this.detail,
    required this.feed,
    required this.chromeHidden,
    required this.ended,
    required this.playing,
    required this.userPaused,
    required this.duration,
    required this.positionNotifier,
    required this.chromeMatchesActive,
    required this.chromeSyncedWithFeed,
    required this.standalone,
    required this.playerSheetOpen,
    this.sheetHeightNotifier,
    required this.onTogglePlayPause,
    required this.onLongPress,
    required this.onClearScreen,
    required this.onExitClearScreen,
    required this.onSeekActive,
    required this.onOpenFullDrama,
    required this.onOpenDetailTab,
    required this.onLike,
    required this.onFavorite,
    required this.onCommentPosted,
    this.aroundShare,
    this.holdWithCollapsedPlayer,
  });

  @override
  Widget build(BuildContext context) {
    final showEpisodeCta = !item.workType.isShortVideo;
    final totalEpisodes =
        (isCurrent ? detail?.totalEpisodes : null) ?? item.totalEpisodes ?? 1;
    // Detail / roles overlay only when this page owns the loaded card.
    final pageDetail = isCurrent && chromeSyncedWithFeed ? detail : null;
    final live = isCurrent;

    Widget chrome({required bool hidden}) {
      return RecommendFeedChrome(
        current: item,
        detail: pageDetail,
        feed: feed,
        play: chromeSyncedWithFeed ? feed.currentPlay : null,
        chromeHidden: hidden,
        showEpisodeCta: showEpisodeCta,
        totalEpisodes: totalEpisodes,
        ended: live ? ended : false,
        playing: live ? playing : _idlePlaying,
        userPaused: live ? userPaused : _idlePlaying,
        duration: duration,
        positionNotifier: live && chromeMatchesActive
            ? positionNotifier
            : _idlePosition,
        onTogglePlayPause: live ? onTogglePlayPause : () {},
        onLongPress: live ? onLongPress : () {},
        onClearScreen: live ? onClearScreen : () {},
        onSeek: live && chromeMatchesActive ? onSeekActive : (_) {},
        pinProgressToBottom: !standalone,
        playerSheetOpen: live ? playerSheetOpen : null,
        sheetHeightNotifier: live ? sheetHeightNotifier : null,
        selectorLabel: showEpisodeCta && !standalone && live
            ? context.l10n.watchFullDramaEpisodes(totalEpisodes)
            : null,
        onOpenFullDrama: live ? onOpenFullDrama : () {},
        onOpenDetailTab: live ? onOpenDetailTab : (_) {},
        engagement: live
            ? FeedEngagementCallbacks(
                onLike: onLike,
                onFavorite: onFavorite,
                onCommentPosted: onCommentPosted,
              )
            : FeedEngagementCallbacks.empty,
        aroundShare: live ? aroundShare : null,
        holdAutoAdvance: live ? holdWithCollapsedPlayer : null,
        onExitClearScreen: live ? onExitClearScreen : () {},
      );
    }

    if (!live) return chrome(hidden: false);

    return ListenableBuilder(
      listenable: Listenable.merge([playerSheetOpen, chromeHidden]),
      builder: (context, _) {
        if (playerSheetOpen.value) {
          return const SizedBox.shrink();
        }
        return chrome(hidden: chromeHidden.value);
      },
    );
  }
}
