import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/view/widgets/video_feed/feed_surface_lifecycle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedAppLifecyclePolicy', () {
    test('ignores inactive but handles paused/hidden/resumed', () {
      expect(
        FeedAppLifecyclePolicy.shouldMarkBackground(AppLifecycleState.inactive),
        isFalse,
      );
      expect(
        FeedAppLifecyclePolicy.shouldMarkBackground(AppLifecycleState.paused),
        isTrue,
      );
      expect(
        FeedAppLifecyclePolicy.shouldMarkBackground(AppLifecycleState.hidden),
        isTrue,
      );
      expect(
        FeedAppLifecyclePolicy.shouldMarkForeground(AppLifecycleState.resumed),
        isTrue,
      );
      expect(
        FeedAppLifecyclePolicy.shouldMarkForeground(AppLifecycleState.inactive),
        isFalse,
      );
    });
  });

  group('FeedShellOcclusionPolicy', () {
    test('soft-hides when tab leaves theater', () {
      expect(
        FeedShellOcclusionPolicy.shouldSoftHideForTab(
          tabIndex: 1,
          theaterTabIndex: 0,
        ),
        isTrue,
      );
      expect(
        FeedShellOcclusionPolicy.shouldSoftHideForTab(
          tabIndex: 0,
          theaterTabIndex: 0,
        ),
        isFalse,
      );
    });

    test('shell cover teardown respects sheet hold', () {
      expect(
        FeedShellOcclusionPolicy.shouldHardTeardownForShellCover(
          shellRouteCovered: true,
          overlayHoldsAdvance: true,
        ),
        isFalse,
      );
      expect(
        FeedShellOcclusionPolicy.shouldHardTeardownForShellCover(
          shellRouteCovered: true,
          overlayHoldsAdvance: false,
        ),
        isTrue,
      );
    });
  });

  group('scheduleFeedAuthCoverSurfaceTeardown', () {
    testWidgets('defers unmount until after a frame', (tester) async {
      var unmounted = false;
      scheduleFeedAuthCoverSurfaceTeardown(
        mounted: () => true,
        stillCovering: () => true,
        shouldUnmount: () => true,
        unmount: () => unmounted = true,
      );
      expect(unmounted, isFalse);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(unmounted, isTrue);
    });

    testWidgets('skips unmount when cover cleared before frame', (tester) async {
      var covering = true;
      var unmounted = false;
      scheduleFeedAuthCoverSurfaceTeardown(
        mounted: () => true,
        stillCovering: () => covering,
        shouldUnmount: () => true,
        unmount: () => unmounted = true,
      );
      covering = false;
      await tester.pump();
      expect(unmounted, isFalse);
    });
  });
}
