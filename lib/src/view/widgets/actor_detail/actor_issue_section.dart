import 'package:flutter/material.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/actor_collection_model.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/actor_pricing.dart';
import '../../../utils/format_number.dart';
import '../../../utils/validators.dart';
import 'actor_ip_vault_section.dart';
import 'actor_detail_widgets.dart';
import '../../../components/nft/actor_price_trend_section.dart';

class ActorIssueSection extends StatelessWidget {
  final ActorCollection actor;
  final ThemeData theme;
  final bool isDark;
  final double price;
  final int signedCount;
  final int remainingCount;
  final int maxSupply;
  final String? vaultAmountUsdc;

  const ActorIssueSection({
    super.key,
    required this.actor,
    required this.theme,
    required this.isDark,
    required this.price,
    required this.signedCount,
    required this.remainingCount,
    required this.maxSupply,
    this.vaultAmountUsdc,
  });

  String _shortenAddress(String? address) {
    if (address == null || address.isEmpty) return '0x7A2b...3fD8';
    return truncateAddress(address);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isFixed = isFixedActorPricingMode(actor.pricingMode);
    final issueInfoRows = [
      (
        label: l10n.actorContractAddress,
        value: _shortenAddress(actor.nftMintAddress),
      ),
      (
        label: l10n.createActorTokenStandard,
        value: formatActorNftTokenStandard(actor.nftTokenStandard),
      ),
      (
        label: l10n.actorPricingType,
        value: actorPricingModeLabel(l10n, actor.pricingMode),
      ),
      (
        label: l10n.actorPriceStatTotalSupply,
        value: formatNumber(maxSupply, 0),
      ),
      (label: l10n.actorPriceStatSigned, value: formatNumber(signedCount, 0)),
      (
        label: l10n.actorPriceStatRemaining,
        value: formatNumber(remainingCount, 0),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.screenHorizontal,
        StorySpacing.xl,
        StorySpacing.screenHorizontal,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.actorIssueInfo,
            style: TextStyle(
              fontSize: 16,
              height: 24 / 16,
              fontWeight: FontWeight.bold,
              color: StoryColors.foregroundOf(theme.brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          Container(
            padding: const EdgeInsets.all(StorySpacing.base),
            decoration: BoxDecoration(
              color: StoryColors.cardOf(theme.brightness),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: StoryColors.borderOf(theme.brightness),
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < issueInfoRows.length; i++) ...[
                  if (i > 0) const SizedBox(height: StorySpacing.sm),
                  ActorIssueInfoRow(
                    label: issueInfoRows[i].label,
                    value: issueInfoRows[i].value,
                    brightness: theme.brightness,
                  ),
                ],
                const SizedBox(height: StorySpacing.base),
                if (isFixed)
                  ActorIssueFixedPricePanel(brightness: theme.brightness)
                else
                  ActorPriceTrendSection(
                    signedCount: signedCount,
                    maxSupply: maxSupply,
                    initialPrice: actor.initialPriceUsdc ?? price,
                    currentPrice: price,
                  ),
                const SizedBox(height: StorySpacing.base),
                ActorIpVaultSection(vaultAmountUsdc: vaultAmountUsdc),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
