import 'package:equatable/equatable.dart';

import '../core/video_url_helpers.dart';
import 'drama_model.dart';
import 'json_converters.dart';
import 'recommend_card_json.dart';
import 'work_content_type.dart';

/// Query `type` for `GET /api/recommend/search`.
enum RecommendSearchType {
  all,
  drama,
  shortVideo;

  String get apiValue => switch (this) {
    RecommendSearchType.all => 'all',
    RecommendSearchType.drama => 'drama',
    RecommendSearchType.shortVideo => 'short_video',
  };

  static RecommendSearchType fromApi(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'drama':
      case 'drama_episode':
        return RecommendSearchType.drama;
      case 'short_video':
        return RecommendSearchType.shortVideo;
      case 'all':
      default:
        return RecommendSearchType.all;
    }
  }
}

class FeedActor extends Equatable {
  final String? actorId;
  final String? actorName;
  final String? avatarUrl;
  final String? badge;
  final double? trust;
  final double? computingPower;
  final int? storyPerHour;

  const FeedActor({
    this.actorId,
    this.actorName,
    this.avatarUrl,
    this.badge,
    this.trust,
    this.computingPower,
    this.storyPerHour,
  });

  factory FeedActor.fromJson(Map<String, dynamic> json) {
    return FeedActor(
      actorId: asString(json['actorId']) ?? asString(json['actorCollectionId']),
      actorName:
          asString(json['actorName']) ?? asString(json['actorCollectionName']),
      avatarUrl:
          asString(json['avatarUrl']) ??
          asString(json['actorCollectionAvatar']) ??
          asString(json['avatar']),
      badge: asString(json['badge']),
      trust: asDouble(json['trust']),
      computingPower: asDouble(json['computingPower']),
      storyPerHour: asInt(json['storyPerHour']),
    );
  }

  @override
  List<Object?> get props => [
    actorId,
    actorName,
    avatarUrl,
    badge,
    trust,
    computingPower,
    storyPerHour,
  ];
}

/// Single item from recommend feed / search (`FeedItemResponse`).
class FeedItem extends Equatable {
  /// `drama_episode` or `short_video`.
  final String? contentType;
  final String? dramaId;
  final String? episodeId;
  final int? episodeNo;

  /// Video length in seconds (`FeedItemResponse.durationSec`).
  final int? durationSec;
  final String? title;
  final String? description;
  final String? dramaDescription;
  final String? episodeDescription;
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  final String? firstFrameUrl;
  final String? mediaAccessUrl;
  final String? playbackType;
  final double? avgRating;
  final int? totalEpisodes;
  final String? badge;
  final int? likeCount;
  final int? commentCount;
  final int? favoriteCount;
  final int? playCount;
  final int? completeCount;
  final double? totalHeatValue;
  final bool? likedByMe;
  final bool? favoritedByMe;
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatar;
  final List<String> tags;
  final List<FeedActor> actors;
  final double? score;
  final String? reason;

  /// Optional publish time from backfill (ISO / epoch); may be absent.
  final String? publishedAt;

  const FeedItem({
    this.contentType,
    this.dramaId,
    this.episodeId,
    this.episodeNo,
    this.durationSec,
    this.title,
    this.description,
    this.dramaDescription,
    this.episodeDescription,
    this.coverUrl,
    this.firstFrameUrl,
    this.mediaAccessUrl,
    this.playbackType,
    this.avgRating,
    this.totalEpisodes,
    this.badge,
    this.likeCount,
    this.commentCount,
    this.favoriteCount,
    this.playCount,
    this.completeCount,
    this.totalHeatValue,
    this.likedByMe,
    this.favoritedByMe,
    this.creatorId,
    this.creatorName,
    this.creatorAvatar,
    this.tags = const [],
    this.actors = const [],
    this.score,
    this.reason,
    this.publishedAt,
  });

  bool get isShortVideo => WorkContentType.fromApi(contentType).isShortVideo;

