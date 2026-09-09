import 'package:equatable/equatable.dart';

import '../model/models.dart';

/// Feed visibility lifecycle — whether the feed is frontmost, covered by a
/// push route, or the app is backgrounded. Replaces bare `_coverSuspended`.
///
/// Transition rules:
/// - `active → background`  ([onAppBackground])
/// - `background → active`  ([onAppForeground])
/// - `active → routeCovered` ([onRouteCovered])
/// - `routeCovered → active` ([onPageRevealed])
/// - any → `active`          ([_enqueueActivate] on new episode)
enum FeedVisibility { active, background, routeCovered }

/// Auth recovery phase for the current episode.
///
/// - `idle`: no stale-auth recovery has been attempted
/// - `inFlight`: a recovery attempt is in progress
/// - `attempted`: a recovery was attempted (possibly failed)
enum AuthRecoveryPhase {
  idle,
  inFlight,
  attempted,

  /// Reset on episode change ([_markEpisodeReady], [_activateFromPreload], retry).
}

/// Frame-stall detection state machine.
///
/// - `monitoring`: normal — checking frames advance on each position update
/// - `nudging`: first stall — nudging native texture, waiting for a new frame
/// - `reactivating`: nudge failed — force-reloading the episode
/// - `exhausted`: both recovery paths failed — surface error to UI
///
/// Transition:
///   monitoring → nudging → reactivating → exhausted
///        ↑          ↑ (frame recovered)    │
///        └──────────┴──────────────────────┘ (episode change → monitoring)
enum FrameStallPhase { monitoring, nudging, reactivating, exhausted }

/// Playback lifecycle status for the video feed.
enum FeedPlaybackStatus {
  idle,
  loading,
  ready,
  paused,
  buffering,
  completed,
  error,
}

/// How aggressively to resume after returning to the feed.
enum ForegroundResumeStrategy {
  /// <1.5s away — play() only.
  brief,

  /// Normal — cookies + surface + play, then nudge once.
  soft,

  /// Long background — skip soft path, reload episode.
  force,
}

/// Per-episode metadata prefetch bookkeeping (not a native decode slot).
class FeedEpisodeState with Equatable {
  final DramaPlayResponse? play;
  final bool isPrefetching;
  final Object? error;

  const FeedEpisodeState({this.play, this.isPrefetching = false, this.error});

  @override
  List<Object?> get props => [play, isPrefetching, error];
}

/// Immutable state for [VideoFeedController].
class VideoFeedState extends Equatable {
  final int currentEpisodeNo;
  final int? loadedEpisodeNo;
  final FeedPlaybackStatus status;
  final bool isPlaying;
  final bool isUserPaused;
  final Duration duration;
  final DramaPlayResponse? currentPlay;
  final DramaDetail? dramaDetail;
  final Object? error;
  final int? autoAdvanceToEpisodeNo;
  final Set<int> playedEpisodeNos;
  final Set<int> prefetchedEpisodeNos;
  final Map<int, DramaPlayResponse> episodePlays;

  /// Per-episode poster URLs (`episode.coverUrl`), keyed by episode number.
  ///
  /// Falls back to [dramaDetail.coverUrl] in the UI when a key is missing.
  final Map<int, String> episodeCoverUrls;

  /// Per-episode prefetch failures surfaced to UI for "tap to retry".
  ///
  /// Keyed by episode number. An entry here means prefetch failed and the
  /// user can retry by re-entering the page or tapping the error overlay.
  /// Cleared on next successful load of the same episode.
  final Map<int, Object> episodeErrors;

  /// True once the native surface has a decodable frame for [loadedEpisodeNo].
  final bool playerSurfaceVisible;

  /// Episodes decoded on the previous/next native slots.
  final Set<int> preloadedEpisodeNos;

  /// Episodes whose native slot has painted at least one frame.
  ///
  /// Distinct from [preloadedEpisodeNos]: mapping after `loadUrl` does not
  /// mean a frame is on screen. Neighbor covers unmount only when listed here.
  final Set<int> frameReadyEpisodeNos;

  int? get preloadedEpisodeNo =>
      preloadedEpisodeNos.isEmpty ? null : preloadedEpisodeNos.first;

