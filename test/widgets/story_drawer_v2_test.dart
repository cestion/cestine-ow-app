import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:story_app/src/controller/auth_controller.dart';
import 'package:story_app/src/controller/auth_state.dart';
import 'package:story_app/src/foundation/story_theme.dart';
import 'package:story_app/src/l10n/app_localizations.dart';
import 'package:story_app/src/model/models.dart';
import 'package:story_app/src/provider/app_providers.dart';
import 'package:story_app/src/widgets/app/story_drawer_v2.dart';

void main() {
  testWidgets('renders the Figma empty drawer layout', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedOutAuthController.new),
          drawerNotificationPreviewProvider.overrideWith(
            _EmptyNotificationPreviewNotifier.new,
          ),
          withdrawConfigProvider.overrideWithValue(const WithdrawConfigState()),
          drawerWatchHistoryPreviewProvider.overrideWithValue(
            const AsyncValue<List<WatchHistoryDrama>>.data([]),
          ),
          onChainWalletBalanceProvider.overrideWith(
            _FakeWalletBalanceNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: StoryDrawerV2(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('通知消息'), findsOneWidget);
    expect(find.text('暂无新消息'), findsOneWidget);
    expect(find.text('白皮书'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('观看历史'), findsOneWidget);

    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('storyDrawerV2.notificationCard')),
      ),
      const Size(281, 56),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('storyDrawerV2.whitepaperCard')),
      ),
      const Size(281, 36),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey<String>('storyDrawerV2.settingsCard')),
      ),
      const Size(281, 36),
    );
  });

  testWidgets('logged-in header shows nickname instead of email', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_LoggedInAuthController.new),
          drawerNotificationPreviewProvider.overrideWith(
            _EmptyNotificationPreviewNotifier.new,
          ),
          withdrawConfigProvider.overrideWithValue(const WithdrawConfigState()),
          drawerWatchHistoryPreviewProvider.overrideWithValue(
            const AsyncValue<List<WatchHistoryDrama>>.data([]),
          ),
          onChainWalletBalanceProvider.overrideWith(
            _FakeWalletBalanceNotifier.new,
          ),
        ],
        child: MaterialApp(
          theme: buildLightTheme(),
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: Align(
              alignment: Alignment.centerLeft,
              child: StoryDrawerV2(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('小明'), findsOneWidget);
    expect(find.text('user@example.com'), findsNothing);
    expect(find.text('白皮书'), findsNothing);
    expect(find.text('设置'), findsNothing);
  });
}

class _LoggedOutAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(ready: true);
}

class _LoggedInAuthController extends AuthController {
  @override
  AuthState build() => const AuthState(
    ready: true,
    isLoggedIn: true,
    profile: UserProfile(
      userId: 'u1',
      email: 'user@example.com',
      nickname: '小明',
    ),
  );
}

class _EmptyNotificationPreviewNotifier
    extends DrawerNotificationPreviewNotifier {
  @override
  DrawerNotificationPreviewState build() =>
      const DrawerNotificationPreviewState.ready();
}

class _FakeWalletBalanceNotifier extends WalletBalanceNotifier {
  @override
  WalletBalanceState build() => const WalletBalanceState();
}
