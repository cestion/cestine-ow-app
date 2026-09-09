import 'package:flutter/material.dart';

import '../../model/models.dart';
import '../../routes/actor_detail_navigation.dart';
import '../../widgets/story_avatar.dart';

/// Unified actor/role avatar used across the theater banner, drama cards,
/// the drama-detail cast row and the feed overlay.
///
/// Visuals delegate to [StoryAvatar] (custom URL → identicon fallback); an
/// optional [ringColor] draws a border ring on top. When [actorId] is
/// non-empty, tapping opens the actor detail page and seeds the list-card
/// preview cache so the destination renders instantly.
class ActorRoleAvatar extends StatelessWidget {
  final String? avatarUrl;

  /// Actor collection id; tap navigation is enabled only when non-empty.
  final String? actorId;

  /// Actor display name — identicon seed and detail-page preview.
  final String? actorName;
  final double size;
  final Color? ringColor;
  final double ringWidth;

  /// Set to `false` when a parent widget already handles the tap.
  final bool tappable;

  const ActorRoleAvatar({
    super.key,
    required this.size,
    this.avatarUrl,
    this.actorId,
    this.actorName,
    this.ringColor,
    this.ringWidth = 1.5,
    this.tappable = true,
  });

  /// Builds from a drama [RoleCharacter]: prefers the bound actor's IP avatar
  /// and falls back to the role's own avatar.
  factory ActorRoleAvatar.forRole(
    RoleCharacter role, {
    Key? key,
    required double size,
    Color? ringColor,
    double ringWidth = 1.5,
    bool tappable = true,
  }) {
    final boundAvatar = role.boundActorAvatar?.trim();
    final avatarUrl =
        role.isBound && boundAvatar != null && boundAvatar.isNotEmpty
        ? boundAvatar
        : role.avatar?.trim();
    return ActorRoleAvatar(
      key: key,
      size: size,
      avatarUrl: avatarUrl,
      actorId: role.boundActorCollectionId,
      actorName: role.boundActorName ?? role.name,
      ringColor: ringColor,
      ringWidth: ringWidth,
      tappable: tappable,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = StoryAvatar(
      imageUrl: avatarUrl,
      fallbackText: actorName,
      size: size,
    );
    if (ringColor != null) {
      avatar = Container(
        width: size,
        height: size,
        foregroundDecoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ringColor!, width: ringWidth),
        ),
        child: avatar,
      );
    }

    final id = actorId?.trim();
    if (!tappable || id == null || id.isEmpty) return avatar;

    return GestureDetector(
      onTap: () => openActorDetail(
        context,
        actorId: id,
        preview: ActorCollection(id: id, name: actorName, avatarUrl: avatarUrl),
      ),
      behavior: HitTestBehavior.opaque,
      child: avatar,
    );
  }
}
