import '../core/result.dart';
import '../model/models.dart';
import '../repositories/drama_repository.dart';

/// Episode unlock flows for drama detail widgets.
class DramaUnlockService {
  final DramaRepository _drama;

  const DramaUnlockService(this._drama);

  Future<Result<void>> unlockEpisode(String dramaId, String signature) {
    return _drama.unlockEpisode(dramaId, signature);
  }

  Future<Result<void>> unlockEpisodeBatch(String dramaId, String signature) {
    return _drama.unlockEpisodeBatch(dramaId, signature);
  }

  Future<Result<DramaPlayResponse>> getEpisodeDetail(
    String dramaId,
    int episodeNo,
  ) {
    return _drama.getEpisodeDetail(dramaId, episodeNo);
  }

  /// Poll until episode media URL is available (up to [maxWaitSeconds]).
  ///
  /// Checks immediately first (unlock usually means media is already ready),
  /// then re-checks with exponential backoff (500ms → 3s cap) so the ~30s
  /// budget costs far fewer requests than a fixed 1s poll loop.
  Future<Result<DramaPlayResponse>> pollEpisodeMedia({
    required String dramaId,
    required int episodeNo,
    int maxWaitSeconds = 30,
  }) async {
    final deadline = DateTime.now().add(Duration(seconds: maxWaitSeconds));
    var delay = const Duration(milliseconds: 500);
    while (DateTime.now().isBefore(deadline)) {
      final check = await _drama.getEpisodeDetail(dramaId, episodeNo);
      if (check.isSuccess) {
        final detail = check.dataOrNull;
        if (detail?.mediaAccessUrl?.isNotEmpty == true ||
            detail?.videoUrl?.isNotEmpty == true) {
          return check;
        }
      }
      final remaining = deadline.difference(DateTime.now());
      if (remaining <= Duration.zero) break;
      final wait = delay < remaining ? delay : remaining;
      await Future<void>.delayed(wait);
      delay = delay * 2 > const Duration(seconds: 3)
          ? const Duration(seconds: 3)
          : delay * 2;
    }
    return Result.failure(
      ApiError.business(-1, 'Episode media not ready after polling'),
    );
  }
}
