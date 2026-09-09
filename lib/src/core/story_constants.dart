/// Common durations used across the app.
class StoryDurations {
  StoryDurations._();

  // Player
  static const Duration playerRetryBaseDelay = Duration(milliseconds: 300);
  static const Duration playerControlsAutoHide = Duration(seconds: 4);
  static const Duration playerViewReadyDelay = Duration(milliseconds: 500);
  static const Duration prefetchPreviousDelay = Duration(seconds: 2);

  /// Base delay for adjacent episode retry (multiplied by attempt number).
  static const Duration adjacentRetryBaseDelay = Duration(milliseconds: 350);

  /// After the active episode paints a frame, wait this long before neighbor
  /// loadUrl. Too short (≪150ms) overlaps a second AVPlayer/ExoPlayer decode
  /// with migrateToActive and freezes the visible texture while audio continues.
  /// Keep ≥600ms so promote → first stable playing settles before a neighbor
  /// loadUrl can pause the active player (iOS) or starve its buffer (Android).
  static const Duration adjacentPreloadAfterPlaying = Duration(
    milliseconds: 700,
  );

  /// Extra delay for the reverse-direction neighbor after the primary side
  /// finishes. Keep short — primary already waited [adjacentPreloadAfterPlaying]
  /// + Active-stable gate; another full 700ms makes reverse warm too late for
  /// fast swipes.
  static const Duration adjacentPreloadReverseExtra = Duration(
    milliseconds: 250,
  );

  /// Poll while waiting for the first painted frame before arming neighbor warm.
  static const Duration adjacentPreloadFramePoll = Duration(milliseconds: 200);

  /// App was backgrounded for less than this → skip cookie refresh / soft
  /// settle and just play() (Control Center flaps, quick app switcher).
  static const Duration foregroundBriefBackground = Duration(
    milliseconds: 1500,
  );

  /// Longer than this in background → AVPlayer/ExoPlayer buffers and
  /// CloudFront cookies are usually stale; skip soft resume and reload.
  static const Duration foregroundLongBackground = Duration(seconds: 45);

  /// Soft foreground resume first-frame budget (longer than cold play —
  /// surface/cookie settle takes extra time after returning).
  static const Duration foregroundSoftFrameBudget = Duration(seconds: 6);

  /// Brief-background resume frame budget.
  static const Duration foregroundBriefFrameBudget = Duration(seconds: 2);

  /// How long a picker jump waits for silent preload before falling to cold.
  static const Duration jumpPreloadRaceBudget = Duration(milliseconds: 900);

  /// Cap for waiting on an in-flight neighbor decode before controlled cold.
  /// Same budget as jump race — limbo under a poster feels worse than cold.
  static const Duration waitInFlightRaceBudget = jumpPreloadRaceBudget;

  /// Brief gap before a second CloudFront cookie MethodChannel attempt after
  /// timeout (queue is free; one more short try often succeeds on weak net).
  static const Duration cookieApplyRetryGap = Duration(milliseconds: 300);

  /// Delay between successive prefetch requests to avoid network contention.
  /// Lower on WiFi (fast pipe), the initial constant is a safe upper-bound
  /// that prevents thundering-herd when the connection is slow.
  static const Duration prefetchInterRequestDelay = Duration(milliseconds: 80);

  /// Brief pause so an underlying native player can finish dispose before init.
  static const Duration nativePlayerHandoffDelay = Duration(milliseconds: 350);

  static const Duration nativePlayerReleaseDelay = Duration(milliseconds: 80);

  /// After popping the drama player, wait for the route transition before
  /// disposing AVPlayers (concurrent dispose wedges the iOS main thread).
  static const Duration nativePlayerDisposeAfterPop = Duration(
    milliseconds: 600,
  );

  /// Gap between sequential native controller disposes on feed exit.
  static const Duration nativePlayerDisposeStagger = Duration(
    milliseconds: 120,
  );

  /// Switch playback reuses an initialized view — shorter settle time.
  /// At 60 fps, 50 ms ≈ 3 frames, which is enough for platform-view
  /// surface renderability per Apple/Android compositor guidelines.
  static const Duration playerViewReadyDelaySwitch = Duration(milliseconds: 50);

