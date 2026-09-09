import 'package:flutter/material.dart';

import '../routes/route_names.dart';

/// Notifies active players when login / report covers them.
///
/// Comment / drama sheets keep playback running under [overlayHoldsAdvance],
/// which also suppresses [RouteAware.didPushNext]. Full-screen login and
/// report still use the same cover → pause / reveal → resume path.
class PlaybackAuthRouteObserver extends NavigatorObserver {
  PlaybackAuthRouteObserver._();

  static final PlaybackAuthRouteObserver instance =
      PlaybackAuthRouteObserver._();

  final Set<void Function(bool covering)> _listeners = {};
  int _depth = 0;

  void addListener(void Function(bool covering) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(bool covering) listener) {
    _listeners.remove(listener);
  }

  static bool isAuthCoverRoute(Route<dynamic> route) {
    final raw = route.settings.name;
    if (raw == null || raw.isEmpty) return false;
    final name = raw.split('?').first;
    return name == RouteNames.login || name == RouteNames.report;
  }

  void _notify(bool covering) {
    for (final listener in List<void Function(bool)>.of(_listeners)) {
      listener(covering);
    }
  }

  void _push() {
    _depth++;
    if (_depth == 1) _notify(true);
  }

  void _pop() {
    if (_depth == 0) return;
    _depth--;
    if (_depth == 0) _notify(false);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (isAuthCoverRoute(route)) _push();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (isAuthCoverRoute(route)) _pop();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (isAuthCoverRoute(route)) _pop();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final oldAuth = oldRoute != null && isAuthCoverRoute(oldRoute);
    final newAuth = newRoute != null && isAuthCoverRoute(newRoute);
    if (oldAuth && !newAuth) {
      _pop();
    } else if (!oldAuth && newAuth) {
      _push();
    }
  }
}
