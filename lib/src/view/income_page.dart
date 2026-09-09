import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../components/components.dart';
import '../l10n/app_localizations.dart';
import '../l10n/story_l10n.dart';
import '../model/models.dart';
import '../provider/app_providers.dart';
import '../styles/story_colors.dart';
import '../styles/story_spacing.dart';
import '../styles/story_text_styles.dart';
import '../utils/format_number.dart';
import '../widgets/widgets.dart';
import 'widgets/income/income_earnings_help_dialog.dart';

/// 与 web `IncomeQuickBalanceCard` 对齐：累计收益（USDC/STORY） + 可领取资产。
class IncomePage extends ConsumerWidget {
  const IncomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(
      authControllerProvider.select((s) => s.isLoggedIn),
    );
    final l10n = context.l10n;

    if (!isLoggedIn) {
      return AppScaffold(
        title: l10n.profileEarnings,
        body: StoryStateWidget.error(message: l10n.errorUnauthorized),
      );
    }

    return const _IncomePageBody();
  }
}

class _IncomePageBody extends ConsumerStatefulWidget {
  const _IncomePageBody();

  @override
  ConsumerState<_IncomePageBody> createState() => _IncomePageBodyState();
}

class _IncomePageBodyState extends ConsumerState<_IncomePageBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  ListRewardDetailsFilter _storyFilter = ListRewardDetailsFilter.all;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incomeControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    ref.invalidate(incomeControllerProvider);
    await ref.read(incomeControllerProvider.notifier).refresh();
  }

  Future<void> _onStoryFilterChanged(ListRewardDetailsFilter filter) async {
    setState(() => _storyFilter = filter);
    await ref
        .read(incomeControllerProvider.notifier)
        .refreshRewardDetails(type: filter);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return AppScaffold(
      title: l10n.profileEarnings,
      // Figma 970:115329 / 970:114321 — page&sheet/thirdly #F6F6F6 / dark #111113
      backgroundColor: theme.brightness == Brightness.dark
          ? StoryColors.darkBackground
          : StoryColors.lightMuted,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(child: _buildSummaryCards(l10n, theme)),
              SliverPersistentHeader(
                pinned: true,
                delegate: StorySliverHeaderDelegate(
                  child: Container(
                    color: theme.brightness == Brightness.dark
                        ? StoryColors.darkBackground
                        : StoryColors.lightMuted,
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                      horizontal: StorySpacing.screenHorizontal,
                    ),
                    child: StoryTabBar(
                      controller: _tabCtrl,
                      isScrollable: true,
                      showDivider: false,
                      labelPadding: const EdgeInsets.only(right: 20),
                      indicator: StoryTabIndicator(
                        color: StoryColors.foregroundOf(theme.brightness),
                        width: 16,
                        borderRadius: 17,
                      ),
                      unselectedLabelColor: StoryColors.mutedForegroundOf(
                        theme.brightness,
                      ),
                      tabs: [
                        const Tab(text: 'STORY'),
                        Tab(text: l10n.currency),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabCtrl,
            children: [_buildStoryTab(), _buildUsdcTab()],
          ),
        ),
      ),
    );
  }

  /// Summary header: cumulative / settling / claimable balances.
  /// Only watches [incomeControllerProvider] fields that affect the header.
  Widget _buildSummaryCards(AppLocalizations l10n, ThemeData theme) {
    final cardBg = StoryColors.cardOf(theme.brightness);

    return Consumer(
      builder: (context, ref, _) {
        final totalStory = ref.watch(
          incomeControllerProvider.select((s) => s.totalStoryEarnings),
        );
        final totalUsdc = ref.watch(
          incomeControllerProvider.select((s) => s.totalUsdcEarnings),
        );
        final settlingStory = ref.watch(
          incomeControllerProvider.select((s) => s.settlingStoryEarnings),
        );
        final claimableStory = ref.watch(
          incomeControllerProvider.select((s) => s.storyBalance),
        );
        final claimableUsdc = ref.watch(
          incomeControllerProvider.select((s) => s.usdcBalance),
        );

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.base,
            StorySpacing.screenHorizontal,
            StorySpacing.sm,
          ),
          child: Column(
            children: [
              _buildCumulativeCard(
                l10n: l10n,
                cardBg: cardBg,
                cumulativeStory: totalStory,
                cumulativeUsdc: totalUsdc,
              ),
              const SizedBox(height: StorySpacing.md),
              _buildSettlingCard(
                l10n: l10n,
                cardBg: cardBg,
                settlingStory: settlingStory,
              ),
              const SizedBox(height: StorySpacing.md),
              _buildClaimSection(
                context: context,
                l10n: l10n,
                cardBg: cardBg,
                claimableStory: claimableStory,
                claimableUsdc: claimableUsdc,
              ),
            ],
          ),
        );
      },
    );
  }

  /// STORY tab with filter chips and records list.
  /// Watches [storyRecords] and uses local [_storyFilter] for client-side filtering.
  Widget _buildStoryTab() {
    return Consumer(
      builder: (context, ref, _) {
        final storyTabState = ref.watch(
          incomeControllerProvider.select(
            (s) => (
              isLoading: s.isLoading,
              isPageLoading: s.isStoryPageLoading,
              records: s.storyRecords,
            ),
          ),
        );
        final records = storyTabState.records;
        final l10n = context.l10n;
        // 缓存过滤结果，避免每次 Consumer 重建时重复分配
        final filtered = records
            .where((r) => _matchesStoryFilter(r.type))
            .toList(growable: false);

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent -
                        StorySpacing.scrollThreshold) {
              ref
                  .read(incomeControllerProvider.notifier)
                  .loadMoreRewardDetails(type: _storyFilter);
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
            itemCount: storyTabState.isLoading ? 6 : filtered.length + 2,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: StorySpacing.sm),
                  child: Row(
                    children: [
                      _buildSubTabChip(
                        label: l10n.incomeFilterAll,
                        isActive: _storyFilter == ListRewardDetailsFilter.all,
                        onTap: () =>
                            _onStoryFilterChanged(ListRewardDetailsFilter.all),
                      ),
                      const SizedBox(width: StorySpacing.sm),
                      _buildSubTabChip(
                        label: l10n.incomeFilterMining,
                        isActive:
                            _storyFilter == ListRewardDetailsFilter.mining,
                        onTap: () => _onStoryFilterChanged(
                          ListRewardDetailsFilter.mining,
                        ),
                      ),
                      const SizedBox(width: StorySpacing.sm),
                      _buildSubTabChip(
                        label: l10n.incomeFilterInvite,
                        isActive:
                            _storyFilter == ListRewardDetailsFilter.invite,
                        onTap: () => _onStoryFilterChanged(
                          ListRewardDetailsFilter.invite,
                        ),
                      ),
                    ],
                  ),
                );
              }

              if (storyTabState.isLoading) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: StorySpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StorySkeletonBox(width: 88, height: 16),
                          StorySkeletonBox(width: 136, height: 16),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StorySkeletonBox(width: 128, height: 10),
                          StorySkeletonBox(width: 88, height: 10),
                        ],
                      ),
                    ],
                  ),
                );
              }

              if (index == filtered.length + 1) {
                if (!storyTabState.isPageLoading) {
                  return const SizedBox.shrink();
                }
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: StorySpacing.lg),
                  child: Center(child: StoryLoading.inline()),
                );
              }

              final record = filtered[index - 1];
              return _buildStoryRecordTile(record);
            },
          ),
        );
      },
    );
  }

  /// USDC tab — only watches [usdcRecords].
  Widget _buildUsdcTab() {
    return Consumer(
      builder: (context, ref, _) {
        final usdcTabState = ref.watch(
          incomeControllerProvider.select(
            (s) => (records: s.usdcRecords, isPageLoading: s.isUsdcPageLoading),
          ),
        );
        final records = usdcTabState.records;

        if (records.isEmpty) {
          return Center(
            child: StoryEmptyCard(label: context.l10n.incomeNoRecords),
          );
        }

        return NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollEndNotification &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent -
                        StorySpacing.scrollThreshold) {
              ref.read(incomeControllerProvider.notifier).loadMoreUsdcIncome();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(StorySpacing.screenHorizontal),
            itemCount: records.length + (usdcTabState.isPageLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == records.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: StorySpacing.lg),
                  child: Center(child: StoryLoading.inline()),
                );
              }

              final record = records[index];
              return _buildUsdcRecordTile(record);
            },
          ),
        );
      },
    );
  }

  Widget _buildCumulativeCard({
    required AppLocalizations l10n,
    required Color cardBg,
    required double cumulativeStory,
    required double cumulativeUsdc,
  }) {
    return Container(
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryColumn(
              label: l10n.incomeCumulativeStory,
              value: formatNumber(cumulativeStory),
              helpType: IncomeEarningsHelpType.totalStory,
            ),
          ),
          const SizedBox(width: StorySpacing.base),
          Expanded(
            child: _SummaryColumn(
              label: l10n.incomeCumulativeUsdc(l10n.currency),
              value: formatNumber(cumulativeUsdc),
              helpType: IncomeEarningsHelpType.totalUsdc,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlingCard({
    required AppLocalizations l10n,
    required Color cardBg,
    required double settlingStory,
  }) {
    final theme = Theme.of(context);
    final showSettlingHint = settlingStory > 0;
    final labelStyle = _incomeLabelStyle(theme.brightness);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                IncomeEarningsHelpLabel(
                  label: l10n.incomeSettlingStory,
                  helpType: IncomeEarningsHelpType.settlingStory,
                  labelStyle: labelStyle,
                ),
                if (showSettlingHint) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.incomeSettlingHint,
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                      color: StoryColors.tertiaryTextOf(theme.brightness),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatNumber(settlingStory),
                style: _incomeValueStyle(theme.brightness),
              ),
              const SizedBox(width: 4),
              SvgPicture.asset(
                StoryPerHourUnitLabel.assetPath,
                width: 16,
                height: 16,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClaimSection({
    required BuildContext context,
    required AppLocalizations l10n,
    required Color cardBg,
    required double claimableStory,
    required double claimableUsdc,
  }) {
    return Column(
      children: [
        _ClaimRow(
          label: l10n.incomeClaimableStory,
          helpType: IncomeEarningsHelpType.claimableStory,
          displayAmount: formatNumber(claimableStory),
          claimableAmount: claimableStory,
          currency: 'STORY',
          cardBg: cardBg,
          onClaim: () => _handleClaim(
            context: context,
            assetCode: 'STORY',
            amount: claimableStory,
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        _ClaimRow(
          label: l10n.incomeClaimableUsdc(l10n.currency),

          helpType: IncomeEarningsHelpType.claimableUsdc,
          displayAmount: formatNumber(claimableUsdc),
          claimableAmount: claimableUsdc,
          currency: l10n.currency,
          cardBg: cardBg,
          onClaim: () => _handleClaim(
            context: context,
            assetCode: 'USDC',
            amount: claimableUsdc,
          ),
        ),
      ],
    );
  }

  bool _matchesStoryFilter(RewardDetailType? type) {
    switch (_storyFilter) {
      case ListRewardDetailsFilter.all:
        return true;
      case ListRewardDetailsFilter.mining:
        return type == RewardDetailType.mining;
      case ListRewardDetailsFilter.invite:
        return type == RewardDetailType.invite;
    }
  }

  Widget _buildSubTabChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    // Figma 二级导航 pill：选中 dark/white 反色；未选中 secondary 面。
    final chipBg = isActive
        ? StoryColors.actorSignSheetConfirmBgOf(brightness)
        : (brightness == Brightness.dark
              ? StoryColors.darkMuted
              : StoryColors.lightSheetSecondary);
    final chipTextColor = isActive
        ? StoryColors.actorSignSheetConfirmFgOf(brightness)
        : StoryColors.foregroundOf(brightness);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: const BorderRadius.all(Radius.circular(80)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              height: 20 / 14,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: chipTextColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStoryRecordTile(RewardDetail record) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final brightness = theme.brightness;

    final typeLabel = record.type == RewardDetailType.invite
        ? l10n.incomeInviteReward
        : l10n.incomeMiningReward;
    final amountText = '${formatNumber(record.storyAmount)} STORY';
    final timeText = _formatTime(record.rewardTime);
    final sourceText = _buildStorySource(record);

    return _IncomeRecordTile(
      title: typeLabel,
      amount: amountText,
      timeText: timeText,
      sourceText: sourceText,
      brightness: brightness,
    );
  }

  Widget _buildUsdcRecordTile(UsdcIncomeItem record) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    final typeLabel = _usdcTypeLabel(record.type);
    final amountText =
        '${formatNumber(record.amount)} ${context.l10n.currency}';
    final timeText = _formatTime(record.createdAt);

    return _IncomeRecordTile(
      title: typeLabel,
      amount: amountText,
      timeText: timeText,
      sourceWidget: _buildUsdcSource(
        record,
        StoryColors.tertiaryTextOf(brightness),
      ),
      brightness: brightness,
    );
  }

  String _usdcTypeLabel(String? type) {
    if (type == null) return context.l10n.incomeUsdcActorSignShare;
    switch (type) {
      case 'ACTOR_SIGN_SHARE':
        return context.l10n.incomeUsdcActorSignShare;
      case 'INVITE':
        return context.l10n.incomeInviteReward;
      default:
        return type;
    }
  }

  String _buildStorySource(RewardDetail record) {
    final period = _formatPeriod(
      record.rewardPeriodStart,
      record.rewardPeriodEnd,
    );
    if (record.type == RewardDetailType.invite) {
      final name = record.sourceUserName?.trim();
      if (period.isNotEmpty && name != null && name.isNotEmpty) {
        return '$period | $name';
      }
      if (name != null && name.isNotEmpty) return name;
      return period;
    }
    return period;
  }

  /// 签约分成显示演员名称和编号；邀请收益仅显示邀请人名称。
  ///
  /// 记录时间由 [_buildUsdcRecordTile] 在来源左侧统一展示。
  Widget _buildUsdcSource(UsdcIncomeItem record, Color muted) {
    final name = record.actorName?.trim();
    final tokenId = record.tokenId?.trim();
    final caption = TextStyle(
      fontSize: 10,
      height: 12 / 10,
      letterSpacing: 0.08,
      color: muted,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: name ?? '',
            style: caption.copyWith(fontWeight: FontWeight.w500),
          ),
          if (tokenId != null && tokenId.isNotEmpty) ...[
            TextSpan(text: ' #$tokenId', style: caption),
          ],
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.right,
    );
  }

  String _formatPeriod(String? start, String? end) {
    final s = _formatPeriodDate(start);
    final e = _formatPeriodDate(end);
    if (s.isNotEmpty && e.isNotEmpty) return '$s ~ $e';
    if (s.isNotEmpty) return s;
    return e;
  }

  String _formatPeriodDate(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    final dt = DateTime.tryParse(trimmed);
    if (dt != null) {
      return '${dt.year}-${_two(dt.month)}-${_two(dt.day)}';
    }
    final ms = int.tryParse(trimmed);
    if (ms != null) {
      final fromMs = DateTime.fromMillisecondsSinceEpoch(ms);
      return '${fromMs.year}-${_two(fromMs.month)}-${_two(fromMs.day)}';
    }
    return trimmed;
  }

  String _formatTime(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '';
    int ts;
    if (RegExp(r'^\d+$').hasMatch(trimmed)) {
      ts = int.tryParse(trimmed) ?? 0;
    } else {
      ts = DateTime.tryParse(trimmed)?.millisecondsSinceEpoch ?? 0;
    }
    if (ts == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      ts < 10000000000 ? ts * 1000 : ts,
    );
    return '${dt.year}/${_two(dt.month)}/${_two(dt.day)} '
        '${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int v) => v.toString().padLeft(2, '0');

  void _handleClaim({
    required BuildContext context,
    required String assetCode,
    required double amount,
  }) {
    final l10n = context.l10n;
    final auth = ref.read(authControllerProvider);
    if (auth.solanaAddress.isEmpty) {
      StoryToast.error(context, l10n.incomeClaimNoWallet);
      return;
    }

    final brightness = Theme.of(context).brightness;
    StoryDialog.confirm(
      context: context,
      title: l10n.incomeClaimTitle,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.incomeClaimAction,
            textAlign: TextAlign.center,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
          const SizedBox(height: StorySpacing.sm),
          Text(
            '${formatNumber(amount)} $assetCode',
            textAlign: TextAlign.center,
            style: StoryTextStyles.headingLarge(
              color: StoryColors.brandTeal,
            ).copyWith(fontWeight: FontWeight.w700, fontSize: 28, height: 1.2),
          ),
        ],
      ),
      confirmLabel: l10n.incomeConfirmClaim,
      onConfirm: () async {
        final result = await ref
            .read(rewardRepositoryProvider)
            .claim(
              assetCode: assetCode,
              amount: amount,
              toAddress: auth.solanaAddress,
            );

        if (context.mounted) {
          if (result.isSuccess) {
            StoryToast.success(context, l10n.incomeClaimWithdrawSubmitted);
            _handleRefresh();
            // Claimed earnings will arrive in on-chain wallet
            ref.read(onChainWalletBalanceProvider.notifier).refresh();

            // Poll order status if orderNo is available
            final orderNo = result.dataOrNull?.orderNo;
            if (orderNo != null && orderNo.isNotEmpty) {
              _pollOrderStatus(orderNo);
            }
          } else {
            StoryToast.error(
              context,
              result.errorOrNull?.userMessage ?? l10n.incomeClaimWithdrawFailed,
            );
          }
        }
      },
    );
  }

  /// Poll order status every 3 seconds, max 20 attempts (60 seconds total).
  Future<void> _pollOrderStatus(String orderNo) async {
    const maxAttempts = 20;
    const interval = Duration(seconds: 3);

    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(interval);
      if (!mounted) return;

      final result = await ref
          .read(rewardRepositoryProvider)
          .getWithdrawOrder(orderNo);

      if (result.isSuccess) {
        final detail = result.dataOrNull;
        final status = detail?.status;

        if (status == '2') {
          // Order confirmed — refresh balance to show new on-chain funds
          ref.read(onChainWalletBalanceProvider.notifier).refresh();
          if (mounted) {
            StoryToast.success(context, context.l10n.withdrawOrderSuccess);
          }
          return;
        } else if (status == '3') {
          // Order failed — reconcile balance
          ref.read(onChainWalletBalanceProvider.notifier).refresh();
          if (mounted) {
            StoryToast.error(context, context.l10n.withdrawOrderFailed);
          }
          return;
        }
      }
    }
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String value;
  final IncomeEarningsHelpType helpType;

  const _SummaryColumn({
    required this.label,
    required this.value,
    required this.helpType,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IncomeEarningsHelpLabel(
          label: label,
          helpType: helpType,
          labelStyle: _incomeLabelStyle(brightness),
        ),
        const SizedBox(height: 6),
        Text(value, style: _incomeValueStyle(brightness)),
      ],
    );
  }
}

class _ClaimRow extends StatelessWidget {
  final String label;
  final IncomeEarningsHelpType helpType;
  final String displayAmount;
  final double claimableAmount;
  final String currency;
  final Color cardBg;
  final VoidCallback onClaim;

  const _ClaimRow({
    required this.label,
    required this.helpType,
    required this.displayAmount,
    required this.claimableAmount,
    required this.currency,
    required this.cardBg,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final hasAmount = claimableAmount > 0;
    // Figma：可领 = primary/15% red + #E50815；不可领 = unavailable #C3C5CE + 白字
    final claimBg = hasAmount
        ? const Color(0x26E50815)
        : StoryColors.buttonDisabledForeground;
    final claimFg = hasAmount ? StoryColors.brandTealRed : Colors.white;

    return Container(
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IncomeEarningsHelpLabel(
                  label: label,
                  helpType: helpType,
                  labelStyle: _incomeLabelStyle(brightness),
                ),
                const SizedBox(height: 6),
                Text(displayAmount, style: _incomeValueStyle(brightness)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: hasAmount ? onClaim : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: claimBg,
                borderRadius: const BorderRadius.all(Radius.circular(80)),
              ),
              child: Text(
                l10n.incomeClaimAction,
                style: TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w700,
                  color: claimFg,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Figma 列表行：标题/金额 14 Medium，次要信息 10 Regular tertiary，金额青绿 #01BAB2。
class _IncomeRecordTile extends StatelessWidget {
  final String title;
  final String amount;
  final String timeText;
  final String? sourceText;
  final Widget? sourceWidget;
  final Brightness brightness;

  const _IncomeRecordTile({
    required this.title,
    required this.amount,
    required this.timeText,
    required this.brightness,
    this.sourceText,
    this.sourceWidget,
  });

  @override
  Widget build(BuildContext context) {
    final tertiary = StoryColors.tertiaryTextOf(brightness);
    final metaStyle = TextStyle(
      fontSize: 10,
      height: 12 / 10,
      letterSpacing: 0.08,
      color: tertiary,
    );

    return SizedBox(
      width: double.infinity,
      height: 60,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: StoryColors.foregroundOf(brightness),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(timeText, style: metaStyle),
                    ],
                  ),
                ),
                const SizedBox(width: StorySpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        amount,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 20 / 14,
                          fontWeight: FontWeight.w500,
                          color: StoryColors.createDramaEpisodeAccent,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (sourceWidget != null)
                        sourceWidget!
                      else if (sourceText != null && sourceText!.isNotEmpty)
                        Text(
                          sourceText!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: metaStyle,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 0.5,
            thickness: 0.5,
            color: StoryColors.borderOf(brightness),
          ),
        ],
      ),
    );
  }
}

TextStyle _incomeLabelStyle(Brightness brightness) => TextStyle(
  fontSize: 13,
  height: 18 / 13,
  fontWeight: FontWeight.w400,
  color: StoryColors.mutedForegroundOf(brightness),
);

TextStyle _incomeValueStyle(Brightness brightness) => TextStyle(
  fontSize: 16,
  height: 24 / 16,
  fontWeight: FontWeight.w700,
  color: StoryColors.foregroundOf(brightness),
);
