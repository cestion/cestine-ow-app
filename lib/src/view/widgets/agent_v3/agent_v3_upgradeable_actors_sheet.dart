import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../controller/agent_v2_upgradeable_actors_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_info_dialog.dart';
import '../../../widgets/story_paginated_scroll_view.dart';
import '../../../widgets/story_state_widget.dart';
import '../agent_v2/agent_v2_upgrade_confirm_dialog.dart';
import 'agent_v3_actor_list_skeleton.dart';
import 'agent_v3_purchase_sheet.dart';

const _cardDesignWidth = 175.5;
const _cardAspectRatio = _cardDesignWidth / 234;
const _monetaryColor = Color(0xFFD99902);
const _controlBackground = Color(0x80000000);
const _activeButtonColor = Color(0xFFFFC53D);
const _disabledButtonColor = Color(0xFFC3C5CE);
const _manualAsset = 'assets/game_v3/agent_token_usdc.png';
const _sameIpAsset = 'assets/game_v3/agent_upgrade_same_ip.png';
const _labelAsset = 'assets/game_v3/agent_upgrade_label.svg';
const _salaryAsset = 'assets/game_v3/agent_candidate_salary.svg';
const _plusAsset = 'assets/game_v3/agent_upgrade_plus.svg';
const _checkAsset = 'assets/game_v3/agent_upgrade_check.svg';
const _fallbackMaxActorLevel = 5;

int _fallbackTrainingManualAmount(int currentLevel) => switch (currentLevel) {
  1 => 2,
  2 => 4,
  3 => 8,
  4 => 16,
  _ => 0,
};

int _requiredSameIpActorCount(InitActorNftConfig? config, int currentLevel) {
  final configured = config?.requiredMaterialCountForLevel(currentLevel) ?? 2;
  return configured < 0 ? 0 : configured;
}

Future<void> _showUpgradeMaterialHint(
  BuildContext context, {
  required int requiredCount,
}) {
  final brightness = Theme.of(context).brightness;
  return StoryInfoDialog.show(
    context: context,
    title: context.l10n.commonNotice,
    actionLabel: context.l10n.commonOk,
    content: Text(
      context.l10n.agentV3UpgradeMaterialHint(requiredCount),
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

/// 打开 Figma `2620:135114` 的 V3「升级角色」面板。
///
/// 角色列表、分页和同 IP 材料数量复用 V2 的唯一数据源；点击可升级角色后
/// 打开 Figma `2797:183316` 确认弹窗，并沿用既有订单与链上提交链路。
Future<void> showAgentV3UpgradeableActorsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: StoryColors.cardOf(Theme.of(context).brightness),
    barrierColor: StoryColors.overlayMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    clipBehavior: Clip.antiAlias,
    showDragHandle: false,
    builder: (_) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      snap: true,
      snapAnimationDuration: const Duration(milliseconds: 220),
      builder: (_, scrollController) =>
          AgentV3UpgradeableActorsSheet(scrollController: scrollController),
    ),
  );
}

class AgentV3UpgradeableActorsSheet extends ConsumerStatefulWidget {
  const AgentV3UpgradeableActorsSheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<AgentV3UpgradeableActorsSheet> createState() =>
      _AgentV3UpgradeableActorsSheetState();
}

