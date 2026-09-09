import '../../../core/story_constants.dart';

/// Shared player-viewport collapse math for overlay sheets.
///
/// Both feeds keep their own rebuild scopes — the recommend feed merges the
/// sheet listenable with the pager scroll — and only share the height
/// calculation, so this stays a static helper rather than a widget.
class FeedCollapsibleSurface {
  FeedCollapsibleSurface._();

  /// Calculates the effective player height given screen height and sheet state.
  static double calculatePlayerHeight(
    double totalHeight,
    bool isSheetOpen, {
    double sheetHeight = StoryConstants.playerOverlaySheetHeight,
  }) {
    if (!isSheetOpen) return totalHeight;
    return (totalHeight - sheetHeight).clamp(1.0, totalHeight);
  }
}
