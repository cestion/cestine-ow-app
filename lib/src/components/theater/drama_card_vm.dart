import 'package:equatable/equatable.dart';

import '../../model/models.dart';

/// Cover overlay stat chip on grid [DramaCard].
enum DramaCardCoverStatKind { play, complete, like, heat, rating }

class DramaCardCoverStatVm extends Equatable {
  final DramaCardCoverStatKind kind;
  final String label;

  /// Rating star keeps its native colors on the cover gradient.
  final bool tintIcon;

  const DramaCardCoverStatVm({
    required this.kind,
    required this.label,
    this.tintIcon = true,
  });

  @override
  List<Object?> get props => [kind, label, tintIcon];
}

/// Presentation model for [DramaCard] / [GridDramaCard].
///
/// Built from API models via [DramaCardVmMapper]; the card widget only renders
/// these fields.
class DramaCardVm extends Equatable {
  final String id;
  final String? coverUrl;
  final String? badge;
  final bool showContentBadge;
  final bool isShortVideo;

  /// Whether this card represents one episode of a short drama rather than
  /// the whole series.
  final bool isSingleEpisode;

  /// Whether the collapsible cast-role pill is rendered over the cover.
  final bool showActorRolePill;

  /// Single-video / single-episode duration rendered over the cover (for
  /// example `1:30`).
  final String? durationLabel;

  /// Grid title row.
  final String headline;

  /// Grid subtitle left (`标签 · 全24集`).
  final String? gridMetaLine;

  /// Grid subtitle creator (without `@` prefix).
  final String? gridCreator;

  /// Ordered left-to-right cover stats (play / like / heat / rating).
  final List<DramaCardCoverStatVm> coverStats;

  /// Cast shown on the cover role pill (dialog still uses domain models).
  final List<DramaActorCollection> actors;

  /// Single-row list layout (actor detail, favorites list mode).
  final String? listTitle;
  final String? listDescription;
  final List<String> tags;
  final int? totalEpisodes;
  final String? listCreator;
  final String? listPlayLabel;
  final String? listHeatLabel;
  final double? listRating;

  const DramaCardVm({
    required this.id,
    this.coverUrl,
    this.badge,
    this.showContentBadge = false,
    this.isShortVideo = false,
    this.isSingleEpisode = false,
    this.showActorRolePill = true,
    this.durationLabel,
    required this.headline,
    this.gridMetaLine,
    this.gridCreator,
    this.coverStats = const [],
    this.actors = const [],
    this.listTitle,
    this.listDescription,
    this.tags = const [],
    this.totalEpisodes,
    this.listCreator,
    this.listPlayLabel,
    this.listHeatLabel,
    this.listRating,
  });

  List<DramaActorCollection> get actorsWithAvatar {
    if (!showActorRolePill || actors.isEmpty) return const [];
    return actors
        .where((actor) => actor.avatarUrl?.trim().isNotEmpty == true)
        .toList();
  }

  @override
  List<Object?> get props => [
    id,
    coverUrl,
    badge,
    showContentBadge,
    isShortVideo,
    isSingleEpisode,
    showActorRolePill,
    durationLabel,
    headline,
    gridMetaLine,
    gridCreator,
    coverStats,
    actors,
    listTitle,
    listDescription,
    tags,
    totalEpisodes,
    listCreator,
    listPlayLabel,
    listHeatLabel,
    listRating,
  ];
}
