import '../../l10n/app_localizations.dart';
import '../../model/models.dart';
import '../../styles/story_format.dart';
import '../../utils/format_number.dart';
import 'drama_card_vm.dart';

/// Maps API / domain models onto [DramaCardVm].
abstract final class DramaCardVmMapper {
  static DramaCardVm fromTheaterList(
    DramaListItem drama, {
    required AppLocalizations l10n,
    bool showContentBadge = false,
    bool isSingleEpisode = false,
  }) {
    final isShortVideo = WorkContentType.fromApi(drama.type).isShortVideo;
    final singleEpisode =
        !isShortVideo && (isSingleEpisode || _isSingleEpisodeDrama(drama));
    final tags =
        drama.tags?.map((t) => t.trim()).where((t) => t.isNotEmpty).toList() ??
        const <String>[];
    final category = tags.isNotEmpty ? tags.first : null;
    final creator = drama.creatorName?.trim();
    final metaParts = <String>[
      ?category,
      if (!isShortVideo && drama.episodeNo != null)
        l10n.searchEpisodeNo(drama.episodeNo!)
      else if (drama.totalEpisodes != null)
        l10n.dramaAllEpisodesFull(drama.totalEpisodes!),
    ];
    final playCount = drama.totalCompletedViewCount ?? drama.totalPlayCount;
    final title = drama.dramaTitle?.trim() ?? '';
    final description = drama.dramaDescription?.trim() ?? '';
    final headline = isShortVideo
        ? (description.isNotEmpty ? description : l10n.dramaUnnamed)
        : singleEpisode
        ? (description.isNotEmpty
              ? description
              : (title.isNotEmpty ? title : l10n.dramaUnnamed))
        : (title.isNotEmpty ? title : l10n.dramaUnnamed);

    return DramaCardVm(
      id: drama.id,
      coverUrl: drama.dramaCoverUrl,
      badge: drama.badge,
      showContentBadge: showContentBadge,
      isShortVideo: isShortVideo,
      isSingleEpisode: singleEpisode,
      showActorRolePill: !isShortVideo && drama.episodeNo == null,
      durationLabel: _durationLabel(
        shouldShow: isShortVideo || singleEpisode,
        durationSec: drama.durationSec,
      ),
      headline: headline,
      gridMetaLine: metaParts.isEmpty ? null : metaParts.join(' · '),
      gridCreator: creator,
      coverStats: _theaterCoverStats(drama),
      actors: drama.actorCollections ?? const [],
      listTitle: drama.dramaTitle?.trim(),
      listDescription: drama.dramaDescription?.trim(),
      tags: tags,
      totalEpisodes: drama.totalEpisodes,
      listCreator: creator,
      listPlayLabel: playCount != null
          ? StoryFormat.formatCount(playCount)
          : null,
      listHeatLabel: formatHeatValue(drama.totalHeatValue),
      listRating: _visibleAvgRating(drama.avgRating),
    );
  }

  /// Own-profile「作品」tab: effective play (`totalPlayCount`) + like on cover.
  static DramaCardVm fromProfileOwnWorks(
    DramaListItem drama, {
    required AppLocalizations l10n,
  }) {
    final isShortVideo = WorkContentType.fromApi(drama.type).isShortVideo;
    final base = fromTheaterList(
      drama,
      l10n: l10n,
      isSingleEpisode:
          isShortVideo || drama.episodeId?.trim().isNotEmpty == true,
    );
    final playCount = drama.totalPlayCount;
    final coverStats = <DramaCardCoverStatVm>[
      if (playCount != null)
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.play,
          label: StoryFormat.formatCount(playCount),
        ),
      DramaCardCoverStatVm(
        kind: DramaCardCoverStatKind.like,
        label: StoryFormat.formatCount(drama.likeCount ?? 0),
      ),
    ];

