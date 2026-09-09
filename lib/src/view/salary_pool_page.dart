import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../controller/weekly_salary_state.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_radius.dart';
import '../styles/story_spacing.dart';
import '../utils/format_number.dart';
import '../widgets/widgets.dart';

const _backAsset = 'assets/game_v2/mining_rules_back.svg';

/// 片酬与奖池 — 对齐 Figma `637:71739`。
///
/// 数据走 `GET /api/mining/weeklyStats`，与 Agent V2 顶栏共享
/// [weeklySalaryControllerProvider] 的刷新和账号隔离逻辑。
///
/// 布局策略：单一 `ListView` 作为 `RefreshIndicator` 的可滚动根节点，
/// 仅切换 `children` 而不切换根 widget —— 避免 loading/error/data 三态
/// 切换时 sliver 在布局中途被回收导致 `child.hasSize` 断言失败。
class SalaryPoolPage extends ConsumerWidget {
  const SalaryPoolPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = _SalaryPoolColors(Theme.of(context).brightness);
    final isLoggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    return AppScaffold(
      title: '',
      titleWidget: Text(
        l10n.agentMoreSalaryAndPool,
        style: TextStyle(
          color: colors.primaryText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          height: 26 / 18,
          letterSpacing: -0.04,
        ),
      ),
      backgroundColor: colors.page,
      toolbarHeight: 44,
      leadingWidth: 56,
      leading: _BackButton(color: colors.primaryText),
      body: isLoggedIn
          ? _SalaryPoolBody(
              state: ref.watch(weeklySalaryControllerProvider),
              onRefresh: () => ref
                  .read(weeklySalaryControllerProvider.notifier)
                  .forceRefresh(),
            )
          : StoryStateWidget.error(message: l10n.errorUnauthorized),
    );
  }
}

class _SalaryPoolBody extends StatelessWidget {
  final WeeklySalaryState state;
  final Future<void> Function() onRefresh;

  const _SalaryPoolBody({required this.state, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await onRefresh();
      },
      child: ListView(
        key: const ValueKey('salary-pool-list'),
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.screenHorizontal,
          vertical: StorySpacing.base,
        ),
        physics: const AlwaysScrollableScrollPhysics(),
        children: _buildChildren(context, state),
      ),
    );
  }

  List<Widget> _buildChildren(BuildContext context, WeeklySalaryState state) {
    if (state.stats == null && state.isRefreshing) return _loadingChildren;
    final error = state.lastError;
    if (state.stats == null && error != null) {
      return [
        const SizedBox(height: StorySpacing.xxl),
        StoryStateWidget.error(message: context.l10nError(error)),
      ];
    }
    return _dataChildren(state.stats);
  }

  /// 骨架屏：与数据态卡片位置一一对应。
  static List<Widget> get _loadingChildren => const [
    StorySkeletonBox(
      width: double.infinity,
      height: 90,
      borderRadius: BorderRadius.all(Radius.circular(StoryRadius.xxlValue)),
    ),
    SizedBox(height: StorySpacing.md),
    Row(
      children: [
        Expanded(
          child: StorySkeletonBox(
            width: double.infinity,
            height: 64,
            borderRadius: BorderRadius.all(
              Radius.circular(StoryRadius.xxlValue),
            ),
          ),
        ),
        SizedBox(width: StorySpacing.md),
        Expanded(
          child: StorySkeletonBox(
            width: double.infinity,
            height: 64,
            borderRadius: BorderRadius.all(
              Radius.circular(StoryRadius.xxlValue),
            ),
          ),
        ),
      ],
    ),
    SizedBox(height: StorySpacing.md),
    StorySkeletonBox(
      width: double.infinity,
      height: 244,
      borderRadius: BorderRadius.all(Radius.circular(StoryRadius.xxlValue)),
    ),
  ];

  static List<Widget> _dataChildren(MiningWeeklyStats? stats) {
    final totalPool = stats?.weekPool ?? 0;
    final invitePool = stats?.weekInvitePool ?? 0;
    final performancePool = totalPool - invitePool;
    return [
      _TotalPoolCard(total: totalPool),
      const SizedBox(height: StorySpacing.md),
      _PoolPairRow(performancePool: performancePool, invitePool: invitePool),
      const SizedBox(height: StorySpacing.md),
      const _DistributionRulesCard(),
    ];
  }
}

class _SalaryPoolColors {
  final Color page;
  final Color splitCardSurface;
  final Color splitCardBorder;
  final Color rulesSurface;
  final Color primaryText;
  final Color secondaryText;
  final Color tertiaryText;