  // Toast
  static const Duration toastDefault = Duration(seconds: 3);
  static const Duration toastError = Duration(seconds: 5);

  // Navigation
  static const Duration navigationTransition = Duration(seconds: 1);

  // API
  static const Duration apiConnectTimeout = Duration(seconds: 15);
  static const Duration apiReceiveTimeout = Duration(seconds: 60);

  // Auth
  static const Duration authStateDebounce = Duration(milliseconds: 300);

  // Animation
  static const Duration animationFast = Duration(milliseconds: 280);
  static const Duration animationMedium = Duration(milliseconds: 500);
  static const Duration animationSkeleton = Duration(milliseconds: 1200);
}

/// Common string constants.
class StoryStrings {
  StoryStrings._();

  // Tags (logging)
  static const String tagAuth = 'Auth';
  static const String tagPlayer = 'Player';
  static const String tagPrivy = 'Privy';
  static const String tagSdk = 'StorySdk';
}

/// Common integer constants.
class StoryConstants {
  StoryConstants._();

  // Player
  static const int playerMaxRetries = 3;
  static const int playerThrottleIntervalMs = 1000;

  /// Business code for "episode is still transcoding". The rendition the feed
  /// card points at does not exist yet, so playback must be skipped instead of
  /// retried.
  static const int episodeTranscodeFailedCode = 121019;

  /// Recommend cards are swipeable — a stuck card must not hold the UI for
  /// `playerMaxRetries * playerOperationTimeout` (45s observed on dev).
  static const int recommendMaxRetries = 2;
  static const Duration recommendLoadTimeout = Duration(seconds: 8);

  /// Hard ceiling for HLS ABR (L1): never select video taller than this.
  ///
  /// When the ladder includes variants ≤ this height, [PlaybackEngine] caps
  /// via native `preferredMaximumResolution` / peak bitrate. If every rung
  /// is taller, it falls back to the lowest available variant.
  static const int maxPlaybackVideoHeight = 1080;

  /// Cellular startup soft peak (L2): temporarily constrain ABR to this
  /// height so the first frame lands on a cheaper rung, then release to
  /// Auto (still under [maxPlaybackVideoHeight]).
  ///
  /// No-op when the ladder never exceeds this height (e.g. 360/480 only).
  static const int cellularSoftPeakVideoHeight = 480;
  static const Duration playerOperationTimeout = Duration(seconds: 15);

  /// play / pause / seek / setVolume. Native method-channel calls can hang
  /// forever when the platform view was disposed mid-call — never await them
  /// without a short budget or the feed activate queue wedges the UI.
  static const Duration playerControlTimeout = Duration(seconds: 2);

  /// Fixed height of the player comment / drama-detail bottom sheet.
  /// The feed collapses the native surface into the remaining top band while
  /// this sheet is open, then restores full-bleed on dismiss.
  ///
  /// Collapse height must use **window** height (`MediaQuery.size.height -
  /// playerOverlaySheetHeight`), not Scaffold body height — root-navigator
  /// sheets pin to the screen bottom; body-only math leaves a bottom-nav gap.
  static const double playerOverlaySheetHeight = 570;

  /// Maximum time from a successful native play command to a frame reaching
  /// the native render pipeline.
  static const Duration playerFirstFrameTimeout = Duration(seconds: 4);

  /// Playing position may advance while a detached/stale surface paints no
  /// frames. Heartbeats arrive every ~250ms; this budget tolerates brief stalls.
  static const Duration playerFrameStallThreshold = Duration(
    milliseconds: 1800,
  );

  /// Wait after a surface nudge for a fresh frame before forcing reactivation.
  static const Duration playerFrameRecoveryTimeout = Duration(
    milliseconds: 1200,
  );

  /// Shorter timeout for theater banner preview init — carousel handoff must
  /// not stay blocked for a full feed-length operation timeout.
  static const Duration bannerPlayerInitTimeout = Duration(seconds: 8);

  // Prefetch
  /// Number of episodes to prefetch ahead on WiFi (metadata + cover stills).
  static const int prefetchWindowWifi = 5;