    return DramaCardVm(
      id: base.id,
      coverUrl: base.coverUrl,
      badge: base.badge,
      showContentBadge: base.showContentBadge,
      isShortVideo: base.isShortVideo,
      isSingleEpisode: base.isSingleEpisode,
      showActorRolePill: base.showActorRolePill,
      durationLabel: base.durationLabel,
      headline: base.headline,
      gridMetaLine: base.gridMetaLine,
      gridCreator: base.gridCreator,
      coverStats: coverStats,
      actors: base.actors,
      listTitle: base.listTitle,
      listDescription: base.listDescription,
      tags: base.tags,
      totalEpisodes: base.totalEpisodes,
      listCreator: base.listCreator,
      listPlayLabel: playCount != null
          ? StoryFormat.formatCount(playCount)
          : null,
      listHeatLabel: base.listHeatLabel,
      listRating: base.listRating,
    );
  }

  /// Search / recommend [FeedItem] → card VM.
  ///
  /// Drama hits reuse [fromTheaterList] via [FeedItem.toDramaListItem] so the
  /// search「短剧」tab matches the home dual-column theater cards (全 x 集,
  /// heat/rating, cast pill). Short videos keep episode-level play/like stats.
  static DramaCardVm fromSearchFeed(
    FeedItem item, {
    required AppLocalizations l10n,
    bool showContentBadge = false,
  }) {
    if (!item.isShortVideo) {
      // Search「短剧」tab is series-level (same as home theater grid): keep
      // 完播 / 热度 / 评分. Do not mark as single-episode or GridDramaCard
      // strips the completion (play) chip.
      return fromTheaterList(
        item.toDramaListItem(),
        l10n: l10n,
        showContentBadge: showContentBadge,
      );
    }

    final tags = item.tags;
    final category = tags.isNotEmpty ? tags.first : null;
    final metaParts = <String>[
      ?category,
      if (item.totalEpisodes != null)
        l10n.dramaAllEpisodesFull(item.totalEpisodes!),
    ];

    return DramaCardVm(
      id: item.dramaId ?? item.episodeId ?? '',
      coverUrl: item.posterUrl,
      badge: item.badge,
      showContentBadge: showContentBadge,
      isShortVideo: true,
      showActorRolePill: false,
      durationLabel: _durationLabel(
        shouldShow: true,
        durationSec: item.durationSec,
      ),
      headline: item.title?.trim().isNotEmpty == true
          ? item.title!.trim()
          : l10n.dramaUnnamed,
      gridMetaLine: metaParts.isEmpty ? null : metaParts.join(' · '),
      gridCreator: item.creatorName?.trim(),
      coverStats: [
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.play,
          label: StoryFormat.formatCount(item.playCount ?? 0),
        ),
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.like,
          label: StoryFormat.formatCount(item.likeCount ?? 0),
        ),
      ],
      actors: item.uniqueActors
          .map(
            (a) => DramaActorCollection(
              id: a.actorId,
              name: a.actorName,
              avatarUrl: a.avatarUrl,
              storyPerHour: a.storyPerHour,
              computingPower: a.computingPower,
            ),
          )
          .toList(),
    );
  }

  static List<DramaCardCoverStatVm> _theaterCoverStats(DramaListItem drama) {
    final playCount =
        drama.totalCompletedViewCount ?? drama.totalPlayCount ?? 0;
    final stats = <DramaCardCoverStatVm>[
      DramaCardCoverStatVm(
        kind: DramaCardCoverStatKind.complete,
        label: StoryFormat.formatCount(playCount),
      ),
    ];

    if (drama.episodeId != null && drama.episodeId!.isNotEmpty) {
      stats.add(
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.like,
          label: StoryFormat.formatCount(drama.likeCount ?? 0),
        ),
      );
    } else {
      stats.add(
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.heat,
          label: formatHeatValue(drama.totalHeatValue) ?? '0',
        ),
      );
    }

    final rating = _visibleAvgRating(drama.avgRating);
    if (rating != null) {
      stats.add(
        DramaCardCoverStatVm(
          kind: DramaCardCoverStatKind.rating,
          label: rating.toStringAsFixed(1),
          tintIcon: false,
        ),
      );
    }

    return stats;
  }

  static bool _isSingleEpisodeDrama(DramaListItem drama) {
    // Only a concrete episode id means "one episode" UI. Feed discriminators
    // like DRAMA_EPISODE must not hide series completion (完播) on search /
    // theater drama cards that intentionally omit episodeId.
    return drama.episodeId?.trim().isNotEmpty == true;
  }

  /// Home / search drama cards hide rating when missing or zero.
  static double? _visibleAvgRating(double? avgRating) {
    if (avgRating == null || avgRating <= 0) return null;
    return avgRating;
  }

  static String? _durationLabel({
    required bool shouldShow,
    required int? durationSec,
  }) {
    if (!shouldShow || durationSec == null || durationSec <= 0) return null;
    return StoryFormat.formatDuration(durationSec * 1000);
  }
}
