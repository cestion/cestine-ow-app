import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

import '../core/video_url_helpers.dart';
import 'drama_model.dart';
import 'json_converters.dart';
import 'work_content_type.dart';

part 'user_profile_content_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserProfileContentDrama extends Equatable {
  @JsonKey(name: 'dramaId', fromJson: asStringRequired)
  final String id;
  @JsonKey(fromJson: asString)
  final String? title;
  @JsonKey(fromJson: asString)
  final String? description;
  @JsonKey(fromJson: asString)
  final String? coverUrl;
  @JsonKey(fromJson: asString)
  final String? contentType;
  @JsonKey(fromJson: _stringListFromJson)
  final List<String>? tags;
  @JsonKey(fromJson: asInt)
  final int? totalEpisodes;
  @JsonKey(fromJson: asString)
  final String? badge;
  final List<DramaActorCollection>? actorCollections;
  @JsonKey(fromJson: asInt)
  final int? totalPlayCount;
  @JsonKey(fromJson: asInt)
  final int? totalCompletedViewCount;
  @JsonKey(fromJson: asInt)
  final int? totalFavoriteCount;
  @JsonKey(fromJson: asDouble)
  final double? totalHeatValue;
  @JsonKey(fromJson: asDouble)
  final double? avgRating;

  const UserProfileContentDrama({
    required this.id,
    this.title,
    this.description,
    this.coverUrl,
    this.contentType,
    this.tags,
    this.totalEpisodes,
    this.badge,
    this.actorCollections,
    this.totalPlayCount,
    this.totalCompletedViewCount,
    this.totalFavoriteCount,
    this.totalHeatValue,
    this.avgRating,
  });

  factory UserProfileContentDrama.fromJson(Map<String, dynamic> json) =>
      _$UserProfileContentDramaFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileContentDramaToJson(this);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    coverUrl,
    contentType,
    tags,
    totalEpisodes,
    badge,
    actorCollections,
    totalPlayCount,
    totalCompletedViewCount,
    totalFavoriteCount,
    totalHeatValue,
    avgRating,
  ];
}

@JsonSerializable()
class UserProfileContentEpisode extends Equatable {
  @JsonKey(name: 'episodeId', fromJson: asStringRequired)
  final String id;
  @JsonKey(fromJson: asInt)
  final int? episodeNo;
  @JsonKey(fromJson: asString)
  final String? contentType;
  @JsonKey(fromJson: asInt)
  final int? durationSec;
  @JsonKey(fromJson: asString)
  final String? title;
  @JsonKey(fromJson: asString)
  final String? description;
  @JsonKey(fromJson: asString)
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  @JsonKey(fromJson: asString)
  final String? firstFrameUrl;
  @JsonKey(fromJson: asInt)
  final int? playCount;
  @JsonKey(fromJson: asInt)
  final int? completeCount;
  @JsonKey(fromJson: asInt)
  final int? likeCount;
  @JsonKey(fromJson: asInt)
  final int? commentCount;
  @JsonKey(fromJson: asInt)
  final int? favoriteCount;

  const UserProfileContentEpisode({
    required this.id,
    this.episodeNo,
    this.contentType,
    this.durationSec,
    this.title,
    this.description,
    this.coverUrl,
    this.firstFrameUrl,
    this.playCount,
    this.completeCount,
    this.likeCount,
    this.commentCount,
    this.favoriteCount,
  });

  factory UserProfileContentEpisode.fromJson(Map<String, dynamic> json) =>
      _$UserProfileContentEpisodeFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileContentEpisodeToJson(this);

  /// Poster for list / player chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  @override
  List<Object?> get props => [
    id,
    episodeNo,
    contentType,
    durationSec,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    playCount,
    completeCount,
    likeCount,
    commentCount,
    favoriteCount,
  ];
}

