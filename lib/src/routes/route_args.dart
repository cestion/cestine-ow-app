import 'package:equatable/equatable.dart';

import '../controller/search_state.dart';
import '../core/json_helpers.dart';
import '../model/json_converters.dart';
import '../model/models.dart';

typedef RouteArgsMap = Map<String, dynamic>?;

List<RecommendFeedActor>? _actorsFromRouteRaw(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final actors = <RecommendFeedActor>[];
  for (final item in raw) {
    if (item is RecommendFeedActor) {
      actors.add(item);
    } else if (item is Map<String, dynamic>) {
      actors.add(RecommendFeedActor.fromJson(item));
    } else if (item is Map) {
      actors.add(RecommendFeedActor.fromJson(Map<String, dynamic>.from(item)));
    }
  }
  return actors.isEmpty ? null : actors;
}

List<RoleCharacter>? _rolesFromRouteRaw(dynamic raw) {
  if (raw is! List || raw.isEmpty) return null;
  final roles = <RoleCharacter>[];
  for (final item in raw) {
    if (item is RoleCharacter) {
      roles.add(item);
    } else if (item is Map<String, dynamic>) {
      roles.add(RoleCharacter.fromMap(item));
    } else if (item is Map) {
      roles.add(RoleCharacter.fromMap(Map<String, dynamic>.from(item)));
    }
  }
  return roles.isEmpty ? null : roles;
}

/// Result returned when leaving actor detail. [signedCount] represents actor
/// NFTs confirmed during this visit; the mining indexer may expose their full
/// DTOs shortly afterwards.
class ActorDetailResult {
  final ActorCollection? actor;
  final int signedCount;

  const ActorDetailResult({this.actor, this.signedCount = 0});
}

class LoginArgs extends Equatable {
  final String? returnTo;

  const LoginArgs({this.returnTo});

  factory LoginArgs.fromMap(RouteArgsMap map) {
    return LoginArgs(returnTo: asStringOrNull(map?['returnTo']));
  }

  @override
  List<Object?> get props => [returnTo];
}

class DramaDetailArgs extends Equatable {
  final String dramaId;
  final String? coverUrl;

  /// Search drama card: open the player at episode 1 once data is ready.
  final bool autoPlayFirstEpisode;

  /// Search drama continuous-play queue (unique dramas). Empty elsewhere.
  final List<VideoFeedPlaylistEntry> searchPlaylist;
  final int searchPlaylistIndex;

  const DramaDetailArgs({
    required this.dramaId,
    this.coverUrl,
    this.autoPlayFirstEpisode = false,
    this.searchPlaylist = const [],
    this.searchPlaylistIndex = 0,
  });

  factory DramaDetailArgs.fromMap(RouteArgsMap map) {
    return DramaDetailArgs(
      dramaId: asStringRequired(map?['dramaId']),
      coverUrl: asStringOrNull(map?['coverUrl']),
      autoPlayFirstEpisode: map?['autoPlayFirstEpisode'] == true,
      searchPlaylist: VideoFeedPlaylistEntry.listFromRaw(
        map?['searchPlaylist'],
      ),
      searchPlaylistIndex: asIntOrNull(map?['searchPlaylistIndex']) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    dramaId,
    coverUrl,
    autoPlayFirstEpisode,
    searchPlaylist,
    searchPlaylistIndex,
  ];
}

class ActorDetailArgs extends Equatable {
  final String actorId;
  final ActorCollection? preview;
  final int initialTabIndex;

  const ActorDetailArgs({
    required this.actorId,
    this.preview,
    this.initialTabIndex = 0,
  });

  factory ActorDetailArgs.fromMap(RouteArgsMap map) {
    ActorCollection? preview;
    final previewRaw = map?['preview'];
    if (previewRaw is Map) {
      preview = ActorCollection.fromJson(deepStringMap(previewRaw));
    }
    // Legacy 三 Tab：0 签约 / 1 发行信息 / 2 参演 → 现双 Tab：0 参演 / 1 信息
    final rawTab = asIntOrNull(map?['initialTabIndex']) ?? 0;
    final initialTabIndex = switch (rawTab) {
      1 => 1,
      2 => 0,
      _ => 0,
    };
    return ActorDetailArgs(
      actorId: asStringRequired(map?['actorId']),
      preview: preview,
      initialTabIndex: initialTabIndex,
    );
  }

