import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../routes/route_names.dart';
import '../../../styles/story_colors.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_loading.dart';
import 'agent_v2_upgrade_confirm_dialog.dart';
import 'agent_v2_upgrade_requirements_dialog.dart';
import 'agent_v2_salary_detail_dialog.dart';
import '../../../foundation/navigator.dart';

const _defaultAvatarLight = 'assets/common/avatar.svg';
const _defaultAvatarDark = 'assets/common/avatar_d.svg';

Future<void> showAgentV2UpgradeableActorsSheet(BuildContext context) {
  final sheetColor = StoryColors.cardOf(Theme.of(context).brightness);
  // 每次打开弹窗都立即回源校准；Provider 可能被顶栏持有，不能只复用
  // 上一次加载后保留的缓存数据。
  unawaited(
    ProviderScope.containerOf(
      context,
    ).read(agentV2UpgradeableActorsControllerProvider.notifier).refresh(),
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
    builder: (_) => const AgentV2UpgradeableActorsSheet(),
  );
}

/// Figma `198:44145`：「升级角色」分页 bottom sheet。
class AgentV2UpgradeableActorsSheet extends ConsumerStatefulWidget {
  const AgentV2UpgradeableActorsSheet({super.key});

  @override
  ConsumerState<AgentV2UpgradeableActorsSheet> createState() =>
      _AgentV2UpgradeableActorsSheetState();
}

class _AgentV2UpgradeableActorsSheetState
    extends ConsumerState<AgentV2UpgradeableActorsSheet> {
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
      ref.read(agentV2UpgradeableActorsControllerProvider.notifier).loadMore(),
    );
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
    final state = ref.watch(agentV2UpgradeableActorsControllerProvider);
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
            mainAxisSize: MainAxisSize.min,
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
                    height: 220,
                    child: StoryLoading.centered(),
                  ),
                  (false, final error?, final actors) when actors.isEmpty =>
                    SizedBox(
                      height: 220,
                      child: _InitialError(
                        message: error.userMessage,
                        onRetry: () => ref
                            .read(
                              agentV2UpgradeableActorsControllerProvider
                                  .notifier,
                            )
                            .refresh(),
                      ),
                    ),
                  (false, _, final actors) when actors.isEmpty => SizedBox(
                    height: 220,
                    child: _EmptyActors(
                      message: context.l10n.agentV2UpgradeableActorsEmpty,
                    ),
                  ),
                  _ => LayoutBuilder(
                    builder: (context, constraints) {
                      final cardWidth = (constraints.maxWidth - 24) / 2;
                      return GridView.builder(
                        key: const ValueKey('agent-v2-upgradeable-actors-grid'),
                        controller: _scrollController,
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          mainAxisExtent: cardWidth * 0.75 + 236,
                        ),
                        itemCount:
                            state.actors.length + (state.isLoadingMore ? 2 : 0),
                        itemBuilder: (context, index) {
                          if (index >= state.actors.length) {
                            return const StoryLoading.centered(size: 20);
                          }
                          return _UpgradeableActorCard(
                            actor: state.actors[index],
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
                color: StoryColors.sheetSecondaryOf(brightness),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
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
      ],
    );
  }
}

class _UpgradeableActorCard extends ConsumerWidget {
  final MiningActor actor;

  const _UpgradeableActorCard({required this.actor});

  Future<void> _openUpgrade(BuildContext context, WidgetRef ref) async {
    final upgraded = await showAgentV2UpgradeConfirmDialog(context, ref, actor);
    if (!upgraded || !context.mounted) return;
    ref.read(weeklySalaryControllerProvider.notifier).refreshAfterMutation();
    await ref
        .read(agentV2UpgradeableActorsControllerProvider.notifier)
        .refreshAfterUpgrade();
  }

  Future<void> _showRequirements(
    BuildContext context,
    WidgetRef ref, {
    required int completionRemaining,
    required int materialRemaining,
  }) async {
    await showAgentV2UpgradeRequirementsDialog(
      context,
      actorName: actor.displayName,
      actorCode: actor.actorCode,
      completionRemaining: completionRemaining,
      materialRemaining: materialRemaining,
      onWatchDramas: () => _openActorFromRequirements(context, ref),
      onGetActors: () => _openActorFromRequirements(context, ref),
      onCreateDrama: () => _openCreateDrama(context),
    );
  }

