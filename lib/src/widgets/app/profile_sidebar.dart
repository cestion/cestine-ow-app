import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/common/story_toast.dart';
import '../../core/app_channel.dart';
import '../../core/story_env.dart';
import '../../core/story_sdk.dart';
import '../../foundation/navigator.dart';
import '../../foundation/story_launcher.dart';
import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../story_dialog.dart';

typedef ProfileSidebarAction = FutureOr<void> Function();

/// Optional action overrides for [ProfileSidebar].
///
/// Omitted actions use the app's standard routes and external links. This
/// keeps the sidebar convenient for normal use while allowing embedders and
/// widget tests to replace individual destinations.
@immutable
class ProfileSidebarActions {
  final ProfileSidebarAction? onCreatorManagement;
  final ProfileSidebarAction? onInvite;
  final ProfileSidebarAction? onIncome;
  final ProfileSidebarAction? onTransactionHistory;
  final ProfileSidebarAction? onFinanceDashboard;
  final ProfileSidebarAction? onWhitepaper;
  final ProfileSidebarAction? onSettings;
  final ProfileSidebarAction? onLogout;

  const ProfileSidebarActions({
    this.onCreatorManagement,
    this.onInvite,
    this.onIncome,
    this.onTransactionHistory,
    this.onFinanceDashboard,
    this.onWhitepaper,
    this.onSettings,
    this.onLogout,
  });
}

/// Figma-aligned side panel used by the current user's profile page.
///
/// Prefer [showProfileSidebar] over wiring this widget through
/// [Scaffold.endDrawer]: the route-based presentation overlays the bottom
/// navigation bar (full screen height) and supports swipe-to-dismiss while
/// staying scoped to the profile page.
class ProfileSidebar extends ConsumerWidget {
  static const double panelWidth = 305;

  final double width;
  final ProfileSidebarActions? actions;

