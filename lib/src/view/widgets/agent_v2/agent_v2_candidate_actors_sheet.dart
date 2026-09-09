import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_loading.dart';
import '../../../widgets/story_state_widget.dart';
import '../agent_performance_confirm_dialog.dart';
import 'agent_v2_hourly_salary_text.dart';
import 'agent_v2_refill_stamina_dialog.dart';

const _staminaAsset = 'assets/game_v2/agent_candidate_stamina.svg';
const _refillAsset = 'assets/game_v2/agent_candidate_refill.svg';
const _refillLineAsset = 'assets/game_v2/agent_candidate_refill_horizontal.svg';
const _performAsset = 'assets/game_v2/agent_candidate_perform.svg';
const _defaultAvatarLight = 'assets/common/avatar.svg';
const _defaultAvatarDark = 'assets/common/avatar_d.svg';

Future<void> showAgentV2CandidateActorsSheet(BuildContext context) {
  final sheetColor = StoryColors.cardOf(Theme.of(context).brightness);
  // 每次打开弹窗都立即回源校准；Provider 可能被主页面持有，不能把已有
  // 内存/磁盘缓存当作本次打开的数据来源。
  unawaited(
    ProviderScope.containerOf(
      context,
    ).read(agentV2CandidateActorsControllerProvider.notifier).refresh(),
  );
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: sheetColor,
    barrierColor: StoryColors.overlayMid,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    clipBehavior: Clip.antiAlias,
    showDragHandle: false,
    useSafeArea: true,
    builder: (_) => const AgentV2CandidateActorsSheet(),
  );
}

/// Figma `198:44125`：候选角色分页 bottom sheet。
class AgentV2CandidateActorsSheet extends ConsumerStatefulWidget {
  const AgentV2CandidateActorsSheet({super.key});

  @override
  ConsumerState<AgentV2CandidateActorsSheet> createState() =>
      _AgentV2CandidateActorsSheetState();
}

class _AgentV2CandidateActorsSheetState
    extends ConsumerState<AgentV2CandidateActorsSheet> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter >= 240) {
      return;
    }
    unawaited(
      ref.read(agentV2CandidateActorsControllerProvider.notifier).loadMore(),
    );
  }

  void _openActorIpTab() {
    ref.read(tabIndexProvider.notifier).setIndex(StoryTab.nft.index);
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final state = ref.watch(agentV2CandidateActorsControllerProvider);
    final staminaLimit = ref.watch(
      gameControllerProvider.select((value) => value.staminaLimit),
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
              Flexible(
                child: switch ((
                  state.isLoading,
                  state.lastError,
                  state.actors,
                )) {
                  (true, _, _) => const SizedBox(
                    height: 180,
                    child: StoryLoading.centered(),
                  ),
                  (false, final error?, final actors) when actors.isEmpty =>
                    SizedBox(
                      height: 180,
                      child: _InitialError(
                        message: error.userMessage,
                        onRetry: () => ref
                            .read(
                              agentV2CandidateActorsControllerProvider.notifier,
                            )
                            .refresh(),
                      ),
                    ),
                  (false, _, final actors) when actors.isEmpty => _EmptyActors(
                    onAddActor: _openActorIpTab,
                  ),
                  _ => LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 24) / 2;
                      return GridView.builder(
                        key: const ValueKey('agent-v2-candidate-grid'),
                        controller: _scrollController,
                        padding: EdgeInsets.fromLTRB(
                          8,
                          0,
                          8,
                          8 + MediaQuery.paddingOf(context).bottom,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: cardWidth * 0.75 + 138,
                        ),
                        itemCount:
                            state.actors.length + (state.isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.actors.length) {
                            return const StoryLoading.centered(size: 20);
                          }
                          return _CandidateActorCard(
                            actor: state.actors[index],
                            staminaLimit: staminaLimit,
                          );
                        },
                      );
                    },
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
          context.l10n.agentV2CandidateActorsTitle,
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
          context.l10n.agentV2CandidateActorsDescription,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: StoryColors.mutedForegroundOf(brightness),
            fontSize: 12,
            fontWeight: FontWeight.w400,
            height: 16 / 12,
            letterSpacing: 0.04,
          ),
        ),
      ],
    );
  }
}

class _CandidateActorCard extends StatelessWidget {
  final MiningActor actor;
  final int staminaLimit;

