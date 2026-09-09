import 'package:equatable/equatable.dart';

import '../core/video_url_helpers.dart';
import 'actor_hourly_rate.dart';
import 'cloudfront_signed_cookies_model.dart';
import 'drama_model.dart';
import 'drama_play_response_model.dart';
import 'json_converters.dart';
import 'recommend_card_json.dart';
import 'work_content_type.dart';

/// Role IP brief on a recommend / search card.
class RecommendFeedActor extends Equatable {
  final String? actorId;
  final String? actorName;
  final String? avatarUrl;
  final String? badge;
  final double? trust;
  final double? computingPower;
  final num? storyPerHour;
  final double? unitPrice;

  const RecommendFeedActor({
    this.actorId,
    this.actorName,
    this.avatarUrl,
    this.badge,
    this.trust,
    this.computingPower,
    this.storyPerHour,
    this.unitPrice,
  });

  ActorHourlyRate get rate => ActorHourlyRate(
    storyPerHour: storyPerHour,
    unitPrice: unitPrice,
    computingPower: computingPower,
  );

  /// Display rate: [storyPerHour], else [unitPrice], else [computingPower].
  num? get hourlyRate => rate.value;

  /// 片酬 in STORY/h: [storyPerHour], else [computingPower].
  /// Never NFT [unitPrice] / signing list price (player rail label).
  num? get payRate => rate.payValue;

  /// Rail actors: feed briefs overlaid with drama-detail role rates when present.
  static List<RecommendFeedActor> forRail({
    List<RecommendFeedActor>? feedActors,
    List<RoleCharacter>? roles,
  }) {
    final feed = feedActors ?? const <RecommendFeedActor>[];
    final boundRoles = [
      for (final role in roles ?? const <RoleCharacter>[])
        if (role.isBound) role,
    ];
    final byId = {
      for (final role in boundRoles)
        if (role.boundActorCollectionId != null &&
            role.boundActorCollectionId!.isNotEmpty)
          role.boundActorCollectionId!: role,
    };

    if (feed.isNotEmpty) {
      final overlaid = [
        for (final actor in feed) actor._overlay(byId[actor.actorId]),
      ];
      final seen = <String>{
        for (final actor in overlaid)
          if (actor.actorId != null && actor.actorId!.isNotEmpty)
            actor.actorId!,
      };
      return [
        ...overlaid,
        for (final role in boundRoles)
          if (role.boundActorCollectionId != null &&
              role.boundActorCollectionId!.isNotEmpty &&
              !seen.contains(role.boundActorCollectionId))
            RecommendFeedActor._fromBoundRole(role),
      ];
    }
    return [
      for (final role in boundRoles) RecommendFeedActor._fromBoundRole(role),
    ];
  }

  factory RecommendFeedActor._fromBoundRole(RoleCharacter role) {
    return RecommendFeedActor(
      actorId: role.boundActorCollectionId,
      actorName: role.boundActorName ?? role.name,
      avatarUrl: role.boundActorAvatar,
      storyPerHour: role.boundActorStoryPerHour,
      unitPrice: role.boundActorUnitPrice,
      computingPower: role.boundActorComputingPower,
    );
  }

  RecommendFeedActor _overlay(RoleCharacter? role) {
    if (role == null) return this;
    final rates = rate.overlay(role.boundRate);
    return RecommendFeedActor(
      actorId: actorId,
      actorName: actorName ?? role.boundActorName,
      avatarUrl: avatarUrl ?? role.boundActorAvatar,
      badge: badge,
      trust: trust,
      storyPerHour: rates.storyPerHour,
      unitPrice: rates.unitPrice,
      computingPower: rates.computingPower,
    );
  }

  Map<String, dynamic> toMap() => {
    if (actorId != null) 'actorId': actorId,
    if (actorName != null) 'actorName': actorName,
    if (avatarUrl != null) 'avatarUrl': avatarUrl,
    if (badge != null) 'badge': badge,
    if (trust != null) 'trust': trust,
    if (computingPower != null) 'computingPower': computingPower,
    if (storyPerHour != null) 'storyPerHour': storyPerHour,
    if (unitPrice != null) 'unitPrice': unitPrice,
  };

