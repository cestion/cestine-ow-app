import 'recommend_feed_state.dart';

/// Shared contract for triple-slot activate orchestrators.
///
/// Implementations stay feed-specific because identity models differ:
/// - Short drama: episode numbers via [FeedActivationPipeline] (`part of`
///   [VideoFeedController]) — entry [VideoFeedController.onSwipeToIndex].
/// - Recommend: flat card index via [RecommendActivatePipeline].
abstract interface class FeedActivateOrchestrator<T> {
  /// Resume bound active, promote a ready neighbor, or cold-bind [target].
  Future<void> bindOrPromote(T target, {bool force});
}

/// Recommend implementation of [FeedActivateOrchestrator].
abstract interface class RecommendActivateOrchestrator
    implements FeedActivateOrchestrator<RecommendFeedState> {}
