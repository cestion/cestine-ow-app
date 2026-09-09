import 'dart:ui';

import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../routes/actor_detail_navigation.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../common/actor_role_avatar.dart';
import '../common/story_per_hour_unit_label.dart';

/// Modal listing cast character IPs for a drama card (Figma 参演角色IP).
class DramaCastActorsDialog extends StatelessWidget {
  final List<DramaActorCollection> actors;

  const DramaCastActorsDialog({super.key, required this.actors});

  static Future<void> show(
    BuildContext context, {
    required List<DramaActorCollection> actors,
  }) {
    if (actors.isEmpty) return Future<void>.value();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      builder: (ctx) => DramaCastActorsDialog(actors: actors),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final fg = StoryColors.foregroundOf(brightness);
    final muted = StoryColors.mutedForegroundOf(brightness);

    return Dialog(
      backgroundColor: StoryColors.backgroundOf(brightness),
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.dramaCastActorsTitle,
              textAlign: TextAlign.center,
              style: StoryTextStyles.titleMedium(color: fg).copyWith(
                fontSize: 18,
                height: 26 / 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: StorySpacing.base),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: actors.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: StorySpacing.sm),
                itemBuilder: (context, index) {
                  final actor = actors[index];
                  return _CastActorRow(
                    actor: actor,
                    fg: fg,
                    muted: muted,
                    // Light: Figma rgba(240, 240, 243, 1) / #F0F0F3
                    rowBg: brightness == Brightness.light
                        ? StoryColors.lightSheetSecondary
                        : StoryColors.fillSecondaryOf(brightness),
                  );
                },
              ),
            ),
            const SizedBox(height: StorySpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: fg,
                  side: BorderSide(color: StoryColors.borderOf(brightness)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                child: Text(
                  l10n.commonClose,
                  style: StoryTextStyles.labelLarge(
                    color: fg,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CastActorRow extends StatelessWidget {
  final DramaActorCollection actor;
  final Color fg;
  final Color muted;
  final Color rowBg;

  const _CastActorRow({
    required this.actor,
    required this.fg,
    required this.muted,
    required this.rowBg,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = actor.id?.trim();
    final canOpen = id != null && id.isNotEmpty;
    final name = actor.name?.trim().isNotEmpty == true
        ? actor.name!.trim()
        : l10n.dramaDetailPendingActor;
    final rate = ActorHourlyRate.format(actor.payRate);
    final salaryColor = rate != null ? StoryColors.star : muted;
    final salaryStyle = StoryTextStyles.caption(
      color: salaryColor,
    ).copyWith(fontWeight: FontWeight.w600);

    return Material(
      color: rowBg,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      child: InkWell(
        onTap: canOpen
            ? () {
                Navigator.of(context).pop();
                openActorDetail(
                  context,
                  actorId: id,
                  preview: ActorCollection(
                    id: id,
                    name: actor.name,
                    avatarUrl: actor.avatarUrl,
                  ),
                );
              }
            : null,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
          child: Row(
            children: [
              ActorRoleAvatar(
                size: 40,
                avatarUrl: actor.avatarUrl,
                actorId: actor.id,
                actorName: actor.name,
                tappable: false,
              ),
              const SizedBox(width: StorySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: StoryTextStyles.bodyMedium(
                        color: fg,
                      ).copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (rate != null)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              l10n.dramaDetailRoleSalary(rate),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: salaryStyle,
                            ),
                          ),
                          const SizedBox(width: 2),
                          StoryPerHourUnitLabel(
                            iconSize: 10,
                            textStyle: salaryStyle,
                          ),
                        ],
                      )
                    else
                      Text(
                        l10n.dramaDetailRoleUnbound,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: salaryStyle,
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 20, color: muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic overlapping-avatar + points-icon/h pill on the drama cover.
class DramaCardRolePill extends StatelessWidget {
  final List<DramaActorCollection> actors;
  final VoidCallback? onTap;

  static const double avatarSize = 32;
  static const double overlap = 12;
  static const int maxAvatars = 5;

  const DramaCardRolePill({super.key, required this.actors, this.onTap});

  static num? totalStoryPerHour(List<DramaActorCollection> actors) {
    num total = 0;
    var hasRate = false;
    for (final a in actors) {
      final v = a.rate.payValue;
      if (v == null) continue;
      total += v;
      hasRate = true;
    }
    return hasRate ? total : null;
  }

  static double overlapForCount(int count) {
    if (count >= maxAvatars) return 16;
    return overlap;
  }

  static double stackWidthForCount(int count) {
    if (count <= 0) return 0;
    final step = avatarSize - overlapForCount(count);
    return avatarSize + (count - 1) * step;
  }

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();
    final visible = actors.take(maxAvatars).toList();
    final total = totalStoryPerHour(actors);
    final rate = ActorHourlyRate.format(total) ?? '0';
    final stackWidth = stackWidthForCount(visible.length);
    final avatarOverlap = overlapForCount(visible.length);
    final avatarStep = avatarSize - avatarOverlap;
    final unitStyle = TextStyle(
      fontSize: 9,
      height: 1.1,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.75),
    );

    Widget buildRow() {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: stackWidth,
            height: avatarSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var i = 0; i < visible.length; i++)
                  Positioned(
                    left: i * avatarStep,
                    child: _PillAvatar(actor: visible[i], size: avatarSize),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                rate,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              StoryPerHourUnitLabel(iconSize: 9, textStyle: unitStyle),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final row = buildRow();
                  if (!constraints.hasBoundedWidth) return row;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: row,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PillAvatar extends StatelessWidget {
  final DramaActorCollection actor;
  final double size;

  const _PillAvatar({required this.actor, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: ActorRoleAvatar(
        size: size,
        avatarUrl: actor.avatarUrl,
        actorId: actor.id,
        actorName: actor.name,
        tappable: false,
      ),
    );
  }
}
