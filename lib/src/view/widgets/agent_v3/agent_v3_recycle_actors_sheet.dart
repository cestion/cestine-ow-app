import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/story_toast.dart';
import '../../../components/iap/iap_point_icon.dart';
import '../../../controller/agent_v3_recycle_actors_state.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_paginated_scroll_view.dart';
import '../../../widgets/story_state_widget.dart';
import 'agent_v3_actor_list_skeleton.dart';

const _cardDesignWidth = 175.5;
const _cardAspectRatio = _cardDesignWidth / 234;
const _monetaryColor = Color(0xFFD99902);
const _controlBackground = Color(0x80000000);
const _recycleButtonColor = Color(0xFF1C2024);
const _labelAsset = 'assets/game_v3/agent_upgrade_label.svg';
const _salaryAsset = 'assets/game_v3/agent_candidate_salary.svg';
const _recycleManualAsset = 'assets/game_v3/agent_token_usdc.png';
const _recyclePrimary = Color(0xFFE50815);
const _recycleError = Color(0xFFE5484D);

/// 打开 Figma `2708:167672` 的 V3「角色回收」面板。
Future<void> showAgentV3RecycleActorsSheet(BuildContext context) {
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
          AgentV3RecycleActorsSheet(scrollController: scrollController),
    ),
  );
}

/// Figma `2708:167672`：角色回收两列分页列表。
class AgentV3RecycleActorsSheet extends ConsumerStatefulWidget {
  const AgentV3RecycleActorsSheet({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<AgentV3RecycleActorsSheet> createState() =>
      _AgentV3RecycleActorsSheetState();
}

class _AgentV3RecycleActorsSheetState
    extends ConsumerState<AgentV3RecycleActorsSheet> {
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
        ref.read(agentV3RecycleActorsControllerProvider.notifier).refresh(),
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
    final state = ref.watch(agentV3RecycleActorsControllerProvider);
    final controller = ref.read(
      agentV3RecycleActorsControllerProvider.notifier,
    );

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
                child: _SheetBody(
                  state: state,
                  controller: _scrollController,
                  onRefresh: controller.refresh,
                  onLoadMore: controller.loadMore,
                ),
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
                color: StoryColors.sheetSecondaryOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Text(
          context.l10n.agentV3RecycleActorsTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 26 / 18,
            letterSpacing: -0.04,
          ),
        ),
      ],
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({
    required this.state,
    required this.controller,
    required this.onRefresh,
    required this.onLoadMore,
  });

