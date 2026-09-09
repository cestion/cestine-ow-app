import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/common/story_action_sheet.dart';
import '../../components/iap/iap_buy_sheet.dart';
import '../../core/app_channel.dart';
import '../../core/story_sdk.dart';
import '../../foundation/story_launcher.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../provider/tab_index_provider.dart';
import '../../routes/route_args.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_time.dart';
import '../story_avatar.dart';
import '../story_skeleton.dart';
import 'story_drawer_watch_history.dart';
import 'story_drawer_wallet_card.dart';
import '../../foundation/navigator.dart';

const _notificationCardKey = ValueKey<String>('storyDrawerV2.notificationCard');
const _whitepaperCardKey = ValueKey<String>('storyDrawerV2.whitepaperCard');
const _settingsCardKey = ValueKey<String>('storyDrawerV2.settingsCard');

/// Figma V2 drawer (node `841:158236`, empty node `102:109764`).
///
/// Profile and content imagery comes from live data; the shared bundled empty
/// illustration matches the Figma empty-state asset.
class StoryDrawerV2 extends ConsumerWidget {
  const StoryDrawerV2({super.key, this.onNotificationsTap});

  static const double width = 305;

  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final isLoggedIn = ref.watch(
      authControllerProvider.select((c) => c.isLoggedIn),
    );
    final profile = ref.watch(authControllerProvider.select((c) => c.profile));
    // Guests render placeholders without initializing balance data.
    final walletBalances = isLoggedIn
        ? ref.watch(
            onChainWalletBalanceProvider.select(
              (state) => (state.usdcBalance, state.storyBalance),
            ),
          )
        : null;
    final walletIconUrls = ref.watch(
      withdrawConfigProvider.select((config) {
        final tokens = config.svmChainInfo?.tokens;
        return (tokens?['usdc']?.icon, tokens?['story']?.icon);
      }),
    );
    final notifications = isLoggedIn
        ? ref.watch(drawerNotificationPreviewProvider)
        : const DrawerNotificationPreviewState.ready();
    final watchHistory = isLoggedIn
        ? ref.watch(drawerWatchHistoryPreviewProvider)
        : const AsyncValue<List<WatchHistoryDrama>>.data([]);
    final background = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : StoryColors.lightMuted;

    void handleNotificationsTap() {
      if (isLoggedIn) {
        onNotificationsTap?.call();
        return;
      }

      unawaited(context.storyPopAndPush(RouteNames.login));
    }

    void handleProfileTap() {
      Navigator.of(context).pop();
      if (!isLoggedIn) {
        unawaited(context.storyPush(RouteNames.login));
        return;
      }
      ref
          .read(tabIndexProvider.notifier)
          .selectTabWithAuth(StoryTab.profile.index)
          .then((ok) {
            if (!context.mounted) return;
            if (!ok) {
              unawaited(
                context.storyPush(
                  RouteNames.login,
                  arguments: {'returnTo': 'tab'},
                ),
              );
            }
          });
    }

    void handleWhitepaperTap() {
      Navigator.of(context).pop();
      unawaited(
        StoryLauncher.openExternal(StorySdk.instance.config.env.whitepaperUrl),
      );
    }

    void handleSettingsTap() {
      unawaited(context.storyPopAndPush(RouteNames.settings));
    }

    void handleWatchHistoryTap() {
      unawaited(
        context.storyPopAndPush(
          isLoggedIn ? RouteNames.watchHistory : RouteNames.login,
        ),
      );
    }

    void requestLogin() {
      unawaited(context.storyPopAndPush(RouteNames.login));
    }

    bool ensureLoggedIn() {
      if (isLoggedIn) return true;
      requestLogin();
      return false;
    }

    void handleDepositTap() {
      if (!ensureLoggedIn()) return;
      if (AppChannel.isStore) {
        unawaited(showIapBuySheet(context, ref: ref));
        return;
      }
      final navigator = Navigator.of(context);
      navigator.pop();
      unawaited(context.storyPopAndPush(RouteNames.deposit));
    }

    void handleTradeTap() {
      if (!ensureLoggedIn()) return;
      Navigator.of(context).pop();
      unawaited(
        StoryLauncher.openExternal(StorySdk.instance.config.env.buyStoryUrl),
      );
    }

    void closeDrawerAndPush(String routeName, {String? token}) {
      unawaited(
        context.storyPopAndPush(
          routeName,
          arguments: token == null ? null : {'token': token},
        ),
      );
    }