  @override
  List<Object?> get props => [actorId, preview, initialTabIndex];
}

class PlayerArgs extends Equatable {
  final String dramaId;
  final int episodeNo;
  final String title;

  const PlayerArgs({
    required this.dramaId,
    required this.episodeNo,
    this.title = '播放',
  });

  factory PlayerArgs.fromMap(RouteArgsMap map) {
    return PlayerArgs(
      dramaId: asStringRequired(map?['dramaId']),
      episodeNo: asIntOrNull(map?['episodeNo']) ?? 1,
      title: asStringOrNull(map?['title']) ?? '播放',
    );
  }

  @override
  List<Object?> get props => [dramaId, episodeNo, title];
}

class SearchArgs extends Equatable {
  final SearchType searchType;
  final String? hintText;

  const SearchArgs({this.searchType = SearchType.dramas, this.hintText});

  factory SearchArgs.fromMap(RouteArgsMap map) {
    final raw = asStringOrNull(
      map?['type'] ?? map?['tab'],
    )?.trim().toLowerCase();
    final type = switch (raw) {
      'works' || 'work' => SearchType.works,
      'actors' || 'actor' => SearchType.actors,
      'users' || 'user' => SearchType.users,
      'dramas' || 'drama' => SearchType.dramas,
      _ => SearchType.dramas,
    };
    return SearchArgs(
      searchType: type,
      hintText: asStringOrNull(map?['hintText']),
    );
  }

  @override
  List<Object?> get props => [searchType, hintText];
}

class EditArgs extends Equatable {
  final String type;
  final String id;

  const EditArgs({required this.type, required this.id});

  factory EditArgs.fromMap(RouteArgsMap map) {
    return EditArgs(
      type: asStringOrNull(map?['type']) ?? 'drama',
      id: asStringRequired(map?['id']),
    );
  }

  @override
  List<Object?> get props => [type, id];
}

class CreateDramaArgs extends Equatable {
  /// 非空时进入编辑模式，回显该 dramaId 的数据。
  final String? dramaId;

  const CreateDramaArgs({this.dramaId});

  factory CreateDramaArgs.fromMap(RouteArgsMap map) {
    final raw = asStringOrNull(map?['dramaId']);
    return CreateDramaArgs(dramaId: (raw == null || raw.isEmpty) ? null : raw);
  }

  @override
  List<Object?> get props => [dramaId];
}

class PublishVideoArgs extends Equatable {
  /// 非空时进入编辑模式，回显该短视频的数据。
  final int? episodeId;

  const PublishVideoArgs({this.episodeId});

  factory PublishVideoArgs.fromMap(RouteArgsMap map) {
    final raw = asInt(map?['episodeId']);
    return PublishVideoArgs(episodeId: raw != null && raw > 0 ? raw : null);
  }

  @override
  List<Object?> get props => [episodeId];
}

class CreatorManagementArgs extends Equatable {
  /// 0 为短剧，1 为视频。
  final int initialTabIndex;

  const CreatorManagementArgs({this.initialTabIndex = 0});

  factory CreatorManagementArgs.fromMap(RouteArgsMap map) {
    return CreatorManagementArgs(
      initialTabIndex: (asIntOrNull(map?['initialTabIndex']) ?? 0).clamp(0, 1),
    );
  }

  Map<String, dynamic> toMap() => {'initialTabIndex': initialTabIndex};

  @override
  List<Object?> get props => [initialTabIndex];
}

class PublicProfileArgs extends Equatable {
  final String? userId;

  const PublicProfileArgs({this.userId});

  factory PublicProfileArgs.fromMap(RouteArgsMap map) {
    final raw = asStringOrNull(map?['userId']);
    return PublicProfileArgs(userId: raw?.isEmpty == true ? null : raw);
  }

  @override
  List<Object?> get props => [userId];
}

class NotificationArgs extends Equatable {
  /// Backend notification tab: 1-system, 2-interaction.
  final int initialTab;

  const NotificationArgs({this.initialTab = 1})
    : assert(initialTab == 1 || initialTab == 2);

