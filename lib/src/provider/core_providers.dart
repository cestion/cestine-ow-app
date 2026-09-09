import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/story_api_client.dart';
import '../components/common/story_toast.dart';
import '../controller/controllers.dart';
import '../core/logging_request_policy_observer.dart';
import '../core/request_coalescer.dart';
import '../core/story_constants.dart';
import '../core/story_logger.dart';
import '../core/story_sdk.dart';
import '../core/story_sdk_config.dart';
import '../data/repository/story_local_repository.dart';
import '../foundation/locale_controller.dart';
import '../foundation/navigator_bridge.dart';
import '../foundation/shell_coverage_observer.dart';
import '../foundation/telemetry.dart';
import '../foundation/theme_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/cloudfront_cookie_service.dart';
import '../services/connectivity_service.dart';
import '../services/device_id_service.dart';
import '../services/alice_inspector_service.dart';
import '../services/privy_service.dart';
import 'auth_providers.dart';
import '../foundation/navigator.dart';

final Provider<StorySdkConfig> storySdkConfigProvider =
    Provider<StorySdkConfig>((ref) {
      return StorySdk.instance.config;
    });

final Provider<StoryLocalRepository> localRepositoryProvider =
    Provider<StoryLocalRepository>((ref) {
      return StorySdk.instance.localRepository;
    });

/// Process-wide in-flight merger for idempotent reads.
///
/// Repositories and read-path controllers should [ref.read] this instead of
/// constructing a private [MemoryRequestCoalescer]. Keys must stay unique via
/// [RequestKeys]. Cleared on logout / account switch.
///
/// Debug builds attach [debugRequestPolicyObserver] for coalesce hit logs.
final Provider<RequestCoalescer> requestCoalescerProvider =
    Provider<RequestCoalescer>((ref) {
      return MemoryRequestCoalescer(observer: debugRequestPolicyObserver);
    });

/// Logged-in owner for user-scoped background services.
final Provider<String?> currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(
    authControllerProvider.select((auth) {
      if (!auth.isLoggedIn || auth.isLoggingOut) return null;
      final userId = auth.userId?.trim();
      return userId?.isNotEmpty == true ? userId : null;
    }),
  );
});

final Provider<PrivyService> privyServiceProvider = Provider<PrivyService>((
  ref,
) {
  return StorySdk.instance.privyService;
});

final Provider<ConnectivityService> connectivityProvider =
    Provider<ConnectivityService>((ref) {
      final service = ConnectivityService();
      service.initialize();
      ref.onDispose(service.dispose);
      return service;
    });

final Provider<DeviceIdService> deviceIdServiceProvider =
    Provider<DeviceIdService>((ref) {
      return DeviceIdService();
    });

final Provider<StoryApiClient> apiClientProvider = Provider<StoryApiClient>((
  ref,
) {
  final config = ref.watch(storySdkConfigProvider);
  final localRepo = ref.read(localRepositoryProvider);
  final client = StoryApiClient(
    baseUrl: config.effectiveApiBaseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
    maxRetries: config.enableApiRetry ? config.apiMaxRetries : 1,
    connectivity: ref.read(connectivityProvider),
    aliceAdapter: config.env.isProduction
        ? null
        : AliceInspectorService.httpAdapter,
    tokenProvider: () => localRepo.cachedToken,
    localeProvider: () {
      final locale = StoryLocaleController.instance.current;
      return locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    },
    onUnauthorized: (code) async {
      final authNotifier = ref.read<AuthController>(
        authControllerProvider.notifier,
      );
      final authState = ref.read<AuthState>(authControllerProvider);
      if (authState.isLoggingOut) {
        StoryLogger.d(
          'Unauthorized received but logout already in progress, skipping',
          tag: 'ApiClient',
        );
        return;
      }
      // Guest / already-logged-out callers (e.g. drama detail my-review) can
      // legitimately get 401. Never pop the navigation stack for them.
      if (!authState.isLoggedIn) {
        StoryLogger.d(
          'Unauthorized while guest; skip logout/popToRoot',
          tag: 'ApiClient',
        );
        return;
      }
      final showSessionExpiredToast =
          code == ApiResponseCode.unauthorizedAlt ||
          code == ApiResponseCode.unauthorized;
      StoryLogger.d(
        'Unauthorized response received (code=$code), triggering logout'
        '${showSessionExpiredToast ? ' + session toast' : ''}',
        tag: 'ApiClient',
      );
      await _logoutAndReturnHome(
        authNotifier,
        showSessionExpiredToast: showSessionExpiredToast,
      );
    },
  );
  ref.onDispose(client.dispose);
  client.preheatDns();
  return client;
});

