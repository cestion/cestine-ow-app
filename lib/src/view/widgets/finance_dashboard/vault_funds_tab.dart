import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/app_providers.dart';
import '../../../styles/story_spacing.dart';
import 'actor_vault_ranking_section.dart';
import 'vault_funds_summary_card.dart';

/// 金库资金沉淀 Tab（Figma node 6312:96340 内容区）。
///
/// 结构：总资金/覆盖演员 IP 汇总卡片（[VaultFundsSummaryCard]）+
/// 演员 IP 金库排行（[ActorVaultRankingSection]，最多 5 条 + 查看更多入口）。
/// 数据来自 [vaultFundsControllerProvider]。
class VaultFundsTab extends ConsumerStatefulWidget {
  const VaultFundsTab({super.key});

  @override
  ConsumerState<VaultFundsTab> createState() => _VaultFundsTabState();
}

class _VaultFundsTabState extends ConsumerState<VaultFundsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vaultFundsControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vaultFundsControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
      children: [
        const VaultFundsSummaryCard(),
        const SizedBox(height: StorySpacing.base),
        ActorVaultRankingSection(
          items: state.ranking,
          isLoading: state.isLoading,
        ),
      ],
    );
  }
}
