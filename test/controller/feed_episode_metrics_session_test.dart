import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_engine_completion_handler.dart';
import 'package:story_app/src/controller/feed_episode_metrics_session.dart';
import 'package:story_app/src/controller/playback_episode_metrics_tracker.dart';
import 'package:story_app/src/repositories/drama_repository.dart';

void main() {
  group('FeedEpisodeMetricsSession', () {
    test('applySignals fires play then complete once', () {
      final session = FeedEpisodeMetricsSession();
      final fired = <EpisodeTrackEvent>[];
      session.applySignals(
        const PlaybackEpisodeMetricsSignals(
          reportPlay: true,
          reportComplete: true,
        ),
        fireTrack: fired.add,
      );
      session.applySignals(
        const PlaybackEpisodeMetricsSignals(
          reportPlay: true,
          reportComplete: true,
        ),
        fireTrack: fired.add,
      );
      expect(fired, [EpisodeTrackEvent.play, EpisodeTrackEvent.complete]);
    });
  });

  group('FeedWatchHistoryGate', () {
    test('dedupes by episode id', () {
      final gate = FeedWatchHistoryGate();
      expect(
        gate.shouldReportPlay(positionMs: 2000, episodeId: 'ep-1'),
        isTrue,
      );
      gate.markReported(episodeId: 'ep-1');
      expect(
        gate.shouldReportPlay(positionMs: 2000, episodeId: 'ep-1'),
        isFalse,
      );
    });

    test('reset clears dedupe', () {
      final gate = FeedWatchHistoryGate();
      gate.markReported(episodeNo: 3);
      gate.reset();
      expect(gate.shouldReportPlay(positionMs: 2000, episodeNo: 3), isTrue);
    });

    test('survives metrics session reset without clearing dedupe', () {
      final metrics = FeedEpisodeMetricsSession();
      final gate = FeedWatchHistoryGate();
      expect(
        gate.shouldReportPlay(positionMs: 2000, episodeId: 'ep-1'),
        isTrue,
      );
      gate.markReported(episodeId: 'ep-1');
      metrics.reset();
      expect(
        gate.shouldReportPlay(positionMs: 2000, episodeId: 'ep-1'),
        isFalse,
      );
    });

    test('dedupes by episode no when id absent', () {
      final gate = FeedWatchHistoryGate();
      expect(gate.shouldReportPlay(positionMs: 1500, episodeNo: 2), isTrue);
      gate.markReported(episodeNo: 2);
      expect(gate.shouldReportPlay(positionMs: 1500, episodeNo: 2), isFalse);
      expect(gate.shouldReportPlay(positionMs: 1500, episodeNo: 3), isTrue);
    });
  });

  group('FeedEngineCompletionHandler', () {
    test('isBufferingTimeout delegates to policy', () {
      expect(
        FeedEngineCompletionHandler.isBufferingTimeout(
          StateError('buffering timed out after 4000ms'),
        ),
        isTrue,
      );
    });
  });
}