  /// Poster for list / player chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  /// Description for a whole-series card or expanded drama playlist entry.
  String? get resolvedDramaDescription => dramaDescription ?? description;

  /// Description for a concrete episode / standalone short-video card.
  String? get resolvedEpisodeDescription => episodeDescription ?? description;

  factory FeedItem.fromJson(Map<String, dynamic> json) {
    json = flattenRecommendCardJson(json);
    final tagsRaw = json['tags'];
    final tags = <String>[];
    if (tagsRaw is List) {
      for (final t in tagsRaw) {
        final s = asString(t);
        if (s != null && s.isNotEmpty) tags.add(s);
      }
    }
    final actorsRaw = json['actors'];
    final actors = <FeedActor>[];
    if (actorsRaw is List) {
      for (final a in actorsRaw) {
        if (a is Map<String, dynamic>) {
          actors.add(FeedActor.fromJson(a));
        } else if (a is Map) {
          actors.add(FeedActor.fromJson(Map<String, dynamic>.from(a)));
        }
      }
    }
    return FeedItem(
      contentType: asString(json['contentType']),
      dramaId: asString(json['dramaId']),
      episodeId: asString(json['episodeId']),
      episodeNo: asInt(json['episodeNo']),
      durationSec: asInt(json['durationSec']),
      title: asString(json['title']),
      description: asString(json['description']),
      dramaDescription: asString(json['dramaDescription']),
      episodeDescription: asString(json['episodeDescription']),
      coverUrl: asString(json['coverUrl']),
      firstFrameUrl: asString(json['firstFrameUrl']),
      mediaAccessUrl: asString(json['mediaAccessUrl']),
      playbackType: asString(json['playbackType']),
      avgRating: asDouble(json['avgRating']),
      totalEpisodes: asInt(json['totalEpisodes']),
      badge: asString(json['badge']),
      likeCount: asInt(json['likeCount']),
      commentCount: asInt(json['commentCount']),
      favoriteCount: asInt(json['favoriteCount']),
      playCount: asInt(json['playCount']),
      completeCount: asInt(json['completeCount']),
      totalHeatValue: asDouble(json['totalHeatValue'] ?? json['heatValue']),
      likedByMe: asBool(json['likedByMe']),
      favoritedByMe: asBool(json['favoritedByMe']),
      creatorId: asString(json['creatorId']),
      creatorName: asString(json['creatorName']),
      creatorAvatar: asString(json['creatorAvatar']),
      tags: tags,
      actors: actors,
      score: asDouble(json['score']),
      reason: asString(json['reason']),
      publishedAt: asString(json['publishedAt'] ?? json['createTime']),
    );
  }

  /// Returns a copy with episode/work engagement fields replaced.
  ///
  /// Search pages use this after returning from playback so one changed work
  /// can be reconciled by id without re-running the complete search request.
  FeedItem copyWithEngagement({
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
  }) {
    return FeedItem(
      contentType: contentType,
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo,
      durationSec: durationSec,
      title: title,
      description: description,
      dramaDescription: dramaDescription,
      episodeDescription: episodeDescription,
      coverUrl: coverUrl,
      firstFrameUrl: firstFrameUrl,
      mediaAccessUrl: mediaAccessUrl,
      playbackType: playbackType,
      avgRating: avgRating,
      totalEpisodes: totalEpisodes,
      badge: badge,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      playCount: playCount,
      completeCount: completeCount,
      totalHeatValue: totalHeatValue,
      likedByMe: likedByMe ?? this.likedByMe,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      tags: tags,
      actors: actors,
      score: score,
      reason: reason,
      publishedAt: publishedAt,
    );
  }

  /// Unique actors by [FeedActor.actorId]. Entries without an id are kept.
  List<FeedActor> get uniqueActors {
    final seen = <String>{};
    final out = <FeedActor>[];
    for (final a in actors) {
      final id = a.actorId?.trim();
      if (id != null && id.isNotEmpty && !seen.add(id)) continue;
      out.add(a);
    }
    return out;
  }

