import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/nft/actor_price_trend_section.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/actor_collection_model.dart';
import '../../../provider/controller_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/actor_pricing.dart';
import '../../../utils/format_number.dart';
import '../../../utils/validators.dart';
import 'actor_detail_widgets.dart';
import 'actor_ip_vault_section.dart';

class ActorIssueTab extends ConsumerWidget {
  final ActorCollection actor;
  final int maxSupply;
  final int signedCount;
  final int remainingCount;
  final double price;

  const ActorIssueTab({
    super.key,
    required this.actor,
    required this.maxSupply,
    required this.signedCount,
    required this.remainingCount,
    required this.price,
  });

  String _shortenAddress(String? address) {
    if (address == null || address.isEmpty) return '0x7A2b...3fD8';
    return truncateAddress(address);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final initialPrice = actor.initialPriceUsdc ?? price;
    final isFixed = isFixedActorPricingMode(actor.pricingMode);
    final actorId = actor.id;
    final vaultAsync = actorId == null
        ? null
        : ref.watch(actorVaultDepositProvider(actorId));

    final isVaultLoading = vaultAsync?.isLoading ?? false;
    final vaultAmount = vaultAsync?.maybeWhen(
      data: (result) =>
          result.isSuccess ? result.dataOrNull?.vaultAmount : null,
      orElse: () => null,
    );

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

    // Figma 881:188908 / 881:190612 — 信息区圆角描边卡片。
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.screenHorizontal,
        StorySpacing.base,
        StorySpacing.screenHorizontal,
        StorySpacing.xl,
      ),
      child: Container(
        padding: const EdgeInsets.all(StorySpacing.base),
        decoration: BoxDecoration(
          color: StoryColors.cardOf(brightness),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StoryColors.borderOf(brightness),
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
                brightness: brightness,
              ),
            ],
            const SizedBox(height: StorySpacing.base),
            if (isFixed)
              ActorIssueFixedPricePanel(brightness: brightness)
            else
              ActorPriceTrendSection(
                signedCount: signedCount,
                maxSupply: maxSupply,
                initialPrice: initialPrice,
                currentPrice: price,
              ),
            const SizedBox(height: StorySpacing.base),
            ActorIpVaultSection(
              vaultAmountUsdc: vaultAmount,
              isVaultLoading: isVaultLoading,
            ),
          ],
        ),
      ),
    );
  }
}
