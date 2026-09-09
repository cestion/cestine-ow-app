import '../core/story_constants.dart';
import 'feed_slot.dart';
import 'playback_engine.dart';

/// Owns the three-slot map and selection heuristics.
///
/// Keeps episode↔slot bookkeeping out of [VideoFeedController] so activation
/// and preload orchestration can evolve without touching map math.
class FeedSlotCoordinator {
  FeedSlotCoordinator(this._engineForSlot) {
    for (final slot in slots) {
      slot.onDirty = () => _inFlightCacheDirty = true;
    }
  }

  final PlaybackEngine? Function(int slot) _engineForSlot;

  int activeEngineIndex = 0;
  final List<FeedSlot> slots = List.generate(3, (_) => FeedSlot());
  final Map<int, int> episodeToSlot = <int, int>{};

  /// Reversed cache of [episodeToSlot] for O(1) slot→episode lookup in
  /// [nativePlayerSurfaces] (was O(n) `.entries.where().map().toList()` per
  /// slot per rebuild). Invalidated via [_markSlotIndexDirty] + rebuilt in
  /// [_rebuildSlotToEpisode].
  Map<int, int>? _slotToEpisodeCache;
  Set<int>? _preloadedEpisodesCache;
  bool _slotIndexDirty = true;

  /// Cache for [nativePreloadInFlightEpisodeNos] — avoids per-call
  /// `slots.map(...).whereType<int>().toSet()` allocation on hot paths.
  Set<int>? _inFlightCache;
  bool _inFlightCacheDirty = true;

  /// Unmodifiable view of episodes currently mapped to a slot.
  ///
  /// Cached across [episodeToSlot] mutations — scroll-tick hot path
  /// (`_onPageScroll` calls [VideoFeedController.preloadedEpisodeNos])
  /// reads this on every tick; the prior `Set.unmodifiable` per call
  /// allocated ~1 Set/tick during fling.
  Set<int> get preloadedEpisodeNos {
    final cached = _preloadedEpisodesCache;
    if (cached != null) return cached;
    final fresh = Set<int>.unmodifiable(episodeToSlot.keys);
    _preloadedEpisodesCache = fresh;
    return fresh;
  }

  /// O(1) slot→episode lookup, replacing
  /// `episodeToSlot.entries.where((e) => e.value == slot).map((e) => e.key).toList()`
  /// in [VideoFeedController.nativePlayerSurfaces]. Returns null when [slot]
  /// has no mapped episode.
  int? episodeForSlot(int slot) {
    if (_slotIndexDirty) _rebuildSlotToEpisode();
    return _slotToEpisodeCache?[slot];
  }

  void _rebuildSlotToEpisode() {
    final map = <int, int>{};
    episodeToSlot.forEach((episode, slot) {
      map[slot] = episode;
    });
    _slotToEpisodeCache = Map<int, int>.unmodifiable(map);
    _slotIndexDirty = false;
  }

  /// Call this whenever [episodeToSlot] mutates.
  void _markSlotIndexDirty() {
    _preloadedEpisodesCache = null;
    _slotToEpisodeCache = null;
    _slotIndexDirty = true;
    _inFlightCacheDirty = true;
  }

  // ─── Encapsulated mutations (invalidate slot index cache) ───
  //
  // External callers (extensions on VideoFeedController) must route
  // [episodeToSlot] writes through these methods so [episodeForSlot] and
  // [preloadedEpisodeNos] stay consistent. Direct map access elsewhere
  // bypasses the cache, so adding `episodeToSlot[k] = v` outside this
  // class corrupts the index.

  void mapEpisodeToSlot(int episodeNo, int slot) {
    episodeToSlot[episodeNo] = slot;
    _markSlotIndexDirty();
  }

  void unmapEpisode(int episodeNo) {
    if (episodeToSlot.remove(episodeNo) != null) {
      _markSlotIndexDirty();
    }
  }

  void unmapSlotsWhere(bool Function(int episode, int slot) test) {
    final before = episodeToSlot.length;
    episodeToSlot.removeWhere(test);
    if (episodeToSlot.length != before) _markSlotIndexDirty();
  }

  Iterable<int> get inactiveSlots sync* {
    for (var slot = 0; slot < 3; slot++) {
      if (slot != activeEngineIndex) yield slot;
    }
  }

  /// Set of episodes whose slots are currently loading.
  ///
  /// Cached across slot mutations — read by [FeedPrefetchOrchestrator] and
  /// [FeedNativePreloadOrchestrator] during scroll-tick hot paths.
  Set<int> get nativePreloadInFlightEpisodeNos {
    if (_inFlightCacheDirty) {
      _inFlightCache = Set<int>.unmodifiable(
        slots.map((s) => s.loadingEpisodeNo).whereType<int>(),
      );
      _inFlightCacheDirty = false;
    }
    return _inFlightCache!;
  }

  int? closestPreloadedEpisode(int currentEpisodeNo) {
    final next = currentEpisodeNo + 1;
    if (episodeToSlot.containsKey(next)) return next;
    final previous = currentEpisodeNo - 1;
    if (episodeToSlot.containsKey(previous)) return previous;
    final episodes = episodeToSlot.keys;
    return episodes.isEmpty ? null : episodes.first;
  }

