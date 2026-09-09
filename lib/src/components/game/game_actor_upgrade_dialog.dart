import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/format_number.dart';
import '../../utils/wallet_balance_gate.dart';
import '../../services/wallet_ledger.dart';
import '../common/story_bottom_sheet.dart';
import '../common/story_toast.dart';
import 'actor_upgrade_success_dialog.dart';

/// 显示演员升级对话框，复用 [StoryBottomSheet.showStyledSheet] 作为外层壳。
Future<void> showGameActorUpgradeDialog(
  BuildContext context,
  WidgetRef ref,
  MiningActor actor,
) async {
  await StoryBottomSheet.showStyledSheet<void>(
    context: context,
    title: actor.displayName.isNotEmpty ? actor.displayName : '-',
    subtitle: actor.actorCode,
    showCloseButton: false,
    isScrollControlled: true,
    content: _UpgradeContent(actor: actor),
  );
}

class _UpgradeContent extends ConsumerStatefulWidget {
  final MiningActor actor;
  const _UpgradeContent({required this.actor});

  @override
  ConsumerState<_UpgradeContent> createState() => _UpgradeContentState();
}

class _UpgradeContentState extends ConsumerState<_UpgradeContent> {
  List<ActorUpgradeMaterial> _materials = [];
  ActorCollection? _actorCollection;
  bool _isLoading = true;
  String? _error;
  final Set<int> _selectedTokenIds = {};

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    final notifier = ref.read(gameControllerProvider.notifier);
    final actorCollectionId = widget.actor.actorCollectionId;

    // 并行：耗材列表 + 合集详情（走网络，与 web
    // `useActorCompletePlayRequirementSatisfied` 中 refetchOnMount 口径一致）
    final materialsFuture = notifier.getUpgradeMaterials(widget.actor.nftId);
    final collectionFuture = actorCollectionId == null
        ? Future<ActorCollection?>.value()
        : ref
              .read(actorRepositoryProvider)
              .getActorCollectionDetailFromNetwork('$actorCollectionId')
              .then((r) => r.dataOrNull);

    final results = await Future.wait<Object?>([
      materialsFuture,
      collectionFuture,
    ]);
    if (!mounted) return;

    final materials = results[0] as List<ActorUpgradeMaterial>;
    final collection = results[1] as ActorCollection?;

