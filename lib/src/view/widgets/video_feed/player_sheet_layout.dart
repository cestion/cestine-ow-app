import '../../../core/story_constants.dart';
import 'feed_collapsible_surface.dart';

/// Immutable layout result for one player slot while a sheet may be open.
class PlayerSheetSlotLayout {
  const PlayerSheetSlotLayout({
    required this.playerHeight,
    required this.isCollapsed,
  });

  /// Height for the [Positioned] / [SizedBox] wrapping the native surface.
  final double playerHeight;

  /// True when this slot is the active one and the sheet is collapsing it.
  final bool isCollapsed;

  /// Outer collapse is **height + clip only**. Inner
  /// [VideoFeedPlayerSurface.fitCollapsedBand] may still flip — it only
  /// changes [Positioned] geometry, not Platform View parent types.
  static const bool useGeometryOnlyCollapse = true;
}

/// Shared sheet-collapse math and active-slot matching for both feeds.
class PlayerSheetLayoutCoordinator {
  PlayerSheetLayoutCoordinator._();

  /// Window height minus sheet — not Scaffold body height (root-navigator
  /// sheets pin to the screen bottom).
  static double collapsedBandHeight(
    double windowHeight, {
    double sheetHeight = StoryConstants.playerOverlaySheetHeight,
  }) {
    return FeedCollapsibleSurface.calculatePlayerHeight(
      windowHeight,
      true,
      sheetHeight: sheetHeight,
    );
  }

  /// Prefer [activePlaybackId] over [currentIndex] — early-activate can
  /// advance the feed index before the visible slot catches up.
  ///
  /// When [activePlaybackId] is known, **only** identity may win. Falling
  /// through to `slotIndex == currentIndex` while another slot already holds
  /// the active id marks *two* slots active during promote.
  static bool isActiveSlot({
    required String? slotPlaybackId,
    required int? slotIndex,
    required String? activePlaybackId,
    required int currentIndex,
  }) {
    final id = activePlaybackId?.trim();
    if (id != null && id.isNotEmpty) {
      return slotPlaybackId == id;
    }
    return slotIndex != null && slotIndex == currentIndex;
  }

  static PlayerSheetSlotLayout layoutForSlot({
    required bool sheetOpen,
    required bool collapseEnabled,
    required bool isActiveSlot,
    required double windowHeight,
    required double bodyHeight,
    double sheetHeight = StoryConstants.playerOverlaySheetHeight,
  }) {
    final collapse = sheetOpen && collapseEnabled && isActiveSlot;
    if (!collapse) {
      return PlayerSheetSlotLayout(
        playerHeight: bodyHeight,
        isCollapsed: false,
      );
    }
    final band = collapsedBandHeight(
      windowHeight,
      sheetHeight: sheetHeight,
    ).clamp(1.0, bodyHeight);
    return PlayerSheetSlotLayout(
      playerHeight: band,
      isCollapsed: true,
    );
  }

  /// Vertical offset for a triple-slot player while [page] is fractional.
  static double slotTopOffset({
    required double page,
    required int slotIndex,
    required double pageHeight,
    double parkThreshold = 1.25,
  }) {
    final raw = (slotIndex - page) * pageHeight;
    if (raw.abs() > pageHeight * parkThreshold) {
      return raw < 0 ? -pageHeight * 2.0 : pageHeight * 2.0;
    }
    return raw;
  }
}
