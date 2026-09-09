import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/result.dart';
import '../core/story_constants.dart';
import '../core/story_dns_preheater.dart';
import '../core/story_logger.dart';
import '../core/video_url_helpers.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../repositories/drama_repository.dart';
import '../repositories/recommend_repository.dart';
import '../services/video_precache_service.dart';
import 'feed_episode_metrics_session.dart';
import 'feed_media_prefetch.dart';
import 'engagement_state.dart';
import 'engagement_sync.dart';
import 'feed_playback_policy.dart';
import 'feed_activate_telemetry_session.dart';
import 'feed_overlay_hold.dart';
import 'feed_tracking_service.dart';
import 'playback_episode_metrics_tracker.dart';
import 'follow_status_store.dart';
import 'pagination_mixin.dart';
import 'pagination_state.dart';
import 'playlist_continuation.dart';
import 'playlist_feed_expand.dart';
import 'recommend_feed_state.dart';
import 'story_controller_mixin.dart';
import 'watch_history_reporter.dart';

class RecommendFeedController extends Notifier<RecommendFeedState>
    with
        PaginationMixin<RecommendFeedItem, RecommendFeedState>,
        StoryControllerMixin<RecommendFeedState> {
  RecommendFeedController({
    List<RecommendFeedItem>? initialItems,
    this.initialIndex = 0,
    this.continuation,
  }) : _initialItems = initialItems == null
           ? null
           : List<RecommendFeedItem>.unmodifiable(initialItems);

  final List<RecommendFeedItem>? _initialItems;
  final int initialIndex;
  final PlaylistContinuation? continuation;

  bool get isExternalFeed => _initialItems != null;

  /// True while an external playlist still has a parent page to fetch.
  bool get canLoadMoreFromParent =>
      isExternalFeed && (continuation?.hasMore ?? false);

  late DramaRepository _drama;
  late RecommendRepository _recommend;
  late FeedTrackingService _tracking;
  int _activateGeneration = 0;
  int _prefetchGeneration = 0;
  final Map<String, DramaPlayResponse> _playCache = {};
  final Map<String, ApiError> _playResolutionErrors = {};
  final Set<String> _engagementHydratedKeys = {};

  /// External playlist metadata is calibrated at most once per page session.
  final Set<String> _metadataCalibrationStarted = {};

  /// Keys whose episode-detail already came back without cookies — do not
  /// refetch on every swipe (current gateway omits `signedCookies`).
  final Set<String> _unsignedConfirmed = {};

  /// Keys the backend reported as not transcoded yet (`121019`). The feed
  /// card's `mediaAccessUrl` points at the same missing rendition, so binding
  /// it only burns a 4s frame wait plus two 15s `loadUrl` timeouts.
  final Set<String> _untranscoded = {};
  final FeedEpisodeMetricsSession _episodeMetrics =
      FeedEpisodeMetricsSession();
  final FeedWatchHistoryGate _watchHistoryGate = FeedWatchHistoryGate();

  final FeedActivateTelemetrySession _activateTelemetry =
      FeedActivateTelemetrySession(feed: 'recommend');
  int? _neighborsWarmedForIndex;
  String _feedSubject = 'guest';

  /// True while [ensureLoaded] is revalidating a stale-while-revalidate paint.
  /// Blocks opportunistic [activateIndex] from the body (tab re-entry) so we
  /// do not race native load against the in-flight first-page fetch.
  bool _swrRevalidateInFlight = false;

  /// Guards concurrent [ensureLoaded] during the local cache peek (before
  /// [isLoading] flips on a network miss).
  bool _ensureInFlight = false;

  @override
  RecommendFeedState build() {
    _drama = ref.read(dramaRepositoryProvider);
    _recommend = ref.read(recommendRepositoryProvider);
    _tracking = FeedTrackingService(ref);
    _feedSubject = _recommendSubject();
    final watchHistory = ref.read(watchHistoryBatchReporterProvider.notifier);
    ref.onDispose(() {
      unawaited(watchHistory.flush());
    });
    final initialItems = _initialItems;
    if (initialItems != null) {
      final index = initialItems.isEmpty
          ? 0
          : initialIndex.clamp(0, initialItems.length - 1);
      final current = initialItems.isEmpty ? null : initialItems[index];
      return RecommendFeedState(
        pagination: PaginationState<RecommendFeedItem>(
          items: initialItems,
          hasMore: continuation?.hasMore ?? false,
        ),
        currentIndex: index,
        currentDetail: current == null ? null : _detailFromFeedItem(current),
      );
    }
    ref.listen<String>(localeCodeProvider, (prev, next) {
      if (prev != null && prev != next) {
        // Defer: listener can fire while the widget tree is still building.
        Future.microtask(() async {
          if (!ref.mounted) return;
          await _recommend.invalidateFirstPageCache();
          if (!ref.mounted) return;
          unawaited(refresh());
        });
      }
    });
    ref.listen<String?>(authControllerProvider.select((s) => s.userId), (
      prev,
      next,
    ) {
      if ((prev ?? '') == (next ?? '')) return;
      Future.microtask(() async {
        if (!ref.mounted) return;
        await _recommend.invalidateFirstPageCache();
        if (!ref.mounted) return;
        unawaited(refresh());
      });
    });
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(ensureLoaded());
    });
    return const RecommendFeedState();
  }

  @override
  RecommendFeedState copyWithLoadingState({
    bool? isLoading,
    ApiError? lastError,
    bool clearLastError = false,
  }) {
    return state.copyWith(
      isLoading: isLoading,
      lastError: lastError,
      clearLastError: clearLastError,
    );
  }

  @override
  PaginationState<RecommendFeedItem> get pagination => state.pagination;

  @override
  bool get isLoading => state.isLoading;

  @override
  void setPaginationState(
    PaginationState<RecommendFeedItem> pagination, {
    bool? isLoading,
  }) {
    state = state.copyWith(pagination: pagination, isLoading: isLoading);
    _seedFollowFromItems(pagination.items);
  }

  @override
  void setPaginationError(ApiError? error) {
    state = state.copyWith(lastError: error);
  }

  @override
  Future<Result<PageDto<RecommendFeedItem>>> fetchPage({String? mark}) async {
    if (isExternalFeed) {
      return _fetchExternalContinuationPage();
    }
    return _recommend.fetchFeed(cursor: mark, subject: _recommendSubject());
  }

  Future<Result<PageDto<RecommendFeedItem>>>
  _fetchExternalContinuationPage() async {
    final continuation = this.continuation;
    if (continuation == null || !continuation.hasMore) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    final pageResult = await continuation.loadMore();
    if (!ref.mounted) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    final error = pageResult.errorOrNull;
    if (error != null) return Result.failure(error);
    final page = pageResult.dataOrNull;
    if (page == null) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    if (page.entries.isEmpty) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    final resolved = await PlaylistFeedExpand.resolveEpisodeCounts(
      page.entries,
      loadEpisodeCount: _loadEpisodeCountForPlaylist,
    );
    if (!ref.mounted) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    final resolveError = resolved.errorOrNull;
    if (resolveError != null) return Result.failure(resolveError);
    final flattened = PlaylistFeedExpand.flattenEntries(
      resolved.dataOrNull ?? const [],
    );
    if (flattened.isEmpty) {
      return Result.success(
        const PageDto<RecommendFeedItem>(hasMore: false, list: []),
      );
    }
    return Result.success(
      PageDto<RecommendFeedItem>(hasMore: page.hasMore, list: flattened),
    );
  }

  Future<Result<int>> _loadEpisodeCountForPlaylist(String dramaId) async {
    var detailResult = await _drama.getDetail(dramaId);
    var detail = detailResult.dataOrNull;
    var count = detail?.totalEpisodes ?? 0;
    if (detailResult.isSuccess && count < 1) {
      detailResult = await _drama.getDetail(dramaId, forceRefresh: true);
      detail = detailResult.dataOrNull;
      count = detail?.totalEpisodes ?? 0;
    }
    final error = detailResult.errorOrNull;
    if (error != null) return Result.failure(error);
    if (count < 1) {
      return Result.failure(ApiError.validation('Invalid total episode count'));
    }
    return Result.success(count);
  }

  @override
  Future<void> loadMore() async {
    if (isExternalFeed) {
      await super.loadMore();
      return;
    }
    if (_recommendSubject() != _feedSubject) {
      await refresh();
      return;
    }
    final usedCursor = mark.isNotEmpty;
    await super.loadMore();
    if (!ref.mounted) return;
    final err = state.lastError;
    if (usedCursor && err is BusinessError && err.code == 100400) {
      await refresh();
    }
  }

  /// Fetch the next page when the playhead is on the last flattened card, or
  /// (external feeds) already inside the last source work.
  ///
  /// [index] is the pager page when it has not yet been written to
  /// [RecommendFeedState.currentIndex] (PageView `onPageChanged`).
  ///
  /// Returns true if new items were appended. A failed request leaves
  /// [RecommendFeedState.hasMore] unchanged so the UI can retry instead of
  /// toasting "no more".
  Future<bool> loadMoreIfAtEnd({int? index}) async {
    final playhead = index ?? state.currentIndex;
    final shouldLoad = isExternalFeed
        ? _shouldLoadMoreExternal(playhead)
        : FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
            currentIndex: playhead,
            itemCount: state.items.length,
            hasMore: state.hasMore,
          );
    if (!shouldLoad) return false;
    final before = state.items.length;
    await loadMore();
    if (!ref.mounted) return false;
    return state.items.length > before;
  }

  bool _shouldLoadMoreExternal(int playhead) {
    if (!state.hasMore || state.items.isEmpty) return false;
    if (FeedPlaybackPolicy.shouldLoadMoreAtLastItem(
      currentIndex: playhead,
      itemCount: state.items.length,
      hasMore: state.hasMore,
    )) {
      return true;
    }
    final keys = [
      for (final item in state.items)
        FeedPlaybackPolicy.sourceWorkKey(
          contentType: item.contentType,
          dramaId: item.dramaId,
          episodeId: item.episodeId,
        ),
    ];
    return FeedPlaybackPolicy.shouldPrefetchAtLastSourceWork(
      currentSourceIndex: FeedPlaybackPolicy.sourceIndexForFlatIndex(
        sourceKeys: keys,
        flatIndex: playhead,
      ),
      sourceCount: FeedPlaybackPolicy.sourceCountForKeys(keys),
      hasMore: state.hasMore,
    );
  }

  String _recommendSubject() {
    final id = ref.read(authControllerProvider).userId?.trim();
    if (id != null && id.isNotEmpty) return id;
    return 'guest';
  }

  void _applyFirstPage(
    PageDto<RecommendFeedItem> page, {
    required bool loading,
    bool playLoading = false,
  }) {
    final items = page.list ?? const <RecommendFeedItem>[];
    _seedFollowFromItems(items);
    final current = items.isEmpty ? null : items.first;
    state = state.copyWith(
      pagination: (const PaginationState<RecommendFeedItem>()).appendPage(page),
      currentIndex: 0,
      currentDetail: current == null ? null : _detailFromFeedItem(current),
      clearCurrentPlay: true,
      isUserPaused: false,
      isLoading: loading,
      isPlayLoading: playLoading,
      clearLastError: true,
    );
  }

  @override
  Future<void> refresh() async {
    _feedSubject = _recommendSubject();
    _activateGeneration++;
    _prefetchGeneration++;
    _playCache.clear();
    _playResolutionErrors.clear();
    _unsignedConfirmed.clear();
    _untranscoded.clear();
    final initialItems = _initialItems;
    if (initialItems != null) {
      final index = initialItems.isEmpty
          ? 0
          : initialIndex.clamp(0, initialItems.length - 1);
      final current = initialItems.isEmpty ? null : initialItems[index];
      state = RecommendFeedState(
        pagination: PaginationState<RecommendFeedItem>(
          items: initialItems,
          hasMore: false,
        ),
        currentIndex: index,
        currentDetail: current == null ? null : _detailFromFeedItem(current),
      );
      if (current != null) unawaited(activateIndex(index));
      return;
    }
    state = state.copyWith(
      currentIndex: 0,
      clearCurrentDetail: true,
      clearCurrentPlay: true,
      isUserPaused: false,
      clearLastError: true,
    );
    await super.refresh();
    if (!ref.mounted) return;
    _seedFollowFromItems(state.items);
    // Do not await play prep — list/covers can paint while episode detail
    // and native bootstrap run in parallel.
    if (state.items.isNotEmpty) {
      unawaited(activateIndex(0));
    }
  }

  /// Apply [RecommendFeedItem.followedByMe] onto the session follow cache so
  /// the player rail does not page `GET .../followings`.
  void _seedFollowFromItems(List<RecommendFeedItem> items) {
    if (!ref.read(authControllerProvider).isLoggedIn) return;
    final store = ref.read(followStatusStoreProvider.notifier);
    for (final item in items) {
      final id = item.creatorId?.trim();
      if (id == null || id.isEmpty) continue;
      final followed = item.followedByMe;
      if (followed == null) continue;
      store.seedIfUnknown(id, followed);
    }
  }

  Future<void> ensureLoaded() async {
    if (state.items.isNotEmpty || state.isLoading || state.isPageLoading) {
      return;
    }
    if (_ensureInFlight) return;
    if (isExternalFeed) {
      await refresh();
      return;
    }

    _ensureInFlight = true;
    try {
      final subject = _recommendSubject();
      _feedSubject = subject;

      final syncCached = _recommend.peekCachedFirstPageSync(subject: subject);
      if (syncCached != null && (syncCached.list?.isNotEmpty ?? false)) {
        _paintCachedFirstPage(syncCached);
        await _revalidateCachedFirstPage();
        return;
      }

      // Peek local cache first — do not flip isLoading yet so a hit can paint
      // without a spinner. UI uses _awaitingFirstLoad to avoid empty-state flash.
      final cached = await _recommend.peekCachedFirstPage(subject: subject);
      if (!ref.mounted) return;
      if (cached != null && (cached.list?.isNotEmpty ?? false)) {
        _paintCachedFirstPage(cached);
        await _revalidateCachedFirstPage();
        return;
      }

      // Cold miss: now show loading and hit the network.
      await refresh();
    } finally {
      _ensureInFlight = false;
    }
  }

  void _paintCachedFirstPage(PageDto<RecommendFeedItem> cached) {
    StoryLogger.d(
      'Recommend SWR: paint ${cached.list!.length} cached items',
      tag: 'Rec',
    );
    _activateGeneration++;
    _prefetchGeneration++;
    _playCache.clear();
    _playResolutionErrors.clear();
    _unsignedConfirmed.clear();
    _untranscoded.clear();
    _applyFirstPage(cached, loading: false, playLoading: true);
  }

  Future<void> _revalidateCachedFirstPage() async {
    _swrRevalidateInFlight = true;
    try {
      // Quiet first-page reload only — do not call [refresh], which bumps
      // activate generation, clears play cache, and unawaited activateIndex(0).
      // That raced the forced activate below and produced spurious drama
      // switches + no-frame failures on cold start.
      await reloadFirstPage(showLoading: false);
      if (!ref.mounted) return;
      _seedFollowFromItems(state.items);
      if (state.items.isNotEmpty) {
        await activateIndex(0, force: true);
      } else {
        state = state.copyWith(isPlayLoading: false);
      }
    } finally {
      _swrRevalidateInFlight = false;
    }
  }

  Future<void> onPageChanged(int index) async {
    if (index < 0 || index >= state.items.length) return;
    final item = state.items[index];
    if (index == state.currentIndex && state.currentPlay != null) {
      final loadedId = RecommendFeedItem.playbackIdOfPlay(state.currentPlay);
      if (loadedId != null &&
          loadedId.isNotEmpty &&
          loadedId == item.playbackId) {
        return;
      }
    }
    final cached = _memoryPlay(item);
    // Binding an unsigned CloudFront URL 403s, so only pre-bind a play that
    // already carries cookies; otherwise wait for [activateIndex].
    final signed = _hasUsableCookies(cached);
    state = state.copyWith(
      currentIndex: index,
      currentDetail: _detailFromFeedItem(item),
      currentPlay: signed ? _withFeedEngagement(item, cached!) : null,
      clearCurrentPlay: !signed,
      isUserPaused: false,
      isPlayLoading: !signed,
      clearLastError: true,
    );
    await activateIndex(index);
  }

  Future<void> activateIndex(int index, {bool force = false}) async {
    if (_swrRevalidateInFlight && !force) return;
    if (index < 0 || index >= state.items.length) return;
    final generation = ++_activateGeneration;
    _prefetchGeneration++;
    _resetEpisodeMetrics();
    if (_neighborsWarmedForIndex != index) {
      _neighborsWarmedForIndex = null;
    }
    var item = state.items[index];
    if (!item.hasPlayableIdentity) return;

    _activateTelemetry.begin(item.playbackId);
    final episodeNo = episodeNoOf(item);

    var play = _memoryPlay(item);
    if (!_shouldResolveByEpisodeId(item) && item.dramaId.isNotEmpty) {
      play ??= await _drama.peekPrefetchedEpisode(item.dramaId, episodeNo);
    }
    if (!ref.mounted || generation != _activateGeneration) return;

    play ??= item.toPlayResponse();
    DramaPlayResponse? authoritativePlay;
    if (play != null) {
      authoritativePlay = play;
      play = _withFeedEngagement(item, play);
      _rememberPlay(item, play);
    }

    final url = play?.effectivePlayUrl ?? item.mediaAccessUrl?.trim();
    if (url != null && VideoUrlHelpers.isHttpUrl(url)) {
      StoryDnsPreheater.preheat(url);
    }

    // Chrome comes straight from the feed card — title, cover, counts and
    // actors never wait on the network.
    final signedReady = _hasUsableCookies(play);
    _seedEngagement(item, play, authoritativePlay: authoritativePlay);
    state = state.copyWith(
      currentIndex: index,
      currentDetail: _detailFromFeedItem(item),
      currentPlay: signedReady ? play : null,
      clearCurrentPlay: !signedReady,
      isPlayLoading: !signedReady,
      clearLastError: true,
    );

    // Playback is the one thing the card cannot supply: the feed omits
    // `signedCookies`, and CloudFront 403s an unsigned media URL. Fetch the
    // signed payload only when we do not already have usable cookies.
    final signed = await _ensureSignedPlay(item, play);
    play = signed.play;
    if (!ref.mounted || generation != _activateGeneration) return;
    if (play == null) {
      final unplayable = _untranscoded.contains(_playKey(item));
      final error = unplayable
          ? const BusinessError(StoryConstants.episodeTranscodeFailedCode, '')
          : (isExternalFeed ? _playResolutionErrors[_playKey(item)] : null);
      state = state.copyWith(
        isPlayLoading: false,
        clearCurrentPlay: true,
        lastError: error,
        clearLastError: error == null,
      );
      return;
    }

    item = _applyResolvedEpisodeIdentity(index, item, play);
    _rememberPlay(item, play);

    // Re-seed: the signed payload can carry an episodeId the card omitted,
    // and the rail keys its store off the bound play.
    _seedEngagement(item, play, authoritativePlay: signed.authoritativePlay);
    _refreshExternalEpisodeEngagement(item);
    state = state.copyWith(
      currentPlay: play,
      isPlayLoading: false,
      clearLastError: true,
    );
    _reportRecommendActivateTelemetry();

    // Sparse playlists (watch history) omit creator chrome — fill after play
    // is live so getDetail does not delay the first frame.
    if (item.workType.isShortVideo) {
      unawaited(_hydrateMissingCreator(index, item, play, generation));
    } else {
      unawaited(_hydrateShortDramaMetadata(index, item, play, generation));
    }
    if (isExternalFeed) {
      unawaited(_calibrateExternalMetadata(index, item));
    }

    // Do not disk-warm the current URL or loadMore here. Both contend with
    // the native loadUrl (iOS connection limit) and were hanging the first
    // AVPlayer item for 15s. Neighbor disk-warm waits for first frame
    // ([warmNeighborsAfterFirstFrame]). Next page waits until the playhead
    // is on the last card ([loadMoreIfAtEnd]).
  }

  /// Fill missing title / creator chrome for short dramas. One [getDetail]
  /// when either field is sparse; skip entirely when the feed card is complete.
  Future<void> _hydrateShortDramaMetadata(
    int index,
    RecommendFeedItem item,
    DramaPlayResponse play,
    int generation,
  ) async {
    final needsTitle = item.title?.trim().isNotEmpty != true;
    final hasCreatorId = item.creatorId?.trim().isNotEmpty == true;
    final hasCreatorAvatar = item.creatorAvatar?.trim().isNotEmpty == true;
    final needsCreator = !(hasCreatorId && hasCreatorAvatar);
    if (!needsTitle && !needsCreator) return;

    DramaDetail? detail;
    final dramaId = item.dramaId.trim();
    if (dramaId.isNotEmpty && (needsTitle || needsCreator)) {
      final result = await _drama.getDetail(dramaId);
      if (!ref.mounted || generation != _activateGeneration) return;
      detail = result.dataOrNull;
    }

    final title = needsTitle ? detail?.title?.trim() : null;

    String? creatorId;
    String? creatorName;
    String? creatorAvatar;
    if (needsCreator) {
      creatorId = detail?.userId?.trim();
      creatorName = detail?.creatorName?.trim();
      creatorAvatar = detail?.creatorAvatarUrl?.trim();
      creatorId ??= play.userId?.trim();
    }

    if ((title == null || title.isEmpty) &&
        (creatorId == null || creatorId.isEmpty) &&
        (creatorAvatar == null || creatorAvatar.isEmpty) &&
        (creatorName == null || creatorName.isEmpty)) {
      return;
    }

    if (!ref.mounted || generation != _activateGeneration) return;
    if (index < 0 || index >= state.items.length) return;
    final current = state.items[index];
    if (current.playbackId != item.playbackId) return;

    final patched = current.withCreator(
      title: title,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
    );
    if (patched.title == current.title &&
        patched.creatorId == current.creatorId &&
        patched.creatorName == current.creatorName &&
        patched.creatorAvatar == current.creatorAvatar) {
      return;
    }

    final items = [...state.items]..[index] = patched;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: items),
      currentDetail: index == state.currentIndex
          ? _detailFromFeedItem(patched)
          : null,
    );
    if (index == state.currentIndex) {
      _seedEngagement(patched, play);
    }
  }

  /// Sparse playlists omit creator chrome. Short videos use [DramaPlayResponse.userId]
  /// only — no drama [/detail] round trip.
  Future<void> _hydrateMissingCreator(
    int index,
    RecommendFeedItem item,
    DramaPlayResponse play,
    int generation,
  ) async {
    final hasId = item.creatorId?.trim().isNotEmpty == true;
    final hasAvatar = item.creatorAvatar?.trim().isNotEmpty == true;
    if (hasId && hasAvatar) return;

    final creatorId = play.userId?.trim();
    if (creatorId == null || creatorId.isEmpty) return;

    if (!ref.mounted || generation != _activateGeneration) return;
    if (index < 0 || index >= state.items.length) return;
    if (state.items[index].playbackId != item.playbackId) return;

    final patched = state.items[index].withCreator(creatorId: creatorId);
    if (patched.creatorId == state.items[index].creatorId) return;

    final items = [...state.items]..[index] = patched;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: items),
      currentDetail: index == state.currentIndex
          ? _detailFromFeedItem(patched)
          : null,
    );
    if (index == state.currentIndex) {
      _seedEngagement(patched, play);
    }
  }

  void _seedEngagement(
    RecommendFeedItem item,
    DramaPlayResponse? play, {
    DramaPlayResponse? authoritativePlay,
  }) {
    final creatorId = item.creatorId?.trim();
    final followed = item.followedByMe;
    if (creatorId != null &&
        creatorId.isNotEmpty &&
        followed != null &&
        ref.read(authControllerProvider).isLoggedIn) {
      ref
          .read(followStatusStoreProvider.notifier)
          .seedIfUnknown(creatorId, followed);
    }
    final episodeId = play?.episodeId ?? item.episodeId;
    if (episodeId == null || episodeId.isEmpty) return;
    final key = EpisodeEngagementKey.forEpisode(
      dramaId: item.dramaId,
      episodeId: episodeId,
      episodeNo: play?.episodeNo ?? episodeNoOf(item),
    );
    syncVisibleEpisodeEngagement(
      ref,
      key: key,
      engagement: VisibleEpisodeEngagement.fromPlayAndCard(
        play: play,
        cardLikedByMe: item.likedByMe,
        cardLikeCount: item.likeCount,
        cardCommentCount: item.commentCount,
        cardFavoritedByMe: item.favoritedByMe,
        cardFavoriteCount: item.favoriteCount,
        inferFavoriteCountWhenFavorited: true,
      ),
      authoritativePlay: authoritativePlay,
    );
  }

  /// Profile playlists may enter with a whole-drama row and then expand it
  /// into episodes. Their route seed intentionally omits episode engagement,
  /// so refresh the active episode once per session instead of trusting the
  /// repository's 24-hour play cache for its counters.
  void _refreshExternalEpisodeEngagement(RecommendFeedItem item) {
    if (!isExternalFeed || item.workType.isShortVideo) return;
    final dramaId = item.dramaId.trim();
    if (dramaId.isEmpty) return;
    final key = _playKey(item);
    if (!_engagementHydratedKeys.add(key)) return;
    unawaited(
      ref
          .read(engagementHydratorProvider)
          .hydrateEpisode(dramaId: dramaId, episodeNo: episodeNoOf(item)),
    );
  }

  Future<DramaPlayResponse?> resolvePlayForIndex(int index) async {
    if (index < 0 || index >= state.items.length) return null;
    final item = state.items[index];
    final play = await _resolvePlay(item);
    if (play != null && ref.mounted) {
      final resolvedItem = _applyResolvedEpisodeIdentity(index, item, play);
      _rememberPlay(resolvedItem, play);
    }
    return play;
  }

  RecommendFeedItem _applyResolvedEpisodeIdentity(
    int index,
    RecommendFeedItem item,
    DramaPlayResponse play,
  ) {
    final episodeId = play.episodeId?.trim();
    final resolvedEpisodeNo = switch (play.episodeNo) {
      final value? when value > 0 => value,
      _ => null,
    };
    final episodeIdChanged =
        episodeId != null &&
        episodeId.isNotEmpty &&
        episodeId != item.episodeId;
    final episodeNoChanged =
        resolvedEpisodeNo != null && resolvedEpisodeNo != item.episodeNo;
    if ((!episodeIdChanged && !episodeNoChanged) ||
        index < 0 ||
        index >= state.items.length) {
      return item;
    }
    final patched = item.withEngagement(
      resolvedEpisodeId: episodeIdChanged ? episodeId : null,
      resolvedEpisodeNo: episodeNoChanged ? resolvedEpisodeNo : null,
    );
    final items = [...state.items]..[index] = patched;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: items),
      currentDetail: index == state.currentIndex
          ? _detailFromFeedItem(patched)
          : null,
    );
    return patched;
  }

  /// Disk-warm farther neighbors after the active item has presented a frame.
  ///
  /// [skipDramaIds] are already covered by native prev/next slots — disk
  /// warm would only contend with decode.
  void warmNeighborsAfterFirstFrame({Set<String> skipDramaIds = const {}}) {
    if (!ref.mounted) return;
    final index = state.currentIndex;
    if (_neighborsWarmedForIndex == index) return;
    _neighborsWarmedForIndex = index;
    final generation = _prefetchGeneration;
    unawaited(
      _prefetchAround(
        index,
        skipDramaIds: skipDramaIds,
        generation: generation,
      ),
    );
  }

  /// Drop memory/prefetch play for the current item and re-fetch from network.
  ///
  /// Used by the recommend UI retry toast after loadUrl / frame failures. The
  /// common cause is expired or missing CloudFront cookies, so this has to go
  /// back to episode detail — rebinding the card's unsigned URL 403s again.
  Future<DramaPlayResponse?> refreshCurrentPlay() async {
    final item = state.currentItem;
    if (item == null || !item.hasPlayableIdentity) return null;
    final generation = ++_activateGeneration;
    final index = state.currentIndex;
    final playbackId = item.playbackId;
    bool targetStillCurrent() =>
        ref.mounted &&
        generation == _activateGeneration &&
        state.currentIndex == index &&
        state.currentItem?.playbackId == playbackId;
    final episodeNo = episodeNoOf(item);
    final key = _playKey(item);
    _playCache.remove(key);
    _playResolutionErrors.remove(key);
    _unsignedConfirmed.remove(key);
    if (!_shouldResolveByEpisodeId(item) && item.dramaId.isNotEmpty) {
      _drama.clearPrefetchCache(item.dramaId, episodeNo);
    }
    state = state.copyWith(isPlayLoading: true, clearLastError: true);
    try {
      final result = await _fetchEpisodeDetail(item, forceRefresh: true);
      if (!targetStillCurrent()) return null;
      final fetched = result.dataOrNull;
      if (fetched != null) {
        _untranscoded.remove(key);
        _playResolutionErrors.remove(key);
        final play = _withFeedEngagement(item, fetched);
        final resolvedItem = _applyResolvedEpisodeIdentity(
          state.currentIndex,
          item,
          play,
        );
        _rememberPlay(resolvedItem, play);
        state = state.copyWith(
          currentPlay: play,
          isPlayLoading: false,
          clearLastError: true,
        );
        return play;
      }
      if (FeedPlaybackPolicy.isUnplayableTranscodeError(result.errorOrNull)) {
        _untranscoded.add(key);
      } else if (result.errorOrNull case final error?) {
        _playResolutionErrors[key] = error;
      }
      state = state.copyWith(
        isPlayLoading: false,
        clearCurrentPlay: true,
        lastError: result.errorOrNull,
      );
      return null;
    } catch (e) {
      StoryLogger.d(
        'Recommend refreshCurrentPlay failed',
        error: e,
        tag: 'Rec',
      );
      if (!targetStillCurrent()) return null;
      final error = ApiError.unknown('Playback detail failed');
      _playResolutionErrors[key] = error;
      state = state.copyWith(
        isPlayLoading: false,
        clearCurrentPlay: true,
        lastError: error,
      );
      return null;
    }
  }

  static int episodeNoOf(RecommendFeedItem item) => item.resolvedEpisodeNo;

  String _playKey(RecommendFeedItem item) =>
      '${item.playbackId}_${episodeNoOf(item)}';

  /// 外部混合队列中的具体剧集按 episodeId 解析，避免 episodeNo 缺失时
  /// 播错集；整剧展开项没有 episodeId，仍按 dramaId + episodeNo 获取。
  bool _shouldResolveByEpisodeId(RecommendFeedItem item) {
    final episodeId = item.episodeId?.trim() ?? '';
    return item.workType.isShortVideo ||
        (isExternalFeed && episodeId.isNotEmpty);
  }

  Future<Result<DramaPlayResponse>> _fetchEpisodeDetail(
    RecommendFeedItem item, {
    bool forceRefresh = false,
  }) {
    if (_shouldResolveByEpisodeId(item)) {
      final episodeId = item.episodeId?.trim() ?? '';
      if (episodeId.isEmpty) {
        return Future.value(
          Result.failure(ApiError.unknown('missing episodeId')),
        );
      }
      return _drama.getEpisodeDetailByEpisodeId(episodeId);
    }
    if (forceRefresh) {
      return _drama.getEpisodeDetail(
        item.dramaId,
        episodeNoOf(item),
        forceRefresh: true,
      );
    }
    return _drama.getEpisodeDetail(item.dramaId, episodeNoOf(item));
  }

  Future<void> _calibrateExternalMetadata(
    int index,
    RecommendFeedItem item,
  ) async {
    if (!_metadataCalibrationStarted.add(_playKey(item))) return;
    try {
      final result = await _fetchEpisodeDetail(item, forceRefresh: true);
      final detail = result.dataOrNull;
      if (detail == null || !ref.mounted) return;
      if (index < 0 || index >= state.items.length) return;
      final current = state.items[index];
      if (current.playbackId != item.playbackId) return;

      final patched = current.withCreator(
        title: item.workType.isShortVideo ? detail.title : null,
        description: detail.description,
        creatorId: detail.creatorId,
        creatorName: detail.creatorName,
        creatorAvatar: detail.creatorAvatarUrl,
        overwriteExisting: true,
      );
      if (patched == current) return;
      final items = [...state.items]..[index] = patched;
      state = state.copyWith(
        pagination: state.pagination.copyWith(items: items),
        currentDetail: index == state.currentIndex
            ? _detailFromFeedItem(patched)
            : null,
      );
    } catch (e) {
      StoryLogger.d(
        'External playlist metadata calibration failed',
        error: e,
        tag: 'Rec',
      );
    }
  }

  DramaPlayResponse? _memoryPlay(RecommendFeedItem item) {
    final cached = _playCache[_playKey(item)];
    if (cached == null) return null;
    final cookies = cached.signedCookies;
    if (cookies != null && !cookies.isValid) {
      _playCache.remove(_playKey(item));
      return null;
    }
    return cached;
  }

  void _rememberPlay(RecommendFeedItem item, DramaPlayResponse play) {
    _playCache[_playKey(item)] = play;
  }

  static bool _hasUsableCookies(DramaPlayResponse? play) =>
      play != null && play.hasUsableSignedCookies;

  /// Whether the item's episode is still transcoding — the UI must not bind
  /// playback for it.
  bool isUntranscoded(RecommendFeedItem item) =>
      _untranscoded.contains(_playKey(item));

  /// Resolve a play payload for the current card.
  ///
  /// The recommend feed omits `signedCookies`. Episode detail is the only
  /// place they can appear; it is cache-backed (memory → Hive). When detail
  /// also has no cookies — the current test gateway — bind the media URL
  /// unsigned. [_unsignedConfirmed] skips refetching that miss on later
  /// swipes. Transcode failures still skip bind.
  ///
  /// Short-circuit: if the play URL is not on a CloudFront-protected host there
  /// is nothing a detail fetch could add, so skip the request entirely.
  Future<({DramaPlayResponse? play, DramaPlayResponse? authoritativePlay})>
  _ensureSignedPlay(RecommendFeedItem item, DramaPlayResponse? play) async {
    final key = _playKey(item);
    if (_untranscoded.contains(key)) {
      return (play: null, authoritativePlay: null);
    }
    if (_hasUsableCookies(play)) {
      return (play: play, authoritativePlay: play);
    }
    if (play != null && _unsignedConfirmed.contains(key)) {
      return (play: play, authoritativePlay: play);
    }

    // If the URL does not require CloudFront cookies, no detail fetch can help.
    final candidateUrl =
        play?.effectivePlayUrl ?? item.toPlayResponse()?.effectivePlayUrl;
    if (candidateUrl != null &&
        !VideoUrlHelpers.requiresCloudFrontCookies(candidateUrl)) {
      final resolved = play ?? item.toPlayResponse();
      return (play: resolved, authoritativePlay: resolved);
    }

    final result = await _fetchEpisodeDetail(item);
    final fetched = result.dataOrNull;
    if (fetched != null) {
      _playResolutionErrors.remove(key);
      // Cookies from the signed payload, counters from the card: detail can
      // be a 24h Hive hit, while the card is this session's data.
      final merged = _withFeedEngagement(item, fetched);
      _rememberPlay(item, merged);
      if (_hasUsableCookies(merged)) {
        _unsignedConfirmed.remove(key);
      } else {
        _unsignedConfirmed.add(key);
        if (merged.isUnsignedProtectedPlay) {
          StoryLogger.d(
            'Recommend binding unsigned CloudFront play '
            'drama=${item.dramaId} ep=${episodeNoOf(item)} '
            'url=${merged.effectivePlayUrl}',
            tag: 'Rec',
          );
        }
      }
      return (play: merged, authoritativePlay: fetched);
    }
    final error = result.errorOrNull;
    if (FeedPlaybackPolicy.isUnplayableTranscodeError(error)) {
      _untranscoded.add(key);
      _playResolutionErrors.remove(key);
      _playCache.remove(key);
      StoryLogger.w(
        'Recommend episode not transcoded, skipping playback '
        'drama=${item.dramaId} ep=${episodeNoOf(item)}',
        tag: 'Rec',
      );
      return (play: null, authoritativePlay: null);
    }
    if (result.isFailure) {
      if (error != null) _playResolutionErrors[key] = error;
      StoryLogger.d(
        'Recommend play-detail failed, using feed mediaAccessUrl '
        'drama=${item.dramaId}',
        tag: 'Rec',
      );
      if (isExternalFeed) return (play: null, authoritativePlay: null);
    }
    final fallback = play ?? item.toPlayResponse();
    if (fallback != null && !_hasUsableCookies(fallback)) {
      _unsignedConfirmed.add(key);
    }
    return (play: fallback, authoritativePlay: fallback);
  }

  Future<DramaPlayResponse?> _resolvePlay(RecommendFeedItem item) async {
    if (!item.hasPlayableIdentity) return null;
    if (_untranscoded.contains(_playKey(item))) return null;
    var play = _memoryPlay(item);
    if (play == null &&
        !_shouldResolveByEpisodeId(item) &&
        item.dramaId.isNotEmpty) {
      try {
        play = await _drama.peekPrefetchedEpisode(
          item.dramaId,
          episodeNoOf(item),
        );
      } catch (e) {
        StoryLogger.d('Recommend peek play failed', error: e, tag: 'Rec');
      }
    }
    if (play != null) {
      play = _withFeedEngagement(item, play);
      _rememberPlay(item, play);
      if (_hasUsableCookies(play)) return play;
    }
    try {
      final signed = await _ensureSignedPlay(item, play);
      return signed.play;
    } catch (e) {
      StoryLogger.d('Recommend resolvePlay failed', error: e, tag: 'Rec');
      if (_untranscoded.contains(_playKey(item))) return null;
      if (isExternalFeed) {
        _playResolutionErrors[_playKey(item)] = ApiError.unknown(
          'Playback detail failed',
        );
        return null;
      }
      return play ?? item.toPlayResponse();
    }
  }

  /// Overlay the feed card's interaction fields onto [play].
  ///
  /// [DramaRepository.peekPrefetchedEpisode] can return a play payload cached
  /// for up to 24h, and recommend no longer force-refreshes it. The feed list
  /// is the fresher source, so its counters win whenever it supplies them.
  DramaPlayResponse _withFeedEngagement(
    RecommendFeedItem item,
    DramaPlayResponse play,
  ) {
    return play.copyWith(
      // Keep API work id on [DramaPlayResponse.dramaId]. Slot / cover
      // identity uses [RecommendFeedItem.playbackId] /
      // [RecommendFeedItem.playbackIdOfPlay].
      episodeId: play.episodeId ?? item.episodeId,
      likeCount: item.likeCount,
      commentCount: item.commentCount,
      favoriteCount: item.favoriteCount,
      likedByMe: item.likedByMe,
      favoritedByMe: item.favoritedByMe,
    );
  }

  Future<void> _prefetchAround(
    int index, {
    Set<String> skipDramaIds = const {},
    int? generation,
  }) async {
    if (!ref.mounted) return;
    if (generation != null && generation != _prefetchGeneration) return;
    _warmNeighbors(index, skipDramaIds: skipDramaIds, generation: generation);

    // Only fetch the next page when this card is already the last one
    // (e.g. a 1-item first page). Do not prefetch pages ahead of the
    // playhead — that waits for a swipe / auto-advance onto the last card.
    final before = state.items.length;
    await loadMoreIfAtEnd();
    if (!ref.mounted) return;
    if (generation != null && generation != _prefetchGeneration) return;
    if (state.items.length > before) {
      _warmNeighbors(index, skipDramaIds: skipDramaIds, generation: generation);
    }
  }

  void _warmNeighbors(
    int index, {
    Set<String> skipDramaIds = const {},
    int? generation,
  }) {
    if (!ref.mounted) return;
    final isWifi = ref.read(connectivityProvider).isWifi;
    final ahead = isWifi
        ? StoryConstants.recommendPrefetchAheadWifi
        : StoryConstants.recommendPrefetchAheadCellular;
    unawaited(() async {
      for (var i = 1; i <= ahead; i++) {
        if (generation != null && generation != _prefetchGeneration) return;
        await _prefetchNeighbor(
          index + i,
          budgetRatio: 1.0,
          context: VideoPrecacheContext.recommendHead,
          skipDramaIds: skipDramaIds,
        );
        if (!ref.mounted) return;
      }
      if (generation != null && generation != _prefetchGeneration) return;
      await _prefetchNeighbor(
        index - 1,
        budgetRatio: isWifi ? 1.0 : StoryConstants.prefetchCellularBudgetRatio,
        skipDramaIds: skipDramaIds,
      );
    }());
  }

  Future<void> _prefetchNeighbor(
    int index, {
    required double budgetRatio,
    VideoPrecacheContext context = VideoPrecacheContext.episode,
    Set<String> skipDramaIds = const {},
  }) async {
    if (index < 0 || index >= state.items.length || budgetRatio <= 0) return;
    final item = state.items[index];
    if (!item.hasPlayableIdentity) return;
    if (skipDramaIds.contains(item.playbackId)) return;
    if (_untranscoded.contains(_playKey(item))) return;
    final episodeNo = episodeNoOf(item);
    try {
      final play = await _resolvePlay(item);
      if (play == null || !ref.mounted) return;
      FeedMediaPrefetch.warmHttpUrl(
        item.mediaAccessUrl,
        context: context,
        budgetRatio: budgetRatio,
      );
      await FeedMediaPrefetch.warmPlay(
        play,
        context: context,
        budgetRatio: budgetRatio,
      );
    } catch (e) {
      StoryLogger.d(
        'Recommend neighbor prefetch failed drama=${item.dramaId} ep=$episodeNo',
        error: e,
        tag: 'Rec',
      );
    }
  }

  Future<bool> dislikeCurrent() async {
    final item = state.currentItem;
    final videoId = item?.episodeId ?? state.currentPlay?.episodeId;
    if (item == null || videoId == null || videoId.isEmpty) return false;

    final result = await _recommend.dislike(videoId);
    if (!ref.mounted) return false;
    if (result.isFailure) {
      state = state.copyWith(lastError: result.errorOrNull);
      return false;
    }

    final index = state.currentIndex;
    final removedLastLoaded = index >= state.items.length - 1 && state.hasMore;
    final nextItems = [...state.items]..removeAt(index);
    _activateGeneration++;

    if (nextItems.isEmpty) {
      state = state.copyWith(
        pagination: state.pagination.copyWith(
          items: const [],
          hasMore: state.hasMore,
        ),
        currentIndex: 0,
        clearCurrentDetail: true,
        clearCurrentPlay: true,
        isUserPaused: false,
        isPlayLoading: false,
        clearLastError: true,
      );
      if (state.hasMore) {
        await loadMore();
        if (!ref.mounted) return true;
        if (state.items.isNotEmpty) {
          await activateIndex(0);
        }
      }
      return true;
    }

    // Disliked the last loaded card while more pages exist: fetch next page
    // and land on the first newly appended item (same index after removal).
    if (removedLastLoaded) {
      state = state.copyWith(
        pagination: state.pagination.copyWith(items: nextItems),
        currentIndex: nextItems.length - 1,
        clearCurrentDetail: true,
        clearCurrentPlay: true,
        isUserPaused: false,
        isPlayLoading: true,
        clearLastError: true,
      );
      final before = nextItems.length;
      await loadMore();
      if (!ref.mounted) return true;
      if (state.items.length > before) {
        await activateIndex(before);
      } else if (state.items.isNotEmpty) {
        await activateIndex(state.items.length - 1);
      }
      return true;
    }

    final nextIndex = index >= nextItems.length ? nextItems.length - 1 : index;
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: nextItems),
      currentIndex: nextIndex,
      clearCurrentDetail: true,
      clearCurrentPlay: true,
      isUserPaused: false,
      isPlayLoading: true,
      clearLastError: true,
    );
    await activateIndex(nextIndex);
    return true;
  }

  bool _autoPlayEnabled = false;
  bool get autoPlayEnabled => _autoPlayEnabled;
  set autoPlayEnabled(bool value) {
    if (_autoPlayEnabled == value) return;
    _autoPlayEnabled = value;
  }

  /// Comment / drama / character sheets: do not auto-advance underneath.
  final FeedOverlayHold _overlayHold = FeedOverlayHold();
  bool get overlayHoldsAdvance => _overlayHold.holdsAdvance;

  void beginOverlayHold() => _overlayHold.begin();

  void endOverlayHold() => _overlayHold.end();

  Future<T> holdAutoAdvance<T>(Future<T> Function() action) =>
      _overlayHold.run(action);

  /// 连播 off → loop the current card instead of pausing at EOS.

  void setUserPaused(bool paused) {
    if (state.isUserPaused != paused) {
      state = state.copyWith(isUserPaused: paused);
    }
  }

  Future<bool> toggleLike({RecommendFeedItem? target}) async {
    final item = target ?? state.currentItem;
    if (item == null) return false;
    final isCurrent = item.playbackId == state.currentItem?.playbackId;
    final play = isCurrent ? state.currentPlay : _memoryPlay(item);
    final dramaId = item.dramaId;
    final episodeId = play?.episodeId ?? item.episodeId;
    if (episodeId == null || episodeId.isEmpty) return false;
    final type = item.workType;
    final episodeNo = play?.episodeNo ?? episodeNoOf(item);

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
    );
    final engagement = VisibleEpisodeEngagement.fromPlayAndCard(
      play: play,
      cardLikedByMe: item.likedByMe,
      cardLikeCount: item.likeCount,
      cardCommentCount: item.commentCount,
    );
    final store = ref.read(episodeEngagementProvider(key));
    final result = await episodeEngagementNotifier(ref, key).toggleLike(
      episodeNo: episodeNo,
      type: type,
      authorUserId: item.creatorId ?? play?.userId,
      likedByMeBaseline: store.likedByMe ?? engagement.likedByMe,
    );
    if (result == null || result.isFailure || !ref.mounted) return false;

    final settled = ref.read(episodeEngagementProvider(key));
    _patchItemEngagement(
      item,
      likedByMe: settled.likedByMe,
      likeCount: settled.likeCount,
    );
    return true;
  }

  Future<bool> toggleFavorite({RecommendFeedItem? target}) async {
    final item = target ?? state.currentItem;
    if (item == null) return false;
    final isCurrent = item.playbackId == state.currentItem?.playbackId;
    final play = isCurrent ? state.currentPlay : _memoryPlay(item);
    final episodeId = item.episodeId ?? play?.episodeId;
    if (episodeId == null || episodeId.isEmpty) return false;

    final key = EpisodeEngagementKey.forEpisode(
      dramaId: item.dramaId,
      episodeId: episodeId,
      episodeNo: play?.episodeNo ?? episodeNoOf(item),
    );
    final engagement = VisibleEpisodeEngagement.fromPlayAndCard(
      play: play,
      cardFavoritedByMe: item.favoritedByMe,
      cardFavoriteCount: item.favoriteCount,
      inferFavoriteCountWhenFavorited: true,
    );
    final store = ref.read(episodeEngagementProvider(key));
    final result = await episodeEngagementNotifier(ref, key).toggleWorkFavorite(
      episodeNo: play?.episodeNo ?? episodeNoOf(item),
      type: item.workType,
      authorUserId: item.creatorId ?? play?.userId,
      favoritedByMeBaseline: store.favoritedByMe ?? engagement.favoritedByMe,
    );
    if (result == null || result.isFailure || !ref.mounted) return false;

    final settled = ref.read(episodeEngagementProvider(key));
    _patchItemEngagement(
      item,
      favoritedByMe: settled.favoritedByMe,
      favoriteCount: settled.favoriteCount,
    );
    return true;
  }

  /// Write a settled engagement result back onto the current feed card.
  ///
  /// The engagement stores are only retained for a short window after their
  /// last listener; once one is rebuilt it re-seeds from the card. Without
  /// this the like / favorite would visually revert on the next activation.
  void _patchCurrentItem({
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? favoriteCount,
    int? commentCount,
  }) {
    final item = state.currentItem;
    if (item == null) return;
    _patchItemEngagement(
      item,
      likedByMe: likedByMe,
      likeCount: likeCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      commentCount: commentCount,
    );
  }

  void _patchItemEngagement(
    RecommendFeedItem item, {
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? favoriteCount,
    int? commentCount,
  }) {
    final index = state.items.indexWhere(
      (entry) => entry.playbackId == item.playbackId,
    );
    if (index < 0) return;
    final patched = state.items[index].withEngagement(
      likedByMe: likedByMe,
      likeCount: likeCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      commentCount: commentCount,
    );
    final items = [...state.items]..[index] = patched;
    final isCurrent = index == state.currentIndex;
    final play = isCurrent ? state.currentPlay : null;
    final nextPlay = play == null ? null : _withFeedEngagement(patched, play);
    if (nextPlay != null) _rememberPlay(patched, nextPlay);
    state = state.copyWith(
      pagination: state.pagination.copyWith(items: items),
      currentDetail: isCurrent
          ? _detailFromFeedItem(patched)
          : state.currentDetail,
      currentPlay: isCurrent ? nextPlay : state.currentPlay,
    );
  }

  void resetEpisodeMetrics() => _resetEpisodeMetrics();

  void onEpisodeMetricsPlayStart() => _episodeMetrics.onPlayStart();

  void onEpisodeMetricsPause() => _episodeMetrics.onPause();

  void onEpisodeMetricsTimeUpdate(int positionMs, int durationMs) {
    _applyEpisodeMetricsSignals(
      _episodeMetrics.onTimeUpdate(positionMs, durationMs),
    );
  }

  void onEpisodeMetricsNaturalEnd(int positionMs, int durationMs) {
    final durationSec = durationMs > 0 ? durationMs / 1000.0 : null;
    final signals = _episodeMetrics.tracker.onNaturalPlaybackEnd(
      positionSeconds: positionMs > 0 ? positionMs / 1000.0 : null,
      durationSeconds: durationSec,
    );
    if (!signals.reportComplete && !signals.reportPlay) {
      StoryLogger.d(
        'metrics EOS produced no report posMs=$positionMs durMs=$durationMs',
        tag: 'play-report-api',
      );
    }
    _applyEpisodeMetricsSignals(signals);
  }

  void _resetEpisodeMetrics() {
    _episodeMetrics.reset();
  }

  void _applyEpisodeMetricsSignals(PlaybackEpisodeMetricsSignals signals) {
    final item = state.currentItem;
    final episodeId = item?.episodeId ?? state.currentPlay?.episodeId;
    if (item == null || episodeId == null || episodeId.isEmpty) {
      if (signals.reportPlay || signals.reportComplete) {
        StoryLogger.d(
          'drop track reason=noEpisodeId '
          'play=${signals.reportPlay} complete=${signals.reportComplete}',
          tag: 'play-report-api',
        );
      }
      return;
    }

    _episodeMetrics.applySignals(
      signals,
      fireTrack: (EpisodeTrackEvent event) => _tracking.fireTrack(
        dramaId: item.dramaId,
        episodeId: episodeId,
        event: event,
        type: item.workType,
      ),
    );
  }

  void maybeTrackWatchHistory(int positionMs) {
    final episodeId =
        state.currentItem?.episodeId ?? state.currentPlay?.episodeId;
    if (!_watchHistoryGate.shouldReportPlay(
      positionMs: positionMs,
      episodeId: episodeId,
    )) {
      return;
    }
    _watchHistoryGate.markReported(episodeId: episodeId);
    reportWatchHistory(ref, episodeId!, EpisodeTrackEvent.play);
  }

  /// Flush queued watch-history when the feed is no longer the visible surface.
  void flushPendingWatchHistory() {
    Future.microtask(() {
      if (!ref.mounted) return;
      unawaited(ref.read(watchHistoryBatchReporterProvider.notifier).flush());
    });
  }

  void _reportRecommendActivateTelemetry() {
    _activateTelemetry.reportActivate(fromNeighbor: false);
  }

  void reportRecommendFirstFrameTelemetry() {
    _activateTelemetry.reportFirstFrame(
      fallbackPlaybackId: state.currentItem?.playbackId,
    );
  }

  void onCommentPosted() {
    final item = state.currentItem;
    if (item == null) return;
    _patchCurrentItem(commentCount: (item.commentCount ?? 0) + 1);
  }

  /// Pull settled engagement values from the shared stores onto the current
  /// card. The detail sheet posts comments and force-refreshes counts through
  /// those stores directly, so the feed card would otherwise stay behind.
  void syncEngagementFromStores() {
    final item = state.currentItem;
    if (item == null) return;
    final episodeId = state.currentPlay?.episodeId ?? item.episodeId;
    final episode = (episodeId == null || episodeId.isEmpty)
        ? null
        : ref.read(
            episodeEngagementProvider(
              EpisodeEngagementKey.forEpisode(
                dramaId: item.dramaId,
                episodeId: episodeId,
                episodeNo: state.currentPlay?.episodeNo ?? episodeNoOf(item),
              ),
            ),
          );
    _patchCurrentItem(
      likedByMe: episode?.likedByMe,
      likeCount: episode?.likeCount,
      commentCount: episode?.commentCount,
      favoritedByMe: episode?.favoritedByMe,
      favoriteCount: episode?.favoriteCount,
    );
  }

  static DramaDetail _detailFromFeedItem(RecommendFeedItem item) {
    return DramaDetail(
      id: item.dramaId,
      userId: item.creatorId,
      title: item.title,
      description: item.description,
      coverUrl: item.posterUrl,
      totalEpisodes: item.totalEpisodes,
      badge: item.badge,
      creatorName: item.creatorName,
      creatorAvatarUrl: item.creatorAvatar,
      tags: item.tags,
      avgRating: item.avgRating,
      favoriteCount: item.favoriteCount,
      totalPlayCount: item.playCount,
      totalCompletedViewCount: item.completeCount,
      roles: item.roles,
    );
  }
}

final recommendFeedControllerProvider =
    NotifierProvider.autoDispose<RecommendFeedController, RecommendFeedState>(
      RecommendFeedController.new,
    );