    void showUsdcActions() {
      if (!ensureLoggedIn()) return;
      if (AppChannel.isStore) {
        unawaited(showIapBuySheet(context, ref: ref));
        return;
      }
      unawaited(
        StoryActionSheet.show<void>(
          context: context,
          title: 'USDC',
          style: StoryActionSheetStyle.groupedMenu,
          items: [
            ActionSheetItem<void>(
              label: context.l10n.drawerDeposit,
              onTap: (_) => closeDrawerAndPush(RouteNames.deposit),
            ),
            ActionSheetItem<void>(
              label: context.l10n.drawerWithdraw,
              onTap: (_) => closeDrawerAndPush(RouteNames.withdraw),
            ),
          ],
        ),
      );
    }

    void showStoryActions() {
      if (!ensureLoggedIn()) return;
      unawaited(
        StoryActionSheet.show<void>(
          context: context,
          title: 'STORY',
          style: StoryActionSheetStyle.groupedMenu,
          items: [
            ActionSheetItem<void>(
              label: context.l10n.profileWalletTrade,
              onTap: (_) => handleTradeTap(),
            ),
            ActionSheetItem<void>(
              label: context.l10n.drawerDeposit,
              onTap: (_) =>
                  closeDrawerAndPush(RouteNames.deposit, token: 'STORY'),
            ),
            ActionSheetItem<void>(
              label: context.l10n.drawerWithdraw,
              onTap: (_) =>
                  closeDrawerAndPush(RouteNames.withdraw, token: 'STORY'),
            ),
          ],
        ),
      );
    }

