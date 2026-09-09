import 'dart:ui';

import 'package:flutter/material.dart';

import '../../model/models.dart';
import '../../routes/actor_detail_navigation.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';
import '../common/actor_role_avatar.dart';
import '../common/story_per_hour_unit_label.dart';

/// Glassmorphic horizontal cast strip on the theater hero banner.
///
/// Avatar + white ring + status dot, then name / points-icon/h stacked under it.
class TheaterHeroActorStrip extends StatelessWidget {
  final List<DramaActorCollection> actors;

  static const int maxVisible = 5;
  static const double _avatarSize = 44;
  static const double _itemWidth = 58;
  static const double _radius = 16;

  const TheaterHeroActorStrip({super.key, required this.actors});

  @override
  Widget build(BuildContext context) {
    final visible = actors.take(maxVisible).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(_radius)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.all(Radius.circular(_radius)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SizedBox(width: StorySpacing.sm),
                    _HeroActorItem(actor: visible[i]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroActorItem extends StatelessWidget {
  final DramaActorCollection actor;

  const _HeroActorItem({required this.actor});

  @override
  Widget build(BuildContext context) {
    final name = actor.name?.trim() ?? '';
    final rate = ActorHourlyRate.format(actor.payRate);
    final id = actor.id?.trim();
    final unitStyle = StoryTextStyles.labelSmall(
      color: StoryColors.onOverlaySubtle,
    ).copyWith(fontSize: 9, height: 1.1);

    final Widget column = SizedBox(
      width: TheaterHeroActorStrip._itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: TheaterHeroActorStrip._avatarSize,
            height: TheaterHeroActorStrip._avatarSize,
            child: ActorRoleAvatar(
              size: TheaterHeroActorStrip._avatarSize,
              avatarUrl: actor.avatarUrl,
              actorId: actor.id,
              actorName: actor.name,
              ringColor: StoryColors.onOverlay,
              tappable: false,
            ),
          ),
          const SizedBox(height: StorySpacing.xs),
          if (name.isNotEmpty)
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: StoryTextStyles.labelSmall(
                color: StoryColors.onOverlay,
              ).copyWith(fontWeight: FontWeight.w600, height: 1.15),
            ),
          if (rate != null) ...[
            Text(
              rate,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: StoryTextStyles.labelMedium(
                color: StoryColors.onOverlay,
              ).copyWith(fontWeight: FontWeight.w700, height: 1.15),
            ),
            StoryPerHourUnitLabel(iconSize: 9, textStyle: unitStyle),
          ],
        ],
      ),
    );

    if (id == null || id.isEmpty) return column;
    return GestureDetector(
      onTap: () => openActorDetail(
        context,
        actorId: id,
        preview: ActorCollection(
          id: id,
          name: actor.name,
          avatarUrl: actor.avatarUrl,
        ),
      ),
      behavior: HitTestBehavior.opaque,
      child: column,
    );
  }
}
