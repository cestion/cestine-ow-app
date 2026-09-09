import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../l10n/story_l10n.dart';
import '../../model/follow_models.dart';
import '../../styles/story_text_styles.dart';
import '../profile/profile_colors.dart';

/// Compact relation CTA for follow lists — Figma `358:98084` / `358:88369`
/// (`Button/New primary`, radius 12).
class FollowRelationButton extends StatelessWidget {
  final FollowRelationStatus status;
  final bool loading;
  final VoidCallback? onPressed;

  const FollowRelationButton({
    super.key,
    required this.status,
    this.loading = false,
    this.onPressed,
  });

  static const _radius = BorderRadius.all(Radius.circular(12));

  static String labelFor(AppLocalizations l10n, FollowRelationStatus status) {
    return switch (status) {
      FollowRelationStatus.followBack => l10n.followActionFollowBack,
      FollowRelationStatus.mutual => l10n.followActionMutual,
      FollowRelationStatus.following => l10n.followActionFollowing,
      FollowRelationStatus.none => l10n.followActionFollow,
    };
  }

  bool get _isPrimary =>
      status == FollowRelationStatus.none ||
      status == FollowRelationStatus.followBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final bg = _isPrimary
        ? ProfileColors.followPrimaryBg(brightness)
        : ProfileColors.followSecondaryBg(brightness);
    final fg = _isPrimary
        ? ProfileColors.followPrimaryFg(brightness)
        : ProfileColors.followSecondaryFg(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: loading ? null : onPressed,
        borderRadius: _radius,
        child: Container(
          constraints: const BoxConstraints(minWidth: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(color: bg, borderRadius: _radius),
          alignment: Alignment.center,
          // Text line 18 + vertical padding 2×2 — keep slot fixed while loading.
          child: SizedBox(
            height: 22,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Text(
                      labelFor(l10n, status),
                      style: StoryTextStyles.labelMedium(color: fg).copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 18 / 13,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