    return Drawer(
      width: width,
      elevation: 0,
      backgroundColor: background,
      shape: const RoundedRectangleBorder(),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(3, 4),
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: StorySpacing.base),
              _ProfileHeader(
                isLoggedIn: isLoggedIn,
                profile: profile,
                onProfileTap: handleProfileTap,
              ),
              const SizedBox(height: StorySpacing.base),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    StorySpacing.md,
                    0,
                    StorySpacing.md,
                    StorySpacing.base,
                  ),
                  children: [
                    StoryDrawerWalletCard(
                      usdcBalance: walletBalances?.$1,
                      storyBalance: walletBalances?.$2,
                      usdcIconUrl: walletIconUrls.$1,
                      storyIconUrl: walletIconUrls.$2,
                      onDepositTap: handleDepositTap,
                      onTradeTap: handleTradeTap,
                      onUsdcMoreTap: showUsdcActions,
                      onStoryMoreTap: showStoryActions,
                    ),
                    const SizedBox(height: StorySpacing.md),
                    _NotificationCard(
                      notifications: notifications,
                      prominentTitle: !isLoggedIn,
                      onTap: handleNotificationsTap,
                    ),
                    const SizedBox(height: StorySpacing.md),
                    StoryDrawerWatchHistoryCard(
                      history: watchHistory,
                      height: isLoggedIn ? null : 332,
                      headerFontSize: isLoggedIn ? 14 : 16,
                      emptyLabel: isLoggedIn ? null : context.l10n.commonNoData,
                      onHeaderTap: handleWatchHistoryTap,
                    ),
                    if (!isLoggedIn) ...[
                      const SizedBox(height: StorySpacing.md),
                      if (!AppChannel.isStore)
                        _DrawerMenuLink(
                          key: _whitepaperCardKey,
                          iconAsset: 'assets/drawer/receipt.svg',
                          label: context.l10n.drawerWhitepaper,
                          onTap: handleWhitepaperTap,
                        ),
                      const SizedBox(height: StorySpacing.itemGap),
                      _DrawerMenuLink(
                        key: _settingsCardKey,
                        iconAsset: 'assets/drawer/settings.svg',
                        label: context.l10n.drawerSettings,
                        onTap: handleSettingsTap,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.isLoggedIn,
    required this.profile,
    required this.onProfileTap,
  });

  final bool isLoggedIn;
  final UserProfile? profile;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final accountLabel = isLoggedIn
        ? _firstNonEmpty([profile?.nickname, profile?.email]) ??
              l10n.drawerEmailAccount
        : l10n.profileNotLoggedIn;

    return SizedBox(
      height: 44,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: StorySpacing.base),
        child: Row(
          children: [
            InkWell(
              customBorder: const CircleBorder(),
              onTap: onProfileTap,
              child: isLoggedIn
                  ? StoryAvatar(
                      imageUrl: profile?.avatarUrl,
                      userId: profile?.userId ?? profile?.id,
                      fallbackText: accountLabel,
                      size: 44,
                    )
                  : SvgPicture.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/common/avatar_d.svg'
                          : 'assets/common/avatar.svg',
                      key: const ValueKey('storyDrawerV2.guestAvatar'),
                      width: 44,
                      height: 44,
                    ),
            ),
            const SizedBox(width: StorySpacing.sm),
            Expanded(
              child: InkWell(
                onTap: onProfileTap,
                child: Text(
                  accountLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.04,
                  ),
                ),
              ),
            ),
            if (isLoggedIn) ...[
              const SizedBox(width: StorySpacing.sm),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  splashRadius: 18,
                  iconSize: 24,
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notifications,
    this.prominentTitle = false,
    this.onTap,
  });

  final DrawerNotificationPreviewState notifications;
  final bool prominentTitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final items = notifications.items;
    final hasUnread = items.any((item) => item.isUnread);

    if (!notifications.isReadingCache &&
        !notifications.isLoading &&
        items.isEmpty) {
      return _DrawerCard(
        key: _notificationCardKey,
        child: _CardHeader(
          title: context.l10n.drawerNotifications,
          trailingLabel: context.l10n.drawerNoNotifications,
          showChevron: true,
          fontSize: prominentTitle ? 16 : 14,
          onTap: onTap,
        ),
      );
    }

    return _DrawerCard(
      key: _notificationCardKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardHeader(
            title: context.l10n.drawerNotifications,
            showUnreadDot: hasUnread,
            showChevron: true,
            onTap: onTap,
          ),
          const SizedBox(height: StorySpacing.base),
          if (notifications.isReadingCache || notifications.isLoading)
            const _DrawerLoading.notification()
          else
            ..._withSpacing(
              items.take(3).map((item) => _NotificationRow(notification: item)),
              StorySpacing.md,
            ),
        ],
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.notification});

  final NotificationItem notification;

  @override
  Widget build(BuildContext context) {
    final userId = _firstNonEmpty([notification.operateUserId]);
    final actorCandidate =
        _firstNonEmpty([notification.operateNickname, userId]) ?? '';
    final actor = switch (notification.data) {
      ShowRewardNotificationData() || StaminaLowNotificationData() => '',
      _ => actorCandidate,
    };
    final avatarFallback = _firstNonEmpty([
      notification.operateNickname,
      userId,
    ]);
    final message =
        notification.data is UnknownNotificationData && actor.isNotEmpty
        ? ''
        : _notificationMessage(context, notification, includeActor: false);
    final messageStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    );

    return Row(
      children: [
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openNotifications(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              StoryAvatar(
                imageUrl: notification.leadingAvatarUrl,
                userId: userId,
                fallbackText: avatarFallback,
                size: 32,
              ),
              if (notification.isUnread)
                const Positioned(left: -3, top: -3, child: _UnreadDot(size: 6)),
            ],
          ),
        ),
        const SizedBox(width: StorySpacing.sm),
        Expanded(
          child: InkWell(
            onTap: () => _openNotifications(context),
            child: LayoutBuilder(
              builder: (context, constraints) => Row(
                children: [
                  if (actor.isNotEmpty)
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.4,
                      ),
                      child: Text(
                        actor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: messageStyle,
                      ),
                    ),
                  if (actor.isNotEmpty && message.isNotEmpty)
                    const SizedBox(width: 4),
                  if (message.isNotEmpty)
                    Expanded(
                      child: Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: messageStyle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          _formatEventTime(context, notification.eventTime),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
            color: Theme.of(context).brightness == Brightness.dark
                ? StoryColors.darkTertiaryText
                : StoryColors.lightTertiaryText,
          ),
        ),
      ],
    );
  }

  void _openNotifications(BuildContext context) {
    unawaited(
      context.storyPopAndPush(
        RouteNames.notifications,
        arguments: NotificationArgs.forNotification(notification).toMap(),
      ),
    );
  }
}

/// Guest-only link matching the profile sidebar row: icon + label + chevron.
class _DrawerMenuLink extends StatelessWidget {
  const _DrawerMenuLink({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 36,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: StorySpacing.sm),
          child: Row(
            children: [
              SvgPicture.asset(
                iconAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
              ),
              const SizedBox(width: StorySpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 10,
                height: 20,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/drawer/arrow_right.svg',
                    width: 6,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                      Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerCard extends StatelessWidget {
  const _DrawerCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightCard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.md,
          vertical: StorySpacing.base,
        ),
        child: child,
      ),
    );
  }
}

class _CardHeader extends StatelessWidget {
  const _CardHeader({
    required this.title,
    this.showUnreadDot = false,
    this.showChevron = false,
    this.trailingLabel,
    this.fontSize = 14,
    this.onTap,
  });