  /// Sum of unique actors' Lv.1 IP 片酬 (`computingPower`).
  /// Missing values count as 0. Null only when there are no actors.
  double? get totalComputingPower {
    if (uniqueActors.isEmpty) return null;
    var rate = 0.0;
    for (final a in uniqueActors) {
      final v = a.computingPower;
      if (v != null && v.isFinite) rate += v;
    }
    return rate;
  }

  /// Maps a folded drama search hit onto [DramaListItem] for existing cards.
  ///
  /// Omits [episodeId] / [episodeNo] so theater-style cards keep series stats
  /// (完播 / 热度 / 评分) instead of episode like-count.
  DramaListItem toDramaListItem() {
    return DramaListItem(
      id: dramaId ?? episodeId ?? '',
      dramaTitle: title,
      dramaDescription: resolvedDramaDescription,
      dramaCoverUrl: posterUrl,
      tags: tags.isEmpty ? null : tags,
      creatorName: creatorName,
      badge: badge,
      // Prefer mini-drama kind over feed discriminator (DRAMA_EPISODE) so
      // series cards are not treated as a single episode.
      type: _dramaListContentType,
      durationSec: durationSec,
      avgRating: avgRating,
      totalEpisodes: totalEpisodes,
      totalPlayCount: playCount,
      totalCompletedViewCount: completeCount,
      totalHeatValue: totalHeatValue,
      actorCollections: uniqueActors
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

  /// [contentType] after flatten may be the card discriminator `DRAMA_EPISODE`.
  /// Theater cards need `SHORT_DRAMA` / `SHORT_VIDEO` style kinds.
  String? get _dramaListContentType {
    final raw = contentType?.trim();
    if (raw == null || raw.isEmpty) return raw;
    final normalized = raw.toUpperCase().replaceAll('-', '_');
    if (normalized == 'DRAMA_EPISODE' || normalized == 'SHORT_DRAMA_EPISODE') {
      return WorkContentType.shortDrama.apiValue;
    }
    return raw;
  }

  @override
  List<Object?> get props => [
    contentType,
    dramaId,
    episodeId,
    episodeNo,
    durationSec,
    title,
    description,
    dramaDescription,
    episodeDescription,
    coverUrl,
    firstFrameUrl,
    mediaAccessUrl,
    playbackType,
    avgRating,
    totalEpisodes,
    badge,
    likeCount,
    commentCount,
    favoriteCount,
    playCount,
    completeCount,
    totalHeatValue,
    likedByMe,
    favoritedByMe,
    creatorId,
    creatorName,
    creatorAvatar,
    tags,
    actors,
    score,
    reason,
    publishedAt,
  ];
}

class RecommendSearchResponse extends Equatable {
  final String keyword;
  final RecommendSearchType type;
  final List<FeedItem> items;

  /// Next-page cursor from `GET /api/recommend/search`. Empty when exhausted.
  final String? cursor;
  final bool hasMore;

  const RecommendSearchResponse({
    this.keyword = '',
    this.type = RecommendSearchType.all,
    this.items = const [],
    this.cursor,
    this.hasMore = false,
  });

  factory RecommendSearchResponse.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final items = <FeedItem>[];
    if (itemsRaw is List) {
      for (final i in itemsRaw) {
        if (i is Map<String, dynamic>) {
          items.add(FeedItem.fromJson(i));
        } else if (i is Map) {
          items.add(FeedItem.fromJson(Map<String, dynamic>.from(i)));
        }
      }
    }
    final cursor = asString(json['cursor']);
    final hasMore =
        asBool(json['hasMore']) ??
        (cursor != null && cursor.isNotEmpty && cursor != '-1');
    return RecommendSearchResponse(
      keyword: asString(json['keyword']) ?? '',
      type: RecommendSearchType.fromApi(asString(json['type'])),
      items: items,
      cursor: cursor,
      hasMore: hasMore,
    );
  }

  @override
  List<Object?> get props => [keyword, type, items, cursor, hasMore];
}