  _SalaryPoolColors(Brightness brightness)
    : page = brightness == Brightness.dark
          ? StoryColors.darkBackground
          : StoryColors.lightCard,
      splitCardSurface = brightness == Brightness.dark
          ? StoryColors.darkCard
          : StoryColors.lightCard,
      splitCardBorder = brightness == Brightness.dark
          ? const Color(0xFF363A3F)
          : StoryColors.lightSheetSecondary,
      rulesSurface = brightness == Brightness.dark
          ? StoryColors.darkCard
          : StoryColors.lightMuted,
      primaryText = brightness == Brightness.dark
          ? StoryColors.darkForeground
          : StoryColors.lightForeground,
      secondaryText = brightness == Brightness.dark
          ? StoryColors.darkMutedForeground
          : StoryColors.lightMutedForeground,
      tertiaryText = brightness == Brightness.dark
          ? StoryColors.darkTertiaryText
          : const Color(0xFFB0B4BA);
}

class _BackButton extends StatelessWidget {
  final Color color;

  const _BackButton({required this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () => Navigator.maybePop(context),
      padding: const EdgeInsets.all(16),
      icon: SizedBox.square(
        dimension: 24,
        child: Center(
          child: Transform.flip(
            flipX: true,
            child: SvgPicture.asset(
              _backAsset,
              width: 8.5,
              height: 15.5,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _TotalPoolCard extends StatelessWidget {
  final double total;

  const _TotalPoolCard({required this.total});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final colors = _SalaryPoolColors(brightness);
    // Figma `red5%` tinted panel; raise alpha on dark for legibility.
    final bg = StoryColors.brandTealRed.withValues(
      alpha: brightness == Brightness.dark ? 0.10 : 0.05,
    );

    return Container(
      width: double.infinity,
      key: const ValueKey('salary-pool-total-card'),
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              l10n.gameStatHelpWeekTotalPool,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: Text(
              '${formatNumber(total, 0)} STORY',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: StoryColors.brandTealRed,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.md),
          SizedBox(
            width: double.infinity,
            child: Text(
              l10n.salaryPoolDecayInfo,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.secondaryText,
                fontSize: 10,
                fontWeight: FontWeight.w400,
                height: 12 / 10,
                letterSpacing: 0.08,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolPairRow extends StatelessWidget {
  final double performancePool;
  final double invitePool;

  const _PoolPairRow({required this.performancePool, required this.invitePool});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PoolSplitCard(
            cardKey: const ValueKey('salary-pool-performance-card'),
            label: context.l10n.salaryPoolStakeLabel,
            value: performancePool,
          ),
        ),
        const SizedBox(width: StorySpacing.md),
        Expanded(
          child: _PoolSplitCard(
            cardKey: const ValueKey('salary-pool-invite-card'),
            label: context.l10n.salaryPoolInviteLabel,
            value: invitePool,
          ),
        ),
      ],
    );
  }
}

class _PoolSplitCard extends StatelessWidget {
  final Key cardKey;
  final String label;
  final double value;

  const _PoolSplitCard({
    required this.cardKey,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = _SalaryPoolColors(brightness);

    return SizedBox(
      key: cardKey,
      height: 64,
      child: Container(
        padding: const EdgeInsets.symmetric(
          // Flutter lays borders inside the content constraints. Subtract the
          // 0.5 px stroke so the visual insets stay at Figma's 16 / 12 px.
          horizontal: StorySpacing.base - 0.5,
          vertical: StorySpacing.md - 0.5,
        ),
        decoration: BoxDecoration(
          color: colors.splitCardSurface,
          border: Border.all(color: colors.splitCardBorder, width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Opacity(
              opacity: 0.9,
              child: SizedBox(
                height: 16,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 24,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: formatNumber(value, 0),
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 24 / 16,
                        ),
                      ),
                      const TextSpan(text: ' '),
                      TextSpan(
                        text: 'STORY',
                        style: TextStyle(
                          color: colors.tertiaryText,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 16 / 12,
                          letterSpacing: 0.04,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  softWrap: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DistributionRulesCard extends StatelessWidget {
  const _DistributionRulesCard();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final colors = _SalaryPoolColors(brightness);
    final titleColon = Localizations.localeOf(context).languageCode == 'zh'
        ? '：'
        : ':';

    return Container(
      key: const ValueKey('salary-pool-rules-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.md),
      decoration: BoxDecoration(
        color: colors.rulesSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.miningRulesSettleColRule,
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 20 / 14,
            ),
          ),
          const SizedBox(height: StorySpacing.lg),
          _RuleLine(
            title: l10n.salaryPoolRule1Title,
            body: l10n.gameStatHelpUserActualEqNominal,
          ),
          const SizedBox(height: StorySpacing.lg),
          _RuleLine(
            title: l10n.salaryPoolRule2Title,
            body: l10n.salaryPoolRule2Body,
          ),
          const SizedBox(height: StorySpacing.lg),
          _RuleLine(
            title: '${l10n.gameStatHelpAddressCap}$titleColon',
            body: l10n.gameStatHelpAddressCapValue,
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  final String title;
  final String body;

  const _RuleLine({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final colors = _SalaryPoolColors(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.primaryText,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
          ),
        ),
        Text(
          body,
          style: TextStyle(
            color: colors.tertiaryText,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 20 / 14,
          ),
        ),
      ],
    );
  }
}
