import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_loading.dart';
import 'agent_v2_candidate_actors_sheet.dart';
import 'agent_v2_hourly_salary_text.dart';
import 'agent_v2_refill_stamina_dialog.dart';
import 'agent_v2_rest_confirm_dialog.dart';

const _defaultAvatarLight = 'assets/common/avatar.svg';
const _defaultAvatarDark = 'assets/common/avatar_d.svg';
const _miningSlotCount = 5;
const _miningCardHorizontalMargin = 16.0;
const _miningCardDetailsHeight = 161.314;

/// 经纪人 V2 的 5 个固定挖矿槽位。
class AgentV2MiningCardList extends ConsumerStatefulWidget {
  const AgentV2MiningCardList({super.key});

  @override
  ConsumerState<AgentV2MiningCardList> createState() =>
      _AgentV2MiningCardListState();
}

class _AgentV2MiningCardListState extends ConsumerState<AgentV2MiningCardList> {
  final _pageController = PageController();
  var _selectedIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectSlot(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _restActor(MiningActor actor) async {
    await showAgentV2RestConfirmDialog(context, actor);
  }

  Future<void> _openActorDetail(MiningActor actor) {
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
    final slots = ref.watch(
      gameControllerProvider.select((state) => state.deploySlots),
    );
    final staminaLimit = ref.watch(
      gameControllerProvider.select((state) => state.agentV2StaminaLimit),
    );
    final isLoading = ref.watch(
      gameControllerProvider.select((state) => state.isLoading),
    );
    final isActionLoading = ref.watch(
      gameControllerProvider.select((state) => state.isActionLoading),
    );
    final lastError = ref.watch(
      gameControllerProvider.select((state) => state.lastError),
    );

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: _miningSlotCount,
          onPageChanged: (index) => setState(() => _selectedIndex = index),
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _miningCardHorizontalMargin,
            ),
            child: switch (slots[index]) {
              final actor? => AgentV2MiningCard(
                actor: actor,
                staminaLimit: staminaLimit,
                actionsEnabled: !isActionLoading,
                onOpenDetail: actor.actorCollectionId == null
                    ? null
                    : () => unawaited(_openActorDetail(actor)),
                onSupplement: () => showAgentV2RefillStaminaDialog(
                  context,
                  ref,
                  actor,
                  showRefillAll: true,
                ),
                onRest: () => _restActor(actor),
              ),
              null when index == 0 && isLoading => const _LoadingMiningCard(),
              null when index == 0 && lastError != null => _ErrorMiningCard(
                onRetry: () => ref
                    .read(gameControllerProvider.notifier)
                    .refreshDeployedActors(force: true),
              ),
              _ => _EmptyMiningCard(
                onTap: () async {
                  await showAgentV2CandidateActorsSheet(context);
                },
              ),
            },
          ),
        ),
        Positioned.fill(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    _miningCardHorizontalMargin + 12,
                    16,
                    _miningCardHorizontalMargin + 12,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedIndex > 0)
                        _RoundArrow(
                          icon: Icons.chevron_left,
                          onPressed: () => _selectSlot(_selectedIndex - 1),
                        )
                      else
                        const SizedBox.square(dimension: 44),
                      if (_selectedIndex < _miningSlotCount - 1)
                        _RoundArrow(
                          icon: Icons.chevron_right,
                          onPressed: () => _selectSlot(_selectedIndex + 1),
                        )
                      else
                        const SizedBox.square(dimension: 44),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: _miningCardDetailsHeight),
            ],
          ),
        ),
        Positioned(
          bottom: 12,
          child: _PageDiamonds(
            selectedIndex: _selectedIndex,
            slots: slots,
            staminaLimit: staminaLimit,
            onSelected: _selectSlot,
          ),
        ),
      ],
    );
  }
}

/// 经纪人 V2 正在挖矿演员卡片。
class AgentV2MiningCard extends StatelessWidget {
  final MiningActor actor;
  final int? staminaLimit;
  final bool actionsEnabled;
  final VoidCallback? onOpenDetail;
  final VoidCallback onSupplement;
  final VoidCallback onRest;