class _AgentV3UpgradeableActorsSheetState
    extends ConsumerState<AgentV3UpgradeableActorsSheet> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(agentV2UpgradeableActorsControllerProvider.notifier).refresh(),
      );
    });
  }

  @override
  void dispose() {
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final state = ref.watch(agentV2UpgradeableActorsControllerProvider);
    final manualBalance = ref.watch(
      agentV3ControllerProvider.select(
        (value) => (value.assets ?? UserAssets.empty).trainingManual,
      ),
    );
    final manualBalanceLabel = ref.watch(
      agentV3ControllerProvider.select((value) => value.secondaryItemCount),
    );
    final sharedActorNftConfig = ref
        .watch(globalConfigProvider)
        .whenOrNull(data: (result) => result.dataOrNull?.init?.actorNft);
    final calibratedActorNftConfig = ref
        .watch(agentV3UpgradeConfigCalibrationProvider)
        .whenOrNull(data: (result) => result.dataOrNull?.init?.actorNft);
    // 网络校准成功后立即覆盖共享快照；校准期间仍用已有配置或卡片默认值，
    // 不让材料行因为配置请求尚未结束而消失。
    final actorNftConfig = calibratedActorNftConfig ?? sharedActorNftConfig;

    return Material(
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SheetHeader(manualBalanceLabel: manualBalanceLabel),
            const SizedBox(height: 16),
            Expanded(
              child: _SheetBody(
                state: state,
                controller: _scrollController,
                manualBalance: manualBalance,
                actorNftConfig: actorNftConfig,
                onRefresh: ref
                    .read(agentV2UpgradeableActorsControllerProvider.notifier)
                    .refresh,
                onLoadMore: ref
                    .read(agentV2UpgradeableActorsControllerProvider.notifier)
                    .loadMore,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeader extends ConsumerWidget {
  const _SheetHeader({required this.manualBalanceLabel});

  final String manualBalanceLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    return SizedBox(
      height: 108,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 24,
              child: Center(
                child: Container(
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(
                    color: StoryColors.sheetSecondaryOf(brightness),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.agentV2UpgradeableActorsTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 26 / 18,
                letterSpacing: -0.04,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _ManualBalanceChip(
                  value: manualBalanceLabel,
                  onAdd: () => showAgentV3PurchaseSheet(
                    context,
                    ref,
                    CardPurchaseType.trainingManual,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ManualBalanceChip extends StatelessWidget {
  const _ManualBalanceChip({required this.value, required this.onAdd});

  final String value;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: 34,
      padding: const EdgeInsets.fromLTRB(6, 3, 3, 3),
      decoration: BoxDecoration(
        color: StoryColors.sheetSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(88),
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            _manualAsset,
            width: 21.161,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 38,
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.center,
              overflow: TextOverflow.fade,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 18 / 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            button: true,
            label: context.l10n.agentV3Upgrade,
            child: GestureDetector(
              key: const ValueKey('agent-v3-upgrade-buy-manual'),
              behavior: HitTestBehavior.opaque,
              onTap: onAdd,
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: StoryColors.foregroundOf(brightness),
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  _plusAsset,
                  width: 12,
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    StoryColors.cardOf(brightness),
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.state,
    required this.controller,
    required this.manualBalance,
    required this.actorNftConfig,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final AgentV2UpgradeableActorsState state;
  final ScrollController controller;
  final double manualBalance;
  final InitActorNftConfig? actorNftConfig;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.isInitialized || state.isLoading) {
      return const AgentV3ActorListSkeleton();
    }
    if (state.isInitialized && state.actors.isEmpty) {
      final error = state.lastError;
      if (error != null) {
        return StoryStateWidget.error(
          key: const ValueKey('agent-v3-upgrade-error'),
          message: context.l10nError(error),
          actionLabel: context.l10n.commonRetry,
          onAction: onRefresh,
          compact: true,
        );
      }
      return StoryStateWidget.empty(
        key: const ValueKey('agent-v3-upgrade-empty'),
        message: context.l10n.agentV2UpgradeableActorsEmpty,
        compact: true,
      );
    }

    return _UpgradeableGrid(
      controller: controller,
      actors: state.actors,
      manualBalance: manualBalance,
      actorNftConfig: actorNftConfig,
      hasMore: state.hasMore,
      loadingMore: state.isLoadingMore,
      onLoadMore: onLoadMore,
    );
  }
}

/// 与 V3 候选列表保持一致的 Sliver 分页网格。
class _UpgradeableGrid extends StatelessWidget {
  const _UpgradeableGrid({
    required this.controller,
    required this.actors,
    required this.manualBalance,
    required this.actorNftConfig,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final ScrollController controller;
  final List<MiningActor> actors;
  final double manualBalance;
  final InitActorNftConfig? actorNftConfig;
  final bool hasMore;
  final bool loadingMore;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 2;
        final cardHeight = cardWidth / _cardAspectRatio;
        return StoryPaginatedScrollView(
          key: const ValueKey('agent-v3-upgrade-grid'),
          controller: controller,
          itemCount: actors.length,
          hasMore: hasMore,
          isLoadingMore: loadingMore,
          onLoadMore: onLoadMore,
          showNoMoreIndicator: true,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                8,
                0,
                8,
                8 + MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: cardHeight,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _UpgradeableActorCard(
                    actor: actors[index],
                    manualBalance: manualBalance,
                    actorNftConfig: actorNftConfig,
                  ),
                  childCount: actors.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UpgradeableActorCard extends ConsumerWidget {
  const _UpgradeableActorCard({
    required this.actor,
    required this.manualBalance,
    required this.actorNftConfig,
  });

  final MiningActor actor;
  final double manualBalance;
  final InitActorNftConfig? actorNftConfig;

  Future<void> _openActorDetail(BuildContext context) {
    final actorId = actor.actorCollectionId?.toString();
    if (actorId == null) return Future.value();
    return openActorDetail(
      context,
      actorId: actorId,
      preview: ActorCollection(
        id: actorId,
        name: actor.actorName,
        avatarUrl: actor.avatarUrl,
        heatValue: actor.heat,
        trust: actor.trust,
        computingPower: actor.computingPower,
      ),
    );
  }

  Future<void> _openUpgrade(BuildContext context, WidgetRef ref) async {
    final upgraded = await showAgentV2UpgradeConfirmDialog(context, ref, actor);
    if (!upgraded || !context.mounted) return;

    // 升级会同时改变主演员等级、销毁耗材并影响片酬，两份展示数据都需回源。
    ref.read(weeklySalaryControllerProvider.notifier).refreshAfterMutation();
    await ref
        .read(agentV2UpgradeableActorsControllerProvider.notifier)
        .refreshAfterUpgrade();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLevel = actor.level ?? 0;
    final currentUpgrade = actorNftConfig?.upgradeConfigForLevel(currentLevel);
    final configuredMaxLevel = actorNftConfig?.maxConfiguredLevel;
    // 满级判断必须基于角色当前等级，而不是升级后的目标等级。否则
    // Lv.4 → Lv.5 会因为目标恰好等于最高等级而被误判成已经满级。
    // 若当前等级显式配置了 upgrade，即使服务端 levels 暂未包含目标等级，
    // 也应优先视为仍存在升级路径。
    final isCurrentMaxLevel =
        currentUpgrade == null &&
        currentLevel >= (configuredMaxLevel ?? _fallbackMaxActorLevel);

    // 训练手册按当前等级读取，例如 Lv.2 → Lv.3 使用
    // levels[2].upgrade.trainingManualAmount。只有当前角色已经满级才隐藏材料。
    final configuredManualRequired = actorNftConfig
        ?.trainingManualAmountForLevel(currentLevel);
    final resolvedManualRequired =
        configuredManualRequired ?? _fallbackTrainingManualAmount(currentLevel);
    final manualRequired = resolvedManualRequired < 0
        ? 0
        : resolvedManualRequired;
    final manualAvailable = manualBalance.floor();
    final manualMet = manualRequired <= 0 || manualAvailable >= manualRequired;
    final manualDisplay = manualMet ? manualRequired : manualAvailable;
    final sameIpRequired = _requiredSameIpActorCount(
      actorNftConfig,
      currentLevel,
    );
    final sameIpAvailable = actor.materialCount ?? 0;
    final sameIpMet = sameIpRequired <= 0 || sameIpAvailable >= sameIpRequired;
    final sameIpDisplay = sameIpMet ? sameIpRequired : sameIpAvailable;
    final canUpgrade = !isCurrentMaxLevel && manualMet && sameIpMet;

    return Semantics(
      label: actor.displayName,
      child: RepaintBoundary(
        key: ValueKey('agent-v3-upgrade-card-${actor.nftId}'),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: StoryColors.whiteToDarkOf(Theme.of(context).brightness),
              border: Border.all(color: _monetaryColor, width: 0.8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                fit: StackFit.expand,
                children: [
                  _ActorImage(actor: actor, logicalWidth: constraints.maxWidth),
                  const Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: 104,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0x66000000)],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: _ActorIdentity(actor: actor),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: MediaQuery.withNoTextScaling(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrentMaxLevel) ...[
                              Row(
                                key: ValueKey(
                                  'agent-v3-upgrade-requirements-${actor.nftId}',
                                ),
                                children: [
                                  Expanded(
                                    child: _RequirementPill(
                                      key: ValueKey(
                                        'agent-v3-upgrade-manual-requirement-${actor.nftId}',
                                      ),
                                      asset: _manualAsset,
                                      assetWidth: 14.108,
                                      current: manualDisplay,
                                      required: manualRequired,
                                      isMet: manualMet,
                                      addKey: ValueKey(
                                        'agent-v3-upgrade-manual-add-${actor.nftId}',
                                      ),
                                      addSemanticLabel: context.l10n
                                          .agentV3PurchaseTitle(
                                            context.l10n.agentV3TrainingManual,
                                          ),
                                      onAddTap: manualMet
                                          ? null
                                          : () => unawaited(
                                              showAgentV3PurchaseSheet(
                                                context,
                                                ref,
                                                CardPurchaseType.trainingManual,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _RequirementPill(
                                      key: ValueKey(
                                        'agent-v3-upgrade-same-ip-requirement-${actor.nftId}',
                                      ),
                                      asset: _sameIpAsset,
                                      assetWidth: 14,
                                      current: sameIpDisplay,
                                      required: sameIpRequired,
                                      isMet: sameIpMet,
                                      countKey: ValueKey(
                                        'agent-v3-upgrade-same-ip-count-${actor.nftId}',
                                      ),
                                      countSemanticLabel: context.l10n
                                          .agentV3UpgradeMaterialHint(
                                            sameIpRequired,
                                          ),
                                      onCountTap: () => unawaited(
                                        _showUpgradeMaterialHint(
                                          context,
                                          requiredCount: sameIpRequired,
                                        ),
                                      ),
                                      addKey: ValueKey(
                                        'agent-v3-upgrade-same-ip-add-${actor.nftId}',
                                      ),
                                      addSemanticLabel: context.l10n
                                          .agentV2UpgradeMaterialsHint(
                                            actor.displayName,
                                          ),
                                      onAddTap:
                                          sameIpMet ||
                                              actor.actorCollectionId == null
                                          ? null
                                          : () => unawaited(
                                              _openActorDetail(context),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            _SalaryPill(actor: actor),
                            const SizedBox(height: 8),
                            _UpgradeButton(
                              enabled: canUpgrade,
                              onPressed: canUpgrade
                                  ? () => _openUpgrade(context, ref)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActorImage extends StatelessWidget {
  const _ActorImage({required this.actor, required this.logicalWidth});

  final MiningActor actor;
  final double logicalWidth;

  @override
  Widget build(BuildContext context) {
    final url = actor.avatarUrl?.trim();
    final fallback = ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Center(
        child: Icon(
          Icons.person,
          size: 56,
          color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
        ),
      ),
    );
    if (url == null || url.isEmpty) return fallback;
    return StoryCachedImage(
      imageUrl: url,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
        context,
        logicalWidth,
      ),
      placeholder: fallback,
      errorWidget: fallback,
    );
  }
}

class _ActorIdentity extends StatelessWidget {
  const _ActorIdentity({required this.actor});

  final MiningActor actor;

  @override
  Widget build(BuildContext context) {
    final tokenId = actor.actorTokenId;
    final code = tokenId == null
        ? actor.actorCode ?? '-'
        : '#${tokenId.toString().padLeft(5, '0')}';
    return SizedBox(
      width: 112,
      height: 42,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset(_labelAsset, fit: BoxFit.fill),
          MediaQuery.withNoTextScaling(
            child: Padding(
              // 两行设计行高共 30px。底部额外保留 1px，兼容 Android
              // 字体度量取整，避免 42px 标签内出现 RenderFlex overflow。
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    actor.displayName.isEmpty ? '-' : actor.displayName,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 18 / 13,
                    ),
                  ),
                  Text(
                    code,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _monetaryColor,
                      fontSize: 10,
                      height: 12 / 10,
                      letterSpacing: 0.08,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequirementPill extends StatelessWidget {
  const _RequirementPill({
    super.key,
    required this.asset,
    required this.assetWidth,
    required this.current,
    required this.required,
    required this.isMet,
    this.countKey,
    this.countSemanticLabel,
    this.onCountTap,
    this.addKey,
    this.addSemanticLabel,
    this.onAddTap,
  });

  final String asset;
  final double assetWidth;
  final int current;
  final int required;
  final bool isMet;
  final Key? countKey;
  final String? countSemanticLabel;
  final VoidCallback? onCountTap;
  final Key? addKey;
  final String? addSemanticLabel;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _controlBackground,
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(88),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: onCountTap != null,
              label: countSemanticLabel,
              child: GestureDetector(
                key: countKey,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: onCountTap,
                child: Row(
                  children: [
                    Image.asset(
                      asset,
                      width: assetWidth,
                      height: 16,
                      fit: BoxFit.contain,
                    ),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$current',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 18 / 13,
                                ),
                              ),
                              TextSpan(
                                text: '/$required',
                                style: const TextStyle(
                                  color: Color(0xFFB0B4BA),
                                  fontSize: 10,
                                  height: 12 / 10,
                                  letterSpacing: 0.08,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMet)
            Container(
              width: 28,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFF212225),
                borderRadius: BorderRadius.circular(49),
              ),
              child: SvgPicture.asset(_checkAsset, width: 12, height: 12),
            )
          else
            Semantics(
              button: true,
              enabled: onAddTap != null,
              label: addSemanticLabel,
              child: GestureDetector(
                key: addKey,
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: onAddTap,
                child: Container(
                  width: 28,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFF212225),
                    borderRadius: BorderRadius.circular(49),
                  ),
                  child: SvgPicture.asset(_plusAsset, width: 12, height: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SalaryPill extends StatelessWidget {
  const _SalaryPill({required this.actor});

  final MiningActor actor;

  @override
  Widget build(BuildContext context) {
    final salary = formatNumber(getMiningActorHourlySalary(actor));
    return Container(
      height: 26,
      padding: const EdgeInsets.fromLTRB(3, 3, 5, 3),
      decoration: BoxDecoration(
        color: _controlBackground,
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(88),
      ),
      child: Row(
        children: [
          SvgPicture.asset(_salaryAsset, width: 20, height: 20),
          const SizedBox(width: 6),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: salary,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        height: 20 / 16,
                      ),
                    ),
                    const TextSpan(
                      text: ' /h',
                      style: TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 10,
                        height: 12 / 10,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
                maxLines: 1,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: _activeButtonColor, width: 0.5),
              borderRadius: BorderRadius.circular(52),
            ),
            child: Text(
              'Lv.${actor.level ?? '-'}',
              style: const TextStyle(
                color: _activeButtonColor,
                fontSize: 10,
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

class _UpgradeButton extends StatelessWidget {
  const _UpgradeButton({required this.enabled, this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      child: Material(
        color: enabled ? _activeButtonColor : _disabledButtonColor,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Color(0x26FFFFFF), width: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('agent-v3-upgrade-button-$enabled'),
          onTap: enabled ? onPressed : null,
          child: SizedBox(
            height: 40,
            child: Center(
              child: Text(
                context.l10n.agentV3Upgrade,
                style: TextStyle(
                  color: enabled
                      ? const Color(0xFF1C2024)
                      : StoryColors.mutedForegroundOf(Brightness.light),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