  const VideoFeedState({
    this.currentEpisodeNo = 0,
    this.loadedEpisodeNo,
    this.status = FeedPlaybackStatus.idle,
    this.isPlaying = false,
    this.isUserPaused = false,
    this.duration = Duration.zero,
    this.currentPlay,
    this.dramaDetail,
    this.error,
    this.autoAdvanceToEpisodeNo,
    this.playedEpisodeNos = const {},
    this.prefetchedEpisodeNos = const {},
    this.episodePlays = const {},
    this.episodeCoverUrls = const {},
    this.episodeErrors = const {},
    this.playerSurfaceVisible = false,
    this.preloadedEpisodeNos = const {},
    this.frameReadyEpisodeNos = const {},
  });

  bool hasPlayedEpisode(int episodeNo) => playedEpisodeNos.contains(episodeNo);

  bool hasPrefetchedEpisode(int episodeNo) =>
      prefetchedEpisodeNos.contains(episodeNo);

  bool shouldSkipCover(int episodeNo) =>
      hasPlayedEpisode(episodeNo) || hasPrefetchedEpisode(episodeNo);

  bool hasEpisodeError(int episodeNo) => episodeErrors.containsKey(episodeNo);

  bool get isLoading => status == FeedPlaybackStatus.loading;

  VideoFeedState copyWith({
    int? currentEpisodeNo,
    int? loadedEpisodeNo,
    FeedPlaybackStatus? status,
    bool? isPlaying,
    bool? isUserPaused,
    Duration? duration,
    DramaPlayResponse? currentPlay,
    DramaDetail? dramaDetail,
    Object? error,
    int? autoAdvanceToEpisodeNo,
    Set<int>? playedEpisodeNos,
    Set<int>? prefetchedEpisodeNos,
    Map<int, DramaPlayResponse>? episodePlays,
    Map<int, String>? episodeCoverUrls,
    Map<int, Object>? episodeErrors,
    bool? playerSurfaceVisible,
    Set<int>? preloadedEpisodeNos,
    Set<int>? frameReadyEpisodeNos,
    bool clearLoadedEpisodeNo = false,
    bool clearCurrentPlay = false,
    bool clearDramaDetail = false,
    bool clearError = false,
    bool clearAutoAdvanceToEpisodeNo = false,
    bool clearPreloadedEpisodeNos = false,
  }) {
    return VideoFeedState(
      currentEpisodeNo: currentEpisodeNo ?? this.currentEpisodeNo,
      loadedEpisodeNo: clearLoadedEpisodeNo
          ? null
          : (loadedEpisodeNo ?? this.loadedEpisodeNo),
      status: status ?? this.status,
      isPlaying: isPlaying ?? this.isPlaying,
      isUserPaused: isUserPaused ?? this.isUserPaused,
      duration: duration ?? this.duration,
      currentPlay: clearCurrentPlay ? null : (currentPlay ?? this.currentPlay),
      dramaDetail: clearDramaDetail ? null : (dramaDetail ?? this.dramaDetail),
      error: clearError ? null : (error ?? this.error),
      autoAdvanceToEpisodeNo: clearAutoAdvanceToEpisodeNo
          ? null
          : (autoAdvanceToEpisodeNo ?? this.autoAdvanceToEpisodeNo),
      playedEpisodeNos: playedEpisodeNos ?? this.playedEpisodeNos,
      prefetchedEpisodeNos: prefetchedEpisodeNos ?? this.prefetchedEpisodeNos,
      episodePlays: episodePlays ?? this.episodePlays,
      episodeCoverUrls: episodeCoverUrls ?? this.episodeCoverUrls,
      episodeErrors: episodeErrors ?? this.episodeErrors,
      playerSurfaceVisible: playerSurfaceVisible ?? this.playerSurfaceVisible,
      preloadedEpisodeNos: clearPreloadedEpisodeNos
          ? const {}
          : (preloadedEpisodeNos ?? this.preloadedEpisodeNos),
      frameReadyEpisodeNos: frameReadyEpisodeNos ?? this.frameReadyEpisodeNos,
    );
  }

  @override
  List<Object?> get props => [
    currentEpisodeNo,
    loadedEpisodeNo,
    status,
    isPlaying,
    isUserPaused,
    duration,
    currentPlay,
    dramaDetail,
    error,
    autoAdvanceToEpisodeNo,
    playedEpisodeNos,
    prefetchedEpisodeNos,
    episodePlays,
    episodeCoverUrls,
    episodeErrors,
    playerSurfaceVisible,
    preloadedEpisodeNos,
    frameReadyEpisodeNos,
  ];
}
