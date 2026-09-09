import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../components/badge/content_badge.dart';
import '../../../components/common/story_toast.dart';
import '../../../components/nft/actor_info_dialogs.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/actor_collection_model.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../utils/mining_power.dart';
import '../../../widgets/story_cached_image.dart';
import '../../../widgets/story_info_dialog.dart';
import 'actor_detail_widgets.dart';

/// Figma 亮色 `881:190584` / 暗色 `881:188186` — 演员主页 Hero。
class ActorHeroSection extends StatelessWidget {
  final ActorCollection actor;
  final ThemeData theme;
  final String issuerName;
  final String actorIpLabel;
  final bool blendWithPageBackground;

  /// When false, hides the actor [ContentBadge] in the badge wrap.
  final bool showContentBadge;

  const ActorHeroSection({
    super.key,
    required this.actor,
    required this.theme,
    required this.issuerName,
    required this.actorIpLabel,
    this.blendWithPageBackground = false,
    this.showContentBadge = true,
  });

  static String truncateId(String? id) {
    if (id == null || id.length <= 12) return id ?? '';
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  static Future<void> _showRiskIpDialog(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    return StoryInfoDialog.show(
      context: context,
      title: l10n.actorRiskIp,
      actionLabel: l10n.commonOk,
      content: Text(
        l10n.actorRiskIpDescription,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w500,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = theme.brightness;
    final ipPowerBreakdown = getActorIpPowerBreakdown(actor);
    final pay = ipPowerBreakdown.ipPower;
    final cardColor = blendWithPageBackground
        ? StoryColors.actorDetailBackgroundOf(brightness)
        : StoryColors.cardOf(brightness);

    // Figma：头图通栏；名称 / 徽章 / 简介 / 片酬区左右 16。
    return ColoredBox(
      color: cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: actor.avatarUrl?.isNotEmpty == true
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return StoryCachedImage(
                        imageUrl: actor.avatarUrl!,
                        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                          context,
                          constraints.maxWidth,
                        ),
                        errorWidget: const ActorGradientBg(),
                      );
                    },
                  )
                : const ActorGradientBg(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              StorySpacing.screenHorizontal,
              StorySpacing.base,
              StorySpacing.screenHorizontal,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        actor.name ?? l10n.commonUntitled,
                        style: TextStyle(
                          fontSize: 24,
                          height: 30 / 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.1,
                          color: StoryColors.foregroundOf(brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (actor.isRiskActorIp) ...[
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _showRiskIpDialog(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: StoryColors.pending.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(49),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: StoryColors.pending,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                l10n.actorRiskIp,
                                style: const TextStyle(
                                  fontSize: 12,
                                  height: 16 / 12,
                                  letterSpacing: 0.04,
                                  fontWeight: FontWeight.w400,
                                  color: StoryColors.pending,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: StorySpacing.md),
                Wrap(
                  spacing: 6,
                  runSpacing: StorySpacing.xs,
                  children: [
                    if (showContentBadge) ContentBadge(badge: actor.badge),
                    ActorHeroBadge(label: l10n.actorIssuer(issuerName)),
                    ActorHeroBadge(
                      label: l10n.actorIpLabel(actorIpLabel),
                      onTap: actor.id == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: actor.id!));
                              StoryToast.success(context, l10n.actorIdCopied);
                            },
                    ),
                    if ((actor.availableSupplyInt ?? 0) <= 0)
                      ActorHeroBadge(
                        label: l10n.actorSignSoldOut,
                        backgroundColor: StoryColors.destructive.withValues(
                          alpha: 0.15,
                        ),
                        foregroundColor: StoryColors.destructive,
                      ),
                  ],
                ),
                if (actor.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: StorySpacing.md),
                  Text(
                    actor.bio!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 20 / 14,
                      color: StoryColors.foregroundOf(brightness),
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: StorySpacing.md),
                ActorHeroStatsPanel(
                  payLabel: l10n.nftSortLv1Pay,
                  payValue: formatPowerValue(pay),
                  brightness: brightness,
                  onPayTap: () => IpPowerInfoDialog.show(
                    context: context,
                    actorName: actor.name ?? '',
                    breakdown: ipPowerBreakdown,
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