  Future<void> _handleUpgrade(
    BuildContext context,
    WidgetRef ref, {
    required bool completionMet,
    required int completionRemaining,
    required bool materialMet,
    required int materialRemaining,
  }) async {
    if (!completionMet || !materialMet) {
      await _showRequirements(
        context,
        ref,
        completionRemaining: completionRemaining,
        materialRemaining: materialRemaining,
      );
      return;
    }

    await _openUpgrade(context, ref);
  }

  void _openActorFromRequirements(
    BuildContext context,
    WidgetRef ref, {
    int initialTabIndex = 0,
  }) {
    Navigator.of(context, rootNavigator: true).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      unawaited(
        _openActorDetail(context, ref, initialTabIndex: initialTabIndex),
      );
    });
  }

  void _openCreateDrama(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    navigator.popUntil((route) => route.isFirst);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!navigator.mounted) return;
      context.storyPush(RouteNames.createDrama);
    });
  }

  Future<void> _openActorDetail(
    BuildContext context,
    WidgetRef ref, {
    int initialTabIndex = 0,
  }) async {
    final actorId = actor.actorCollectionId?.toString();
    if (actorId == null) return;
    await openActorDetail(
      context,
      actorId: actorId,
      initialTabIndex: initialTabIndex,
      preview: ActorCollection(
        id: actorId,
        name: actor.actorName,
        avatarUrl: actor.avatarUrl,
        heatValue: actor.heat,
        trust: actor.trust,
        computingPower: actor.computingPower,
      ),
    );
    if (!context.mounted) return;
    await ref
        .read(agentV2UpgradeableActorsControllerProvider.notifier)
        .refreshActor(actor);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final actorNftConfig = ref
        .watch(globalConfigProvider)
        .whenOrNull(data: (result) => result.dataOrNull?.init?.actorNft);
    final currentLevel = actor.level ?? 0;
    final upgrade = actorNftConfig?.levels?['$currentLevel']?.upgrade;
    final targetLevel = upgrade?.toLevel ?? currentLevel + 1;
    final targetCoefficient =
        actorNftConfig?.levels?['$targetLevel']?.miningCoefficient;
    final currentHourlySalary = getMiningActorHourlySalary(actor);
    final breakdown = getMiningActorPowerBreakdown(actor);
    final targetHourlySalary = targetCoefficient == null
        ? null
        : truncatePower(
            breakdown.ipPower *
                targetCoefficient *
                breakdown.cpCoefficient *
                breakdown.trust2,
            10,
          );
    final completionCurrent = actor.completedPlayCount ?? 0;
    final completionRequired = upgrade?.heatThreshold ?? 0;
    final completionMet =
        actor.completePlayThresholdMet == true ||
        completionRequired <= 0 ||
        completionCurrent >= completionRequired;
    final completionRemaining = completionRequired > completionCurrent
        ? completionRequired - completionCurrent
        : 0;
    final materialCurrent = actor.materialCount ?? 0;
    final materialRequired = upgrade?.requiredMaterialCount ?? 2;
    final materialMet = materialCurrent >= materialRequired;
    final materialRemaining = materialRequired > materialCurrent
        ? materialRequired - materialCurrent
        : 0;
    final canUpgrade = completionMet && materialMet;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: brightness == Brightness.dark
            ? StoryColors.sheetSecondaryOf(brightness)
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
                  : () => unawaited(_openActorDetail(context, ref)),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ActorCover(actor: actor),
                    if (actor.level != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                          decoration: const BoxDecoration(
                            color: Color(0x80006FFF),
                            borderRadius: BorderRadius.only(
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
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ActorName(
                    actor: actor,
                    onTap: actor.actorCollectionId == null
                        ? null
                        : () => unawaited(_openActorDetail(context, ref)),
                  ),
                  const SizedBox(height: 8),
                  _UpgradeSummary(
                    actor: actor,
                    currentLevel: currentLevel,
                    targetLevel: targetLevel,
                    currentHourlySalary: currentHourlySalary,
                    targetHourlySalary: targetHourlySalary,
                  ),
                  const SizedBox(height: 8),
                  _RequirementProgress(
                    label: context.l10n.agentV2UpgradeCompletion,
                    current: completionCurrent,
                    required: completionRequired,
                    isMet: completionMet,
                    onPlusTap: () => unawaited(
                      _showRequirements(
                        context,
                        ref,
                        completionRemaining: completionRemaining,
                        materialRemaining: materialRemaining,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RequirementProgress(
                    label: context.l10n.agentV2UpgradeMaterials,
                    current: materialCurrent,
                    required: materialRequired,
                    isMet: materialMet,
                    onPlusTap: () => unawaited(
                      _showRequirements(
                        context,
                        ref,
                        completionRemaining: completionRemaining,
                        materialRemaining: materialRemaining,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Material(
                    color: canUpgrade
                        ? StoryColors.darkButtonBgOf(brightness)
                        : StoryColors.darkButtonBgOf(
                            brightness,
                          ).withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey('upgrade-actor-${actor.nftId}'),
                      onTap: canUpgrade
                          ? () => unawaited(
                              _handleUpgrade(
                                context,
                                ref,
                                completionMet: completionMet,
                                completionRemaining: completionRemaining,
                                materialMet: materialMet,
                                materialRemaining: materialRemaining,
                              ),
                            )
                          : null,
                      child: SizedBox(
                        height: 36,
                        child: Center(
                          child: Text(
                            context.l10n.agentV2UpgradeNow,
                            style: TextStyle(
                              color: canUpgrade
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              height: 20 / 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActorCover extends StatelessWidget {
  final MiningActor actor;

  const _ActorCover({required this.actor});

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
        Expanded(
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
          Text(
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
        ],
      ],
    );
  }
}

class _UpgradeSummary extends StatelessWidget {
  final MiningActor actor;
  final int currentLevel;
  final int targetLevel;
  final double currentHourlySalary;
  final double? targetHourlySalary;

  const _UpgradeSummary({
    required this.actor,
    required this.currentLevel,
    required this.targetLevel,
    required this.currentHourlySalary,
    required this.targetHourlySalary,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(brightness),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LevelPill(
                level: currentLevel,
                color: StoryColors.buttonDisabledForeground,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.chevron_right, size: 16),
              ),
              _LevelPill(level: targetLevel, color: const Color(0x800CA87F)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text:
                        '${formatNumber(currentHourlySalary)} → '
                        '${targetHourlySalary == null ? '-' : formatNumber(targetHourlySalary!)}',
                    style: TextStyle(
                      color: StoryColors.foregroundOf(brightness),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                    ),
                  ),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      key: ValueKey(
                        'upgrade-hourly-salary-link-${actor.nftId}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: () =>
                          showAgentV2SalaryDetailDialog(context, actor),
                      child: Text(
                        ' STORY/h',
                        style: TextStyle(
                          color: StoryColors.mutedForegroundOf(brightness),
                          fontSize: 10,
                          height: 12 / 10,
                          letterSpacing: 0.08,
                          decoration: TextDecoration.underline,
                          decorationStyle: TextDecorationStyle.dotted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  final int level;
  final Color color;

  const _LevelPill({required this.level, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(52),
      ),
      child: Text(
        'Lv$level',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          letterSpacing: 0.04,
        ),
      ),
    );
  }
}

class _RequirementProgress extends StatelessWidget {
  final String label;
  final int current;
  final int required;
  final bool isMet;
  final VoidCallback? onPlusTap;

  const _RequirementProgress({
    required this.label,
    required this.current,
    required this.required,
    required this.isMet,
    this.onPlusTap,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final trackColor = brightness == Brightness.dark
        ? StoryColors.darkBackground
        : StoryColors.sheetSecondaryOf(brightness);
    final progress = required <= 0
        ? (isMet ? 1.0 : 0.0)
        : (current / required).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: !isMet ? onPlusTap : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: StoryColors.foregroundOf(brightness),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                ),
              ),
              const Spacer(),
              if (isMet)
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: StoryColors.cardOf(brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    size: 12,
                    color: StoryColors.foregroundOf(brightness),
                  ),
                )
              else
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: StoryColors.cardOf(brightness),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    size: 12,
                    color: StoryColors.foregroundOf(brightness),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          SizedBox(
            height: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(color: trackColor),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress,
                    child: const ColoredBox(color: StoryColors.success),
                  ),
                  Center(
                    child: Text(
                      '$current/$required',
                      style: TextStyle(
                        color: progress >= 0.45
                            ? StoryColors.onOverlayMuted
                            : StoryColors.mutedForegroundOf(brightness),
                        fontSize: 11,
                        height: 13 / 11,
                        letterSpacing: 0.04,
                      ),
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
  final String message;

  const _EmptyActors({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: TextStyle(
          color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
        ),
      ),
    );
  }
}
