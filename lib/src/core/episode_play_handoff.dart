import '../model/models.dart';

/// One-shot handoff of episode play data from Theater banner → full-screen feed.
///
/// Drama detail no longer plays inline; it only navigates to the feed, so there
/// is no reverse (Feed → Detail) handoff.
class EpisodePlayHandoff {
  EpisodePlayHandoff._();

  static String? _dramaId;
  static int? _episodeNo;
  static DramaPlayResponse? _play;
  static Duration _startAt = Duration.zero;
  static bool _diskWarmed = false;
  static DateTime? _offeredAt;

  static void offer({
    required String dramaId,
    required int episodeNo,
    required DramaPlayResponse play,
    Duration startAt = Duration.zero,
    bool diskWarmed = false,
  }) {
    _dramaId = dramaId;
    _episodeNo = episodeNo;
    _play = play;
    _startAt = startAt;
    _diskWarmed = diskWarmed;
    _offeredAt = DateTime.now();
  }

  static bool _isExpired() {
    if (_offeredAt == null) return true;
    final elapsed = DateTime.now().difference(_offeredAt!);
    return elapsed > const Duration(seconds: 5);
  }

  static ({DramaPlayResponse play, Duration startAt, bool diskWarmed})? take({
    required String dramaId,
    required int episodeNo,
  }) {
    if (_isExpired()) {
      clear();
      return null;
    }
    if (_dramaId == dramaId && _episodeNo == episodeNo && _play != null) {
      final result = (
        play: _play!,
        startAt: _startAt,
        diskWarmed: _diskWarmed,
      );
      clear();
      return result;
    }
    return null;
  }

  static bool hasOffer({required String dramaId, required int episodeNo}) {
    if (_isExpired()) {
      clear();
      return false;
    }
    return _dramaId == dramaId && _episodeNo == episodeNo && _play != null;
  }

  static void clear() {
    _dramaId = null;
    _episodeNo = null;
    _play = null;
    _startAt = Duration.zero;
    _diskWarmed = false;
    _offeredAt = null;
  }
}