@JsonSerializable(explicitToJson: true)
class UserProfileContentItem extends Equatable {
  @JsonKey(fromJson: asString)
  final String? userId;
  @JsonKey(fromJson: asString)
  final String? creatorName;
  @JsonKey(fromJson: asString)
  final String? creatorAvatarUrl;
  @JsonKey(fromJson: asBool)
  final bool? likedByMe;
  @JsonKey(fromJson: asBool)
  final bool? favoritedByMe;
  @JsonKey(fromJson: asBool)
  final bool? followedByMe;
  @JsonKey(fromJson: asInt)
  final int? actionTime;
  @JsonKey(fromJson: asString)
  final String? type;
  final UserProfileContentDrama? drama;
  final UserProfileContentEpisode? episode;

  const UserProfileContentItem({
    this.userId,
    this.creatorName,
    this.creatorAvatarUrl,
    this.likedByMe,
    this.favoritedByMe,
    this.followedByMe,
    this.actionTime,
    this.type,
    this.drama,
    this.episode,
  });

  factory UserProfileContentItem.fromJson(Map<String, dynamic> json) =>
      _$UserProfileContentItemFromJson(json);

  Map<String, dynamic> toJson() => _$UserProfileContentItemToJson(this);

  String get contentId {
    final dramaId = drama?.id;
    if (dramaId != null && dramaId.isNotEmpty) return dramaId;
    return episode?.id ?? '';
  }

  bool matchesContentId(String id) => drama?.id == id || episode?.id == id;

  DramaListItem toDramaListItem() {
    final dramaData = drama;
    final episodeData = episode;
    final contentType =
        episodeData?.contentType ?? dramaData?.contentType ?? type;
    final isShortVideo = WorkContentType.fromApi(contentType).isShortVideo;

    return DramaListItem(
      id: dramaData?.id ?? episodeData?.id ?? '',
      episodeId: episodeData?.id,
      episodeNo: episodeData?.episodeNo,
      dramaTitle: isShortVideo
          ? (episodeData?.title ?? dramaData?.title)
          : (dramaData?.title ?? episodeData?.title),
      // Concrete work rows are episode-scoped even for short dramas. Only a
      // whole-series row (no episode payload) should show the drama synopsis.
      dramaDescription: episodeData != null
          ? (episodeData.description ?? dramaData?.description)
          : dramaData?.description,
      // Concrete episode rows (likes / favorites / works): prefer the
      // transcoded first frame so list chrome and player seed share one URL
      // (and the CachedNetworkImage cache). Whole-series rows keep drama cover.
      dramaCoverUrl: episodeData != null
          ? VideoUrlHelpers.preferPosterUrl(
              firstFrameUrl: episodeData.firstFrameUrl,
              coverUrl: episodeData.coverUrl ?? dramaData?.coverUrl,
            )
          : dramaData?.coverUrl,
      tags: dramaData?.tags,
      creatorName: creatorName,
      badge: dramaData?.badge,
      type: contentType,
      durationSec: episodeData?.durationSec,
      avgRating: dramaData?.avgRating,
      totalEpisodes: dramaData?.totalEpisodes,
      totalPlayCount: episodeData != null
          ? episodeData.playCount
          : dramaData?.totalPlayCount,
      totalCompletedViewCount: episodeData != null
          ? episodeData.completeCount
          : dramaData?.totalCompletedViewCount,
      totalHeatValue: dramaData?.totalHeatValue,
      likeCount: episodeData?.likeCount,
      // Episode metrics and drama aggregates belong to different scopes.
      // Never fill a missing episode value with the enclosing drama total.
      favoriteCount: episodeData != null
          ? episodeData.favoriteCount
          : dramaData?.totalFavoriteCount,
      actorCollections: dramaData?.actorCollections,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    creatorName,
    creatorAvatarUrl,
    likedByMe,
    favoritedByMe,
    followedByMe,
    actionTime,
    type,
    drama,
    episode,
  ];
}

List<String>? _stringListFromJson(dynamic value) {
  if (value is! List) return null;
  return value.map((item) => item.toString()).toList();
}