  factory NotificationArgs.fromMap(RouteArgsMap map) {
    final tab = asIntOrNull(map?['tab']);
    return NotificationArgs(initialTab: tab == 2 ? 2 : 1);
  }

  /// Resolves the destination tab for a notification preview.
  ///
  /// [NotificationItem.tab] is authoritative. Older payloads may omit it, so
  /// interaction event names are also recognized as a compatibility fallback.
  factory NotificationArgs.forNotification(NotificationItem notification) {
    if (notification.tab == 1 || notification.tab == 2) {
      return NotificationArgs(initialTab: notification.tab!);
    }

    return NotificationArgs(
      initialTab: notification.eventType.isInteraction ? 2 : 1,
    );
  }

  Map<String, dynamic> toMap() => {'tab': initialTab};

  @override
  List<Object?> get props => [initialTab];
}

class FollowRelationsArgs extends Equatable {
  final String userId;
  final FollowListType initialTab;

  const FollowRelationsArgs({
    required this.userId,
    this.initialTab = FollowListType.followers,
  });

  factory FollowRelationsArgs.fromMap(RouteArgsMap map) {
    final tabRaw = (asStringOrNull(map?['tab']) ?? '').toLowerCase();
    final initialTab = switch (tabRaw) {
      'following' => FollowListType.following,
      'mutuals' || 'mutual' => FollowListType.mutuals,
      _ => FollowListType.followers,
    };
    return FollowRelationsArgs(
      userId: asStringRequired(map?['userId']),
      initialTab: initialTab,
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'tab': switch (initialTab) {
      FollowListType.following => 'following',
      FollowListType.followers => 'followers',
      FollowListType.mutuals => 'mutuals',
    },
  };

  @override
  List<Object?> get props => [userId, initialTab];
}

class WebViewArgs extends Equatable {
  final String title;
  final String url;

  const WebViewArgs({required this.title, required this.url});

  factory WebViewArgs.fromMap(RouteArgsMap map) {
    return WebViewArgs(
      title: asStringOrNull(map?['title']) ?? '',
      url: asStringRequired(map?['url']),
    );
  }

  Map<String, dynamic> toMap() => {'title': title, 'url': url};

  @override
  List<Object?> get props => [title, url];
}

/// One target in a continuous-play queue. A target is either a short drama
/// (which may span multiple episodes) or one standalone short video.
class VideoFeedPlaylistEntry extends Equatable {
  final String dramaId;
  final String? episodeId;
  final WorkContentType contentType;
  final int episodeNo;
  final String title;

  /// Null means the source row did not provide an authoritative episode
  /// count. Whole-drama playlist entries resolve it before expansion.
  final int? totalEpisodes;
  final String? coverUrl;
  final String? description;
  final String? creatorName;
  final String? creatorUserId;
  final String? creatorAvatarUrl;

  /// Optional engagement seed from list rows (profile favorites / search).
  final bool? likedByMe;
  final int? likeCount;
  final int? commentCount;
  final bool? favoritedByMe;
  final int? favoriteCount;
  final bool? followedByMe;

  /// Drama-level targets expand to episode 1…N in the mixed vertical feed.
  /// Concrete episode targets keep this false and occupy one feed page.
  final bool expandEpisodes;

  /// Role IP briefs for the player rail (list rows / recommend cards).
  final List<RecommendFeedActor>? actors;

  /// Full drama roles when the caller already has detail-page data.
  final List<RoleCharacter>? roles;

  const VideoFeedPlaylistEntry({
    required this.dramaId,
    this.episodeId,
    this.contentType = WorkContentType.shortDrama,
    required this.episodeNo,
    this.title = '',
    this.totalEpisodes,
    this.coverUrl,
    this.description,
    this.expandEpisodes = false,
    this.creatorName,
    this.creatorUserId,
    this.creatorAvatarUrl,
    this.likedByMe,
    this.likeCount,
    this.commentCount,
    this.favoritedByMe,
    this.favoriteCount,
    this.followedByMe,
    this.actors,
    this.roles,
  });

