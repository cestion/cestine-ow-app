import 'dart:ui' show Rect;

import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_player_surface.dart';

/// Pixel-8-Pro-ish logical viewport; band is what is left above the sheet.
const double _screenW = 384;
const double _screenH = 854;
const double _band = _screenH - StoryConstants.playerOverlaySheetHeight;

const double _portrait = 9 / 16;
const double _landscape = 16 / 9;

void main() {
  group('VideoFeedPlayerSurface.videoRect — collapsed sheet band', () {
    test('portrait video fits inside the band above the sheet', () {
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: _screenW,
        parentH: _band,
        aspect: _portrait,
        boxH: _band,
        fitCollapsedBand: true,
        pinProgressToBottom: false,
      );

      // Height-first contain: the whole frame is visible, not top-cropped.
      expect(rect.height, closeTo(_band, 0.01));
      expect(rect.width, closeTo(_band * _portrait, 0.01));
      expect(rect.left, closeTo((_screenW - _band * _portrait) / 2, 0.01));
      expect(rect.top, closeTo(0, 0.01));
    });

    // The band is wider than it is tall, so filling it would crop a portrait
    // frame down to its top sliver. Guards the Android full-slot regression,
    // where the rect was the whole band regardless of aspect.
    test('portrait keeps its aspect and stays inside the band', () {
      for (final aspect in <double>[_portrait, 0.4, 0.75, 0.99]) {
        final rect = VideoFeedPlayerSurface.videoRect(
          parentW: _screenW,
          parentH: _band,
          aspect: aspect,
          boxH: _screenH, // full-bleed height must not leak into the band
          fitCollapsedBand: true,
          pinProgressToBottom: false,
        );
        expect(
          rect.width / rect.height,
          closeTo(aspect, 0.001),
          reason: 'aspect $aspect is cropped instead of contained',
        );
        expect(rect.height, lessThanOrEqualTo(_band + 0.01));
        expect(rect.width, lessThanOrEqualTo(_screenW + 0.01));
        expect(rect.top, greaterThanOrEqualTo(-0.01));
      }
    });

    test('very narrow band falls back to width-contain', () {
      const narrowBand = 60.0;
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: 100,
        parentH: narrowBand,
        aspect: _landscape,
        boxH: narrowBand,
        fitCollapsedBand: true,
        pinProgressToBottom: false,
      );
      // Landscape covers the band edge-to-edge.
      expect(rect.width, closeTo(100, 0.01));
      expect(rect.height, closeTo(narrowBand, 0.01));
    });

    test('landscape covers the band edge-to-edge', () {
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: _screenW,
        parentH: _band,
        aspect: _landscape,
        boxH: _band,
        fitCollapsedBand: true,
        pinProgressToBottom: false,
      );
      expect(rect, const Rect.fromLTWH(0, 0, _screenW, _band));
    });
  });

  group('VideoFeedPlayerSurface.videoRect — full slot', () {
    test('landscape letterboxes centered', () {
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: _screenW,
        parentH: _screenH,
        aspect: _landscape,
        boxH: _screenH,
        fitCollapsedBand: false,
        pinProgressToBottom: false,
      );
      expect(rect.width, closeTo(_screenW, 0.01));
      expect(rect.height, closeTo(_screenW / _landscape, 0.01));
      expect(rect.left, closeTo(0, 0.01));
      expect(rect.top, closeTo((_screenH - _screenW / _landscape) / 2, 0.01));
    });

    test('recommend portrait fills the parent', () {
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: _screenW,
        parentH: _screenH,
        aspect: _portrait,
        boxH: 700,
        fitCollapsedBand: false,
        pinProgressToBottom: true,
      );
      expect(rect, const Rect.fromLTWH(0, 0, _screenW, _screenH));
    });

    test('drama portrait stops at the episode chrome', () {
      const boxH = 700.0;
      final rect = VideoFeedPlayerSurface.videoRect(
        parentW: _screenW,
        parentH: _screenH,
        aspect: _portrait,
        boxH: boxH,
        fitCollapsedBand: false,
        pinProgressToBottom: false,
      );
      expect(rect, const Rect.fromLTWH(0, 0, _screenW, boxH));
    });
  });
}
