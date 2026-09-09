import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/story_constants.dart';
import '../../widgets/story_cached_image.dart';

import '../../l10n/story_l10n.dart';
import '../../styles/story_colors.dart';
import '../../styles/story_spacing.dart';
import '../../styles/story_text_styles.dart';

class DramaRoleCard extends StatelessWidget {
  final String roleName;
  final String bio;
  final String? avatarUrl;
  final String? localAvatarPath;
  final String? boundActorName;
  final VoidCallback? onBindActor;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// 该角色绑定是否来自后端持久化；为 true 时锁定 bind/delete 按钮，
  /// 避免覆盖已落库的绑定关系。本地选择/解绑后置 false，按钮恢复可用。
  final bool actorBindingLocked;

  const DramaRoleCard({
    super.key,
    required this.roleName,
    required this.bio,
    this.avatarUrl,
    this.localAvatarPath,
    this.boundActorName,
    this.onBindActor,
    this.onEdit,
    this.onDelete,
    this.actorBindingLocked = false,
  });

  bool get _isActorBound =>
      boundActorName != null && boundActorName!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: StorySpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: StoryColors.cardOf(theme.brightness),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: StoryColors.dividerOf(theme.brightness)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 600 / 500,
            child: _buildCover(context, theme),
          ),
          Padding(
            padding: const EdgeInsets.all(StorySpacing.base),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleName,
                  style: StoryTextStyles.headingMedium(
                    color: StoryColors.foregroundOf(theme.brightness),
                  ).copyWith(fontWeight: FontWeight.w700, height: 24 / 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: StorySpacing.sm),
                Text(
                  bio,
                  style: StoryTextStyles.bodySmall(
                    color: StoryColors.mutedForegroundOf(theme.brightness),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: StorySpacing.md),
                if (!_isActorBound)
                  _RoleCardButton.filled(
                    label: boundActorName ?? l10n.createDramaBindActor,
                    onTap: onBindActor,
                    disabled: actorBindingLocked,
                  )
                else
                  _RoleCardButton.outline(
                    label: boundActorName ?? l10n.createDramaBindActor,
                    onTap: onBindActor,
                    disabled: actorBindingLocked,
                  ),
                const SizedBox(height: StorySpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _RoleCardButton.outline(
                        label: l10n.creatorDramaDelete,
                        onTap: onDelete,
                        disabled: actorBindingLocked,
                      ),
                    ),
                    const SizedBox(width: StorySpacing.md),
                    Expanded(
                      child: _RoleCardButton.outline(
                        label: l10n.creatorDramaEdit,
                        onTap: onEdit,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(BuildContext context, ThemeData theme) {
    final localPath = localAvatarPath;
    if (localPath != null && localPath.isNotEmpty) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }
    final url = avatarUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        memCacheWidth: StoryCachedImage.memCacheForLogicalWidth(
          context,
          StoryImageCache.coverRole,
        ),
        placeholder: (context, _) =>
            ColoredBox(color: StoryColors.mutedOf(theme.brightness)),
        errorWidget: (context, _, _) => _placeholderIcon(theme),
      );
    }
    return _placeholderIcon(theme);
  }

  Widget _placeholderIcon(ThemeData theme) {
    return ColoredBox(
      color: StoryColors.mutedOf(theme.brightness),
      child: Center(
        child: Icon(
          Icons.person_outline,
          size: 48,
          color: StoryColors.mutedForegroundOf(theme.brightness),
        ),
      ),
    );
  }
}

class _RoleCardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool _filled;

  final bool disabled;

  const _RoleCardButton.filled({
    required this.label,
    this.onTap,
    this.disabled = false,
  }) : _filled = true;

  const _RoleCardButton.outline({
    required this.label,
    this.onTap,
    this.disabled = false,
  }) : _filled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = disabled
        ? StoryColors.mutedForegroundOf(theme.brightness)
        : (_filled
              ? StoryColors.onOverlay
              : StoryColors.foregroundOf(theme.brightness));
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      color: _filled ? StoryColors.darkMuted : Colors.transparent,
      child: InkWell(
        onTap: disabled ? null : onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: _filled
                ? null
                : Border.all(color: StoryColors.dividerOf(theme.brightness)),
          ),
          child: Text(
            label,
            style: StoryTextStyles.labelLarge(
              color: foreground,
            ).copyWith(fontWeight: FontWeight.w700, height: 20 / 14),
          ),
        ),
      ),
    );
  }
}
