import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../provider/app_providers.dart';
import '../../../styles/story_spacing.dart';
import 'fee_breakdown_section.dart';
import 'recent_usdc_ledger_section.dart';

/// USDC 收入明细 Tab（Figma node 6312:95387 内容区）。
///
/// 结构：4 项费用网格（[IncomeFeeGrid]）+
/// 近期 USDC 收入流水（[RecentUsdcLedgerSection]，最多 5 条 + 查看更多入口）。
/// 数据来自 [usdcIncomeDetailControllerProvider]。
class UsdcIncomeDetailTab extends ConsumerStatefulWidget {
  const UsdcIncomeDetailTab({super.key});

  @override
  ConsumerState<UsdcIncomeDetailTab> createState() =>
      _UsdcIncomeDetailTabState();
}

class _UsdcIncomeDetailTabState extends ConsumerState<UsdcIncomeDetailTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usdcIncomeDetailControllerProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(usdcIncomeDetailControllerProvider);

    return ListView(
      padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
      children: [
        IncomeFeeGrid(stats: state.incomeStats, isLoading: state.isLoading),
        const SizedBox(height: StorySpacing.base),
        RecentUsdcLedgerSection(
          items: state.recentLedger,
          isLoading: state.isLoading,
        ),
      ],
    );
  }
}
