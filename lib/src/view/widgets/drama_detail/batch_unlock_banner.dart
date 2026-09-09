import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/components.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/wallet_balance_gate.dart';

class BatchUnlockBanner extends ConsumerWidget {
  final DramaDetail d;
  final ThemeData theme;
  const BatchUnlockBanner({super.key, required this.d, required this.theme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: StorySpacing.sm),
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: const BoxDecoration(
        gradient: StoryColors.brandGradient,
        borderRadius: StoryRadius.brLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.local_offer, color: StoryColors.onOverlay, size: 24),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.dramaBatchUnlockDiscount(
                    (d.batchUnlockDiscountRate! * 100).toStringAsFixed(0),
                  ),
                  style: StoryTextStyles.headingMedium(
                    color: StoryColors.onOverlay,
                  ),
                ),
                const SizedBox(height: StorySpacing.xxs),
                Text(
                  context.l10n.dramaBatchUnlockSubtitle,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.onOverlayMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              if (!ref.read(authControllerProvider).isLoggedIn) {
                StoryToast.warning(context, context.l10n.errorUnauthorized);
                return;
              }

              // Calculate batch unlock cost
              final totalEps = d.totalEpisodes ?? 0;
              final freeEps = d.freeEps ?? 0;
              final unlockedEps = d.unlockedEpsCount ?? 0;
              final lockedCount = totalEps - freeEps - unlockedEps;
              final pricePerEp = d.episodePrice ?? 0.0;
              final discount = d.batchUnlockDiscountRate ?? 0.0;
              final batchCost = lockedCount > 0
                  ? lockedCount * pricePerEp * (1 - discount)
                  : 0.0;

              // Check sufficient balance (fresh on-chain read) + optimistic deduct
              if (batchCost > 0) {
                final ticket = await prepareUsdcSpend(
                  ref,
                  context,
                  batchCost,
                  reason: 'batch_unlock',
                );
                if (ticket == null) return;
              }

              final unlock = ref.read(dramaUnlockServiceProvider);
              final result = await unlock.unlockEpisodeBatch(
                d.id ?? '',
                'batch_unlock',
              );

              // Always refresh to reconcile with chain state
              await ref.read(walletLedgerProvider).refresh();

              if (context.mounted) {
                StoryToast.show(
                  context,
                  message: result.isSuccess
                      ? context.l10n.dramaBatchUnlockSuccess
                      : (result.errorOrNull?.userMessage ??
                            context.l10n.dramaUnlockFailedRetry),
                  type: result.isSuccess
                      ? StoryToastType.success
                      : StoryToastType.error,
                );
              }
            },
            child: Text(
              context.l10n.dramaBatchUnlockAll,
              style: StoryTextStyles.labelMedium(color: StoryColors.onOverlay),
            ),
          ),
        ],
      ),
    );
  }
}