    setState(() {
      _materials = materials;
      _actorCollection = collection;
      _isLoading = false;
    });
  }

  /// 解析当前等级名称（群演/配角/主角/...），与 web `formatGameActorLevelName`
  /// 对齐：l10n 静态表 > 全局配置 `actorNft.levels.name` 兜底。
  ///
  /// 当 [level] 为 null（演员尚无等级数据）时返回 null —— 没有等级就无法推断
  /// 咖位名，卡片仅展示 `Lv$level` 部分而不伪造名称。l10n 表覆盖了所有已知等级
  /// (1~5)，因此兜底 `Lv$level` 不会命中；若服务端下发未知等级，返回 null 以避免
  /// 与卡片左侧的 `Lv$level` 重复。
  String? _resolveLevelName(int? level) {
    if (level == null) return null;
    final l10n = context.l10n;
    switch (level) {
      case 1:
        return l10n.gameActorLevelName1;
      case 2:
        return l10n.gameActorLevelName2;
      case 3:
        return l10n.gameActorLevelName3;
      case 4:
        return l10n.gameActorLevelName4;
      case 5:
        return l10n.gameActorLevelName5;
    }
    // 用 ref.watch 订阅全局配置：配置加载完成后弹窗自动 rebuild，避免 nextLevel
    // 因配置未就绪而为空（与 web 响应式 useConfigStore 行为一致）。
    final config = ref.watch(globalConfigProvider);
    final configName = config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels?['$level']?.name,
        failure: (_) => null,
      ),
    );
    return configName;
  }

  String? _targetLevelName(int? toLevel) {
    return _resolveLevelName(toLevel);
  }

  double? _targetMiningCoefficient(int? toLevel) {
    if (toLevel == null) return null;
    final config = ref.watch(globalConfigProvider);
    return config.whenOrNull(
      data: (result) => result.when(
        success: (config) =>
            config.init?.actorNft?.levels?['$toLevel']?.miningCoefficient,
        failure: (_) => null,
      ),
    );
  }

  /// 解析当前等级对应的下一级升级规则，与 web `getGameActorUpgradeConfig` 对齐：
  /// `init.actorNft.levels[level].upgrade`。
  InitActorNftUpgradeConfig? _resolveUpgradeConfig() {
    final level = widget.actor.level;
    if (level == null) return null;
    final config = ref.watch(globalConfigProvider);
    return config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels?['$level']?.upgrade,
        failure: (_) => null,
      ),
    );
  }

  /// 是否已达顶级咖位，与 web `isGameActorMaxLevel` 对齐：
  /// `actor.level >= init.actorNft.levels` 的最大 key。
  bool _isMaxLevel() {
    final level = widget.actor.level;
    if (level == null) return false;
    final config = ref.watch(globalConfigProvider);
    final levels = config.whenOrNull(
      data: (result) => result.when(
        success: (c) => c.init?.actorNft?.levels,
        failure: (_) => null,
      ),
    );
    if (levels == null || levels.isEmpty) return false;
    final maxLevel = levels.keys
        .map(int.tryParse)
        .whereType<int>()
        .fold<int>(0, (a, b) => a > b ? a : b);
    return level >= maxLevel;
  }

  Future<void> _handleConfirm() async {
    final l10n = context.l10n;
    final gameState = ref.read(gameControllerProvider);
    final notifier = ref.read(gameControllerProvider.notifier);

    if (gameState.isActionLoading || _materials.isEmpty) return;

    final requirement = _materials.first.upgradeRequirement;
    if (requirement == null) return;

    final requiredCount = requirement.requiredMaterialCount ?? 3;
    if (_selectedTokenIds.length != requiredCount) {
      StoryToast.error(context, l10n.gameUpgradeSelectMaterials(requiredCount));
      return;
    }

    final upgradeConfig = _resolveUpgradeConfig();
    final fee = requirement.fee ?? upgradeConfig?.fee ?? 0;
    SpendTicket? spendTicket;
    if (fee > 0) {
      // Soft-check first so insufficient balance pops the recharge dialog
      // instead of only showing a toast after the optimistic deduction.
      final okBalance = await ensureUsdcBalanceOrShowDialog(ref, context, fee);
      if (!okBalance || !mounted) return;
      spendTicket = await prepareUsdcSpend(
        ref,
        context,
        fee,
        reason: 'actor_upgrade',
      );
      if (spendTicket == null) return;
    }
    final ledger = ref.read(walletLedgerProvider);

    final mainNftTokenId = widget.actor.actorTokenId;
    final actorCollectionId = widget.actor.actorCollectionId;
    final actorNftId = widget.actor.nftId;
    if (mainNftTokenId == null ||
        actorCollectionId == null ||
        actorNftId.isEmpty) {
      if (spendTicket != null && spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
      return;
    }

    final toLevel = requirement.toLevel;
    // 在异步升级请求前解析目标等级名称，避免 await 后 widget 被销毁时
    // 访问 ref 失败；名称缺失时回退到 toast 提示。
    final targetLevelName = toLevel == null ? null : _targetLevelName(toLevel);

    final ok = await notifier.upgradeActor(
      actorCollectionId: actorCollectionId,
      mainNftTokenId: mainNftTokenId,
      burnNftTokenIds: _selectedTokenIds.toList(),
      actorNftId: actorNftId,
      toLevel: toLevel,
    );

    if (!mounted) {
      if (spendTicket != null && spendTicket.didDeduct) {
        await ledger.reconcile(spendTicket);
      }
      return;
    }

    if (ok) {
      // 先关闭升级底部弹层，再弹出成功对话框，保证成功提示不被底部弹层遮挡。
      Navigator.of(context).pop();
      if (toLevel != null && targetLevelName != null) {
        await showActorUpgradeSuccessDialog(
          context,
          actorName: widget.actor.displayName,
          nextLevel: toLevel,
          levelName: targetLevelName,
          actorCode: widget.actor.actorCode,
        );
      } else {
        StoryToast.success(context, l10n.gameUpgradeSuccess);
      }
      // 关闭成功弹窗后强制刷新我的演员列表，确保页面展示升级后的最新数据
      // （`upgradeActor` 内部已轮询索引器并 refresh，此处二次刷新对齐
      // replenishStamina 的行为，覆盖弹窗停留期间可能发生的链上状态变化）。
      if (context.mounted) {
        ref.read(gameControllerProvider.notifier).refresh(force: true);
        if (spendTicket != null && spendTicket.didDeduct) {
          await ledger.commitSpend(spendTicket);
        }
      }
      return;
    }

    if (spendTicket != null && spendTicket.didDeduct) {
      await ledger.reconcile(spendTicket);
    }
    if (!mounted) return;

    final err = ref.read(gameControllerProvider).lastError;
    StoryToast.error(
      context,
      err == null ? l10n.gameUpgradeFailed : context.l10nError(err),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final isActionLoading = ref.watch(
      gameControllerProvider.select((s) => s.isActionLoading),
    );

    final actor = widget.actor;
    final mainMaterial = _materials.isNotEmpty ? _materials.first : null;
    final requirement = mainMaterial?.upgradeRequirement;
    // 升级规则优先取耗材接口返回，缺省回退全局配置 `levels[level].upgrade`
    // （与 web `getGameActorUpgradeConfig` 口径一致）
    final upgradeConfig = _resolveUpgradeConfig();
    final isMaxLevel = _isMaxLevel();
    final hasNextLevelUpgrade = !isMaxLevel;
    final nextLevel = requirement?.toLevel ?? upgradeConfig?.toLevel;
    final requiredCount =
        requirement?.requiredMaterialCount ??
        upgradeConfig?.requiredMaterialCount ??
        2;
    final fee = requirement?.fee ?? upgradeConfig?.fee;
    final heatThreshold = upgradeConfig?.heatThreshold;
    final targetLevelName = _targetLevelName(nextLevel);
    final targetMiningCoefficient = _targetMiningCoefficient(nextLevel);
    final currentLevelName = _resolveLevelName(actor.level);
    final completedViewCount = _actorCollection?.completedViewCountInt;
    // 体力上限来自全局配置（与 web `getGameActorStaminaLimit` 一致），与耗材解耦。
    final staminaLimit = ref.watch(
      gameControllerProvider.select((s) => s.staminaLimit),
    );
    final canConfirm =
        !isActionLoading &&
        _selectedTokenIds.length == requiredCount &&
        actor.completePlayThresholdMet == true &&
        hasNextLevelUpgrade;

    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            _error!,
            style: StoryTextStyles.bodyMedium(color: StoryColors.destructive),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        minHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CurrentLevelCard(
                    actor: actor,
                    levelName: currentLevelName,
                    staminaLimit: staminaLimit,
                  ),
                  const SizedBox(height: StorySpacing.lg),
                  _UpgradeComparison(
                    currentLevel: actor.level,
                    currentLevelName: currentLevelName,
                    currentMiningCoefficient: actor.miningCoefficient,
                    nextLevel: nextLevel,
                    nextLevelName: targetLevelName,
                    nextMiningCoefficient: targetMiningCoefficient,
                  ),
                  const SizedBox(height: StorySpacing.lg),
                  _RequirementsCard(
                    actor: actor,
                    requiredCount: requiredCount,
                    fee: fee,
                    selectedCount: _selectedTokenIds.length,
                    completedViewCount: completedViewCount,
                    heatThreshold: heatThreshold,
                  ),
                  const SizedBox(height: StorySpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.gameUpgradeSelectMaterialDesc,
                          style: StoryTextStyles.bodyMedium(
                            color: StoryColors.foregroundOf(brightness),
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: StorySpacing.md),
                      Text(
                        l10n.gameUpgradeMaterialCount(
                          _selectedTokenIds.length,
                          requiredCount,
                        ),
                        style: StoryTextStyles.bodySmall(
                          color: StoryColors.brandTealDark,
                        ).copyWith(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.sm + 2),
                  if (_materials.isNotEmpty)
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_materials.length, (index) {
                        final material = _materials[index];
                        final materialTokenId = material.tokenId;
                        final isSelected =
                            materialTokenId != null &&
                            _selectedTokenIds.contains(materialTokenId);
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _materials.length - 1 ? 8 : 0,
                          ),
                          child: _MaterialItem(
                            material: material,
                            isSelected: isSelected,
                            isDisabled:
                                isActionLoading || materialTokenId == null,
                            onTap: materialTokenId == null || isActionLoading
                                ? null
                                : () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTokenIds.remove(
                                          materialTokenId,
                                        );
                                      } else if (_selectedTokenIds.length <
                                          requiredCount) {
                                        _selectedTokenIds.add(materialTokenId);
                                      }
                                    });
                                  },
                          ),
                        );
                      }),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: StorySpacing.xl,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SvgPicture.asset(
                            brightness == Brightness.dark
                                ? 'assets/common/empty_d.svg'
                                : 'assets/common/empty.svg',
                            width: 72,
                            height: 72,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.gameUpgradeNoMaterials,
                            style: StoryTextStyles.bodyMedium(
                              color: StoryColors.mutedForegroundOf(brightness),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.base),
          Row(
            children: [
              _CloseButton(
                onPressed: isActionLoading
                    ? null
                    : () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: StorySpacing.md),
              Expanded(
                child: _UpgradeButton(
                  label: isMaxLevel
                      ? l10n.gameUpgradeMaxLevel
                      : targetLevelName != null && nextLevel != null
                      ? l10n.gameUpgradeToLevel(nextLevel, targetLevelName)
                      : l10n.gameUpgradeConfirm,
                  onPressed: canConfirm ? _handleConfirm : null,
                  isLoading: isActionLoading,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 升级前后属性对比（Figma node 6284:70994）。
class _UpgradeComparison extends StatelessWidget {
  final int? currentLevel;
  final String? currentLevelName;
  final double? currentMiningCoefficient;
  final int? nextLevel;
  final String? nextLevelName;
  final double? nextMiningCoefficient;

  const _UpgradeComparison({
    this.currentLevel,
    this.currentLevelName,
    this.currentMiningCoefficient,
    this.nextLevel,
    this.nextLevelName,
    this.nextMiningCoefficient,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gameUpgradeBeforeAfter,
          style: StoryTextStyles.bodyMedium(
            color: StoryColors.foregroundOf(brightness),
          ).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _UpgradeLevelCard(
                level: currentLevel,
                levelName: currentLevelName,
                miningCoefficient: currentMiningCoefficient,
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(Icons.chevron_right, size: 16),
            ),
            Expanded(
              child: _UpgradeLevelCard(
                level: nextLevel,
                levelName: nextLevelName,
                miningCoefficient: nextMiningCoefficient,
                color: StoryColors.brandTealDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpgradeLevelCard extends StatelessWidget {
  final int? level;
  final String? levelName;
  final double? miningCoefficient;
  final Color color;

  const _UpgradeLevelCard({
    this.level,
    this.levelName,
    this.miningCoefficient,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 18 / 13,
      letterSpacing: 0,
    );
    final coefficient = miningCoefficient == null
        ? '-'
        : 'x${formatNumber(miningCoefficient!, 1)}';

    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            level == null ? '-' : 'Lv$level',
            style: textStyle.copyWith(color: color),
          ),
          const SizedBox(height: 10),
          Text(levelName ?? '-', style: textStyle.copyWith(color: color)),
          const SizedBox(height: 10),
          Text(
            '${l10n.gameMiningCoef} $coefficient',
            style: textStyle.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// 当前等级卡片 — 灰色背景，展示当前 Lv + 咖位名 + 挖矿系数 + 体力。
class _CurrentLevelCard extends StatelessWidget {
  final MiningActor actor;
  final String? levelName;
  final int staminaLimit;

  const _CurrentLevelCard({
    required this.actor,
    this.levelName,
    required this.staminaLimit,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final level = actor.level;
    final miningCoef = actor.miningCoefficient;
    // 防止后端脏数据导致体力值超出上限或为负。
    final stamina = actor.stamina ?? 0;

    // 设计 token（Figma node 5792:80859）：
    //   page/sheet/thirdly bg, rounded 16, padding 16, gap 24 (Lv→info)
    //   Lv       18/700  lh26  ls -0.04  text/primary
    //   levelName 16/700  lh24  ls 0     text/primary
    //   副标题   12/400  lh16  ls 0.04  text/secondary（挖矿系数 / 体力）
    //   info column gap 6；info row gap 12 + 3px dot
    const metaStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 16 / 12,
      letterSpacing: 0.04,
    );
    final foreground = StoryColors.foregroundOf(brightness);
    final mutedForeground = StoryColors.createActorSecondaryTextOf(brightness);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(StorySpacing.base),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          if (level != null) ...[
            Text(
              'Lv$level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
                color: foreground,
              ),
            ),
            const SizedBox(width: StorySpacing.xl),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (levelName != null)
                  Text(
                    levelName!,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 24 / 16,
                      letterSpacing: 0,
                      color: foreground,
                    ),
                  ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (miningCoef != null && miningCoef > 0) ...[
                      Text(
                        '${l10n.gameMiningCoef} x${formatNumber(miningCoef, 1)}',
                        style: metaStyle.copyWith(color: mutedForeground),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 3,
                        height: 3,
                        decoration: BoxDecoration(
                          color: mutedForeground,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Text(
                      l10n.gameStaminaProgress('$stamina', '$staminaLimit'),
                      style: metaStyle.copyWith(color: mutedForeground),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 升级要求卡片 — 青绿色淡背景 + 青色边框（Figma node 5792:80869）。
class _RequirementsCard extends StatelessWidget {
  final MiningActor actor;
  final int requiredCount;
  final double? fee;
  final int selectedCount;
  final int? completedViewCount;
  final int? heatThreshold;

  const _RequirementsCard({
    required this.actor,
    required this.requiredCount,
    this.fee,
    required this.selectedCount,
    this.completedViewCount,
    this.heatThreshold,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    // 青半透明16 = brandTeal alpha41；青绿5 = brandTeal alpha13
    final dividerColor = StoryColors.brandTeal.withAlpha(41);
    final foreground = StoryColors.foregroundOf(brightness);
    final mutedForeground = StoryColors.mutedForegroundOf(brightness);
    const darkTeal = StoryColors.brandTealDark;

    // 各行取值与 web `GameActorUpgradeDialog` 对齐，默认不显示 '-'：
    //   参演短剧累计完播 = completedViewCount / heatThreshold（缺省 0 / 0）
    //   升级费用 = fee USDC（缺省 0 USDC）
    //   消耗同IP同等级演员 = selectedCount / requiredCount
    final cv = completedViewCount ?? 0;
    final ht = heatThreshold ?? 0;
    final heatValue = '${formatNumber(cv, 0)} / ${formatNumber(ht, 0)}';
    final feeValue = '${formatNumber(fee ?? 0, 0)} ${l10n.currency}';
    final countValue = '$selectedCount / $requiredCount';

    // 设计 token（Figma）：
    //   title  14/700  lh20  ls0  深绿
    //   label  13/400  lh18  ls0  text/secondary
    //   value  13/510  lh18  ls0  text/primary | 深绿
    const titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 20 / 14,
      letterSpacing: 0,
    );
    const labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
      letterSpacing: 0,
    );
    const valueStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 18 / 13,
      letterSpacing: 0,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: StoryColors.brandTeal.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // column gap 4（Figma）
        children: [
          Text(
            l10n.gameUpgradeNextLevelReq,
            style: titleStyle.copyWith(color: darkTeal),
          ),
          const SizedBox(height: 4),
          _ReqDetailRow(
            label: l10n.gameUpgradeHeatThreshold,
            value: heatValue,
            labelStyle: labelStyle.copyWith(color: mutedForeground),
            valueStyle: valueStyle.copyWith(color: foreground),
            dividerColor: dividerColor,
          ),
          const SizedBox(height: 4),
          _ReqDetailRow(
            label: l10n.gameUpgradeFee,
            value: feeValue,
            labelStyle: labelStyle.copyWith(color: mutedForeground),
            valueStyle: valueStyle.copyWith(color: darkTeal),
            dividerColor: dividerColor,
          ),
          const SizedBox(height: 4),
          _ReqDetailRow(
            label: l10n.gameUpgradeRequiredCount,
            value: countValue,
            labelStyle: labelStyle.copyWith(color: mutedForeground),
            valueStyle: valueStyle.copyWith(color: darkTeal),
          ),
        ],
      ),
    );
  }
}

/// 升级要求明细行 — py8 + 可选底部 0.5px 青色分隔线（Figma detail-row）。
class _ReqDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle labelStyle;
  final TextStyle valueStyle;
  final Color? dividerColor;

  const _ReqDetailRow({
    required this.label,
    required this.value,
    required this.labelStyle,
    required this.valueStyle,
    this.dividerColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Text(label, style: labelStyle),
              const Spacer(),
              Text(value, style: valueStyle),
            ],
          ),
        ),
        if (dividerColor != null)
          Divider(color: dividerColor, height: 1, thickness: 0.5),
      ],
    );
  }
}

/// 耗材选择项 — 复选框 + 名称 + 编号 + 等级 + 闪电图标 + 体力。
class _MaterialItem extends StatelessWidget {
  final ActorUpgradeMaterial material;
  final bool isSelected;
  final bool isDisabled;
  final VoidCallback? onTap;

  const _MaterialItem({
    required this.material,
    required this.isSelected,
    required this.isDisabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final materialName = material.actorName?.trim() ?? '';
    final materialLevel = material.level;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: StorySpacing.base,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? StoryColors.brandTeal
                  : StoryColors.dividerOf(brightness),
            ),
            color: isSelected
                ? StoryColors.brandTeal.withAlpha(15)
                : Colors.transparent,
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 24,
                color: isSelected
                    ? StoryColors.brandTeal
                    : StoryColors.mutedForegroundOf(brightness),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    if (materialName.isNotEmpty)
                      Flexible(
                        child: Text(
                          materialName,
                          style: StoryTextStyles.bodyMedium(
                            color: StoryColors.foregroundOf(brightness),
                          ).copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (materialName.isNotEmpty) const SizedBox(width: 4),
                    if (material.actorId != null)
                      Text(
                        material.actorId!.startsWith('#')
                            ? material.actorId!
                            : '#${material.actorId}',
                        style: StoryTextStyles.caption(
                          color: StoryColors.mutedForegroundOf(brightness),
                        ),
                      ),
                  ],
                ),
              ),
              if (materialLevel != null) ...[
                const SizedBox(width: 12),
                Text(
                  'Lv$materialLevel',
                  style: TextStyle(
                    fontSize: 12,
                    color: StoryColors.foregroundOf(brightness),
                  ),
                ),
              ],
              if (material.stamina != null &&
                  material.staminaLimit != null) ...[
                const SizedBox(width: 12),
                SvgPicture.asset(
                  'assets/game/earlier.svg',
                  width: 16,
                  height: 16,
                ),
                const SizedBox(width: 2),
                Text(
                  '${material.stamina}/${material.staminaLimit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 关闭按钮 — 描边样式。
class _CloseButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const _CloseButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(120, 44),
        side: BorderSide(color: StoryColors.dividerOf(brightness)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: Text(
        l10n.commonClose,
        style: StoryTextStyles.bodyMedium(
          color: StoryColors.foregroundOf(brightness),
        ).copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

/// 升级按钮 — 深色填充，flex-1。
class _UpgradeButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _UpgradeButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = StoryColors.foregroundOf(brightness);
    final fg = StoryColors.backgroundOf(brightness);
    final disabledBg = StoryColors.buttonDisabledForegroundOf(brightness);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: bg,
        foregroundColor: fg,
        disabledBackgroundColor: disabledBg,
        disabledForegroundColor: StoryColors.onOverlaySubtle,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
      child: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: fg),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
    );
  }
}
