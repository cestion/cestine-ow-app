import 'package:flutter/material.dart';

import '../../../components/common/actor_role_avatar.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';

/// Displays the main actors/roles cast for this drama.
/// Mirrors H5 PlayDetailCharactersSection.
class DramaCharactersSection extends StatelessWidget {
  final List<RoleCharacter> roles;

  const DramaCharactersSection({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    if (roles.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final brightness = theme.brightness;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.dramaDetailMainCharacters,
          style: StoryTextStyles.headingMedium(
            color: StoryColors.foregroundOf(brightness),
          ),
        ),
        const SizedBox(height: StorySpacing.sm),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: roles.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: StorySpacing.base),
            itemBuilder: (context, index) {
              final role = roles[index];
              return _RoleCastCard(role: role, brightness: brightness);
            },
          ),
        ),
      ],
    );
  }
}

class _RoleCastCard extends StatelessWidget {
  final RoleCharacter role;
  final Brightness brightness;

  const _RoleCastCard({required this.role, required this.brightness});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isBound = role.isBound;
    // Bound → actor IP name + avatar; unbound → "待定演员" + role avatar.
    final displayName = isBound
        ? (role.boundActorName?.trim().isNotEmpty == true
              ? role.boundActorName!.trim()
              : null)
        : l10n.dramaDetailPendingActor;
    final actorId = role.boundActorCollectionId?.trim();
    final canOpenActor = actorId != null && actorId.isNotEmpty;
    final boundAvatar = role.boundActorAvatar?.trim();
    final avatarUrl = isBound && boundAvatar != null && boundAvatar.isNotEmpty
        ? boundAvatar
        : role.avatar?.trim();

    return GestureDetector(
      onTap: canOpenActor
          ? () => openActorDetail(
              context,
              actorId: actorId,
              preview: ActorCollection(
                id: actorId,
                name: role.boundActorName ?? role.name,
                avatarUrl: avatarUrl,
              ),
            )
          : null,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Card handles the tap itself so labels are tappable too.
            ActorRoleAvatar.forRole(
              role,
              size: 60,
              ringWidth: 2,
              // Actor avatar style for every bound role: teal ring + name.
              ringColor: isBound ? StoryColors.brandTeal : null,
              tappable: false,
            ),
            const SizedBox(height: StorySpacing.xxs),
            if (displayName != null && displayName.isNotEmpty)
              Text(
                displayName,
                style: StoryTextStyles.labelSmall(
                  color: isBound
                      ? StoryColors.brandTeal
                      : StoryColors.mutedForegroundOf(brightness),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
