import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/story_constants.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/format_number.dart';
import '../../utils/mining_power.dart';
import '../../widgets/story_cached_image.dart';
import '../../widgets/story_info_dialog.dart';
import '../common/story_toast.dart';
import 'game_actor_power_dialog.dart';

/// Actor card for the agency workshop — deployed slot or my-actors list item.
class GameActorCard extends StatelessWidget {
  final MiningActor actor;
  final int staminaLimit;
  final VoidCallback? onSupplement;
  final VoidCallback? onRest;
  final VoidCallback? onDeploy;
  final VoidCallback? onUpgrade;

  const GameActorCard({
    super.key,
    required this.actor,
    required this.staminaLimit,
    this.onSupplement,
    this.onRest,
    this.onDeploy,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final brightness = theme.brightness;
    final isStaminaFull = actor.isStaminaFull(staminaLimit);
    final isMining = actor.isMining;
    final borderColor = StoryColors.borderOf(brightness);
    final weeklyOutputText = formatNumber(actor.weeklyOutput);

    final body = Padding(
      padding: const EdgeInsets.all(StorySpacing.base),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NameRow(actor: actor),
          if (actor.stamina != null && staminaLimit > 0) ...[
            const SizedBox(height: StorySpacing.md),
            _StaminaRow(actor: actor, staminaLimit: staminaLimit),
          ],
          // 派遣中 / 闲置：双 chip（角色算力 + 本周名义产出），对齐 Figma 7371:65439
          const SizedBox(height: StorySpacing.md),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => GameActorPowerDialog.show(
                      context: context,
                      actor: actor,
                    ),
                    behavior: HitTestBehavior.opaque,
                    child: _StatChip(
                      label: l10n.gameActorPower,
                      value: formatPowerValue(
                        getMiningActorPowerBreakdown(actor).actorPower,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StorySpacing.sm),
                Expanded(
                  child: _StatChip(
                    label: l10n.gameWeeklyNominalOutputLabel,
                    value: weeklyOutputText,
                    valueSuffix: weeklyOutputText == '-' ? null : 'STORY',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: StorySpacing.md),
          _ActionRow(
            actor: actor,
            isStaminaFull: isStaminaFull,
            onSupplement: onSupplement,
            onRest: onRest,
            onDeploy: onDeploy,
          ),
        ],
      ),
    );

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(brightness),
        borderRadius: StoryRadius.brLg,
        border: Border.all(color: borderColor, width: 0.5),
      ),
      // 派遣轮播（horizontal ListView）会给子项交叉轴 tight 高度；
      // 用 min 避免被撑开后内部 Row/按钮拿到异常约束。
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActorCover(
            actor: actor,
            showUpgrade: onUpgrade != null && !isMining,
            onUpgrade: onUpgrade,
          ),
          body,
        ],
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  final MiningActor actor;

