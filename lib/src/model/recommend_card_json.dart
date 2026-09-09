import 'json_converters.dart';
import 'work_content_type.dart';

Map<String, dynamic>? _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamic v) => MapEntry(key.toString(), v));
  }
  return null;
}

dynamic _first(List<dynamic> values) {
  for (final value in values) {
    if (value == null) continue;
    if (value is String && value.trim().isEmpty) continue;
    return value;
  }
  return null;
}

/// Flatten nested recommend/search cards:
/// `{ type, userId, creatorAvatarUrl, drama: {...}, episode: {...} }`
/// onto the previous flat `FeedItemResponse` keys. Already-flat payloads pass
/// through unchanged so existing tests keep working.
Map<String, dynamic> flattenRecommendCardJson(Map<String, dynamic> json) {
  final drama = _asMap(json['drama']);
  final episode = _asMap(json['episode']);
  if (drama == null && episode == null) return json;

  final contentType = _first([
    json['contentType'],
    json['type'],
    episode?['contentType'],
    drama?['contentType'],
  ]);
  final isShortVideo = WorkContentType.fromApi(
    asString(contentType),
  ).isShortVideo;
  final normalizedType = (asString(contentType) ?? '')
      .trim()
      .toUpperCase()
      .replaceAll('-', '_');
  final isEpisodeItem =
      isShortVideo ||
      normalizedType == 'DRAMA_EPISODE' ||
      normalizedType == 'SHORT_DRAMA_EPISODE';
  final dramaDescription = _first([
    json['dramaDescription'],
    drama?['description'],
  ]);
  final episodeDescription = _first([
    json['episodeDescription'],
    episode?['description'],
  ]);
  final out = Map<String, dynamic>.from(json);
  out['contentType'] = contentType;
  out['dramaId'] = _first([json['dramaId'], drama?['dramaId']]);
  out['episodeId'] = _first([json['episodeId'], episode?['episodeId']]);
  out['episodeNo'] = _first([json['episodeNo'], episode?['episodeNo']]);
  out['durationSec'] = _first([json['durationSec'], episode?['durationSec']]);
  out['title'] = isShortVideo
      ? _first([json['title'], episode?['title'], drama?['title']])
      : _first([json['title'], drama?['title'], episode?['title']]);
  // Keep both scopes so series grids and episode/work grids can render the
  // correct copy. The legacy `description` field follows the card scope.
  out['dramaDescription'] = dramaDescription;
  out['episodeDescription'] = episodeDescription;
  out['description'] = isEpisodeItem
      ? _first([episodeDescription, json['description'], dramaDescription])
      : _first([dramaDescription, json['description'], episodeDescription]);
  out['coverUrl'] = _first([
    json['coverUrl'],
    episode?['coverUrl'],
    drama?['coverUrl'],
  ]);
  // Episode-scoped t=0 still — never fold into coverUrl.
  out['firstFrameUrl'] = _first([
    json['firstFrameUrl'],
    episode?['firstFrameUrl'],
  ]);
  out['mediaAccessUrl'] = _first([
    json['mediaAccessUrl'],
    episode?['mediaAccessUrl'],
  ]);
  out['playbackType'] = _first([
    json['playbackType'],
    episode?['playbackType'],
  ]);
  out['totalEpisodes'] = _first([
    json['totalEpisodes'],
    drama?['totalEpisodes'],
  ]);
  out['avgRating'] = _first([json['avgRating'], drama?['avgRating']]);
  out['totalHeatValue'] = _first([
    json['totalHeatValue'],
    json['heatValue'],
    drama?['totalHeatValue'],
    drama?['heatValue'],
  ]);
  out['badge'] = _first([json['badge'], drama?['badge']]);
  out['tags'] = json['tags'] ?? drama?['tags'];
  out['actors'] = json['actors'] ?? json['roles'] ?? drama?['actorCollections'];
  out['likeCount'] = _first([json['likeCount'], episode?['likeCount']]);
  out['commentCount'] = _first([
    json['commentCount'],
    episode?['commentCount'],
  ]);
  out['favoriteCount'] = _first([
    json['favoriteCount'],
    episode?['favoriteCount'],
    drama?['favoriteCount'],
    drama?['totalFavoriteCount'],
  ]);
  // Prefer drama-level totals for theater-style cards; episode counts fall back.
  out['playCount'] = _first([
    json['playCount'],
    drama?['totalPlayCount'],
    drama?['playCount'],
    episode?['playCount'],
  ]);
  out['completeCount'] = _first([
    json['completeCount'],
    drama?['totalCompletedViewCount'],
    drama?['completeCount'],
    episode?['completeCount'],
  ]);
  out['creatorId'] = _first([json['creatorId'], json['userId']]);
  out['creatorName'] = _first([json['creatorName']]);
  out['creatorAvatar'] = _first([
    json['creatorAvatar'],
    json['creatorAvatarUrl'],
  ]);
  out['likedByMe'] = json['likedByMe'];
  out['favoritedByMe'] = json['favoritedByMe'];
  out['followedByMe'] = json['followedByMe'];
  return out;
}
