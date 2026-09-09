import 'package:flutter/material.dart';

typedef StoryRouteBuilder = Widget Function(dynamic arguments);

/// Wraps a deferred-import page factory with lazy loading.
///
/// On first navigation shows a loading indicator, then transitions to the
/// real page once [loadLibrary] completes. Subsequent navigations are
/// served from the cached factory directly.
class LazyPageRoute {
  final Future<void> Function() loadLibrary;
  final Widget Function(dynamic args) buildPage;
  bool _loaded = false;

  LazyPageRoute({required this.loadLibrary, required this.buildPage});

  Widget call(dynamic args) {
    if (_loaded) return buildPage(args);
    return _LazyPageLoader(
      loadLibrary: loadLibrary,
      buildPage: buildPage,
      args: args,
      onLoaded: () => _loaded = true,
    );
  }
}

class _LazyPageLoader extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final Widget Function(dynamic args) buildPage;
  final dynamic args;
  final VoidCallback onLoaded;

  const _LazyPageLoader({
    required this.loadLibrary,
    required this.buildPage,
    required this.args,
    required this.onLoaded,
  });

  @override
  State<_LazyPageLoader> createState() => _LazyPageLoaderState();
}

class _LazyPageLoaderState extends State<_LazyPageLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    widget.loadLibrary().then((_) {
      widget.onLoaded();
      if (mounted) setState(() => _loaded = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.buildPage(widget.args);
  }
}

class StoryRoute {
  final String name;
  final StoryRouteBuilder builder;

  const StoryRoute({required this.name, required this.builder});
}

class StoryRouter {
  static final StoryRouter _instance = StoryRouter._();
  static StoryRouter get instance => _instance;

  StoryRouter._();

  static final RouteObserver<PageRoute<dynamic>> observer =
      RouteObserver<PageRoute<dynamic>>();

  final Map<String, StoryRouteBuilder> _routes = {};

  static Widget Function(Widget page)? pageDecorator;

  void register(String name, StoryRouteBuilder builder) {
    _routes[name] = builder;
  }

  void registerAll(List<StoryRoute> routes) {
    for (final route in routes) {
      register(route.name, route.builder);
    }
  }

  List<String> get routeNames => _routes.keys.toList();

  Widget? buildPage(String name, dynamic arguments) {
    final builder = _routes[name];
    final page = builder?.call(arguments);
    if (page != null && pageDecorator != null) {
      return pageDecorator!(page);
    }
    return page;
  }

  bool hasRoute(String name) => _routes.containsKey(name);

  void clear() {
    _routes.clear();
  }
}
