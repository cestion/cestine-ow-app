import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../l10n/story_l10n.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

// ─── Badge ────────────────────────────────────────────────────

class ActorBadge extends StatelessWidget {
  final String label;
  const ActorBadge({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(theme.brightness),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: StoryColors.foregroundOf(theme.brightness),
        ),
      ),
    );
  }
}

// ─── Hero Badge ───────────────────────────────────────────────

class ActorHeroBadge extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const ActorHeroBadge({
    super.key,
    required this.label,
    this.onTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = backgroundColor ?? StoryColors.actorHeroBadgeBgOf(brightness);
    final fg = foregroundColor ?? StoryColors.foregroundOf(brightness);
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.sm,
        vertical: StorySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0.04,
          color: fg,
        ),
      ),
    );

    if (onTap == null) return child;
    return GestureDetector(onTap: onTap, child: child);
  }
}

// ─── Hero Stats（Figma 2826:191733 — 单行片酬）────────────────

/// 暗色对齐稿 `page&sheet/thirdly`；亮色沿用旧 badge 底色。
class ActorHeroStatsPanel extends StatelessWidget {
  final String payLabel;
  final String payValue;
  final Brightness brightness;
  final VoidCallback? onPayTap;

  const ActorHeroStatsPanel({
    super.key,
    required this.payLabel,
    required this.payValue,
    required this.brightness,
    this.onPayTap,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = brightness == Brightness.dark
        ? StoryColors.darkActorHeroStatsBg
        : StoryColors.lightActorHeroBadgeBg;
    final foreground = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);

    final child = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              payLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                height: 24 / 16,
                fontWeight: FontWeight.w500,
                color: foreground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: payValue,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.bold,
                    color: foreground,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SvgPicture.asset(
                      'assets/game_v3/agent_salary.svg',
                      width: 16,
                      height: 16,
                      semanticsLabel: payLabel,
                    ),
                  ),
                ),
                TextSpan(
                  text: '/h',
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                    color: muted,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );

    if (onPayTap == null) return child;
    return GestureDetector(
      onTap: onPayTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

// ─── Sign Bottom Bar ──────────────────────────────────────────

class ActorSignBottomBar extends StatelessWidget {
  final bool isSoldOut;
  final bool isLoading;
  final String priceLabel;
  final Widget? priceWidget;
  final VoidCallback? onSign;
  final VoidCallback? onTrade;

  const ActorSignBottomBar({
    super.key,
    required this.isSoldOut,
    this.isLoading = false,
    required this.priceLabel,
    this.priceWidget,
    this.onSign,
    this.onTrade,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final buttonBackground = isDark
        ? StoryColors.privyDarkNormal
        : StoryColors.lightForeground;
    final buttonForeground = isDark
        ? StoryColors.privyDarkForeground
        : StoryColors.onOverlay;
    final actionLabel = isSoldOut
        ? context.l10n.actorGoTrade
        : context.l10n.actorSign;
    final label = priceLabel.isEmpty
        ? actionLabel
        : '$priceLabel · $actionLabel';

    return ColoredBox(
      color: StoryColors.actorDetailBackgroundOf(brightness),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            StorySpacing.screenHorizontal,
            StorySpacing.xs,
            StorySpacing.screenHorizontal,
            StorySpacing.screenHorizontal,
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : (isSoldOut ? onTrade : onSign),
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonBackground,
              disabledBackgroundColor: isLoading ? buttonBackground : null,
              foregroundColor: buttonForeground,
              disabledForegroundColor: isLoading ? buttonForeground : null,
              elevation: 0,
              minimumSize: const Size(double.infinity, 44),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: const RoundedRectangleBorder(
                borderRadius: StoryRadius.brMd,
              ),
            ),
            child: isLoading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: buttonForeground,
                    ),
                  )
                : priceWidget != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      priceWidget!,
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· $actionLabel',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 20 / 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  )
                : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─── Hero Price Banner ────────────────────────────────────────

class ActorHeroPriceBanner extends StatelessWidget {
  final String priceLabel;
  final String priceText;
  final Widget? priceWidget;
  final Brightness brightness;

  const ActorHeroPriceBanner({
    super.key,
    required this.priceLabel,
    required this.priceText,
    this.priceWidget,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: StoryColors.actorSignPriceBannerBg,
        borderRadius: StoryRadius.brMd,
        border: Border.all(color: StoryColors.actorSignPriceBannerBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              priceLabel,
              style: TextStyle(
                fontSize: 13,
                height: 18 / 13,
                color: StoryColors.actorSignPriceLabelOf(brightness),
              ),
            ),
          ),
          priceWidget ??
              Text(
                priceText,
                style: const TextStyle(
                  fontSize: 16,
                  height: 24 / 16,
                  fontWeight: FontWeight.bold,
                  color: StoryColors.brandTeal,
                ),
              ),
        ],
      ),
    );
  }
}

// ─── Detail Metric ────────────────────────────────────────────

class ActorDetailMetric extends StatelessWidget {
  final String label;
  final int value;
  final Brightness brightness;

  const ActorDetailMetric({
    super.key,
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.transparent,
        borderRadius: StoryRadius.brSm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              height: 1.2,
              color: StoryColors.privyFooterTextOf(brightness),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: StoryColors.foregroundOf(brightness),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Issue Info Row ───────────────────────────────────────────

class ActorIssueInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Brightness brightness;

  const ActorIssueInfoRow({
    super.key,
    required this.label,
    required this.value,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 155,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              letterSpacing: 0.04,
              color: StoryColors.actorSignPriceLabelOf(brightness),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              height: 16 / 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.04,
              color: StoryColors.foregroundOf(brightness),
            ),
          ),
        ),
      ],
    );
  }
}

/// 固定价格模式下的发行信息说明（无 K 线），对齐 Figma 演员详情「发行信息」Tab。
class ActorIssueFixedPricePanel extends StatelessWidget {
  final Brightness brightness;

  const ActorIssueFixedPricePanel({super.key, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final foreground = StoryColors.foregroundOf(brightness);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.actorPricingFixed,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: foreground,
          ),
        ),
        const SizedBox(height: StorySpacing.sm),
        Text(
          l10n.actorIssueFixedPriceDesc,
          style: TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w400,
            color: foreground,
          ),
        ),
      ],
    );
  }
}

// ─── Issue Info Card ──────────────────────────────────────────

class ActorIssueInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const ActorIssueInfoCard({
    super.key,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(StorySpacing.sm),
      decoration: BoxDecoration(
        color: StoryColors.mutedOf(theme.brightness).withValues(alpha: 0.7),
        borderRadius: StoryRadius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: StoryTextStyles.caption(
              color: StoryColors.actorIssueInfoCardLabelTextOf(
                theme.brightness,
              ),
            ),
          ),
          const SizedBox(height: StorySpacing.xs),
          Text(
            value,
            style: StoryTextStyles.titleMedium(
              color: StoryColors.foregroundOf(theme.brightness),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── Gradient Background ──────────────────────────────────────

class ActorGradientBg extends StatelessWidget {
  const ActorGradientBg({super.key});

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [StoryColors.brandTeal, StoryColors.gradientMid],
        ),
      ),
      child: Center(
        child: Icon(Icons.person, size: 48, color: StoryColors.onOverlayMuted),
      ),
    );
  }
}
