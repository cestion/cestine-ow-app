import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import 'feed_surface_lifecycle.dart';

/// Subscribes to main-shell drawer / tab / route cover for embedded feeds.
///
/// Soft hide (drawer, tab away) keeps pending loads abandonable; hard teardown
/// (shell route cover) awaits player disposal for cross-page handoff.
class FeedShellOcclusionCoordinator {
  FeedShellOcclusionCoordinator({
    required this.theaterTabIndex,
    required this.overlayHoldsAdvance,
    required this.onSoftHide,
    required this.onHardTeardown,
    required this.onRemount,
  });

  final int theaterTabIndex;
  final bool Function() overlayHoldsAdvance;
  final void Function() onSoftHide;
  final void Function() onHardTeardown;
  final void Function() onRemount;

  ProviderSubscription<bool>? _drawerSub;
  ProviderSubscription<int>? _tabSub;
  ProviderSubscription<bool>? _shellCoverSub;

  void attach(WidgetRef ref) {
    _drawerSub = ref.listenManual<bool>(mainShellDrawerOpenProvider, (
      prev,
      drawerOpen,
    ) {
      if (drawerOpen) {
        onSoftHide();
      } else {
        onRemount();
      }
    });
    _tabSub = ref.listenManual<int>(tabIndexProvider, (prev, tabIndex) {
      if (FeedShellOcclusionPolicy.shouldSoftHideForTab(
        tabIndex: tabIndex,
        theaterTabIndex: theaterTabIndex,
      )) {
        onSoftHide();
      } else {
        onRemount();
      }
    });
    _shellCoverSub = ref.listenManual<bool>(mainShellRouteCoveredProvider, (
      prev,
      shellRouteCovered,
    ) {
      if (shellRouteCovered) {
        if (!FeedShellOcclusionPolicy.shouldHardTeardownForShellCover(
          shellRouteCovered: true,
          overlayHoldsAdvance: overlayHoldsAdvance(),
        )) {
          return;
        }
        onHardTeardown();
      } else {
        onRemount();
      }
    });
  }

  void dispose() {
    _drawerSub?.close();
    _tabSub?.close();
    _shellCoverSub?.close();
    _drawerSub = null;
    _tabSub = null;
    _shellCoverSub = null;
  }
}
