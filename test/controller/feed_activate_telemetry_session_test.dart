import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/feed_activate_telemetry_session.dart';
import 'package:story_app/src/foundation/telemetry.dart';

void main() {
  group('FeedActivateTelemetrySession', () {
    late _RecordingTelemetry telemetry;

    setUp(() {
      telemetry = _RecordingTelemetry();
      StoryTelemetryRegistry.set(telemetry);
    });

    tearDown(StoryTelemetryRegistry.reset);

    test('reports activate once per begin', () {
      final session = FeedActivateTelemetrySession(feed: 'drama');
      session.begin('playback-1');
      session.reportActivate(fromNeighbor: false);
      session.reportActivate(fromNeighbor: true);

      final events = telemetry.timings.where((e) => e.name == 'feed_activate');
      expect(events, hasLength(1));
      expect(events.first.properties['feed'], 'drama');
      expect(events.first.properties['playbackId'], 'playback-1');
      expect(events.first.properties['fromNeighbor'], isFalse);
    });

    test('reports first frame once with fallback id', () {
      final session = FeedActivateTelemetrySession(feed: 'recommend');
      session.begin('primary-id');
      session.reportFirstFrame(fallbackPlaybackId: 'fallback-id');
      session.reportFirstFrame(fallbackPlaybackId: 'other-id');

      final events =
          telemetry.timings.where((e) => e.name == 'feed_first_frame');
      expect(events, hasLength(1));
      expect(events.first.properties['playbackId'], 'primary-id');
    });

    test('begin resets duplicate guards', () {
      final session = FeedActivateTelemetrySession(feed: 'drama');
      session.begin('a');
      session.reportActivate(fromNeighbor: false);
      session.reportFirstFrame();
      session.begin('b');
      session.reportActivate(fromNeighbor: true);
      session.reportFirstFrame();

      final activates =
          telemetry.timings.where((e) => e.name == 'feed_activate').toList();
      expect(activates, hasLength(2));
      expect(activates.last.properties['playbackId'], 'b');
      expect(activates.last.properties['fromNeighbor'], isTrue);
    });
  });
}

class _RecordingTelemetry implements StoryTelemetry {
  final List<_TimingRecord> timings = [];

  @override
  void event(String name, {Map<String, Object?>? properties}) {}

  @override
  void error(
    Object error, {
    StackTrace? stackTrace,
    Map<String, Object?>? properties,
  }) {}

  @override
  void timing(
    String name,
    Duration duration, {
    Map<String, Object?>? properties,
  }) {
    timings.add(
      _TimingRecord(name: name, duration: duration, properties: properties ?? {}),
    );
  }
}

class _TimingRecord {
  _TimingRecord({
    required this.name,
    required this.duration,
    required this.properties,
  });

  final String name;
  final Duration duration;
  final Map<String, Object?> properties;
}