  factory RecommendFeedActor.fromJson(Map<String, dynamic> json) {
    final boundRaw = json['boundActorCollection'] ?? json['boundActor'];
    final bound = boundRaw is Map ? Map<String, dynamic>.from(boundRaw) : null;
    final rates = ActorHourlyRate.fromJson(json);

    return RecommendFeedActor(
      actorId:
          asString(json['actorId']) ??
          asString(json['actorCollectionId']) ??
          asString(bound?['actorCollectionId']) ??
          asString(bound?['id']) ??
          asString(json['id']),
      actorName:
          asString(json['actorName']) ??
          asString(json['actorCollectionName']) ??
          asString(bound?['name']) ??
          asString(json['name']),
      avatarUrl:
          asString(json['avatarUrl']) ??
          asString(json['actorCollectionAvatar']) ??
          asString(bound?['avatar']) ??
          asString(bound?['avatarUrl']) ??
          asString(json['avatar']),
      badge: json['badge'] as String? ?? bound?['badge'] as String?,
      trust: asDouble(json['trust']) ?? asDouble(bound?['trust']),
      computingPower: rates.computingPower,
      storyPerHour: rates.storyPerHour,
      unitPrice: rates.unitPrice,
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
    unitPrice,
  ];
}

/// Single recommend / search card (`FeedItemResponse`).
class RecommendFeedItem extends Equatable {
  /// `drama_episode` | `short_video`
  final String? contentType;
  final String dramaId;
  final String? episodeId;
  final int? episodeNo;
  final String? title;
  final String? description;
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  final String? firstFrameUrl;
  final String? mediaAccessUrl;
  final String? playbackType;
  final CloudFrontSignedCookies? signedCookies;
  final double? avgRating;
  final int? totalEpisodes;
  final String? badge;
  final int? likeCount;
  final int? commentCount;
  final int? favoriteCount;
  final int? playCount;
  final int? completeCount;
  final bool? likedByMe;
  final bool? favoritedByMe;
  final bool? followedByMe;
  final String? creatorId;
  final String? creatorName;
  final String? creatorAvatar;
  final List<String>? tags;
  final List<RecommendFeedActor>? actors;
  final double? score;
  final String? reason;

  /// Drama roles when seeded from an external playlist (detail page / theater).
  final List<RoleCharacter>? roles;

  const RecommendFeedItem({
    required this.dramaId,
    this.contentType,
    this.episodeId,
    this.episodeNo,
    this.title,
    this.description,
    this.coverUrl,
    this.firstFrameUrl,
    this.mediaAccessUrl,
    this.playbackType,
    this.signedCookies,
    this.avgRating,
    this.totalEpisodes,
    this.badge,
    this.likeCount,
    this.commentCount,
    this.favoriteCount,
    this.playCount,
    this.completeCount,
    this.likedByMe,
    this.favoritedByMe,
    this.followedByMe,
    this.creatorId,
    this.creatorName,
    this.creatorAvatar,
    this.tags,
    this.actors,
    this.score,
    this.reason,
    this.roles,
  });

  /// Alias used by recommend UI that previously keyed on [DramaListItem.id].
  String get id => playbackId;

  /// Slot / bind-target identity: `dramaId:episodeId` when both exist and
  /// differ (short-drama episodes). Short videos (no series id, or series id
  /// equals episode id) key on [episodeId] alone.
  ///
  /// 注意：首帧缓存 key 不要用本 getter —— 一律改用
  /// `PlaybackFrameCacheService.frameCacheKey`。本 getter 的短剧无 episodeId
  /// 分支（`drama:episode:N`）与短剧页 key（`drama_ep$episodeNo`）不一致，
  /// 直接用它缓存会导致同一集跨入口缓存 miss。
  String get playbackId {
    final drama = dramaId.trim();
    final ep = episodeId?.trim() ?? '';
    if (drama.isNotEmpty && ep.isNotEmpty && drama != ep) {
      return '$drama:$ep';
    }
    if (ep.isNotEmpty) return ep;
    if (drama.isNotEmpty && workType.isShortDrama) {
      return '$drama:episode:$resolvedEpisodeNo';
    }
    return drama;
  }

  /// API / [PlaybackEngine] work id — series [dramaId] for short dramas,
  /// [episodeId] for standalone short videos.
  String get bindWorkId {
    if (workType.isShortVideo) {
      final ep = episodeId?.trim() ?? '';
      if (ep.isNotEmpty) return ep;
    }
    final drama = dramaId.trim();
    if (drama.isNotEmpty) return drama;
    return episodeId?.trim() ?? '';
  }

  /// Same composite rules as [playbackId], from a play payload.
  static String? playbackIdOfPlay(DramaPlayResponse? play) {
    if (play == null) return null;
    final drama = play.dramaId?.trim() ?? '';
    final ep = play.episodeId?.trim() ?? '';
    if (drama.isNotEmpty && ep.isNotEmpty && drama != ep) {
      return '$drama:$ep';
    }
    if (ep.isNotEmpty) return ep;
    return drama.isEmpty ? null : drama;
  }

  bool get hasPlayableIdentity => playbackId.isNotEmpty;