  /// WiFi disk-segment warm window (≤ [prefetchWindowWifi]).
  /// N+1 full budget + N+2 partial so a fast double-swipe does not always
  /// cold-load. Keep ≤2 while sources are often single-variant 4K.
  /// Farther rungs still get metadata without competing for HLS bytes.
  static const int prefetchDiskWindowWifi = 2;

  /// Number of episodes to prefetch ahead on cellular.
  static const int prefetchWindowCellular = 1;

  /// Number of episodes to prefetch behind.
  static const int prefetchWindowBackward = 1;

  /// Fraction of the byte budget to use on cellular vs WiFi.
  /// 0.25 = 25% of the WiFi prefetch budget.
  static const double prefetchCellularBudgetRatio = 0.25;

  /// Disk-segment budget ratio by distance from the playing episode on WiFi.
  /// N+1 full; N+2 partial head so continuous swipes stay warm without
  /// starving the active decode.
  static double prefetchDiskBudgetRatioForDistance(int distance) {
    return switch (distance) {
      1 => 1.0,
      2 => 0.35,
      _ => 0.0,
    };
  }

  /// Max distance from the current episode to keep in-memory episode states.
  /// Keep ≥ [prefetchWindowWifi] so N+5 metadata is not evicted immediately.
  static const int episodeStateEvictWindow = 5;

  /// During a vertical swipe, once drag progress toward a *preloaded*
  /// neighbor exceeds this fraction of a page, activate that episode
  /// immediately (don't wait for PageView settle / debounce).
  /// Kept ≥0.55 so the destination platform view is mostly on-screen before
  /// migrateToActive play — earlier swaps correlated with frozen video + audio.

  /// Legacy floor used in tests; client play gating uses
  /// [PlaybackEpisodeMetricsTracker.playThresholdSeconds].
  static const int playEpisodeTrackMinMs = 5000;

  /// Enforce [maxPlayTracksPerDay] / [maxCompleteTracksPerDay] client-side
  /// before calling the API (backend also caps per UTC calendar day).
  static const bool enableEpisodeTrackDailyLimits = true;

  /// Max valid `play-episode` reports per user/drama/episode/calendar day.
  /// Only applied when [enableEpisodeTrackDailyLimits] is true.
  static const int maxPlayTracksPerDay = 5;

  /// Max valid `complete-episode` reports per user/drama/episode/calendar day.
  /// Only applied when [enableEpisodeTrackDailyLimits] is true.
  static const int maxCompleteTracksPerDay = 1;

  /// Backend cap for `POST /api/mini-drama/user/watch-history/report`.
  static const int watchHistoryBatchMaxItems = 20;

  /// Debounced flush delay after the last enqueued watch-history item.
  static const Duration watchHistoryBatchFlushDelay = Duration(seconds: 30);

  /// Prefix applied to the installation UUID when sending `Device-ID`.
  static const String deviceIdReportingPrefix = 'app-';

  static const double feedEarlyActivateProgress = 0.58;

  /// Pager offset from the playing card before scroll-direction preload is
  /// biased (recommend + short-drama). Audio duck uses
  /// [feedEarlyActivateProgress] instead — mid-swipe must stay audible.
  static const double feedPagerDriftThreshold = 0.08;

  /// During playback, once progress exceeds this ratio, warm disk cache for
  /// the next episode (metadata + segments) without touching the native
  /// preload slot — so reverse-swipe swap stays intact.
  static const double feedProgressWarmNextRatio = 0.72;

  // Video precache (Android disk cache byte budgets)
  /// HLS: warm playlist + first segments (playlist + ~6-10s of segments).
  /// 8MB covers the master playlist, media playlist, and 4-5 leading segments
  /// on typical single-variant 4K CDN packs. Balances warm-start latency
  /// against MediaCodec buffer churn during active playback.
  /// Also used as [NativeVideoPlayerConfig.androidPrecacheBytes] so the
  /// plugin default and [VideoPrecacheService] share one budget.
  static const int precacheBytesHls = 8 * 1024 * 1024;