  final String title;
  final bool showUnreadDot;
  final bool showChevron;
  final String? trailingLabel;
  final double fontSize;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 20),
        child: Row(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: fontSize,
                height: (fontSize == 16 ? 24 : 20) / fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (showUnreadDot) ...[
              const SizedBox(width: StorySpacing.xs),
              const _UnreadDot(size: 6),
            ],
            const Spacer(),
            if (trailingLabel != null) ...[
              Text(
                trailingLabel!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? StoryColors.darkTertiaryText
                      : StoryColors.lightTertiaryText,
                ),
              ),
              const SizedBox(width: StorySpacing.sm),
            ],
            if (showChevron)
              SizedBox(
                width: 10,
                height: 20,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/drawer/arrow_right.svg',
                    width: 6,
                    height: 12,
                    colorFilter: ColorFilter.mode(
                      Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: StoryColors.destructive,
        shape: BoxShape.circle,
      ),
      child: SizedBox.square(dimension: size),
    );
  }
}

class _DrawerLoading extends StatelessWidget {
  const _DrawerLoading.notification()
    : itemHeight = 32,
      leadingWidth = 32,
      leadingRadius = const BorderRadius.all(Radius.circular(16));

  final double itemHeight;
  final double leadingWidth;
  final BorderRadius leadingRadius;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _withSpacing(
        List<Widget>.generate(3, (_) => _buildRow()),
        StorySpacing.md,
      ),
    );
  }

  Widget _buildRow() {
    return SizedBox(
      height: itemHeight,
      child: Row(
        children: [
          StorySkeletonBox(
            width: leadingWidth,
            height: itemHeight,
            borderRadius: leadingRadius,
          ),
          const SizedBox(width: StorySpacing.sm),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StorySkeletonBox(width: double.infinity, height: 12),
                SizedBox(height: StorySpacing.sm),
                StorySkeletonBox(width: 72, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _withSpacing(Iterable<Widget> children, double spacing) {
  final widgets = children.toList();
  return [
    for (var index = 0; index < widgets.length; index++) ...[
      if (index > 0) SizedBox(height: spacing),
      widgets[index],
    ],
  ];
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

String _notificationMessage(
  BuildContext context,
  NotificationItem item, {
  bool includeActor = true,
}) {
  final actor = includeActor
      ? _firstNonEmpty([item.operateNickname, item.operateUserId]) ?? ''
      : '';

  String withActor(String message) => actor.isEmpty
      ? message
      : message.isEmpty
      ? actor
      : '$actor $message';

  return (switch (item.data) {
    IpSignNotificationData(:final ipName) =>
      context.l10n.drawerNotificationSignedActor(actor, ipName ?? ''),
    ShowRewardNotificationData(:final amount, :final assetCode) =>
      context.l10n.notificationIncomeEarned(
        [
          amount?.trim() ?? '',
          assetCode?.trim() ?? '',
        ].where((part) => part.isNotEmpty).join(' '),
      ),
    StaminaLowNotificationData(:final ipName) =>
      context.l10n.notificationStaminaLow(ipName ?? ''),
    final TargetInteractionNotificationData data => withActor(
      switch (item.eventType) {
        NotificationEventType.favorite =>
          data.isDrama
              ? context.l10n.notificationInteractionFavoritedDrama(
                  data.targetName ?? '',
                )
              : context.l10n.notificationInteractionFavoritedVideo,
        _ =>
          data.isDrama
              ? context.l10n.notificationInteractionLikedDrama(
                  data.targetName ?? '',
                )
              : context.l10n.notificationInteractionLikedVideo,
      },
    ),
    CommentNotificationData(:final content) => withActor(
      context.l10n.notificationInteractionCommented(content ?? ''),
    ),
    FollowNotificationData() => withActor(
      context.l10n.notificationInteractionFollowedYou,
    ),
    UnknownNotificationData(:final rawEventType) =>
      _firstNonEmpty([actor, rawEventType]) ?? '',
  }).trim();
}

String _formatEventTime(BuildContext context, String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return '';
  final numeric = int.tryParse(trimmed);
  final parsedDate = numeric == null ? DateTime.tryParse(trimmed) : null;
  final milliseconds = numeric == null
      ? parsedDate?.millisecondsSinceEpoch
      : (numeric < 10000000000 ? numeric * 1000 : numeric);
  return FormatTime.formatRecentOrDateTime(context, milliseconds);
}
