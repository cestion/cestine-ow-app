/// Generation-gated guard for user-initiated playback retry on recommend.
///
/// Keeps swipe invalidation out of the widget so bind enqueue can ask a single
/// question: "should this loading play still suppress auto-bind?"
class RecommendManualRetryGuard {
  bool inFlight = false;
  int generation = 0;
  int? index;
  String? workId;

  bool matches({
    required int currentIndex,
    required String? bindWorkId,
  }) =>
      inFlight && index == currentIndex && workId == bindWorkId;

  /// Call on feed identity changes. Returns whether the retry still targets
  /// the live card (true → suppress bind while play is loading).
  bool onFeedIdentity({
    required int currentIndex,
    required String? bindWorkId,
  }) {
    if (!inFlight) return false;
    if (matches(currentIndex: currentIndex, bindWorkId: bindWorkId)) {
      return true;
    }
    invalidate();
    return false;
  }

  int begin({required int index, required String? workId}) {
    inFlight = true;
    this.index = index;
    this.workId = workId;
    return ++generation;
  }

  void clearIfCurrent(int gen) {
    if (gen != generation) return;
    inFlight = false;
    index = null;
    workId = null;
  }

  void invalidate() {
    generation++;
    inFlight = false;
    index = null;
    workId = null;
  }
}