  /// Parsed [contentType] (`drama_episode` / `SHORT_DRAMA` / `short_video` / …).
  WorkContentType get workType => WorkContentType.fromApi(contentType);

  /// Poster for player / list chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  /// Favorite target id for UI keys: episode id when present (work favorite),
  /// otherwise series [dramaId].
  String get favoriteTargetId {
    final ep = episodeId;
    if (ep != null && ep.isNotEmpty) return ep;
    return dramaId;
  }

  /// 1-based episode used for play / prefetch when [episodeNo] is missing.
  int get resolvedEpisodeNo {
    final no = episodeNo;
    return (no != null && no >= 1) ? no : 1;
  }

  /// Card with interaction fields replaced by the settled values of a
  /// like / favorite / comment action.
  ///
  /// The feed list is the only engagement source the recommend flow refetches,
  /// so a mutation has to land here — otherwise re-activating the card
  /// re-seeds the pre-toggle state once the engagement store is disposed.
  RecommendFeedItem withEngagement({
    String? resolvedEpisodeId,
    int? resolvedEpisodeNo,
    bool? likedByMe,
    int? likeCount,
    bool? favoritedByMe,
    int? favoriteCount,
    int? commentCount,
    bool? followedByMe,
  }) {
    return RecommendFeedItem(
      dramaId: dramaId,
      contentType: contentType,
      episodeId: resolvedEpisodeId ?? episodeId,
      episodeNo: resolvedEpisodeNo ?? episodeNo,
      title: title,
      description: description,
      coverUrl: coverUrl,
      firstFrameUrl: firstFrameUrl,
      mediaAccessUrl: mediaAccessUrl,
      playbackType: playbackType,
      signedCookies: signedCookies,
      avgRating: avgRating,
      totalEpisodes: totalEpisodes,
      badge: badge,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      playCount: playCount,
      completeCount: completeCount,
      likedByMe: likedByMe ?? this.likedByMe,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      followedByMe: followedByMe ?? this.followedByMe,
      creatorId: creatorId,
      creatorName: creatorName,
      creatorAvatar: creatorAvatar,
      tags: tags,
      actors: actors,
      score: score,
      reason: reason,
      roles: roles,
    );
  }

  /// Update display metadata. Existing non-empty values are kept unless the
  /// caller supplies an authoritative replacement.
  RecommendFeedItem withCreator({
    String? title,
    String? description,
    String? creatorId,
    String? creatorName,
    String? creatorAvatar,
    bool overwriteExisting = false,
  }) {
    String? merge(String? current, String? next) {
      final trimmed = next?.trim();
      if (trimmed == null || trimmed.isEmpty) return current;
      if (overwriteExisting || current?.trim().isNotEmpty != true) {
        return trimmed;
      }
      return current;
    }

    return RecommendFeedItem(
      dramaId: dramaId,
      contentType: contentType,
      episodeId: episodeId,
      episodeNo: episodeNo,
      title: merge(this.title, title),
      description: merge(this.description, description),
      coverUrl: coverUrl,
      firstFrameUrl: firstFrameUrl,
      mediaAccessUrl: mediaAccessUrl,
      playbackType: playbackType,
      signedCookies: signedCookies,
      avgRating: avgRating,
      totalEpisodes: totalEpisodes,
      badge: badge,
      likeCount: likeCount,
      commentCount: commentCount,
      favoriteCount: favoriteCount,
      playCount: playCount,
      completeCount: completeCount,
      likedByMe: likedByMe,
      favoritedByMe: favoritedByMe,
      followedByMe: followedByMe,
      creatorId: merge(this.creatorId, creatorId),
      creatorName: merge(this.creatorName, creatorName),
      creatorAvatar: merge(this.creatorAvatar, creatorAvatar),
      tags: tags,
      actors: actors,
      score: score,
      reason: reason,
      roles: roles,
    );
  }

  /// Play payload from the feed card so chrome / disk-warm / playback
  /// do not wait on [DramaRepository.getEpisodeDetail].
  DramaPlayResponse? toPlayResponse() {
    final url = mediaAccessUrl?.trim();
    if (url == null || url.isEmpty || !VideoUrlHelpers.isHttpUrl(url)) {
      return null;
    }
    final isHls = VideoUrlHelpers.formatOf(url) == VideoUrlFormat.hls;
    final cookies = signedCookies;
    return DramaPlayResponse(
      dramaId: bindWorkId,
      episodeId: episodeId,
      episodeNo: resolvedEpisodeNo,
      description: description,
      mediaAccessUrl: url,
      hlsUrl: isHls ? url : null,
      playbackType: playbackType ?? (isHls ? 'hls' : null),
      signedCookies: cookies != null && cookies.isValid ? cookies : null,
      likeCount: likeCount,
      commentCount: commentCount,
      favoriteCount: favoriteCount,
      likedByMe: likedByMe,
      favoritedByMe: favoritedByMe,
      coverUrl: coverUrl,
      firstFrameUrl: firstFrameUrl,
    );
  }