  /// MP4 progressive: warm moov + leading media for fast start.
  static const int precacheBytesMp4 = 30 * 1024 * 1024;

  /// Banner HLS preview clips are short — keep warm small so theater
  /// precache does not starve the focused preview decode.
  static const int precacheBytesBannerHls = 2 * 1024 * 1024;

  /// Banner MP4 preview — moov + leading frames only.
  static const int precacheBytesBannerMp4 = 3 * 1024 * 1024;

  /// Recommend For You: disk-warm the first ~6s of the next N cards.
  /// Native slots already cover N±1; this is only for farther cards.
  static const int recommendPrefetchAheadWifi = 2;
  static const int recommendPrefetchAheadCellular = 1;

  /// Byte cap for one recommend head warm (playlist + first ~6s segment).
  /// Shared for HLS/MP4 so five queued warms cannot pin a full MP4 mdat.
  static const int precacheBytesRecommendHead = 4 * 1024 * 1024;

  /// Fallback when the URL format is unknown.
  static const int precacheBytesDefault = 20 * 1024 * 1024;

  /// LRU cap for in-memory playback frame JPEG snapshots.
  static const int playbackFrameMemoryMaxEntries = 80;

  /// Max JPEG files kept under temp/playback_frames (oldest trimmed).
  static const int playbackFrameDiskMaxEntries = 120;

  /// Max total bytes for playback frame disk cache (100MB).
  /// Trimming evicts oldest files when total exceeds this, preventing
  /// high-res frames from filling temp directory.
  static const int playbackFrameDiskMaxBytes = 100 * 1024 * 1024;

  /// Trim slack for the playback frame disk cache. Trimming scans the whole
  /// directory + statSync each file, so it runs only once the directory has
  /// grown [playbackFrameDiskTrimSlack] files past [playbackFrameDiskMaxEntries]
  /// instead of after every single capture (avoids micro-jank while scrolling).
  static const int playbackFrameDiskTrimSlack = 20;

  /// Downscale width for native captureCurrentFrame (balance size vs clarity).
  static const int playbackFrameCaptureMaxWidth = 480;

  /// How many neighbor episodes to warm in the first-frame JPEG cache around
  /// the current page (current ± radius). Wider than the native neighbor
  /// mount window so swipe posters are ready before Platform Views attach.
  static const int playbackFramePrimeRadius = 2;

  // Pagination
  static const int defaultPageSize = 20;

  // Feed slot management
  /// Infinite distance used in slot sorting to push empty/stale slots to the end.
  static const int infiniteSlotDistance = 1 << 30;

  /// Minimum playhead position (ms) before migrateToActive seeks to zero.
  /// Below this threshold the player is effectively at the start, so seeking
  /// wastes a platform-channel roundtrip and can trigger a seek storm.
  /// Seek-to-0 before migrate play only when playhead moved past this.
  ///
  /// A low threshold (e.g. 80ms) seeks after a brief play→pause from a
  /// superseded swipe; that seekTo(0)+play pattern freezes the video track
  /// while audio continues. Keep this high enough that only real mid-episode
  /// reverse-swipe reuse seeks.
  static const int migrateSeekThresholdMs = 2000;

  /// Maximum displayed favorite count to prevent overflow in UI.
  static const int maxFavoriteCountDisplay = 9999999;

  /// How long an engagement store (favorite/like/comment counts) survives
  /// after its last listener is gone. Bridges quick page hops
  /// (detail → back → detail, feed → detail → feed) without keeping
  /// per-drama state alive forever.
  static const Duration engagementStoreRetention = Duration(minutes: 3);

  /// Page size when hydrating the current user's following set for player
  /// follow badges. Recommend only needs `creatorId ∈ followingIds`.
  static const int followingsHydratePageSize = 100;

  /// Safety cap so a huge following list cannot loop forever.
  static const int followingsHydrateMaxPages = 20;

  /// Minimum interval between AppLifecycle-driven on-chain wallet refreshes.
  /// Avoids hammering RPC when the user briefly backgrounds the app.
  static const Duration walletBalanceResumeThrottle = Duration(seconds: 15);

