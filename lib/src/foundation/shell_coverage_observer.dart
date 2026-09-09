import 'package:flutter/material.dart';

/// Tracks whether any route sits above the root (main shell).
///
/// Android banner [SurfaceView] / platform views can composite above later
/// Flutter routes. Theater watches [covered] and tears down the banner
/// surface while the shell is occluded (Login, feed, detail, dialogs…).
class ShellCoverageObserver extends NavigatorObserver {
  ShellCoverageObserver._();

  static final ShellCoverageObserver instance = ShellCoverageObserver._();

  /// True when [Navigator.canPop] — i.e. something covers the root route.
  final ValueNotifier<bool> covered = ValueNotifier<bool>(false);

  void _sync() {
    final nav = navigator;
    if (nav == null) return;
    final next = nav.canPop();
    if (covered.value != next) {
      covered.value = next;
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _sync();
}
