import 'package:flutter/material.dart';

import '../../l10n/story_l10n.dart';
import '../../model/models.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../utils/format_number.dart';
import '../../widgets/story_cached_image.dart';

/// Actor IP search result card — Figma 6640:68215 (light) / 6646:70499 (dark).
///
/// Mirrors Web `ActorSearchDropdownCard` in `ActorPlazaView.tsx`.
class SearchActorCard extends StatelessWidget {
  final ActorCollection actor;
  final VoidCallback? onTap;

  const SearchActorCard({super.key, required this.actor, this.onTap});

  static const _avatarWidth = 100.0;
  static const _avatarHeight = 83.0;
  static const _avatarRadius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final l10n = context.l10n;
    final name = actor.name?.trim();
    final bio = actor.bio?.trim();
    final completionCount = actor.completedViewCountInt ?? 0;
    final heatValue = actor.heatValue ?? 0;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: _avatarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Avatar(url: actor.avatarUrl, brightness: brightness),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (name != null && name.isNotEmpty) ? name : '—',
                        style: TextStyle(
                          fontSize: 16,
                          height: 24 / 16,
                          fontWeight: FontWeight.w700,
                          color: StoryColors.foregroundOf(brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (bio != null && bio.isNotEmpty) ? bio : '',
                        style: TextStyle(
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: 0.04,
                          fontWeight: FontWeight.w400,
                          color: StoryColors.mutedForegroundOf(brightness),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _MetricChip(
                        label:
                            '${l10n.actorStatCompletion} ${formatNumber(completionCount, 0)}',
                        brightness: brightness,
                      ),
                      const SizedBox(width: 6),
                      _MetricChip(
                        label:
                            '${l10n.actorHeatCoefficient} ${formatNumber(heatValue)}',
                        brightness: brightness,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final Brightness brightness;

  const _Avatar({required this.url, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final trimmed = url?.trim();
    final hasUrl = trimmed != null && trimmed.isNotEmpty;
    final placeholder = ColoredBox(
      color: StoryColors.mutedOf(brightness),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 28,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );

    return ClipRRect(
      borderRadius: SearchActorCard._avatarRadius,
      child: SizedBox(
        width: SearchActorCard._avatarWidth,
        height: SearchActorCard._avatarHeight,
        child: hasUrl
            ? StoryCachedImage(
                imageUrl: trimmed,
                memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
                  context,
                  SearchActorCard._avatarWidth,
                ),
                placeholder: placeholder,
                errorWidget: placeholder,
              )
            : placeholder,
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final Brightness brightness;

  const _MetricChip({required this.label, required this.brightness});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.sm,
        vertical: StorySpacing.xs,
      ),
      decoration: BoxDecoration(
        color: StoryColors.actorHeroBadgeBgOf(brightness),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          height: 16 / 12,
          letterSpacing: 0.04,
          fontWeight: FontWeight.w400,
          color: StoryColors.mutedForegroundOf(brightness),
        ),
      ),
    );
  }
}
