import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';

/// 内容徽章枚举，对齐 Web `ActorCollectionResponseBadge` / `DramaListItemResponseBadge`。
enum ContentBadgeValue {
  official('OFFICIAL'),
  community('COMMUNITY'),
  partner('PARTNER'),
  verified('VERIFIED');

  const ContentBadgeValue(this.apiValue);
  final String apiValue;

  static ContentBadgeValue? fromApiValue(String? value) {
    final raw = value?.trim().toUpperCase();
    if (raw == null || raw.isEmpty) return null;
    for (final item in ContentBadgeValue.values) {
      if (item.apiValue == raw) return item;
    }
    return null;
  }

  /// Drama list/detail: invalid or missing badge falls back to community.
  static ContentBadgeValue resolveDrama(String? value) =>
      fromApiValue(value) ?? ContentBadgeValue.community;
}

/// `issue`：演员发行徽章；`drama`：短剧徽章（文案为「xx短剧」）。
enum ContentBadgeVariant { issue, drama }

/// Visual style for [ContentBadge].
///
/// [standard] — 4px rounded rect (default; detail / feed / hero / actor, etc.).
/// [onOverlay] — player chrome over video (white fill, black label).
/// [cardCorner] — Figma theater-card corner chip (24px / 12r).
/// [profileCardCorner] — 角色 IP / 个人中心紧凑卡角标（20px / 10r，Figma 655:125754）。
enum ContentBadgeStyle { standard, onOverlay, cardCorner, profileCardCorner }

/// 演员/短剧徽章，对齐 Web `ContentBadge`。
class ContentBadge extends StatelessWidget {
  final String? badge;
  final ContentBadgeVariant variant;
  final ContentBadgeStyle style;

  const ContentBadge({
    super.key,
    this.badge,
    this.variant = ContentBadgeVariant.issue,
    this.style = ContentBadgeStyle.standard,
  });

  /// Pins a card-corner badge to the top-left of a [Stack].
  ///
  /// The stack must give this a bounded width (via [right]: 0) so the label
  /// can cap at two thirds of the cover and ellipsize.
  static Widget positionedCardCorner({
    String? badge,
    ContentBadgeVariant variant = ContentBadgeVariant.issue,
    ContentBadgeStyle style = ContentBadgeStyle.cardCorner,
  }) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth * 2 / 3
              : double.infinity;
          return Align(
            alignment: Alignment.topLeft,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: ContentBadge(badge: badge, variant: variant, style: style),
            ),
          );
        },
      ),
    );
  }

  // Figma node 521:72807 — 官方/社区/合作/认证
  static const _bgOfficial = StoryColors.contentBadgeOfficial;
  static const _bgCommunity = StoryColors.contentBadgeCommunity;
  static const _bgPartner = StoryColors.contentBadgePartner;
  static const _bgVerified = StoryColors.contentBadgeVerified;

  static const _labelStyle = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.04,
    fontWeight: FontWeight.w400,
    color: Colors.white,
  );

  static const _onOverlayLabelStyle = TextStyle(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.04,
    fontWeight: FontWeight.w400,
    color: Colors.black,
  );

  @override
  Widget build(BuildContext context) {
    final value = variant == ContentBadgeVariant.drama
        ? ContentBadgeValue.resolveDrama(badge)
        : ContentBadgeValue.fromApiValue(badge);
    if (value == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final isDrama = variant == ContentBadgeVariant.drama;
    final isOnOverlay = style == ContentBadgeStyle.onOverlay;
    final isCorner =
        style == ContentBadgeStyle.cardCorner ||
        style == ContentBadgeStyle.profileCardCorner;
    final isProfileCorner = style == ContentBadgeStyle.profileCardCorner;

    final label = switch (value) {
      ContentBadgeValue.official =>
        isDrama
            ? l10n.contentBadgeOfficialDrama
            : l10n.contentBadgeOfficialIssue,
      ContentBadgeValue.community =>
        isDrama
            ? l10n.contentBadgeCommunityDrama
            : l10n.contentBadgeCommunityIssue,
      ContentBadgeValue.partner =>
        isDrama ? l10n.contentBadgePartnerDrama : l10n.contentBadgePartnerIssue,
      ContentBadgeValue.verified =>
        isDrama
            ? l10n.contentBadgeVerifiedDrama
            : l10n.contentBadgeVerifiedIssue,
    };

    final bg = isOnOverlay
        ? Colors.white
        : switch (value) {
            ContentBadgeValue.official => _bgOfficial,
            ContentBadgeValue.community => _bgCommunity,
            ContentBadgeValue.partner => _bgPartner,
            ContentBadgeValue.verified => _bgVerified,
          };

    if (isCorner) {
      // 角色 IP / 个人中心：20px/10r/11；剧场短剧卡：24px/12r/12。
      // 不要设 alignment：Container 有 alignment 会横向撑满 maxWidth，
      // 短文案也会占满父级 2/3，而不是按视觉稿包住文字。
      final radius = isProfileCorner ? 10.0 : 12.0;
      return Container(
        height: isProfileCorner ? 20 : 24,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(radius),
            bottomRight: Radius.circular(radius),
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          textScaler: isProfileCorner ? TextScaler.noScaling : null,
          style: isProfileCorner
              ? const TextStyle(
                  fontSize: 11,
                  height: 12 / 11,
                  letterSpacing: 0.08,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                )
              : _labelStyle,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: isOnOverlay ? _onOverlayLabelStyle : _labelStyle,
      ),
    );
  }
}