  const VideoFeedPlaylistEntry.drama({
    required String dramaId,
    String? episodeId,
    int episodeNo = 1,
    int? totalEpisodes,
    String title = '',
    String? coverUrl,
    String? description,
    bool expandEpisodes = false,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<RecommendFeedActor>? actors,
    List<RoleCharacter>? roles,
  }) : this(
         dramaId: dramaId,
         episodeId: episodeId,
         episodeNo: episodeNo,
         totalEpisodes: totalEpisodes,
         title: title,
         coverUrl: coverUrl,
         description: description,
         expandEpisodes: expandEpisodes,
         creatorName: creatorName,
         creatorUserId: creatorUserId,
         creatorAvatarUrl: creatorAvatarUrl,
         likedByMe: likedByMe,
         likeCount: likeCount,
         commentCount: commentCount,
         favoritedByMe: favoritedByMe,
         favoriteCount: favoriteCount,
         followedByMe: followedByMe,
         actors: actors,
         roles: roles,
       );

  const VideoFeedPlaylistEntry.shortVideo({
    required String episodeId,
    String title = '',
    String? coverUrl,
    String? description,
    String? creatorName,
    String? creatorUserId,
    String? creatorAvatarUrl,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<RecommendFeedActor>? actors,
    List<RoleCharacter>? roles,
  }) : this(
         dramaId: '',
         episodeId: episodeId,
         contentType: WorkContentType.shortVideo,
         episodeNo: 1,
         totalEpisodes: 1,
         title: title,
         coverUrl: coverUrl,
         description: description,
         creatorName: creatorName,
         creatorUserId: creatorUserId,
         creatorAvatarUrl: creatorAvatarUrl,
         likedByMe: likedByMe,
         likeCount: likeCount,
         commentCount: commentCount,
         favoritedByMe: favoritedByMe,
         favoriteCount: favoriteCount,
         followedByMe: followedByMe,
         actors: actors,
         roles: roles,
       );

  bool get isShortVideo => contentType.isShortVideo;

  String get workId => isShortVideo ? episodeId?.trim() ?? '' : dramaId.trim();

  /// Stable identity for playlist dedupe / continuation.
  ///
  /// - Short video: `SHORT_VIDEO:{episodeId}`
  /// - Whole-drama expand row: `SHORT_DRAMA:{dramaId}`
  /// - Concrete liked/history episode: include episode id (or `#episodeNo`)
  ///   so multiple episodes of the same drama are not collapsed.
  String get playbackKey {
    if (isShortVideo) {
      final id = episodeId?.trim() ?? '';
      return id.isEmpty ? '' : '${contentType.apiValue}:$id';
    }
    final drama = dramaId.trim();
    if (drama.isEmpty) return '';
    if (expandEpisodes) return '${contentType.apiValue}:$drama';
    final epId = episodeId?.trim() ?? '';
    if (epId.isNotEmpty) return '${contentType.apiValue}:$drama:$epId';
    return '${contentType.apiValue}:$drama#$episodeNo';
  }

  bool get isValid => workId.isNotEmpty;

  factory VideoFeedPlaylistEntry.fromMap(Map<String, dynamic> map) {
    return VideoFeedPlaylistEntry(
      dramaId: asStringRequired(map['dramaId']),
      episodeId: asStringOrNull(map['episodeId']),
      contentType: WorkContentType.fromApi(asStringOrNull(map['contentType'])),
      episodeNo: asIntOrNull(map['episodeNo']) ?? 1,
      title: asStringOrNull(map['title']) ?? '',
      totalEpisodes: asIntOrNull(map['totalEpisodes']),
      coverUrl: asStringOrNull(map['coverUrl']),
      description: asStringOrNull(map['description']),
      expandEpisodes: map['expandEpisodes'] == true,
      creatorName: asStringOrNull(map['creatorName']),
      creatorUserId: asStringOrNull(map['creatorUserId']),
      creatorAvatarUrl: asStringOrNull(map['creatorAvatarUrl']),
      likedByMe: asBool(map['likedByMe']),
      likeCount: asIntOrNull(map['likeCount']),
      commentCount: asIntOrNull(map['commentCount']),
      favoritedByMe: asBool(map['favoritedByMe']),
      favoriteCount: asIntOrNull(map['favoriteCount']),
      followedByMe: asBool(map['followedByMe']),
      actors: _actorsFromRouteRaw(map['actors']),
      roles: _rolesFromRouteRaw(map['roles']),
    );
  }

