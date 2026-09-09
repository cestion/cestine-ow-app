import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../controller/feed_slot.dart';
import '../../../core/story_constants.dart';
import '../../../services/playback_frame_cache_service.dart';

/// First-frame JPEG snapshots for RecommendFeed cold start / swipe posters.
///
/// User pause keeps the native surface on-screen (last decoded frame) — this
/// manager is not involved in pause UX.
class RecommendFeedFrameManager {
  final Map<String, Uint8List> firstFrameBytes = {};
  VoidCallback? onStateChanged;

  /// Coalesce rapid disk/memory hits so neighbor JPEG warmup does not
  /// `setState` every file during active playback.
  Timer? _notifyTimer;

  RecommendFeedFrameManager({this.onStateChanged});

  Uint8List? getBytes(String? playbackId) {
    if (playbackId == null) return null;
    return firstFrameBytes[playbackId] ??
        PlaybackFrameCacheService.instance.peek(playbackId);
  }

  Future<void> prime(String playbackId) async {
    if (playbackId.isEmpty) return;
    final hot = PlaybackFrameCacheService.instance.peek(playbackId);
    if (hot != null && hot.isNotEmpty) {
      if (!identical(firstFrameBytes[playbackId], hot)) {
        firstFrameBytes[playbackId] = hot;
        _scheduleNotify();
      }
      return;
    }
    if (firstFrameBytes.containsKey(playbackId)) return;
    final bytes = await PlaybackFrameCacheService.instance.get(playbackId);
    if (bytes != null && bytes.isNotEmpty) {
      firstFrameBytes[playbackId] = bytes;
      _scheduleNotify();
    }
  }

  /// Primes [center] and its ±[radius] neighbors (by feed index).
  Future<void> primeAround(
    List<String> playbackIds, {
    required int centerIndex,
    int? radius,
  }) async {
    if (playbackIds.isEmpty) return;
    final span = radius ?? StoryConstants.playbackFramePrimeRadius;
    final futures = <Future<void>>[];
    for (var i = centerIndex - span; i <= centerIndex + span; i++) {
      if (i < 0 || i >= playbackIds.length) continue;
      final id = playbackIds[i];
      if (id.isEmpty) continue;
      futures.add(prime(id));
    }
    if (futures.isEmpty) return;
    await Future.wait(futures);
  }

  Future<void> capture(FeedSlot slot, String playbackId) async {
    if (playbackId.isEmpty || firstFrameBytes.containsKey(playbackId)) {
      return;
    }
    final engine = slot.engine;
    if (engine == null || !slot.frameReady) return;
    final bytes = await PlaybackFrameCacheService.instance.captureAndStore(
      engine: engine,
      playbackId: playbackId,
    );
    if (bytes != null && bytes.isNotEmpty) {
      firstFrameBytes[playbackId] = bytes;
      _scheduleNotify();
    }
  }

  void onRevision(Iterable<String> itemIds) {
    var changed = false;
    for (final id in itemIds) {
      if (id.isEmpty) continue;
      final hot = PlaybackFrameCacheService.instance.peek(id);
      if (hot != null &&
          hot.isNotEmpty &&
          !identical(firstFrameBytes[id], hot)) {
        firstFrameBytes[id] = hot;
        changed = true;
      }
    }
    if (changed) _scheduleNotify();
  }

  void clear() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
    firstFrameBytes.clear();
  }

  void dispose() {
    _notifyTimer?.cancel();
    _notifyTimer = null;
  }

  void _scheduleNotify() {
    if (_notifyTimer?.isActive == true) return;
    _notifyTimer = Timer(const Duration(milliseconds: 48), () {
      _notifyTimer = null;
      onStateChanged?.call();
    });
  }
}