  const _CandidateActorCard({required this.actor, required this.staminaLimit});

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
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? StoryColors.darkMuted
            : StoryColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 20,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: actor.actorCollectionId == null
                  ? null
                  : () => unawaited(_openActorDetail(context)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _CandidateActorCover(actor: actor),
                    if (actor.level != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: _levelBadgeColor(actor.level!),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Lv${actor.level}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ActorName(
                      actor: actor,
                      onTap: actor.actorCollectionId == null
                          ? null
                          : () => unawaited(_openActorDetail(context)),
                    ),
                    const SizedBox(height: 8),
                    _ActorEarnings(actor: actor, staminaLimit: staminaLimit),
                    const Spacer(),
                    _ActorActions(
                      actor: actor,
                      isStaminaFull: actor.isStaminaFull(staminaLimit),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateActorCover extends StatelessWidget {
  final MiningActor actor;

  const _CandidateActorCover({required this.actor});

  @override
  Widget build(BuildContext context) {
    final url = actor.avatarUrl?.trim();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallback = SvgPicture.asset(
      isDark ? _defaultAvatarDark : _defaultAvatarLight,
      fit: BoxFit.cover,
    );
    if (url == null || url.isEmpty) return fallback;
    return StoryCachedImage(
      imageUrl: url,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(context, 200),
      errorWidget: fallback,
    );
  }
}

class _ActorName extends StatelessWidget {
  final MiningActor actor;
  final VoidCallback? onTap;

  const _ActorName({required this.actor, this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final actorCode = actor.actorCode;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Text(
              actor.displayName.isEmpty ? '-' : actor.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 24 / 16,
              ),
            ),
          ),
        ),
        if (actorCode != null) ...[
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              actorCode,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: StoryColors.mutedForegroundOf(brightness),
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

class _ActorEarnings extends StatelessWidget {
  final MiningActor actor;
  final int staminaLimit;

  const _ActorEarnings({required this.actor, required this.staminaLimit});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final currentStamina = actor.stamina ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  key: ValueKey('candidate-stamina-${actor.nftId}'),
                  value: actor.staminaProgress(staminaLimit) ?? 0,
                  minHeight: 6,
                  backgroundColor: brightness == Brightness.dark
                      ? StoryColors.darkBackground
                      : StoryColors.lightSheetSecondary,
                  valueColor: const AlwaysStoppedAnimation(StoryColors.success),
                ),
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(_staminaAsset, width: 16, height: 16),
            const SizedBox(width: 2),
            Text(
              '$currentStamina/$staminaLimit',
              style: TextStyle(
                color: StoryColors.foregroundOf(brightness),
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        AgentV2HourlySalaryText(actor: actor),
      ],
    );
  }
}

class _ActorActions extends ConsumerWidget {
  final MiningActor actor;
  final bool isStaminaFull;

  const _ActorActions({required this.actor, required this.isStaminaFull});

  Future<void> _refillStamina(BuildContext context, WidgetRef ref) async {
    final didRefill = await showAgentV2RefillStaminaDialog(context, ref, actor);
    if (!didRefill || !context.mounted) return;

    final staminaLimit = ref.read(gameControllerProvider).staminaLimit;
    ref
        .read(agentV2CandidateActorsControllerProvider.notifier)
        .markStaminaRefilled(actor.nftId, staminaLimit);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final refillColor = isStaminaFull
        ? StoryColors.buttonDisabledForegroundOf(brightness)
        : StoryColors.foregroundOf(brightness);
    return Row(
      children: [
        Expanded(
          child: _CandidateActionButton(
            semanticLabel: context.l10n.gameRefillTitle,
            borderColor: isStaminaFull
                ? StoryColors.buttonDisabledForegroundOf(brightness)
                : StoryColors.dividerOf(brightness),
            onTap: isStaminaFull ? null : () => _refillStamina(context, ref),
            child: SizedBox.square(
              dimension: 20,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SvgPicture.asset(
                    _refillAsset,
                    width: 15,
                    height: 15,
                    colorFilter: ColorFilter.mode(refillColor, BlendMode.srcIn),
                  ),
                  SvgPicture.asset(
                    _refillLineAsset,
                    width: 6.25,
                    height: 1.25,
                    colorFilter: ColorFilter.mode(refillColor, BlendMode.srcIn),
                  ),
                  Transform.rotate(
                    angle: 1.5707963267948966,
                    child: SvgPicture.asset(
                      _refillLineAsset,
                      width: 6.25,
                      height: 1.25,
                      colorFilter: ColorFilter.mode(
                        refillColor,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CandidateActionButton(
            semanticLabel: context.l10n.agentV2SchedulePerformance,
            backgroundColor: StoryColors.darkButtonBgOf(brightness),
            onTap: () => showAgentPerformanceConfirmDialog(
              context,
              ref,
              actor,
              hasVacantSlot: ref.read(gameControllerProvider).canDeployMore,
              onScheduled: () => unawaited(
                ref
                    .read(gameControllerProvider.notifier)
                    .refreshDeployedActors(bypassCache: true),
              ),
            ),
            child: SvgPicture.asset(_performAsset, width: 20, height: 20),
          ),
        ),
      ],
    );
  }
}

class _CandidateActionButton extends StatelessWidget {
  final String semanticLabel;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Widget child;

  const _CandidateActionButton({
    required this.semanticLabel,
    required this.child,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
  });

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
          child: SizedBox(height: 36, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _InitialError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _InitialError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

class _EmptyActors extends StatelessWidget {
  final VoidCallback onAddActor;

  const _EmptyActors({required this.onAddActor});

  @override
  Widget build(BuildContext context) {
    return StoryStateWidget.empty(
      key: const ValueKey('agent-v2-candidate-empty'),
      message: context.l10n.agentV2NoActors,
      compact: true,
      iconSize: 88,
      action: SizedBox.square(
        dimension: 44,
        child: IconButton(
          key: const ValueKey('agent-v2-candidate-add'),
          tooltip: context.l10n.navNftIp,
          onPressed: onAddActor,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 44, height: 44),
          icon: SvgPicture.asset(
            'assets/game_v2/agent_add_actor.svg',
            width: 68,
            height: 36,
          ),
        ),
      ),
    );
  }
}

Color _levelBadgeColor(int level) => switch (level) {
  2 => const Color(0x800CA87F),
  3 => const Color(0x80CF8A37),
  4 => const Color(0x80CF4F5B),
  5 => const Color(0x807244E4),
  _ => const Color(0x80006FFF),
};
