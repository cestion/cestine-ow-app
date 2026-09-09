import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/core/story_constants.dart';
import 'package:story_app/src/foundation/playback_visibility.dart';
import 'package:story_app/src/view/widgets/video_feed/player_sheet_layout.dart';

void main() {
  group('PlayerSheetLayoutCoordinator.isActiveSlot', () {
    test('prefers playbackId over index', () {
      expect(
        PlayerSheetLayoutCoordinator.isActiveSlot(
          slotPlaybackId: 'a:1',
          slotIndex: 0,
          activePlaybackId: 'a:1',
          currentIndex: 5,
        ),
        isTrue,
      );
    });

    test('falls back to index when playbackId missing', () {
      expect(
        PlayerSheetLayoutCoordinator.isActiveSlot(
          slotPlaybackId: 'other',
          slotIndex: 2,
          activePlaybackId: null,
          currentIndex: 2,
        ),
        isTrue,
      );
      expect(
        PlayerSheetLayoutCoordinator.isActiveSlot(
          slotPlaybackId: 'other',
          slotIndex: 1,
          activePlaybackId: '',
          currentIndex: 2,
        ),
        isFalse,
      );
    });

    test('with known active id, index alone must not mark another slot active', () {
      expect(
        PlayerSheetLayoutCoordinator.isActiveSlot(
          slotPlaybackId: 'old:1',
          slotIndex: 5,
          activePlaybackId: 'new:2',
          currentIndex: 5,
        ),
        isFalse,
      );
      expect(
        PlayerSheetLayoutCoordinator.isActiveSlot(
          slotPlaybackId: 'new:2',
          slotIndex: 4,
          activePlaybackId: 'new:2',
          currentIndex: 5,
        ),
        isTrue,
      );
    });
  });

  group('PlayerSheetLayoutCoordinator.layoutForSlot', () {
    test('geometry-only collapse snaps active slot to window-sheet band', () {
      const window = 800.0;
      const body = 700.0;
      final layout = PlayerSheetLayoutCoordinator.layoutForSlot(
        sheetOpen: true,
        collapseEnabled: true,
        isActiveSlot: true,
        windowHeight: window,
        bodyHeight: body,
      );
      expect(layout.isCollapsed, isTrue);
      expect(
        layout.playerHeight,
        (window - StoryConstants.playerOverlaySheetHeight).clamp(1.0, body),
      );
      expect(PlayerSheetSlotLayout.useGeometryOnlyCollapse, isTrue);
    });

    test('neighbors stay full body height while sheet is open', () {
      final layout = PlayerSheetLayoutCoordinator.layoutForSlot(
        sheetOpen: true,
        collapseEnabled: true,
        isActiveSlot: false,
        windowHeight: 800,
        bodyHeight: 700,
      );
      expect(layout.isCollapsed, isFalse);
      expect(layout.playerHeight, 700);
    });

    test('closed sheet keeps full height', () {
      final layout = PlayerSheetLayoutCoordinator.layoutForSlot(
        sheetOpen: false,
        collapseEnabled: true,
        isActiveSlot: true,
        windowHeight: 800,
        bodyHeight: 700,
      );
      expect(layout.playerHeight, 700);
    });
  });

  group('PlaybackVisibility', () {
    test('sheet overlay keeps surfaces mounted and playback visible', () {
      final kind = PlaybackVisibility.resolve(
        mounted: true,
        feedActive: true,
        appForeground: true,
        authOverlayCovering: false,
        standaloneRouteCovered: false,
        isStandalone: false,
        tabIndex: 0,
        theaterTabIndex: 0,
        drawerOpen: false,
        shellRouteCovered: true,
        overlayHoldsAdvance: true,
      );
      expect(kind, PlaybackVisibilityKind.sheetOverlay);
      expect(PlaybackVisibility.shouldMountSurfaces(kind), isTrue);
      expect(PlaybackVisibility.isPlaybackVisible(kind), isTrue);
      expect(
        PlaybackVisibility.shellCoverShouldTeardown(
          shellRouteCovered: true,
          overlayHoldsAdvance: true,
        ),
        isFalse,
      );
    });

    test('shell cover without hold tears down', () {
      final kind = PlaybackVisibility.resolve(
        mounted: true,
        feedActive: true,
        appForeground: true,
        authOverlayCovering: false,
        standaloneRouteCovered: false,
        isStandalone: false,
        tabIndex: 0,
        theaterTabIndex: 0,
        drawerOpen: false,
        shellRouteCovered: true,
        overlayHoldsAdvance: false,
      );
      expect(kind, PlaybackVisibilityKind.occluded);
      expect(PlaybackVisibility.shouldMountSurfaces(kind), isFalse);
      expect(
        PlaybackVisibility.shellCoverShouldTeardown(
          shellRouteCovered: true,
          overlayHoldsAdvance: false,
        ),
        isTrue,
      );
    });

    test('auth overlay unmounts surfaces and is not playback-visible', () {
      final kind = PlaybackVisibility.resolve(
        mounted: true,
        feedActive: true,
        appForeground: true,
        authOverlayCovering: true,
        standaloneRouteCovered: false,
        isStandalone: false,
        tabIndex: 0,
        theaterTabIndex: 0,
        drawerOpen: false,
        shellRouteCovered: false,
        overlayHoldsAdvance: false,
      );
      expect(kind, PlaybackVisibilityKind.authOccluded);
      expect(PlaybackVisibility.shouldMountSurfaces(kind), isFalse);
      expect(PlaybackVisibility.isPlaybackVisible(kind), isFalse);
    });
  });
}
