import 'drama_model.dart';
import 'drama_play_response_model.dart';
import 'recommend_feed_model.dart';
import 'work_content_type.dart';

/// Unified read-only abstraction for any playable item in short-drama,
/// recommend, and playlist feeds.
abstract interface class FeedPlayableItem {
  String get dramaId;
  String? get episodeId;
  int get episodeNo;
  int get totalEpisodes;
  String get title;
  String? get description;
  String? get coverUrl;
  String? get creatorName;
  String? get creatorAvatarUrl;
  String? get creatorUserId;
  WorkContentType get contentType;

  /// Identity-only item for loading states / play-payload fallbacks where the
  /// richer adapters ([RecommendFeedItemPlayable], [DramaDetailPlayable],
  /// [DramaPlayResponsePlayable]) cannot resolve every field.
  factory FeedPlayableItem.basic({
    required String dramaId,
    String? episodeId,
    int episodeNo = 1,
    int totalEpisodes = 1,
    String title = '',
    String? description,
    String? coverUrl,
    String? creatorName,
    String? creatorAvatarUrl,
    String? creatorUserId,
    WorkContentType contentType = WorkContentType.shortDrama,
  }) {
    return _AdaptedFeedPlayableItem(
      dramaId: dramaId,
      episodeId: episodeId,
      episodeNo: episodeNo >= 1 ? episodeNo : 1,
      totalEpisodes: totalEpisodes >= 1 ? totalEpisodes : 1,
      title: title,
      description: description,
      coverUrl: coverUrl,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      creatorUserId: creatorUserId,
      contentType: contentType,
    );
  }
}

/// Extension mapping on [RecommendFeedItem] to [FeedPlayableItem].
extension RecommendFeedItemPlayable on RecommendFeedItem {
  FeedPlayableItem toPlayable({DramaDetail? detail, DramaPlayResponse? play}) {
    return _AdaptedFeedPlayableItem(
      dramaId: dramaId,
      episodeId: episodeId ?? play?.episodeId,
      episodeNo: resolvedEpisodeNo,
      totalEpisodes: detail?.totalEpisodes ?? totalEpisodes ?? 1,
      title: detail?.title ?? title ?? '',
      description: detail?.description ?? description,
      // Prefer episode/short-video poster (firstFrame then cover); drama detail
      // cover is series-level fallback when the card has no work still.
      coverUrl: play?.posterUrl ?? posterUrl ?? detail?.coverUrl,
      creatorName: detail?.creatorName ?? creatorName,
      creatorAvatarUrl: detail?.creatorAvatarUrl ?? creatorAvatar,
      // Prefer card/detail identity; fall back to play.userId for sparse
      // playlist seeds (watch history) before creator hydration lands.
      creatorUserId: detail?.userId ?? creatorId ?? play?.userId,
      contentType: workType,
    );
  }
}

/// Extension mapping on [DramaDetail] to [FeedPlayableItem].
extension DramaDetailPlayable on DramaDetail {
  FeedPlayableItem toPlayable({
    int? episodeNo,
    String? episodeId,
    WorkContentType? contentType,
  }) {
    return _AdaptedFeedPlayableItem(
      dramaId: id ?? '',
      episodeId: episodeId,
      episodeNo: (episodeNo != null && episodeNo >= 1) ? episodeNo : 1,
      totalEpisodes: totalEpisodes ?? 1,
      title: title ?? '',
      description: description,
      coverUrl: coverUrl,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      creatorUserId: userId,
      contentType: contentType ?? WorkContentType.shortDrama,
    );
  }
}

/// Extension mapping on [DramaPlayResponse] to [FeedPlayableItem].
///
/// A play payload carries identity, episode description, and engagement —
/// title / creator / cover are not present and must be injected by the caller.
///
/// [creatorUserId] is deliberately NOT seeded from [DramaPlayResponse.userId]:
/// that field can hold the *viewer* on shared play responses and would open a
/// self-profile without a back affordance (see video feed overlays).
extension DramaPlayResponsePlayable on DramaPlayResponse {
  FeedPlayableItem toPlayable({
    String? title,
    String? coverUrl,
    String? creatorName,
    String? creatorAvatarUrl,
    String? creatorUserId,
    WorkContentType? contentType,
  }) {
    final no = episodeNo;
    return _AdaptedFeedPlayableItem(
      dramaId: dramaId ?? '',
      episodeId: episodeId,
      episodeNo: (no != null && no >= 1) ? no : 1,
      totalEpisodes: 1,
      title: title ?? '',
      description: description,
      coverUrl: coverUrl,
      creatorName: creatorName,
      creatorAvatarUrl: creatorAvatarUrl,
      creatorUserId: creatorUserId,
      contentType: contentType ?? WorkContentType.shortDrama,
    );
  }
}

class _AdaptedFeedPlayableItem implements FeedPlayableItem {
  @override
  final String dramaId;
  @override
  final String? episodeId;
  @override
  final int episodeNo;
  @override
  final int totalEpisodes;
  @override
  final String title;
  @override
  final String? description;
  @override
  final String? coverUrl;
  @override
  final String? creatorName;
  @override
  final String? creatorAvatarUrl;
  @override
  final String? creatorUserId;
  @override
  final WorkContentType contentType;

  const _AdaptedFeedPlayableItem({
    required this.dramaId,
    this.episodeId,
    required this.episodeNo,
    required this.totalEpisodes,
    required this.title,
    this.description,
    this.coverUrl,
    this.creatorName,
    this.creatorAvatarUrl,
    this.creatorUserId,
    required this.contentType,
  });
}
