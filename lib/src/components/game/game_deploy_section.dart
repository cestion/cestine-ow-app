import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../controller/game_controller.dart';
import '../../controller/game_state.dart';
import '../../l10n/story_l10n.dart';
import '../../widgets/error_handler.dart';
import '../../widgets/story_cached_image.dart';
import '../../model/models.dart';
import '../../provider/app_providers.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../common/story_toast.dart';
import 'game_actor_card.dart';
import 'game_deploy_dialog.dart';
import 'game_refill_stamina_dialog.dart';
import 'game_rest_confirm_dialog.dart';

const _deployCardWidth = 280.0;
// 封面 600/500（≈233）+ 正文，预留文案换行余量
const _deployCarouselHeight = 450.0;
const _slotNavSize = 32.0;
const _slotNavGap = 6.0;

/// 派遣演员选择弹窗，与 web `GameDeployActorDialog` 对齐（数据来自 listRestActors）。
Future<void> showGameDeployDialog(BuildContext context, WidgetRef ref) async {
  final state = ref.read(gameControllerProvider);
  if (!state.canDeployMore) {
    StoryToast.error(context, context.l10n.gameDeploySlotFull);
    return;
  }

  final result = await ref
      .read(gameControllerProvider.notifier)
      .fetchRestActors();
  if (!context.mounted) return;

  if (result.isFailure) {
    handleApiError(result.errorOrNull!, ctx: context);
    return;
  }

  final actors = result.dataOrNull ?? [];
  if (actors.isEmpty) {
    StoryToast.info(context, context.l10n.gameEmptyMyActors);
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: StoryColors.overlayMedium,
    builder: (ctx) => _GameDeploySheet(actors: actors),
  );
}

class _GameDeploySheet extends ConsumerWidget {
  final List<MiningActor> actors;

  const _GameDeploySheet({required this.actors});

  Widget _avatarFallback(Brightness brightness) {
    return Container(
      width: 60,
      height: 50,
      color: brightness == Brightness.dark
          ? StoryColors.darkMuted
          : StoryColors.lightMuted,
      alignment: Alignment.center,
      child: Icon(
        Icons.person,
        color: StoryColors.mutedForegroundOf(brightness),
      ),
    );
  }

  String? _levelName(BuildContext context, int? level) {
    final l10n = context.l10n;
    return switch (level) {
      1 => l10n.gameActorLevelName1,
      2 => l10n.gameActorLevelName2,
      3 => l10n.gameActorLevelName3,
      4 => l10n.gameActorLevelName4,
      5 => l10n.gameActorLevelName5,
      _ => null,
    };
  }

  String _actorSubtitle(BuildContext context, MiningActor actor) {
    final parts = <String>[];
    if (actor.actorCode case final actorCode?) parts.add(actorCode);
    if (_levelName(context, actor.level) case final levelName?) {
      parts.add(levelName);
    }
    if (actor.level case final level?) parts.add('Lv$level');
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final staminaLimit = ref.watch(
      gameControllerProvider.select((state) => state.staminaLimit),
    );

    return Container(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.8,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
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
          const SizedBox(height: StorySpacing.base),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: StorySpacing.base,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.gameSelectActor,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 26 / 18,
                      letterSpacing: -0.04,
                      color: StoryColors.foregroundOf(brightness),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.gameSelectActorDesc,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                      color: StoryColors.mutedForegroundOf(brightness),
                    ),
                  ),
                  const SizedBox(height: StorySpacing.base),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: actors.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: StorySpacing.sm),
                      itemBuilder: (context, index) {
                        final actor = actors[index];
                        final stamina = actor.stamina;
                        final isStaminaFull = actor.isStaminaFull(staminaLimit);
                        final staminaLabel = stamina != null
                            ? '$stamina/$staminaLimit'
                            : '-';

                        return GestureDetector(
                          onTap: () async {
                            final deployed = await showGameDeployConfirmDialog(
                              context,
                              ref,
                              actor,
                            );
                            if (deployed == true && context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(StorySpacing.base),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: StoryColors.dividerOf(brightness),
                                width: 0.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: actor.avatarUrl?.isNotEmpty == true
                                      ? StoryCachedImage(
                                          imageUrl: actor.avatarUrl!,
                                          width: 60,
                                          height: 50,
                                          memCacheWidth:
                                              StoryCachedImage.memCacheForLogicalWidth(
                                                context,
                                                60,
                                              ),
                                          errorWidget: _avatarFallback(
                                            brightness,
                                          ),
                                        )
                                      : _avatarFallback(brightness),
                                ),
                                const SizedBox(width: StorySpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        actor.displayName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 24 / 16,
                                          color: StoryColors.foregroundOf(
                                            brightness,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _actorSubtitle(context, actor),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          height: 16 / 12,
                                          letterSpacing: 0.04,
                                          color: StoryColors.mutedForegroundOf(
                                            brightness,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: StorySpacing.sm),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isStaminaFull
                                          ? Icons.bolt
                                          : Icons.bolt_outlined,
                                      size: 16,
                                      color: StoryColors.brandTeal,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      staminaLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 16 / 12,
                                        letterSpacing: 0.04,
                                        color: StoryColors.mutedForegroundOf(
                                          brightness,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: StorySpacing.xl),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      side: BorderSide(
                        color: StoryColors.dividerOf(brightness),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: StorySpacing.xxl,
                        vertical: 10,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      l10n.commonCancel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        height: 20 / 14,
                        color: StoryColors.foregroundOf(brightness),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.base),
        ],
      ),
    );
  }
}

