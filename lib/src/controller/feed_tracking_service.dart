import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/story_logger.dart';
import '../model/work_content_type.dart';
import '../provider/app_providers.dart';
import '../repositories/drama_repository.dart';

/// Handles analytics/metrics tracking for video feed episodes.
class FeedTrackingService {
  final Ref _ref;

  FeedTrackingService(this._ref);

  /// In-flight keys to coalesce concurrent reports for the same drama/episode/event.
  static final Set<String> _inFlightKeys = {};

  static void clearTrackingHistory() {
    _inFlightKeys.clear();
  }

  static String _inFlightKey({
    required String dramaId,
    required String episodeId,
    required EpisodeTrackEvent event,
  }) => '$dramaId|$episodeId|${event.name}';

  /// Fires a tracking event for the given episode.
  void fireTrack({
    required String dramaId,
    required String? episodeId,
    required EpisodeTrackEvent event,
    int positionMs = 0,
    WorkContentType type = WorkContentType.shortDrama,
  }) {
    if (episodeId == null) {
      StoryLogger.d(
        'skip track drama=$dramaId event=$event reason=noEpisodeId',
        tag: 'Feed',
      );
      return;
    }
    StoryLogger.d(
      'fire track drama=$dramaId ep=$episodeId event=$event'
      '${positionMs > 0 ? ' positionMs=$positionMs' : ''}',
      tag: 'Feed',
    );
    unawaited(_reportTrack(dramaId, episodeId, event, type: type));
  }

  Future<void> _reportTrack(
    String dramaId,
    String episodeId,
    EpisodeTrackEvent event, {
    WorkContentType type = WorkContentType.shortDrama,
  }) async {
    final inFlightKey = _inFlightKey(
      dramaId: dramaId,
      episodeId: episodeId,
      event: event,
    );

    if (!_inFlightKeys.add(inFlightKey)) {
      StoryLogger.d(
        'skip track drama=$dramaId ep=$episodeId event=$event '
        'reason=inFlight',
        tag: 'Feed',
      );
      return;
    }

    try {
      final deviceId = await _ref.read(deviceIdServiceProvider).getDeviceId();
      final repo = _ref.read(dramaRepositoryProvider);
      final result = await repo.trackEpisode(
        dramaId,
        episodeId,
        event,
        deviceId: deviceId,
        type: type,
      );
      result.when(
        success: (_) {
          StoryLogger.d(
            'track ok drama=$dramaId ep=$episodeId event=$event',
            tag: 'Feed',
          );
        },
        failure: (_) {
          StoryLogger.w(
            'track failed drama=$dramaId ep=$episodeId event=$event',
            tag: 'Feed',
          );
        },
      );
    } finally {
      _inFlightKeys.remove(inFlightKey);
    }
  }
}
