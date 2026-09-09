import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../components/common/actor_role_avatar.dart';
import '../../../components/common/story_per_hour_unit_label.dart';
import '../../../l10n/story_l10n.dart';
import '../../../model/models.dart';
import '../../../provider/app_providers.dart';
import '../../../provider/tab_index_provider.dart';
import '../../../routes/actor_detail_navigation.dart';
import '../../../styles/story_colors.dart';
import '../../../styles/story_radius.dart';
import '../../../styles/story_spacing.dart';
import '../../../styles/story_text_styles.dart';
import '../../../utils/actor_data_sync.dart';

({Color background, Color foreground}) _compactSignButtonColors(
  Brightness brightness,
) => (
  background: StoryColors.actorSignSheetConfirmBgOf(brightness),
  foreground: StoryColors.actorSignSheetConfirmFgOf(brightness),
);

/// Vertical cast list for the recommend-feed drama overlay (H5 play-detail).
class DramaCharactersList extends StatelessWidget {
  final List<RoleCharacter> roles;

  const DramaCharactersList({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        StorySpacing.screenHorizontal,
        StorySpacing.base,
        StorySpacing.screenHorizontal,
        StorySpacing.xl,
      ),
      itemCount: roles.isEmpty ? 2 : roles.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return const _SignMoreBanner();

        return Padding(
          padding: EdgeInsets.only(
            top: index == 1 ? StorySpacing.base : StorySpacing.lg,
          ),
          child: roles.isEmpty
              ? const _CharactersEmptyState()
              : _CharacterRow(role: roles[index - 1]),
        );
      },
    );
  }
}

class _CharactersEmptyState extends StatelessWidget {
  const _CharactersEmptyState();

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: StorySpacing.base,
        vertical: 111,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/common/drama_characters_empty.svg',
            width: 68,
            height: 68,
          ),
          const SizedBox(height: StorySpacing.base),
          Text(
            context.l10n.dramaDetailCharactersEmpty,
            textAlign: TextAlign.center,
            style: StoryTextStyles.bodyMedium(
              color: StoryColors.mutedForegroundOf(brightness),
            ).copyWith(height: 20 / 14),
          ),
        ],
      ),
    );
  }
}

class _SignMoreBanner extends ConsumerWidget {
  const _SignMoreBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final foreground = StoryColors.foregroundOf(brightness);
    final buttonColors = _compactSignButtonColors(brightness);

    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: StoryColors.dividerOf(brightness), width: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          // Return to the main shell before switching to the character-IP tab.
          ref.read(tabIndexProvider.notifier).setIndex(StoryTab.nft.index);
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
        child: Padding(
          padding: const EdgeInsets.all(StorySpacing.md),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: buttonColors.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.add,
                  size: 16,
                  color: buttonColors.foreground,
                ),
              ),
              const SizedBox(width: StorySpacing.sm),
              Expanded(
                child: Text(
                  l10n.dramaDetailSignMoreCharacterIps,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoryTextStyles.bodyMedium(color: foreground).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 22 / 15,
                  ),
                ),
              ),
              SizedBox.square(
                dimension: 32,
                child: Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: StoryColors.mutedForegroundOf(brightness),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CharacterRow extends ConsumerWidget {
  final RoleCharacter role;

  const _CharacterRow({required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final brightness = Theme.of(context).brightness;
    final isBound = role.isBound;
    final actorId = role.boundActorCollectionId?.trim();
    final canOpenActor = actorId != null && actorId.isNotEmpty;
    final boundAvatar = role.boundActorAvatar?.trim();
    final avatarUrl = isBound && boundAvatar != null && boundAvatar.isNotEmpty
        ? boundAvatar
        : role.avatar?.trim();
    final actorName = isBound
        ? (role.boundActorName?.trim().isNotEmpty == true
              ? role.boundActorName!.trim()
              : l10n.dramaDetailPendingActor)
        : l10n.dramaDetailPendingActor;

    ActorCollection? detail;
    if (canOpenActor) {
      detail = ref
          .watch(actorCollectionDetailProvider(actorId))
          .asData
          ?.value
          .dataOrNull;
    }
    final salaryAmount = ActorHourlyRate.format(
      role.boundRate
          .overlay(
            detail == null
                ? null
                : ActorHourlyRate(computingPower: detail.computingPower),
          )
          .payValue,
    );
    final preview = ActorCollection(
      id: actorId,
      name: role.boundActorName ?? role.name,
      avatarUrl: avatarUrl,
    );

    return GestureDetector(
      onTap: canOpenActor
          ? () => openActorDetail(context, actorId: actorId, preview: preview)
          : null,
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActorRoleAvatar.forRole(
            role,
            size: 40,
            ringColor: isBound ? StoryColors.star : null,
            tappable: false,
          ),
          const SizedBox(width: StorySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actorName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: StoryTextStyles.bodyMedium(
                    color: StoryColors.foregroundOf(brightness),
                  ).copyWith(fontSize: 15, height: 22 / 15),
                ),
                const SizedBox(height: StorySpacing.xs),
                _SalaryChip(
                  highlighted: isBound,
                  brightness: brightness,
                  child: isBound
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.dramaDetailRoleSalary(salaryAmount ?? '-'),
                            ),
                            const SizedBox(width: 2),
                            const StoryPerHourUnitLabel(iconSize: 10),
                          ],
                        )
                      : Text(l10n.dramaDetailRoleUnbound),
                ),
              ],
            ),
          ),
          if (isBound && canOpenActor) ...[
            const SizedBox(width: StorySpacing.sm),
            _SignButton(
              onTap: () =>
                  showActorSignFlowWithFreshDetail(context, ref, preview),
            ),
          ],
        ],
      ),
    );
  }
}

class _SalaryChip extends StatelessWidget {
  static const _lightForeground = Color(0xFFD99902);

  final Widget child;
  final bool highlighted;
  final Brightness brightness;

  const _SalaryChip({
    required this.child,
    required this.highlighted,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = highlighted
        ? (brightness == Brightness.dark ? StoryColors.star : _lightForeground)
        : StoryColors.mutedForegroundOf(brightness);
    final style = TextStyle(
      color: foreground,
      fontSize: 13,
      fontWeight: FontWeight.w400,
      height: 18 / 13,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? StoryColors.star.withValues(alpha: 0.05)
            : Colors.transparent,
        border: highlighted
            ? Border.all(color: StoryColors.star.withValues(alpha: 0.15))
            : null,
        borderRadius: StoryRadius.brPill,
      ),
      child: DefaultTextStyle.merge(
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: child,
      ),
    );
  }
}

class _SignButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SignButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final buttonColors = _compactSignButtonColors(brightness);

    return Material(
      color: buttonColors.background,
      borderRadius: StoryRadius.brPill,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 32,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: StorySpacing.md),
            child: Center(
              child: Text(
                context.l10n.actorSign,
                style: TextStyle(
                  color: buttonColors.foreground,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
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