  factory RecommendFeedItem.fromJson(Map<String, dynamic> json) {
    json = flattenRecommendCardJson(json);
    final actorsRaw = json['actors'] ?? json['roles'];
    final dramaId = (asString(json['dramaId']) ?? '').trim();
    return RecommendFeedItem(
      contentType: asString(json['contentType']),
      dramaId: dramaId,
      episodeId: asString(json['episodeId']),
      episodeNo: asInt(json['episodeNo']),
      title: asString(json['title']),
      description: asString(json['description']),
      coverUrl: asString(json['coverUrl']),
      firstFrameUrl: asString(json['firstFrameUrl']),
      mediaAccessUrl: asString(json['mediaAccessUrl']),
      playbackType: asString(json['playbackType']),
      signedCookies: _signedCookiesFromJson(json['signedCookies']),
      avgRating: asDouble(json['avgRating']),
      totalEpisodes: asInt(json['totalEpisodes']),
      badge: asString(json['badge']),
      likeCount: asInt(json['likeCount']),
      commentCount: asInt(json['commentCount']),
      favoriteCount: asInt(json['favoriteCount']),
      playCount: asInt(json['playCount']),
      completeCount: asInt(json['completeCount']),
      likedByMe: asBool(json['likedByMe']),
      favoritedByMe: asBool(json['favoritedByMe']),
      followedByMe: asBool(json['followedByMe']),
      creatorId: asString(json['creatorId']),
      creatorName: asString(json['creatorName']),
      creatorAvatar: asString(json['creatorAvatar']),
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList(),
      actors: actorsRaw is List
          ? actorsRaw
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      RecommendFeedActor.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : null,
      score: asDouble(json['score']),
      reason: asString(json['reason']),
    );
  }

  @override
  List<Object?> get props => [
    contentType,
    dramaId,
    episodeId,
    episodeNo,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    mediaAccessUrl,
    playbackType,
    signedCookies,
    avgRating,
    totalEpisodes,
    badge,
    likeCount,
    commentCount,
    favoriteCount,
    playCount,
    completeCount,
    likedByMe,
    favoritedByMe,
    followedByMe,
    creatorId,
    creatorName,
    creatorAvatar,
    tags,
    actors,
    score,
    reason,
    roles,
  ];

  static CloudFrontSignedCookies? _signedCookiesFromJson(dynamic json) {
    if (json == null) return null;
    if (json is CloudFrontSignedCookies) return json;
    if (json is Map<String, dynamic>) {
      return CloudFrontSignedCookies.fromJson(json);
    }
    if (json is Map) {
      return CloudFrontSignedCookies.fromJson(
        json.map((key, value) => MapEntry(key.toString(), value)),
      );
    }
    return null;
  }
}

/// `/api/recommend/feed` page payload.
class RecommendFeedPage extends Equatable {
  final String? sessionId;
  final String? cursor;
  final bool hasMore;
  final String? source;
  final List<RecommendFeedItem> items;

  const RecommendFeedPage({
    this.sessionId,
    this.cursor,
    this.hasMore = false,
    this.source,
    this.items = const [],
  });

  factory RecommendFeedPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final cursor = json['cursor'] as String?;
    return RecommendFeedPage(
      sessionId: json['sessionId'] as String?,
      cursor: cursor,
      hasMore:
          asBool(json['hasMore']) ??
          (cursor != null && cursor.trim().isNotEmpty),
      source: json['source'] as String?,
      items: rawItems is List
          ? rawItems
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      RecommendFeedItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .where((item) => item.hasPlayableIdentity)
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [sessionId, cursor, hasMore, source, items];
}

/// `/api/recommend/search` payload (cards share [RecommendFeedItem]).
class RecommendSearchResult extends Equatable {
  final String? keyword;
  final String? type;
  final List<RecommendFeedItem> items;

  const RecommendSearchResult({this.keyword, this.type, this.items = const []});

  factory RecommendSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return RecommendSearchResult(
      keyword: json['keyword'] as String?,
      type: json['type'] as String?,
      items: rawItems is List
          ? rawItems
                .whereType<Map<dynamic, dynamic>>()
                .map(
                  (e) =>
                      RecommendFeedItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .where((item) => item.hasPlayableIdentity)
                .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [keyword, type, items];
}