Future<void> _logoutAndReturnHome(
  AuthController authNotifier, {
  required bool showSessionExpiredToast,
}) async {
  try {
    final toastMessage = showSessionExpiredToast
        ? lookupAppLocalizations(
            StoryLocaleController.instance.current,
          ).authSessionExpired
        : null;

    await authNotifier.logout();
    StoryNavigator.instance.popToRoot();

    // Brief delay so navigator overlay is ready after popToRoot.
    if (toastMessage != null) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final overlay =
          StoryNavigator.instance.navigatorKey.currentState?.overlay;
      if (overlay == null) {
        StoryLogger.w(
          'No navigator overlay for session-expired toast',
          tag: 'ApiClient',
        );
        return;
      }
      StoryToast.showOnOverlay(
        overlay,
        message: toastMessage,
        type: StoryToastType.error,
      );
    }
  } catch (e, st) {
    StoryLogger.e(
      'Failed to handle unauthorized response',
      error: e,
      stackTrace: st,
      tag: 'ApiClient',
    );
  }
}

class LocaleCodeNotifier extends Notifier<String> {
  @override
  String build() {
    final controller = StoryLocaleController.instance;
    final sub = controller.changes.listen((locale) {
      state = locale.languageCode == 'zh' ? 'zh' : locale.languageCode;
    });
    ref.onDispose(() => sub.cancel());
    final current = controller.current;
    return current.languageCode == 'zh' ? 'zh' : current.languageCode;
  }
}

final localeCodeProvider = NotifierProvider<LocaleCodeNotifier, String>(
  LocaleCodeNotifier.new,
);

final mainShellScaffoldKeyProvider = Provider<GlobalKey<ScaffoldState>>((ref) {
  return GlobalKey<ScaffoldState>();
});

/// Whether the main shell drawer is open. Banner SurfaceViews must detach
/// while the drawer covers the theater tab (Android z-order leak).
final mainShellDrawerOpenProvider = NotifierProvider<_DrawerOpenNotifier, bool>(
  _DrawerOpenNotifier.new,
);

class _DrawerOpenNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setOpen(bool open) => state = open;
}

/// True when a route covers the main shell ([ShellCoverageObserver.canPop]).
final mainShellRouteCoveredProvider =
    NotifierProvider<_RouteCoveredNotifier, bool>(_RouteCoveredNotifier.new);

class _RouteCoveredNotifier extends Notifier<bool> {
  @override
  bool build() {
    final observer = ShellCoverageObserver.instance;
    void onChange() => state = observer.covered.value;
    observer.covered.addListener(onChange);
    ref.onDispose(() => observer.covered.removeListener(onChange));
    return observer.covered.value;
  }
}

final Provider<CloudFrontCookieService> cloudfrontCookieServiceProvider =
    Provider<CloudFrontCookieService>((ref) {
      return CloudFrontCookieService.instance;
    });

final Provider<StoryNavigatorBridge> navigatorBridgeProvider =
    Provider<StoryNavigatorBridge>((ref) {
      return StoryNavigatorBridgeRegistry.instance;
    });

final Provider<StoryTelemetry> telemetryProvider = Provider<StoryTelemetry>((
  ref,
) {
  return StoryTelemetryRegistry.instance;
});

// ─── Locale and Theme mode Notifiers to bridge controller streams ───────────

class AppLocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final controller = StoryLocaleController.instance;
    final sub = controller.changes.listen((locale) {
      state = locale;
    });
    ref.onDispose(() => sub.cancel());
    return controller.current;
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale>(
  AppLocaleNotifier.new,
);

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final controller = StoryThemeController.instance;
    final sub = controller.changes.listen((mode) {
      state = mode;
    });
    ref.onDispose(() => sub.cancel());
    return controller.current;
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);
