import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../controller/game_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_paginated_scroll_view.dart';
import '../../../widgets/story_state_widget.dart';
import '../agent_performance_confirm_dialog.dart';
import 'agent_v3_actor_list_skeleton.dart';
import 'agent_v3_refill_stamina_dialog.dart';

const _candidateLabelAsset = 'assets/game_v3/agent_candidate_label.svg';
const _salaryAsset = 'assets/game_v3/agent_candidate_salary.svg';
const _staminaAsset = 'assets/game_v3/agent_candidate_stamina.svg';
const _plusAsset = 'assets/game_v3/agent_candidate_plus.svg';
const _monetaryColor = Color(0xFFD99902);
const _controlBackground = Color(0xB3111113);
const _candidateCardDesignWidth = 175.5;
const _cardAspectRatio = _candidateCardDesignWidth / 234;

/// 打开 V3 候场角色面板；数据和操作状态继续复用 V2 的唯一数据源。
Future<String?> showAgentV3CandidateActorsSheet(BuildContext context) {
  return showModalBottomSheet<String>(
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
          AgentV3CandidateActorsSheet(scrollController: scrollController),
    ),
  );
}

/// Figma `2679:150949`：候场角色两列列表。
class AgentV3CandidateActorsSheet extends ConsumerStatefulWidget {
  const AgentV3CandidateActorsSheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<AgentV3CandidateActorsSheet> createState() =>
      _AgentV3CandidateActorsSheetState();
}

