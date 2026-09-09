import '../foundation/telemetry.dart';

/// Playback health events for both feeds.
///
/// Wired through [StoryTelemetryRegistry] so production can attach an
/// analytics backend without touching feed code.
class FeedPlaybackTelemetry {
  FeedPlaybackTelemetry._();

  static StoryTelemetry get _t => StoryTelemetryRegistry.instance;

  static void activate({
    required String feed,
    required String playbackId,
    required Duration elapsed,
    required bool fromNeighbor,
  }) {
    _t.timing(
      'feed_activate',
      elapsed,
      properties: {
        'feed': feed,
        'playbackId': playbackId,
        'fromNeighbor': fromNeighbor,
      },
    );
  }

  static void firstFrame({
    required String feed,
    required String playbackId,
    required Duration elapsed,
  }) {
    _t.timing(
      'feed_first_frame',
      elapsed,
      properties: {'feed': feed, 'playbackId': playbackId},
    );
  }

  static void surfaceRemount({
    required String feed,
    required String reason,
  }) {
    _t.event(
      'feed_surface_remount',
      properties: {'feed': feed, 'reason': reason},
    );
  }

  static void unexpectedPause({
    required String feed,
    required String playbackId,
    required bool recovered,
  }) {
    _t.event(
      'feed_unexpected_pause',
      properties: {
        'feed': feed,
        'playbackId': playbackId,
        'recovered': recovered,
      },
    );
  }

  static void bufferingTimeout({
    required String feed,
    required String playbackId,
  }) {
    _t.event(
      'feed_buffering_timeout',
      properties: {'feed': feed, 'playbackId': playbackId},
    );
  }

  static void sheetCollapse({
    required String feed,
    required bool open,
    required double bandHeight,
  }) {
    _t.event(
      'feed_sheet_collapse',
      properties: {
        'feed': feed,
        'open': open,
        'bandHeight': bandHeight,
      },
    );
  }

  static void cookieOpTimeout({
    required String op,
    required int timeoutMs,
  }) {
    _t.event(
      'feed_cookie_op_timeout',
      properties: {
        'op': op,
        'timeoutMs': timeoutMs,
      },
    );
  }
}