/// 横向 5 槽派遣区 + 底部槽位导航，与 web `GameDeployedActorsSection` 对齐。
class GameDeployedActorsSection extends ConsumerStatefulWidget {
  const GameDeployedActorsSection({super.key});

  @override
  ConsumerState<GameDeployedActorsSection> createState() =>
      _GameDeployedActorsSectionState();
}

class _GameDeployedActorsSectionState
    extends ConsumerState<GameDeployedActorsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSlot(int index) {
    if (!_scrollController.hasClients) return;

    const cardStride = _deployCardWidth + StorySpacing.md;
    final slotOffset = index * cardStride;
    final viewport = _scrollController.position.viewportDimension;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final target = (slotOffset + _deployCardWidth - viewport).clamp(
      0.0,
      maxScroll,
    );

    _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slots = ref.watch(
      gameControllerProvider.select((s) => s.deploySlots),
    );
    final staminaLimit = ref.watch(
      gameControllerProvider.select((s) => s.staminaLimit),
    );
    final canDeployMore = ref.watch(
      gameControllerProvider.select((s) => s.canDeployMore),
    );
    final notifier = ref.read(gameControllerProvider.notifier);

    return Column(
      children: [
        SizedBox(
          height: _deployCarouselHeight,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: slots.length,
            separatorBuilder: (_, _) => const SizedBox(width: StorySpacing.md),
            itemBuilder: (context, index) {
              final actor = slots[index];
              if (actor == null) {
                return SizedBox(
                  width: _deployCardWidth,
                  height: _deployCarouselHeight,
                  child: GameDeployEmptySlot(
                    onTap: canDeployMore
                        ? () => showGameDeployDialog(context, ref)
                        : () => StoryToast.error(
                            context,
                            context.l10n.gameDeploySlotFull,
                          ),
                  ),
                );
              }

              // horizontal ListView 交叉轴为 tight 高度；Align 放开后让卡片按内容高度布局，避免内部 Row 约束异常
              return RepaintBoundary(
                child: SizedBox(
                  width: _deployCardWidth,
                  height: _deployCarouselHeight,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: GameActorCard(
                      actor: actor,
                      staminaLimit: staminaLimit,
                      onSupplement: () =>
                          showGameRefillStaminaDialog(context, ref, actor),
                      onRest: () => _confirmRest(context, ref, notifier, actor),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: StorySpacing.md),
        GameDeploySlotNav(slots: slots, onSelect: _scrollToSlot),
      ],
    );
  }

  Future<void> _confirmRest(
    BuildContext context,
    WidgetRef ref,
    GameController notifier,
    MiningActor actor,
  ) async {
    final gameState = ref.read(gameControllerProvider);
    final feeAmount = ref
        .read(gameControllerProvider.notifier)
        .supplyFeeForLevel(actor.level);
    final ok = await showGameRestConfirmDialogWithMeta(
      context,
      actor,
      staminaLimit: gameState.staminaLimit,
      restoreFeeLabel: feeAmount != null
          ? '${feeAmount.toStringAsFixed(1)} ${context.l10n.currency}'
          : null,
    );
    if (ok != true || !context.mounted) return;

    final rested = await notifier.rest(actor.nftId);
    if (!context.mounted) return;
    if (!rested) {
      final err = ref.read(gameControllerProvider).lastError;
      if (err != null) handleApiError(err, ctx: context);
    } else {
      StoryToast.success(context, context.l10n.gameRestSuccessToast);
    }
  }
}

/// 底部 5 槽位导航，点击滚动到对应派遣卡。
class GameDeploySlotNav extends StatelessWidget {
  final List<MiningActor?> slots;
  final ValueChanged<int> onSelect;

  const GameDeploySlotNav({
    super.key,
    required this.slots,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < gameDeploySlotCount; i++) ...[
            if (i > 0) const SizedBox(width: _slotNavGap),
            _GameDeploySlotNavItem(
              actor: i < slots.length ? slots[i] : null,
              onTap: () => onSelect(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _GameDeploySlotNavItem extends StatelessWidget {
  final MiningActor? actor;
  final VoidCallback onTap;

  const _GameDeploySlotNavItem({required this.actor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = actor?.avatarUrl?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: _slotNavSize,
          height: _slotNavSize,
          child: avatarUrl != null && avatarUrl.isNotEmpty
              ? ClipOval(
                  child: StoryCachedImage(
                    imageUrl: avatarUrl,
                    width: _slotNavSize,
                    height: _slotNavSize,
                    memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                      context,
                      _slotNavSize,
                    ),
                    errorWidget: _emptyAvatar(),
                  ),
                )
              : _emptyAvatar(),
        ),
      ),
    );
  }

  Widget _emptyAvatar() {
    return SvgPicture.asset(
      'assets/game/game_deploy_slot_empty.svg',
      width: _slotNavSize,
      height: _slotNavSize,
    );
  }
}