  const ProfileSidebar({super.key, this.width = panelWidth, this.actions});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final foreground = StoryColors.foregroundOf(theme.brightness);
    final background = theme.colorScheme.surface;
    final topInset = MediaQuery.paddingOf(context).top;
    final l10n = context.l10n;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((c) => c.isLoggedIn),
    );

    final items = <_ProfileSidebarItem>[
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_creator_management'),
        asset: 'assets/drawer/creator_management.svg',
        label: l10n.drawerCreatorManagement,
        onTap: () => _openProtectedRoute(
          context,
          ref,
          RouteNames.creatorManagement,
          actions?.onCreatorManagement,
        ),
      ),
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_invite'),
        asset: 'assets/drawer/referral.svg',
        label: l10n.drawerInvite,
        onTap: () => _openProtectedRoute(
          context,
          ref,
          RouteNames.invite,
          actions?.onInvite,
        ),
      ),
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_income'),
        asset: 'assets/drawer/token.svg',
        label: l10n.profileEarnings,
        onTap: () => _openProtectedRoute(
          context,
          ref,
          RouteNames.income,
          actions?.onIncome,
        ),
      ),
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_transaction_history'),
        asset: 'assets/drawer/records.svg',
        label: l10n.drawerTxHistory,
        onTap: () => _openTransactionHistory(context, ref),
      ),
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_finance_dashboard'),
        asset: 'assets/drawer/dashboard.svg',
        label: l10n.drawerFinanceDashboard,
        onTap: () => _runAction(context, actions?.onFinanceDashboard, () async {
          await context.storyPush(RouteNames.financeDashboard,
            rootNavigator: true);
        }),
      ),
      if (!AppChannel.isStore)
        _ProfileSidebarItem(
          key: const ValueKey('profile_sidebar_whitepaper'),
          asset: 'assets/drawer/receipt.svg',
          label: l10n.drawerWhitepaper,
          onTap: () => _runAction(context, actions?.onWhitepaper, () async {
            await StoryLauncher.openExternal(
              StorySdk.instance.config.env.whitepaperUrl,
            );
          }),
        ),
      _ProfileSidebarItem(
        key: const ValueKey('profile_sidebar_settings'),
        asset: 'assets/drawer/settings.svg',
        label: l10n.drawerSettings,
        onTap: () => _runAction(context, actions?.onSettings, () async {
          await context.storyPush(RouteNames.settings,
            rootNavigator: true);
        }),
      ),
      if (isLoggedIn)
        _ProfileSidebarItem(
          key: const ValueKey('profile_sidebar_logout'),
          asset: 'assets/drawer/logout.svg',
          label: l10n.profileLogout,
          showChevron: false,
          onTap: () => _confirmLogout(context, ref),
        ),
    ];

    return Container(
      key: const ValueKey('profile_sidebar_panel'),
      width: width,
      height: double.infinity,
      decoration: BoxDecoration(
        color: background,
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            offset: Offset(3, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: topInset),
            const SizedBox(height: StorySpacing.base),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.screenHorizontal,
              ),
              child: Column(
                children: [
                  for (var index = 0; index < items.length; index++) ...[
                    items[index].build(foreground),
                    if (index != items.length - 1)
                      const SizedBox(height: StorySpacing.itemGap),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openProtectedRoute(
    BuildContext context,
    WidgetRef ref,
    String route,
    ProfileSidebarAction? override,
  ) {
    return _runAction(context, override, () async {
      final isLoggedIn = ref.read(
        authControllerProvider.select((s) => s.isLoggedIn),
      );
      await context.storyPush(isLoggedIn ? route : RouteNames.login,
        rootNavigator: true);
    });
  }

  Future<void> _openTransactionHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final override = actions?.onTransactionHistory;
    if (override != null) {
      await _runAction(context, override, () {});
      return;
    }

    final auth = ref.read(authControllerProvider);
    if (!auth.isLoggedIn) {
      await _runAction(context, null, () async {
        await context.storyPush(RouteNames.login,
          rootNavigator: true);
      });
      return;
    }

    final address = auth.solanaAddress;
    if (address.isEmpty) {
      StoryToast.error(context, context.l10n.incomeClaimNoWallet);
      return;
    }

    await _runAction(context, null, () async {
      final env = StorySdk.instance.config.env;
      final cluster = env.isProduction ? '' : '?cluster=devnet';
      await StoryLauncher.openExternal(
        '${StoryEnv.solscanBaseUrl}/$address$cluster',
      );
    });
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final override = actions?.onLogout;
    if (override != null) {
      await _runAction(context, override, () {});
      return;
    }

    final l10n = context.l10n;
    StoryDialog.confirm(
      context: context,
      title: l10n.profileLogoutConfirm,
      cancelLabel: l10n.commonCancel,
      confirmLabel: l10n.commonConfirm,
      onConfirm: () async {
        Navigator.of(context, rootNavigator: true).pop();
        await ref.read(authControllerProvider.notifier).logout();
      },
    );
  }

  Future<void> _runAction(
    BuildContext context,
    ProfileSidebarAction? override,
    ProfileSidebarAction fallback,
  ) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.pop();
    await Future<void>.delayed(Duration.zero);

    if (override != null) {
      await Future<void>.sync(override);
    } else {
      await Future<void>.sync(fallback);
    }
  }
}

class _ProfileSidebarItem {
  final Key key;
  final String asset;
  final String label;
  final VoidCallback onTap;
  final bool showChevron;

  const _ProfileSidebarItem({
    required this.key,
    required this.asset,
    required this.label,
    required this.onTap,
    this.showChevron = true,
  });

  Widget build(Color foreground) {
    final isSvg = asset.toLowerCase().endsWith('.svg');
    final icon = isSvg
        ? SvgPicture.asset(
            asset,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
          )
        : Image.asset(
            asset,
            width: 20,
            height: 20,
            color: foreground,
            colorBlendMode: BlendMode.srcIn,
            filterQuality: FilterQuality.high,
          );

    return SizedBox(
      key: key,
      height: 36,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: StorySpacing.sm),
          child: Row(
            children: [
              SizedBox.square(dimension: 20, child: icon),
              const SizedBox(width: StorySpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ),
              SizedBox(
                width: 10,
                height: 20,
                child: showChevron
                    ? SvgPicture.asset(
                        'assets/drawer/arrow_right.svg',
                        width: 10,
                        height: 20,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-height side panel route for [ProfileSidebar].
///
/// Slides in from the right edge, overlays the bottom navigation bar (unlike
/// [Scaffold.endDrawer], which is constrained by the hosting Scaffold), and
/// supports swipe-right-to-dismiss via a gesture-driven [AnimationController].
/// The route stays local to the page that pushes it, so other tabs never need
/// to know about it.
class ProfileSidebarRoute extends PopupRoute<void> {
  ProfileSidebarRoute({this.actions, super.settings});

  final ProfileSidebarActions? actions;

  @override
  String get barrierLabel => 'Profile sidebar';

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => StoryColors.overlayMid;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 250);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 200);

  AnimationController? _controller;

  @override
  AnimationController createAnimationController() {
    final controller = AnimationController(
      duration: transitionDuration,
      reverseDuration: reverseTransitionDuration,
      vsync: navigator!,
    );
    _controller = controller;
    return controller;
  }

  // No route-level transition wrapper — the slide is handled inside buildPage
  // so the same animation can be gesture-driven.
  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _ProfileSidebarPanel(controller: _controller!, actions: actions);
  }
}

/// Pushes [ProfileSidebar] as a full-height side panel that supports
/// swipe-to-dismiss and overlays the bottom navigation bar.
Future<void> showProfileSidebar(
  BuildContext context, {
  ProfileSidebarActions? actions,
}) {
  return Navigator.of(
    context,
    rootNavigator: true,
  ).push(ProfileSidebarRoute(actions: actions));
}

class _ProfileSidebarPanel extends StatelessWidget {
  const _ProfileSidebarPanel({required this.controller, required this.actions});

  final AnimationController controller;
  final ProfileSidebarActions? actions;

  static const double _panelWidth = ProfileSidebar.panelWidth;
  static const double _closeVelocityThreshold = 300;
  static const double _snapThreshold = 0.5;

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final delta = details.primaryDelta;
    if (delta == null) return;
    controller.value -= delta / _panelWidth;
  }

  void _onHorizontalDragEnd(DragEndDetails details, BuildContext context) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > _closeVelocityThreshold) {
      Navigator.of(context).maybePop();
      return;
    }
    if (velocity < -_closeVelocityThreshold) {
      controller.forward();
      return;
    }
    if (controller.value < _snapThreshold) {
      Navigator.of(context).maybePop();
    } else {
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: _onHorizontalDragUpdate,
        onHorizontalDragEnd: (details) =>
            _onHorizontalDragEnd(details, context),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(controller),
          child: SizedBox(
            width: _panelWidth,
            child: ProfileSidebar(actions: actions),
          ),
        ),
      ),
    );
  }
}