  const AgentV2MiningCard({
    super.key,
    required this.actor,
    required this.staminaLimit,
    required this.actionsEnabled,
    this.onOpenDetail,
    required this.onSupplement,
    required this.onRest,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        border: Border.all(color: agentV2MiningSlotColor(actor, staminaLimit)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x21000000),
            offset: Offset(1, 5),
            blurRadius: 20,
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
              child: Row(
                children: [
                  const SizedBox.square(dimension: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        height: 207,
                        width: 207,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: onOpenDetail,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                _MiningActorImage(actor: actor),
                                if (actor.level != null)
                                  Align(
                                    alignment: Alignment.topLeft,
                                    child: _LevelBadge(level: actor.level!),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const SizedBox.square(dimension: 44),
                ],
              ),
            ),
          ),
          _MiningCardDetails(
            actor: actor,
            staminaLimit: staminaLimit,
            actionsEnabled: actionsEnabled,
            onOpenDetail: onOpenDetail,
            onSupplement: onSupplement,
            onRest: onRest,
          ),
        ],
      ),
    );
  }
}

class _MiningCardDetails extends StatelessWidget {
  final MiningActor actor;
  final int? staminaLimit;
  final bool actionsEnabled;
  final VoidCallback? onOpenDetail;
  final VoidCallback onSupplement;
  final VoidCallback onRest;

