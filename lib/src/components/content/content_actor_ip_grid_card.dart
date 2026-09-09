import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/app_channel.dart';
import '../../l10n/story_l10n.dart';
import '../../model/actor_collection_model.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_radius.dart';
import '../../styles/story_spacing.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/mining_power.dart';
import '../../widgets/story_cached_image.dart';
import '../badge/content_badge.dart';
import '../common/story_toast.dart';
import '../iap/iap_point_icon.dart';
import '../nft/actor_info_dialogs.dart';

/// 通用双列「角色 IP」紧凑卡 — Figma 亮色 `881:194231` / 暗色 `881:193414`。
///
/// 封面 6:5 + 信息区：名称 · 片酬行 · 价格 + 操作按钮。
class ContentActorIpGridCard extends ConsumerWidget {
  final ActorCollection actor;
  final VoidCallback? onTap;
  final VoidCallback? onSign;
  final VoidCallback? onTrade;

  /// 封面角标默认展示。广场 / 搜索 / 个人中心暂时传 false 隐藏。
  final bool showContentBadge;

  const ContentActorIpGridCard({
    super.key,
    required this.actor,
    this.onTap,
    this.onSign,
    this.onTrade,
    this.showContentBadge = false,
  });

  static const coverAspectRatio = 6 / 5;

  /// Padding 24 + name 24 + gaps 16 + pay row 20 + price row 32 = 116; +4 slack
  /// for dotted-underline / font metrics that otherwise overflow by ~2px.
  static const infoHeight = 120.0;
  static const gridCrossAxisCount = 2;
  static const gridSpacing = 8.0;

  /// Fallback @ Figma 375 宽（卡宽 175.5 → cover 146.25 + info 120）。
  static const gridChildAspectRatio = 175.5 / 266.25;

  /// 网格内容区宽度（已扣除外层 padding）对应的 cell 宽/高。
  static double gridChildAspectRatioFor(double gridWidth) {
    final cardWidth =
        (gridWidth - gridSpacing * (gridCrossAxisCount - 1)) /
        gridCrossAxisCount;
    if (cardWidth <= 0) return gridChildAspectRatio;
    return cardWidth / (cardWidth / coverAspectRatio + infoHeight);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);
    final cardBg = brightness == Brightness.dark
        ? StoryColors.darkCard
        : Colors.white;
    final price = actor.displayCurrentPriceUsdc;
    final remaining = actor.availableSupplyInt ?? 0;
    final isSoldOut = remaining <= 0;
    final floorPriceLabel = formatActorFloorPriceDisplay(
      resolveActorFloorPriceUsdc(floorPriceUsdc: actor.floorPriceUsdc),
      l10n.currency,
    );
    final priceLabel = isSoldOut
        ? floorPriceLabel
        : formatActorPriceCeilDisplay(price);
    final ipValue = actor.id?.trim() ?? '';
    final ipLabel = formatActorIpDisplay(ipValue);
    final breakdown = getActorIpPowerBreakdown(actor);
    final lv1 = breakdown.ipPower;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: StoryRadius.brLg,
        ),
        child: ClipRRect(
          borderRadius: StoryRadius.brLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if ((actor.avatarUrl ?? '').isNotEmpty)
                      StoryCachedImage(imageUrl: actor.avatarUrl!)
                    else
                      const ColoredBox(color: Color(0xFF2A2A2E)),
                    if (showContentBadge)
                      ContentBadge.positionedCardCorner(
                        badge: actor.badge,
                        style: ContentBadgeStyle.profileCardCorner,
                      ),
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: ipValue.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: ipValue));
                                StoryToast.success(context, l10n.actorIpCopied);
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(52),
                          ),
                          child: Text(
                            ipLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 16 / 12,
                              letterSpacing: 0.04,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: infoHeight,
                child: Padding(
                  padding: const EdgeInsets.all(StorySpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        actor.name?.trim().isNotEmpty == true
                            ? actor.name!.trim()
                            : l10n.commonUntitled,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w500,
                          color: fg,
                        ),
                      ),
                      const SizedBox(height: StorySpacing.sm),
                      _Lv1PayRateRow(
                        value: formatPowerValue(lv1),
                        fg: fg,
                        muted: muted,
                        dividerColor: StoryColors.dividerOf(brightness),
                        onTap: () => IpPowerInfoDialog.show(
                          context: context,
                          actorName: actor.name ?? '',
                          breakdown: breakdown,
                        ),
                      ),
                      const SizedBox(height: StorySpacing.sm),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // vi/tr 等长文案（如「Ký kết hợp đồng」）不能把价格+USDC 挤没。
                          final chipMaxWidth = constraints.maxWidth * 0.5;
                          return Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        priceLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 17,
                                          height: 25 / 17,
                                          fontWeight: FontWeight.w700,
                                          color: fg,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    AppChannel.isStore
                                        ? const IapPointIcon()
                                        : SvgPicture.asset(
                                            'assets/common/usdc.svg',
                                            width: 16,
                                            height: 16,
                                          ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: chipMaxWidth,
                                ),
                                child: _ActionChip(
                                  label: isSoldOut
                                      ? l10n.actorGoTrade
                                      : l10n.actorSign,
                                  outlined: isSoldOut,
                                  brightness: brightness,
                                  onTap: isSoldOut ? onTrade : onSign,
                                ),
                              ),
                            ],
                          );
                        },
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

class _Lv1PayRateRow extends StatelessWidget {
  final String value;
  final Color fg;
  final Color muted;
  final Color dividerColor;
  final VoidCallback? onTap;

  const _Lv1PayRateRow({
    required this.value,
    required this.fg,
    required this.muted,
    required this.dividerColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const lineHeight = 20.0;
    final row = SizedBox(
      height: lineHeight,
      child: Row(
        children: [
          Text(
            context.l10n.gameFilterComputingPower,
            strutStyle: const StrutStyle(
              fontSize: 14,
              height: lineHeight / 14,
              forceStrutHeight: true,
            ),
            style: TextStyle(
              fontSize: 14,
              height: lineHeight / 14,
              color: fg,
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationStyle: onTap != null
                  ? TextDecorationStyle.dotted
                  : null,
              decorationColor: fg,
            ),
          ),
          const SizedBox(width: 6),
          Container(width: 1, height: 10, color: dividerColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: TextStyle(
                      fontSize: 14,
                      height: lineHeight / 14,
                      fontWeight: FontWeight.w500,
                      color: fg,
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
                        semanticsLabel: context.l10n.gameFilterComputingPower,
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
              strutStyle: const StrutStyle(
                fontSize: 14,
                height: lineHeight / 14,
                forceStrutHeight: true,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return row;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: row,
    );
  }
}

class _ActionChip extends StatelessWidget {
  final String label;
  final bool outlined;
  final Brightness brightness;
  final VoidCallback? onTap;

  const _ActionChip({
    required this.label,
    required this.outlined,
    required this.brightness,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = StoryColors.foregroundOf(brightness);
    final isDark = brightness == Brightness.dark;
    final bg = outlined
        ? Colors.transparent
        : (isDark ? Colors.white : StoryColors.darkButtonBg);
    final textColor = outlined
        ? fg
        : (isDark ? StoryColors.darkButtonBg : Colors.white);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: outlined ? Border.all(color: fg) : null,
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            height: 18 / 13,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