  static List<VideoFeedPlaylistEntry> listFromRaw(dynamic raw) {
    final playlist = <VideoFeedPlaylistEntry>[];
    if (raw is! List) return playlist;
    for (final item in raw) {
      if (item is VideoFeedPlaylistEntry) {
        playlist.add(item);
      } else if (item is Map<String, dynamic>) {
        playlist.add(VideoFeedPlaylistEntry.fromMap(item));
      } else if (item is Map) {
        playlist.add(
          VideoFeedPlaylistEntry.fromMap(Map<String, dynamic>.from(item)),
        );
      }
    }
    return playlist;
  }

  Map<String, dynamic> toMap() => {
    'dramaId': dramaId,
    if (episodeId != null) 'episodeId': episodeId,
    'contentType': contentType.apiValue,
    'episodeNo': episodeNo,
    'title': title,
    if (totalEpisodes != null) 'totalEpisodes': totalEpisodes,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (description != null) 'description': description,
    'expandEpisodes': expandEpisodes,
    if (creatorName != null) 'creatorName': creatorName,
    if (creatorUserId != null) 'creatorUserId': creatorUserId,
    if (creatorAvatarUrl != null) 'creatorAvatarUrl': creatorAvatarUrl,
    if (likedByMe != null) 'likedByMe': likedByMe,
    if (likeCount != null) 'likeCount': likeCount,
    if (commentCount != null) 'commentCount': commentCount,
    if (favoritedByMe != null) 'favoritedByMe': favoritedByMe,
    if (favoriteCount != null) 'favoriteCount': favoriteCount,
    if (followedByMe != null) 'followedByMe': followedByMe,
    if (actors != null && actors!.isNotEmpty)
      'actors': [for (final actor in actors!) actor.toMap()],
    if (roles != null && roles!.isNotEmpty)
      'roles': [for (final role in roles!) role.toMap()],
  };

  VideoFeedArgs toFeedArgs({
    required List<VideoFeedPlaylistEntry> playlist,
    required int playlistIndex,
    bool searchDramaPlaylist = false,
    String? playlistSourceId,
  }) {
    final listedTotal = totalEpisodes ?? 0;
    final safeEpisodeNo = episodeNo < 1 ? 1 : episodeNo;
    final resolvedTotal = isShortVideo
        ? 1
        : (listedTotal < safeEpisodeNo ? safeEpisodeNo : listedTotal);
    return VideoFeedArgs(
      dramaId: isShortVideo ? '' : dramaId.trim(),
      episodeId: isShortVideo ? episodeId?.trim() : null,
      contentType: contentType,
      episodeNo: isShortVideo ? 1 : safeEpisodeNo,
      title: title,
      totalEpisodes: resolvedTotal,
      coverUrl: coverUrl,
      episodeCoverUrl: expandEpisodes ? null : coverUrl,
      description: description,
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      likedByMe: likedByMe,
      likeCount: likeCount,
      commentCount: commentCount,
      favoritedByMe: favoritedByMe,
      favoriteCount: favoriteCount,
      followedByMe: followedByMe,
      actors: actors,
      roles: roles,
      searchPlaylist: playlist,
      searchPlaylistIndex: playlistIndex,
      searchDramaPlaylist: searchDramaPlaylist,
      playlistSourceId: playlistSourceId,
    );
  }

  VideoFeedPlaylistEntry copyWith({
    int? totalEpisodes,
    bool? likedByMe,
    int? likeCount,
    int? commentCount,
    bool? favoritedByMe,
    int? favoriteCount,
    bool? followedByMe,
    List<RecommendFeedActor>? actors,
    List<RoleCharacter>? roles,
  }) {
    return VideoFeedPlaylistEntry(
      dramaId: dramaId,
      episodeId: episodeId,
      contentType: contentType,
      episodeNo: episodeNo,
      title: title,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      coverUrl: coverUrl,
      description: description,
      expandEpisodes: expandEpisodes,
      creatorName: creatorName,
      creatorUserId: creatorUserId,
      creatorAvatarUrl: creatorAvatarUrl,
      likedByMe: likedByMe ?? this.likedByMe,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      favoritedByMe: favoritedByMe ?? this.favoritedByMe,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      followedByMe: followedByMe ?? this.followedByMe,
      actors: actors ?? this.actors,
      roles: roles ?? this.roles,
    );
  }