class _AgentV3CandidateActorsSheetState
    extends ConsumerState<AgentV3CandidateActorsSheet> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
    // 首帧后再刷新，确保 autoDispose Provider 已由弹窗持有。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(agentV2CandidateActorsControllerProvider.notifier).refresh(),
      );
    });
  }

  void _openActorPlaza() {
    ref.read(tabIndexProvider.notifier).setIndex(StoryTab.nft.index);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    if (_ownsScrollController) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final state = ref.watch(agentV2CandidateActorsControllerProvider);
    final configuredStaminaLimit = ref.watch(
      agentV3ControllerProvider.select((value) => value.staminaLimit),
    );
    final staminaLimit =
        configuredStaminaLimit != null && configuredStaminaLimit > 0
        ? configuredStaminaLimit
        : defaultGameStaminaLimit;

    return Material(
      color: StoryColors.cardOf(brightness),
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: StoryColors.dividerOf(brightness),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _SheetHeader(),
              const SizedBox(height: 12),
              Expanded(
                child: switch ((
                  state.isInitialized,
                  state.isLoading,
                  state.lastError,
                  state.actors,
                )) {
                  (false, _, _, _) || (_, true, _, _) =>
                    const AgentV3ActorListSkeleton(showExternalActions: true),
                  (true, false, final error?, final actors)
                      when actors.isEmpty =>
                    StoryStateWidget.error(
                      key: const ValueKey('agent-v3-candidate-error'),
                      message: error.userMessage,
                      actionLabel: context.l10n.commonRetry,
                      onAction: () => ref
                          .read(
                            agentV2CandidateActorsControllerProvider.notifier,
                          )
                          .refresh(),
                      compact: true,
                    ),
                  (true, false, _, final actors) when actors.isEmpty =>
                    StoryStateWidget.empty(
                      key: const ValueKey('agent-v3-candidate-empty'),
                      message: context.l10n.agentV2NoActors,
                      compact: true,
                      action: IconButton(
                        key: const ValueKey('agent-v3-candidate-add'),
                        tooltip: context.l10n.navNftIp,
                        onPressed: _openActorPlaza,
                        icon: SvgPicture.asset(
                          _plusAsset,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            StoryColors.foregroundOf(brightness),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  _ => _CandidateGrid(
                    controller: _scrollController,
                    actors: state.actors,
                    staminaLimit: staminaLimit,
                    hasMore: state.hasMore,
                    loadingMore: state.isLoadingMore,
                    onLoadMore: ref
                        .read(agentV2CandidateActorsControllerProvider.notifier)
                        .loadMore,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        SizedBox(
          height: 24,
          child: Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: StoryColors.actorHeroBadgeBgOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Text(
          context.l10n.agentV3WaitingActorsTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 26 / 18,
            letterSpacing: -0.04,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          context.l10n.agentV3WaitingActorsDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.mutedForegroundOf(brightness),
            fontSize: 12,
            height: 16 / 12,
            letterSpacing: 0.04,
          ),
        ),
      ],
    );
  }
}

class _CandidateGrid extends StatelessWidget {
  const _CandidateGrid({
    required this.controller,
    required this.actors,
    required this.staminaLimit,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final ScrollController controller;
  final List<MiningActor> actors;
  final int staminaLimit;
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
          key: const ValueKey('agent-v3-candidate-grid'),
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
                  mainAxisSpacing: 16,
                  mainAxisExtent: cardHeight + 48,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _CandidateItem(
                    actor: actors[index],
                    staminaLimit: staminaLimit,
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

class _CandidateItem extends StatelessWidget {
  const _CandidateItem({required this.actor, required this.staminaLimit});

  final MiningActor actor;
  final int staminaLimit;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Semantics(
            button: actor.actorCollectionId != null,
            label: actor.displayName,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: actor.actorCollectionId == null
                  ? null
                  : () => unawaited(_openActorDetail(context)),
              child: _CandidateCard(actor: actor, staminaLimit: staminaLimit),
            ),
          ),
        ),
        const SizedBox(height: 8),
        _CandidateActions(actor: actor, staminaLimit: staminaLimit),
      ],
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.actor, required this.staminaLimit});

  final MiningActor actor;
  final int staminaLimit;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.whiteToDarkOf(Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: Color(0x21000000),
              offset: Offset(1, 5),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: DecoratedBox(
            decoration: BoxDecoration(
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
                    child: _ActorIdentity(
                      actor: actor,
                      cardWidth: constraints.maxWidth,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SalaryPill(actor: actor),
                          const SizedBox(height: 8),
                          _StaminaPill(actor: actor, limit: staminaLimit),
                        ],
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
  const _ActorIdentity({required this.actor, required this.cardWidth});

  final MiningActor actor;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final tokenId = actor.actorTokenId;
    final code = tokenId == null
        ? actor.actorCode ?? '-'
        : '#${tokenId.toString().padLeft(5, '0')}';
    final scale = (cardWidth / _candidateCardDesignWidth).clamp(0.0, 1.0);
    return SizedBox(
      width: 114 * scale,
      height: 51 * scale,
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 114,
          height: 51,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SvgPicture.asset(_candidateLabelAsset, fit: BoxFit.fill),
              MediaQuery.withNoTextScaling(
                child: Padding(
                  // Keep the designed top offset, but leave 3 px of vertical
                  // tolerance for Android font-metric rounding. The two lines
                  // nominally occupy 20 + 16 px; an exact 7 + 36 + 8 budget
                  // can still overflow by 1 px on some devices.
                  padding: const EdgeInsets.fromLTRB(8, 7, 8, 5),
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
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 20 / 14,
                        ),
                      ),
                      Text(
                        code,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _monetaryColor,
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: 0.04,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
        color: const Color(0x80000000),
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
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.04,
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
              border: Border.all(color: StoryColors.star, width: 0.5),
              borderRadius: BorderRadius.circular(52),
            ),
            child: Text(
              'Lv.${actor.level ?? '-'}',
              style: const TextStyle(
                color: StoryColors.star,
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

class _StaminaPill extends StatelessWidget {
  const _StaminaPill({required this.actor, required this.limit});

  final MiningActor actor;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final stamina = actor.stamina ?? 0;
    final isDepleted = stamina == 0;
    final progress = actor.staminaProgress(limit) ?? 0;
    return Container(
      height: 32,
      padding: const EdgeInsets.fromLTRB(3, 3, 16, 3),
      decoration: BoxDecoration(
        color: _controlBackground,
        border: Border.all(color: const Color(0x1AFFFFFF), width: 0.5),
        borderRadius: BorderRadius.circular(88),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              border: Border.all(color: const Color(0x1AFFFFFF), width: 0.27),
              shape: BoxShape.circle,
            ),
            child: SvgPicture.asset(
              _staminaAsset,
              colorFilter: isDepleted
                  ? const ColorFilter.mode(
                      StoryColors.destructive,
                      BlendMode.srcIn,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 17,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$stamina',
                            style: TextStyle(
                              color: isDepleted
                                  ? StoryColors.destructive
                                  : StoryColors.star,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              height: 1,
                            ),
                          ),
                          TextSpan(
                            text: ' / $limit',
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF),
                              fontSize: 12,
                              height: 1,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: const Color(0x26FFFFFF),
                      valueColor: const AlwaysStoppedAnimation(
                        StoryColors.star,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CandidateActions extends ConsumerWidget {
  const _CandidateActions({required this.actor, required this.staminaLimit});

  final MiningActor actor;
  final int staminaLimit;

  Future<void> _refill(BuildContext context, WidgetRef ref) async {
    final refill = await showAgentV3RefillStaminaDialog(context, ref, actor);
    if (refill == null || !context.mounted) return;
    ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .markStaminaRefilled(actor.nftId, refill.afterStamina);
  }

  Future<void> _schedulePerformance(BuildContext context, WidgetRef ref) async {
    final scheduled = await showAgentPerformanceConfirmDialog(
      context,
      ref,
      actor,
      hasVacantSlot:
          ref.read(agentV3ControllerProvider).vacantDeploySlotCount > 0,
    );
    if (scheduled != true || !context.mounted) return;
    Navigator.of(context).pop(actor.nftId);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final isFull = actor.isStaminaFull(staminaLimit);
    final foreground = isFull
        ? StoryColors.buttonDisabledForegroundOf(brightness)
        : StoryColors.foregroundOf(brightness);

    return SizedBox(
      height: 40,
      child: Row(
        children: [
          SizedBox.square(
            dimension: 40,
            child: _ActionButton(
              key: ValueKey('agent-v3-refill-${actor.nftId}'),
              semanticLabel: context.l10n.gameRefillTitle,
              borderColor: isFull
                  ? StoryColors.buttonDisabledForegroundOf(brightness)
                  : StoryColors.dividerOf(brightness),
              onTap: isFull ? null : () => _refill(context, ref),
              child: SvgPicture.asset(
                _plusAsset,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _ActionButton(
              key: ValueKey('agent-v3-perform-${actor.nftId}'),
              semanticLabel: context.l10n.agentV2SchedulePerformance,
              backgroundColor: StoryColors.foregroundOf(brightness),
              onTap: () => _schedulePerformance(context, ref),
              child: Text(
                context.l10n.agentV2SchedulePerformance,
                style: TextStyle(
                  color: StoryColors.whiteToDarkOf(brightness),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 20 / 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

  final String semanticLabel;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: borderColor == null
              ? BorderSide.none
              : BorderSide(color: borderColor!, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(child: child),
        ),
      ),
    );
  }
}
