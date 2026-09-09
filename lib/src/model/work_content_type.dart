/// Favorite API target.
///
/// - [drama]: `POST /user/dramas/{dramaId}/favorite` — whole series (sheet /
///   theater / detail engagement bar).
/// - [work]: player right-rail episode/work favorite —
///   short drama → `POST /user/dramas/episodes/{episodeId}/favorite`;
///   short video → `POST /user/short-videos/{episodeId}/favorite`.
enum FavoriteTarget { drama, work }

/// Mini-drama work kind. Short-drama episodes and standalone short videos
/// share like / favorite / play / complete / report, but hit different paths.
enum WorkContentType {
  shortDrama,
  shortVideo;

  static const apiShortDrama = 'SHORT_DRAMA';
  static const apiShortVideo = 'SHORT_VIDEO';

  bool get isShortVideo => this == WorkContentType.shortVideo;

  bool get isShortDrama => this == WorkContentType.shortDrama;

  String get apiValue => switch (this) {
    WorkContentType.shortDrama => apiShortDrama,
    WorkContentType.shortVideo => apiShortVideo,
  };

  /// Accepts mini-drama (`SHORT_DRAMA` / `SHORT_VIDEO`) and recommend-feed
  /// (`drama_episode` / `short_video`) payloads.
  static WorkContentType fromApi(String? raw) {
    if (raw == null || raw.isEmpty) return WorkContentType.shortDrama;
    final normalized = raw.trim().toUpperCase().replaceAll('-', '_');
    if (normalized == apiShortVideo || normalized == 'SHORTVIDEO') {
      return WorkContentType.shortVideo;
    }
    return WorkContentType.shortDrama;
  }
}
