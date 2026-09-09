import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_channel.dart';
import '../../core/story_sdk.dart';
import '../../foundation/story_launcher.dart';
import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../utils/format_number.dart';
import '../../widgets/story_token_logo.dart';
import '../common/story_action_sheet.dart';
import '../iap/iap_buy_sheet.dart';
import '../iap/iap_point_icon.dart';
import 'profile_colors.dart';
import '../../foundation/navigator.dart';

/// Compact two-row wallet card from the personal-center design.
class ProfileWalletSection extends ConsumerWidget {
  const ProfileWalletSection({super.key});

  Future<void> _openTransferPage(
    BuildContext context,
    WidgetRef ref,
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    await context.storyPush(routeName, arguments: arguments);
    if (!context.mounted) return;
    await ref.read(onChainWalletBalanceProvider.notifier).refreshSilently();
  }

  void _showUsdcActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    unawaited(
      StoryActionSheet.show<void>(
        context: context,
        title: 'USDC',
        style: StoryActionSheetStyle.groupedMenu,
        items: [
          ActionSheetItem<void>(
            label: l10n.drawerDeposit,
            onTap: (_) =>
                unawaited(_openTransferPage(context, ref, RouteNames.deposit)),
          ),
          ActionSheetItem<void>(
            label: l10n.drawerWithdraw,
            onTap: (_) =>
                unawaited(_openTransferPage(context, ref, RouteNames.withdraw)),
          ),
        ],
      ),
    );
  }

  void _showStoryActions(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    unawaited(
      StoryActionSheet.show<void>(
        context: context,
        title: 'STORY',
        style: StoryActionSheetStyle.groupedMenu,
        items: [
          ActionSheetItem<void>(
            label: l10n.profileWalletTrade,
            onTap: (_) => StoryLauncher.openExternal(
              StorySdk.instance.config.env.buyStoryUrl,
            ),
          ),
          ActionSheetItem<void>(
            label: l10n.drawerDeposit,
            onTap: (_) => unawaited(
              _openTransferPage(
                context,
                ref,
                RouteNames.deposit,
                arguments: const {'token': 'STORY'},
              ),
            ),
          ),
          ActionSheetItem<void>(
            label: l10n.drawerWithdraw,
            onTap: (_) => unawaited(
              _openTransferPage(
                context,
                ref,
                RouteNames.withdraw,
                arguments: const {'token': 'STORY'},
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final wallet = ref.watch(onChainWalletBalanceProvider);
    final config = ref.watch(withdrawConfigProvider);
    final storyToken = config.svmChainInfo?.tokens?['story'];
    final usdcToken = config.svmChainInfo?.tokens?['usdc'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: ProfileColors.walletCardBg(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _WalletAssetRow(
                token: 'USDC',
                label: 'USDC',
                balance: wallet.usdcBalance,
                loading: wallet.isLoading,
                iconUrl: usdcToken?.icon,
                actionLabel: l10n.drawerDeposit,
                onAction: () => AppChannel.isStore
                    ? showIapBuySheet(context, ref: ref)
                    : unawaited(
                        _openTransferPage(context, ref, RouteNames.deposit),
                      ),
                onMore: () => AppChannel.isStore
                    ? showIapBuySheet(context, ref: ref)
                    : _showUsdcActions(context, ref),
                storePoints: true,
              ),
              const SizedBox(height: 12),
              Divider(
                height: 0,
                thickness: 0.5,
                color: ProfileColors.outlineBorder(brightness),
              ),
              const SizedBox(height: 12),
              _WalletAssetRow(
                token: 'STORY',
                label: 'Story',
                balance: wallet.storyBalance,
                loading: wallet.isLoading,
                iconUrl: storyToken?.icon,
                actionLabel: l10n.profileWalletTrade,
                onAction: () => StoryLauncher.openExternal(
                  StorySdk.instance.config.env.buyStoryUrl,
                ),
                onMore: () => _showStoryActions(context, ref),
                hideActionInStore: true,
                hideRowTapInStore: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletAssetRow extends StatelessWidget {
  const _WalletAssetRow({
    required this.token,
    required this.label,
    required this.balance,
    required this.loading,
    required this.actionLabel,
    required this.onAction,
    required this.onMore,
    this.iconUrl,
    this.storePoints = false,
    this.hideActionInStore = false,
    this.hideRowTapInStore = false,
  });

  final String token;
  final String label;
  final double balance;
  final bool loading;
  final String? iconUrl;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback onMore;
  final bool storePoints;
  final bool hideActionInStore;
  final bool hideRowTapInStore;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = ProfileColors.secondaryText(brightness);
    final isStorePoints = storePoints && AppChannel.isStore;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hideRowTapInStore && AppChannel.isStore ? null : onMore,
      child: Row(
        children: [
          if (isStorePoints)
            const IapPointIcon(size: 36)
          else
            StoryTokenLogo(token: token, imageUrl: iconUrl, size: 36),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStorePoints ? context.l10n.currency : label,
                  maxLines: 1,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 13,
                    height: 18 / 13,
                  ),
                ),
                Text(
                  loading ? '—' : formatNumber(balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.04,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (!(hideActionInStore && AppChannel.isStore))
            _WalletActionButton(label: actionLabel, onPressed: onAction),
          if (!AppChannel.isStore) ...[
            const SizedBox(width: 8),
            _WalletMoreButton(onPressed: onMore),
          ],
        ],
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: ProfileColors.walletActionBg(brightness),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.04,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletMoreButton extends StatelessWidget {
  const _WalletMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: ProfileColors.walletActionBg(brightness),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(
            Icons.more_vert,
            size: 20,
            color: StoryColors.foregroundOf(brightness),
          ),
        ),
      ),
    );
  }
}
