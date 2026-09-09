import 'package:better_native_video_player/better_native_video_player.dart';

import 'playback_engine.dart';

/// A single playback slot in the triple-player feed architecture.
///
/// Shared by the episode player ([VideoFeedController] via
/// [FeedSlotCoordinator]) and the Recommend feed ([RecommendFeedBody]).
/// Both run three native player slots — one active, two preload neighbors —
/// and both previously kept a parallel, slightly-divergent slot state class
/// (`RecommendPlayerSlot` and `FeedSlotState`). This unifies them.
///
/// The two consumers use disjoint subsets of these fields:
/// - **Recommend**: [engine], [native], [playbackId], [index], [surfaceReady],
///   [frameReady].
/// - **Episode player**: [engine], [generation], [loadingEpisodeNo],
///   [inFlightFuture], [activationReserved].
class FeedSlot {
  PlaybackEngine? engine;
  NativeVideoPlayerController? native;

  /// Item identity this slot is (being) bound to.
  /// Recommend uses `dramaId:episodeId` (the card playback identity), not the
  /// API work id on [PlaybackEngine.dramaId].
  String? playbackId;

  /// Slot index within the pool. Recommend stores the feed card index here.
  int? index;

  /// Platform view is in the tree (needed before `initialize()`).
  bool surfaceReady = false;

  /// Native slot has painted a frame for [playbackId] — cover may unmount.
  bool frameReady = false;

  /// Bumped on reuse so in-flight load callbacks can detect stale slots.
  int generation = 0;

  /// Episode currently loading on this slot (episode player only).
  int? _loadingEpisodeNo;
  int? get loadingEpisodeNo => _loadingEpisodeNo;
  set loadingEpisodeNo(int? value) {
    if (_loadingEpisodeNo == value) return;
    _loadingEpisodeNo = value;
    onDirty?.call();
  }

  /// In-flight preload future (episode player only).
  Future<bool>? inFlightFuture;

  /// Reserved for an activation swap (episode player only).
  bool activationReserved = false;

  /// Invoked when slot state changes in a way that invalidates a
  /// coordinator's derived caches (e.g. [FeedSlotCoordinator]'s in-flight
  /// episode cache). Assigned by the owning coordinator.
  void Function()? onDirty;

  /// Reset slot bindings for reuse.
  void reset() {
    playbackId = null;
    index = null;
    surfaceReady = false;
    frameReady = false;
    generation++;
    loadingEpisodeNo = null; // fires [onDirty]
    inFlightFuture = null;
    activationReserved = false;
  }
}
