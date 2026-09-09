import 'package:equatable/equatable.dart';

import '../core/json_helpers.dart';
import '../core/video_url_helpers.dart';
import 'json_converters.dart';

/// Public drama episode row from
/// `GET /api/mini-drama/public/dramas/{dramaId}/episodes`.
class DramaEpisodeListItem extends Equatable {
  final String episodeId;
  final String? dramaId;
  final int? episodeNo;
  final String? title;
  final String? description;
  final String? coverUrl;

  /// Transcoded t=0 still — independent from [coverUrl].
  final String? firstFrameUrl;
  final int? likeCount;
  final bool? likedByMe;

  const DramaEpisodeListItem({
    required this.episodeId,
    this.dramaId,
    this.episodeNo,
    this.title,
    this.description,
    this.coverUrl,
    this.firstFrameUrl,
    this.likeCount,
    this.likedByMe,
  });

  /// Poster for list / player chrome: [firstFrameUrl] then [coverUrl].
  String? get posterUrl => VideoUrlHelpers.preferPosterUrl(
    firstFrameUrl: firstFrameUrl,
    coverUrl: coverUrl,
  );

  factory DramaEpisodeListItem.fromJson(Map<String, dynamic> json) {
    final map = _flattenEpisodeListJson(json);
    return DramaEpisodeListItem(
      episodeId: asStringRequired(map['episodeId'] ?? map['id']),
      dramaId: asString(map['dramaId']),
      episodeNo: asInt(map['episodeNo']),
      title: map['title'] as String?,
      description: map['description'] as String?,
      coverUrl: asString(
        map['coverUrl'] ?? map['coverImg'] ?? map['thumbnailUrl'],
      ),
      firstFrameUrl: asString(map['firstFrameUrl']),
      likeCount: asInt(map['likeCount']),
      likedByMe: asBool(map['likedByMe']),
    );
  }

  /// Public episode list rows nest play fields under [episodeInfo].
  static Map<String, dynamic> _flattenEpisodeListJson(Map<String, dynamic> json) {
    final episodeInfo = json['episodeInfo'];
    if (episodeInfo is! Map) return json;
    final ep = normalizeJson(episodeInfo);
    final drama = normalizeJson(json['dramaInfo']);
    return <String, dynamic>{
      ...json,
      ...drama,
      ...ep,
      'dramaId': drama['dramaId'] ?? ep['dramaId'] ?? json['dramaId'],
      'episodeId': ep['episodeId'] ?? ep['id'] ?? json['episodeId'] ?? json['id'],
      'episodeNo': ep['episodeNo'] ?? json['episodeNo'],
    };
  }

  Map<String, dynamic> toJson() => {
    'episodeId': episodeId,
    if (dramaId != null) 'dramaId': dramaId,
    if (episodeNo != null) 'episodeNo': episodeNo,
    if (title != null) 'title': title,
    if (description != null) 'description': description,
    if (coverUrl != null) 'coverUrl': coverUrl,
    if (firstFrameUrl != null) 'firstFrameUrl': firstFrameUrl,
    if (likeCount != null) 'likeCount': likeCount,
    if (likedByMe != null) 'likedByMe': likedByMe,
  };

  @override
  List<Object?> get props => [
    episodeId,
    dramaId,
    episodeNo,
    title,
    description,
    coverUrl,
    firstFrameUrl,
    likeCount,
    likedByMe,
  ];
}
