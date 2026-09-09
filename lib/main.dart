import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/l10n/app_localizations.dart';
import 'src/core/core.dart';
import 'src/foundation/playback_auth_route_observer.dart';
import 'src/foundation/router.dart';
import 'src/foundation/shell_coverage_observer.dart';
import 'src/foundation/story_theme.dart';
import 'src/foundation/telemetry.dart';
import 'src/routes/route_names.dart';
import 'src/routes/story_routes.dart';
import 'src/provider/app_providers.dart';
import 'src/controller/watch_history_reporter.dart';
import 'src/services/alice_inspector_service.dart';
import 'src/view/main_shell_page.dart';
import 'src/widgets/story_root_builder.dart';
import 'src/foundation/navigator.dart';

Future<void> main() async {
  // 全局异常捕获：Flutter 框架层同步错误（布局/渲染/构建异常）
  // 以及 Dart 异步未处理异常（在同一个 zone 内初始化，避免 zone mismatch）
  FlutterError.onError = (details) {
    final exception = details.exception;

    // Suppress expected platform errors from NativeVideoPlayerController
    // during page disposal. When the native view is destroyed before the
    // controller finishes cleanup, the EventChannel cancel and dispose
    // calls throw MissingPluginException / NO_VIEW. These are harmless.
    if (exception is MissingPluginException) {
      final msg = exception.message ?? '';
      if (msg.contains('native_video_player') &&
          (msg.contains('cancel') ||
              msg.contains('listen') ||
              msg.contains('pause') ||
              msg.contains('dispose'))) {
        return; // Expected: controller method call after native view destroyed.
      }
    }
    if (exception is PlatformException && exception.code == 'NO_VIEW') {
      return; // Expected: dispose after native view destroyed.
    }

    // Suppress image codec errors — CachedNetworkImage handles these via
    // its errorWidget. The error surfaces here because the image pipeline
    // also reports to FlutterError.onError before the widget's errorBuilder
    // kicks in.
    if (exception is Exception &&
        exception.toString().contains('Invalid image data')) {
      return;
    }

    FlutterError.presentError(details);
    final stack = details.stack;
    StoryTelemetryRegistry.instance.error(exception, stackTrace: stack);
    StoryLogger.e(
      'FlutterError: $exception',
      error: exception,
      stackTrace: stack,
      tag: 'Global',
    );
  };

  // 环境选择优先级：--dart-define=ENV=dev|development|test|production
  // > kReleaseMode 默认（release→production，debug/profile→test）
  // 打 release 开发包：flutter build apk --release --dart-define=ENV=dev
  // 打 release 测试包：flutter build apk --release --dart-define=ENV=test
  const envStr = String.fromEnvironment('ENV');
  final StorySdkConfig sdkConfig;
  switch (envStr) {
    case 'dev':
    case 'development':
      sdkConfig = StorySdkConfig.development;
    case 'test':
      sdkConfig = StorySdkConfig.test;
    case 'production':
      sdkConfig = StorySdkConfig.production;
    default:
      sdkConfig = kReleaseMode
          ? StorySdkConfig.production
          : StorySdkConfig.test;
  }

  // 开发期绕过 OTP 的 initialToken 通过 --dart-define=INITIAL_TOKEN=... 注入。
  // 源码不留任何明文 token；production 严禁使用（如检测到非空，build 阶段就拒绝）。
  const initialToken = String.fromEnvironment('INITIAL_TOKEN');
  final effectiveConfig = initialToken.isEmpty || sdkConfig.env.isProduction
      ? sdkConfig
      : sdkConfig.copyWith(initialToken: initialToken);

  AliceInspectorService.configureStoryLogger(
    enabled: !effectiveConfig.env.isProduction,
  );
  await StorySdk.instance.initialize(config: effectiveConfig);

  // 路由注册（依赖 view 层，必须在 SDK 初始化之后）
  StoryRoutes.registerRoutes();

  runApp(const ProviderScope(child: _AppBootstrap(child: StoryApp())));
}

/// Starts app-wide services that require an initialized [StorySdk]. Keeping
/// this outside [StoryApp] lets widget tests render the app shell in isolation.
class _AppBootstrap extends ConsumerWidget {
  const _AppBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(uploadCoordinatorProvider.notifier);
    ref.read(watchHistoryBatchReporterProvider.notifier);
    return child;
  }
}

class StoryApp extends ConsumerWidget {
  const StoryApp({super.key});

  // ThemeData construction is expensive (full TextTheme + extensions);
  // build once instead of on every locale/themeMode rebuild.
  static final ThemeData _lightTheme = buildLightTheme();
  static final ThemeData _darkTheme = buildDarkTheme();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 全局 IAP 订阅：iapControllerProvider 非 autoDispose，App 启动即建立
    // purchaseStream 订阅与登录对账（防丢单前提，Apple IAP 契约 §5.3）。
    ref.watch(iapControllerProvider);

    final currentLocale = ref.watch(appLocaleProvider);
    final themeMode = ref.watch(appThemeModeProvider);

    return MaterialApp(
      title: 'StoryFun',
      debugShowCheckedModeBanner: false,
      navigatorKey: StoryNavigator.instance.navigatorKey,
      navigatorObservers: [
        StoryRouter.observer,
        ShellCoverageObserver.instance,
        PlaybackAuthRouteObserver.instance,
      ],
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: themeMode,
      initialRoute: RouteNames.main,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => StoryRootBuilder(child: child),
      onGenerateRoute: (settings) {
        final routeName = settings.name?.split('?').first ?? '';
        final arguments = settings.arguments;
        final page = StoryRouter.instance.buildPage(routeName, arguments);
        if (page != null) {
          if (routeName == RouteNames.login) {
            return MaterialPageRoute<bool>(
              builder: (_) => page,
              settings: settings,
            );
          }
          return MaterialPageRoute<dynamic>(
            builder: (_) => page,
            settings: settings,
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        // Fallback: navigate to main page for unknown routes
        return MaterialPageRoute<dynamic>(
          builder: (_) => const MainShellPage(),
          settings: const RouteSettings(name: RouteNames.main),
        );
      },
    );
  }
}
