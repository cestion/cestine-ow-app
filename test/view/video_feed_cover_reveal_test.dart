import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/view/widgets/video_feed/video_feed_page_item.dart';

void main() {
  group('shouldUnmountFeedCover', () {
    test('keeps cover until the current page has a painted frame', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: false,
        ),
        isFalse,
      );
    });

    test('unmounts cover once the current surface has a frame', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: true,
          neighborHasDecodedFrame: false,
          currentRevealLatched: false,
        ),
        isTrue,
      );
    });

    test('keeps a latched current reveal across brief surface flickers', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: true,
        ),
        isTrue,
      );
    });

    test('ignores latch when allowLatchedReveal is false', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: true,
          allowLatchedReveal: false,
        ),
        isFalse,
      );
    });

    test('surfaceReady still wins when latch is disallowed', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: true,
          neighborHasDecodedFrame: false,
          currentRevealLatched: true,
          allowLatchedReveal: false,
        ),
        isTrue,
      );
    });

    test('does not unmount a neighbor that is only mapped after loadUrl', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: false,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: false,
        ),
        isFalse,
      );
    });

    test('unmounts a neighbor only after it has decoded a frame', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: false,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: true,
          currentRevealLatched: false,
        ),
        isTrue,
      );
    });

    test('latched reveal on a neighbor does not drop its cover', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: false,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: true,
        ),
        isFalse,
      );
    });

    test('mapped surface without a frame keeps the current-page cover', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: false,
        ),
        isFalse,
      );
    });

    test('stale latch of another drama must be passed as unlatched', () {
      expect(
        shouldUnmountFeedCover(
          isCurrentPage: true,
          currentSurfaceReady: false,
          neighborHasDecodedFrame: false,
          currentRevealLatched: false,
        ),
        isFalse,
      );
    });
  });

  group('VideoFeedPageItem cover fade', () {
    // 1x1 PNG — avoids l10n fallback when coverUrl is null.
    final tinyPng = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
      0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
      0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC,
      0x59, 0xE7, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
      0x60, 0x82,
    ]);

    Finder coverFadeOf(Key key) => find.descendant(
      of: find.byKey(key),
      matching: find.byType(AnimatedOpacity),
    );

    testWidgets('fades out then removes cover when revealPlayer becomes true', (
      tester,
    ) async {
      const fade = Duration(milliseconds: 100);
      const key = ValueKey('cover-fade');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeedPageItem(
              key: key,
              episodeNo: 1,
              totalEpisodes: 1,
              firstFrameBytes: tinyPng,
              isCurrentPage: true,
              revealPlayer: false,
              fadeOutDuration: fade,
            ),
          ),
        ),
      );
      expect(coverFadeOf(key), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeedPageItem(
              key: key,
              episodeNo: 1,
              totalEpisodes: 1,
              firstFrameBytes: tinyPng,
              isCurrentPage: true,
              revealPlayer: true,
              fadeOutDuration: fade,
            ),
          ),
        ),
      );
      // Mid-fade: cover still in tree under FadeTransition.
      await tester.pump(const Duration(milliseconds: 40));
      expect(coverFadeOf(key), findsOneWidget);

      await tester.pumpAndSettle();
      // After fade: empty expand only — cover FadeTransition unmounted.
      expect(coverFadeOf(key), findsNothing);
    });

    testWidgets('starts revealed without a fade when revealPlayer is true', (
      tester,
    ) async {
      const key = ValueKey('cover-latched');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VideoFeedPageItem(
              key: key,
              episodeNo: 1,
              totalEpisodes: 1,
              firstFrameBytes: tinyPng,
              isCurrentPage: true,
              revealPlayer: true,
            ),
          ),
        ),
      );
      expect(coverFadeOf(key), findsNothing);
    });
  });
}
