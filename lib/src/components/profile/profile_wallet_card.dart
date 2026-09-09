import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/story_l10n.dart';
import '../../provider/app_providers.dart';
import '../../routes/route_names.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/format_number.dart';
import '../common/story_toast.dart';
import '../../foundation/navigator.dart';

/// Figma「钱包模块」— balances, address copy, trade / deposit / withdraw.
class ProfileWalletCard extends ConsumerWidget {
  const ProfileWalletCard({super.key});

  String _shortAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final address = ref.watch(
      authControllerProvider.select((c) => c.solanaAddress),
    );
    final wallet = ref.watch(onChainWalletBalanceProvider);
    final cardBg = StoryColors.cardOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final fg = StoryColors.foregroundOf(brightness);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.screenHorizontal,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StoryColors.borderOf(brightness),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(
                    l10n.profileWalletTitle,
                    style: StoryTextStyles.bodyMedium(
                      color: fg,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const Spacer(),
                  if (address.isNotEmpty) ...[
                    Flexible(
                      child: Text(
                        _shortAddress(address),
                        style: StoryTextStyles.bodySmall(color: muted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: address));
                        if (!context.mounted) return;
                        StoryToast.show(
                          context,
                          message: l10n.profileAddressCopied,
                          type: StoryToastType.success,
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(Icons.copy_rounded, size: 16, color: muted),
                      ),
                    ),
                  ] else
                    Text(
                      l10n.profileWalletCreating,
                      style: StoryTextStyles.bodySmall(color: muted),
                    ),
                ],
              ),
              const SizedBox(height: StorySpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _BalanceTile(
                      icon: Icons.auto_awesome,
                      iconBg: const Color(0xFF22C55E),
                      label: 'STORY',
                      value: formatNumber(wallet.storyBalance),
                      loading: wallet.isLoading,
                    ),
                  ),
                  const SizedBox(width: StorySpacing.sm),
                  Expanded(
                    child: _BalanceTile(
                      icon: Icons.attach_money,
                      iconBg: const Color(0xFF2775CA),
                      label: 'USDC',
                      value: formatNumber(wallet.usdcBalance),
                      loading: wallet.isLoading,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: StorySpacing.md),
              _OutlinedActionButton(
                label: l10n.profileTradeStory,
                onPressed: () {
                  StoryToast.show(context, message: l10n.nftTradeUnavailable);
                },
              ),
              const SizedBox(height: StorySpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: _FilledDarkButton(
                      label: l10n.drawerDeposit,
                      onPressed: () =>
                          context.storyPush(RouteNames.deposit),
                    ),
                  ),
                  const SizedBox(width: StorySpacing.sm),
                  Expanded(
                    child: _OutlinedActionButton(
                      label: l10n.drawerWithdraw,
                      onPressed: () =>
                          context.storyPush(RouteNames.withdraw),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final bool loading;

  const _BalanceTile({
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final tileBg = StoryColors.fillSecondaryOf(brightness);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(StoryRadius.mdValue),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: StorySpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: StoryTextStyles.bodySmall(color: muted)),
                  const SizedBox(height: 2),
                  Text(
                    loading ? '...' : value,
                    style: StoryTextStyles.bodyMedium(
                      color: fg,
                    ).copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilledDarkButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FilledDarkButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            color: StoryColors.darkButtonBgOf(brightness),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: StoryTextStyles.labelLarge(
                color: StoryColors.onOverlay,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _OutlinedActionButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: StoryColors.borderOf(brightness)),
          ),
          child: Center(
            child: Text(
              label,
              style: StoryTextStyles.labelLarge(
                color: StoryColors.foregroundOf(brightness),
              ).copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