  int? findInactiveSlotHolding(int episodeNo) {
    for (final slot in inactiveSlots) {
      final engine = _engineForSlot(slot);
      if (engine == null) continue;
      final loadingEpisode = slots[slot].loadingEpisodeNo;
      if (engine.currentEpisodeNo == episodeNo &&
          engine.currentPlay != null &&
          !engine.hasPendingLoad &&
          (loadingEpisode == null || loadingEpisode == episodeNo)) {
        return slot;
      }
    }
    return null;
  }

  int? findSlotLoadingEpisode(int episodeNo) {
    for (var slot = 0; slot < 3; slot++) {
      if (slots[slot].loadingEpisodeNo == episodeNo) return slot;
    }
    return null;
  }

  /// Returns a mapped slot only when its engine still holds [episodeNo].
  ///
  /// Native loads can finish after their coordinator generation was
  /// superseded. Never trust the map without validating the engine identity.
  int? readySlotForEpisode(int episodeNo) {
    final mapped = episodeToSlot[episodeNo];
    if (mapped == null) return null;
    final engine = _engineForSlot(mapped);
    final loadingEpisode = slots[mapped].loadingEpisodeNo;
    if (engine?.currentEpisodeNo == episodeNo &&
        engine?.currentPlay != null &&
        !(engine?.hasPendingLoad ?? false) &&
        (loadingEpisode == null || loadingEpisode == episodeNo)) {
      return mapped;
    }
    unmapEpisode(episodeNo);
    return null;
  }

  /// Ready slot (including an untracked decoded inactive slot), else the slot
  /// currently loading [episodeNo].
  int? slotForEpisode(int episodeNo) =>
      readySlotForEpisode(episodeNo) ??
      findInactiveSlotHolding(episodeNo) ??
      findSlotLoadingEpisode(episodeNo);

  bool isMappedOrLoading(int episodeNo) =>
      readySlotForEpisode(episodeNo) != null ||
      findInactiveSlotHolding(episodeNo) != null ||
      slots.any((s) => s.loadingEpisodeNo == episodeNo);

  void removeStalePreloadEntries() {
    unmapSlotsWhere((episode, slot) {
      if (slot == activeEngineIndex) return true;
      final engine = _engineForSlot(slot);
      if (engine == null) return true;
      return engine.currentEpisodeNo != episode || engine.currentPlay == null;
    });
  }

  void invalidateInactivePreloads({
    int? exceptEpisode,
    Set<int> exceptEpisodes = const {},
  }) {
    final keep = <int>{?exceptEpisode, ...exceptEpisodes};
    for (final slot in inactiveSlots) {
      final inFlightEpisode = slots[slot].loadingEpisodeNo;
      int? readyEpisode;
      final mapped = episodeForSlot(slot);
      readyEpisode = mapped;
      if ((inFlightEpisode != null && keep.contains(inFlightEpisode)) ||
          (readyEpisode != null && keep.contains(readyEpisode))) {
        continue;
      }
      slots[slot].reset();
    }
    unmapSlotsWhere((episode, slot) {
      if (slot == activeEngineIndex) return true;
      if (keep.contains(episode)) return false;
      return true;
    });
  }

  /// Pick an inactive slot for [episodeNo], preferring idle engines.
  int? choosePreloadSlot(
    int episodeNo, {
    required int currentEpisodeNo,
    bool force = false,
  }) {
    final alreadyReady = readySlotForEpisode(episodeNo);
    if (alreadyReady != null) return alreadyReady;
    for (var slot = 0; slot < 3; slot++) {
      if (slots[slot].loadingEpisodeNo == episodeNo) return slot;
    }

    bool isIdle(int slot) {
      final engine = _engineForSlot(slot);
      return engine == null || !engine.hasPendingLoad;
    }

    var candidates = inactiveSlots
        .where(
          (slot) =>
              !slots[slot].activationReserved &&
              slots[slot].loadingEpisodeNo == null &&
              isIdle(slot),
        )
        .toList();
    if (candidates.isEmpty) {
      candidates = inactiveSlots
          .where((slot) => !slots[slot].activationReserved && isIdle(slot))
          .toList();
    }
    if (candidates.isEmpty) {
      if (!force) return null;
      // Last resort: allow a wedged (pending-load) inactive slot so the
      // caller can forceAbandon + reuse it. Returning null here left swipe
      // activation stuck in cancelStaleLoad retries forever.
      candidates = inactiveSlots
          .where((slot) => !slots[slot].activationReserved)
          .toList();
      if (candidates.isEmpty) return null;
    }

    candidates.sort((a, b) {
      final aEngine = _engineForSlot(a);
      final bEngine = _engineForSlot(b);
      final aPending = (aEngine?.hasPendingLoad ?? false) ? 1 : 0;
      final bPending = (bEngine?.hasPendingLoad ?? false) ? 1 : 0;
      if (aPending != bPending) return aPending.compareTo(bPending);
      final aEpisode = aEngine?.currentEpisodeNo;
      final bEpisode = bEngine?.currentEpisodeNo;
      final aDistance = aEpisode == null
          ? StoryConstants.infiniteSlotDistance
          : (aEpisode - currentEpisodeNo).abs();
      final bDistance = bEpisode == null
          ? StoryConstants.infiniteSlotDistance
          : (bEpisode - currentEpisodeNo).abs();
      return bDistance.compareTo(aDistance);
    });
    return candidates.first;
  }

  void resetAll() {
    for (final slot in slots) {
      slot.reset();
    }
    episodeToSlot.clear();
    _markSlotIndexDirty();
    activeEngineIndex = 0;
  }
}
