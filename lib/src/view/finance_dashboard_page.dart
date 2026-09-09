import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../foundation/locale_controller.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../widgets/widgets.dart';
import 'widgets/finance_dashboard/finance_summary_cards.dart';
import 'widgets/finance_dashboard/story_release_overview_tab.dart';
import 'widgets/finance_dashboard/usdc_income_detail_tab.dart';
import 'widgets/finance_dashboard/vault_funds_tab.dart';

/// 平台资金看板（Figma node 6312:95387）。
///
/// 结构：NestedScrollView 承载顶部汇总卡片（USDC 总收入 / STORY 总释放，来自
/// [financeDashboardControllerProvider]）+ 吸顶 TabBar + TabBarView。三个
/// TabView 子页面各自拥有独立 Controller，当前均为占位实现。
class FinanceDashboardPage extends ConsumerStatefulWidget {
  const FinanceDashboardPage({super.key});

  @override
  ConsumerState<FinanceDashboardPage> createState() =>
      _FinanceDashboardPageState();
}

class _FinanceDashboardPageState extends ConsumerState<FinanceDashboardPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(financeDashboardControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final surface = StoryColors.storyBgOf(theme.brightness);
    final appBarBackground = StoryColors.appBarBackgroundOf(theme.brightness);
    return AppScaffold(
      title: l10n.financeDashboardPageTitle,
      backgroundColor: appBarBackground,
      body: ColoredBox(
        color: surface,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    StorySpacing.screenHorizontal,
                    StorySpacing.base,
                    StorySpacing.screenHorizontal,
                    0,
                  ),
                  child: FinanceSummaryCards(),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: StorySliverHeaderDelegate(
                  child: Container(
                    color: surface,
                    alignment: Alignment.centerLeft,
                    child: StoryTabBar(
                      controller: _tabController,
                      isScrollable: true,
                      indicator: StoryTabIndicator(
                        color: StoryColors.foregroundOf(theme.brightness),
                        width: 32,
                        height: 2,
                        borderRadius: 0,
                      ),
                      tabs: [
                        Tab(text: l10n.financeDashboardTabUsdcIncome(l10n.currency)),
                        Tab(text: l10n.financeDashboardTabVaultFunds),
                        Tab(text: l10n.financeDashboardTabStoryRelease),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: const [
              UsdcIncomeDetailTab(),
              VaultFundsTab(),
              StoryReleaseOverviewTab(),
            ],
          ),
        ),
      ),
    );
  }
}