  @override
  List<Object?> get props => [
    dramaId,
    episodeId,
    contentType,
    episodeNo,
    title,
    totalEpisodes,
    coverUrl,
    description,
    expandEpisodes,
    creatorName,
    creatorUserId,
    creatorAvatarUrl,
    likedByMe,
    likeCount,
    commentCount,
    favoritedByMe,
    favoriteCount,
    followedByMe,
    actors,
    roles,
  ];
}

class VideoFeedArgs extends Equatable {
  final String dramaId;
  final String? episodeId;
  final WorkContentType contentType;
  final int episodeNo;
  final String title;
  final int totalEpisodes;
  final String? coverUrl;

  /// Poster for [episodeNo] when known at navigation time (episode thumbnail).
  final String? episodeCoverUrl;
  final bool warmStart;
  final String? description;
  final String? creatorName;
  final String? creatorUserId;
  final String? creatorAvatarUrl;
  final bool? likedByMe;
  final int? likeCount;
  final int? commentCount;
  final bool? favoritedByMe;
  final int? favoriteCount;
  final bool? followedByMe;
  final List<RecommendFeedActor>? actors;
  final List<RoleCharacter>? roles;
  final bool fromDramaDetail;
  final bool openComments;
  final String? commentEpisodeId;
  final StoryComment? highlightedComment;

  /// When non-empty, finishing the current item advances to the next entry
  /// (loops). Used by search works continuous play (PRD).
  final List<VideoFeedPlaylistEntry> searchPlaylist;
  final int searchPlaylistIndex;

  /// Search drama cards: keep intra-drama episode auto-advance; when the
  /// last episode completes, loop to the next drama in [searchPlaylist].
  /// Also skips persisting the continue-watching cursor so search-from-ep-1
  /// does not overwrite theater resume.
  final bool searchDramaPlaylist;

  /// Opaque id for [PlaylistContinuationStore]; enables parent-list loadMore
  /// while the external playlist is open. Empty when the queue is finite.
  final String? playlistSourceId;

  const VideoFeedArgs({
    required this.dramaId,
    this.episodeId,
    this.contentType = WorkContentType.shortDrama,
    required this.episodeNo,
    this.title = '播放',
    this.totalEpisodes = 1,
    this.coverUrl,
    this.episodeCoverUrl,
    this.warmStart = false,
    this.description,
    this.creatorName,
    this.creatorUserId,
    this.creatorAvatarUrl,
    this.likedByMe,
    this.likeCount,
    this.commentCount,
    this.favoritedByMe,
    this.favoriteCount,
    this.followedByMe,
    this.actors,
    this.roles,
    this.fromDramaDetail = false,
    this.openComments = false,
    this.commentEpisodeId,
    this.highlightedComment,
    this.searchPlaylist = const [],
    this.searchPlaylistIndex = 0,
    this.searchDramaPlaylist = false,
    this.playlistSourceId,
  });

  bool get isShortVideo => contentType.isShortVideo;

  /// Work identity used by navigation, local progress and engagement stores.
  /// Prefixing the type prevents an episode id from colliding with a drama id.
  String get playbackKey {
    final id = isShortVideo ? episodeId?.trim() ?? '' : dramaId.trim();
    return id.isEmpty ? '' : '${contentType.apiValue}:$id';
  }

  /// Concrete server-side work id. For short videos this is the episode id.
  String get workId => isShortVideo ? episodeId?.trim() ?? '' : dramaId.trim();

