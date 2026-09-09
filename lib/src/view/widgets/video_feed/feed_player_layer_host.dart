import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../controller/feed_slot.dart';
import '../../../controller/recommend_feed_state.dart';
import 'player_sheet_layout.dart';

/// Positions triple player slots from scroll offset + sheet collapse.
///
/// Scroll (`pageController` / `pageOffset`) rebuilds tops. Sheet open /
/// height share one stable ListenableBuilder so the child stays a [Stack]
/// across open/close (swapping Stack ↔ nested builder remounts Platform
/// Views).
///
/// Collapse is geometry-only
/// ([PlayerSheetSlotLayout.useGeometryOnlyCollapse]).
class FeedPlayerLayerHost extends StatelessWidget {
  const FeedPlayerLayerHost({
    super.key,
    required this.sheetOpenNotifier,
    required this.sheetHeightListenable,
    required this.pageController,
    required this.pageOffset,
    required this.feed,
    required this.height,
    required this.slots,
    required this.collapseForSheet,
    required this.playerLayer,
  });

  final ValueNotifier<bool> sheetOpenNotifier;
  final ValueListenable<double> sheetHeightListenable;
  final PageController pageController;
  final ValueNotifier<double> pageOffset;
  final RecommendFeedState feed;
  final double height;
  final List<FeedSlot> slots;
  final bool collapseForSheet;
  final Widget Function(
    FeedSlot slot,
    double Function(int) topFor,
    double pageHeight,
    double playerHeight,
  )
  playerLayer;

  @override
  Widget build(BuildContext context) {
    final listenables = <Listenable>[pageController, pageOffset];
    if (collapseForSheet) {
      listenables.add(sheetOpenNotifier);
      listenables.add(sheetHeightListenable);
    }

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final page = pageController.hasClients
            ? (pageController.page ?? feed.currentIndex.toDouble())
            : feed.currentIndex.toDouble();

        double topFor(int index) {
          return PlayerSheetLayoutCoordinator.slotTopOffset(
            page: page,
            slotIndex: index,
            pageHeight: height,
          );
        }

        final sheetOpen = collapseForSheet && sheetOpenNotifier.value;
        final windowHeight = MediaQuery.sizeOf(context).height;
        final sheetHeight = sheetHeightListenable.value;
        final activePlaybackId = feed.currentItem?.playbackId;

        // One Stack shape for sheet open/close — never swap fullHeightStack
        // vs a nested Builder stack or Platform Views remount (iOS
        // recreating_view).
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final slot in slots)
              Builder(
                builder: (context) {
                  final active = PlayerSheetLayoutCoordinator.isActiveSlot(
                    slotPlaybackId: slot.playbackId,
                    slotIndex: slot.index,
                    activePlaybackId: activePlaybackId,
                    currentIndex: feed.currentIndex,
                  );
                  final layout = PlayerSheetLayoutCoordinator.layoutForSlot(
                    sheetOpen: sheetOpen,
                    collapseEnabled: collapseForSheet,
                    isActiveSlot: active,
                    windowHeight: windowHeight,
                    bodyHeight: height,
                    sheetHeight: sheetHeight,
                  );
                  return playerLayer(
                    slot,
                    topFor,
                    height,
                    layout.playerHeight,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}