  /// Minimum interval between Profile-tab visibility revalidations
  /// (bottom-nav re-entry, resume, connectivity recovery). Avoids duplicate
  /// list/stats requests when the user flips tabs quickly.
  static const Duration profileTabRevalidateThrottle = Duration(seconds: 15);

  /// Minimum interval between AppLifecycle-driven global config refreshes.
  /// `globalConfigProvider` has no autoDispose, so without this it only
  /// refetches on a true cold start (process killed), not on resume from background.
  static const Duration globalConfigResumeThrottle = Duration(minutes: 15);

  /// Agent V3 only polls while its retained tab is visible and the app is in
  /// the foreground. Resume, tab activation and connectivity recovery bypass
  /// this interval and calibrate immediately.
  static const Duration agentV3SyncInterval = Duration(seconds: 60);

  /// Prevents a burst of lifecycle/tab callbacks from starting redundant
  /// calibrations while still allowing every genuine page re-entry to recheck.
  static const Duration agentV3SyncDebounce = Duration(seconds: 3);

  /// Search overlay keyword → API debounce.
  static const Duration searchQueryDebounce = Duration(milliseconds: 300);

  /// Default USDC mint/issue fee used as soft pre-check and digest fallback
  /// when [feeAmount] is missing (aligned with web ACTOR_COLLECTION_ISSUE_FEE).
  static const double defaultMintFeeUsdc = 1.0;

  // Cache
  /// High-water mark for Hive cache file size.
  /// When [StoryLocalRepositoryImpl.vacuumCache] detects the on-disk Hive
  /// file exceeds this threshold, it evicts the oldest 25% of cache entries
  /// (by cachedAt / expiresAt) to reclaim space.
  static const int hiveCacheHighWaterBytes = 500 * 1024 * 1024;

  /// Flutter [ImageCache] entry cap (decoded bitmaps held in RAM).
  static const int imageCacheMaxEntries = 5000;

  /// Flutter [ImageCache] byte cap (decoded bitmaps held in RAM).
  static const int imageCacheMaxBytes = 500 * 1024 * 1024;

  // UI
  static const int maxDramaTitleLines = 2;
  static const int maxActorNameLines = 1;
  static const int maxSynopsisLines = 3;
}

/// Common API response codes.
class ApiResponseCode {
  ApiResponseCode._();

  /// Success codes
  static const int success = 100000;
  static const int successAlt = 200;

  /// Unauthorized codes
  static const int unauthorized = 100401;
  static const int unauthorizedAlt = 100001;

  /// 评论不存在（回复评论时目标评论已被删除等）。
  static const int commentNotExists = 125101;

  /// 邀请码无效（绑定邀请码时）。
  static const int inviteCodeInvalid = 110008;

  /// 账号已绑定邀请码（重复绑定）。
  static const int inviteCodeAlreadyBound = 110045;
}

/// Sentinel [BusinessError.message] values mapped in [BuildContext.l10nError]
/// for comment reply block pre-checks (拉黑拦截本地提示，非服务端错误码)。
abstract final class CommentBlockErrorMessages {
  /// 当前用户已拉黑被回复方。
  static const blockedByMe = 'COMMENT_BLOCKED_BY_ME';

  /// 被回复方已拉黑当前用户。
  static const blockedByTarget = 'COMMENT_BLOCKED_BY_TARGET';
}

/// Sentinel [BusinessError.message] values mapped in [BuildContext.l10nError]
/// for follow block pre-checks (拉黑关系中禁止关注)。
abstract final class FollowBlockErrorMessages {
  /// 当前用户已拉黑被关注方。
  static const blockedByMe = 'FOLLOW_BLOCKED_BY_ME';

  /// 被关注方已拉黑当前用户。
  static const blockedByTarget = 'FOLLOW_BLOCKED_BY_TARGET';
}

/// Sentinel [BusinessError.message] values mapped in [BuildContext.l10nError]
/// for like block pre-checks (拉黑关系中禁止点赞作品/单集)。
abstract final class LikeBlockErrorMessages {
  /// 当前用户已拉黑作品作者。
  static const blockedByMe = 'LIKE_BLOCKED_BY_ME';

