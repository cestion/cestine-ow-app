import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_channel.dart';
import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/actor_pricing.dart';
import '../../utils/format_number.dart';
import '../../utils/mining_power.dart';
import '../../widgets/story_cached_image.dart';
import '../badge/content_badge.dart';
import '../common/story_toast.dart';
import '../iap/iap_point_icon.dart';
import 'actor_info_dialogs.dart';

class ActorCollectionCard extends StatelessWidget {
  final ActorCollection actor;
  final VoidCallback? onTap;
  final VoidCallback? onSign;
  final VoidCallback? onTrade;

  /// 封面角标默认展示。调用方传 false 可隐藏。
  final bool showContentBadge;

  const ActorCollectionCard({
    super.key,
    required this.actor,
    this.onTap,
    this.onSign,
    this.onTrade,
    this.showContentBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;

    final price = actor.displayCurrentPriceUsdc;
    final remainingCount = actor.availableSupplyInt ?? 0;
    final isSoldOut = remainingCount <= 0;
    final actorIpValue = actor.id?.trim() ?? '';
    final actorIpLabel = formatActorIpDisplay(actorIpValue);
    final creatorName = actor.creatorName?.trim().isNotEmpty == true
        ? actor.creatorName!.trim()
        : '-';

    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: StoryColors.cardOf(brightness),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: AspectRatio(
                aspectRatio: 6 / 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    actor.avatarUrl?.isNotEmpty == true
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              return StoryCachedImage(
                                imageUrl: actor.avatarUrl!,
                                memCacheWidth:
                                    StoryCachedImage.memCacheForLogicalWidth(
                                      context,
                                      constraints.maxWidth,
                                    ),
                                errorWidget: _gradientBg(),
                              );
                            },
                          )
                        : _gradientBg(),
                    if (showContentBadge)
                      ContentBadge.positionedCardCorner(badge: actor.badge),
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _CoverPill(
                                onTap: actorIpValue.isEmpty
                                    ? null
                                    : () {
                                        Clipboard.setData(
                                          ClipboardData(text: actorIpValue),
                                        );
                                        StoryToast.success(
                                          context,
                                          l10n.actorIpCopied,
                                        );
                                      },
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
                                    Flexible(
                                      child: Text(
                                        actorIpLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 16 / 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.04,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _CoverPill(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.person_outline,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        creatorName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          height: 16 / 12,
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 0.04,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
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
            ),
            Padding(
              padding: const EdgeInsets.all(StorySpacing.base),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    actor.name?.trim().isNotEmpty == true
                        ? actor.name!.trim()
                        : l10n.commonUntitled,
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.bold,
                      color: StoryColors.foregroundOf(brightness),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (actor.bio?.trim().isNotEmpty == true) ...[
                    const SizedBox(height: StorySpacing.sm),
                    Text(
                      actor.bio!.trim(),
                      style: TextStyle(
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.04,
                        color: StoryColors.mutedForegroundOf(brightness),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: StorySpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ClickableStatChip(
                          label: l10n.actorIpPower,
                          valueText: formatPowerValue(
                            getActorIpPowerBreakdown(actor).ipPower,
                          ),
                          brightness: brightness,
                          onTap: () => IpPowerInfoDialog.show(
                            context: context,
                            actorName: actor.name ?? '',
                            breakdown: getActorIpPowerBreakdown(actor),
                          ),
                        ),
                      ),
                      const SizedBox(width: StorySpacing.sm),
                      Expanded(
                        child: _ClickableStatChip(
                          label: l10n.actorStatCompletion,
                          valueText: formatNumber(
                            actor.completedViewCountInt ?? 0,
                            0,
                          ),
                          brightness: brightness,
                          onTap: () => CompletionInfoDialog.show(context),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: StorySpacing.sm),
                  _ActorPriceArea(
                    actor: actor,
                    price: price,
                    isSoldOut: isSoldOut,
                    remainingCount: remainingCount,
                    brightness: brightness,
                  ),
                  const SizedBox(height: StorySpacing.md),
                  _ActorActionButtons(
                    isSoldOut: isSoldOut,
                    floorPriceLabel: formatActorFloorPriceDisplay(
                      resolveActorFloorPriceUsdc(
                        floorPriceUsdc: actor.floorPriceUsdc,
                      ),
                      l10n.currency,
                    ),
                    brightness: brightness,
                    onSign: onSign,
                    onTrade: onTrade,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradientBg() => const DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [StoryColors.brandTeal, StoryColors.gradientMid],
      ),
    ),
    child: Center(
      child: Icon(Icons.person, size: 36, color: StoryColors.onOverlayMuted),
    ),
  );
}

class _CoverPill extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;

  const _CoverPill({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 6, 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(52),
      ),
      child: child,
    );
    if (onTap == null) return pill;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: pill,
    );
  }
}

class _ClickableStatChip extends StatelessWidget {
  final String label;
  final String valueText;
  final Brightness brightness;
  final VoidCallback onTap;

  const _ClickableStatChip({
    required this.label,
    required this.valueText,
    required this.brightness,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Figma `--story-bg` #F8F9FB (light) / muted surface (dark) on card.
          color: brightness == Brightness.dark
              ? StoryColors.darkMuted
              : StoryColors.lightStoryBg,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                height: 12 / 10,
                letterSpacing: 0.08,
                color: StoryColors.mutedForegroundOf(brightness),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valueText,
              style: TextStyle(
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w500,
                color: StoryColors.foregroundOf(brightness),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 签约价格区域，点击弹出价格详情。
class _ActorPriceArea extends StatelessWidget {
  final ActorCollection actor;
  final double price;
  final bool isSoldOut;
  final int remainingCount;
  final Brightness brightness;

  const _ActorPriceArea({
    required this.actor,
    required this.price,
    required this.isSoldOut,
    required this.remainingCount,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final accent = brightness == Brightness.dark
        ? StoryColors.brandTeal
        : StoryColors.brandTealDark;
    final accentMuted = accent.withValues(alpha: 0.8);

    return GestureDetector(
      onTap: () => PriceInfoDialog.show(
        context: context,
        pricingMode: actor.pricingMode,
        signedCount: actor.mintedSupplyInt ?? 0,
        maxSupply: actor.totalSupplyInt ?? 0,
        initialPrice: actor.initialPriceUsdc ?? price,
        currentPrice: price,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: StorySpacing.base,
          vertical: StorySpacing.md,
        ),
        decoration: BoxDecoration(
          color: StoryColors.brandTeal.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: StoryColors.brandTeal.withValues(alpha: 0.16),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.actorSignPriceLabel,
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.04,
                          color: accent,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.help_outline, size: 16, color: accent),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSoldOut
                        ? context.l10n.actorSignSoldOut
                        : context.l10n.actorSignRemainingCount(remainingCount),
                    style: TextStyle(
                      fontSize: 12,
                      height: 16 / 12,
                      letterSpacing: 0.04,
                      color: accentMuted,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatActorPriceCeilDisplay(price),
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 2),
                if (AppChannel.isStore)
                  const IapPointIcon()
                else
                  Text(
                    'USDC',
                    style: TextStyle(
                      fontSize: 16,
                      height: 24 / 16,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 签约/交易按钮区域。
class _ActorActionButtons extends StatelessWidget {
  final bool isSoldOut;
  final String floorPriceLabel;
  final Brightness brightness;
  final VoidCallback? onSign;
  final VoidCallback? onTrade;

  const _ActorActionButtons({
    required this.isSoldOut,
    required this.floorPriceLabel,
    required this.brightness,
    this.onSign,
    this.onTrade,
  });

  @override
  Widget build(BuildContext context) {
    final border = StoryColors.dividerOf(brightness);
    final fg = StoryColors.foregroundOf(brightness);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    if (isSoldOut) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.actorFloorPrice,
                  style: TextStyle(
                    fontSize: 12,
                    height: 16 / 12,
                    letterSpacing: 0.04,
                    color: StoryColors.mutedForegroundOf(brightness),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  floorPriceLabel,
                  style: TextStyle(
                    fontSize: 16,
                    height: 24 / 16,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton(
                onPressed: onTrade,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: border),
                  shape: buttonShape,
                  foregroundColor: fg,
                ),
                child: Text(
                  context.l10n.actorGoTrade,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: onSign,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border),
          shape: buttonShape,
          foregroundColor: fg,
        ),
        child: Text(
          context.l10n.actorSign,
          style: const TextStyle(
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