  final AgentV3RecycleActorsState state;
  final ScrollController controller;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.isInitialized || state.isLoading) {
      return const AgentV3ActorListSkeleton();
    }

    if (state.actors.isEmpty) {
      final error = state.lastError;
      if (error != null) {
        return StoryStateWidget.error(
          key: const ValueKey('agent-v3-recycle-error'),
          message: context.l10nError(error),
          actionLabel: context.l10n.commonRetry,
          onAction: onRefresh,
          compact: true,
        );
      }
      return StoryStateWidget.empty(
        key: const ValueKey('agent-v3-recycle-empty'),
        message: context.l10n.commonNoData,
        compact: true,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 24) / 2;
        final cardHeight = cardWidth / _cardAspectRatio;
        return StoryPaginatedScrollView(
          key: const ValueKey('agent-v3-recycle-grid'),
          controller: controller,
          itemCount: state.actors.length,
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onRefresh: onRefresh,
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
                  (context, index) =>
                      _RecycleActorCard(actor: state.actors[index]),
                  childCount: state.actors.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RecycleActorCard extends StatelessWidget {
  const _RecycleActorCard({required this.actor});

  final MiningActor actor;

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
    final canOpenDetail = actor.actorCollectionId != null;
    return Semantics(
      button: canOpenDetail,
      label: actor.displayName,
      child: GestureDetector(
        key: ValueKey('agent-v3-recycle-card-${actor.nftId}'),
        behavior: HitTestBehavior.opaque,
        onTap: canOpenDetail
            ? () => unawaited(_openActorDetail(context))
            : null,
        child: RepaintBoundary(
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
                      _ActorImage(
                        actor: actor,
                        logicalWidth: constraints.maxWidth,
                      ),
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
                                _SalaryPill(actor: actor),
                                const SizedBox(height: 8),
                                _RecycleButton(actor: actor),
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
          Padding(
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

class _RecycleButton extends StatelessWidget {
  const _RecycleButton({required this.actor});

  final MiningActor actor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('agent-v3-recycle-submit'),
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          unawaited(showAgentV3RecycleConfirmDialog(context, actor: actor)),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _recycleButtonColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          context.l10n.agentV3Recycle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            height: 20 / 14,
          ),
        ),
      ),
    );
  }
}

/// Figma `2797:183314`：单个角色回收确认弹窗。
Future<void> showAgentV3RecycleConfirmDialog(
  BuildContext context, {
  required MiningActor actor,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: StoryColors.overlayMid,
    builder: (_) => _RecycleConfirmDialog(actor: actor),
  );
}

class _RecycleConfirmDialog extends ConsumerStatefulWidget {
  const _RecycleConfirmDialog({required this.actor});

  final MiningActor actor;

  @override
  ConsumerState<_RecycleConfirmDialog> createState() =>
      _RecycleConfirmDialogState();
}

class _RecycleConfirmDialogState extends ConsumerState<_RecycleConfirmDialog> {
  ActorNftRecycleEstimateResponse? _estimate;
  bool _isLoading = true;
  bool _isDestructionArmed = false;
  Object? _estimateError;

  @override
  void initState() {
    super.initState();
    unawaited(_loadEstimate());
  }

  Future<void> _loadEstimate() async {
    setState(() {
      _isLoading = true;
      _isDestructionArmed = false;
      _estimateError = null;
    });
    final result = await ref
        .read(agentV3RecycleActorsControllerProvider.notifier)
        .getRecycleEstimate(widget.actor);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _estimate = result.dataOrNull;
      _estimateError = result.errorOrNull;
    });
  }

  void _handleConfirm() {
    if (!_isDestructionArmed) {
      setState(() => _isDestructionArmed = true);
      return;
    }
    unawaited(_submit());
  }

  Future<void> _submit() async {
    final estimate = _estimate;
    final controller = ref.read(
      agentV3RecycleActorsControllerProvider.notifier,
    );
    if (estimate == null ||
        ref
            .read(agentV3RecycleActorsControllerProvider)
            .isRecycling(widget.actor.nftId)) {
      return;
    }

    final result = await controller.recycleActor(
      actor: widget.actor,
      estimate: estimate,
    );
    if (!mounted) return;
    if (result.isFailure) {
      StoryToast.error(
        context,
        context.l10nError(result.errorOrNull!),
        rootOverlay: true,
      );
      return;
    }
    StoryToast.success(
      context,
      context.l10n.agentV3RecycleSubmitted,
      rootOverlay: true,
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final state = ref.watch(agentV3RecycleActorsControllerProvider);
    final isSubmitting = state.isRecycling(widget.actor.nftId);
    final tokenLabel = widget.actor.actorTokenId == null
        ? null
        : '#${widget.actor.actorTokenId}';
    final subtitle = [
      if (widget.actor.displayName.isNotEmpty) widget.actor.displayName,
      ?tokenLabel,
    ].join(' ');

    return PopScope(
      canPop: !isSubmitting,
      child: Dialog(
        key: const ValueKey('agent-v3-recycle-confirm-dialog'),
        elevation: 0,
        backgroundColor: StoryColors.backgroundOf(brightness),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          key: const ValueKey('agent-v3-recycle-dialog-surface'),
          constraints: const BoxConstraints(maxWidth: 400),
          child: MediaQuery.withNoTextScaling(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RecycleDialogHeader(
                    subtitle: subtitle,
                    isPerforming: widget.actor.isMining,
                  ),
                  const SizedBox(height: 24),
                  _RecycleEstimatePanel(
                    estimate: _estimate,
                    isLoading: _isLoading,
                    hasError: _estimateError != null,
                    onRetry: _loadEstimate,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 44,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _recycleError.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.l10n.agentV3RecyclePermanentWarning,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _recycleError,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RecycleDialogButton(
                    key: const ValueKey('agent-v3-recycle-confirm'),
                    label: _isDestructionArmed
                        ? context.l10n.agentV3RecycleConfirmAgain
                        : context.l10n.agentV3RecycleConfirm,
                    foregroundColor: _isDestructionArmed
                        ? Colors.white
                        : _recyclePrimary,
                    borderColor: _isDestructionArmed
                        ? _recyclePrimary
                        : _recyclePrimary.withValues(alpha: 0.4),
                    backgroundColor: _isDestructionArmed
                        ? _recyclePrimary
                        : null,
                    onPressed: _estimate == null || isSubmitting
                        ? null
                        : _handleConfirm,
                    isLoading: isSubmitting,
                  ),
                  const SizedBox(height: 12),
                  _RecycleDialogButton(
                    key: const ValueKey('agent-v3-recycle-cancel'),
                    label: context.l10n.commonCancel,
                    foregroundColor: StoryColors.foregroundOf(brightness),
                    borderColor: StoryColors.dividerOf(brightness),
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
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

class _RecycleDialogHeader extends StatelessWidget {
  const _RecycleDialogHeader({
    required this.subtitle,
    required this.isPerforming,
  });

  final String subtitle;
  final bool isPerforming;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Column(
      children: [
        Text(
          context.l10n.agentV3Recycle,
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
          subtitle.isEmpty ? '-' : subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.foregroundOf(brightness),
            fontSize: 14,
            height: 20 / 14,
          ),
        ),
        if (isPerforming) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0x17FFC53D),
              border: Border.all(color: const Color(0x3BFFC53D), width: 0.5),
              borderRadius: BorderRadius.circular(115),
            ),
            child: Text(
              context.l10n.agentV3RecyclePerforming,
              style: const TextStyle(
                color: _monetaryColor,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecycleEstimatePanel extends StatelessWidget {
  const _RecycleEstimatePanel({
    required this.estimate,
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final ActorNftRecycleEstimateResponse? estimate;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11.5),
      decoration: BoxDecoration(
        color: StoryColors.sheetSecondaryOf(brightness),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            context.l10n.agentV3RecycleReceive,
            style: TextStyle(
              color: StoryColors.mutedForegroundOf(brightness),
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
            ),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (hasError || estimate == null)
            GestureDetector(
              key: const ValueKey('agent-v3-recycle-estimate-retry'),
              onTap: onRetry,
              child: Text(
                context.l10n.agentV3RecycleEstimateUnavailable,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _recycleError,
                  fontSize: 12,
                  height: 16 / 12,
                ),
              ),
            )
          else
            _RecycleRewards(estimate: estimate!),
        ],
      ),
    );
  }
}

class _RecycleRewards extends StatelessWidget {
  const _RecycleRewards({required this.estimate});

  final ActorNftRecycleEstimateResponse estimate;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final valueStyle = TextStyle(
      color: StoryColors.foregroundOf(brightness),
      fontSize: 17,
      fontWeight: FontWeight.w700,
      height: 25 / 17,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              const IapPointIcon(
                key: ValueKey('agent-v3-recycle-points-icon'),
                size: 20,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  formatNumber(estimate.refundUsdcAmount),
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: valueStyle,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '+',
            style: valueStyle.copyWith(
              color: StoryColors.mutedForegroundOf(brightness),
            ),
          ),
        ),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _recycleManualAsset,
                width: 18,
                height: 20,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  estimate.refundTrainingManual,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: valueStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecycleDialogButton extends StatelessWidget {
  const _RecycleDialogButton({
    super.key,
    required this.label,
    required this.foregroundColor,
    required this.borderColor,
    required this.onPressed,
    this.backgroundColor,
    this.isLoading = false,
  });

  final String label;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        maximumSize: const Size.fromHeight(44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        foregroundColor: foregroundColor,
        disabledForegroundColor: foregroundColor.withValues(alpha: 0.45),
        backgroundColor: backgroundColor,
        disabledBackgroundColor: backgroundColor?.withValues(alpha: 0.65),
        side: BorderSide(color: borderColor, width: 1.5),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: foregroundColor,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 20 / 14,
              ),
            ),
    );
  }
}