  const _NameRow({required this.actor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            actor.displayName.isNotEmpty ? actor.displayName : '-',
            style: StoryTextStyles.headingMedium(
              color: StoryColors.foregroundOf(theme.brightness),
            ).copyWith(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (actor.actorCode != null) ...[
          const SizedBox(width: StorySpacing.xs),
          Text(
            actor.actorCode!,
            style: StoryTextStyles.bodySmall(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _ActorCover extends StatelessWidget {
  final MiningActor actor;
  final bool showUpgrade;
  final VoidCallback? onUpgrade;

  const _ActorCover({
    required this.actor,
    this.showUpgrade = false,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isMining = actor.isMining;
    final statusLabel = isMining ? l10n.gameStatusMining : l10n.gameStatusIdle;
    final collectionId = actor.actorCollectionId?.toString();
    final ipShortLabel = collectionId == null
        ? null
        : formatActorIpDisplay(collectionId);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: AspectRatio(
        aspectRatio: 600 / 500,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (showUpgrade)
              GestureDetector(onTap: onUpgrade, child: _coverImage(context))
            else
              _coverImage(context),
            if (actor.level != null)
              Positioned(
                top: 12,
                left: 12,
                child: _LevelBadge(level: actor.level!),
              ),
            // 闲置封面：IP + 状态角标；派遣中仅 Lv
            if (!isMining && ipShortLabel != null)
              Positioned(
                bottom: 12,
                left: 12,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: collectionId!));
                    if (!context.mounted) return;
                    StoryToast.success(context, l10n.actorIpCopied);
                  },
                  child: _IpOverlayBadge(label: ipShortLabel),
                ),
              ),
            if (showUpgrade)
              Positioned(
                top: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onUpgrade,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
                    decoration: const BoxDecoration(
                      color: StoryColors.warning,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      context.l10n.gameUpgrade,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (!isMining)
              Positioned(
                bottom: 12,
                right: 12,
                child: _StatusOverlayBadge(label: statusLabel),
              ),
          ],
        ),
      ),
    );
  }

  Widget _coverImage(BuildContext context) {
    final url = actor.avatarUrl?.trim();
    if (url?.isNotEmpty == true) {
      return StoryCachedImage(
        imageUrl: url!,
        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
          context,
          StoryImageCache.avatarEdit,
        ),
        errorWidget: const _CoverFallback(),
      );
    }
    return const _CoverFallback();
  }
}

class _CoverFallback extends StatelessWidget {
  const _CoverFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StoryColors.brandTeal, StoryColors.gradientMid],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.person,
          size: 48,
          color: StoryColors.onOverlay.withValues(alpha: 0.38),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  /// 与 web `gameActorLevelVisual` / Figma Lv1–Lv5 对齐
  static Color _surfaceForLevel(int level) => switch (level) {
    2 => const Color(0x800CA87F),
    3 => const Color(0x80CF8A37),
    4 => const Color(0x80CF4F5B),
    5 => const Color(0x807244E4),
    _ => const Color(0x80006FFF), // Lv1 及未知
  };

  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: _surfaceForLevel(level),
        borderRadius: BorderRadius.circular(52),
      ),
      child: Text(
        context.l10n.gameLevelBadge('$level'),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 16 / 12,
          letterSpacing: 0.04,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _IpOverlayBadge extends StatelessWidget {
  final String label;

  const _IpOverlayBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(52),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white),
            ),
            child: const Text(
              'IP',
              style: TextStyle(
                fontSize: 8,
                height: 1,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusOverlayBadge extends StatelessWidget {
  final String label;

  const _StatusOverlayBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(52),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _StaminaRow extends StatelessWidget {
  static const _helpIconAsset = 'assets/game/stamina_help.svg';

  final MiningActor actor;
  final int staminaLimit;

  const _StaminaRow({required this.actor, required this.staminaLimit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // 防止后端脏数据导致体力值超出上限或为负。
    final current = actor.stamina ?? 0;
    final progress = actor.staminaProgress(staminaLimit) ?? 0.0;
    final ratio = staminaLimit > 0 ? current / staminaLimit : 0.0;
    final progressColor = ratio <= 0.3
        ? StoryColors.destructive
        : (ratio <= 0.7 ? StoryColors.warning : StoryColors.brandTeal);
    final isMining = actor.isMining;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: StoryColors.brandTeal.withValues(alpha: 0.05),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            ),
          ),
        ),
        const SizedBox(width: StorySpacing.xs),
        SvgPicture.asset(
          current >= staminaLimit
              ? 'assets/game/solid_earlier.svg'
              : 'assets/game/earlier.svg',
          width: 16,
          height: 16,
        ),
        const SizedBox(width: StorySpacing.xxs),
        Text(
          context.l10n.gameStaminaProgress('$current', '$staminaLimit'),
          style: StoryTextStyles.bodySmall(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (!isMining) ...[
          const SizedBox(width: StorySpacing.xs),
          Semantics(
            button: true,
            label: context.l10n.gameStaminaMechanismTitle,
            child: Tooltip(
              message: context.l10n.gameStaminaMechanismTitle,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showStaminaMechanismDialog(context),
                child: SizedBox.square(
                  dimension: 16,
                  child: SvgPicture.asset(
                    _helpIconAsset,
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      theme.colorScheme.onSurfaceVariant,
                      BlendMode.srcIn,
                    ),
                    errorBuilder: (_, _, _) => Icon(
                      Icons.help_outline,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _showStaminaMechanismDialog(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.gameStaminaMechanismTitle,
      content: Text(
        l10n.gameStaminaMechanismDesc(l10n.currency),
        style: StoryTextStyles.bodyMedium(
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
      actionLabel: l10n.gameStaminaMechanismAction,
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final String? valueSuffix;

  const _StatChip({required this.label, required this.value, this.valueSuffix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final secondary = theme.colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        // 亮色 story-bg #F8F9FB；暗色 story-bg #111113（Figma 7371:65439 / 7446:150356）
        color: brightness == Brightness.dark
            ? StoryColors.darkBackground
            : StoryColors.lightStoryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              height: 12 / 10,
              letterSpacing: 0.08,
              color: secondary,
            ),
          ),
          const SizedBox(height: 2),
          if (valueSuffix == null)
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            )
          else
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: foreground,
                    ),
                  ),
                  TextSpan(
                    text: ' $valueSuffix',
                    style: TextStyle(
                      fontSize: 10,
                      height: 12 / 10,
                      letterSpacing: 0.08,
                      fontWeight: FontWeight.w400,
                      color: secondary,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final MiningActor actor;
  final bool isStaminaFull;
  final VoidCallback? onSupplement;
  final VoidCallback? onRest;
  final VoidCallback? onDeploy;

  const _ActionRow({
    required this.actor,
    required this.isStaminaFull,
    this.onSupplement,
    this.onRest,
    this.onDeploy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (actor.isRest) {
      if (isStaminaFull) {
        return SizedBox(
          width: double.infinity,
          child: _DeployButton(label: l10n.gameDeploy, onPressed: onDeploy),
        );
      }
      return Row(
        children: [
          Expanded(
            child: _TintedActionButton(
              label: l10n.gameSupplement,
              backgroundColor: const Color(0x1AF4D100),
              foregroundColor: const Color(0xFFE2A336),
              onPressed: onSupplement,
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: _DeployButton(label: l10n.gameDeploy, onPressed: onDeploy),
          ),
        ],
      );
    }

    // Figma：补充 rgba(244,209,0,0.1)/#e2a336；休息 rgba(255,0,8,0.1)/#e5484d
    return Row(
      children: [
        Expanded(
          child: _TintedActionButton(
            label: l10n.gameSupplement,
            backgroundColor: const Color(0x1AF4D100),
            foregroundColor: const Color(0xFFE2A336),
            onPressed: isStaminaFull ? null : onSupplement,
            disabled: isStaminaFull,
          ),
        ),
        const SizedBox(width: StorySpacing.md),
        Expanded(
          child: _TintedActionButton(
            label: l10n.gameRest,
            backgroundColor: const Color(0x1AFF0008),
            foregroundColor: StoryColors.destructive,
            onPressed: onRest,
          ),
        ),
      ],
    );
  }
}

const _gameActionButtonHeight = 44.0;

const _gameActionTextHeightBehavior = TextHeightBehavior(
  applyHeightToFirstAscent: false,
  applyHeightToLastDescent: false,
);

TextStyle _gameActionLabelStyle(Color color) => TextStyle(
  color: color,
  fontSize: 14,
  fontWeight: FontWeight.bold,
  height: 1.2,
);

ButtonStyle _gameCompactButtonStyle({
  Color? backgroundColor,
  Color? foregroundColor,
}) {
  return TextButton.styleFrom(
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    minimumSize: const Size(0, _gameActionButtonHeight),
    maximumSize: const Size(double.infinity, _gameActionButtonHeight),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    visualDensity: VisualDensity.standard,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  );
}

class _DeployButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const _DeployButton({required this.label, this.onPressed});

  @override
  Widget build(BuildContext context) {
    const brandBlueBg = Color(0x0F0044FF); // rgba(0, 68, 255, 0.06)
    const brandBlueText = Color(0xFF3E63DD); // #3e63dd

    return SizedBox(
      width: double.infinity,
      height: _gameActionButtonHeight,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: brandBlueBg,
          foregroundColor: brandBlueText,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size(0, _gameActionButtonHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.standard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: _gameActionLabelStyle(brandBlueText),
          textHeightBehavior: _gameActionTextHeightBehavior,
        ),
      ),
    );
  }
}

class _TintedActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onPressed;
  final bool disabled;

  const _TintedActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onPressed,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBg = disabled
        ? StoryColors.mutedOf(theme.brightness)
        : backgroundColor;
    final effectiveFg = disabled
        ? theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45)
        : foregroundColor;
    return TextButton(
      onPressed: onPressed,
      style: _gameCompactButtonStyle(
        backgroundColor: effectiveBg,
        foregroundColor: effectiveFg,
      ),
      child: Text(
        label,
        style: _gameActionLabelStyle(effectiveFg),
        textHeightBehavior: _gameActionTextHeightBehavior,
      ),
    );
  }
}

/// 空派遣槽位，点击打开派遣弹窗。
class GameDeployEmptySlot extends StatelessWidget {
  final VoidCallback? onTap;

  const GameDeployEmptySlot({super.key, this.onTap});

  static const _borderRadius = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: _GameDeployDashedBorderPainter(
          color: StoryColors.borderOf(brightness),
          radius: _borderRadius,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: StoryColors.cardOf(brightness),
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 28, color: StoryColors.brandTeal),
              const SizedBox(height: 6),
              Text(
                context.l10n.gameDeployActor,
                style: StoryTextStyles.bodyMedium(
                  color: StoryColors.brandTeal,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameDeployDashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _GameDeployDashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const dash = 5.0;
    const gap = 4.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GameDeployDashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