  /// 作品作者已拉黑当前用户。
  static const blockedByTarget = 'LIKE_BLOCKED_BY_TARGET';
}

/// Sentinel [BusinessError.message] values mapped in [BuildContext.l10nError]
/// for favorite block pre-checks (拉黑关系中禁止收藏作品/短剧)。
abstract final class FavoriteBlockErrorMessages {
  /// 当前用户已拉黑作品/短剧作者。
  static const blockedByMe = 'FAVORITE_BLOCKED_BY_ME';

  /// 作品/短剧作者已拉黑当前用户。
  static const blockedByTarget = 'FAVORITE_BLOCKED_BY_TARGET';
}

/// Sentinel [BusinessError.message] values mapped in [BuildContext.l10nError]
/// for rating block pre-checks (拉黑关系中禁止为短剧评分)。
abstract final class RatingBlockErrorMessages {
  /// 当前用户已拉黑短剧作者。
  static const blockedByMe = 'RATING_BLOCKED_BY_ME';

  /// 短剧作者已拉黑当前用户。
  static const blockedByTarget = 'RATING_BLOCKED_BY_TARGET';
}

/// Logical widths for image cache sizing.
///
/// These are logical (CSS-like) pixel values, NOT multiplied by DPR.
/// Pass to [StoryCachedImage.memCacheForLogicalWidth] to compute the
/// device-specific [CachedNetworkImage.memCacheWidth].
///
/// Convention: divide a fixed pixel value by 3 (typical DPR) to get the
/// logical width, or use the actual rendered logical width directly.
class StoryImageCache {
  StoryImageCache._();

  /// 24 logical px — tiny avatar/icon (BoundActorAvatar 24px, stats icon).
  static const double avatarTiny = 24;

  /// 32 logical px — small avatar (hero banner small avatar).
  static const double avatarSmall = 32;

  /// 60 logical px — card thumbnail in actor cast list.
  static const double cardThumbnail = 60;

  /// 80 logical px — search result thumbnail.
  static const double searchThumbnail = 80;

  /// 160 logical px — edit form avatar / game actor card.
  static const double avatarEdit = 160;

  /// 180 logical px — drama card cover / hero banner image.
  static const double cardCover = 180;

  /// 200 logical px — drama role card cover.
  static const double coverRole = 200;

  /// 240 logical px — detail page cover.
  static const double coverDetail = 240;

  /// 48 logical px — game deploy slot avatar.
  static const double gameSlotAvatar = 48;

  /// 400 logical px — management card cover.
  static const double coverManagement = 400;
}

/// Common size constants used in UI layouts.
class StorySizes {
  StorySizes._();

  // Icon / avatar sizes
  static const double iconBack = 20;
  static const double iconNav = 24;
  static const double iconPlay = 36;
  static const double iconPlayLarge = 64;

  /// Player / detail play triangle (Figma Polygon 1).
  static const double playerPlayIconWidth = 68;
  static const double playerPlayIconHeight = 68;
  static const double avatarSmall = 30;

  /// Player right-rail creator avatar (recommend + short drama).
  static const double avatarMedium = 50;

  // Button / touch targets
  static const double touchIcon = 40;
  static const double touchIconSmall = 36;

  // Loading indicators
  static const double loadingSmall = 32;
  static const double loadingInline = 24;
  static const double loadingStroke = 2.75;

  // Label widths
  static const double labelMaxWidth = 56;

  // Drag handle
  static const double dragHandleWidth = 32;
  static const double dragHandleHeight = 4;

  // Player gradients
  static const double playerGradientTopHeight = 192;
  static const double playerGradientBottomHeight = 384;

  // Video feed rail (icon + hit target 48, inset 8 from right)
  static const double videoFeedRailIconSize = 48;
  static const double videoFeedRailHitSize = 48;
  static const double videoFeedRailRightInset = 8;
  static const double videoFeedRailItemGap = 6;

  /// Right-rail column width: avatar may exceed icon hit target.
  static double get videoFeedRailWidth =>
      avatarMedium > videoFeedRailHitSize ? avatarMedium : videoFeedRailHitSize;
}