  factory VideoFeedArgs.fromMap(RouteArgsMap map) {
    final highlightedCommentRaw = map?['highlightedComment'];
    final highlightedComment = switch (highlightedCommentRaw) {
      final StoryComment value => value,
      final Map<dynamic, dynamic> value => StoryComment.fromJson(
        deepStringMap(value),
      ),
      _ => null,
    };
    final contentType = WorkContentType.fromApi(
      asStringOrNull(map?['contentType']),
    );
    return VideoFeedArgs(
      dramaId: asStringRequired(map?['dramaId']),
      episodeId: asStringOrNull(map?['episodeId']),
      contentType: contentType,
      episodeNo: asIntOrNull(map?['episodeNo']) ?? 1,
      title: asStringOrNull(map?['title']) ?? '播放',
      totalEpisodes: asIntOrNull(map?['totalEpisodes']) ?? 1,
      coverUrl: asStringOrNull(map?['coverUrl']),
      episodeCoverUrl: asStringOrNull(map?['episodeCoverUrl']),
      warmStart: map?['warmStart'] == true,
      description: asStringOrNull(map?['description']),
      creatorName: asStringOrNull(map?['creatorName']),
      creatorUserId: asStringOrNull(map?['creatorUserId']),
      creatorAvatarUrl: asStringOrNull(map?['creatorAvatarUrl']),
      likedByMe: asBool(map?['likedByMe']),
      likeCount: asIntOrNull(map?['likeCount']),
      commentCount: asIntOrNull(map?['commentCount']),
      favoritedByMe: asBool(map?['favoritedByMe']),
      favoriteCount: asIntOrNull(map?['favoriteCount']),
      followedByMe: asBool(map?['followedByMe']),
      actors: _actorsFromRouteRaw(map?['actors']),
      roles: _rolesFromRouteRaw(map?['roles']),
      fromDramaDetail: map?['fromDramaDetail'] == true,
      openComments: map?['openComments'] == true,
      commentEpisodeId: asStringOrNull(map?['commentEpisodeId']),
      highlightedComment: highlightedComment,
      searchPlaylist: VideoFeedPlaylistEntry.listFromRaw(
        map?['searchPlaylist'],
      ),
      searchPlaylistIndex: asIntOrNull(map?['searchPlaylistIndex']) ?? 0,
      searchDramaPlaylist: map?['searchDramaPlaylist'] == true,
      playlistSourceId: asStringOrNull(map?['playlistSourceId']),
    );
  }

  Map<String, dynamic> toMap() => {
    'dramaId': dramaId,
    if (episodeId != null) 'episodeId': episodeId,
    'contentType': contentType.apiValue,
    'episodeNo': episodeNo,
    'title': title,
    'totalEpisodes': totalEpisodes,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (episodeCoverUrl != null) 'episodeCoverUrl': episodeCoverUrl,
    'warmStart': warmStart,
    if (description != null) 'description': description,
    if (creatorName != null) 'creatorName': creatorName,
    if (creatorUserId != null) 'creatorUserId': creatorUserId,
    if (creatorAvatarUrl != null) 'creatorAvatarUrl': creatorAvatarUrl,
    if (likedByMe != null) 'likedByMe': likedByMe,
    if (likeCount != null) 'likeCount': likeCount,
    if (commentCount != null) 'commentCount': commentCount,
    if (favoritedByMe != null) 'favoritedByMe': favoritedByMe,
    if (favoriteCount != null) 'favoriteCount': favoriteCount,
    if (followedByMe != null) 'followedByMe': followedByMe,
    if (actors != null && actors!.isNotEmpty)
      'actors': [for (final actor in actors!) actor.toMap()],
    if (roles != null && roles!.isNotEmpty)
      'roles': [for (final role in roles!) role.toMap()],
    'fromDramaDetail': fromDramaDetail,
    'openComments': openComments,
    if (commentEpisodeId != null) 'commentEpisodeId': commentEpisodeId,
    if (highlightedComment != null)
      'highlightedComment': highlightedComment!.toJson(),
    if (searchPlaylist.isNotEmpty)
      'searchPlaylist': [for (final e in searchPlaylist) e.toMap()],
    'searchPlaylistIndex': searchPlaylistIndex,
    'searchDramaPlaylist': searchDramaPlaylist,
    if (playlistSourceId != null && playlistSourceId!.isNotEmpty)
      'playlistSourceId': playlistSourceId,
  };

  @override
  List<Object?> get props => [
    dramaId,
    episodeId,
    contentType,
    episodeNo,
    title,
    totalEpisodes,
    coverUrl,
    episodeCoverUrl,
    warmStart,
    description,
    creatorName,
    creatorUserId,
    creatorAvatarUrl,
    likedByMe,
    likeCount,
    commentCount,
    favoritedByMe,
    favoriteCount,
    followedByMe,
    actors,
    roles,
    fromDramaDetail,
    openComments,
    commentEpisodeId,
    highlightedComment,
    searchPlaylist,
    searchPlaylistIndex,
    searchDramaPlaylist,
    playlistSourceId,
  ];
}
