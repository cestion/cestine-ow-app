import 'package:flutter/material.dart';

import '../../../components/iap/iap_point_icon.dart';
import '../../../core/app_channel.dart';
import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/actor_pricing.dart';
import '../../../widgets/story_info_dialog.dart';

/// 发行信息 Tab 内「演员 IP 金库」区块，对齐 Figma / Web `ActorIpVaultDialog`。
class ActorIpVaultSection extends StatelessWidget {
  final String? vaultAmountUsdc;
  final bool isVaultLoading;

  const ActorIpVaultSection({
    super.key,
    this.vaultAmountUsdc,
    this.isVaultLoading = false,
  });

  static const _depositPercent = '30%';

  static Future<void> showHelpDialog(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.actorIpVault,
      actionLabel: l10n.commonOk,
      content: Text(
        l10n.actorIpVaultDescription,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
  }

  String _formatVaultAmount() {
    return formatActorVaultAmountDisplay(
      vaultAmountRaw: vaultAmountUsdc,
      isLoading: isVaultLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final foreground = StoryColors.foregroundOf(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              l10n.actorIpVault,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => showHelpDialog(context),
              behavior: HitTestBehavior.opaque,
              child: Icon(Icons.help_outline, size: 16, color: secondary),
            ),
          ],
        ),
        const SizedBox(height: StorySpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(StorySpacing.base),
          decoration: BoxDecoration(
            color: StoryColors.brandTeal.withValues(alpha: 0.05),
            borderRadius: StoryRadius.brMd,
          ),
          child: Row(
            children: [
              Text(
                _formatVaultAmount(),
                style: const TextStyle(
                  fontSize: 18,
                  height: 26 / 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.04,
                  color: StoryColors.brandTeal,
                ),
              ),
              const SizedBox(width: 2),
              if (AppChannel.isStore)
                const IapPointIcon(size: 18)
              else
                const Text(
                  'USDC',
                  style: TextStyle(
                    fontSize: 18,
                    height: 26 / 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.04,
                    color: StoryColors.brandTeal,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        _DepositLegendRow(
          dotColor: StoryColors.warning,
          prefix: l10n.actorIpVaultSignIncomePrefix,
          percent: _depositPercent,
          secondaryColor: secondary,
          emphasisColor: foreground,
        ),
        const SizedBox(height: StorySpacing.sm),
        _DepositLegendRow(
          dotColor: StoryColors.brandTeal,
          prefix: l10n.actorIpVaultSecondaryRoyaltyPrefix,
          percent: _depositPercent,
          secondaryColor: secondary,
          emphasisColor: foreground,
        ),
      ],
    );
  }
}

class _DepositLegendRow extends StatelessWidget {
  final Color dotColor;
  final String prefix;
  final String percent;
  final Color secondaryColor;
  final Color emphasisColor;

  const _DepositLegendRow({
    required this.dotColor,
    required this.prefix,
    required this.percent,
    required this.secondaryColor,
    required this.emphasisColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: prefix,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    color: secondaryColor,
                  ),
                ),
                TextSpan(
                  text: percent,
                  style: TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.bold,
                    color: emphasisColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
