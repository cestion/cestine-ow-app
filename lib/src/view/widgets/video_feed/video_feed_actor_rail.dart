import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../components/common/actor_role_avatar.dart';
import '../../../components/common/story_per_hour_unit_label.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

/// Left-side role IP rail on the recommend / playback feed (avatar + icon/h).
///
/// Rates use [RecommendFeedActor.payRate] (storyPerHour → computingPower),
/// never NFT [RecommendFeedActor.unitPrice].
class VideoFeedActorRail extends StatelessWidget {
  final List<RecommendFeedActor> actors;

  /// Opens the drama-detail overlay (roles tab) when the rail is tapped.
  final VoidCallback? onTap;

  static const double _avatarSize = 32;
  static const double _itemWidth = 44;

  const VideoFeedActorRail({super.key, required this.actors, this.onTap});

  /// Thousands grouping with ASCII commas (matches design `6,344`).
  /// Whole numbers stay integer; fractional values keep up to 2 decimals
  /// (e.g. NFT `unitPrice` `0.01`). Returns `'0'` when the rate is zero
  /// or omitted so the rail always paints icon/h.
  static String formatStoryPerHour(num? value) =>
      ActorHourlyRate.format(value) ?? '0';

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();

    final column = Padding(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.xs,
        StorySpacing.sm,
        StorySpacing.xs,
        StorySpacing.sm,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actors.length; i++) ...[
            if (i > 0) const SizedBox(height: StorySpacing.md),
            _ActorRailItem(
              actor: actors[i],
              tappable: onTap == null,
            ),
          ],
        ],
      ),
    );

    final rail = ClipRRect(
      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(12),
            ),
          ),
          child: column,
        ),
      ),
    );

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!constraints.hasBoundedHeight) return rail;
            return ConstrainedBox(
              constraints: BoxConstraints(maxHeight: constraints.maxHeight),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: rail,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActorRailItem extends StatelessWidget {
  final RecommendFeedActor actor;
  final bool tappable;

  const _ActorRailItem({
    required this.actor,
    this.tappable = true,
  });

  @override
  Widget build(BuildContext context) {
    final unitStyle = StoryTextStyles.labelSmall(
      color: StoryColors.onOverlaySubtle,
    ).copyWith(height: 1.2);

    return SizedBox(
      width: VideoFeedActorRail._itemWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ActorRoleAvatar(
            size: VideoFeedActorRail._avatarSize,
            avatarUrl: actor.avatarUrl,
            actorId: actor.actorId,
            actorName: actor.actorName,
            ringColor: StoryColors.onOverlay,
            ringWidth: 1,
            tappable: tappable,
          ),
          const SizedBox(height: StorySpacing.xs),
          _ActorRailPayRate(actor: actor),
          StoryPerHourUnitLabel(iconSize: 9, textStyle: unitStyle),
        ],
      ),
    );
  }
}

/// Matches [DramaCharactersList]: overlay actor-detail `computingPower` so
/// sub-cent pay rates are not lost when roles only carry placeholder `0`.
class _ActorRailPayRate extends ConsumerWidget {
  final RecommendFeedActor actor;

  const _ActorRailPayRate({required this.actor});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actorId = actor.actorId?.trim();
    ActorHourlyRate? detailRates;
    if (actorId != null && actorId.isNotEmpty) {
      final detail = ref
          .watch(actorCollectionDetailProvider(actorId))
          .asData
          ?.value
          .dataOrNull;
      if (detail?.computingPower != null) {
        detailRates = ActorHourlyRate(computingPower: detail!.computingPower);
      }
    }
    final label = VideoFeedActorRail.formatStoryPerHour(
      actor.rate.overlay(detailRates).payValue,
    );
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: StoryTextStyles.labelMedium(
        color: StoryColors.onOverlay,
      ).copyWith(fontWeight: FontWeight.w600, height: 1.2),
    );
  }
}
