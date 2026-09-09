import 'package:flutter/material.dart';

import 'navigator_bridge.dart';
import 'router.dart';

/// Global navigation entry. Prefer [StoryNavX] on [BuildContext] when a
/// widget context is available.
class StoryNavigator {
  StoryNavigator._();
  static final StoryNavigator instance = StoryNavigator._();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Fire-and-forget push. Prefer this over [pushForResult] when the pop
  /// result is unused (avoids strict-inference warnings on bare generics).
  Future<void> push(
    String path, {
    Map<String, dynamic>? arguments,
    BuildContext? context,
    bool rootNavigator = false,
  }) {
    return pushForResult<void>(
      path,
      arguments: arguments,
      context: context,
      rootNavigator: rootNavigator,
    ).then((_) {});
  }

  /// Push and await a typed route result (e.g. login `bool`, editor models).
  Future<T?> pushForResult<T>(
    String path, {
    Map<String, dynamic>? arguments,
    BuildContext? context,
    bool rootNavigator = false,
  }) async {
    final bridge = StoryNavigatorBridgeRegistry.instance;
    if (StoryNavigatorBridgeRegistry.isRegistered) {
      await bridge.pushPath(path, arguments: arguments, context: context);
      return null;
    }
    final nav = _navigator(context, rootNavigator: rootNavigator);
    if (nav == null) return null;

    final resolved = _resolveRoute<T>(path, arguments);
    if (resolved == null) return null;
    return nav.push<T>(resolved);
  }

  /// Pop current route (if possible) then [push].
  Future<void> popAndPush(
    String path, {
    Map<String, dynamic>? arguments,
    BuildContext? context,
    bool rootNavigator = false,
  }) async {
    final nav = _navigator(context, rootNavigator: rootNavigator);
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    await push(
      path,
      arguments: arguments,
      context: context,
      rootNavigator: rootNavigator,
    );
  }

  /// Replace the stack above [predicate] with [path].
  Future<void> pushAndRemoveUntil(
    String path,
    RoutePredicate predicate, {
    Map<String, dynamic>? arguments,
    BuildContext? context,
    bool rootNavigator = false,
  }) async {
    final bridge = StoryNavigatorBridgeRegistry.instance;
    if (StoryNavigatorBridgeRegistry.isRegistered) {
      await bridge.pushPath(path, arguments: arguments, context: context);
      return;
    }
    final nav = _navigator(context, rootNavigator: rootNavigator);
    if (nav == null) return;

    final resolved = _resolveRoute<void>(path, arguments);
    if (resolved == null) return;
    await nav.pushAndRemoveUntil<void>(resolved, predicate);
  }

  void popToRoot({BuildContext? context, bool rootNavigator = false}) {
    final nav = _navigator(context, rootNavigator: rootNavigator);
    if (nav == null) return;
    nav.popUntil((route) => route.isFirst);
  }

  Future<void> pop<T>({
    BuildContext? context,
    T? result,
    bool rootNavigator = false,
  }) async {
    final bridge = StoryNavigatorBridgeRegistry.instance;
    if (StoryNavigatorBridgeRegistry.isRegistered) {
      await bridge.pop<T>(context: context, result: result);
      return;
    }
    final nav = _navigator(context, rootNavigator: rootNavigator);
    if (nav == null) return;
    if (nav.canPop()) {
      nav.pop<T>(result);
    }
  }

  Future<bool> ensureLogin() async {
    final bridge = StoryNavigatorBridgeRegistry.instance;
    if (StoryNavigatorBridgeRegistry.isRegistered) {
      return bridge.ensureLogin();
    }
    return false;
  }

  MaterialPageRoute<T>? _resolveRoute<T>(
    String path,
    Map<String, dynamic>? arguments,
  ) {
    final routeName = path.split('?').first;
    final queryStr = path.contains('?') ? path.split('?').last : '';
    final queryArgs = _parseQueryParams(queryStr);
    final merged = <String, dynamic>{
      ...?queryArgs,
      ...?arguments,
    };
    final page = StoryRouter.instance.buildPage(routeName, merged);
    if (page == null) return null;
    return MaterialPageRoute<T>(
      builder: (_) => page,
      settings: RouteSettings(name: path, arguments: merged),
    );
  }

  NavigatorState? _navigator(
    BuildContext? context, {
    bool rootNavigator = false,
  }) {
    return context != null
        ? Navigator.of(context, rootNavigator: rootNavigator)
        : navigatorKey.currentState;
  }

  Map<String, dynamic>? _parseQueryParams(String queryStr) {
    if (queryStr.isEmpty) return null;
    final params = <String, dynamic>{};
    for (final pair in queryStr.split('&')) {
      final idx = pair.indexOf('=');
      if (idx > 0) {
        final key = pair.substring(0, idx);
        final value = pair.substring(idx + 1);
        params[key] = Uri.decodeQueryComponent(value);
      }
    }
    return params;
  }
}

/// Concise navigation helpers when a [BuildContext] is in scope.
extension StoryNavX on BuildContext {
  Future<void> storyPush(
    String path, {
    Map<String, dynamic>? arguments,
    bool rootNavigator = false,
  }) {
    return StoryNavigator.instance.push(
      path,
      arguments: arguments,
      context: this,
      rootNavigator: rootNavigator,
    );
  }

  Future<T?> storyPushForResult<T>(
    String path, {
    Map<String, dynamic>? arguments,
    bool rootNavigator = false,
  }) {
    return StoryNavigator.instance.pushForResult<T>(
      path,
      arguments: arguments,
      context: this,
      rootNavigator: rootNavigator,
    );
  }

  Future<void> storyPopAndPush(
    String path, {
    Map<String, dynamic>? arguments,
    bool rootNavigator = false,
  }) {
    return StoryNavigator.instance.popAndPush(
      path,
      arguments: arguments,
      context: this,
      rootNavigator: rootNavigator,
    );
  }

  Future<void> storyPushAndRemoveUntil(
    String path,
    RoutePredicate predicate, {
    Map<String, dynamic>? arguments,
    bool rootNavigator = false,
  }) {
    return StoryNavigator.instance.pushAndRemoveUntil(
      path,
      predicate,
      arguments: arguments,
      context: this,
      rootNavigator: rootNavigator,
    );
  }

  Future<void> storyPop<T>({T? result, bool rootNavigator = false}) {
    return StoryNavigator.instance.pop<T>(
      context: this,
      result: result,
      rootNavigator: rootNavigator,
    );
  }

  void storyPopToRoot({bool rootNavigator = false}) {
    StoryNavigator.instance.popToRoot(
      context: this,
      rootNavigator: rootNavigator,
    );
  }
}