  const _MiningCardDetails({
    required this.actor,
    required this.staminaLimit,
    required this.actionsEnabled,
    required this.onOpenDetail,
    required this.onSupplement,
    required this.onRest,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = StoryColors.mutedForegroundOf(brightness);
    final stamina = actor.stamina;
    final isStaminaFull =
        staminaLimit != null && actor.isStaminaFull(staminaLimit!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 35.314),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onOpenDetail,
                  child: Text(
                    actor.displayName.isEmpty ? '-' : actor.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
              if (actor.actorCode != null) ...[
                const SizedBox(width: 4),
                Text(
                  actor.actorCode!,
                  style: TextStyle(
                    color: secondary,
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LinearProgressIndicator(
                    value: staminaLimit == null
                        ? 0
                        : actor.staminaProgress(staminaLimit!) ?? 0,
                    minHeight: 6,
                    backgroundColor: StoryColors.lightSheetSecondary,
                    valueColor: const AlwaysStoppedAnimation(
                      StoryColors.success,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.bolt, size: 16, color: StoryColors.success),
              const SizedBox(width: 4),
              Text(
                '${stamina ?? '-'}/${staminaLimit ?? '--'}',
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  height: 16 / 12,
                  letterSpacing: 0.04,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: AgentV2HourlySalaryText(actor: actor),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _OutlineAction(
                  label: context.l10n.gameSupplement,
                  onPressed:
                      (actionsEnabled && staminaLimit != null && !isStaminaFull)
                      ? onSupplement
                      : null,
                  disabled: staminaLimit == null || isStaminaFull,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _OutlineAction(
                  label: context.l10n.gameRest,
                  onPressed: actionsEnabled ? onRest : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyMiningCard extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyMiningCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        border: Border.all(color: agentV2MiningSlotColor(null, 0)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              isDark ? _defaultAvatarDark : _defaultAvatarLight,
              width: 44,
              height: 44,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 36,
              child: OutlinedButton(
                onPressed: onTap,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  side: BorderSide(
                    color: brightness == Brightness.dark
                        ? StoryColors.darkDivider
                        : StoryColors.lightDivider,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: StoryColors.foregroundOf(brightness),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 20 / 14,
                  ),
                ),
                child: Text(context.l10n.agentV2SchedulePerformance),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _RoundArrow({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return SizedBox.square(
      dimension: 44,
      child: IconButton(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          side: BorderSide(color: StoryColors.borderOf(brightness)),
          shape: const CircleBorder(),
          disabledForegroundColor: StoryColors.mutedForegroundOf(brightness),
        ),
        icon: Icon(icon, size: 24),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: _levelColor(level),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Text(
        context.l10n.gameLevelBadge('$level'),
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

class _OutlineAction extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool disabled;

  const _OutlineAction({
    required this.label,
    required this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final effectiveFg = disabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : StoryColors.foregroundOf(brightness);
    final effectiveBorder = disabled
        ? StoryColors.mutedForegroundOf(brightness).withValues(alpha: 0.3)
        : (brightness == Brightness.dark
              ? StoryColors.darkDivider
              : StoryColors.lightDivider);
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          side: BorderSide(color: effectiveBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: effectiveFg,
          disabledForegroundColor: effectiveFg,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 20 / 14,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _PageDiamonds extends StatelessWidget {
  final int selectedIndex;
  final List<MiningActor?> slots;
  final int? staminaLimit;
  final ValueChanged<int> onSelected;

  const _PageDiamonds({
    required this.selectedIndex,
    required this.slots,
    required this.staminaLimit,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < _miningSlotCount; index++) ...[
          Semantics(
            label: '${index + 1} / $_miningSlotCount',
            selected: index == selectedIndex,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onSelected(index),
              child: SizedBox.square(
                dimension: 14.142,
                child: Center(
                  child: Transform.rotate(
                    angle: 0.785398,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: index == selectedIndex ? 10 : 8,
                      height: index == selectedIndex ? 10 : 8,
                      decoration: BoxDecoration(
                        color: agentV2MiningSlotColor(
                          slots[index],
                          staminaLimit,
                        ),
                        borderRadius: BorderRadius.circular(2),
                        border: index == selectedIndex
                            ? Border.all(
                                color: StoryColors.foregroundOf(
                                  Theme.of(context).brightness,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (index != _miningSlotCount - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

/// V2 挖矿槽位状态色：半体力及以上为成功色，低于半体力为警告色，
/// 体力耗尽为错误色；空槽或体力未知时使用中性色。
@visibleForTesting
Color agentV2MiningSlotColor(MiningActor? actor, int? staminaLimit) {
  final stamina = actor?.stamina;
  if (stamina == null || staminaLimit == null || staminaLimit <= 0) {
    return StoryColors.buttonDisabledForeground;
  }
  if (stamina <= 0) return StoryColors.destructive;
  return stamina / staminaLimit >= 0.5
      ? StoryColors.success
      : StoryColors.warning;
}

Color _levelColor(int? level) => switch (level) {
  2 => const Color(0xFF0CA87F),
  3 => const Color(0xFFCF8A37),
  4 => const Color(0xFFCF4F5B),
  5 => const Color(0xFF7244E4),
  _ => const Color(0xFF006FFF),
};

class _MiningActorImage extends StatelessWidget {
  final MiningActor actor;

  const _MiningActorImage({required this.actor});

  @override
  Widget build(BuildContext context) {
    final imageUrl = actor.avatarUrl?.trim();
    if (imageUrl == null || imageUrl.isEmpty) {
      return const _MiningActorImageFallback();
    }
    return StoryCachedImage(
      imageUrl: imageUrl,
      memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(context, 207),
      placeholder: const _MiningActorImageLoading(),
      errorWidget: const _MiningActorImageFallback(),
    );
  }
}

class _MiningActorImageLoading extends StatelessWidget {
  const _MiningActorImageLoading();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('agent-v2-mining-avatar-loading'),
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: const StoryLoading.centered(),
    );
  }
}

class _MiningActorImageFallback extends StatelessWidget {
  const _MiningActorImageFallback();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: StoryColors.mutedOf(Theme.of(context).brightness),
      child: Center(
        child: Icon(
          Icons.person,
          size: 56,
          color: StoryColors.mutedForegroundOf(Theme.of(context).brightness),
        ),
      ),
    );
  }
}

class _LoadingMiningCard extends StatelessWidget {
  const _LoadingMiningCard();

  @override
  Widget build(BuildContext context) {
    return _MiningCardStatus(
      child: CircularProgressIndicator(
        color: StoryColors.foregroundOf(Theme.of(context).brightness),
      ),
    );
  }
}

class _ErrorMiningCard extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorMiningCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return _MiningCardStatus(
      child: OutlinedButton(
        onPressed: onRetry,
        child: Text(context.l10n.commonRetry),
      ),
    );
  }
}

class _MiningCardStatus extends StatelessWidget {
  final Widget child;

  const _MiningCardStatus({required this.child});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        border: Border.all(color: agentV2MiningSlotColor(null, 0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: child),
    );
  }
}
