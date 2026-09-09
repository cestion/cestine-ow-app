import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../components/iap/iap_point_icon.dart';
import '../../core/app_channel.dart';
import '../../foundation/story_theme.dart';
import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_number.dart';
import '../story_token_logo.dart';

/// Drawer wallet summary from Figma node `2670:141365`.
class StoryDrawerWalletCard extends StatelessWidget {
  const StoryDrawerWalletCard({
    super.key,
    required this.usdcBalance,
    required this.storyBalance,
    this.usdcIconUrl,
    this.storyIconUrl,
    required this.onDepositTap,
    required this.onTradeTap,
    required this.onUsdcMoreTap,
    required this.onStoryMoreTap,
  });

  final double? usdcBalance;
  final double? storyBalance;
  final String? usdcIconUrl;
  final String? storyIconUrl;
  final VoidCallback onDepositTap;
  final VoidCallback onTradeTap;
  final VoidCallback onUsdcMoreTap;
  final VoidCallback onStoryMoreTap;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final cardColor = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightCard;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.md,
          vertical: StorySpacing.base,
        ),
        child: Column(
          children: [
            _WalletTokenRow(
              token: 'USDC',
              iconUrl: usdcIconUrl,
              symbol: 'USDC',
              balance: usdcBalance,
              actionLabel: context.l10n.drawerDeposit,
              actionButtonKey: const ValueKey('storyDrawer.wallet.usdc.action'),
              onActionTap: onDepositTap,
              moreButtonKey: const ValueKey('storyDrawer.wallet.usdc.more'),
              onMoreTap: onUsdcMoreTap,
              storePoints: true,
            ),
            const SizedBox(height: StorySpacing.base),
            Divider(
              height: 0.3,
              thickness: 0.3,
              color: context.storyColors.divider,
            ),
            const SizedBox(height: StorySpacing.base),
            _WalletTokenRow(
              token: 'STORY',
              iconUrl: storyIconUrl,
              symbol: 'Story',
              balance: storyBalance,
              actionLabel: context.l10n.profileWalletTrade,
              actionButtonKey: const ValueKey(
                'storyDrawer.wallet.story.action',
              ),
              onActionTap: onTradeTap,
              moreButtonKey: const ValueKey('storyDrawer.wallet.story.more'),
              onMoreTap: onStoryMoreTap,
              hideActionInStore: true,
              hideRowTapInStore: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletTokenRow extends StatelessWidget {
  const _WalletTokenRow({
    required this.token,
    required this.symbol,
    required this.balance,
    required this.actionLabel,
    required this.actionButtonKey,
    required this.onActionTap,
    required this.moreButtonKey,
    required this.onMoreTap,
    this.iconUrl,
    this.storePoints = false,
    this.hideActionInStore = false,
    this.hideRowTapInStore = false,
  });

  final String token;
  final String symbol;
  final String? iconUrl;
  final double? balance;
  final String actionLabel;
  final Key actionButtonKey;
  final VoidCallback onActionTap;
  final Key moreButtonKey;
  final VoidCallback onMoreTap;
  final bool storePoints;
  final bool hideActionInStore;
  final bool hideRowTapInStore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isStorePoints = storePoints && AppChannel.isStore;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hideRowTapInStore && AppChannel.isStore ? null : onMoreTap,
      child: Row(
        children: [
          if (isStorePoints)
            const IapPointIcon(size: 32)
          else
            StoryTokenLogo(token: token, imageUrl: iconUrl, size: 32),
          const SizedBox(width: StorySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isStorePoints ? context.l10n.currency : symbol,
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    height: 18 / 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  balance == null ? '--' : formatNumber(balance),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: StorySpacing.sm),
          if (!(hideActionInStore && AppChannel.isStore))
            _WalletActionButton(
              key: actionButtonKey,
              label: actionLabel,
              onTap: onActionTap,
            ),
          if (!AppChannel.isStore) ...[
            const SizedBox(width: StorySpacing.sm),
            _WalletMoreButton(key: moreButtonKey, onTap: onMoreTap),
          ],
        ],
      ),
    );
  }
}

class _WalletActionButton extends StatelessWidget {
  const _WalletActionButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.storyColors.surfaceMuted,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 64,
          height: 28,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 12,
                height: 16 / 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.04,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletMoreButton extends StatelessWidget {
  const _WalletMoreButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.l10n.drawerWithdraw,
      child: Material(
        color: context.storyColors.surfaceMuted,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: SvgPicture.asset(
                'assets/drawer/dots_vertical.svg',
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onSurface,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
