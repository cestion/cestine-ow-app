import 'package:flutter/material.dart';

import '../../../foundation/router.dart';

/// Manages [RouteAware] subscribe/unsubscribe for feed pages.
///
/// Call [update] from [State.didChangeDependencies] and [dispose] from
/// [State.dispose] so route transitions stay symmetric.
class FeedRouteAwareSubscription {
  PageRoute<dynamic>? _route;

  void update(
    BuildContext context,
    RouteAware observer, {
    required bool enabled,
  }) {
    if (!enabled) {
      dispose(observer);
      return;
    }
    final route = ModalRoute.of(context);
    if (route is! PageRoute || route == _route) return;
    dispose(observer);
    _route = route;
    StoryRouter.observer.subscribe(observer, route);
  }

  void dispose(RouteAware observer) {
    if (_route != null) {
      StoryRouter.observer.unsubscribe(observer);
      _route = null;
    }
  }
}
