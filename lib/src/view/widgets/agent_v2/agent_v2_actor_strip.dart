import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/format_number.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_loading.dart';
import '../../../widgets/story_state_widget.dart';
import '../agent_performance_confirm_dialog.dart';
import 'agent_v2_candidate_actors_sheet.dart';

const _maxActorCount = 5;

/// 经纪人 V2 底部五个候场演员小卡片。
class AgentV2ActorStrip extends ConsumerWidget {
  const AgentV2ActorStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final staminaLimit = ref.watch(
      gameControllerProvider.select((state) => state.staminaLimit),
    );
    final restActors = ref.watch(agentV2CandidateActorsControllerProvider);
    // 网络校准会替换共享候选列表的第一页；候场条始终从该页重新截取
    // 前五条，确保五个可见候选一起切换为校准后的数据。
    final visibleActors = restActors.actors
        .take(_maxActorCount)
        .toList(growable: false);
    final hasRestActors = visibleActors.isNotEmpty;
    final hasNoRestActors =
        restActors.isInitialized && restActors.actors.isEmpty;

    return Container(
      height: hasNoRestActors ? 136 : 118,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          bottom: BorderSide(
            color: StoryColors.borderOf(brightness),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: hasNoRestActors
            ? const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: StorySpacing.sm,
              )
            : const EdgeInsets.fromLTRB(16, 16, 16, 15.5),
        child: Stack(
          children: [
            if (restActors.isLoading && !restActors.isInitialized)
              const StoryLoading.centered()
            else if (restActors.actors.isEmpty)
              if (restActors.isInitialized)
                _ActorStripEmptyState(
                  onAddActor: () => ref
                      .read(tabIndexProvider.notifier)
                      .setIndex(StoryTab.nft.index),
                )
              else
                const SizedBox.shrink()
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final actor in visibleActors)
                    _ActorStripCard(actor: actor, staminaLimit: staminaLimit),
                  for (int i = visibleActors.length; i < _maxActorCount; i++)
                    const SizedBox(width: 56),
                ],
              ),
            if (hasRestActors)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  key: const ValueKey('agent-v2-actor-strip-more'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showAgentV2CandidateActorsSheet(context),
                  child: Container(
                    width: 36,
                    height: 86,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          StoryColors.cardOf(brightness).withValues(alpha: 0),
                          StoryColors.cardOf(
                            brightness,
                          ).withValues(alpha: 0.86),
                        ],
                      ),
                    ),
                    child: Icon(
                      Icons.chevron_right,
                      size: 24,
                      color: StoryColors.foregroundOf(brightness),
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

class _ActorStripEmptyState extends StatelessWidget {
  final VoidCallback onAddActor;

  const _ActorStripEmptyState({required this.onAddActor});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: StoryStateWidget.empty(
        key: const ValueKey('agent-v2-actor-strip-empty'),
        message: context.l10n.agentV2NoActors,
        compact: true,
        iconSize: 40,
        action: SizedBox.square(
          dimension: 44,
          child: IconButton(
            key: const ValueKey('agent-v2-actor-strip-add'),
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
      ),
    );
  }
}

class _ActorStripCard extends ConsumerWidget {
  final MiningActor actor;
  final int staminaLimit;

  const _ActorStripCard({required this.actor, required this.staminaLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final trackColor = brightness == Brightness.dark
        ? StoryColors.darkMuted
        : StoryColors.lightSheetSecondary;
    final hourlySalary = getMiningActorHourlySalary(actor);
    final nftId = actor.nftId;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: nftId.isEmpty
          ? null
          : () => showAgentPerformanceConfirmDialog(
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
      child: SizedBox(
        width: 56,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ActorStripImage(actor: actor),
                    if (actor.level != null)
                      Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                          decoration: BoxDecoration(
                            color: _badgeColor(actor.level!),
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
            const SizedBox(height: 6),
            Text(
              '${formatNumber(hourlySalary)} /h',
              maxLines: 1,
              style: const TextStyle(
                color: StoryColors.lightTertiaryText,
                fontSize: 12,
                height: 16 / 12,
                letterSpacing: 0.04,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: actor.staminaProgress(staminaLimit) ?? 0,
                minHeight: 4,
                backgroundColor: trackColor,
                valueColor: const AlwaysStoppedAnimation(StoryColors.success),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActorStripImage extends StatelessWidget {
  final MiningActor actor;

  const _ActorStripImage({required this.actor});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = actor.avatarUrl?.trim();
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return const _ActorStripImageFallback();
    }
    return StoryCachedImage(
      imageUrl: avatarUrl,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(context, 56),
      placeholder: const StoryLoading.centered(size: 18, strokeWidth: 2),
      errorWidget: const _ActorStripImageFallback(),
    );
  }
}

class _ActorStripImageFallback extends StatelessWidget {
  const _ActorStripImageFallback();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return ColoredBox(
      color: StoryColors.mutedOf(brightness),
      child: Icon(
        Icons.person,
        size: 24,
        color: StoryColors.mutedForegroundOf(brightness),
      ),
    );
  }
}

Color _badgeColor(int level) => switch (level) {
  2 => const Color(0x800CA87F),
  3 => const Color(0x80CF8A37),
  4 => const Color(0x80CF4F5B),
  5 => const Color(0x807244E4),
  _ => const Color(0x80006FFF),
};
